# Performance Profiling Guide

Systematic approaches to identifying and resolving performance bottlenecks across the full stack.

## Profiling Methodology

### The Golden Rule

**Measure first, optimize second.** Never optimize based on assumptions.

### Profiling Workflow

1. **Establish baseline**: Measure current performance with real workloads
2. **Set targets**: Define acceptable thresholds (e.g., p95 < 200ms)
3. **Profile**: Identify where time is actually spent
4. **Analyze**: Determine root cause of bottlenecks
5. **Optimize**: Fix the biggest bottleneck first
6. **Verify**: Confirm improvement with measurements
7. **Repeat**: Move to the next bottleneck

## CPU Profiling

### JavaScript / Node.js

#### Chrome DevTools Performance Tab

1. Open DevTools > Performance
2. Click Record (or Ctrl+Shift+E)
3. Perform the action to profile
4. Click Stop
5. Analyze the flame chart

**Reading a flame chart:**
- X-axis = time, Y-axis = call stack depth
- Wide bars = functions that took a long time
- Look for unexpectedly wide bars or deep stacks
- Yellow = scripting, purple = rendering, green = painting

#### Node.js Profiling

```bash
# V8 built-in profiler
node --prof app.js
node --prof-process isolate-0x*.log > profile.txt

# Generate flame graph with 0x
npx 0x app.js
# Opens interactive flame graph in browser

# clinic.js flame
npx clinic flame -- node app.js
```

```javascript
// Programmatic profiling with perf_hooks
const { performance, PerformanceObserver } = require("perf_hooks");

const obs = new PerformanceObserver((list) => {
  for (const entry of list.getEntries()) {
    console.log(`${entry.name}: ${entry.duration.toFixed(2)}ms`);
  }
});
obs.observe({ entryTypes: ["measure"] });

performance.mark("start");
await heavyOperation();
performance.mark("end");
performance.measure("heavyOperation", "start", "end");
```

### Python

```python
# cProfile: function-level profiling
import cProfile
import pstats
from io import StringIO

profiler = cProfile.Profile()
profiler.enable()

# ... code to profile ...

profiler.disable()
stream = StringIO()
stats = pstats.Stats(profiler, stream=stream)
stats.sort_stats("cumulative")
stats.print_stats(20)
print(stream.getvalue())

# Line-level profiling with line_profiler
# pip install line_profiler
# Decorate functions with @profile, then run:
# kernprof -l -v script.py

# py-spy: sampling profiler (no code changes needed)
# pip install py-spy
# py-spy top --pid <PID>
# py-spy record -o profile.svg --pid <PID>
```

```bash
# Flame graph from py-spy
py-spy record -o flamegraph.svg -- python app.py

# Speedscope format for web viewer
py-spy record -f speedscope -o profile.json -- python app.py
# Upload to https://www.speedscope.app/
```

### Go

```go
import (
    "os"
    "runtime/pprof"
    "testing"
)

// CPU profile in code
func main() {
    f, _ := os.Create("cpu.prof")
    pprof.StartCPUProfile(f)
    defer pprof.StopCPUProfile()

    // ... code to profile ...
}

// Benchmark tests (built-in)
func BenchmarkProcess(b *testing.B) {
    for i := 0; i < b.N; i++ {
        process(testData)
    }
}
```

```bash
# Run benchmarks
go test -bench=. -cpuprofile=cpu.prof -memprofile=mem.prof

# Analyze with pprof
go tool pprof cpu.prof
# (pprof) top 20
# (pprof) web              # Opens graph in browser
# (pprof) list functionName # Source-level annotation

# Web UI
go tool pprof -http=:8080 cpu.prof
```

## Memory Profiling

### JavaScript

```javascript
// Node.js memory tracking
function logMemory(label) {
  const usage = process.memoryUsage();
  console.log(`${label}:`, {
    rss: `${(usage.rss / 1024 / 1024).toFixed(1)}MB`,
    heapTotal: `${(usage.heapTotal / 1024 / 1024).toFixed(1)}MB`,
    heapUsed: `${(usage.heapUsed / 1024 / 1024).toFixed(1)}MB`,
    external: `${(usage.external / 1024 / 1024).toFixed(1)}MB`,
  });
}

// Heap snapshot
const v8 = require("v8");
v8.writeHeapSnapshot(); // Writes to cwd, open in Chrome DevTools

// Track object allocations
const { monitorEventLoopDelay } = require("perf_hooks");
const h = monitorEventLoopDelay({ resolution: 20 });
h.enable();
setInterval(() => {
  console.log(`Event loop delay p99: ${h.percentile(99).toFixed(0)}ms`);
  h.reset();
}, 5000);
```

#### Common JavaScript Memory Leaks

```javascript
// 1. Forgotten event listeners
element.addEventListener("click", handler);
// Fix: element.removeEventListener('click', handler);
// Or use AbortController:
const controller = new AbortController();
element.addEventListener("click", handler, { signal: controller.signal });
controller.abort(); // Removes listener

// 2. Closures retaining references
function createLeak() {
  const largeData = new Array(1000000).fill("x");
  return function () {
    // largeData is retained even if unused
    return "result";
  };
}

// 3. Global variable accumulation
const cache = {};
function process(key, data) {
  cache[key] = data; // Grows forever
}
// Fix: Use Map with size limit or WeakMap

// 4. Detached DOM nodes
const elements = [];
function addElement() {
  const el = document.createElement("div");
  document.body.appendChild(el);
  elements.push(el); // Array keeps reference even after removal
  document.body.removeChild(el);
}
```

### Python

```python
# tracemalloc: built-in memory tracing
import tracemalloc

tracemalloc.start()

# ... code that might leak ...

snapshot = tracemalloc.take_snapshot()
top_stats = snapshot.statistics('lineno')

print("Top 10 memory allocations:")
for stat in top_stats[:10]:
    print(stat)

# Compare snapshots to find leaks
snapshot1 = tracemalloc.take_snapshot()
# ... do something ...
snapshot2 = tracemalloc.take_snapshot()
top_stats = snapshot2.compare_to(snapshot1, 'lineno')
for stat in top_stats[:10]:
    print(stat)
```

```python
# objgraph: visualize object references
# pip install objgraph
import objgraph

objgraph.show_most_common_types(limit=20)
objgraph.show_growth(limit=10)          # Objects created since last call
objgraph.show_backrefs(obj, max_depth=5, filename='refs.png')
```

### Go

```go
import "runtime"

// Print memory stats
func printMemStats() {
    var m runtime.MemStats
    runtime.ReadMemStats(&m)
    fmt.Printf("Alloc: %d MB\n", m.Alloc/1024/1024)
    fmt.Printf("TotalAlloc: %d MB\n", m.TotalAlloc/1024/1024)
    fmt.Printf("Sys: %d MB\n", m.Sys/1024/1024)
    fmt.Printf("NumGC: %d\n", m.NumGC)
}
```

```bash
# Heap profile
go tool pprof http://localhost:6060/debug/pprof/heap
# (pprof) top
# (pprof) list functionName

# Allocation profile (shows all allocations, not just live)
go tool pprof -alloc_space http://localhost:6060/debug/pprof/heap
```

## Database Query Profiling

### PostgreSQL

```sql
-- Enable query timing
\timing on

-- Explain plan with actual execution stats
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT u.name, COUNT(o.id)
FROM users u
JOIN orders o ON o.user_id = u.id
WHERE u.created_at > '2024-01-01'
GROUP BY u.name;

-- Key things to look for:
-- Seq Scan on large tables (missing index?)
-- Nested Loop with high row counts (bad join strategy?)
-- Sort with high memory usage (missing index for ORDER BY?)
-- Hash Join vs Merge Join efficiency

-- Find missing indexes
SELECT schemaname, relname, seq_scan, idx_scan,
       seq_scan - idx_scan AS too_many_seq
FROM pg_stat_user_tables
WHERE seq_scan > idx_scan
ORDER BY too_many_seq DESC;

-- Identify slow queries (requires pg_stat_statements)
SELECT query,
       calls,
       round(mean_exec_time::numeric, 2) AS avg_ms,
       round(total_exec_time::numeric, 2) AS total_ms
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 20;
```

### MySQL

```sql
-- Enable slow query log
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 1;  -- queries over 1 second

-- Explain query
EXPLAIN FORMAT=TREE SELECT ...;

-- Profile specific query
SET profiling = 1;
SELECT ...;
SHOW PROFILE FOR QUERY 1;
```

## Network Profiling

### HTTP Request Timing

```javascript
// Browser: Resource Timing API
const entries = performance.getEntriesByType("resource");
entries.forEach((entry) => {
  console.log(`${entry.name}:`, {
    dns: `${entry.domainLookupEnd - entry.domainLookupStart}ms`,
    tcp: `${entry.connectEnd - entry.connectStart}ms`,
    ttfb: `${entry.responseStart - entry.requestStart}ms`,
    download: `${entry.responseEnd - entry.responseStart}ms`,
    total: `${entry.duration}ms`,
  });
});
```

```bash
# cURL timing breakdown
curl -w "\
  DNS:        %{time_namelookup}s\n\
  Connect:    %{time_connect}s\n\
  TLS:        %{time_appconnect}s\n\
  TTFB:       %{time_starttransfer}s\n\
  Total:      %{time_total}s\n\
  Size:       %{size_download} bytes\n" \
  -o /dev/null -s https://api.example.com/endpoint
```

## Web Performance Metrics

### Core Web Vitals

| Metric | Good | Needs Work | Poor |
|--------|------|-----------|------|
| LCP (Largest Contentful Paint) | < 2.5s | 2.5-4.0s | > 4.0s |
| INP (Interaction to Next Paint) | < 200ms | 200-500ms | > 500ms |
| CLS (Cumulative Layout Shift) | < 0.1 | 0.1-0.25 | > 0.25 |

```javascript
// Measure Core Web Vitals
import { onLCP, onINP, onCLS } from "web-vitals";

onLCP(console.log);
onINP(console.log);
onCLS(console.log);
```

### Lighthouse

```bash
# CLI usage
npx lighthouse https://example.com --output html --output-path report.html

# Programmatic
npx lighthouse https://example.com --output json --quiet | jq '.categories'
```

## Profiling Cheat Sheet

| Symptom | Profile Type | Tools |
|---------|-------------|-------|
| Slow page load | Network + rendering | DevTools Network/Performance, Lighthouse |
| High CPU usage | CPU profiling | flame graphs, pprof, py-spy |
| Memory growing | Memory profiling | heap snapshots, tracemalloc, pprof heap |
| Slow API response | Server profiling + DB | APM tools, EXPLAIN ANALYZE, pprof |
| UI jank/stuttering | Frame profiling | DevTools Performance, React Profiler |
| Slow database | Query profiling | EXPLAIN, slow query log, pg_stat_statements |
| Event loop blocking | Event loop monitoring | clinic doctor, perf_hooks |

## Anti-Patterns to Avoid

1. **Premature optimization**: Profile first, then optimize the measured bottleneck
2. **Micro-benchmarking without context**: A function being 10x faster matters only if it is called often enough
3. **Optimizing cold paths**: Focus on hot paths that run frequently
4. **Ignoring the 80/20 rule**: 80% of time is typically spent in 20% of code
5. **Benchmarking without warm-up**: JIT compilers need warm-up runs
6. **Testing with unrealistic data**: Use production-like data sizes and patterns
7. **Optimizing only one layer**: A fast backend does not help if the frontend is slow
