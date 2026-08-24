# Error Recovery Strategies

Practical patterns for recovering from failures gracefully across different scenarios: network calls, database operations, file I/O, and distributed systems.

## Strategy Selection Guide

| Failure Type           | Primary Strategy       | Fallback Strategy     |
|------------------------|------------------------|-----------------------|
| Transient network      | Retry with backoff     | Circuit breaker       |
| Service degradation    | Circuit breaker        | Graceful degradation  |
| Invalid input          | Validation + reject    | Default values        |
| Resource exhaustion    | Backpressure           | Shed load             |
| Data corruption        | Compensating action    | Manual intervention   |
| Timeout                | Retry with shorter TTL | Cached/stale response |
| Rate limit             | Respect Retry-After    | Queue for later       |

## Pattern 1: Retry with Exponential Backoff and Jitter

### When to Use

- Transient failures (network blips, temporary unavailability)
- Idempotent operations only (safe to repeat)
- Short-lived outages expected

### When NOT to Use

- Non-idempotent operations (payments, emails) without idempotency keys
- Validation errors (retrying won't help)
- Authentication failures (credentials won't change)

### Python Implementation

```python
import random
import time
from functools import wraps
from typing import Callable, Tuple, Type

def retry(
    max_attempts: int = 3,
    base_delay: float = 1.0,
    max_delay: float = 60.0,
    exponential_base: float = 2.0,
    jitter: bool = True,
    retryable_exceptions: Tuple[Type[Exception], ...] = (Exception,),
    on_retry: Callable = None,
):
    """Retry with exponential backoff and optional jitter."""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            last_exception = None
            for attempt in range(1, max_attempts + 1):
                try:
                    return func(*args, **kwargs)
                except retryable_exceptions as e:
                    last_exception = e
                    if attempt == max_attempts:
                        raise

                    delay = min(base_delay * (exponential_base ** (attempt - 1)), max_delay)
                    if jitter:
                        delay = delay * (0.5 + random.random())

                    if on_retry:
                        on_retry(attempt, delay, e)

                    time.sleep(delay)
            raise last_exception
        return wrapper
    return decorator

# Usage
@retry(
    max_attempts=4,
    retryable_exceptions=(ConnectionError, TimeoutError),
    on_retry=lambda attempt, delay, err: logger.warning(
        f"Retry {attempt}, waiting {delay:.1f}s: {err}"
    ),
)
def call_external_api(endpoint: str) -> dict:
    resp = requests.get(endpoint, timeout=5)
    resp.raise_for_status()
    return resp.json()
```

### TypeScript Implementation

```typescript
interface RetryOptions {
  maxAttempts?: number;
  baseDelay?: number;
  maxDelay?: number;
  jitter?: boolean;
  isRetryable?: (error: Error) => boolean;
  onRetry?: (attempt: number, delay: number, error: Error) => void;
}

async function withRetry<T>(
  fn: () => Promise<T>,
  options: RetryOptions = {},
): Promise<T> {
  const {
    maxAttempts = 3,
    baseDelay = 1000,
    maxDelay = 60000,
    jitter = true,
    isRetryable = () => true,
    onRetry,
  } = options;

  let lastError: Error;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error as Error;
      if (attempt === maxAttempts || !isRetryable(lastError)) {
        throw lastError;
      }

      let delay = Math.min(baseDelay * 2 ** (attempt - 1), maxDelay);
      if (jitter) {
        delay = delay * (0.5 + Math.random());
      }

      onRetry?.(attempt, delay, lastError);
      await new Promise((r) => setTimeout(r, delay));
    }
  }
  throw lastError!;
}

// Usage
const data = await withRetry(() => fetch("/api/data").then((r) => r.json()), {
  maxAttempts: 3,
  isRetryable: (err) => err.message.includes("network") || err.message.includes("timeout"),
  onRetry: (attempt, delay) => console.warn(`Retry ${attempt}, delay ${delay}ms`),
});
```

### Go Implementation

```go
type RetryConfig struct {
    MaxAttempts int
    BaseDelay  time.Duration
    MaxDelay   time.Duration
    Jitter     bool
    IsRetryable func(error) bool
}

func WithRetry[T any](fn func() (T, error), cfg RetryConfig) (T, error) {
    var lastErr error
    var zero T

    for attempt := 1; attempt <= cfg.MaxAttempts; attempt++ {
        result, err := fn()
        if err == nil {
            return result, nil
        }
        lastErr = err

        if attempt == cfg.MaxAttempts {
            break
        }
        if cfg.IsRetryable != nil && !cfg.IsRetryable(err) {
            break
        }

        delay := cfg.BaseDelay * time.Duration(1<<uint(attempt-1))
        if delay > cfg.MaxDelay {
            delay = cfg.MaxDelay
        }
        if cfg.Jitter {
            delay = time.Duration(float64(delay) * (0.5 + rand.Float64()))
        }
        time.Sleep(delay)
    }
    return zero, fmt.Errorf("all %d attempts failed: %w", cfg.MaxAttempts, lastErr)
}
```

## Pattern 2: Circuit Breaker

### States

```
CLOSED  ──(failures >= threshold)──>  OPEN
   ^                                    │
   │                              (timeout expires)
   │                                    v
   └──(successes >= threshold)──  HALF_OPEN
```

- **CLOSED**: Normal operation. Count failures. Trip to OPEN when threshold exceeded.
- **OPEN**: Reject all calls immediately. After timeout, move to HALF_OPEN.
- **HALF_OPEN**: Allow limited calls through. If they succeed, go CLOSED. If they fail, go OPEN.

### Python Implementation

```python
import threading
from datetime import datetime, timedelta
from enum import Enum

class State(Enum):
    CLOSED = "closed"
    OPEN = "open"
    HALF_OPEN = "half_open"

class CircuitBreaker:
    def __init__(self, failure_threshold=5, recovery_timeout=30, success_threshold=2):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = timedelta(seconds=recovery_timeout)
        self.success_threshold = success_threshold
        self._state = State.CLOSED
        self._failure_count = 0
        self._success_count = 0
        self._last_failure = None
        self._lock = threading.Lock()

    @property
    def state(self) -> State:
        with self._lock:
            if self._state == State.OPEN and self._last_failure:
                if datetime.now() - self._last_failure > self.recovery_timeout:
                    self._state = State.HALF_OPEN
                    self._success_count = 0
            return self._state

    def execute(self, func, *args, **kwargs):
        current = self.state
        if current == State.OPEN:
            raise CircuitOpenError(
                f"Circuit is open, retry after {self.recovery_timeout.seconds}s"
            )

        try:
            result = func(*args, **kwargs)
            self._on_success()
            return result
        except Exception as e:
            self._on_failure()
            raise

    def _on_success(self):
        with self._lock:
            self._failure_count = 0
            if self._state == State.HALF_OPEN:
                self._success_count += 1
                if self._success_count >= self.success_threshold:
                    self._state = State.CLOSED

    def _on_failure(self):
        with self._lock:
            self._failure_count += 1
            self._last_failure = datetime.now()
            if self._failure_count >= self.failure_threshold:
                self._state = State.OPEN

class CircuitOpenError(Exception):
    pass
```

### TypeScript Implementation

```typescript
enum CircuitState {
  Closed,
  Open,
  HalfOpen,
}

class CircuitBreaker {
  private state = CircuitState.Closed;
  private failureCount = 0;
  private successCount = 0;
  private lastFailure: number | null = null;

  constructor(
    private failureThreshold = 5,
    private recoveryTimeoutMs = 30_000,
    private successThreshold = 2,
  ) {}

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    this.checkState();
    if (this.state === CircuitState.Open) {
      throw new Error("Circuit breaker is open");
    }

    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  private checkState(): void {
    if (
      this.state === CircuitState.Open &&
      this.lastFailure &&
      Date.now() - this.lastFailure > this.recoveryTimeoutMs
    ) {
      this.state = CircuitState.HalfOpen;
      this.successCount = 0;
    }
  }

  private onSuccess(): void {
    this.failureCount = 0;
    if (this.state === CircuitState.HalfOpen) {
      this.successCount++;
      if (this.successCount >= this.successThreshold) {
        this.state = CircuitState.Closed;
      }
    }
  }

  private onFailure(): void {
    this.failureCount++;
    this.lastFailure = Date.now();
    if (this.failureCount >= this.failureThreshold) {
      this.state = CircuitState.Open;
    }
  }
}
```

## Pattern 3: Graceful Degradation with Fallback Chain

Provide reduced functionality instead of total failure.

### Python Implementation

```python
from typing import Callable, List, Optional, TypeVar

T = TypeVar("T")

class FallbackChain:
    """Try a series of strategies, returning the first successful result."""

    def __init__(self, strategies: List[Callable[[], T]], default: T = None):
        self.strategies = strategies
        self.default = default

    def execute(self) -> Optional[T]:
        errors = []
        for i, strategy in enumerate(self.strategies):
            try:
                result = strategy()
                if result is not None:
                    return result
            except Exception as e:
                errors.append((i, e))
                continue

        if self.default is not None:
            return self.default

        raise FallbackExhaustedError(
            f"All {len(self.strategies)} strategies failed",
            errors=errors,
        )

# Usage
def get_product_price(product_id: str) -> float:
    chain = FallbackChain(
        strategies=[
            lambda: cache.get(f"price:{product_id}"),        # 1. cache
            lambda: pricing_service.get_price(product_id),   # 2. service
            lambda: db.query_price(product_id),              # 3. database
        ],
        default=0.0,
    )
    return chain.execute()
```

## Pattern 4: Bulkhead (Failure Isolation)

Isolate failures so one misbehaving dependency cannot exhaust all resources.

```python
import threading
from concurrent.futures import ThreadPoolExecutor

class Bulkhead:
    """Limit concurrent access to a resource."""

    def __init__(self, name: str, max_concurrent: int = 10, max_queue: int = 20):
        self.name = name
        self._semaphore = threading.Semaphore(max_concurrent)
        self._executor = ThreadPoolExecutor(
            max_workers=max_concurrent,
            thread_name_prefix=f"bulkhead-{name}",
        )
        self._queue_semaphore = threading.Semaphore(max_queue)

    def execute(self, func, *args, timeout: float = 30, **kwargs):
        if not self._queue_semaphore.acquire(blocking=False):
            raise BulkheadFullError(f"Bulkhead '{self.name}' queue is full")

        try:
            if not self._semaphore.acquire(timeout=timeout):
                raise BulkheadFullError(f"Bulkhead '{self.name}' is at capacity")
            try:
                return func(*args, **kwargs)
            finally:
                self._semaphore.release()
        finally:
            self._queue_semaphore.release()

# Usage: isolate payment service from inventory service
payment_bulkhead = Bulkhead("payment", max_concurrent=5)
inventory_bulkhead = Bulkhead("inventory", max_concurrent=10)

def process_order(order):
    payment = payment_bulkhead.execute(payment_service.charge, order.total)
    stock = inventory_bulkhead.execute(inventory_service.reserve, order.items)
    return payment, stock
```

## Pattern 5: Timeout with Cancellation

```python
import signal
from contextlib import contextmanager

@contextmanager
def timeout(seconds: float, message: str = "Operation timed out"):
    """Context manager that raises TimeoutError after given seconds."""
    def handler(signum, frame):
        raise TimeoutError(message)

    old_handler = signal.signal(signal.SIGALRM, handler)
    signal.setitimer(signal.ITIMER_REAL, seconds)
    try:
        yield
    finally:
        signal.setitimer(signal.ITIMER_REAL, 0)
        signal.signal(signal.SIGALRM, old_handler)

# Usage
try:
    with timeout(5, "Database query too slow"):
        result = db.execute_slow_query()
except TimeoutError:
    result = cache.get_stale_result()  # fallback to stale data
```

### TypeScript AbortController Pattern

```typescript
async function fetchWithTimeout(url: string, timeoutMs: number): Promise<Response> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetch(url, { signal: controller.signal });
    return response;
  } catch (error) {
    if (error instanceof DOMException && error.name === "AbortError") {
      throw new TimeoutError(`Request to ${url} timed out after ${timeoutMs}ms`);
    }
    throw error;
  } finally {
    clearTimeout(timeoutId);
  }
}
```

### Go Context Cancellation

```go
func fetchData(ctx context.Context, url string) ([]byte, error) {
    ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel()

    req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
    if err != nil {
        return nil, fmt.Errorf("create request: %w", err)
    }

    resp, err := http.DefaultClient.Do(req)
    if err != nil {
        if ctx.Err() == context.DeadlineExceeded {
            return nil, fmt.Errorf("request timed out: %w", err)
        }
        return nil, fmt.Errorf("request failed: %w", err)
    }
    defer resp.Body.Close()

    return io.ReadAll(resp.Body)
}
```

## Pattern 6: Compensating Transaction (Saga)

When a multi-step operation partially fails, undo completed steps.

```python
class SagaStep:
    def __init__(self, action, compensation):
        self.action = action
        self.compensation = compensation

class Saga:
    def __init__(self):
        self.steps: list[SagaStep] = []
        self.completed: list[SagaStep] = []

    def add_step(self, action, compensation):
        self.steps.append(SagaStep(action, compensation))
        return self

    def execute(self):
        for step in self.steps:
            try:
                step.action()
                self.completed.append(step)
            except Exception as e:
                self._compensate()
                raise SagaFailedError(
                    f"Saga failed at step {len(self.completed) + 1}: {e}",
                    completed_steps=len(self.completed),
                ) from e

    def _compensate(self):
        for step in reversed(self.completed):
            try:
                step.compensation()
            except Exception as comp_error:
                logger.error(f"Compensation failed: {comp_error}")

# Usage
saga = Saga()
saga.add_step(
    action=lambda: payment_service.charge(order.total),
    compensation=lambda: payment_service.refund(order.total),
)
saga.add_step(
    action=lambda: inventory_service.reserve(order.items),
    compensation=lambda: inventory_service.release(order.items),
)
saga.add_step(
    action=lambda: shipping_service.schedule(order),
    compensation=lambda: shipping_service.cancel(order),
)
saga.execute()
```

## Choosing the Right Strategy

```
Is the failure transient?
├── Yes → Can the operation be retried safely (idempotent)?
│   ├── Yes → Retry with backoff
│   └── No  → Add idempotency key, then retry
└── No  → Is the failure in a dependency?
    ├── Yes → Is the dependency essential?
    │   ├── Yes → Circuit breaker + queue for later
    │   └── No  → Graceful degradation (skip or use cached)
    └── No  → Is it a multi-step operation?
        ├── Yes → Compensating transaction (saga)
        └── No  → Fail fast with clear error message
```

## Combining Strategies

In production, you typically combine multiple patterns:

```python
# Retry + Circuit Breaker + Fallback
@retry(max_attempts=2, retryable_exceptions=(ConnectionError,))
def get_recommendations(user_id: str) -> list:
    return circuit_breaker.execute(
        lambda: recommendation_service.get(user_id)
    )

def get_recommendations_safe(user_id: str) -> list:
    try:
        return get_recommendations(user_id)
    except (CircuitOpenError, ConnectionError):
        return cache.get(f"recs:{user_id}") or []  # stale cache fallback
```
