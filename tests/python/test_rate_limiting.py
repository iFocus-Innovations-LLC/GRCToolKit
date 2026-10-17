#!/usr/bin/env python3
"""
Tests for rate limiting in ansible-runner-api.py
"""
import importlib.util
import json
import sys
import threading
import time
import unittest
from pathlib import Path
from unittest.mock import Mock

# Import module with hyphens in filename
ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location(
    "ansible_runner_api",
    ROOT / "scripts" / "ansible-runner-api.py"
)
ansible_runner_api = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ansible_runner_api)

ConcurrencyTracker = ansible_runner_api.ConcurrencyTracker
TokenBucketLimiter = ansible_runner_api.TokenBucketLimiter
_parse_rate_limit = ansible_runner_api._parse_rate_limit


class TestRateLimitParsing(unittest.TestCase):
    """Test rate limit string parsing."""
    
    def test_parse_per_second(self):
        count, window = _parse_rate_limit("10/sec")
        self.assertEqual(count, 10)
        self.assertEqual(window, 1.0)
    
    def test_parse_per_minute(self):
        count, window = _parse_rate_limit("6/min")
        self.assertEqual(count, 6)
        self.assertEqual(window, 60.0)
    
    def test_parse_per_hour(self):
        count, window = _parse_rate_limit("100/hour")
        self.assertEqual(count, 100)
        self.assertEqual(window, 3600.0)
    
    def test_parse_invalid_format(self):
        with self.assertRaises(ValueError) as cm:
            _parse_rate_limit("invalid")
        self.assertIn("Invalid rate format", str(cm.exception))
    
    def test_parse_invalid_count(self):
        with self.assertRaises(ValueError) as cm:
            _parse_rate_limit("abc/min")
        self.assertIn("Invalid rate count", str(cm.exception))
    
    def test_parse_invalid_unit(self):
        with self.assertRaises(ValueError) as cm:
            _parse_rate_limit("10/year")
        self.assertIn("Invalid rate unit", str(cm.exception))


class TestTokenBucketLimiter(unittest.TestCase):
    """Test token bucket rate limiter."""
    
    def test_first_request_allowed(self):
        limiter = TokenBucketLimiter("5/sec")
        allowed, retry_after = limiter.check_limit("client1")
        self.assertTrue(allowed)
        self.assertEqual(retry_after, 0.0)
    
    def test_burst_limit(self):
        """Test that burst over limit is rejected with 429."""
        limiter = TokenBucketLimiter("3/sec")
        
        # First 3 requests should succeed
        for i in range(3):
            allowed, _ = limiter.check_limit("client1")
            self.assertTrue(allowed, f"Request {i+1} should be allowed")
        
        # 4th request should fail
        allowed, retry_after = limiter.check_limit("client1")
        self.assertFalse(allowed)
        self.assertGreater(retry_after, 0)
    
    def test_refill_after_window(self):
        """Test that tokens refill after waiting."""
        limiter = TokenBucketLimiter("2/sec")
        
        # Exhaust tokens
        limiter.check_limit("client1")
        limiter.check_limit("client1")
        allowed, _ = limiter.check_limit("client1")
        self.assertFalse(allowed)
        
        # Wait for refill
        time.sleep(0.6)  # Should refill ~1 token
        allowed, _ = limiter.check_limit("client1")
        self.assertTrue(allowed)
    
    def test_retry_after_calculation(self):
        """Test that Retry-After header value is reasonable."""
        limiter = TokenBucketLimiter("5/sec")
        
        # Exhaust bucket
        for _ in range(5):
            limiter.check_limit("client1")
        
        allowed, retry_after = limiter.check_limit("client1")
        self.assertFalse(allowed)
        # For 5/sec rate, refill_rate is 5 tokens per second
        # Need 1 token, so retry_after should be ~0.2 seconds
        self.assertGreaterEqual(retry_after, 0.1)
        self.assertLessEqual(retry_after, 0.5)
    
    def test_separate_clients(self):
        """Test that different clients have separate buckets."""
        limiter = TokenBucketLimiter("2/sec")
        
        # Client1 exhausts their bucket
        limiter.check_limit("client1")
        limiter.check_limit("client1")
        allowed, _ = limiter.check_limit("client1")
        self.assertFalse(allowed)
        
        # Client2 should still be allowed
        allowed, _ = limiter.check_limit("client2")
        self.assertTrue(allowed)
    
    def test_thread_safety(self):
        """Test that limiter is thread-safe."""
        limiter = TokenBucketLimiter("100/sec")
        results = []
        
        def make_requests():
            for _ in range(20):
                allowed, _ = limiter.check_limit("shared-client")
                results.append(allowed)
        
        threads = [threading.Thread(target=make_requests) for _ in range(5)]
        for t in threads:
            t.start()
        for t in threads:
            t.join()
        
        # Exactly 100 should be allowed (capacity of bucket)
        self.assertEqual(sum(results), 100)
        self.assertEqual(len(results), 100)  # 5 threads * 20 requests
    
    def test_reset_clears_buckets(self):
        """Test that reset() clears all client buckets."""
        limiter = TokenBucketLimiter("2/sec")
        
        # Exhaust bucket for client1
        limiter.check_limit("client1")
        limiter.check_limit("client1")
        allowed, _ = limiter.check_limit("client1")
        self.assertFalse(allowed)
        
        # Reset and verify client1 has full quota again
        limiter.reset()
        allowed, _ = limiter.check_limit("client1")
        self.assertTrue(allowed)


class TestConcurrencyTracker(unittest.TestCase):
    """Test concurrency tracking for playbook runs."""
    
    def test_acquire_within_limit(self):
        tracker = ConcurrencyTracker(max_concurrent=2)
        self.assertTrue(tracker.try_acquire())
        self.assertTrue(tracker.try_acquire())
    
    def test_acquire_at_limit(self):
        """Test that concurrent playbook limit is enforced."""
        tracker = ConcurrencyTracker(max_concurrent=1)
        
        # First acquire succeeds
        self.assertTrue(tracker.try_acquire())
        
        # Second acquire fails (at limit)
        self.assertFalse(tracker.try_acquire())
    
    def test_release_frees_slot(self):
        tracker = ConcurrencyTracker(max_concurrent=1)
        
        tracker.try_acquire()
        self.assertFalse(tracker.try_acquire())
        
        # Release and try again
        tracker.release()
        self.assertTrue(tracker.try_acquire())
    
    def test_thread_safety(self):
        """Test that tracker is thread-safe under concurrent access."""
        tracker = ConcurrencyTracker(max_concurrent=10)
        successes = []
        lock = threading.Lock()
        
        def try_acquire_release():
            acquired = tracker.try_acquire()
            with lock:
                successes.append(acquired)
            if acquired:
                time.sleep(0.05)  # Hold the slot briefly
                tracker.release()
        
        threads = [threading.Thread(target=try_acquire_release) for _ in range(20)]
        for t in threads:
            t.start()
        for t in threads:
            t.join()
        
        # Exactly 10 should succeed acquiring at once (max_concurrent=10)
        # The others fail immediately since they don't wait
        self.assertEqual(sum(successes), 10)
        self.assertEqual(len(successes), 20)
    
    def test_reset_clears_count(self):
        """Test that reset() clears the counter."""
        tracker = ConcurrencyTracker(max_concurrent=1)
        
        tracker.try_acquire()
        self.assertFalse(tracker.try_acquire())
        
        # Reset should clear without explicit release
        tracker.reset()
        self.assertTrue(tracker.try_acquire())


class TestIPExtraction(unittest.TestCase):
    """Test client IP extraction with proxy header security."""
    
    def setUp(self):
        """Reset proxy configuration before each test."""
        self.old_trust = ansible_runner_api.TRUST_PROXY_HEADERS
        self.old_hop_count = ansible_runner_api.TRUST_PROXY_HOP_COUNT
    
    def tearDown(self):
        """Restore original configuration."""
        ansible_runner_api.TRUST_PROXY_HEADERS = self.old_trust
        ansible_runner_api.TRUST_PROXY_HOP_COUNT = self.old_hop_count
    
    def test_get_client_ip_direct(self):
        """Test IP extraction without proxy headers."""
        handler = ansible_runner_api.AnsibleRunnerHandler
        
        # Create minimal mock handler
        mock_handler = Mock(spec=handler)
        mock_handler.client_address = ("10.0.0.5", 12345)
        mock_handler.headers = {}
        
        ansible_runner_api.TRUST_PROXY_HEADERS = False
        
        # Bind the method to the mock
        ip = handler._get_client_ip(mock_handler)
        self.assertEqual(ip, "10.0.0.5")
    
    def test_x_real_ip_preferred(self):
        """Test that X-Real-IP is preferred over X-Forwarded-For."""
        handler = ansible_runner_api.AnsibleRunnerHandler
        
        ansible_runner_api.TRUST_PROXY_HEADERS = True
        
        mock_handler = Mock(spec=handler)
        mock_handler.client_address = ("127.0.0.1", 12345)
        mock_handler.headers = {
            "X-Real-IP": "192.168.1.100",
            "X-Forwarded-For": "10.0.0.1, 192.168.1.100"
        }
        
        ip = handler._get_client_ip(mock_handler)
        self.assertEqual(ip, "192.168.1.100")
    
    def test_xff_rightmost_extraction(self):
        """Test that rightmost XFF entry is extracted, not leftmost (security fix)."""
        handler = ansible_runner_api.AnsibleRunnerHandler
        
        ansible_runner_api.TRUST_PROXY_HEADERS = True
        ansible_runner_api.TRUST_PROXY_HOP_COUNT = 1
        
        mock_handler = Mock(spec=handler)
        mock_handler.client_address = ("127.0.0.1", 12345)
        # Client sends fake-ip, proxy appends real IP
        mock_handler.headers = {"X-Forwarded-For": "1.1.1.1, 2.2.2.2, 192.168.1.100"}
        
        ip = handler._get_client_ip(mock_handler)
        # Should extract rightmost (proxy-appended), not leftmost (client-controlled)
        self.assertEqual(ip, "192.168.1.100")
    
    def test_xff_spoofing_cannot_bypass_limit(self):
        """Test that spoofed leftmost XFF entry doesn't bypass rate limit."""
        handler = ansible_runner_api.AnsibleRunnerHandler
        limiter = TokenBucketLimiter("2/sec")
        
        ansible_runner_api.TRUST_PROXY_HEADERS = True
        ansible_runner_api.TRUST_PROXY_HOP_COUNT = 1
        
        mock_handler = Mock(spec=handler)
        mock_handler.client_address = ("127.0.0.1", 12345)
        
        # Attacker tries to bypass limit by rotating fake IPs
        for fake_ip in ["spoofed1", "spoofed2", "spoofed3"]:
            mock_handler.headers = {"X-Forwarded-For": f"{fake_ip}, 192.168.1.100"}
            client_ip = handler._get_client_ip(mock_handler)
            # All should map to the same real IP (rightmost)
            self.assertEqual(client_ip, "192.168.1.100")
            limiter.check_limit(client_ip)
        
        # Real IP should be rate limited (exhausted bucket)
        allowed, _ = limiter.check_limit("192.168.1.100")
        self.assertFalse(allowed, "Spoofed leftmost XFF should not bypass rate limit")
    
    def test_xff_not_trusted_from_external_ip(self):
        """Test that X-Forwarded-For is NOT trusted from external IPs."""
        handler = ansible_runner_api.AnsibleRunnerHandler
        
        ansible_runner_api.TRUST_PROXY_HEADERS = True
        
        mock_handler = Mock(spec=handler)
        mock_handler.client_address = ("10.0.0.5", 12345)
        mock_handler.headers = {"X-Forwarded-For": "192.168.1.100"}
        
        ip = handler._get_client_ip(mock_handler)
        # Should use direct client IP, not forwarded
        self.assertEqual(ip, "10.0.0.5")
    
    def test_xff_proxy_trust_disabled(self):
        """Test that X-Forwarded-For is ignored when trust is disabled."""
        handler = ansible_runner_api.AnsibleRunnerHandler
        
        ansible_runner_api.TRUST_PROXY_HEADERS = False
        
        mock_handler = Mock(spec=handler)
        mock_handler.client_address = ("127.0.0.1", 12345)
        mock_handler.headers = {"X-Forwarded-For": "192.168.1.100"}
        
        ip = handler._get_client_ip(mock_handler)
        # Should use direct client IP even from localhost
        self.assertEqual(ip, "127.0.0.1")
    
    def test_xff_multiple_hops(self):
        """Test configurable hop count for multi-proxy setups."""
        handler = ansible_runner_api.AnsibleRunnerHandler
        
        ansible_runner_api.TRUST_PROXY_HEADERS = True
        ansible_runner_api.TRUST_PROXY_HOP_COUNT = 2
        
        mock_handler = Mock(spec=handler)
        mock_handler.client_address = ("127.0.0.1", 12345)
        # client -> proxy1 -> proxy2 -> app
        # XFF chain: original, proxy1-append, proxy2-append
        mock_handler.headers = {"X-Forwarded-For": "client-ip, proxy1-ip, proxy2-ip"}
        
        ip = handler._get_client_ip(mock_handler)
        # With hop_count=2, trust last 2 entries, extract the earlier one
        self.assertEqual(ip, "proxy1-ip")


class TestRateLimitIntegration(unittest.TestCase):
    """Integration tests for rate limiting."""
    
    def setUp(self):
        """Reset limiters before each test."""
        ansible_runner_api.playbook_limiter.reset()
        ansible_runner_api.llm_limiter.reset()
        ansible_runner_api.pdf_limiter.reset()
        ansible_runner_api.playbook_concurrency.reset()
    
    def test_rate_limit_integration_multiple_clients(self):
        """Test that rate limiting works end-to-end with multiple clients."""
        limiter = TokenBucketLimiter("5/sec")
        
        # Client 1 makes 5 requests (should all succeed)
        for i in range(5):
            allowed, _ = limiter.check_limit("client1")
            self.assertTrue(allowed, f"Client1 request {i+1} should succeed")
        
        # Client 1's 6th request should fail
        allowed, retry_after = limiter.check_limit("client1")
        self.assertFalse(allowed)
        self.assertGreater(retry_after, 0)
        
        # Client 2 should still have their full quota
        for i in range(5):
            allowed, _ = limiter.check_limit("client2")
            self.assertTrue(allowed, f"Client2 request {i+1} should succeed")
        
        # Wait for partial refill
        time.sleep(0.5)
        
        # Client 1 should have some tokens refilled
        allowed, _ = limiter.check_limit("client1")
        self.assertTrue(allowed)


if __name__ == "__main__":
    unittest.main()
