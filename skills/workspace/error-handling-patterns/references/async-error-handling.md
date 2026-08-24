# Async Error Handling

Patterns for handling errors in asynchronous and concurrent code across languages. Async errors are uniquely tricky because they can be lost silently, occur in parallel, or propagate across thread/task boundaries.

## Key Challenges

1. **Lost errors**: Unhandled promise rejections, ignored futures, detached goroutines
2. **Parallel failures**: Multiple async operations fail simultaneously
3. **Error propagation**: Moving errors across task/thread boundaries
4. **Resource cleanup**: Ensuring cleanup runs even when async code fails
5. **Cancellation**: Stopping in-flight work when an error makes it pointless

## JavaScript / TypeScript

### Promise Error Handling Fundamentals

```typescript
// DANGER: Fire-and-forget loses errors silently
doSomethingAsync(); // No .catch, no await -- error is lost

// CORRECT: Always handle the promise
await doSomethingAsync();
// or
doSomethingAsync().catch((err) => logger.error("Background task failed:", err));
```

### Async/Await Patterns

```typescript
// Pattern 1: Try-catch with async/await
async function processOrder(orderId: string): Promise<Order> {
  try {
    const order = await fetchOrder(orderId);
    const payment = await chargePayment(order);
    const confirmation = await sendConfirmation(order, payment);
    return confirmation;
  } catch (error) {
    if (error instanceof NotFoundError) {
      throw new OrderNotFoundError(orderId);
    }
    if (error instanceof PaymentError) {
      logger.error("Payment failed", { orderId, error });
      await refundIfNeeded(orderId);
      throw error;
    }
    throw error; // re-throw unexpected errors
  }
}

// Pattern 2: Error-first wrapper (avoids nested try-catch)
async function to<T>(promise: Promise<T>): Promise<[null, T] | [Error, null]> {
  try {
    const result = await promise;
    return [null, result];
  } catch (error) {
    return [error as Error, null];
  }
}

// Usage
const [err, user] = await to(fetchUser(userId));
if (err) {
  return handleUserError(err);
}
const [orderErr, orders] = await to(fetchOrders(user.id));
if (orderErr) {
  return handleOrderError(orderErr);
}
```

### Parallel Async with Error Handling

```typescript
// Promise.all: Fails fast on first error
async function fetchAllData(ids: string[]): Promise<Data[]> {
  try {
    return await Promise.all(ids.map((id) => fetchData(id)));
  } catch (error) {
    // Only get the FIRST error; other pending promises continue running
    throw new BatchFetchError("One or more fetches failed", { cause: error });
  }
}

// Promise.allSettled: Collects all results and errors
async function fetchAllDataSafe(
  ids: string[],
): Promise<{ successes: Data[]; failures: Error[] }> {
  const results = await Promise.allSettled(ids.map((id) => fetchData(id)));

  const successes: Data[] = [];
  const failures: Error[] = [];

  for (const result of results) {
    if (result.status === "fulfilled") {
      successes.push(result.value);
    } else {
      failures.push(result.reason);
    }
  }

  return { successes, failures };
}

// Promise.any: Succeeds on first success, fails only if ALL fail
async function fetchFromAnyMirror(url: string): Promise<Response> {
  try {
    return await Promise.any(
      mirrors.map((mirror) => fetch(`${mirror}${url}`)),
    );
  } catch (error) {
    // AggregateError contains all individual errors
    if (error instanceof AggregateError) {
      throw new Error(
        `All ${error.errors.length} mirrors failed: ${error.errors.map((e) => e.message).join(", ")}`,
      );
    }
    throw error;
  }
}
```

### Unhandled Rejection Safety Net

```typescript
// Global handler -- last line of defense, not a substitute for proper handling
process.on("unhandledRejection", (reason, promise) => {
  logger.error("Unhandled rejection", {
    reason: reason instanceof Error ? reason.message : String(reason),
    stack: reason instanceof Error ? reason.stack : undefined,
  });
  // In production, you may want to exit gracefully
  // process.exit(1);
});

// Browser equivalent
window.addEventListener("unhandledrejection", (event) => {
  event.preventDefault();
  errorReporter.capture(event.reason);
});
```

### Async Cleanup with AbortController

```typescript
class ManagedAsyncOperation {
  private controller = new AbortController();

  async execute(): Promise<void> {
    const { signal } = this.controller;

    try {
      const conn = await connectToService({ signal });
      try {
        await processData(conn, { signal });
      } finally {
        await conn.close(); // cleanup always runs
      }
    } catch (error) {
      if (signal.aborted) {
        // Operation was cancelled, not a real error
        return;
      }
      throw error;
    }
  }

  cancel(): void {
    this.controller.abort();
  }
}
```

## Python

### Asyncio Error Handling

```python
import asyncio
from typing import List, Tuple, Any

# Pattern 1: Basic async/await
async def fetch_user_data(user_id: str) -> dict:
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(f"/api/users/{user_id}") as resp:
                if resp.status == 404:
                    raise NotFoundError("User", user_id)
                resp.raise_for_status()
                return await resp.json()
    except aiohttp.ClientError as e:
        raise ExternalServiceError(f"HTTP request failed: {e}", service="user-api") from e

# Pattern 2: Gather with error handling
async def fetch_all_users(user_ids: List[str]) -> Tuple[list, list]:
    """Fetch multiple users, separating successes and failures."""
    tasks = [fetch_user_data(uid) for uid in user_ids]
    results = await asyncio.gather(*tasks, return_exceptions=True)

    successes = []
    failures = []
    for uid, result in zip(user_ids, results):
        if isinstance(result, Exception):
            failures.append((uid, result))
        else:
            successes.append(result)

    return successes, failures

# Pattern 3: TaskGroup (Python 3.11+) -- structured concurrency
async def process_batch(items: list) -> list:
    results = []
    async with asyncio.TaskGroup() as tg:
        tasks = [tg.create_task(process_item(item)) for item in items]
    # If ANY task fails, TaskGroup raises ExceptionGroup
    # All other tasks are cancelled automatically
    return [t.result() for t in tasks]

# Handling ExceptionGroup (Python 3.11+)
async def safe_process_batch(items: list) -> Tuple[list, list]:
    results = []
    errors = []
    try:
        async with asyncio.TaskGroup() as tg:
            tasks = [tg.create_task(process_item(item)) for item in items]
    except* ValueError as eg:
        # Handle all ValueError instances
        errors.extend(eg.exceptions)
    except* ConnectionError as eg:
        errors.extend(eg.exceptions)

    for t in tasks:
        if not t.cancelled() and t.exception() is None:
            results.append(t.result())

    return results, errors
```

### Async Context Managers for Cleanup

```python
from contextlib import asynccontextmanager

@asynccontextmanager
async def managed_connection(url: str):
    """Ensure connection is properly closed even on error."""
    conn = await connect(url)
    try:
        yield conn
    except Exception:
        await conn.rollback()
        raise
    else:
        await conn.commit()
    finally:
        await conn.close()

# Usage
async def transfer_funds(from_id: str, to_id: str, amount: float):
    async with managed_connection(DB_URL) as conn:
        await conn.execute("UPDATE accounts SET balance = balance - $1 WHERE id = $2", amount, from_id)
        await conn.execute("UPDATE accounts SET balance = balance + $1 WHERE id = $2", amount, to_id)
        # auto-commit on success, auto-rollback on exception
```

### Background Task Error Handling

```python
async def run_with_error_handling(coro, name: str = "background"):
    """Wrapper that logs errors from background tasks."""
    try:
        return await coro
    except asyncio.CancelledError:
        logger.info(f"Task '{name}' was cancelled")
        raise  # always re-raise CancelledError
    except Exception:
        logger.exception(f"Task '{name}' failed")
        raise

# Usage
task = asyncio.create_task(
    run_with_error_handling(sync_data(), name="data-sync")
)
```

## Go

### Goroutine Error Handling

```go
// Pattern 1: errgroup for parallel work with error propagation
import "golang.org/x/sync/errgroup"

func fetchAllUsers(ctx context.Context, ids []string) ([]*User, error) {
    g, ctx := errgroup.WithContext(ctx)
    users := make([]*User, len(ids))

    for i, id := range ids {
        i, id := i, id // capture loop vars
        g.Go(func() error {
            user, err := fetchUser(ctx, id)
            if err != nil {
                return fmt.Errorf("fetch user %s: %w", id, err)
            }
            users[i] = user
            return nil
        })
    }

    if err := g.Wait(); err != nil {
        return nil, err // returns first error; context cancels remaining
    }
    return users, nil
}

// Pattern 2: Channel-based error collection
func processItems(ctx context.Context, items []Item) ([]Result, []error) {
    type outcome struct {
        result Result
        err    error
        index  int
    }

    ch := make(chan outcome, len(items))

    for i, item := range items {
        go func(i int, item Item) {
            result, err := process(ctx, item)
            ch <- outcome{result: result, err: err, index: i}
        }(i, item)
    }

    results := make([]Result, len(items))
    var errs []error
    for range items {
        o := <-ch
        if o.err != nil {
            errs = append(errs, fmt.Errorf("item %d: %w", o.index, o.err))
        } else {
            results[o.index] = o.result
        }
    }
    return results, errs
}

// Pattern 3: Panic recovery in goroutines
func safeGo(fn func()) {
    go func() {
        defer func() {
            if r := recover(); r != nil {
                log.Printf("goroutine panicked: %v\n%s", r, debug.Stack())
            }
        }()
        fn()
    }()
}
```

### Context Cancellation Propagation

```go
func processWithTimeout(parentCtx context.Context, data []byte) (Result, error) {
    ctx, cancel := context.WithTimeout(parentCtx, 30*time.Second)
    defer cancel()

    resultCh := make(chan Result, 1)
    errCh := make(chan error, 1)

    go func() {
        result, err := heavyComputation(ctx, data)
        if err != nil {
            errCh <- err
            return
        }
        resultCh <- result
    }()

    select {
    case result := <-resultCh:
        return result, nil
    case err := <-errCh:
        return Result{}, err
    case <-ctx.Done():
        return Result{}, fmt.Errorf("processing timed out: %w", ctx.Err())
    }
}
```

## Rust

### Async Error Handling with Tokio

```rust
use tokio::task;

// Pattern 1: JoinSet for parallel tasks with error collection
async fn fetch_all(urls: Vec<String>) -> (Vec<Response>, Vec<AppError>) {
    let mut set = task::JoinSet::new();

    for url in urls {
        set.spawn(async move {
            fetch_url(&url).await
        });
    }

    let mut successes = Vec::new();
    let mut failures = Vec::new();

    while let Some(result) = set.join_next().await {
        match result {
            Ok(Ok(response)) => successes.push(response),
            Ok(Err(e)) => failures.push(e),
            Err(join_err) => {
                failures.push(AppError::Internal(
                    anyhow::anyhow!("Task panicked: {}", join_err)
                ));
            }
        }
    }

    (successes, failures)
}

// Pattern 2: Select for racing with timeout
use tokio::time::timeout;

async fn fetch_with_timeout(url: &str) -> Result<Response, AppError> {
    match timeout(Duration::from_secs(5), fetch_url(url)).await {
        Ok(result) => result,
        Err(_) => Err(AppError::Timeout {
            operation: format!("fetch {}", url),
            duration: Duration::from_secs(5),
        }),
    }
}

// Pattern 3: Cancellation via drop
struct ManagedTask {
    handle: task::JoinHandle<Result<(), AppError>>,
}

impl ManagedTask {
    fn new(work: impl Future<Output = Result<(), AppError>> + Send + 'static) -> Self {
        Self {
            handle: tokio::spawn(work),
        }
    }
}

impl Drop for ManagedTask {
    fn drop(&mut self) {
        self.handle.abort(); // cancel on drop
    }
}
```

### Stream Error Handling

```rust
use futures::stream::{self, StreamExt, TryStreamExt};

async fn process_stream(items: Vec<Item>) -> Result<Vec<Output>, AppError> {
    stream::iter(items)
        .map(|item| async move { process_item(item).await })
        .buffer_unordered(10)  // process up to 10 concurrently
        .try_collect()         // collect results, short-circuit on first error
        .await
}

// Collect all results, including errors
async fn process_stream_all(items: Vec<Item>) -> (Vec<Output>, Vec<AppError>) {
    let results: Vec<_> = stream::iter(items)
        .map(|item| async move { process_item(item).await })
        .buffer_unordered(10)
        .collect()
        .await;

    let mut successes = Vec::new();
    let mut failures = Vec::new();
    for result in results {
        match result {
            Ok(output) => successes.push(output),
            Err(e) => failures.push(e),
        }
    }
    (successes, failures)
}
```

## Common Async Anti-Patterns

### 1. Swallowing Errors

```typescript
// BAD: Error is silently lost
promise.catch(() => {});

// BAD: Error logged but operation appears successful
try {
  await riskyOperation();
} catch {
  console.log("something went wrong");
  // caller has no idea it failed
}

// GOOD: Re-throw or return error state
try {
  await riskyOperation();
} catch (error) {
  logger.error("Operation failed", { error });
  throw error; // or return an error result
}
```

### 2. Missing Cleanup on Cancellation

```python
# BAD: Resource leak on cancellation
async def bad_worker():
    conn = await connect()
    await do_work(conn)  # if cancelled here, conn is never closed
    await conn.close()

# GOOD: Always use try/finally or context managers
async def good_worker():
    conn = await connect()
    try:
        await do_work(conn)
    finally:
        await conn.close()
```

### 3. Unstructured Concurrency

```go
// BAD: Goroutine errors disappear
go func() {
    if err := doWork(); err != nil {
        log.Println(err) // logged but caller never knows
    }
}()

// GOOD: Use errgroup or channels to propagate errors
g, ctx := errgroup.WithContext(ctx)
g.Go(func() error {
    return doWork()
})
if err := g.Wait(); err != nil {
    // caller sees the error
}
```

### 4. Sequential When Parallel Is Safe

```typescript
// SLOW: Sequential when operations are independent
const user = await fetchUser(id);
const orders = await fetchOrders(id);
const prefs = await fetchPreferences(id);

// FAST: Parallel since they're independent
const [user, orders, prefs] = await Promise.all([
  fetchUser(id),
  fetchOrders(id),
  fetchPreferences(id),
]);
// But: if one fails, all results are lost. Use allSettled if partial results are useful.
```

## Checklist for Async Error Handling

1. Every promise/future/goroutine has an error handler
2. Background tasks log errors and optionally report to monitoring
3. Parallel operations use the right combinator (all vs allSettled vs errgroup)
4. Cleanup runs in finally/defer blocks, not after awaits
5. Cancellation is propagated (AbortController, context.Context, CancellationToken)
6. Timeouts are set on all external calls
7. Global unhandled rejection/panic handlers exist as safety nets
8. Errors from spawned tasks are collected, not lost
9. Resource cleanup handles the cancellation case
10. Tests cover error paths, not just happy paths
