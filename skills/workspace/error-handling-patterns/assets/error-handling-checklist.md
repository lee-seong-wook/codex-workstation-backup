# Error Handling Checklist

- Errors preserve the original cause or stack trace.
- User-facing messages are actionable and avoid leaking secrets.
- Retry logic has bounded attempts and backoff.
- Cleanup runs on success and failure.
- Async/concurrent failures are awaited and surfaced.
- Logs include enough context to debug without exposing sensitive data.
- Tests cover success, expected failure, and unexpected failure paths.

