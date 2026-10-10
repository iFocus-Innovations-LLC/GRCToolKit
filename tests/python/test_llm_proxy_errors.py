import http.client
import importlib.util
import io
import json
import threading
import unittest
import urllib.error
from pathlib import Path
from unittest.mock import patch
from http.server import ThreadingHTTPServer


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "ansible_runner_api", ROOT / "scripts" / "ansible-runner-api.py"
)
runner = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(runner)


class LLMProxyErrorTests(unittest.TestCase):
    def setUp(self):
        self.server = ThreadingHTTPServer(("127.0.0.1", 0), runner.AnsibleRunnerHandler)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join()

    def post_with_upstream_error(
        self, status, detail, api_key="fake-test-key", provider="gemini"
    ):
        def fail(req, timeout=0):
            raise urllib.error.HTTPError(
                req.full_url,
                status,
                "upstream error",
                {},
                io.BytesIO(detail.encode()),
            )

        body = json.dumps(
            {"provider": provider, "prompt": "test", "apiKey": api_key}
        )
        connection = http.client.HTTPConnection(
            "127.0.0.1", self.server.server_address[1]
        )
        try:
            with patch.object(runner.urllib.request, "urlopen", side_effect=fail):
                connection.request(
                    "POST",
                    "/api/llm/analyze",
                    body,
                    {"Content-Type": "application/json"},
                )
                response = connection.getresponse()
                return response.status, json.loads(response.read())
        finally:
            connection.close()

    def test_provider_error_does_not_return_upstream_body_or_api_key(self):
        with self.assertLogs(level="ERROR") as logged:
            status, body = self.post_with_upstream_error(
                429,
                "quota exhausted; echoed credential fake-test-key"
                + (" detail" * 150)
                + " END_OF_UPSTREAM_BODY",
            )

        self.assertEqual(status, 502)
        self.assertEqual(body["error"], "Provider rate limited the request")
        self.assertEqual(body["provider"], "gemini")
        self.assertEqual(body["status"], 429)
        self.assertTrue(body["requestId"])
        self.assertNotIn("quota exhausted", json.dumps(body))
        self.assertNotIn("fake-test-key", json.dumps(body))
        self.assertIn("quota exhausted", "\n".join(logged.output))
        self.assertIn("END_OF_UPSTREAM_BODY", "\n".join(logged.output))
        self.assertNotIn("fake-test-key", "\n".join(logged.output))
        self.assertIn(body["requestId"], "\n".join(logged.output))

    def test_authentication_errors_have_stable_client_message(self):
        for upstream_status in (401, 403):
            with self.subTest(status=upstream_status):
                status, body = self.post_with_upstream_error(
                    upstream_status, "secret vendor response"
                )

                self.assertEqual(status, 502)
                self.assertEqual(body["error"], "Provider rejected credentials")
                self.assertEqual(body["status"], upstream_status)
                self.assertNotIn("secret vendor response", json.dumps(body))

    def test_other_upstream_errors_use_generic_message(self):
        status, body = self.post_with_upstream_error(500, "private provider details")

        self.assertEqual(status, 502)
        self.assertEqual(body["error"], "LLM provider request failed")
        self.assertEqual(body["status"], 500)
        self.assertNotIn("private provider details", json.dumps(body))

    def test_provider_name_is_normalized_in_error_metadata(self):
        status, body = self.post_with_upstream_error(
            429, "quota exhausted", provider=" Gemini "
        )

        self.assertEqual(status, 502)
        self.assertEqual(body["provider"], "gemini")

    def test_non_object_json_is_rejected_by_api_handlers(self):
        for path in (
            "/api/llm/analyze",
            "/api/ansible/playbook",
            "/api/reports/oscal-pdf",
        ):
            with self.subTest(path=path):
                connection = http.client.HTTPConnection(
                    "127.0.0.1", self.server.server_address[1]
                )
                try:
                    connection.request(
                        "POST",
                        path,
                        "[]",
                        {"Content-Type": "application/json"},
                    )
                    response = connection.getresponse()
                    body = json.loads(response.read())
                finally:
                    connection.close()

                self.assertEqual(response.status, 400)
                self.assertEqual(body["error"], "JSON body must be an object")

    def test_redaction_covers_authorization_headers(self):
        request = runner.urllib.request.Request(
            "https://api.example.test/", headers={"Authorization": "Bearer fake-openai-key"}
        )

        detail = runner._redact_upstream_detail(
            "provider echoed Bearer fake-openai-key", request
        )

        self.assertNotIn("fake-openai-key", detail)

    def test_unexpected_llm_exception_returns_generic_error(self):
        connection = http.client.HTTPConnection(
            "127.0.0.1", self.server.server_address[1]
        )
        try:
            with patch.object(
                runner,
                "analyze_llm",
                side_effect=RuntimeError("private traceback details"),
            ):
                connection.request(
                    "POST",
                    "/api/llm/analyze",
                    json.dumps({"provider": "openai", "prompt": "test"}),
                    {"Content-Type": "application/json"},
                )
                response = connection.getresponse()
                body = json.loads(response.read())
        finally:
            connection.close()

        self.assertEqual(response.status, 502)
        self.assertEqual(body["error"], "LLM provider request failed")
        self.assertNotIn("private traceback details", json.dumps(body))

    def test_unexpected_non_llm_exception_returns_generic_error(self):
        connection = http.client.HTTPConnection(
            "127.0.0.1", self.server.server_address[1]
        )
        try:
            with patch.object(
                runner,
                "run_playbook",
                side_effect=Exception("private playbook path"),
            ):
                connection.request(
                    "POST",
                    "/api/ansible/playbook",
                    json.dumps({"playbook": "valid-playbook"}),
                    {"Content-Type": "application/json"},
                )
                response = connection.getresponse()
                body = json.loads(response.read())
        finally:
            connection.close()

        self.assertEqual(response.status, 500)
        self.assertEqual(body["error"], "Internal server error")
        self.assertNotIn("private playbook path", json.dumps(body))
        self.assertTrue(body["requestId"])


if __name__ == "__main__":
    unittest.main()
