---
title: Disaster Recovery Procedures
description: Maintain business continuity through structured recovery processes. Step-by-step runbook for rapid restoration with minimal data loss and downtime.
tags:
  - disaster-recovery
  - runbooks
  - backup
  - restore
  - business-continuity
  - incident-response
  - azure
lastUpdated: 2025-10-09
author: Agent Studio Team
audience: operators
---

# Disaster Recovery Runbook

## Overview

This runbook provides comprehensive disaster recovery (DR) procedures for Project Ascension, a meta-agent orchestration platform. It covers all disaster scenarios, recovery procedures, backup strategies, and business continuity planning to ensure rapid recovery from catastrophic failures.

### DR Strategy

**Recovery Model**: Multi-layered defense with automated backups, geo-redundancy options, and documented recovery procedures

**Critical Services**:
- Azure Cosmos DB (primary data store)
- Container Apps (application runtime)
- Azure OpenAI (AI processing)
- SignalR (real-time communication)
- Redis Cache (session/state management)
- Azure AI Search (semantic search)
- Key Vault (secrets management)
- Storage Accounts (blob storage)

**Recovery Objectives**:

| Environment | RTO (Recovery Time Objective) | RPO (Recovery Point Objective) |
|-------------|-------------------------------|--------------------------------|
| Development | 8 hours | 24 hours |
| Staging | 4 hours | 1 hour |
| Production | 4 hours | 15 minutes |

**Backup Strategy**:
- **Continuous**: Cosmos DB with 7-day continuous backup
- **Automated**: Daily infrastructure snapshots
- **Versioned**: Infrastructure-as-Code in Git (point-in-time recovery)
- **Tested**: Quarterly DR drill validation

### Scope

**In Scope**:
- Complete Azure infrastructure failure
- Regional outages and availability zone failures
- Database corruption and data loss scenarios
- Security breaches requiring infrastructure rebuild
- Application deployment failures
- Service degradation and partial outages

**Out of Scope**:
- Code bugs (use rollback procedures in deployment-procedures.md)
- Performance degradation (use performance tuning guides)
- Minor service interruptions (< 1 minute)
- Planned maintenance windows

## Disaster Scenarios

### Scenario 1: Complete Azure Region Outage

**Description**: Entire Azure region becomes unavailable (eastus primary region failure)

**Impact**:
- All services unavailable in affected region
- Complete application downtime
- No access to regional resources

**Detection**:
```bash
# Check Azure Service Health
az rest --method get \
  --uri "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/providers/Microsoft.ResourceHealth/availabilityStatuses?api-version=2020-05-01" \
  --query "value[?properties.availabilityState!='Available'].{Resource:name,State:properties.availabilityState,Summary:properties.summary}" \
  -o table

# Check all resources in primary region
az resource list \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "[].{Name:name,State:provisioningState,Location:location}" \
  -o table
```

**Immediate Actions**:
1. Confirm region-wide outage (not isolated to our resources)
2. Activate DR team and notify stakeholders
3. Initiate failover to secondary region (if configured)
4. Update DNS/Traffic Manager to route to DR region

**Recovery Procedure**: See [Phase 3: Failover](#phase-3-failover)

**Prevention**:
- Configure geo-redundancy for production
- Implement Traffic Manager for automatic failover
- Deploy to multiple regions for critical production workloads

---

### Scenario 2: Cosmos DB Data Corruption or Loss

**Description**: Database corruption, accidental deletion, or data integrity issues

**Impact**:
- Application unable to read/write data
- Inconsistent application state
- Potential data loss
- Service degradation or complete failure

**Detection**:
```bash
# Check Cosmos DB health
az cosmosdb show \
  --name ascension-${ENVIRONMENT}-cosmos \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "{Status:properties.provisioningState,Endpoint:properties.documentEndpoint,BackupPolicy:backupPolicy.type}" \
  -o json

# Query for data integrity issues
az cosmosdb sql container query \
  --account-name ascension-${ENVIRONMENT}-cosmos \
  --database-name project-ascension-db \
  --container-name workflow-states \
  --query "SELECT COUNT(1) as total FROM c" \
  -o tsv

# Check Application Insights for database errors
az monitor app-insights query \
  --app ascension-${ENVIRONMENT}-ai \
  --analytics-query "
    exceptions
    | where timestamp > ago(15m)
    | where outerMessage contains 'Cosmos' or outerMessage contains 'Database'
    | summarize ErrorCount = count() by outerMessage
    | order by ErrorCount desc
    " \
  --offset 15m -o table
```

**Immediate Actions**:
1. Stop all write operations to prevent further corruption
2. Assess extent of data loss/corruption
3. Identify last known good timestamp
4. Initiate point-in-time restore

**Recovery Procedure**: See [Component Recovery: Cosmos DB](#cosmos-db)

**Prevention**:
- Enable continuous backup mode (already configured)
- Implement application-level data validation
- Regular backup verification tests
- Multi-region replication for production

---

### Scenario 3: Security Breach or Compromise

**Description**: Detected security breach requiring complete infrastructure rebuild

**Impact**:
- Potential data exposure
- Compromised credentials
- Required service shutdown
- Full infrastructure rotation needed

**Detection**:
```bash
# Check for security alerts in Azure Security Center
az security alert list --query "[].{Name:name,Severity:properties.severity,Status:properties.status,Description:properties.description}" -o table

# Check Key Vault access logs for suspicious activity
az monitor activity-log list \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --offset 7d \
  --query "[?contains(authorization.action, 'Microsoft.KeyVault')].{Time:eventTimestamp,Action:authorization.action,Caller:caller,Status:status.value}" \
  -o table

# Check for unauthorized Container App changes
az containerapp revision list \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "[].{Name:name,Created:properties.createdTime,Status:properties.provisioningState}" \
  -o table
```

**Immediate Actions**:
1. Isolate affected systems immediately
2. Activate security incident response team
3. Preserve forensic evidence (logs, snapshots)
4. Rotate all credentials and secrets
5. Initiate clean room infrastructure rebuild

**Recovery Procedure**:

```bash
# Step 1: Isolate - Block all public access
ENVIRONMENT="prod"
RG_NAME="ascension-${ENVIRONMENT}-rg"

# Disable Container App ingress
az containerapp ingress disable \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group $RG_NAME

# Rotate all Key Vault secrets
for secret in $(az keyvault secret list --vault-name ascension-${ENVIRONMENT}-kv --query "[].name" -o tsv); do
  echo "Rotating secret: $secret"
  # Coordinate with service owners to rotate each secret
done

# Step 2: Preserve evidence - Export all logs
INCIDENT_DATE=$(date +%Y%m%d-%H%M%S)
mkdir -p /tmp/incident-${INCIDENT_DATE}

# Export Container App logs
az containerapp logs show \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group $RG_NAME \
  --type console \
  --tail 10000 > /tmp/incident-${INCIDENT_DATE}/container-logs.txt

# Export Application Insights data
az monitor app-insights query \
  --app ascension-${ENVIRONMENT}-ai \
  --analytics-query "
    union requests, exceptions, traces, dependencies
    | where timestamp > ago(7d)
    | order by timestamp desc
    " \
  --offset 7d -o json > /tmp/incident-${INCIDENT_DATE}/app-insights.json

# Export Azure Activity Logs
az monitor activity-log list \
  --resource-group $RG_NAME \
  --offset 7d -o json > /tmp/incident-${INCIDENT_DATE}/activity-logs.json

# Step 3: Rebuild in isolated environment
# Create new resource group for clean rebuild
NEW_RG="ascension-${ENVIRONMENT}-secure-$(date +%Y%m%d)"

az group create \
  --name $NEW_RG \
  --location eastus \
  --tags "Security=Incident" "CreatedDate=$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Deploy fresh infrastructure with new credentials
az deployment sub create \
  --name "secure-rebuild-${INCIDENT_DATE}" \
  --location eastus \
  --template-file infra/deploy.bicep \
  --parameters infra/deploy.parameters.${ENVIRONMENT}.json \
  --parameters resourceGroupName=$NEW_RG

# Step 4: Restore data from last known good backup
# See Cosmos DB restore procedures below

# Step 5: Validate security posture before going live
# Run security scans, penetration tests, credential audits

# Step 6: Cutover DNS to new infrastructure
# Update DNS records, Traffic Manager, or Front Door

# Step 7: Decommission compromised infrastructure
# Only after confirming new infrastructure is secure and operational
az group delete --name $RG_NAME --yes --no-wait
```

**Prevention**:
- Implement principle of least privilege (RBAC)
- Enable Azure AD Conditional Access
- Configure Security Center continuous assessment
- Implement network segmentation with NSGs/firewalls
- Enable audit logging for all resources
- Regular security assessments and penetration testing

---

### Scenario 4: Critical Application Failure

**Description**: Severe application bug causing data loss or service unavailability

**Impact**:
- Application crashes or hangs
- Data corruption through bad logic
- Service unavailable
- User impact across all operations

**Detection**:
```bash
# Check application error rate
az monitor app-insights query \
  --app ascension-${ENVIRONMENT}-ai \
  --analytics-query "
    requests
    | where timestamp > ago(15m)
    | summarize
        TotalRequests = count(),
        FailedRequests = countif(success == false),
        ErrorRate = 100.0 * countif(success == false) / count()
    " \
  --offset 15m

# Check for application crashes
az containerapp replica list \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "[].{Name:name,State:properties.runningState,Restarts:properties.runningStateDetails}" \
  -o table

# Check exception frequency
az monitor app-insights query \
  --app ascension-${ENVIRONMENT}-ai \
  --analytics-query "
    exceptions
    | where timestamp > ago(30m)
    | summarize ExceptionCount = count() by type, outerMessage
    | order by ExceptionCount desc
    | take 10
    " \
  --offset 30m -o table
```

**Immediate Actions**:
1. Assess severity and user impact
2. Immediately rollback to last known good revision
3. Stop database migrations if in progress
4. Preserve application logs and telemetry
5. If data corruption occurred, restore database

**Recovery Procedure**:

```bash
# Immediate rollback to previous revision
PREVIOUS_REVISION=$(az containerapp revision list \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "[?properties.active==\`false\`] | sort_by(@, &properties.createdTime) | [-1].name" -o tsv)

echo "Rolling back to: $PREVIOUS_REVISION"

az containerapp ingress traffic set \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --revision-weight ${PREVIOUS_REVISION}=100

# If database corruption detected, restore to pre-deployment timestamp
RESTORE_TIMESTAMP="2025-10-09T10:00:00Z"  # Time before deployment

az cosmosdb restore \
  --target-database-account-name ascension-${ENVIRONMENT}-cosmos-restored \
  --account-name ascension-${ENVIRONMENT}-cosmos \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --restore-timestamp $RESTORE_TIMESTAMP \
  --location eastus

# See full rollback procedures in deployment-procedures.md
```

**Prevention**:
- Comprehensive automated testing (unit, integration, E2E)
- Canary deployments with automated rollback
- Database migration testing in staging
- Feature flags for gradual rollout
- Circuit breakers for external dependencies

---

### Scenario 5: Data Center / Infrastructure Failure

**Description**: Physical infrastructure failure affecting Azure availability zone or data center

**Impact**:
- Partial or complete service unavailability
- Resource connectivity issues
- Potential data access loss

**Detection**:
```bash
# Check Azure Service Health for infrastructure issues
az rest --method get \
  --uri "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/providers/Microsoft.ResourceHealth/events?api-version=2022-10-01" \
  --query "value[?properties.impactedService=='Azure Container Apps' || properties.impactedService=='Azure Cosmos DB'].{Title:properties.title,Status:properties.status,Level:properties.level}" \
  -o table

# Check zone redundancy status
az cosmosdb show \
  --name ascension-${ENVIRONMENT}-cosmos \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "locations[].{Location:locationName,ZoneRedundant:isZoneRedundant}" \
  -o table
```

**Immediate Actions**:
1. Confirm infrastructure-level failure (vs application issue)
2. Wait for Azure auto-recovery if zone-redundant
3. If no auto-recovery, initiate manual failover
4. Monitor Azure status page for updates

**Recovery Procedure**:
- For zone-redundant resources (production): Wait for automatic failover (typically < 5 minutes)
- For non-zone-redundant: Redeploy to different availability zone
- See infrastructure redeployment procedures below

**Prevention**:
- Enable zone redundancy for production Cosmos DB
- Deploy Container Apps with multiple replicas
- Use Azure Traffic Manager for multi-region failover

## Recovery Objectives

### RTO (Recovery Time Objective)

**Target RTO: 4 hours for production**

**Breakdown by Component**:

| Component | Recovery Time | Dependencies | Manual Steps |
|-----------|---------------|--------------|--------------|
| Infrastructure Provisioning | 30-45 minutes | None | Bicep deployment |
| Cosmos DB Restore | 1-2 hours | Backup availability | Point-in-time restore |
| Container Apps Deployment | 15-20 minutes | ACR, Managed Identity | Image pull and start |
| OpenAI Service | 10 minutes | None | Already provisioned |
| SignalR Service | 5 minutes | None | Configuration update |
| Redis Cache | 10-15 minutes | Storage (for persistence) | Provision and populate |
| AI Search | 20-30 minutes | Data reindexing | Index rebuild |
| Key Vault | 5-10 minutes | Secret rotation | Secret recreation |
| DNS/Traffic Cutover | 5-10 minutes | DNS propagation | Traffic Manager update |
| **Total RTO** | **3-4 hours** | Sequential recovery | Full validation |

**RTO Optimization Strategies**:
- Automate infrastructure deployment (achieved via Bicep)
- Maintain warm standby for critical production
- Pre-provision secondary region resources
- Implement parallel recovery where possible
- Regular DR drill practice

### RPO (Recovery Point Objective)

**Target RPO: 15 minutes for production**

**Data Loss Window by Component**:

| Data Store | RPO | Backup Method | Recovery Method |
|------------|-----|---------------|-----------------|
| Cosmos DB | 7 days continuous | Azure native continuous backup | Point-in-time restore to any second |
| Redis Cache | 15 minutes (prod) / 1 hour (dev) | RDB snapshots to Storage | Restore from latest snapshot |
| AI Search Index | 1 hour | Source data in Cosmos DB | Rebuild from Cosmos DB |
| Storage Blobs | 15 minutes (GRS) | Geo-redundant replication | Failover to secondary region |
| Application Logs | Real-time | Log Analytics ingestion | Query from Log Analytics |
| Configuration | 0 (no loss) | Git repository | Redeploy from Git |

**RPO Achievement**:
- Cosmos DB: Continuous backup ensures any point in last 7 days
- Redis: Premium tier with RDB persistence every 15 minutes
- Configuration: Git-based IaC ensures zero data loss
- Logs: Real-time ingestion to Log Analytics

## Backup Procedures

### Automated Backups

#### Cosmos DB Continuous Backup

**Configuration** (already implemented in infrastructure):
```bicep
backupPolicy: {
  type: 'Continuous'
  continuousModeProperties: {
    tier: 'Continuous7Days'
  }
}
```

**Verification**:
```bash
# Verify continuous backup is enabled
az cosmosdb show \
  --name ascension-${ENVIRONMENT}-cosmos \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "{Account:name,BackupType:backupPolicy.type,Tier:backupPolicy.continuousModeProperties.tier}" \
  -o json

# Expected output:
# {
#   "Account": "ascension-prod-cosmos",
#   "BackupType": "Continuous",
#   "Tier": "Continuous7Days"
# }
```

**Backup Coverage**:
- All containers in database
- Point-in-time recovery to any second within last 7 days
- No manual backup trigger needed
- Zero RTO for backup creation (continuous)

#### Redis Cache RDB Persistence

**Configuration** (production only):
```bash
# Verify RDB backup is configured (Premium tier only)
az redis show \
  --name ascension-${ENVIRONMENT}-redis \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "{Name:name,SKU:sku.name,Persistence:redisConfiguration}" \
  -o json

# Check backup frequency and storage
# Expected: rdb-backup-frequency: 60 (minutes)
```

**Backup Schedule**:
- Frequency: Every 60 minutes (configurable)
- Retention: Last 24 hours
- Location: Azure Storage Account
- Size: Depends on data volume

#### Infrastructure Snapshots

**Daily Infrastructure Backup**:
```bash
#!/bin/bash
# Daily infrastructure snapshot script
# Run via scheduled GitHub Action or Azure Automation

ENVIRONMENT="prod"
BACKUP_DATE=$(date +%Y%m%d)
BACKUP_DIR="backups/${ENVIRONMENT}/${BACKUP_DATE}"

mkdir -p $BACKUP_DIR

# Export current infrastructure state
az group export \
  --name ascension-${ENVIRONMENT}-rg \
  --include-comments \
  --include-parameter-default-value > ${BACKUP_DIR}/resource-group-template.json

# Backup Container App configuration
az containerapp show \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg \
  -o json > ${BACKUP_DIR}/containerapp-config.json

# Backup Key Vault secret metadata (not values)
az keyvault secret list \
  --vault-name ascension-${ENVIRONMENT}-kv \
  --query "[].{name:name,contentType:contentType,enabled:attributes.enabled}" \
  -o json > ${BACKUP_DIR}/keyvault-secrets-metadata.json

# Backup Network Security Groups
az network nsg list \
  --resource-group ascension-${ENVIRONMENT}-rg \
  -o json > ${BACKUP_DIR}/nsgs.json

# Commit to backup repository or upload to Storage
echo "Backup completed: ${BACKUP_DIR}"
```

### Manual Backups

#### On-Demand Cosmos DB Snapshot

For critical operations (e.g., before major migration):

```bash
# Create manual backup marker
BACKUP_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
OPERATION="pre-migration-v2.0"

# Document backup timestamp
cat > /tmp/backup-${OPERATION}.json <<EOF
{
  "timestamp": "${BACKUP_TIMESTAMP}",
  "environment": "${ENVIRONMENT}",
  "operation": "${OPERATION}",
  "cosmosAccount": "ascension-${ENVIRONMENT}-cosmos",
  "purpose": "Manual backup before critical migration",
  "createdBy": "$(whoami)",
  "restorationCommand": "az cosmosdb restore --target-database-account-name ascension-${ENVIRONMENT}-cosmos-restored --account-name ascension-${ENVIRONMENT}-cosmos --resource-group ascension-${ENVIRONMENT}-rg --restore-timestamp ${BACKUP_TIMESTAMP} --location eastus"
}
EOF

# Store backup metadata in Storage Account for reference
az storage blob upload \
  --account-name ascension${ENVIRONMENT}st$(uniqueString) \
  --container-name backups \
  --name "manual/${OPERATION}-${BACKUP_TIMESTAMP}.json" \
  --file /tmp/backup-${OPERATION}.json

echo "Manual backup documented at timestamp: ${BACKUP_TIMESTAMP}"
echo "Use this timestamp for point-in-time restore if needed"
```

#### Redis Cache Manual Snapshot

```bash
# For Premium tier Redis, trigger manual RDB export
az redis export \
  --name ascension-${ENVIRONMENT}-redis \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --file-format RDB \
  --prefix "manual-backup-$(date +%Y%m%d-%H%M%S)" \
  --container "https://ascension${ENVIRONMENT}st.blob.core.windows.net/redis-backups" \
  --storage-subscription-id ${SUBSCRIPTION_ID}

echo "Manual Redis backup initiated"
```

#### Application State Snapshot

```bash
# Export critical application configuration
CONFIG_BACKUP_DIR="/tmp/app-config-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p $CONFIG_BACKUP_DIR

# Export environment variables
az containerapp show \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "properties.template.containers[0].env" \
  -o json > ${CONFIG_BACKUP_DIR}/environment-variables.json

# Export scaling configuration
az containerapp show \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "properties.template.scale" \
  -o json > ${CONFIG_BACKUP_DIR}/scaling-config.json

# Export ingress configuration
az containerapp show \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "properties.configuration.ingress" \
  -o json > ${CONFIG_BACKUP_DIR}/ingress-config.json

tar -czf app-config-backup-$(date +%Y%m%d-%H%M%S).tar.gz $CONFIG_BACKUP_DIR
echo "Application configuration backed up"
```

### Backup Validation

#### Monthly Backup Verification Tests

**Test 1: Cosmos DB Point-in-Time Restore Test**

```bash
#!/bin/bash
# Monthly DR drill - Cosmos DB restore validation
# Run in non-production environment

ENVIRONMENT="staging"
TEST_DATE=$(date +%Y%m%d)
RESTORE_TIMESTAMP=$(date -u --date='1 hour ago' +"%Y-%m-%dT%H:%M:%SZ")

echo "Starting Cosmos DB restore validation test: ${TEST_DATE}"

# Step 1: Create restore to temporary account
az cosmosdb restore \
  --target-database-account-name ascension-${ENVIRONMENT}-cosmos-test-${TEST_DATE} \
  --account-name ascension-${ENVIRONMENT}-cosmos \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --restore-timestamp $RESTORE_TIMESTAMP \
  --location eastus

# Step 2: Wait for restore to complete
echo "Waiting for restore to complete (typically 1-2 hours)..."
while true; do
  STATUS=$(az cosmosdb show \
    --name ascension-${ENVIRONMENT}-cosmos-test-${TEST_DATE} \
    --resource-group ascension-${ENVIRONMENT}-rg \
    --query "properties.provisioningState" -o tsv)

  if [ "$STATUS" == "Succeeded" ]; then
    echo "Restore completed successfully"
    break
  elif [ "$STATUS" == "Failed" ]; then
    echo "ERROR: Restore failed"
    exit 1
  fi

  echo "Status: $STATUS - waiting..."
  sleep 300  # Check every 5 minutes
done

# Step 3: Validate restored data
RESTORED_ENDPOINT=$(az cosmosdb show \
  --name ascension-${ENVIRONMENT}-cosmos-test-${TEST_DATE} \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "properties.documentEndpoint" -o tsv)

echo "Restored endpoint: $RESTORED_ENDPOINT"

# Query restored data to verify integrity
RECORD_COUNT=$(az cosmosdb sql container query \
  --account-name ascension-${ENVIRONMENT}-cosmos-test-${TEST_DATE} \
  --database-name project-ascension-db \
  --container-name workflow-states \
  --query "SELECT VALUE COUNT(1) FROM c" \
  -o tsv)

echo "Restored record count: $RECORD_COUNT"

# Step 4: Compare with source
SOURCE_COUNT=$(az cosmosdb sql container query \
  --account-name ascension-${ENVIRONMENT}-cosmos \
  --database-name project-ascension-db \
  --container-name workflow-states \
  --query "SELECT VALUE COUNT(1) FROM c" \
  -o tsv)

echo "Source record count: $SOURCE_COUNT"

if [ $RECORD_COUNT -gt 0 ] && [ $((SOURCE_COUNT - RECORD_COUNT)) -le 100 ]; then
  echo "PASS: Restore validation successful"
else
  echo "FAIL: Record count mismatch exceeds tolerance"
fi

# Step 5: Cleanup test resources
az cosmosdb delete \
  --name ascension-${ENVIRONMENT}-cosmos-test-${TEST_DATE} \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --yes

echo "Backup validation test completed: ${TEST_DATE}"
```

**Test 2: Full Infrastructure Recovery Drill**

```bash
#!/bin/bash
# Quarterly full DR drill
# Validates complete infrastructure rebuild

ENVIRONMENT="dev"
DR_TEST_DATE=$(date +%Y%m%d)
DR_RG="ascension-${ENVIRONMENT}-dr-test-${DR_TEST_DATE}"

echo "Starting full DR drill: ${DR_TEST_DATE}"

# Step 1: Deploy complete infrastructure to DR resource group
az group create \
  --name $DR_RG \
  --location westus2 \
  --tags "Purpose=DR-Test" "TestDate=${DR_TEST_DATE}"

az deployment sub create \
  --name "dr-test-${DR_TEST_DATE}" \
  --location westus2 \
  --template-file infra/deploy.bicep \
  --parameters infra/deploy.parameters.${ENVIRONMENT}.json \
  --parameters resourceGroupName=$DR_RG

# Step 2: Restore Cosmos DB to DR environment
RESTORE_TIMESTAMP=$(date -u --date='1 hour ago' +"%Y-%m-%dT%H:%M:%SZ")

az cosmosdb restore \
  --target-database-account-name ascension-${ENVIRONMENT}-cosmos-dr \
  --account-name ascension-${ENVIRONMENT}-cosmos \
  --resource-group $DR_RG \
  --restore-timestamp $RESTORE_TIMESTAMP \
  --location westus2

# Step 3: Deploy application to DR environment
# (Container Apps deployment would go here)

# Step 4: Run smoke tests against DR environment
echo "Running smoke tests against DR environment..."
# npm run test:smoke --env=dr-test

# Step 5: Measure RTO
RTO_END=$(date +%s)
RTO_START=$(date -d "${DR_TEST_DATE}" +%s)
RTO_DURATION=$(( (RTO_END - RTO_START) / 60 ))

echo "Measured RTO: ${RTO_DURATION} minutes"

# Step 6: Cleanup DR test environment
echo "Cleaning up DR test environment..."
az group delete --name $DR_RG --yes --no-wait

echo "DR drill completed. RTO: ${RTO_DURATION} minutes"
```

**Test 3: Redis Backup Validation**

```bash
# Verify Redis backup exists and is restorable
LATEST_BACKUP=$(az storage blob list \
  --account-name ascension${ENVIRONMENT}st$(uniqueString) \
  --container-name redis-backups \
  --query "sort_by([].{Name:name,Modified:properties.lastModified}, &Modified) | [-1].Name" \
  -o tsv)

if [ -z "$LATEST_BACKUP" ]; then
  echo "ERROR: No Redis backups found"
  exit 1
fi

echo "Latest Redis backup: $LATEST_BACKUP"

# Verify backup file integrity (size > 0)
BACKUP_SIZE=$(az storage blob show \
  --account-name ascension${ENVIRONMENT}st$(uniqueString) \
  --container-name redis-backups \
  --name $LATEST_BACKUP \
  --query "properties.contentLength" -o tsv)

if [ $BACKUP_SIZE -gt 0 ]; then
  echo "PASS: Redis backup validation successful (${BACKUP_SIZE} bytes)"
else
  echo "FAIL: Redis backup file is empty"
fi
```

## Recovery Procedures

### Phase 1: Assessment

**Incident Classification**

Classify incident severity to determine appropriate response:

| Severity | Impact | Response Time | Examples |
|----------|--------|---------------|----------|
| P0 - Critical | Complete production outage, data loss | Immediate (< 5 min) | Region failure, database corruption |
| P1 - High | Major functionality unavailable | < 15 minutes | Service degradation, partial outage |
| P2 - Medium | Minor functionality impacted | < 1 hour | Non-critical service failure |
| P3 - Low | Minimal user impact | < 4 hours | Development environment issues |

**Impact Assessment Checklist**:

```bash
# Run comprehensive impact assessment

echo "=== DISASTER RECOVERY IMPACT ASSESSMENT ==="
echo "Time: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""

# 1. Check application availability
echo "1. Application Availability:"
FQDN=$(az containerapp show \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "properties.configuration.ingress.fqdn" -o tsv 2>/dev/null || echo "UNREACHABLE")

if curl -f -s --max-time 5 https://${FQDN}/health/ready > /dev/null 2>&1; then
  echo "   Status: ONLINE"
else
  echo "   Status: OFFLINE - CRITICAL"
fi

# 2. Check database accessibility
echo "2. Database Status:"
COSMOS_STATUS=$(az cosmosdb show \
  --name ascension-${ENVIRONMENT}-cosmos \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "properties.provisioningState" -o tsv 2>/dev/null || echo "FAILED")
echo "   Cosmos DB: $COSMOS_STATUS"

# 3. Check error rates
echo "3. Error Rate (last 15 min):"
ERROR_RATE=$(az monitor app-insights query \
  --app ascension-${ENVIRONMENT}-ai \
  --analytics-query "requests | where timestamp > ago(15m) | summarize ErrorRate = round(100.0 * countif(success == false) / count(), 2)" \
  --offset 15m \
  --query "tables[0].rows[0][0]" -o tsv 2>/dev/null || echo "N/A")
echo "   Error Rate: ${ERROR_RATE}%"

# 4. Check regional health
echo "4. Azure Region Health:"
az rest --method get \
  --uri "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/providers/Microsoft.ResourceHealth/availabilityStatuses?api-version=2020-05-01" \
  --query "value[?location=='eastus' && properties.availabilityState!='Available'].{Resource:name,State:properties.availabilityState}" \
  -o table 2>/dev/null || echo "   Unable to check region health"

# 5. Affected user count estimate
echo "5. Affected Users (last 15 min):"
USER_COUNT=$(az monitor app-insights query \
  --app ascension-${ENVIRONMENT}-ai \
  --analytics-query "requests | where timestamp > ago(15m) | summarize UniqueUsers = dcount(user_Id)" \
  --offset 15m \
  --query "tables[0].rows[0][0]" -o tsv 2>/dev/null || echo "N/A")
echo "   Active Users: $USER_COUNT"

# 6. Data loss window
echo "6. Potential Data Loss Window:"
LAST_SUCCESSFUL_WRITE=$(az monitor app-insights query \
  --app ascension-${ENVIRONMENT}-ai \
  --analytics-query "dependencies | where target contains 'cosmos' and success == true | where timestamp > ago(1h) | summarize LastWrite = max(timestamp)" \
  --offset 1h \
  --query "tables[0].rows[0][0]" -o tsv 2>/dev/null || echo "N/A")
echo "   Last Successful Write: $LAST_SUCCESSFUL_WRITE"

echo ""
echo "=== ASSESSMENT COMPLETE ==="
echo "Recommended Action: [MANUAL DECISION REQUIRED]"
echo "  - P0 (Complete Outage): Initiate full DR procedures"
echo "  - P1 (Partial Outage): Investigate + targeted recovery"
echo "  - P2/P3: Standard troubleshooting + monitoring"
```

**Incident Commander Checklist**:

- [ ] Incident severity classified
- [ ] Impact scope documented (users affected, services down)
- [ ] Root cause hypothesis identified
- [ ] Recovery approach determined
- [ ] DR team activated and roles assigned
- [ ] Stakeholders notified via incident communication channel
- [ ] War room established (Teams/Slack channel)

### Phase 2: Communication

**Stakeholder Notification**

Immediate notification templates:

**Initial Notification (within 5 minutes)**:

```bash
# Send initial incident notification
INCIDENT_ID="INC-$(date +%Y%m%d-%H%M%S)"
SEVERITY="P0"
IMPACT="Complete production outage"

# Via Teams webhook
curl -X POST ${TEAMS_WEBHOOK_URL} \
  -H 'Content-Type: application/json' \
  -d "{
    \"@type\": \"MessageCard\",
    \"@context\": \"http://schema.org/extensions\",
    \"themeColor\": \"FF0000\",
    \"title\": \"INCIDENT: ${INCIDENT_ID} - ${SEVERITY}\",
    \"text\": \"Production incident detected requiring disaster recovery procedures.\",
    \"sections\": [{
      \"facts\": [
        {\"name\": \"Incident ID\", \"value\": \"${INCIDENT_ID}\"},
        {\"name\": \"Severity\", \"value\": \"${SEVERITY}\"},
        {\"name\": \"Environment\", \"value\": \"${ENVIRONMENT}\"},
        {\"name\": \"Impact\", \"value\": \"${IMPACT}\"},
        {\"name\": \"Detected At\", \"value\": \"$(date -u +"%Y-%m-%d %H:%M:%S UTC")\"},
        {\"name\": \"Incident Commander\", \"value\": \"${IC_NAME}\"},
        {\"name\": \"War Room\", \"value\": \"${WAR_ROOM_URL}\"}
      ]
    }],
    \"potentialAction\": [{
      \"@type\": \"OpenUri\",
      \"name\": \"Join War Room\",
      \"targets\": [{\"os\": \"default\", \"uri\": \"${WAR_ROOM_URL}\"}]
    }]
  }"

# Create GitHub incident issue
gh issue create \
  --title "INCIDENT ${INCIDENT_ID}: ${SEVERITY} - ${IMPACT}" \
  --label "incident,${SEVERITY},production" \
  --body "
## Incident Details
- **Incident ID**: ${INCIDENT_ID}
- **Severity**: ${SEVERITY}
- **Environment**: ${ENVIRONMENT}
- **Detected**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
- **Incident Commander**: ${IC_NAME}

## Impact
${IMPACT}

## Status
DR procedures initiated. Updates will be posted to this issue.

## War Room
${WAR_ROOM_URL}
"
```

**Hourly Status Updates**:

```bash
# Hourly status update template
UPDATE_NUMBER=1
CURRENT_STATUS="Database restore in progress (60% complete)"
ETA="2 hours"

curl -X POST ${TEAMS_WEBHOOK_URL} \
  -H 'Content-Type: application/json' \
  -d "{
    \"@type\": \"MessageCard\",
    \"themeColor\": \"FFA500\",
    \"title\": \"Update #${UPDATE_NUMBER}: ${INCIDENT_ID}\",
    \"text\": \"${CURRENT_STATUS}\",
    \"sections\": [{
      \"facts\": [
        {\"name\": \"ETA to Resolution\", \"value\": \"${ETA}\"},
        {\"name\": \"Current Phase\", \"value\": \"Data Restoration\"},
        {\"name\": \"Next Update\", \"value\": \"1 hour\"}
      ]
    }]
  }"

# Update GitHub issue
gh issue comment ${INCIDENT_ISSUE_NUMBER} \
  --body "
## Update #${UPDATE_NUMBER} - $(date -u +"%H:%M UTC")

**Status**: ${CURRENT_STATUS}
**ETA**: ${ETA}
**Current Phase**: Data Restoration

### Progress
- [x] Impact assessment complete
- [x] Backup timestamp identified
- [ ] Database restore in progress (60%)
- [ ] Application redeployment
- [ ] Validation and cutover
"
```

**Resolution Notification**:

```bash
# Final resolution notification
RESOLUTION_TIME=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
DOWNTIME_DURATION="3 hours 27 minutes"

curl -X POST ${TEAMS_WEBHOOK_URL} \
  -H 'Content-Type: application/json' \
  -d "{
    \"@type\": \"MessageCard\",
    \"themeColor\": \"00FF00\",
    \"title\": \"RESOLVED: ${INCIDENT_ID}\",
    \"text\": \"Production incident resolved. Services restored.\",
    \"sections\": [{
      \"facts\": [
        {\"name\": \"Resolved At\", \"value\": \"${RESOLUTION_TIME}\"},
        {\"name\": \"Total Downtime\", \"value\": \"${DOWNTIME_DURATION}\"},
        {\"name\": \"RTO Target\", \"value\": \"4 hours\"},
        {\"name\": \"RTO Achievement\", \"value\": \"Met\"},
        {\"name\": \"RPO\", \"value\": \"12 minutes (data loss minimized)\"}
      ]
    }]
  }"

# Close GitHub issue
gh issue close ${INCIDENT_ISSUE_NUMBER} \
  --comment "
## Incident Resolved

**Resolution Time**: ${RESOLUTION_TIME}
**Total Downtime**: ${DOWNTIME_DURATION}
**RTO Target**: 4 hours ✓ Met
**RPO**: 12 minutes (minimal data loss)

### Recovery Summary
- Database restored from continuous backup
- Application redeployed and validated
- All health checks passing
- User traffic restored

### Next Steps
- Post-incident review scheduled for tomorrow
- Root cause analysis in progress
- Runbook updates based on lessons learned
"
```

**Communication Matrix**:

| Stakeholder Group | Initial | Updates | Resolution | Channel |
|-------------------|---------|---------|------------|---------|
| Executive Team | Within 15 min | Every 2 hours | Immediate | Email + Teams |
| Engineering Leadership | Within 5 min | Hourly | Immediate | Teams + War Room |
| Customer Success | Within 30 min | Every hour | Immediate | Email + Slack |
| DR Team | Immediate | Real-time | Immediate | War Room |
| All Staff | Within 1 hour | Every 4 hours | Immediate | Email |

### Phase 3: Failover

**Multi-Region Failover Procedure**

For production environments with geo-redundancy configured:

```bash
#!/bin/bash
# Regional failover to secondary region (westus2)

ENVIRONMENT="prod"
PRIMARY_REGION="eastus"
SECONDARY_REGION="westus2"
FAILOVER_DATE=$(date +%Y%m%d-%H%M%S)

echo "=== INITIATING REGIONAL FAILOVER ==="
echo "From: $PRIMARY_REGION"
echo "To: $SECONDARY_REGION"
echo "Timestamp: $(date -u)"

# Step 1: Verify secondary region health
echo "Step 1: Verifying secondary region availability..."
SECONDARY_HEALTH=$(az rest --method get \
  --uri "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/providers/Microsoft.ResourceHealth/availabilityStatuses?api-version=2020-05-01" \
  --query "value[?location=='${SECONDARY_REGION}'].properties.availabilityState" -o tsv)

if [ "$SECONDARY_HEALTH" != "Available" ]; then
  echo "ERROR: Secondary region is not available"
  exit 1
fi
echo "Secondary region is healthy"

# Step 2: Cosmos DB failover (if multi-region configured)
echo "Step 2: Initiating Cosmos DB failover..."
az cosmosdb failover-priority-change \
  --name ascension-${ENVIRONMENT}-cosmos \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --failover-policies "${SECONDARY_REGION}=0 ${PRIMARY_REGION}=1"

echo "Waiting for Cosmos DB failover to complete..."
while true; do
  COSMOS_STATUS=$(az cosmosdb show \
    --name ascension-${ENVIRONMENT}-cosmos \
    --resource-group ascension-${ENVIRONMENT}-rg \
    --query "properties.provisioningState" -o tsv)

  if [ "$COSMOS_STATUS" == "Succeeded" ]; then
    echo "Cosmos DB failover complete"
    break
  fi
  sleep 30
done

# Step 3: Deploy application to secondary region
echo "Step 3: Deploying application to secondary region..."
SECONDARY_RG="ascension-${ENVIRONMENT}-${SECONDARY_REGION}-rg"

# Create secondary resource group if not exists
az group create \
  --name $SECONDARY_RG \
  --location $SECONDARY_REGION \
  --tags "Role=DR-Secondary" "FailoverDate=${FAILOVER_DATE}"

# Deploy infrastructure to secondary region
az deployment sub create \
  --name "failover-${FAILOVER_DATE}" \
  --location $SECONDARY_REGION \
  --template-file infra/deploy.bicep \
  --parameters infra/deploy.parameters.${ENVIRONMENT}.json \
  --parameters resourceGroupName=$SECONDARY_RG \
  --parameters location=$SECONDARY_REGION

echo "Secondary region deployment complete"

# Step 4: Update DNS/Traffic Manager
echo "Step 4: Updating Traffic Manager routing..."

# If using Azure Traffic Manager
az network traffic-manager endpoint update \
  --name ${SECONDARY_REGION}-endpoint \
  --profile-name ascension-${ENVIRONMENT}-tm \
  --resource-group ascension-${ENVIRONMENT}-global-rg \
  --type azureEndpoints \
  --endpoint-status Enabled \
  --priority 1

az network traffic-manager endpoint update \
  --name ${PRIMARY_REGION}-endpoint \
  --profile-name ascension-${ENVIRONMENT}-tm \
  --resource-group ascension-${ENVIRONMENT}-global-rg \
  --type azureEndpoints \
  --endpoint-status Disabled \
  --priority 2

# If using Azure Front Door
# az afd route update [...]

echo "Traffic routing updated to secondary region"

# Step 5: Validate failover
echo "Step 5: Validating failover..."
SECONDARY_FQDN=$(az containerapp show \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group $SECONDARY_RG \
  --query "properties.configuration.ingress.fqdn" -o tsv)

# Health check
if curl -f -s https://${SECONDARY_FQDN}/health/ready > /dev/null; then
  echo "SUCCESS: Secondary region is healthy and serving traffic"
else
  echo "ERROR: Secondary region health check failed"
  exit 1
fi

# Monitor error rates for 5 minutes
echo "Monitoring error rates for 5 minutes..."
sleep 300

ERROR_RATE=$(az monitor app-insights query \
  --app ascension-${ENVIRONMENT}-ai \
  --analytics-query "requests | where timestamp > ago(5m) | summarize ErrorRate = 100.0 * countif(success == false) / count()" \
  --offset 5m \
  --query "tables[0].rows[0][0]" -o tsv)

if (( $(echo "$ERROR_RATE < 5.0" | bc -l) )); then
  echo "SUCCESS: Error rate acceptable (${ERROR_RATE}%)"
else
  echo "WARNING: Elevated error rate (${ERROR_RATE}%)"
fi

echo ""
echo "=== FAILOVER COMPLETE ==="
echo "Primary Region: $PRIMARY_REGION (OFFLINE)"
echo "Secondary Region: $SECONDARY_REGION (ACTIVE)"
echo "FQDN: https://${SECONDARY_FQDN}"
echo ""
echo "Next steps:"
echo "1. Continue monitoring secondary region"
echo "2. Investigate primary region failure"
echo "3. Plan failback when primary region is restored"
```

### Phase 4: Data Restoration

**Cosmos DB Point-in-Time Restore**

Complete procedure for restoring Cosmos DB from continuous backup:

```bash
#!/bin/bash
# Cosmos DB point-in-time restore procedure

ENVIRONMENT="prod"
RG_NAME="ascension-${ENVIRONMENT}-rg"
SOURCE_ACCOUNT="ascension-${ENVIRONMENT}-cosmos"
RESTORE_TIMESTAMP="2025-10-09T10:00:00Z"  # Specify exact restore point
RESTORE_ACCOUNT="${SOURCE_ACCOUNT}-restored-$(date +%Y%m%d-%H%M%S)"

echo "=== COSMOS DB RESTORE PROCEDURE ==="
echo "Source Account: $SOURCE_ACCOUNT"
echo "Restore Timestamp: $RESTORE_TIMESTAMP"
echo "Target Account: $RESTORE_ACCOUNT"
echo ""

# Step 1: Validate restore timestamp is within backup window
echo "Step 1: Validating restore timestamp..."
BACKUP_TYPE=$(az cosmosdb show \
  --name $SOURCE_ACCOUNT \
  --resource-group $RG_NAME \
  --query "backupPolicy.type" -o tsv)

if [ "$BACKUP_TYPE" != "Continuous" ]; then
  echo "ERROR: Continuous backup is not enabled"
  exit 1
fi

echo "Continuous backup confirmed (7-day retention)"

# Validate timestamp format
if ! date -d "$RESTORE_TIMESTAMP" >/dev/null 2>&1; then
  echo "ERROR: Invalid timestamp format. Use ISO 8601: YYYY-MM-DDTHH:MM:SSZ"
  exit 1
fi

# Step 2: Initiate restore
echo "Step 2: Initiating point-in-time restore..."
echo "This operation will take 1-2 hours depending on database size"

az cosmosdb restore \
  --target-database-account-name $RESTORE_ACCOUNT \
  --account-name $SOURCE_ACCOUNT \
  --resource-group $RG_NAME \
  --restore-timestamp $RESTORE_TIMESTAMP \
  --location eastus

# Step 3: Monitor restore progress
echo "Step 3: Monitoring restore progress..."
START_TIME=$(date +%s)

while true; do
  STATUS=$(az cosmosdb show \
    --name $RESTORE_ACCOUNT \
    --resource-group $RG_NAME \
    --query "properties.provisioningState" -o tsv 2>/dev/null || echo "NotFound")

  ELAPSED=$(( ($(date +%s) - START_TIME) / 60 ))

  echo "Status: $STATUS (Elapsed: ${ELAPSED} minutes)"

  if [ "$STATUS" == "Succeeded" ]; then
    echo "Restore completed successfully"
    break
  elif [ "$STATUS" == "Failed" ]; then
    echo "ERROR: Restore failed"
    az cosmosdb show \
      --name $RESTORE_ACCOUNT \
      --resource-group $RG_NAME \
      --query "properties" -o json
    exit 1
  fi

  sleep 300  # Check every 5 minutes
done

# Step 4: Validate restored data
echo "Step 4: Validating restored data..."
RESTORED_ENDPOINT=$(az cosmosdb show \
  --name $RESTORE_ACCOUNT \
  --resource-group $RG_NAME \
  --query "properties.documentEndpoint" -o tsv)

echo "Restored endpoint: $RESTORED_ENDPOINT"

# Get connection key
RESTORED_KEY=$(az cosmosdb keys list \
  --name $RESTORE_ACCOUNT \
  --resource-group $RG_NAME \
  --query "primaryMasterKey" -o tsv)

# Validate all containers exist
CONTAINERS=("workflow-states" "agent-memories" "agent-metrics" "tool-invocations" "thread-message-store" "system-thread-message-store" "agent-entity-store")

for container in "${CONTAINERS[@]}"; do
  COUNT=$(az cosmosdb sql container query \
    --account-name $RESTORE_ACCOUNT \
    --database-name project-ascension-db \
    --container-name $container \
    --query "SELECT VALUE COUNT(1) FROM c" \
    -o tsv 2>/dev/null || echo "0")

  echo "Container: $container - Record count: $COUNT"
done

# Step 5: Cutover application to restored database
echo "Step 5: Preparing cutover to restored database..."

# Update Key Vault with new connection string
COSMOS_CONNECTION_STRING="${RESTORED_ENDPOINT}:${RESTORED_KEY}"

az keyvault secret set \
  --vault-name ascension-${ENVIRONMENT}-kv \
  --name COSMOS-ENDPOINT \
  --value $RESTORED_ENDPOINT

# Restart Container Apps to pick up new connection
az containerapp revision copy \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group $RG_NAME \
  --revision-suffix "cosmos-restore-$(date +%Y%m%d-%H%M%S)"

echo "Application updated to use restored database"

# Step 6: Validation
echo "Step 6: Post-cutover validation..."
sleep 60

# Check application health
FQDN=$(az containerapp show \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group $RG_NAME \
  --query "properties.configuration.ingress.fqdn" -o tsv)

if curl -f -s https://${FQDN}/health/ready | grep -q "cosmos.*healthy"; then
  echo "SUCCESS: Application connected to restored database"
else
  echo "WARNING: Application health check shows database issues"
fi

# Monitor for errors
ERROR_RATE=$(az monitor app-insights query \
  --app ascension-${ENVIRONMENT}-ai \
  --analytics-query "requests | where timestamp > ago(5m) | summarize ErrorRate = 100.0 * countif(success == false) / count()" \
  --offset 5m \
  --query "tables[0].rows[0][0]" -o tsv)

echo "Error rate: ${ERROR_RATE}%"

# Step 7: Cleanup old database (after validation period)
echo ""
echo "=== RESTORE COMPLETE ==="
echo "Restored Account: $RESTORE_ACCOUNT"
echo "Endpoint: $RESTORED_ENDPOINT"
echo ""
echo "IMPORTANT: Old database account ($SOURCE_ACCOUNT) has NOT been deleted"
echo "After confirming restore success (24-48 hours), delete old account:"
echo "  az cosmosdb delete --name $SOURCE_ACCOUNT --resource-group $RG_NAME --yes"
```

**Redis Cache Restore**

```bash
#!/bin/bash
# Redis Cache restore from RDB backup

ENVIRONMENT="prod"
REDIS_NAME="ascension-${ENVIRONMENT}-redis"
RG_NAME="ascension-${ENVIRONMENT}-rg"
STORAGE_ACCOUNT="ascension${ENVIRONMENT}st$(uniqueString)"

echo "=== REDIS CACHE RESTORE ==="

# Step 1: Find latest backup
LATEST_BACKUP=$(az storage blob list \
  --account-name $STORAGE_ACCOUNT \
  --container-name redis-backups \
  --query "sort_by([].{Name:name,Modified:properties.lastModified}, &Modified) | [-1].Name" \
  -o tsv)

if [ -z "$LATEST_BACKUP" ]; then
  echo "ERROR: No backups found"
  exit 1
fi

echo "Latest backup: $LATEST_BACKUP"

# Step 2: Import backup to Redis
echo "Importing backup to Redis Cache..."
az redis import \
  --name $REDIS_NAME \
  --resource-group $RG_NAME \
  --file-format RDB \
  --files "https://${STORAGE_ACCOUNT}.blob.core.windows.net/redis-backups/${LATEST_BACKUP}" \
  --storage-subscription-id $SUBSCRIPTION_ID

# Step 3: Monitor import progress
echo "Monitoring import progress..."
while true; do
  STATUS=$(az redis show \
    --name $REDIS_NAME \
    --resource-group $RG_NAME \
    --query "provisioningState" -o tsv)

  if [ "$STATUS" == "Succeeded" ]; then
    echo "Redis restore complete"
    break
  elif [ "$STATUS" == "Failed" ]; then
    echo "ERROR: Redis restore failed"
    exit 1
  fi

  echo "Status: $STATUS"
  sleep 30
done

# Step 4: Verify cache connectivity
REDIS_HOSTNAME=$(az redis show \
  --name $REDIS_NAME \
  --resource-group $RG_NAME \
  --query "hostName" -o tsv)

echo "Redis Cache restored: $REDIS_HOSTNAME"
echo "Verify application connectivity via health checks"
```

### Phase 5: Validation

**Comprehensive Post-Recovery Validation**

```bash
#!/bin/bash
# Post-recovery validation suite

ENVIRONMENT="prod"
VALIDATION_RESULTS_FILE="/tmp/dr-validation-$(date +%Y%m%d-%H%M%S).log"

echo "=== DISASTER RECOVERY VALIDATION ===" | tee $VALIDATION_RESULTS_FILE
echo "Timestamp: $(date -u)" | tee -a $VALIDATION_RESULTS_FILE
echo "" | tee -a $VALIDATION_RESULTS_FILE

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test 1: Application Health
echo "Test 1: Application Health Check" | tee -a $VALIDATION_RESULTS_FILE
TOTAL_TESTS=$((TOTAL_TESTS + 1))

FQDN=$(az containerapp show \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "properties.configuration.ingress.fqdn" -o tsv)

HEALTH_RESPONSE=$(curl -s https://${FQDN}/health/ready)

if echo "$HEALTH_RESPONSE" | grep -q '"status":"ready"'; then
  echo "  PASS: Application is healthy" | tee -a $VALIDATION_RESULTS_FILE
  PASSED_TESTS=$((PASSED_TESTS + 1))
else
  echo "  FAIL: Application health check failed" | tee -a $VALIDATION_RESULTS_FILE
  echo "  Response: $HEALTH_RESPONSE" | tee -a $VALIDATION_RESULTS_FILE
  FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# Test 2: Database Connectivity
echo "Test 2: Database Connectivity" | tee -a $VALIDATION_RESULTS_FILE
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if echo "$HEALTH_RESPONSE" | grep -q '"cosmos":"healthy"'; then
  echo "  PASS: Cosmos DB connection healthy" | tee -a $VALIDATION_RESULTS_FILE
  PASSED_TESTS=$((PASSED_TESTS + 1))
else
  echo "  FAIL: Cosmos DB connection failed" | tee -a $VALIDATION_RESULTS_FILE
  FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# Test 3: Redis Connectivity
echo "Test 3: Redis Cache Connectivity" | tee -a $VALIDATION_RESULTS_FILE
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if echo "$HEALTH_RESPONSE" | grep -q '"redis":"healthy"'; then
  echo "  PASS: Redis connection healthy" | tee -a $VALIDATION_RESULTS_FILE
  PASSED_TESTS=$((PASSED_TESTS + 1))
else
  echo "  FAIL: Redis connection failed" | tee -a $VALIDATION_RESULTS_FILE
  FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# Test 4: OpenAI Connectivity
echo "Test 4: Azure OpenAI Connectivity" | tee -a $VALIDATION_RESULTS_FILE
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if echo "$HEALTH_RESPONSE" | grep -q '"openai":"healthy"'; then
  echo "  PASS: OpenAI connection healthy" | tee -a $VALIDATION_RESULTS_FILE
  PASSED_TESTS=$((PASSED_TESTS + 1))
else
  echo "  FAIL: OpenAI connection failed" | tee -a $VALIDATION_RESULTS_FILE
  FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# Test 5: SignalR Connectivity
echo "Test 5: SignalR Service Connectivity" | tee -a $VALIDATION_RESULTS_FILE
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if echo "$HEALTH_RESPONSE" | grep -q '"signalr":"healthy"'; then
  echo "  PASS: SignalR connection healthy" | tee -a $VALIDATION_RESULTS_FILE
  PASSED_TESTS=$((PASSED_TESTS + 1))
else
  echo "  FAIL: SignalR connection failed" | tee -a $VALIDATION_RESULTS_FILE
  FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# Test 6: AI Search Connectivity
echo "Test 6: Azure AI Search Connectivity" | tee -a $VALIDATION_RESULTS_FILE
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if echo "$HEALTH_RESPONSE" | grep -q '"search":"healthy"'; then
  echo "  PASS: AI Search connection healthy" | tee -a $VALIDATION_RESULTS_FILE
  PASSED_TESTS=$((PASSED_TESTS + 1))
else
  echo "  FAIL: AI Search connection failed" | tee -a $VALIDATION_RESULTS_FILE
  FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# Test 7: Error Rate
echo "Test 7: Application Error Rate" | tee -a $VALIDATION_RESULTS_FILE
TOTAL_TESTS=$((TOTAL_TESTS + 1))

ERROR_RATE=$(az monitor app-insights query \
  --app ascension-${ENVIRONMENT}-ai \
  --analytics-query "requests | where timestamp > ago(10m) | summarize ErrorRate = round(100.0 * countif(success == false) / count(), 2)" \
  --offset 10m \
  --query "tables[0].rows[0][0]" -o tsv 2>/dev/null || echo "100")

if (( $(echo "$ERROR_RATE < 5.0" | bc -l) )); then
  echo "  PASS: Error rate acceptable (${ERROR_RATE}%)" | tee -a $VALIDATION_RESULTS_FILE
  PASSED_TESTS=$((PASSED_TESTS + 1))
else
  echo "  FAIL: Error rate too high (${ERROR_RATE}%)" | tee -a $VALIDATION_RESULTS_FILE
  FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# Test 8: Response Time
echo "Test 8: Application Response Time" | tee -a $VALIDATION_RESULTS_FILE
TOTAL_TESTS=$((TOTAL_TESTS + 1))

P95_LATENCY=$(az monitor app-insights query \
  --app ascension-${ENVIRONMENT}-ai \
  --analytics-query "requests | where timestamp > ago(10m) | summarize P95 = percentile(duration, 95)" \
  --offset 10m \
  --query "tables[0].rows[0][0]" -o tsv 2>/dev/null || echo "10000")

if (( $(echo "$P95_LATENCY < 3000" | bc -l) )); then
  echo "  PASS: P95 latency acceptable (${P95_LATENCY}ms)" | tee -a $VALIDATION_RESULTS_FILE
  PASSED_TESTS=$((PASSED_TESTS + 1))
else
  echo "  FAIL: P95 latency too high (${P95_LATENCY}ms)" | tee -a $VALIDATION_RESULTS_FILE
  FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# Test 9: Replica Health
echo "Test 9: Container Replica Health" | tee -a $VALIDATION_RESULTS_FILE
TOTAL_TESTS=$((TOTAL_TESTS + 1))

UNHEALTHY_REPLICAS=$(az containerapp replica list \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "[?properties.healthState!='Healthy'].name" -o tsv | wc -l)

if [ $UNHEALTHY_REPLICAS -eq 0 ]; then
  echo "  PASS: All replicas healthy" | tee -a $VALIDATION_RESULTS_FILE
  PASSED_TESTS=$((PASSED_TESTS + 1))
else
  echo "  FAIL: $UNHEALTHY_REPLICAS unhealthy replicas" | tee -a $VALIDATION_RESULTS_FILE
  FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# Test 10: Smoke Test - Create Agent
echo "Test 10: Smoke Test - Agent Creation" | tee -a $VALIDATION_RESULTS_FILE
TOTAL_TESTS=$((TOTAL_TESTS + 1))

CREATE_RESPONSE=$(curl -s -X POST https://${FQDN}/api/agents \
  -H "Content-Type: application/json" \
  -d '{"name":"dr-validation-agent","type":"test"}' \
  --max-time 10 2>/dev/null || echo "FAILED")

if echo "$CREATE_RESPONSE" | grep -q '"id"'; then
  echo "  PASS: Agent creation successful" | tee -a $VALIDATION_RESULTS_FILE
  PASSED_TESTS=$((PASSED_TESTS + 1))

  # Cleanup test agent
  AGENT_ID=$(echo "$CREATE_RESPONSE" | jq -r '.id' 2>/dev/null)
  if [ -n "$AGENT_ID" ] && [ "$AGENT_ID" != "null" ]; then
    curl -s -X DELETE https://${FQDN}/api/agents/${AGENT_ID} >/dev/null 2>&1
  fi
else
  echo "  FAIL: Agent creation failed" | tee -a $VALIDATION_RESULTS_FILE
  FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# Summary
echo "" | tee -a $VALIDATION_RESULTS_FILE
echo "=== VALIDATION SUMMARY ===" | tee -a $VALIDATION_RESULTS_FILE
echo "Total Tests: $TOTAL_TESTS" | tee -a $VALIDATION_RESULTS_FILE
echo "Passed: $PASSED_TESTS" | tee -a $VALIDATION_RESULTS_FILE
echo "Failed: $FAILED_TESTS" | tee -a $VALIDATION_RESULTS_FILE
echo "" | tee -a $VALIDATION_RESULTS_FILE

if [ $FAILED_TESTS -eq 0 ]; then
  echo "STATUS: ALL TESTS PASSED - Recovery Successful" | tee -a $VALIDATION_RESULTS_FILE
  exit 0
else
  echo "STATUS: VALIDATION FAILED - Investigation Required" | tee -a $VALIDATION_RESULTS_FILE
  exit 1
fi
```

**Success Criteria Checklist**:

- [ ] All health endpoints return 200 OK
- [ ] All dependencies (Cosmos, Redis, OpenAI, SignalR, AI Search) healthy
- [ ] Error rate < 1% sustained for 15 minutes
- [ ] P95 latency < 2000ms
- [ ] All container replicas in healthy state
- [ ] Smoke tests pass (agent creation, query, orchestration)
- [ ] No critical exceptions in Application Insights
- [ ] Monitoring dashboards show normal metrics
- [ ] User acceptance testing passes
- [ ] Data integrity verified (record counts match expectations)

### Phase 6: Failback

**Returning to Primary Region**

After primary region is restored and stable:

```bash
#!/bin/bash
# Failback to primary region procedure

ENVIRONMENT="prod"
PRIMARY_REGION="eastus"
SECONDARY_REGION="westus2"
PRIMARY_RG="ascension-${ENVIRONMENT}-rg"
SECONDARY_RG="ascension-${ENVIRONMENT}-${SECONDARY_REGION}-rg"

echo "=== FAILBACK TO PRIMARY REGION ==="
echo "From: $SECONDARY_REGION (current)"
echo "To: $PRIMARY_REGION (primary)"

# Step 1: Verify primary region is healthy
echo "Step 1: Verifying primary region health..."
PRIMARY_HEALTH=$(az rest --method get \
  --uri "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/providers/Microsoft.ResourceHealth/availabilityStatuses?api-version=2020-05-01" \
  --query "value[?location=='${PRIMARY_REGION}'].properties.availabilityState" -o tsv)

if [ "$PRIMARY_HEALTH" != "Available" ]; then
  echo "ERROR: Primary region is not yet healthy"
  exit 1
fi

echo "Primary region is healthy"

# Step 2: Sync data from secondary to primary Cosmos DB
echo "Step 2: Syncing data to primary region..."
# Cosmos DB will auto-sync if multi-region configured
# Verify replication lag
REPLICATION_LAG=$(az cosmosdb show \
  --name ascension-${ENVIRONMENT}-cosmos \
  --resource-group $PRIMARY_RG \
  --query "locations[?locationName=='${PRIMARY_REGION}'].failoverPriority" -o tsv)

echo "Replication status verified"

# Step 3: Update Traffic Manager to route to primary
echo "Step 3: Updating traffic routing to primary region..."

az network traffic-manager endpoint update \
  --name ${PRIMARY_REGION}-endpoint \
  --profile-name ascension-${ENVIRONMENT}-tm \
  --resource-group ascension-${ENVIRONMENT}-global-rg \
  --endpoint-status Enabled \
  --priority 1

az network traffic-manager endpoint update \
  --name ${SECONDARY_REGION}-endpoint \
  --profile-name ascension-${ENVIRONMENT}-tm \
  --resource-group ascension-${ENVIRONMENT}-global-rg \
  --endpoint-status Enabled \
  --priority 2

echo "Traffic routing updated - gradual failback initiated"

# Step 4: Monitor traffic shift
echo "Step 4: Monitoring traffic shift for 30 minutes..."
for i in {1..6}; do
  sleep 300  # 5 minutes

  ERROR_RATE=$(az monitor app-insights query \
    --app ascension-${ENVIRONMENT}-ai \
    --analytics-query "requests | where timestamp > ago(5m) | summarize ErrorRate = 100.0 * countif(success == false) / count()" \
    --offset 5m \
    --query "tables[0].rows[0][0]" -o tsv)

  echo "Minute $(($i * 5)): Error rate ${ERROR_RATE}%"

  if (( $(echo "$ERROR_RATE > 5.0" | bc -l) )); then
    echo "ERROR: High error rate detected - aborting failback"
    # Revert to secondary
    az network traffic-manager endpoint update \
      --name ${SECONDARY_REGION}-endpoint \
      --profile-name ascension-${ENVIRONMENT}-tm \
      --resource-group ascension-${ENVIRONMENT}-global-rg \
      --priority 1
    exit 1
  fi
done

echo "Failback successful - primary region is active"

# Step 5: Decommission secondary region resources (after grace period)
echo ""
echo "=== FAILBACK COMPLETE ==="
echo "Primary region ($PRIMARY_REGION) is now active"
echo "Secondary region ($SECONDARY_REGION) is on standby"
echo ""
echo "After 24-hour grace period, consider scaling down secondary region:"
echo "  az containerapp update --name ascension-${ENVIRONMENT}-ca --resource-group $SECONDARY_RG --min-replicas 0 --max-replicas 1"
```

## Component-Specific Recovery

### Container Apps

**Redeployment Procedure**:

```bash
# Redeploy Container App from ACR image
ENVIRONMENT="prod"
IMAGE_TAG="last-known-good"  # or specific SHA
ACR_NAME="ascension${ENVIRONMENT}acr$(uniqueString)"

az containerapp update \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --image ${ACR_NAME}.azurecr.io/project-ascension-api:${IMAGE_TAG} \
  --revision-suffix "dr-recovery-$(date +%Y%m%d-%H%M%S)"

# Verify deployment
az containerapp show \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "properties.{ProvisioningState:provisioningState,HealthState:latestRevisionHealth}" \
  -o json
```

### Cosmos DB

**Container Recreation**:

If containers are accidentally deleted:

```bash
# Restore entire database account (recommended)
# See Phase 4: Data Restoration

# Alternative: Recreate containers manually
CONTAINERS=("workflow-states" "agent-memories" "agent-metrics" "tool-invocations" "thread-message-store" "system-thread-message-store" "agent-entity-store")

for container in "${CONTAINERS[@]}"; do
  echo "Recreating container: $container"

  # Determine partition key based on container
  case $container in
    "workflow-states")
      PARTITION_KEY="/workflow_id"
      ;;
    "agent-memories")
      PARTITION_KEY="/agent_id"
      ;;
    "agent-metrics"|"tool-invocations")
      PARTITION_KEY="/metric_date"
      ;;
    *)
      PARTITION_KEY="/id"
      ;;
  esac

  az cosmosdb sql container create \
    --account-name ascension-${ENVIRONMENT}-cosmos \
    --database-name project-ascension-db \
    --name $container \
    --partition-key-path $PARTITION_KEY \
    --throughput 400
done
```

### Redis Cache

**Cache Repopulation**:

If cache is lost and backup restore is not possible:

```bash
# Cache will be repopulated automatically from application logic
# Verify Redis is accessible
REDIS_HOSTNAME=$(az redis show \
  --name ascension-${ENVIRONMENT}-redis \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "hostName" -o tsv)

# Warm cache by triggering common queries
curl -X POST https://ascension-${ENVIRONMENT}.azurecontainerapps.io/api/admin/cache/warm

# Monitor cache hit rate
az redis show-statistics \
  --name ascension-${ENVIRONMENT}-redis \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "{UsedMemory:usedMemory,CacheHitRate:cacheHitRate}" \
  -o json
```

### Key Vault

**Secret Recovery**:

If Key Vault is soft-deleted:

```bash
# Recover soft-deleted Key Vault
az keyvault recover \
  --name ascension-${ENVIRONMENT}-kv \
  --location eastus

# Recover soft-deleted secrets
DELETED_SECRETS=$(az keyvault secret list-deleted \
  --vault-name ascension-${ENVIRONMENT}-kv \
  --query "[].name" -o tsv)

for secret in $DELETED_SECRETS; do
  echo "Recovering secret: $secret"
  az keyvault secret recover \
    --vault-name ascension-${ENVIRONMENT}-kv \
    --name $secret
done
```

If Key Vault is permanently deleted, recreate and repopulate:

```bash
# Recreate Key Vault
az keyvault create \
  --name ascension-${ENVIRONMENT}-kv \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --location eastus \
  --enable-rbac-authorization true \
  --enable-soft-delete true \
  --enable-purge-protection true

# Repopulate secrets from secure backup or source services
az keyvault secret set \
  --vault-name ascension-${ENVIRONMENT}-kv \
  --name AZURE-OPENAI-KEY \
  --value $(az cognitiveservices account keys list --name ascension-${ENVIRONMENT}-openai --resource-group ascension-${ENVIRONMENT}-rg --query "key1" -o tsv)

az keyvault secret set \
  --vault-name ascension-${ENVIRONMENT}-kv \
  --name AZURE-SEARCH-KEY \
  --value $(az search admin-key show --service-name ascension-${ENVIRONMENT}-search --resource-group ascension-${ENVIRONMENT}-rg --query "primaryKey" -o tsv)

# Additional secrets...
```

### Storage Accounts

**Blob Recovery**:

```bash
# For GRS storage, failover to secondary region
az storage account failover \
  --name ascension${ENVIRONMENT}st$(uniqueString) \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --yes

# For LRS storage with soft delete enabled
# Undelete soft-deleted blobs
az storage blob undelete \
  --account-name ascension${ENVIRONMENT}st$(uniqueString) \
  --container-name backups \
  --name deleted-file.json
```

## Business Continuity

### Critical Functions

**Must-Maintain Services** (cannot be degraded):

1. **Agent Orchestration**: Core meta-agent coordination
2. **Data Persistence**: Workflow state and agent memory storage
3. **Authentication**: User access and API authentication
4. **Monitoring**: System health visibility

**Can-Degrade Services** (acceptable reduced functionality):

1. **Real-time Updates**: SignalR can fall back to polling
2. **Caching**: Redis provides performance, not availability
3. **Search**: Can use direct Cosmos DB queries
4. **Analytics**: Historical data access can be delayed

### Degraded Mode Operation

**Minimal Viable System**:

```bash
# Configure application for degraded mode
az containerapp update \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --set-env-vars \
    DEGRADED_MODE=true \
    SIGNALR_ENABLED=false \
    REDIS_ENABLED=false \
    SEARCH_ENABLED=false

# Scale down to minimum viable replicas
az containerapp update \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --min-replicas 1 \
  --max-replicas 2

echo "Application running in degraded mode"
echo "- Core functionality: AVAILABLE"
echo "- Real-time updates: DISABLED (polling fallback)"
echo "- Caching: DISABLED (direct database queries)"
echo "- Search: DISABLED (basic query fallback)"
```

**Degraded Mode Features**:
- Core agent operations continue
- Database reads/writes functional
- Authentication/authorization active
- Reduced performance (no caching)
- No real-time notifications (polling instead)
- Basic search only (no semantic search)

### Communication Plan

**Status Page Updates**:

```bash
# Update status page (via API or manual)
curl -X POST ${STATUS_PAGE_API_URL} \
  -H "Authorization: Bearer ${STATUS_PAGE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "major_outage",
    "message": "Experiencing database issues. Disaster recovery in progress. ETA: 3 hours.",
    "components": [
      {"id": "api", "status": "major_outage"},
      {"id": "webapp", "status": "degraded_performance"},
      {"id": "realtime", "status": "operational"}
    ]
  }'
```

**Escalation Path**:

1. **Level 1** (0-15 min): On-call engineer begins investigation
2. **Level 2** (15-30 min): Engineering lead engaged if not resolved
3. **Level 3** (30-60 min): Engineering manager and DR team activated
4. **Level 4** (60+ min): Executive team notified, all hands on deck

## Testing and Validation

### DR Testing Schedule

**Quarterly Full DR Drill** (Production, off-hours):
- Complete infrastructure failure simulation
- Full recovery procedure execution
- Measured RTO/RPO validation
- Runbook accuracy verification

**Monthly Component Test** (Staging):
- Cosmos DB restore validation
- Container App redeployment
- Failover procedure testing
- Backup integrity checks

**Weekly Backup Verification**:
- Automated backup existence checks
- Backup file integrity validation
- Recovery timestamp documentation

### Test Procedures

**Quarterly DR Drill Runbook**:

```bash
#!/bin/bash
# Quarterly DR drill procedure

DRILL_DATE=$(date +%Y%m%d)
DRILL_LOG="/tmp/dr-drill-${DRILL_DATE}.log"

echo "=== QUARTERLY DR DRILL ===" | tee $DRILL_LOG
echo "Date: $(date)" | tee -a $DRILL_LOG
echo "Environment: Staging (production simulation)" | tee -a $DRILL_LOG

# Record start time for RTO measurement
START_TIME=$(date +%s)

# Phase 1: Simulate region failure
echo "Phase 1: Simulating regional failure..." | tee -a $DRILL_LOG
ENVIRONMENT="staging"

# Disable primary region resources
az containerapp ingress disable \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg

echo "Primary region disabled" | tee -a $DRILL_LOG

# Phase 2: Execute recovery procedures
echo "Phase 2: Executing recovery procedures..." | tee -a $DRILL_LOG

# 2a: Deploy to secondary region
SECONDARY_REGION="westus2"
SECONDARY_RG="ascension-${ENVIRONMENT}-dr-${DRILL_DATE}"

az group create \
  --name $SECONDARY_RG \
  --location $SECONDARY_REGION

az deployment sub create \
  --name "dr-drill-${DRILL_DATE}" \
  --location $SECONDARY_REGION \
  --template-file infra/deploy.bicep \
  --parameters infra/deploy.parameters.${ENVIRONMENT}.json \
  --parameters resourceGroupName=$SECONDARY_RG \
  --parameters location=$SECONDARY_REGION

# 2b: Restore database
RESTORE_TIMESTAMP=$(date -u --date='1 hour ago' +"%Y-%m-%dT%H:%M:%SZ")

az cosmosdb restore \
  --target-database-account-name ascension-${ENVIRONMENT}-cosmos-dr \
  --account-name ascension-${ENVIRONMENT}-cosmos \
  --resource-group $SECONDARY_RG \
  --restore-timestamp $RESTORE_TIMESTAMP \
  --location $SECONDARY_REGION

# Wait for restore
echo "Waiting for database restore..." | tee -a $DRILL_LOG
# (Monitoring loop here)

# 2c: Deploy application
# (Container Apps deployment here)

# Phase 3: Validation
echo "Phase 3: Validation..." | tee -a $DRILL_LOG

# Run validation suite
# (Execute validation script from Phase 5)

# Phase 4: Measure RTO
END_TIME=$(date +%s)
ACTUAL_RTO=$(( (END_TIME - START_TIME) / 60 ))
TARGET_RTO=240  # 4 hours

echo "Measured RTO: ${ACTUAL_RTO} minutes" | tee -a $DRILL_LOG
echo "Target RTO: ${TARGET_RTO} minutes" | tee -a $DRILL_LOG

if [ $ACTUAL_RTO -le $TARGET_RTO ]; then
  echo "RTO TARGET: MET" | tee -a $DRILL_LOG
else
  echo "RTO TARGET: MISSED (exceeded by $(($ACTUAL_RTO - $TARGET_RTO)) minutes)" | tee -a $DRILL_LOG
fi

# Phase 5: Cleanup
echo "Phase 5: Cleanup..." | tee -a $DRILL_LOG

# Re-enable primary
az containerapp ingress enable \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --type external \
  --target-port 8080

# Delete DR environment
az group delete --name $SECONDARY_RG --yes --no-wait

echo "=== DR DRILL COMPLETE ===" | tee -a $DRILL_LOG
echo "Results saved to: $DRILL_LOG" | tee -a $DRILL_LOG
```

### Success Criteria

**DR Drill Pass Criteria**:

- [ ] RTO < 4 hours (production), < 8 hours (dev)
- [ ] RPO < 15 minutes (no significant data loss)
- [ ] All critical services restored and functional
- [ ] All validation tests pass (health, connectivity, smoke tests)
- [ ] No manual intervention required beyond documented runbook
- [ ] Recovery procedures followed exactly as documented
- [ ] All team members know their roles and responsibilities

**Drill Failure Criteria** (immediate remediation required):

- RTO exceeds target by > 50%
- Data loss exceeds RPO by > 2x
- Critical services non-functional after recovery
- Undocumented manual steps required
- Team confusion about procedures

## Post-Recovery

### Root Cause Analysis

**Post-Incident Review Template**:

```markdown
# Post-Incident Review - [Incident ID]

## Incident Summary
- **Incident ID**: INC-YYYYMMDD-HHMMSS
- **Severity**: P0/P1/P2
- **Duration**: X hours Y minutes
- **Services Affected**: [List]
- **Users Affected**: [Estimate]
- **Data Loss**: [RPO achieved]

## Timeline
| Time (UTC) | Event |
|------------|-------|
| HH:MM | Incident detected |
| HH:MM | DR procedures initiated |
| HH:MM | Database restore started |
| HH:MM | Application redeployed |
| HH:MM | Services validated |
| HH:MM | Incident resolved |

## Root Cause
[Detailed analysis of what caused the incident]

## Recovery Actions Taken
1. [Action 1]
2. [Action 2]
...

## What Went Well
- [Positive aspect 1]
- [Positive aspect 2]

## What Went Wrong
- [Issue 1]
- [Issue 2]

## Action Items
| Action | Owner | Priority | Due Date |
|--------|-------|----------|----------|
| [Action item 1] | [Name] | High | YYYY-MM-DD |
| [Action item 2] | [Name] | Medium | YYYY-MM-DD |

## Lessons Learned
[Key takeaways for future incidents]
```

**RCA Process**:

1. Schedule post-incident review within 24-48 hours
2. Invite all participants (DR team, stakeholders)
3. Create blameless timeline of events
4. Identify root cause using 5 Whys technique
5. Document action items with owners and due dates
6. Update runbooks based on lessons learned
7. Share findings with broader organization

### Documentation Updates

**Required Updates After DR Event**:

1. **Update this runbook** with any deviations or improvements discovered
2. **Update infrastructure inventory** with any permanent changes
3. **Update monitoring dashboards** if new metrics needed
4. **Update alerting thresholds** based on incident patterns
5. **Update contact lists** if escalation path changed
6. **Update RTO/RPO targets** if business requirements changed

```bash
# Document recovery metrics
cat >> docs/runbooks/dr-metrics.log <<EOF

## Recovery Event: $(date +%Y-%m-%d)
- Incident Type: [Region Outage/Database Corruption/etc]
- RTO Achieved: X hours Y minutes
- RTO Target: 4 hours
- RPO Achieved: X minutes
- RPO Target: 15 minutes
- Data Loss: [None/Minimal/Significant]
- Recovery Method: [Point-in-time restore/Regional failover/etc]
- Lessons Learned: [Key insights]
- Runbook Updates: [Changes made]

EOF
```

### Process Improvements

**Continuous Improvement Cycle**:

1. **After Each DR Event**:
   - Update runbooks with actual procedures used
   - Document timing for each phase
   - Identify automation opportunities
   - Update scripts with improvements

2. **After Each DR Drill**:
   - Measure RTO/RPO achievement
   - Identify gaps in documentation
   - Train new team members
   - Update contact lists

3. **Quarterly Reviews**:
   - Review DR metrics trends
   - Assess RTO/RPO target adequacy
   - Evaluate infrastructure changes impact
   - Update disaster scenarios list

4. **Annual Assessment**:
   - Full DR strategy review
   - Business impact analysis update
   - Cost-benefit analysis of DR investments
   - Industry best practices review

## Contacts and Resources

### Emergency Contacts

**On-Call Rotation**:
- Primary On-Call: Check PagerDuty schedule at https://[org].pagerduty.com
- Secondary On-Call: Auto-escalates after 15 minutes
- Engineering Manager: [Name] - [Phone]
- Director of Engineering: [Name] - [Phone]

**External Support**:
- Azure Support (Premier): 1-800-MICROSOFT (24/7)
- Azure Support Portal: https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade
- GitHub Support: https://support.github.com

**Vendor Status Pages**:
- Azure Status: https://status.azure.com
- Azure Service Health: https://portal.azure.com/#blade/Microsoft_Azure_Health/AzureHealthBrowseBlade/serviceIssues
- GitHub Status: https://www.githubstatus.com

### External Vendors

**Microsoft Azure**:
- Support Plan: Premier (24/7 phone support)
- Severity A (Critical): Immediate response commitment
- Account Manager: [Name] - [Email]
- Technical Account Manager: [Name] - [Email]

**GitHub**:
- Support Plan: Enterprise
- Contact: https://support.github.com/contact
- Account Manager: [Name] - [Email]

### Documentation Links

**Related Runbooks**:
- [Deployment Procedures](./deployment-procedures.md) - Application deployment and rollback
- [Monitoring and Alerting Guide](../monitoring/alerting.md) - Incident detection
- [Security Incident Response](../security/incident-response.md) - Security breach procedures

**Infrastructure Documentation**:
- [Architecture Overview](../architecture/overview.md)
- [Database Design](../database/design.md)
- [Network Topology](../architecture/network.md)

**Azure Resources**:
- [Cosmos DB Continuous Backup](https://learn.microsoft.com/en-us/azure/cosmos-db/continuous-backup-restore-introduction)
- [Container Apps Disaster Recovery](https://learn.microsoft.com/en-us/azure/container-apps/disaster-recovery)
- [Azure Site Recovery](https://learn.microsoft.com/en-us/azure/site-recovery/)

---

## Appendix

### Quick Reference Commands

```bash
# Environment setup
export ENVIRONMENT="prod"
export RG_NAME="ascension-${ENVIRONMENT}-rg"
export SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Health check
curl -f https://ascension-${ENVIRONMENT}.azurecontainerapps.io/health/ready

# Check backup status
az cosmosdb show --name ascension-${ENVIRONMENT}-cosmos --resource-group $RG_NAME --query "backupPolicy" -o json

# Immediate rollback
az containerapp ingress traffic set --name ascension-${ENVIRONMENT}-ca --resource-group $RG_NAME --revision-weight [previous-revision]=100

# Emergency shutdown
az containerapp ingress disable --name ascension-${ENVIRONMENT}-ca --resource-group $RG_NAME

# Emergency secret rotation
az keyvault secret set --vault-name ascension-${ENVIRONMENT}-kv --name [SECRET_NAME] --value [NEW_VALUE]
```

### Acronyms and Definitions

- **RTO**: Recovery Time Objective - Maximum acceptable downtime
- **RPO**: Recovery Point Objective - Maximum acceptable data loss window
- **PITR**: Point-in-Time Restore - Ability to restore to specific timestamp
- **GRS**: Geo-Redundant Storage - Azure storage replicated to secondary region
- **LRS**: Locally Redundant Storage - Storage replicated within single datacenter
- **RDB**: Redis Database Backup - Redis persistence snapshot format
- **ACR**: Azure Container Registry
- **CAE**: Container Apps Environment

---

**Document Version**: 1.0
**Last Updated**: 2025-10-09
**Maintained By**: DevOps Team / SRE Team
**Review Cycle**: After each DR event, quarterly drills, or significant infrastructure changes
**Feedback**: Create issue or PR in GitHub repository

**CRITICAL: This is a living document. Update immediately after any DR event or drill with lessons learned.**
