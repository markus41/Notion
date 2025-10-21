---
title: "[Problem/Task] Recovery and Resolution"
description: "Operational procedures for [resolving issue/performing task], designed to minimize downtime and restore service reliability"
audience: [operator]
severity: high  # Options: low, medium, high, critical
estimated_time: "20 minutes"
prerequisites:
  - "Azure portal access with appropriate RBAC permissions"
  - "kubectl access to AKS cluster (if applicable)"
  - "Azure CLI installed and authenticated"
  - "Access to monitoring dashboards"
on_call_priority: P1  # Options: P0 (critical), P1 (high), P2 (medium), P3 (low)
related_incidents: []  # Add incident IDs as they occur
last_updated: "2025-10-14"
tags: [runbook, operations, troubleshooting, recovery]
version: "2.0"
escalation_contact: "platform-team@example.com"
sla_impact: "Service degradation affecting 10%+ of users"
related_docs:
  - "/guides/operator/monitoring"
  - "/architecture/deployment-architecture"
  - "/guides/operator/disaster-recovery"
---

# [Problem/Task] Recovery and Resolution

> **Purpose:** Restore [service/functionality] to operational state by [primary action]

## Overview

This runbook provides step-by-step procedures for resolving [specific problem] to ensure rapid service recovery and minimize business impact.

**When to Use This Runbook:**
- ✅ [Scenario 1 requiring this runbook]
- ✅ [Scenario 2 requiring this runbook]
- ✅ [Scenario 3 requiring this runbook]
- ❌ **Do NOT use** for [scenarios where different procedure needed]

**Expected Impact:**
- **Service:** [Which service is affected]
- **Users Affected:** [Scope of impact - e.g., "All users in EU region"]
- **Duration:** [Typical outage duration without intervention]
- **SLA Impact:** [How this affects SLAs]

::: danger Critical Information
**Severity:** {severity}
**Priority:** {on_call_priority}
**SLA Impact:** {sla_impact}

Follow all steps carefully. Skipping steps may result in data loss or extended outages.
:::

---

## Quick Reference

### Key Contacts

| Role | Contact | When to Escalate |
|------|---------|------------------|
| **On-Call Engineer** | Slack: `#oncall-platform` | First responder |
| **Platform Team Lead** | {escalation_contact} | After 30 min without resolution |
| **Engineering Manager** | Slack: `@eng-manager` | After 1 hour or P0 incidents |
| **Azure Support** | Portal: Azure Support | For Azure platform issues |

### Essential Commands

```bash
# Check service health
az resource show --ids /subscriptions/{sub}/resourceGroups/{rg}/providers/{provider}/{resource}

# View recent logs
az monitor activity-log list --resource-group {rg} --start-time 2025-01-15T00:00:00Z

# Check pod status (AKS)
kubectl get pods -n {namespace} -l app={app-name}

# View pod logs (AKS)
kubectl logs -n {namespace} {pod-name} --tail=100
```

### Required Tools

- [ ] Azure CLI (`az` command) - [Installation](https://docs.microsoft.com/cli/azure/install-azure-cli)
- [ ] kubectl (for AKS clusters) - [Installation](https://kubernetes.io/docs/tasks/tools/)
- [ ] jq (JSON processor) - [Installation](https://stedolan.github.io/jq/download/)
- [ ] Access to Azure Portal
- [ ] Access to Application Insights

---

## Pre-Check: Verify You Have the Right Runbook

Before proceeding, confirm this is the correct runbook for your situation:

### Symptoms Checklist

Does the issue exhibit these symptoms?

- [ ] [Specific symptom 1]
- [ ] [Specific symptom 2]
- [ ] [Specific symptom 3]

**If YES to 2+ symptoms:** Continue with this runbook
**If NO:** Refer to alternative runbooks:
- [Alternative Runbook 1](/runbooks/alternative-1)
- [Alternative Runbook 2](/runbooks/alternative-2)

### Diagnostic Queries

Run these queries to confirm the issue:

```bash
# Query 1: Check [metric]
az monitor metrics list \
  --resource {resource-id} \
  --metric {metric-name} \
  --start-time $(date -u -d '30 minutes ago' '+%Y-%m-%dT%H:%M:%SZ') \
  --interval PT1M
```

**Expected Output if Issue Present:**
```json
{
  "value": [
    {
      "timeseries": [{
        "data": [{"average": 100, "timeStamp": "..."}]  // > 80 indicates issue
      }]
    }
  ]
}
```

---

## Resolution Procedure

Follow these steps in order. Do not skip steps unless explicitly noted as optional.

### Phase 1: Assessment and Triage (Est. 5 min)

#### Step 1.1: Verify Service Impact

**Objective:** Quantify the scope of the outage

```bash
# Check error rate
az monitor metrics list \
  --resource {resource-id} \
  --metric 'Requests/Failed' \
  --aggregation Average \
  --interval PT5M \
  --start-time $(date -u -d '1 hour ago' '+%Y-%m-%dT%H:%M:%SZ')
```

**What to Look For:**
- Error rate > 5%: Limited impact
- Error rate > 20%: Significant impact
- Error rate > 50%: Critical impact

**Record Findings:**
- Current error rate: ______%
- Affected region(s): ____________
- Start time: ____________

#### Step 1.2: Check Related Services

```bash
# Check dependencies
az resource list \
  --resource-group {rg} \
  --query "[?tags.component=='dependency'].{name:name, state:properties.provisioningState}" \
  -o table
```

**Dependencies to Verify:**
- [ ] [Dependency 1] - Status: _______
- [ ] [Dependency 2] - Status: _______
- [ ] [Dependency 3] - Status: _______

#### Step 1.3: Review Recent Changes

```bash
# Check recent deployments
az deployment group list \
  --resource-group {rg} \
  --query "[?properties.timestamp >= '$(date -u -d '6 hours ago' '+%Y-%m-%dT%H:%M:%SZ')'].{name:name, state:properties.provisioningState, time:properties.timestamp}" \
  -o table
```

**Recent Changes:**
| Time | Change Type | Deployed By | Status |
|------|-------------|-------------|--------|
|      |             |             |        |

::: warning Decision Point
**If recent deployment found:** Proceed to rollback procedure (Step 2.1)
**If no recent changes:** Continue with diagnostic procedure (Step 2.2)
:::

---

### Phase 2: Mitigation (Est. 10 min)

#### Step 2.1: Rollback Recent Deployment (If Applicable)

**When to Execute:** Recent deployment (< 6 hours) correlates with issue start

```bash
# Rollback to previous deployment
az deployment group create \
  --resource-group {rg} \
  --template-file ./previous-deployment.bicep \
  --parameters @previous-parameters.json \
  --rollback-on-error
```

**Verification:**
```bash
# Verify rollback success
az deployment group show \
  --resource-group {rg} \
  --name {deployment-name} \
  --query 'properties.provisioningState'
```

**Expected Output:** `"Succeeded"`

**Wait for Stabilization:** 3-5 minutes

**Check Service Health:**
```bash
# Verify error rate decreased
az monitor metrics list \
  --resource {resource-id} \
  --metric 'Requests/Failed' \
  --interval PT1M \
  --start-time $(date -u -d '5 minutes ago' '+%Y-%m-%dT%H:%M:%SZ')
```

::: tip Success Criteria
Error rate < 5% for 3 consecutive minutes = Successfully mitigated
:::

**If rollback successful:** Skip to Phase 3 (Post-Incident)
**If rollback unsuccessful:** Continue to Step 2.2

---

#### Step 2.2: Restart Affected Services

**When to Execute:** No recent deployments OR rollback unsuccessful

##### For App Service:
```bash
# Restart App Service
az webapp restart \
  --resource-group {rg} \
  --name {app-name}

# Monitor restart
az webapp show \
  --resource-group {rg} \
  --name {app-name} \
  --query 'state'
```

##### For AKS Pods:
```bash
# Restart pods by deleting (Kubernetes will recreate)
kubectl delete pods -n {namespace} -l app={app-name}

# Watch pod recreation
kubectl get pods -n {namespace} -l app={app-name} -w
```

**Verification:**
```bash
# Wait 2 minutes for services to stabilize

# Check health endpoint
curl -i https://{app-url}/health
```

**Expected Output:**
```
HTTP/2 200
Content-Type: application/json

{
  "status": "healthy",
  "version": "2.0.1",
  "dependencies": {
    "database": "connected",
    "cache": "connected"
  }
}
```

---

#### Step 2.3: Scale Out Resources (If Performance Issue)

**When to Execute:** Services healthy but overloaded (CPU > 80%, Memory > 90%)

```bash
# Scale out App Service
az appservice plan update \
  --resource-group {rg} \
  --name {plan-name} \
  --number-of-workers 5  # Increase from current count

# OR scale out AKS deployment
kubectl scale deployment {deployment-name} -n {namespace} --replicas=10
```

**Monitor Scaling:**
```bash
# Check resource utilization
az monitor metrics list \
  --resource {resource-id} \
  --metric 'CPU Percentage' \
  --interval PT1M
```

**Wait for:** CPU < 70% and Memory < 80% for 5 consecutive minutes

---

### Phase 3: Post-Incident Actions (Est. 5 min)

#### Step 3.1: Verify Full Recovery

**Service Health Checks:**

- [ ] Error rate < 2% for 10 minutes
- [ ] Response time < [SLA threshold]
- [ ] All health endpoints returning 200 OK
- [ ] No error spikes in Application Insights
- [ ] User-reported issues resolved

```bash
# Final verification query
az monitor metrics list \
  --resource {resource-id} \
  --metric 'Requests/Total' 'Requests/Failed' 'ResponseTime' \
  --aggregation Average \
  --interval PT1M \
  --start-time $(date -u -d '15 minutes ago' '+%Y-%m-%dT%H:%M:%SZ')
```

#### Step 3.2: Document Incident

Create incident report with:

- **Incident ID:** INC-YYYY-NNNN
- **Start Time:** [ISO timestamp]
- **Detection Time:** [ISO timestamp]
- **Mitigation Time:** [ISO timestamp]
- **Resolution Time:** [ISO timestamp]
- **Total Duration:** [minutes]
- **Root Cause:** [Preliminary assessment]
- **Mitigation Steps:** [Steps executed from this runbook]
- **Users Affected:** [Count/percentage]

**Template:**
```markdown
## Incident Report: INC-YYYY-NNNN

**Timeline:**
- Start: 2025-01-15 10:30 UTC
- Detected: 2025-01-15 10:32 UTC
- Mitigated: 2025-01-15 10:45 UTC
- Resolved: 2025-01-15 10:50 UTC
- Duration: 20 minutes

**Impact:**
- Users affected: ~500 (10% of total)
- Error rate peak: 35%
- Services degraded: [API name]

**Root Cause (Preliminary):**
[Brief description]

**Resolution:**
[Steps taken from runbook]

**Next Actions:**
- [ ] RCA scheduled for [date]
- [ ] Preventative measures identified
- [ ] Update runbook with learnings
```

#### Step 3.3: Notify Stakeholders

```bash
# Send resolution notification (example)
# Adapt to your notification system

# Slack notification
curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
  -H 'Content-Type: application/json' \
  -d '{
    "text": "🟢 RESOLVED: [Issue] has been mitigated. Services restored to normal operation.",
    "attachments": [{
      "color": "good",
      "fields": [
        {"title": "Incident ID", "value": "INC-2025-001", "short": true},
        {"title": "Duration", "value": "20 minutes", "short": true},
        {"title": "Impact", "value": "10% of users", "short": false}
      ]
    }]
  }'
```

**Notification Channels:**
- [ ] Internal Slack `#incidents`
- [ ] Status page updated
- [ ] Customer notifications (if SLA breach)
- [ ] Leadership briefing (if P0/P1)

---

## Alternative Procedures

If the standard procedure doesn't resolve the issue:

### Alternative 1: Manual Failover to Secondary Region

**When:** Primary region completely unavailable

```bash
# Failover to secondary region
az traffic-manager endpoint update \
  --resource-group {rg} \
  --profile-name {tm-profile} \
  --name {primary-endpoint} \
  --type azureEndpoints \
  --endpoint-status Disabled

az traffic-manager endpoint update \
  --resource-group {rg} \
  --profile-name {tm-profile} \
  --name {secondary-endpoint} \
  --type azureEndpoints \
  --endpoint-status Enabled \
  --priority 1
```

**Validation:**
```bash
# Verify traffic routing to secondary
curl -I https://{service-url}
# Check X-Region header = "secondary"
```

### Alternative 2: Emergency Maintenance Mode

**When:** Unable to restore service, need to prevent cascading failures

```bash
# Enable maintenance mode
az webapp config appsettings set \
  --resource-group {rg} \
  --name {app-name} \
  --settings MAINTENANCE_MODE=true

# Verify maintenance page
curl https://{app-url}
# Should return 503 with maintenance message
```

---

## Escalation Procedure

### When to Escalate

Escalate if:
- [ ] Mitigation unsuccessful after 30 minutes
- [ ] Issue severity increases (e.g., from P1 to P0)
- [ ] Data loss suspected
- [ ] Security incident suspected
- [ ] Multiple regions affected
- [ ] SLA breach imminent or occurred

### Escalation Contacts

**Tier 1:** Platform Team Lead
- Contact: {escalation_contact}
- Threshold: 30 min without resolution
- Expected Response: 15 min

**Tier 2:** Engineering Manager
- Contact: Slack `@eng-manager`
- Threshold: 60 min or P0 incident
- Expected Response: 30 min

**Tier 3:** Azure Support (for platform issues)
- Contact: Azure Portal > Support
- Threshold: Azure platform degradation
- Expected Response: Per support contract

**Tier 4:** Executive Leadership
- Contact: CTO via incident commander
- Threshold: Major outage (>2 hours, >50% users)
- Expected Response: Immediate

---

## Prevention and Monitoring

### Preventative Measures

To prevent this issue from recurring:

1. **[Preventative Action 1]**
   - Implementation: [How to implement]
   - Effort: [Time/complexity]
   - Priority: High/Medium/Low

2. **[Preventative Action 2]**
   - Implementation: [How to implement]
   - Effort: [Time/complexity]
   - Priority: High/Medium/Low

### Monitoring Setup

**Early Warning Alerts:**

Create these alerts to detect issues before outage:

```bash
# Example: High error rate alert
az monitor metrics alert create \
  --name "High-Error-Rate-{service}" \
  --resource-group {rg} \
  --scopes {resource-id} \
  --condition "avg Requests/Failed > 10" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action {action-group-id} \
  --description "Alert when error rate exceeds 10% for 5 minutes"
```

**Recommended Alerts:**
- [ ] Error rate > 5% for 5 minutes
- [ ] Response time > [SLA threshold] for 3 minutes
- [ ] Availability < 99.9% for 5 minutes
- [ ] Dependency failure detected
- [ ] Resource utilization > 80% for 10 minutes

---

## Lessons Learned Template

After incident resolution, conduct a blameless post-mortem:

### Questions to Answer:

1. **What happened?**
   - [Detailed timeline and description]

2. **What was the root cause?**
   - [Technical root cause]
   - [Contributing factors]

3. **How did we detect it?**
   - [Monitoring, alert, user report?]
   - [Time to detection]

4. **How did we respond?**
   - [Actions taken]
   - [What worked well?]
   - [What didn't work?]

5. **What are we changing to prevent recurrence?**
   - Action Item 1: [Description] - Owner: [Name] - Due: [Date]
   - Action Item 2: [Description] - Owner: [Name] - Due: [Date]

6. **How can we detect it faster next time?**
   - [New alerts, monitoring, etc.]

---

## Related Runbooks

- [Related Runbook 1](/runbooks/related-1) - [When to use]
- [Related Runbook 2](/runbooks/related-2) - [When to use]
- [Disaster Recovery](/runbooks/disaster-recovery) - [When to use]

---

## Runbook Maintenance

**Last Validated:** 2025-10-14
**Next Review:** 2025-11-14 (monthly review)
**Validation Method:** [Chaos engineering test / Drill / Real incident]

**Recent Changes:**
- 2025-10-14: Initial version
- [Date]: [Change description]

**Validation Checklist:**
- [ ] All commands tested in non-production
- [ ] Contact information current
- [ ] Escalation paths validated
- [ ] Alternative procedures documented
- [ ] Metrics and thresholds accurate

---

**Emergency Contact:** {escalation_contact} | **Priority:** {on_call_priority} | **Version:** 2.0
