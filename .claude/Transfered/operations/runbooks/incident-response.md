# Incident Response Runbook

## Overview
This runbook provides procedures for responding to production incidents in the AI Orchestrator platform.

## Incident Severity Levels

### P0 - Critical
- **Definition**: Complete service outage or data loss
- **Response Time**: Immediate (< 5 minutes)
- **Examples**: Service down, database corruption, security breach

### P1 - High
- **Definition**: Major functionality degraded
- **Response Time**: < 15 minutes
- **Examples**: Severe performance degradation, multiple agent failures

### P2 - Medium
- **Definition**: Minor functionality impaired
- **Response Time**: < 1 hour
- **Examples**: Single agent failures, elevated error rates

## Initial Response (All Severity Levels)

### 1. Acknowledge and Assess
```bash
# Check service status
kubectl get pods -n ai-orchestrator
kubectl get services -n ai-orchestrator

# Check recent logs
kubectl logs -n ai-orchestrator deployment/ai-orchestrator --tail=100

# Check metrics dashboard
# Navigate to: https://grafana.example.com/d/operational-dashboard
```

### 2. Notify Stakeholders
- P0: Page on-call engineer immediately + notify leadership
- P1: Notify on-call engineer + post to #incidents channel
- P2: Post to #incidents channel

### 3. Create Incident Channel
```
/incident create [P0|P1|P2] [brief description]
```

## Common Incidents and Resolution

### Service Completely Down

#### Symptoms
- Health check endpoint returns 5xx
- No pods running
- Unable to access API

#### Diagnosis
```bash
# Check pod status
kubectl get pods -n ai-orchestrator

# Check events
kubectl get events -n ai-orchestrator --sort-by='.lastTimestamp'

# Check resource limits
kubectl top pods -n ai-orchestrator
kubectl describe nodes
```

#### Resolution
```bash
# If pods are CrashLooping
kubectl logs -n ai-orchestrator <pod-name> --previous

# If ImagePullBackOff
kubectl describe pod -n ai-orchestrator <pod-name>

# Restart deployment
kubectl rollout restart deployment/ai-orchestrator -n ai-orchestrator

# If database connection issue
kubectl get secrets -n ai-orchestrator
kubectl describe secret ai-orchestrator-secrets -n ai-orchestrator

# Emergency rollback
kubectl rollout undo deployment/ai-orchestrator -n ai-orchestrator
```

### High Error Rate

#### Symptoms
- Error rate > 5%
- Alert: "HighErrorRate" firing

#### Diagnosis
```bash
# Check error logs
kubectl logs -n ai-orchestrator -l app=ai-orchestrator --tail=500 | grep -i error

# Check Sentry for error patterns
# Navigate to: https://sentry.io/ai-orchestrator

# Query Prometheus
curl -G http://prometheus:9090/api/v1/query \
  --data-urlencode 'query=rate(errors_total[5m])'
```

#### Resolution
1. Identify error pattern in logs
2. Check recent deployments: `kubectl rollout history deployment/ai-orchestrator -n ai-orchestrator`
3. If deployment-related: `kubectl rollout undo deployment/ai-orchestrator -n ai-orchestrator`
4. If third-party API issue: Enable circuit breaker or use fallback

### Database Connection Issues

#### Symptoms
- Database connection timeouts
- "Connection pool exhausted" errors

#### Diagnosis
```bash
# Check database connectivity
kubectl exec -it -n ai-orchestrator <pod-name> -- \
  psql -h $DATABASE_HOST -U $DATABASE_USER -d $DATABASE_NAME -c "SELECT 1"

# Check connection pool metrics
# Navigate to Grafana > Operational Dashboard > Database Connections

# Check RDS status (AWS)
aws rds describe-db-instances \
  --db-instance-identifier ai-orchestrator-production
```

#### Resolution
```bash
# Increase connection pool size (temporary)
kubectl set env deployment/ai-orchestrator -n ai-orchestrator \
  DATABASE_POOL_MAX=150

# Restart application to clear stale connections
kubectl rollout restart deployment/ai-orchestrator -n ai-orchestrator

# If RDS CPU/memory maxed out
aws rds modify-db-instance \
  --db-instance-identifier ai-orchestrator-production \
  --db-instance-class db.r6g.2xlarge \
  --apply-immediately
```

### Redis/Cache Failures

#### Symptoms
- Cache miss rate > 80%
- Redis connection errors

#### Diagnosis
```bash
# Check Redis connectivity
kubectl exec -it -n ai-orchestrator <pod-name> -- \
  redis-cli -h $REDIS_HOST ping

# Check Redis memory usage
kubectl exec -it -n ai-orchestrator redis-master-0 -- \
  redis-cli INFO memory

# Check ElastiCache status (AWS)
aws elasticache describe-cache-clusters \
  --cache-cluster-id ai-orchestrator-production \
  --show-cache-node-info
```

#### Resolution
```bash
# Verify Redis is running
kubectl get pods -n ai-orchestrator | grep redis

# Restart Redis (if standalone)
kubectl rollout restart statefulset/redis-master -n ai-orchestrator

# Application can operate without cache (degraded performance)
# Verify database fallback is working

# If Redis memory full
kubectl exec -it -n ai-orchestrator redis-master-0 -- \
  redis-cli FLUSHDB
```

### Agent Failures

#### Symptoms
- Multiple agents in "failed" state
- Tasks not being processed

#### Diagnosis
```bash
# Check agent status via API
curl -H "Authorization: Bearer $TOKEN" \
  https://api.example.com/api/agents?status=failed

# Check agent logs
kubectl logs -n ai-orchestrator -l component=agent --tail=200

# Check resource constraints
kubectl top pods -n ai-orchestrator -l component=agent
```

#### Resolution
```bash
# Restart failed agents via API
curl -X POST -H "Authorization: Bearer $TOKEN" \
  https://api.example.com/api/agents/restart-failed

# If resource constraints, scale up
kubectl scale deployment/ai-orchestrator-agents -n ai-orchestrator --replicas=10

# If configuration issue, update ConfigMap
kubectl edit configmap ai-orchestrator-config -n ai-orchestrator
kubectl rollout restart deployment/ai-orchestrator-agents -n ai-orchestrator
```

### Memory Leak Suspected

#### Symptoms
- Memory usage continuously increasing
- OOMKilled pods
- Alert: "MemoryLeakSuspected" firing

#### Diagnosis
```bash
# Check memory trends
# Navigate to Grafana > Operational Dashboard > Memory Usage

# Get heap snapshot
kubectl exec -n ai-orchestrator <pod-name> -- \
  node --expose-gc --max-old-space-size=4096 \
  -e "require('heapdump').writeSnapshot('/tmp/heap.heapsnapshot')"

kubectl cp ai-orchestrator/<pod-name>:/tmp/heap.heapsnapshot ./heap.heapsnapshot

# Analyze with Chrome DevTools or clinic.js
```

#### Resolution
```bash
# Immediate: Restart pods to free memory
kubectl rollout restart deployment/ai-orchestrator -n ai-orchestrator

# Temporary: Increase memory limits
kubectl set resources deployment/ai-orchestrator -n ai-orchestrator \
  --limits=memory=8Gi

# Long-term: Identify and fix memory leak in code
# Use heap snapshot analysis to find leaking objects
```

### Security Incident

#### Symptoms
- Alert: "AuthenticationFailureSpike" or "SuspiciousActivityDetected"
- Unusual API traffic patterns

#### Immediate Actions
1. **DO NOT** shut down immediately - preserve evidence
2. Isolate affected components
3. Enable additional logging
4. Notify security team

#### Diagnosis
```bash
# Check authentication logs
kubectl logs -n ai-orchestrator -l app=ai-orchestrator | \
  grep "authentication_failed"

# Check access logs for suspicious IPs
kubectl logs -n ai-orchestrator ingress-nginx-controller | \
  grep -E "POST /api/auth|401|403"

# Check for privilege escalation attempts
kubectl logs -n ai-orchestrator -l app=ai-orchestrator | \
  grep "permission_denied"
```

#### Resolution
```bash
# Block suspicious IPs
kubectl patch configmap nginx-configuration -n ingress-nginx \
  --patch '{"data": {"block-cidrs": "1.2.3.4/32,5.6.7.8/32"}}'

# Rotate secrets
./operations/scripts/rotate-secrets.sh

# Force re-authentication for all users
kubectl exec -n ai-orchestrator redis-master-0 -- \
  redis-cli FLUSHDB

# Enable WAF rules (if using AWS)
aws wafv2 update-web-acl --id $WAF_ID \
  --scope REGIONAL \
  --rules file://waf-rules-strict.json
```

## Post-Incident Actions

### 1. Verify Resolution
- [ ] All metrics returned to normal
- [ ] Error rate < 1%
- [ ] All health checks passing
- [ ] Stakeholders notified

### 2. Document Incident
```
/incident update [incident-id] status=resolved
/incident postmortem [incident-id]
```

### 3. Conduct Postmortem (P0/P1 only)
- Schedule within 48 hours
- Use blameless postmortem template
- Identify root cause
- Create action items

### 4. Update Runbooks
- Document new learnings
- Update procedures
- Add automation where possible

## Escalation Paths

### Engineering Escalation
1. On-call engineer (PagerDuty)
2. Engineering manager
3. VP Engineering
4. CTO

### Business Escalation
1. Product manager
2. VP Product
3. CEO

## Key Contacts

- **On-call Engineer**: PagerDuty rotation
- **Engineering Manager**: manager@example.com
- **Security Team**: security@example.com
- **Infrastructure Team**: infra@example.com

## Useful Commands Reference

```bash
# Quick health check
kubectl get all -n ai-orchestrator

# Stream logs
kubectl logs -f -n ai-orchestrator deployment/ai-orchestrator

# Execute command in pod
kubectl exec -it -n ai-orchestrator <pod-name> -- /bin/bash

# Port forward to debug
kubectl port-forward -n ai-orchestrator service/ai-orchestrator 3000:80

# Scale deployment
kubectl scale deployment/ai-orchestrator -n ai-orchestrator --replicas=5

# Update environment variable
kubectl set env deployment/ai-orchestrator -n ai-orchestrator LOG_LEVEL=debug

# Check resource usage
kubectl top nodes
kubectl top pods -n ai-orchestrator
```

## Additional Resources

- [Performance Degradation Runbook](./performance-degradation.md)
- [Disaster Recovery Runbook](./disaster-recovery.md)
- [Rollback Procedures](./rollback-procedures.md)
- [Architecture Documentation](../../docs/ARCHITECTURE.md)
- [Grafana Dashboards](https://grafana.example.com)
- [Sentry](https://sentry.io/ai-orchestrator)
