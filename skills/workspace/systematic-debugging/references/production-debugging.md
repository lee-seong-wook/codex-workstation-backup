# Production Debugging Guide

Strategies and practices for safely investigating and resolving issues in live production systems.

## Core Principles

### Safety First

1. **Never experiment on production** without a rollback plan
2. **Avoid making changes** directly on production servers
3. **Prefer observing** (logs, metrics, traces) over interacting
4. **Test fixes in staging** before applying to production
5. **Communicate** with your team before and during investigation

### The OODA Loop for Production Issues

1. **Observe**: What symptoms are visible? What do metrics show?
2. **Orient**: How severe is this? Who is affected? What changed recently?
3. **Decide**: Mitigate first or investigate? Roll back or fix forward?
4. **Act**: Execute the decided course of action

## Incident Response Workflow

### Phase 1: Triage (First 5 Minutes)

```markdown
## Triage Checklist

1. **Severity assessment**
   - How many users affected?
   - Is data being corrupted?
   - Is revenue being lost?
   - Is there a security exposure?

2. **Impact scope**
   - Single endpoint or system-wide?
   - One region or all regions?
   - Intermittent or constant?

3. **Quick checks**
   - Recent deployments? (check deploy log)
   - Infrastructure alerts? (check monitoring)
   - Dependent service outages? (check status pages)
   - Traffic spike? (check load balancer metrics)
```

### Phase 2: Mitigate (Minutes 5-15)

**Goal: Stop the bleeding before finding the root cause.**

```markdown
## Mitigation Options (fastest to slowest)

1. **Rollback deployment** (if recent deploy)
   - git revert + redeploy
   - Feature flag toggle off
   - Container image rollback

2. **Scale resources** (if capacity issue)
   - Increase replicas
   - Scale up instances
   - Enable auto-scaling

3. **Circuit break** (if dependency failure)
   - Enable circuit breakers
   - Switch to fallback/cache
   - Disable non-critical features

4. **Traffic management**
   - Rate limiting
   - Redirect to maintenance page
   - Block problematic traffic patterns

5. **Data fix** (if data corruption)
   - Stop writes to affected tables
   - Restore from backup
   - Apply corrective migration
```

### Phase 3: Investigate (After Mitigation)

```markdown
## Investigation Sources

1. **Application logs**
   - Error logs with stack traces
   - Request/response logs
   - Audit logs

2. **Metrics**
   - Error rate trends
   - Latency percentiles (p50, p95, p99)
   - Throughput changes
   - Resource utilization (CPU, memory, disk, network)

3. **Traces**
   - Distributed traces for slow/failed requests
   - Span timing breakdown
   - Cross-service call chains

4. **Infrastructure**
   - Host-level metrics
   - Container/pod status
   - Network connectivity
   - DNS resolution
   - Certificate expiration

5. **External factors**
   - Dependent service status
   - Cloud provider incidents
   - DNS/CDN issues
   - Traffic pattern changes
```

## Observability Tools

### Structured Logging

```python
# Python: structured logging with context
import structlog
import logging

structlog.configure(
    processors=[
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.add_log_level,
        structlog.processors.JSONRenderer()
    ]
)
logger = structlog.get_logger()

def process_order(order_id, user_id):
    log = logger.bind(order_id=order_id, user_id=user_id)
    log.info("processing_order_started")

    try:
        result = charge_payment(order_id)
        log.info("payment_charged", amount=result.amount)
    except PaymentError as e:
        log.error("payment_failed", error=str(e), error_type=type(e).__name__)
        raise
```

```javascript
// Node.js: structured logging with pino
const pino = require("pino");
const logger = pino({ level: "info" });

function processRequest(req) {
  const log = logger.child({ requestId: req.id, userId: req.userId });
  log.info({ path: req.path, method: req.method }, "request_received");

  try {
    const result = handleRequest(req);
    log.info({ statusCode: 200, durationMs: result.duration }, "request_completed");
  } catch (err) {
    log.error({ err, statusCode: 500 }, "request_failed");
    throw err;
  }
}
```

### Log Querying Patterns

```bash
# Search for errors in a time window
# CloudWatch Logs Insights
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100

# Elasticsearch / Kibana (KQL)
level: "error" AND service: "payment-api" AND @timestamp >= "2024-01-15T10:00:00"

# Datadog logs
service:payment-api status:error @duration:>5000

# grep on log files (when no log aggregation available)
grep -h "ERROR" /var/log/app/*.log | sort | uniq -c | sort -rn | head -20
```

### Metrics to Monitor

```markdown
## RED Method (for request-driven services)

- **Rate**: Requests per second
- **Errors**: Failed requests per second
- **Duration**: Distribution of request latency (p50, p95, p99)

## USE Method (for resources like CPU, memory, disk)

- **Utilization**: % time resource is busy
- **Saturation**: Queue length or degree of extra work
- **Errors**: Count of error events

## The Four Golden Signals (Google SRE)

1. **Latency**: Time to serve a request
2. **Traffic**: Demand on the system (requests/sec)
3. **Errors**: Rate of failed requests
4. **Saturation**: How full the system is (CPU, memory, I/O)
```

## Common Production Issues

### 1. Memory Leaks

**Symptoms**: Memory usage growing over time, eventual OOM kills, increasing GC pauses.

**Investigation:**

```bash
# Check container/process memory over time
kubectl top pods --sort-by=memory
docker stats --no-stream

# Node.js: generate heap snapshot from running process
kill -USR2 <pid>    # If started with --heapsnapshot-signal=SIGUSR2

# Java: heap dump
jmap -dump:format=b,file=heap.hprof <pid>

# Python: memory profiling in production
# Use memray for low-overhead production profiling
python -m memray run --output profile.bin app.py
python -m memray flamegraph profile.bin
```

**Common causes:**
- Unbounded caches or maps
- Event listener accumulation
- Circular references preventing GC
- Large objects in closures
- Connection pool exhaustion

### 2. Connection/Resource Exhaustion

**Symptoms**: Timeouts, connection refused errors, hanging requests.

```bash
# Check open connections
ss -s                                  # Connection summary
ss -tnp | grep <port> | wc -l         # Connections to specific port
lsof -i -P -n | grep <pid>            # Open files/sockets for process

# Check file descriptors
ls /proc/<pid>/fd | wc -l             # Current FD count
cat /proc/<pid>/limits | grep "open files"  # FD limit

# PostgreSQL: check connections
psql -c "SELECT count(*) FROM pg_stat_activity;"
psql -c "SELECT state, count(*) FROM pg_stat_activity GROUP BY state;"
```

**Common causes:**
- Connection pool misconfiguration (too small or not closing)
- Missing connection timeouts
- Leaked database connections in error paths
- DNS resolution failures causing connection buildup

### 3. Cascading Failures

**Symptoms**: One service failure causes others to fail. Retry storms. Timeout propagation.

**Mitigations:**

```markdown
## Circuit Breaker Pattern

- Monitor failure rate for downstream calls
- When failure rate exceeds threshold, open circuit
- Reject requests immediately instead of waiting for timeout
- Periodically allow test requests to check recovery
- Close circuit when downstream recovers

## Bulkhead Pattern

- Isolate resources per dependency
- Separate thread pools / connection pools per service
- Prevent one slow dependency from consuming all resources

## Timeout Strategy

- Set timeouts at every network boundary
- Use deadline propagation (total budget minus elapsed time)
- Timeout hierarchy: client > gateway > service > database
```

### 4. Slow Queries Under Load

**Symptoms**: Latency spikes during peak traffic, database CPU high.

```sql
-- PostgreSQL: find currently running slow queries
SELECT pid, now() - pg_stat_activity.query_start AS duration, query, state
FROM pg_stat_activity
WHERE (now() - pg_stat_activity.query_start) > interval '5 seconds'
AND state != 'idle';

-- Kill a long-running query (use with caution)
SELECT pg_cancel_backend(<pid>);      -- Graceful
SELECT pg_terminate_backend(<pid>);   -- Forceful
```

### 5. Deployment-Related Issues

**Investigation checklist:**

```markdown
1. **What changed in the deploy?**
   - Code changes (git diff between versions)
   - Dependency updates
   - Configuration changes
   - Infrastructure changes (Terraform, Kubernetes manifests)

2. **Canary/rollout status**
   - Was it a gradual rollout?
   - At what percentage did issues start?
   - Are issues only on new instances?

3. **Rollback verification**
   - Can you roll back?
   - Will rollback cause data issues (e.g., schema migrations)?
   - Does rollback fix the symptoms?
```

## Safe Debugging Techniques

### Read-Only Investigation

```bash
# Safe: reading logs, metrics, state
kubectl logs pod/myapp --tail=500
kubectl describe pod/myapp
kubectl get events --sort-by='.lastTimestamp'

# Safe: database read-only queries
# Use a read replica, never the primary
psql -h replica-host -c "EXPLAIN ANALYZE SELECT ..."

# Safe: network inspection
tcpdump -i any -nn port 8080 -c 100   # Capture 100 packets
curl -v --max-time 5 http://internal-service/health
```

### Debug Logging in Production

```python
# Use dynamic log level adjustment (no restart needed)
# Many frameworks support this via admin endpoint or config reload

# Flask example with runtime log level change
@app.route('/admin/log-level', methods=['POST'])
def set_log_level():
    level = request.json.get('level', 'INFO')
    logging.getLogger().setLevel(getattr(logging, level))
    return {'status': 'ok', 'level': level}

# Time-limited debug logging
import threading

def enable_debug_for(seconds=300):
    logger = logging.getLogger()
    original_level = logger.level
    logger.setLevel(logging.DEBUG)

    def restore():
        logger.setLevel(original_level)

    timer = threading.Timer(seconds, restore)
    timer.start()
```

### Feature Flags for Debugging

```javascript
// Use feature flags to enable debug paths in production
if (featureFlags.isEnabled("debug-payment-flow", { userId })) {
  logger.debug("Payment details", {
    userId,
    amount,
    provider: paymentProvider.name,
    requestId,
  });
}
```

## Post-Incident

### Writing an Effective Post-Mortem

```markdown
## Post-Mortem Template

### Summary
One paragraph describing what happened, impact, and duration.

### Timeline
- HH:MM - First alert fired
- HH:MM - Engineer acknowledged
- HH:MM - Root cause identified
- HH:MM - Mitigation applied
- HH:MM - Full resolution confirmed

### Root Cause
Detailed technical explanation of what went wrong and why.

### Impact
- Duration: X hours Y minutes
- Users affected: N
- Revenue impact: $X (if applicable)
- Data impact: None / description

### What Went Well
- Detection was fast
- Runbooks were followed
- Communication was clear

### What Could Be Improved
- Detection took too long because...
- Runbook was missing step for...
- Communication gap between...

### Action Items
| Action | Owner | Priority | Due Date |
|--------|-------|----------|----------|
| Add monitoring for X | @engineer | P1 | 2024-02-01 |
| Update runbook with Y | @oncall | P2 | 2024-02-05 |
| Add circuit breaker to Z | @team | P1 | 2024-02-10 |
```

### Prevention Strategies

1. **Monitoring and alerting**: Alert on symptoms (error rate, latency) not just causes (CPU usage)
2. **Chaos engineering**: Regularly test failure modes in staging
3. **Load testing**: Know your system's breaking points before production discovers them
4. **Deployment safety**: Canary deploys, automated rollback, feature flags
5. **Runbooks**: Document common failure modes and their resolution steps
6. **Game days**: Practice incident response with simulated outages

## Quick Reference: Production Debug Commands

```bash
# Kubernetes
kubectl get pods -o wide                    # Pod status and node
kubectl describe pod <pod>                  # Events and conditions
kubectl logs <pod> --previous               # Logs from crashed container
kubectl exec -it <pod> -- /bin/sh           # Shell into container (read-only investigation)
kubectl top pods --sort-by=memory           # Resource usage
kubectl rollout undo deployment/<name>      # Rollback deployment

# Docker
docker stats --no-stream                    # Container resource usage
docker inspect <container>                  # Full container config
docker logs --since 1h <container>          # Recent logs

# Linux system
dmesg -T | tail -50                         # Kernel messages (OOM kills)
vmstat 1 5                                  # System stats (5 samples, 1s apart)
iostat -x 1 5                              # Disk I/O stats
free -h                                     # Memory usage
df -h                                       # Disk usage
uptime                                      # Load averages
```
