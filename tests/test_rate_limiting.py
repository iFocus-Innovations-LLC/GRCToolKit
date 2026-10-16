#!/usr/bin/env python3
"""
Tests for rate limiting in ansible-runner-api.py
"""
import importlib.util
import json
import sys
import threading
import time
from http.client import HTTPConnection
from pathlib import Path
from unittest.mock import Mock, patch

import pytest

# Add parent dir to path and import the module (handles hyphenated filename)
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

# Import module with hyphens in filename
spec = importlib.util.spec_from_file_location(
    "ansible_runner_api",
    Path(__file__).resolve().parents[1] / "scripts" / "ansible-runner-api.py"
)
ansible_runner_api = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ansible_runner_api)

ConcurrencyTracker = ansible_runner_api.ConcurrencyTracker
TokenBucketLimiter = ansible_runner_api.TokenBucketLimiter
_parse_rate_limit = ansible_runner_api._parse_rate_limit


class TestRateLimitParsing:
    """Test rate limit string parsing."""
    
    def test_parse_per_second(self):
        count, window = _parse_rate_limit("10/sec")
        assert count == 10
        assert window == 1.0
    
    def test_parse_per_minute(self):
        count, window = _parse_rate_limit("6/min")
        assert count == 6
        assert window == 60.0
    
    def test_parse_per_hour(self):
        count, window = _parse_rate_limit("100/hour")
        assert count == 100
        assert window == 3600.0
    
    def test_parse_invalid_format(self):
        with pytest.raises(ValueError, match="Invalid rate format"):
            _parse_rate_limit("invalid")
    
    def test_parse_invalid_count(self):
        with pytest.raises(ValueError, match="Invalid rate count"):
            _parse_rate_limit("abc/min")
    
    def test_parse_invalid_unit(self):
        with pytest.raises(ValueError, match="Invalid rate unit"):
            _parse_rate_limit("10/year")


class TestTokenBucketLimiter:
    """Test token bucket rate limiter."""
    
    def test_first_request_allowed(self):
        limiter = TokenBucketLimiter("5/sec")
        allowed, retry_after = limiter.check_limit("client1")
        assert allowed is True
        assert retry_after == 0.0
    
    def test_burst_limit(self):
        """Test that burst over limit is rejected with 429."""
        limiter = TokenBucketLimiter("3/sec")
        
        # First 3 requests should succeed
        for i in range(3):
            allowed, _ = limiter.check_limit("client1")
            assert allowed is True, f"Request {i+1} should be allowed"
        
        # 4th request should fail
        allowed, retry_after = limiter.check_limit("client1")
        assert allowed is False
        assert retry_after > 0
    
    def test_refill_after_window(self):
        """Test that tokens refill after waiting."""
        limiter = TokenBucketLimiter("2/sec")
        
        # Exhaust tokens
        limiter.check_limit("client1")
        limiter.check_limit("client1")
        allowed, _ = limiter.check_limit("client1")
        assert allowed is False
        
        # Wait for refill
        time.sleep(0.6)  # Should refill ~1 token
        allowed, _ = limiter.check_limit("client1")
        assert allowed is True
    
    def test_retry_after_calculation(self):
        """Test that Retry-After header value is reasonable."""
        limiter = TokenBucketLimiter("5/sec")
        
        # Exhaust bucket
        for _ in range(5):
            limiter.check_limit("client1")
        
        allowed, retry_after = limiter.check_limit("client1")
        assert allowed is False
        # For 5/sec rate, refill_rate is 5 tokens per second
        # Need 1 token, so retry_after should be ~0.2 seconds
        assert 0.1 <= retry_after <= 0.5
    
    def test_separate_clients(self):
        """Test that different clients have separate buckets."""
        limiter = TokenBucketLimiter("2/sec")
        
        # Client1 exhausts their bucket
        limiter.check_limit("client1")
        limiter.check_limit("client1")
        allowed, _ = limiter.check_limit("client1")
        assert allowed is False
        
        # Client2 should still be allowed
        allowed, _ = limiter.check_limit("client2")
        assert allowed is True
    
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
        assert sum(results) == 100
        assert len(results) == 100  # 5 threads * 20 requests


class TestConcurrencyTracker:
    """Test concurrency tracking for playbook runs."""
    
    def test_acquire_within_limit(self):
        tracker = ConcurrencyTracker(max_concurrent=2)
        assert tracker.try_acquire() is True
        assert tracker.try_acquire() is True
    
    def test_acquire_at_limit(self):
        """Test that concurrent playbook limit is enforced."""
        tracker = ConcurrencyTracker(max_concurrent=1)
        
        # First acquire succeeds
        assert tracker.try_acquire() is True
        
        # Second acquire fails (at limit)
        assert tracker.try_acquire() is False
    
    def test_release_frees_slot(self):
        tracker = ConcurrencyTracker(max_concurrent=1)
        
        tracker.try_acquire()
        assert tracker.try_acquire() is False
        
        # Release and try again
        tracker.release()
        assert tracker.try_acquire() is True
    
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
        assert sum(successes) == 10
        assert len(successes) == 20


class TestAPIRateLimiting:
    """Integration tests for rate limiting in the HTTP API."""
    
    def test_get_client_ip_direct(self):
        """Test IP extraction without X-Forwarded-For."""
        handler = ansible_runner_api.AnsibleRunnerHandler
        
        # Create minimal mock handler
        mock_handler = Mock(spec=handler)
        mock_handler.client_address = ("10.0.0.5", 12345)
        mock_handler.headers = {}
        
        # Bind the method to the mock
        ip = handler._get_client_ip(mock_handler)
        assert ip == "10.0.0.5"
    
    def test_get_client_ip_with_x_forwarded_for(self):
        """Test that X-Forwarded-For is respected from localhost when trusted."""
        handler = ansible_runner_api.AnsibleRunnerHandler
        
        old_trust = ansible_runner_api.TRUST_PROXY_HEADERS
        ansible_runner_api.TRUST_PROXY_HEADERS = True
        
        try:
            mock_handler = Mock(spec=handler)
            mock_handler.client_address = ("127.0.0.1", 12345)
            mock_handler.headers = {"X-Forwarded-For": "192.168.1.100, 10.0.0.1"}
            
            ip = handler._get_client_ip(mock_handler)
            # Should extract the first IP from the forwarded chain
            assert ip == "192.168.1.100"
        finally:
            ansible_runner_api.TRUST_PROXY_HEADERS = old_trust
    
    def test_get_client_ip_x_forwarded_not_from_localhost(self):
        """Test that X-Forwarded-For is NOT trusted from external IPs."""
        handler = ansible_runner_api.AnsibleRunnerHandler
        
        old_trust = ansible_runner_api.TRUST_PROXY_HEADERS
        ansible_runner_api.TRUST_PROXY_HEADERS = True
        
        try:
            mock_handler = Mock(spec=handler)
            mock_handler.client_address = ("10.0.0.5", 12345)
            mock_handler.headers = {"X-Forwarded-For": "192.168.1.100"}
            
            ip = handler._get_client_ip(mock_handler)
            # Should use direct client IP, not forwarded
            assert ip == "10.0.0.5"
        finally:
            ansible_runner_api.TRUST_PROXY_HEADERS = old_trust
    
    def test_get_client_ip_proxy_trust_disabled(self):
        """Test that X-Forwarded-For is ignored when trust is disabled."""
        handler = ansible_runner_api.AnsibleRunnerHandler
        
        old_trust = ansible_runner_api.TRUST_PROXY_HEADERS
        ansible_runner_api.TRUST_PROXY_HEADERS = False
        
        try:
            mock_handler = Mock(spec=handler)
            mock_handler.client_address = ("127.0.0.1", 12345)
            mock_handler.headers = {"X-Forwarded-For": "192.168.1.100"}
            
            ip = handler._get_client_ip(mock_handler)
            # Should use direct client IP even from localhost
            assert ip == "127.0.0.1"
        finally:
            ansible_runner_api.TRUST_PROXY_HEADERS = old_trust
    
    def test_rate_limit_integration(self):
        """Test that rate limiting works end-to-end with multiple clients."""
        limiter = TokenBucketLimiter("5/sec")
        
        # Client 1 makes 5 requests (should all succeed)
        for i in range(5):
            allowed, _ = limiter.check_limit("client1")
            assert allowed, f"Client1 request {i+1} should succeed"
        
        # Client 1's 6th request should fail
        allowed, retry_after = limiter.check_limit("client1")
        assert not allowed
        assert retry_after > 0
        
        # Client 2 should still have their full quota
        for i in range(5):
            allowed, _ = limiter.check_limit("client2")
            assert allowed, f"Client2 request {i+1} should succeed"
        
        # Wait for partial refill
        time.sleep(0.5)
        
        # Client 1 should have some tokens refilled
        allowed, _ = limiter.check_limit("client1")
        assert allowed


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
