# Exception Hierarchy Design

Practical guide to designing error class hierarchies that are maintainable, informative, and easy to catch at the right level.

## Design Principles

### 1. Single Root Base Error

Every application should have one base error class. This lets callers catch all application-specific errors without accidentally catching system errors.

**Python:**

```python
class AppError(Exception):
    """Base for all application errors."""
    def __init__(self, message: str, code: str = "UNKNOWN", details: dict = None):
        super().__init__(message)
        self.code = code
        self.details = details or {}
```

**TypeScript:**

```typescript
class AppError extends Error {
  constructor(
    message: string,
    public readonly code: string = "UNKNOWN",
    public readonly statusCode: number = 500,
    public readonly details: Record<string, unknown> = {},
  ) {
    super(message);
    this.name = this.constructor.name;
    Object.setPrototypeOf(this, new.target.prototype);
  }

  toJSON() {
    return {
      name: this.name,
      code: this.code,
      message: this.message,
      details: this.details,
    };
  }
}
```

**Go:**

```go
type AppError struct {
    Code    string         `json:"code"`
    Message string         `json:"message"`
    Details map[string]any `json:"details,omitempty"`
    Cause   error          `json:"-"`
}

func (e *AppError) Error() string {
    return fmt.Sprintf("[%s] %s", e.Code, e.Message)
}

func (e *AppError) Unwrap() error {
    return e.Cause
}
```

**Rust:**

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AppError {
    #[error("validation failed: {message}")]
    Validation { message: String, field: String },

    #[error("resource not found: {resource} ({id})")]
    NotFound { resource: String, id: String },

    #[error("external service error: {service}")]
    ExternalService {
        service: String,
        #[source]
        source: Box<dyn std::error::Error + Send + Sync>,
    },

    #[error("unauthorized: {0}")]
    Unauthorized(String),

    #[error("internal error")]
    Internal(#[from] anyhow::Error),
}
```

## Recommended Hierarchy Structure

### Tier 1: Category Errors (catch by domain)

```
AppError
├── ClientError          (4xx - caller's fault)
│   ├── ValidationError
│   ├── NotFoundError
│   ├── ConflictError
│   └── AuthError
│       ├── AuthenticationError
│       └── AuthorizationError
├── ExternalError        (dependency failures)
│   ├── ServiceError
│   ├── DatabaseError
│   └── NetworkError
└── InternalError        (5xx - our fault)
    ├── ConfigError
    └── StateError
```

### Tier 2: Granular Errors (catch specific cases)

Keep granular errors under their category. Two levels deep is usually enough. Three levels is the maximum before the hierarchy becomes unwieldy.

## Anti-Patterns to Avoid

### Too Flat

```python
# BAD: Everything inherits from base, no grouping
class UserNotFoundError(AppError): ...
class ProductNotFoundError(AppError): ...
class OrderNotFoundError(AppError): ...
# Can't catch "all not found" errors together
```

### Too Deep

```python
# BAD: Excessive nesting
class AppError(Exception): ...
class DataError(AppError): ...
class PersistenceError(DataError): ...
class DatabaseError(PersistenceError): ...
class PostgresError(DatabaseError): ...
class PostgresConnectionError(PostgresError): ...
# Callers don't know which level to catch
```

### Too Generic

```python
# BAD: One error class with a type field
class AppError(Exception):
    def __init__(self, error_type: str, message: str): ...

# Forces string comparison instead of type-based catching
if error.error_type == "NOT_FOUND":  # fragile
```

## Full Implementation Examples

### Python Complete Hierarchy

```python
from datetime import datetime
from typing import Any, Optional

class AppError(Exception):
    """Base application error."""
    status_code: int = 500

    def __init__(self, message: str, code: str = "INTERNAL_ERROR",
                 details: dict = None):
        super().__init__(message)
        self.code = code
        self.details = details or {}
        self.timestamp = datetime.utcnow().isoformat()

    def to_dict(self) -> dict:
        return {
            "error": self.code,
            "message": str(self),
            "details": self.details,
            "timestamp": self.timestamp,
        }


class ClientError(AppError):
    """Errors caused by the caller."""
    status_code = 400


class ValidationError(ClientError):
    """Input validation failures."""
    def __init__(self, message: str, field: str = None, **kwargs):
        details = kwargs.pop("details", {})
        if field:
            details["field"] = field
        super().__init__(message, code="VALIDATION_ERROR", details=details, **kwargs)


class NotFoundError(ClientError):
    """Resource not found."""
    status_code = 404

    def __init__(self, resource: str, resource_id: Any):
        super().__init__(
            f"{resource} not found",
            code="NOT_FOUND",
            details={"resource": resource, "id": str(resource_id)},
        )


class ConflictError(ClientError):
    """Resource state conflict (duplicate, version mismatch)."""
    status_code = 409

    def __init__(self, message: str, **kwargs):
        super().__init__(message, code="CONFLICT", **kwargs)


class AuthenticationError(ClientError):
    """Caller identity unknown."""
    status_code = 401

    def __init__(self, message: str = "Authentication required"):
        super().__init__(message, code="UNAUTHENTICATED")


class AuthorizationError(ClientError):
    """Caller lacks permission."""
    status_code = 403

    def __init__(self, message: str = "Permission denied", action: str = None):
        details = {"action": action} if action else {}
        super().__init__(message, code="FORBIDDEN", details=details)


class ExternalServiceError(AppError):
    """Dependency service failures."""
    status_code = 502

    def __init__(self, message: str, service: str, **kwargs):
        details = kwargs.pop("details", {})
        details["service"] = service
        super().__init__(message, code="EXTERNAL_ERROR", details=details, **kwargs)


class RateLimitError(ExternalServiceError):
    """Rate limit exceeded on external service."""
    status_code = 429

    def __init__(self, service: str, retry_after: Optional[int] = None):
        details = {}
        if retry_after:
            details["retry_after_seconds"] = retry_after
        super().__init__(f"Rate limited by {service}", service=service, details=details)
```

### TypeScript Complete Hierarchy

```typescript
abstract class AppError extends Error {
  abstract readonly statusCode: number;
  abstract readonly code: string;

  constructor(
    message: string,
    public readonly details: Record<string, unknown> = {},
  ) {
    super(message);
    this.name = this.constructor.name;
    Object.setPrototypeOf(this, new.target.prototype);
  }

  toJSON() {
    return {
      error: this.code,
      message: this.message,
      details: this.details,
    };
  }
}

// --- Client Errors ---

class ValidationError extends AppError {
  readonly statusCode = 400;
  readonly code = "VALIDATION_ERROR";

  constructor(message: string, field?: string) {
    super(message, field ? { field } : {});
  }
}

class NotFoundError extends AppError {
  readonly statusCode = 404;
  readonly code = "NOT_FOUND";

  constructor(resource: string, id: string | number) {
    super(`${resource} not found`, { resource, id });
  }
}

class ConflictError extends AppError {
  readonly statusCode = 409;
  readonly code = "CONFLICT";
}

class AuthenticationError extends AppError {
  readonly statusCode = 401;
  readonly code = "UNAUTHENTICATED";

  constructor(message = "Authentication required") {
    super(message);
  }
}

class AuthorizationError extends AppError {
  readonly statusCode = 403;
  readonly code = "FORBIDDEN";

  constructor(message = "Permission denied", action?: string) {
    super(message, action ? { action } : {});
  }
}

// --- External Errors ---

class ExternalServiceError extends AppError {
  readonly statusCode = 502;
  readonly code = "EXTERNAL_ERROR";

  constructor(message: string, public readonly service: string) {
    super(message, { service });
  }
}

// --- Usage with Express middleware ---

function errorHandler(err: Error, req: Request, res: Response, next: NextFunction) {
  if (err instanceof AppError) {
    res.status(err.statusCode).json(err.toJSON());
  } else {
    console.error("Unhandled error:", err);
    res.status(500).json({ error: "INTERNAL_ERROR", message: "An unexpected error occurred" });
  }
}
```

## Go Custom Error Hierarchy via Interfaces

Go uses interfaces and sentinel errors rather than class hierarchies.

```go
// Categorize errors by behavior, not inheritance
type NotFounder interface {
    error
    IsNotFound() bool
}

type Validator interface {
    error
    ValidationErrors() map[string]string
}

type Retryable interface {
    error
    IsRetryable() bool
    RetryAfter() time.Duration
}

// Concrete types implement relevant interfaces
type NotFoundError struct {
    Resource string
    ID       string
}

func (e *NotFoundError) Error() string {
    return fmt.Sprintf("%s %s not found", e.Resource, e.ID)
}

func (e *NotFoundError) IsNotFound() bool { return true }

// Check by interface at catch site
func handleError(err error) {
    var nf NotFounder
    if errors.As(err, &nf) && nf.IsNotFound() {
        // handle not found
        return
    }
    var r Retryable
    if errors.As(err, &r) && r.IsRetryable() {
        time.Sleep(r.RetryAfter())
        // retry
        return
    }
}
```

## Mapping Errors to HTTP Status Codes

| Error Category     | HTTP Status | When to Use                           |
|--------------------|-------------|---------------------------------------|
| ValidationError    | 400         | Bad input, missing fields             |
| AuthenticationError| 401         | No credentials or invalid credentials |
| AuthorizationError | 403         | Valid user, insufficient permissions   |
| NotFoundError      | 404         | Resource does not exist               |
| ConflictError      | 409         | Duplicate, version conflict           |
| RateLimitError     | 429         | Too many requests                     |
| InternalError      | 500         | Bugs, unexpected failures             |
| ExternalServiceError| 502        | Upstream dependency failure           |
| TimeoutError       | 504         | Upstream timeout                      |

## Checklist for Designing Your Hierarchy

1. Start with a single base error class with `code`, `message`, `details`
2. Add category errors (Client, External, Internal) at tier 1
3. Add specific errors under categories only when catch-site behavior differs
4. Keep depth to 2 levels (3 max)
5. Include serialization (toJSON / to_dict) on the base class
6. Map each error to an HTTP status code if building APIs
7. Provide a factory or helper for wrapping unknown errors
8. Document which errors each public function can raise/return
