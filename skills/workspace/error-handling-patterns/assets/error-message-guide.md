# Error Message Guide

Good error messages include:

- What failed.
- Why it likely failed.
- What the user or operator can do next.
- A stable error code when the error crosses process or API boundaries.

Avoid:

- Raw secrets, tokens, credentials, or private paths.
- Catch-all messages that hide the actual failing subsystem.
- Advice that assumes the caller has access they may not have.

