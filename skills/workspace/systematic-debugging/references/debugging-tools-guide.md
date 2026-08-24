# Debugging Tools Guide

Comprehensive reference for debugging tools across languages, runtimes, and environments.

## Browser DevTools

### Chrome DevTools

**Opening**: F12, Ctrl+Shift+I, or right-click > Inspect

#### Console Panel

```javascript
// Structured logging
console.log("Simple value:", x);
console.warn("Warning: unexpected state", { state });
console.error("Failed:", error);

// Object inspection
console.dir(domElement);              // DOM element properties
console.table(arrayOfObjects);        // Tabular display
console.group("Section");             // Grouped output
console.log("detail 1");
console.groupEnd();

// Timing
console.time("fetch");
await fetchData();
console.timeEnd("fetch");             // fetch: 234.5ms

// Stack trace at any point
console.trace("How did we get here?");

// Conditional logging
console.assert(x > 0, "x must be positive, got:", x);

// Counting occurrences
console.count("render");              // render: 1, render: 2, ...
console.countReset("render");
```

#### Sources Panel

- **Breakpoints**: Click line number to set
- **Conditional breakpoints**: Right-click line > Add conditional breakpoint
- **Logpoints**: Right-click line > Add logpoint (logs without pausing)
- **DOM breakpoints**: Right-click element > Break on subtree/attribute/removal
- **XHR breakpoints**: Break on specific URL patterns
- **Event listener breakpoints**: Break on click, keyboard, timer events

**Watch expressions**: Add expressions to monitor in real time.

**Call stack**: Inspect the chain of function calls that led to the current point.

**Scope**: Examine local, closure, and global variables at the breakpoint.

#### Network Panel

- Filter by type: XHR, JS, CSS, Img, Media, Font, Doc, WS
- Throttle network: Simulate 3G, offline, custom speeds
- Block requests: Right-click > Block request URL
- Replay XHR: Right-click > Replay XHR
- Copy as cURL/fetch: Right-click > Copy

#### Performance Panel

1. Click Record
2. Perform the action
3. Click Stop
4. Analyze the flame chart, summary, and call tree

Key metrics: Scripting time, rendering time, painting time, idle time.

#### Memory Panel

- **Heap snapshot**: Capture current memory allocation
- **Allocation timeline**: Track allocations over time
- **Allocation sampling**: Low-overhead profiling

Workflow for finding leaks:
1. Take snapshot A
2. Perform suspected leaking action
3. Take snapshot B
4. Compare: Objects allocated between A and B
5. Look for objects that should have been garbage collected

### Firefox DevTools

Similar to Chrome with some unique features:
- **CSS Grid/Flexbox inspector**: Visual layout debugging
- **Accessibility inspector**: Built-in a11y tree view
- **Network > Edit and Resend**: Modify and replay requests
- **Storage inspector**: Unified cookies/localStorage/sessionStorage view

## Node.js Debugging

### Built-in Inspector

```bash
# Start with inspector
node --inspect src/index.js

# Break on first line
node --inspect-brk src/index.js

# Connect via Chrome: chrome://inspect
# Or VS Code: attach to process
```

### VS Code Debugger

```jsonc
// .vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Launch Program",
      "type": "node",
      "request": "launch",
      "program": "${workspaceFolder}/src/index.ts",
      "outFiles": ["${workspaceFolder}/dist/**/*.js"],
      "sourceMaps": true,
      "skipFiles": ["<node_internals>/**", "node_modules/**"]
    },
    {
      "name": "Attach to Process",
      "type": "node",
      "request": "attach",
      "port": 9229,
      "restart": true
    },
    {
      "name": "Debug Jest Tests",
      "type": "node",
      "request": "launch",
      "runtimeExecutable": "${workspaceFolder}/node_modules/.bin/jest",
      "args": ["--runInBand", "--no-cache", "--watchAll=false"],
      "console": "integratedTerminal",
      "windows": {
        "runtimeExecutable": "${workspaceFolder}/node_modules/.bin/jest.cmd"
      }
    },
    {
      "name": "Debug Current File",
      "type": "node",
      "request": "launch",
      "program": "${file}",
      "skipFiles": ["<node_internals>/**"]
    }
  ]
}
```

### Diagnostic Tools

```bash
# Node.js built-in diagnostics
node --prof app.js                    # V8 CPU profiler
node --prof-process isolate-*.log     # Process profile output

# Heap dump
node --heapsnapshot-signal=SIGUSR2 app.js
kill -USR2 <pid>                      # Trigger heap snapshot

# Trace warnings
node --trace-warnings app.js

# Trace deprecations
node --trace-deprecation app.js
```

### clinic.js Suite

```bash
npm install -g clinic

# CPU profiling with flame graphs
clinic flame -- node app.js

# Event loop analysis
clinic doctor -- node app.js

# I/O bottleneck detection
clinic bubbleprof -- node app.js
```

## Python Debugging

### pdb / ipdb

```python
# Standard debugger
import pdb; pdb.set_trace()

# Python 3.7+ shorthand
breakpoint()

# Remote debugging
import pdb; pdb.Pdb(stdout=open('/tmp/debug.log','w')).set_trace()

# Post-mortem on unhandled exceptions
python -m pdb script.py
```

**pdb commands:**

| Command | Action |
|---------|--------|
| `n` | Next line (step over) |
| `s` | Step into function |
| `c` | Continue to next breakpoint |
| `r` | Return from current function |
| `l` | List source around current line |
| `ll` | List full source of current function |
| `p expr` | Print expression value |
| `pp expr` | Pretty-print expression |
| `w` | Print stack trace |
| `u` / `d` | Move up/down the stack |
| `b N` | Set breakpoint at line N |
| `cl N` | Clear breakpoint at line N |
| `commands N` | Execute commands when breakpoint N hit |

### VS Code Python Debugger

```jsonc
// .vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Python: Current File",
      "type": "debugpy",
      "request": "launch",
      "program": "${file}",
      "console": "integratedTerminal",
      "justMyCode": false
    },
    {
      "name": "Python: Django",
      "type": "debugpy",
      "request": "launch",
      "program": "${workspaceFolder}/manage.py",
      "args": ["runserver", "--noreload"],
      "django": true
    },
    {
      "name": "Python: FastAPI",
      "type": "debugpy",
      "request": "launch",
      "module": "uvicorn",
      "args": ["main:app", "--reload", "--port", "8000"]
    },
    {
      "name": "Python: Pytest",
      "type": "debugpy",
      "request": "launch",
      "module": "pytest",
      "args": ["-xvs", "${file}"]
    }
  ]
}
```

## Go Debugging

### Delve

```bash
# Install
go install github.com/go-delve/delve/cmd/dlv@latest

# Debug a program
dlv debug main.go

# Debug tests
dlv test ./...

# Attach to running process
dlv attach <pid>

# Core dump analysis
dlv core <executable> <core-dump>
```

**Delve commands:**

| Command | Action |
|---------|--------|
| `break main.go:42` | Set breakpoint |
| `condition 1 x > 5` | Conditional breakpoint |
| `continue` | Run to next breakpoint |
| `next` | Step over |
| `step` | Step into |
| `stepout` | Step out of function |
| `print x` | Print variable |
| `locals` | List local variables |
| `goroutines` | List goroutines |
| `goroutine 5` | Switch to goroutine 5 |
| `stack` | Print stack trace |

### Built-in Profiling

```go
import (
    "net/http"
    _ "net/http/pprof"
)

// Add to main:
go func() {
    http.ListenAndServe(":6060", nil)
}()

// Then access:
// http://localhost:6060/debug/pprof/
// http://localhost:6060/debug/pprof/goroutine?debug=2
```

```bash
# Analyze profiles
go tool pprof http://localhost:6060/debug/pprof/profile?seconds=30
go tool pprof http://localhost:6060/debug/pprof/heap
go tool pprof -http=:8080 cpu.prof    # Web UI
```

## Rust Debugging

### LLDB / GDB

```bash
# Compile with debug symbols (default in debug builds)
cargo build

# Debug with lldb
rust-lldb target/debug/myapp

# Debug with gdb
rust-gdb target/debug/myapp
```

### VS Code with CodeLLDB

```jsonc
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug Rust",
      "type": "lldb",
      "request": "launch",
      "program": "${workspaceFolder}/target/debug/${workspaceFolderBasename}",
      "args": [],
      "cwd": "${workspaceFolder}",
      "sourceLanguages": ["rust"]
    },
    {
      "name": "Debug Rust Tests",
      "type": "lldb",
      "request": "launch",
      "cargo": { "args": ["test", "--no-run"] },
      "args": [],
      "cwd": "${workspaceFolder}"
    }
  ]
}
```

## Command-Line Debugging Tools

### System-Level

```bash
# Trace system calls
strace -f -e trace=network ./app      # Linux: network calls
strace -c ./app                       # Linux: syscall summary
dtruss ./app                          # macOS equivalent

# File descriptor monitoring
lsof -p <pid>                         # Open files/sockets
lsof -i :8080                         # What's using port 8080

# Process inspection
ps aux | grep myapp                   # Process details
top -p <pid>                          # Resource usage
htop                                  # Interactive process viewer

# Network debugging
netstat -tlnp                         # Listening ports
ss -tlnp                              # Modern netstat
tcpdump -i any port 8080              # Packet capture
curl -v https://api.example.com       # Verbose HTTP
```

### Log Analysis

```bash
# Follow logs in real time
tail -f /var/log/app.log

# Search logs
grep -r "ERROR" /var/log/app/ --include="*.log"

# Structured log parsing (with jq)
cat app.log | jq 'select(.level == "error")'
cat app.log | jq 'select(.timestamp > "2024-01-01") | .message'

# Log aggregation
journalctl -u myservice -f            # systemd service logs
docker logs -f --tail 100 container   # Docker container logs
kubectl logs -f pod/myapp             # Kubernetes pod logs
```

## Database Debugging

```sql
-- PostgreSQL: analyze query performance
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'test@test.com';

-- Show running queries
SELECT pid, query, state, wait_event_type
FROM pg_stat_activity
WHERE state = 'active';

-- Find slow queries
SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Lock analysis
SELECT * FROM pg_locks WHERE NOT granted;
```

```bash
# Redis debugging
redis-cli MONITOR                     # Watch all commands
redis-cli SLOWLOG GET 10              # Slow commands
redis-cli INFO memory                 # Memory stats
```

## Choosing the Right Tool

| Problem Type | First Tool | Second Tool | Third Tool |
|-------------|-----------|-------------|------------|
| UI rendering bug | Browser DevTools (Elements) | React/Vue DevTools | Lighthouse |
| API error | Network panel | curl/Postman | Server logs |
| Performance slow | Profiler (CPU) | Network panel | Database EXPLAIN |
| Memory leak | Memory panel (heap) | process.memoryUsage() | Heap snapshots |
| Race condition | Logging with timestamps | Debugger | Stress testing |
| Crash/exception | Stack trace + debugger | Error tracking (Sentry) | Core dump |
| Wrong output | Debugger (step through) | Unit tests | Print/log values |
| Intermittent failure | Extensive logging | Stress testing | Monitoring |
