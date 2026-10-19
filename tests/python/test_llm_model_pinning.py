import http.client
import importlib.util
import json
import os
import threading
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch
from http.server import ThreadingHTTPServer


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "ansible_runner_api", ROOT / "scripts" / "ansible-runner-api.py"
)
runner = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(runner)


class LLMModelPinningTests(unittest.TestCase):
    """Test server-key model pinning to prevent abuse (G7 mitigation)."""
    
    def setUp(self):
        # Reset global rate limiters to prevent test pollution
        runner.playbook_limiter.reset()
        runner.llm_limiter.reset()
        runner.pdf_limiter.reset()
        runner.playbook_concurrency.reset()
        
        self.server = ThreadingHTTPServer(("127.0.0.1", 0), runner.AnsibleRunnerHandler)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join()

    def post_llm(self, payload, mock_response=None):
        """Post to /api/llm/analyze with mocked upstream."""
        def mock_urlopen(req, timeout=0):
            response = MagicMock()
            response.read.return_value = json.dumps(mock_response or {
                "candidates": [{"content": {"parts": [{"text": "test response"}]}}]
            }).encode("utf-8")
            response.__enter__ = lambda self: self
            response.__exit__ = lambda self, *args: None
            return response
        
        connection = http.client.HTTPConnection(
            "127.0.0.1", self.server.server_address[1]
        )
        try:
            with patch.object(runner.urllib.request, "urlopen", side_effect=mock_urlopen):
                connection.request(
                    "POST",
                    "/api/llm/analyze",
                    json.dumps(payload),
                    {"Content-Type": "application/json"},
                )
                response = connection.getresponse()
                return response.status, json.loads(response.read())
        finally:
            connection.close()

    def test_server_key_pins_model_gemini(self):
        """When using server GEMINI_API_KEY, client-supplied model is ignored."""
        with patch.dict(
            os.environ,
            {"GEMINI_API_KEY": "server-key", "GEMINI_MODEL": "gemini-3.8-flash"},
            clear=False
        ):
            status, body = self.post_llm({
                "provider": "gemini",
                "prompt": "test prompt",
                "model": "gemini-pro-1.5-experimental",  # Client tries pricier model
                # No apiKey = uses server key
            })
        
        self.assertEqual(status, 200)
        # Server should have pinned to configured model
        self.assertEqual(body["modelId"], "gemini-3.8-flash")

    def test_client_key_allows_custom_model_gemini(self):
        """When client supplies apiKey, they can specify their own model."""
        with patch.dict(os.environ, {"GEMINI_MODEL": "gemini-3.8-flash"}, clear=False):
            status, body = self.post_llm({
                "provider": "gemini",
                "prompt": "test prompt",
                "model": "gemini-pro-1.5-experimental",
                "apiKey": "client-supplied-key",  # BYOK
            })
        
        self.assertEqual(status, 200)
        # Client's model choice should be honored
        self.assertEqual(body["modelId"], "gemini-pro-1.5-experimental")

    def test_server_key_pins_model_openai(self):
        """OpenAI provider also pins model when using server key."""
        with patch.dict(
            os.environ,
            {"OPENAI_API_KEY": "server-key", "OPENAI_MODEL": "gpt-4o-mini"},
            clear=False
        ):
            mock_response = {
                "choices": [{"message": {"content": "test response"}}]
            }
            status, body = self.post_llm({
                "provider": "openai",
                "prompt": "test prompt",
                "model": "gpt-4o",  # Client tries pricier model
            }, mock_response)
        
        self.assertEqual(status, 200)
        self.assertEqual(body["modelId"], "gpt-4o-mini")

    def test_server_key_pins_model_anthropic(self):
        """Anthropic provider also pins model when using server key."""
        with patch.dict(
            os.environ,
            {"ANTHROPIC_API_KEY": "server-key", "ANTHROPIC_MODEL": "claude-sonnet-4-20250514"},
            clear=False
        ):
            mock_response = {
                "content": [{"type": "text", "text": "test response"}]
            }
            status, body = self.post_llm({
                "provider": "anthropic",
                "prompt": "test prompt",
                "model": "claude-opus-4-20250514",  # Client tries pricier model
            }, mock_response)
        
        self.assertEqual(status, 200)
        self.assertEqual(body["modelId"], "claude-sonnet-4-20250514")

    def test_server_key_pins_model_groq(self):
        """Groq provider also pins model when using server key."""
        with patch.dict(
            os.environ,
            {"GROQ_API_KEY": "server-key", "GROQ_MODEL": "llama-3.3-70b-versatile"},
            clear=False
        ):
            mock_response = {
                "choices": [{"message": {"content": "test response"}}]
            }
            status, body = self.post_llm({
                "provider": "groq",
                "prompt": "test prompt",
                "model": "some-expensive-model",
            }, mock_response)
        
        self.assertEqual(status, 200)
        self.assertEqual(body["modelId"], "llama-3.3-70b-versatile")

    def test_server_key_pins_model_vertex(self):
        """Vertex provider also pins model when using server key."""
        with patch.dict(
            os.environ,
            {"VERTEX_API_KEY": "server-key", "VERTEX_MODEL": "gemini-3.8-flash"},
            clear=False
        ):
            status, body = self.post_llm({
                "provider": "vertex",
                "prompt": "test prompt",
                "model": "gemini-pro-experimental",
            })
        
        self.assertEqual(status, 200)
        self.assertEqual(body["modelId"], "gemini-3.8-flash")

    def test_client_matches_server_model_works(self):
        """Client can still request the same model as server default."""
        with patch.dict(
            os.environ,
            {"GEMINI_API_KEY": "server-key", "GEMINI_MODEL": "gemini-3.8-flash"},
            clear=False
        ):
            status, body = self.post_llm({
                "provider": "gemini",
                "prompt": "test prompt",
                "model": "gemini-3.8-flash",  # Same as server default
            })
        
        self.assertEqual(status, 200)
        self.assertEqual(body["modelId"], "gemini-3.8-flash")

    def test_no_model_specified_uses_default(self):
        """When client omits model, server default is used."""
        with patch.dict(
            os.environ,
            {"GEMINI_API_KEY": "server-key", "GEMINI_MODEL": "gemini-3.8-flash"},
            clear=False
        ):
            status, body = self.post_llm({
                "provider": "gemini",
                "prompt": "test prompt",
                # No model specified
            })
        
        self.assertEqual(status, 200)
        self.assertEqual(body["modelId"], "gemini-3.8-flash")


if __name__ == "__main__":
    unittest.main()
