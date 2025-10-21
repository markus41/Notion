---
title: Deployment Procedures - Agent Studio
description: Comprehensive operational runbook for deploying Agent Studio to Azure with step-by-step procedures, pre-flight checks, rollback procedures, and troubleshooting guides
lastUpdated: 2025-10-08
tags: [runbook, deployment, operations, azure, devops]
---

# Deployment Procedures

## Overview

This runbook provides comprehensive deployment procedures for Agent Studio, a meta-agent orchestration platform built on Azure Container Apps with supporting services (Cosmos DB, Azure OpenAI, SignalR, Redis, Azure AI Search).

### Deployment Strategy

**Deployment Model**: Blue-Green deployment with canary rollout capability for production

**Environments**:
- **Development (dev)**: Continuous deployment from `develop` branch, minimal redundancy
- **Staging (staging)**: Automated deployment from `main` branch, production-like configuration
- **Production (prod)**: Manual approval required, blue-green with canary option

**Deployment Frequency**:
- Development: Multiple times per day (automated)
- Staging: Daily or per feature completion (automated)
- Production: Weekly release cycle or hotfixes (manual approval)

**Key Technologies**:
- Infrastructure: Azure Bicep (IaC)
- Container Orchestration: Azure Container Apps
- Container Registry: Azure Container Registry (ACR)
- Database: Azure Cosmos DB (NoSQL)
- Observability: Azure Monitor, Application Insights, Log Analytics
- CI/CD: GitHub Actions with OIDC authentication

## Pre-Deployment Checklist

### Infrastructure Validation

Complete these checks before initiating any deployment:

#### Azure Resources

- [ ] **Resource Group exists**
  ```bash
  az group show --name ascension-{env}-rg --query "properties.provisioningState" -o tsv
  # Expected: Succeeded
  ```

- [ ] **Container Registry accessible**
  ```bash
  az acr check-health --name ascension{env}acr --yes
  # Expected: healthy
  ```

- [ ] **Container Apps Environment healthy**
  ```bash
  az containerapp env show \
    --name ascension-{env}-cae \
    --resource-group ascension-{env}-rg \
    --query "properties.provisioningState" -o tsv
  # Expected: Succeeded
  ```

- [ ] **Cosmos DB online and accessible**
  ```bash
  az cosmosdb show \
    --name ascension-{env}-cosmos \
    --resource-group ascension-{env}-rg \
    --query "properties.documentEndpoint" -o tsv
  # Expected: Returns endpoint URL
  ```

- [ ] **Azure OpenAI deployment ready**
  ```bash
  az cognitiveservices account deployment show \
    --name ascension-{env}-openai \
    --resource-group ascension-{env}-rg \
    --deployment-name gpt-4 \
    --query "properties.provisioningState" -o tsv
  # Expected: Succeeded
  ```

- [ ] **SignalR Service operational**
  ```bash
  az signalr show \
    --name ascension-{env}-signalr \
    --resource-group ascension-{env}-rg \
    --query "provisioningState" -o tsv
  # Expected: Succeeded
  ```

- [ ] **Redis Cache accessible**
  ```bash
  az redis show \
    --name ascension-{env}-redis \
    --resource-group ascension-{env}-rg \
    --query "provisioningState" -o tsv
  # Expected: Succeeded
  ```

- [ ] **Azure AI Search service ready**
  ```bash
  az search service show \
    --name ascension-{env}-search \
    --resource-group ascension-{env}-rg \
    --query "status" -o tsv
  # Expected: running
  ```

#### Network Connectivity

- [ ] **ACR accessible from Container Apps**
  ```bash
  az containerapp show \
    --name ascension-{env}-ca \
    --resource-group ascension-{env}-rg \
    --query "properties.configuration.registries[0].server" -o tsv
  # Expected: ascension{env}acr.azurecr.io
  ```

- [ ] **Managed Identity has ACR Pull permissions**
  ```bash
  az role assignment list \
    --assignee $(az containerapp show --name ascension-{env}-ca --resource-group ascension-{env}-rg --query "identity.userAssignedIdentities" -o tsv | cut -d'/' -f9) \
    --scope $(az acr show --name ascension{env}acr --query id -o tsv) \
    --query "[?roleDefinitionName=='AcrPull'].roleDefinitionName" -o tsv
  # Expected: AcrPull
  ```

- [ ] **Ingress configured and responding**
  ```bash
  az containerapp ingress show \
    --name ascension-{env}-ca \
    --resource-group ascension-{env}-rg \
    --query "fqdn" -o tsv
  # Expected: Returns FQDN
  ```

#### SSL Certificates

- [ ] **Custom domain configured (if applicable)**
  ```bash
  az containerapp hostname list \
    --name ascension-{env}-ca \
    --resource-group ascension-{env}-rg
  # Expected: Lists custom domains
  ```

- [ ] **SSL certificate valid and not expiring soon**
  ```bash
  # For custom domains
  echo | openssl s_client -servername {your-domain} -connect {your-domain}:443 2>/dev/null | \
    openssl x509 -noout -dates
  # Expected: notAfter date > 30 days from now
  ```

#### Secrets in Key Vault

- [ ] **All required secrets present in Key Vault**
  ```bash
  az keyvault secret list \
    --vault-name ascension-{env}-kv \
    --query "[].name" -o tsv
  # Expected: AZURE-OPENAI-KEY, AZURE-SEARCH-KEY, SIGNALR-CONNECTION-STRING, REDIS-CONNECTION-STRING
  ```

- [ ] **Managed Identity has Key Vault Secrets User role**
  ```bash
  az role assignment list \
    --assignee $(az identity show --name ascension-{env}-identity --resource-group ascension-{env}-rg --query principalId -o tsv) \
    --scope $(az keyvault show --name ascension-{env}-kv --query id -o tsv) \
    --query "[?roleDefinitionName=='Key Vault Secrets User'].roleDefinitionName" -o tsv
  # Expected: Key Vault Secrets User
  ```

- [ ] **Secrets accessible from Container App**
  ```bash
  # This is validated during health check after deployment
  # Manual test: Check Container App logs for secret resolution errors
  az containerapp logs show \
    --name ascension-{env}-ca \
    --resource-group ascension-{env}-rg \
    --type console \
    --tail 50 | grep -i "secret\|keyvault"
  ```

#### Database Migrations Ready

- [ ] **Migration scripts tested in staging**
  ```bash
  # Validate migration files exist
  ls -la database/migrations/*.sql
  # Expected: List of migration files with timestamps
  ```

- [ ] **Database backup completed**
  ```bash
  # Cosmos DB continuous backup enabled
  az cosmosdb show \
    --name ascension-{env}-cosmos \
    --resource-group ascension-{env}-rg \
    --query "backupPolicy.type" -o tsv
  # Expected: Continuous
  ```

- [ ] **Migration rollback scripts prepared**
  ```bash
  # Validate rollback scripts exist
  ls -la database/migrations/rollback/*.sql
  # Expected: Matching rollback scripts for each migration
  ```

### Code Quality Gates

Before deploying, ensure all quality gates pass:

- [ ] **All CI tests passing**
  ```bash
  # Check latest CI run status
  gh run list --workflow=ci.yml --limit 1 --json conclusion --jq '.[0].conclusion'
  # Expected: success
  ```

- [ ] **Security scan clean (no critical/high vulnerabilities)**
  ```bash
  # Check Trivy scan results
  gh run view $(gh run list --workflow=containers.yml --limit 1 --json databaseId --jq '.[0].databaseId') \
    --log | grep -i "CRITICAL\|HIGH"
  # Expected: No CRITICAL or HIGH vulnerabilities
  ```

- [ ] **Container build successful**
  ```bash
  # Verify container image exists in ACR
  az acr repository show-tags \
    --name ascension{env}acr \
    --repository project-ascension-api \
    --orderby time_desc \
    --top 1 -o tsv
  # Expected: Returns latest tag (SHA or version)
  ```

- [ ] **Performance benchmarks met**
  ```bash
  # Check performance test results
  gh run view $(gh run list --workflow=performance-benchmarks.yml --limit 1 --json databaseId --jq '.[0].databaseId') \
    --log | grep "Performance Check"
  # Expected: All benchmarks within acceptable thresholds
  ```

- [ ] **Documentation updated**
  ```bash
  # Verify CHANGELOG.md updated
  git diff main..HEAD -- docs/CHANGELOG.md | head -20
  # Expected: New entry for this release
  ```

- [ ] **Release notes prepared**
  ```bash
  # Check if release notes exist for this version
  cat docs/releases/$(git describe --tags --abbrev=0).md 2>/dev/null || echo "Release notes needed"
  # Expected: Release notes file exists
  ```

## Deployment Procedures

### Step 1: Backup Current State

Before any deployment, create comprehensive backups:

#### 1.1 Backup Cosmos DB

```bash
# Cosmos DB uses continuous backup - verify it's enabled
COSMOS_NAME="ascension-${ENVIRONMENT}-cosmos"
RG_NAME="ascension-${ENVIRONMENT}-rg"

az cosmosdb show \
  --name $COSMOS_NAME \
  --resource-group $RG_NAME \
  --query "backupPolicy" -o json

# For point-in-time restore capability, note the current timestamp
BACKUP_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "Backup timestamp for rollback: $BACKUP_TIMESTAMP"
echo $BACKUP_TIMESTAMP > /tmp/deployment-backup-timestamp.txt
```

#### 1.2 Backup Configuration

```bash
# Export current Container App configuration
az containerapp show \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg \
  -o json > /tmp/containerapp-backup-${ENVIRONMENT}-$(date +%Y%m%d-%H%M%S).json

# Export current revision name for rollback
CURRENT_REVISION=$(az containerapp revision list \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "[?properties.active==\`true\`].name" -o tsv)

echo "Current active revision: $CURRENT_REVISION"
echo $CURRENT_REVISION > /tmp/deployment-previous-revision.txt
```

#### 1.3 Backup Key Vault Secrets (metadata only)

```bash
# Export secret names and versions (not values)
az keyvault secret list \
  --vault-name ascension-${ENVIRONMENT}-kv \
  --query "[].{name:name,version:id}" -o json > /tmp/keyvault-backup-${ENVIRONMENT}-$(date +%Y%m%d-%H%M%S).json
```

#### 1.4 Tag Current Deployment

```bash
# Tag the current running image for quick rollback
CURRENT_IMAGE=$(az containerapp show \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "properties.template.containers[0].image" -o tsv)

echo "Current running image: $CURRENT_IMAGE"

# Tag as last-known-good in ACR
az acr import \
  --name ascension${ENVIRONMENT}acr \
  --source $CURRENT_IMAGE \
  --image project-ascension-api:last-known-good-${ENVIRONMENT} \
  --force
```

### Step 2: Deploy Infrastructure Changes

If infrastructure changes are required (e.g., new services, scaling configurations):

#### 2.1 Validate Bicep Templates

```bash
# Navigate to infrastructure directory
cd infra

# Validate Bicep template
az deployment sub validate \
  --location eastus \
  --template-file deploy.bicep \
  --parameters deploy.parameters.${ENVIRONMENT}.json

# Expected: No validation errors
```

#### 2.2 Preview Infrastructure Changes

```bash
# Run What-If analysis to see what will change
az deployment sub what-if \
  --location eastus \
  --template-file deploy.bicep \
  --parameters deploy.parameters.${ENVIRONMENT}.json \
  --result-format FullResourcePayloads

# Review output carefully before proceeding
```

#### 2.3 Deploy Infrastructure

```bash
# Deploy infrastructure changes
az deployment sub create \
  --name "ascension-infra-${ENVIRONMENT}-$(date +%Y%m%d-%H%M%S)" \
  --location eastus \
  --template-file deploy.bicep \
  --parameters deploy.parameters.${ENVIRONMENT}.json \
  --verbose

# Monitor deployment status
az deployment sub show \
  --name "ascension-infra-${ENVIRONMENT}-$(date +%Y%m%d-%H%M%S)" \
  --query "properties.provisioningState" -o tsv
# Expected: Succeeded
```

#### 2.4 Verify Infrastructure Deployment

```bash
# Check all resources are provisioned
az resource list \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "[].{Name:name, Type:type, State:provisioningState}" -o table

# Expected: All resources show "Succeeded"
```

### Step 3: Deploy Application

Choose deployment strategy based on environment:

#### 3.1 Development: Rolling Update (Direct)

```bash
# For dev environment - direct deployment
ENVIRONMENT="dev"
IMAGE_TAG="${GITHUB_SHA:-latest}"
ACR_NAME="ascension${ENVIRONMENT}acr"
APP_NAME="ascension-${ENVIRONMENT}-ca"
RG_NAME="ascension-${ENVIRONMENT}-rg"

# Update Container App with new image
az containerapp update \
  --name $APP_NAME \
  --resource-group $RG_NAME \
  --image ${ACR_NAME}.azurecr.io/project-ascension-api:${IMAGE_TAG} \
  --revision-suffix $(date +%Y%m%d-%H%M%S)

echo "Development deployment initiated - rolling update"
```

#### 3.2 Staging: Blue-Green Deployment

```bash
# For staging environment - blue-green with instant cutover
ENVIRONMENT="staging"
IMAGE_TAG="${GITHUB_SHA:-latest}"
ACR_NAME="ascension${ENVIRONMENT}acr"
APP_NAME="ascension-${ENVIRONMENT}-ca"
RG_NAME="ascension-${ENVIRONMENT}-rg"
REVISION_SUFFIX="green-$(date +%Y%m%d-%H%M%S)"

# Create new revision (green) without activating
az containerapp revision copy \
  --name $APP_NAME \
  --resource-group $RG_NAME \
  --image ${ACR_NAME}.azurecr.io/project-ascension-api:${IMAGE_TAG} \
  --revision-suffix $REVISION_SUFFIX

# Wait for green revision to be ready
echo "Waiting for green revision to be ready..."
sleep 30

# Verify green revision is ready
az containerapp revision show \
  --name ${APP_NAME}--${REVISION_SUFFIX} \
  --resource-group $RG_NAME \
  --query "properties.healthState" -o tsv
# Expected: Healthy

# Perform health check on green environment
GREEN_FQDN=$(az containerapp revision show \
  --name ${APP_NAME}--${REVISION_SUFFIX} \
  --resource-group $RG_NAME \
  --query "properties.fqdn" -o tsv)

curl -f https://${GREEN_FQDN}/health/ready || exit 1

# Cutover: Activate green, deactivate blue
az containerapp ingress traffic set \
  --name $APP_NAME \
  --resource-group $RG_NAME \
  --revision-weight ${APP_NAME}--${REVISION_SUFFIX}=100

echo "Blue-Green deployment complete - traffic switched to green"
```

#### 3.3 Production: Canary Deployment with Progressive Rollout

```bash
# For production environment - canary with gradual rollout
ENVIRONMENT="prod"
IMAGE_TAG="${GITHUB_SHA:-latest}"
ACR_NAME="ascension${ENVIRONMENT}acr"
APP_NAME="ascension-${ENVIRONMENT}-ca"
RG_NAME="ascension-${ENVIRONMENT}-rg"
REVISION_SUFFIX="canary-$(date +%Y%m%d-%H%M%S)"

# Get current active revision name
CURRENT_REVISION=$(az containerapp revision list \
  --name $APP_NAME \
  --resource-group $RG_NAME \
  --query "[?properties.active==\`true\`].name" -o tsv | head -1)

# Create canary revision
az containerapp revision copy \
  --name $APP_NAME \
  --resource-group $RG_NAME \
  --image ${ACR_NAME}.azurecr.io/project-ascension-api:${IMAGE_TAG} \
  --revision-suffix $REVISION_SUFFIX

# Wait for canary to be ready
sleep 45

# Phase 1: 5% canary traffic
echo "Phase 1: Routing 5% traffic to canary..."
az containerapp ingress traffic set \
  --name $APP_NAME \
  --resource-group $RG_NAME \
  --revision-weight ${CURRENT_REVISION}=95 ${APP_NAME}--${REVISION_SUFFIX}=5

# Monitor for 10 minutes
echo "Monitoring canary for 10 minutes..."
sleep 600

# Check error rates and latency (KQL query)
az monitor app-insights query \
  --app ascension-${ENVIRONMENT}-ai \
  --analytics-query "
    requests
    | where timestamp > ago(10m)
    | where cloud_RoleName == '${APP_NAME}--${REVISION_SUFFIX}'
    | summarize
        ErrorRate = 100.0 * countif(success == false) / count(),
        P95Latency = percentile(duration, 95)
    " \
  --offset 10m

# Abort if error rate > 1% or P95 latency > 2000ms
# Otherwise continue...

# Phase 2: 25% canary traffic
echo "Phase 2: Routing 25% traffic to canary..."
az containerapp ingress traffic set \
  --name $APP_NAME \
  --resource-group $RG_NAME \
  --revision-weight ${CURRENT_REVISION}=75 ${APP_NAME}--${REVISION_SUFFIX}=25

sleep 600  # Monitor for 10 minutes

# Phase 3: 50% canary traffic
echo "Phase 3: Routing 50% traffic to canary..."
az containerapp ingress traffic set \
  --name $APP_NAME \
  --resource-group $RG_NAME \
  --revision-weight ${CURRENT_REVISION}=50 ${APP_NAME}--${REVISION_SUFFIX}=50

sleep 600  # Monitor for 10 minutes

# Phase 4: 100% canary traffic (full promotion)
echo "Phase 4: Full canary promotion - 100% traffic"
az containerapp ingress traffic set \
  --name $APP_NAME \
  --resource-group $RG_NAME \
  --revision-weight ${APP_NAME}--${REVISION_SUFFIX}=100

echo "Canary deployment complete - fully promoted to production"

# Deactivate old revision after 1 hour grace period
echo "Old revision will remain available for 1 hour for emergency rollback"
```

### Step 4: Run Database Migrations

Execute database migrations after application deployment:

#### 4.1 Pre-Migration Validation

```bash
# Verify Cosmos DB connection
COSMOS_ENDPOINT=$(az cosmosdb show \
  --name ascension-${ENVIRONMENT}-cosmos \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "documentEndpoint" -o tsv)

# Test connection from Container App
az containerapp exec \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --command "curl -f ${COSMOS_ENDPOINT}" || echo "Connection test"
```

#### 4.2 Execute Migrations

```bash
# Run migrations via Container App job or exec
# Option 1: Use dedicated migration job
az containerapp job create \
  --name ascension-${ENVIRONMENT}-migration \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --environment ascension-${ENVIRONMENT}-cae \
  --trigger-type Manual \
  --replica-timeout 1800 \
  --image ${ACR_NAME}.azurecr.io/project-ascension-migration:${IMAGE_TAG} \
  --cpu 0.5 \
  --memory 1Gi \
  --env-vars \
    COSMOS_ENDPOINT=${COSMOS_ENDPOINT} \
    MIGRATION_MODE=up

# Execute migration job
az containerapp job start \
  --name ascension-${ENVIRONMENT}-migration \
  --resource-group ascension-${ENVIRONMENT}-rg

# Monitor migration job
az containerapp job execution list \
  --name ascension-${ENVIRONMENT}-migration \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "[0].{Name:name,Status:properties.status}" -o table
```

#### 4.3 Verify Migrations

```bash
# Check migration status in database
# Query Cosmos DB for migration version
az cosmosdb sql container item read \
  --account-name ascension-${ENVIRONMENT}-cosmos \
  --database-name AgentStudio \
  --container-name Migrations \
  --item-id latest \
  --partition-key-value system \
  --query "version" -o tsv

# Expected: Latest migration version number
```

#### 4.4 Migration Rollback (if needed)

```bash
# If migration fails, rollback immediately
az containerapp job create \
  --name ascension-${ENVIRONMENT}-migration-rollback \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --environment ascension-${ENVIRONMENT}-cae \
  --trigger-type Manual \
  --replica-timeout 1800 \
  --image ${ACR_NAME}.azurecr.io/project-ascension-migration:${IMAGE_TAG} \
  --cpu 0.5 \
  --memory 1Gi \
  --env-vars \
    COSMOS_ENDPOINT=${COSMOS_ENDPOINT} \
    MIGRATION_MODE=down \
    TARGET_VERSION=${ROLLBACK_VERSION}

# Execute rollback
az containerapp job start \
  --name ascension-${ENVIRONMENT}-migration-rollback \
  --resource-group ascension-${ENVIRONMENT}-rg
```

### Step 5: Health Checks

Comprehensive health validation after deployment:

#### 5.1 Container Health Probes

```bash
# Check liveness probe
FQDN=$(az containerapp show \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "properties.configuration.ingress.fqdn" -o tsv)

curl -f https://${FQDN}/health/live
# Expected: HTTP 200, {"status":"healthy"}

# Check readiness probe
curl -f https://${FQDN}/health/ready
# Expected: HTTP 200, {"status":"ready","dependencies":{"cosmos":"healthy","openai":"healthy",...}}
```

#### 5.2 Dependency Health Checks

```bash
# Verify all dependencies are accessible
curl -s https://${FQDN}/health/ready | jq '.dependencies'

# Expected output:
# {
#   "cosmos": "healthy",
#   "openai": "healthy",
#   "signalr": "healthy",
#   "redis": "healthy",
#   "search": "healthy"
# }
```

#### 5.3 Application Insights Availability Test

```bash
# Check Application Insights for availability
az monitor app-insights query \
  --app ascension-${ENVIRONMENT}-ai \
  --analytics-query "
    availabilityResults
    | where timestamp > ago(5m)
    | summarize AvailabilityPercentage = avg(todouble(success)) * 100
    " \
  --offset 5m
# Expected: AvailabilityPercentage >= 99.9
```

#### 5.4 Replica Health

```bash
# Verify all replicas are running and healthy
az containerapp replica list \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --revision ${APP_NAME}--${REVISION_SUFFIX} \
  --query "[].{Name:name,Status:properties.runningState,Health:properties.healthState}" -o table

# Expected: All replicas show Running/Healthy
```

### Step 6: Traffic Cutover

For Blue-Green and Canary deployments, final traffic management:

#### 6.1 Verify Traffic Distribution

```bash
# Check current traffic weights
az containerapp ingress traffic show \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "[] | sort_by(@, &weight) | reverse(@)" -o table

# Expected: Shows traffic distribution across revisions
```

#### 6.2 Monitor Traffic Shift

```bash
# Monitor request distribution in Application Insights
az monitor app-insights query \
  --app ascension-${ENVIRONMENT}-ai \
  --analytics-query "
    requests
    | where timestamp > ago(5m)
    | summarize RequestCount = count() by cloud_RoleInstance
    | order by RequestCount desc
    " \
  --offset 5m

# Expected: Traffic distributed according to weight configuration
```

#### 6.3 Final Cutover (if using progressive rollout)

```bash
# After all checks pass, route 100% traffic to new revision
az containerapp ingress traffic set \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --revision-weight ${APP_NAME}--${REVISION_SUFFIX}=100

echo "Traffic cutover complete - 100% on new revision"
```

#### 6.4 Deactivate Old Revisions

```bash
# After stability confirmed (30-60 minutes in production)
# Deactivate old revisions to clean up
az containerapp revision deactivate \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --revision ${CURRENT_REVISION}

echo "Old revision deactivated - deployment complete"
```

## Rollback Procedures

### When to Rollback

**Immediate Rollback Required When**:
- Error rate exceeds 5% for more than 2 minutes
- P95 latency exceeds 3 seconds consistently
- Critical dependency failures (Cosmos DB, OpenAI unreachable)
- Application crashes or fails to start
- Security vulnerability detected in deployed version
- Data corruption detected

**Evaluate Rollback When**:
- Error rate between 1-5% (investigate first)
- P99 latency elevated but P95 acceptable
- Isolated feature failures (may fix forward)
- Non-critical dependency degradation

**Do NOT Rollback When**:
- Database migrations have been applied (rollback migrations first)
- Issue is with external dependency, not application code
- Problem affects < 1% of requests and workaround exists

### Rollback Decision Tree

```
Error Detected
    │
    ├─> Error Rate > 5%? ──Yes──> IMMEDIATE ROLLBACK
    │        │
    │        No
    │        │
    ├─> Database Migrations Applied? ──Yes──> Rollback Migrations First
    │        │                                       │
    │        No                                      │
    │        │                                       ▼
    ├─> Critical Dependency Down? ──Yes──> Investigate ──> Still Down? ──Yes──> ROLLBACK
    │        │                                              │
    │        No                                             No ──> Monitor
    │        │
    ├─> Data Corruption? ──Yes──> IMMEDIATE ROLLBACK + Restore Data
    │        │
    │        No
    │        │
    └─> Error Rate 1-5%? ──Yes──> Monitor 5 min ──> Improving? ──No──> ROLLBACK
             │                                            │
             No                                          Yes ──> Continue Monitoring
             │
             ▼
        Fix Forward if Possible
```

### Rollback Steps

#### Step 1: Assess Impact

```bash
# Check error rate in last 5 minutes
az monitor app-insights query \
  --app ascension-${ENVIRONMENT}-ai \
  --analytics-query "
    requests
    | where timestamp > ago(5m)
    | summarize
        TotalRequests = count(),
        FailedRequests = countif(success == false),
        ErrorRate = 100.0 * countif(success == false) / count(),
        P95Latency = percentile(duration, 95),
        P99Latency = percentile(duration, 99)
    " \
  --offset 5m

# Document findings
echo "Rollback initiated at $(date -u +"%Y-%m-%dT%H:%M:%SZ")" | tee /tmp/rollback-log.txt
echo "Error Rate: ${ERROR_RATE}%" | tee -a /tmp/rollback-log.txt
```

#### Step 2: Immediate Traffic Revert

```bash
# Get previous stable revision
PREVIOUS_REVISION=$(cat /tmp/deployment-previous-revision.txt 2>/dev/null || echo "unknown")

if [ "$PREVIOUS_REVISION" != "unknown" ]; then
  # Instant traffic revert to previous revision
  echo "Reverting traffic to previous revision: $PREVIOUS_REVISION"

  az containerapp ingress traffic set \
    --name ascension-${ENVIRONMENT}-ca \
    --resource-group ascension-${ENVIRONMENT}-rg \
    --revision-weight ${PREVIOUS_REVISION}=100

  echo "Traffic reverted to previous revision" | tee -a /tmp/rollback-log.txt
else
  # Use last-known-good tagged image
  echo "Previous revision unknown - deploying last-known-good image"

  az containerapp update \
    --name ascension-${ENVIRONMENT}-ca \
    --resource-group ascension-${ENVIRONMENT}-rg \
    --image ${ACR_NAME}.azurecr.io/project-ascension-api:last-known-good-${ENVIRONMENT} \
    --revision-suffix rollback-$(date +%Y%m%d-%H%M%S)

  echo "Deployed last-known-good image" | tee -a /tmp/rollback-log.txt
fi
```

#### Step 3: Verify Rollback

```bash
# Wait for rollback to propagate
sleep 30

# Check health
curl -f https://${FQDN}/health/ready

# Verify error rate decreased
az monitor app-insights query \
  --app ascension-${ENVIRONMENT}-ai \
  --analytics-query "
    requests
    | where timestamp > ago(2m)
    | summarize ErrorRate = 100.0 * countif(success == false) / count()
    " \
  --offset 2m

# Expected: ErrorRate < 1%
```

#### Step 4: Rollback Database Migrations (if needed)

```bash
# If migrations were applied, rollback to pre-deployment state
BACKUP_TIMESTAMP=$(cat /tmp/deployment-backup-timestamp.txt 2>/dev/null)

if [ -n "$BACKUP_TIMESTAMP" ]; then
  echo "Rolling back database to timestamp: $BACKUP_TIMESTAMP"

  # Point-in-time restore for Cosmos DB
  az cosmosdb restore \
    --target-database-account-name ascension-${ENVIRONMENT}-cosmos-restored \
    --account-name ascension-${ENVIRONMENT}-cosmos \
    --resource-group ascension-${ENVIRONMENT}-rg \
    --restore-timestamp $BACKUP_TIMESTAMP \
    --location eastus

  # Update application to use restored database
  # (This requires updating connection strings in Key Vault)

  echo "Database rolled back" | tee -a /tmp/rollback-log.txt
fi
```

#### Step 5: Deactivate Failed Revision

```bash
# Deactivate the failed revision
FAILED_REVISION=$(az containerapp revision list \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "[?properties.trafficWeight==\`0\` && properties.active==\`true\`].name" -o tsv | head -1)

if [ -n "$FAILED_REVISION" ]; then
  az containerapp revision deactivate \
    --name ascension-${ENVIRONMENT}-ca \
    --resource-group ascension-${ENVIRONMENT}-rg \
    --revision $FAILED_REVISION

  echo "Deactivated failed revision: $FAILED_REVISION" | tee -a /tmp/rollback-log.txt
fi
```

#### Step 6: Confirm System Stability

```bash
# Monitor for 10 minutes post-rollback
echo "Monitoring system for 10 minutes post-rollback..."

for i in {1..10}; do
  sleep 60

  # Check health
  curl -sf https://${FQDN}/health/ready > /dev/null
  HEALTH_STATUS=$?

  # Check error rate
  ERROR_RATE=$(az monitor app-insights query \
    --app ascension-${ENVIRONMENT}-ai \
    --analytics-query "requests | where timestamp > ago(1m) | summarize ErrorRate = 100.0 * countif(success == false) / count()" \
    --offset 1m --query "tables[0].rows[0][0]" -o tsv)

  echo "Minute $i - Health: $HEALTH_STATUS, Error Rate: ${ERROR_RATE}%" | tee -a /tmp/rollback-log.txt

  if (( $(echo "$ERROR_RATE > 1.0" | bc -l) )); then
    echo "ERROR: System still unstable after rollback!" | tee -a /tmp/rollback-log.txt
    exit 1
  fi
done

echo "Rollback successful - system stable" | tee -a /tmp/rollback-log.txt
```

### Post-Rollback Actions

#### Immediate Actions (within 1 hour)

1. **Notify Stakeholders**
   ```bash
   # Send notification via Teams/Slack webhook
   curl -X POST ${TEAMS_WEBHOOK_URL} \
     -H 'Content-Type: application/json' \
     -d "{
       \"@type\": \"MessageCard\",
       \"title\": \"Production Rollback - ${ENVIRONMENT}\",
       \"text\": \"Deployment rolled back at $(date). Error rate exceeded threshold.\",
       \"sections\": [{
         \"facts\": [
           {\"name\": \"Environment\", \"value\": \"${ENVIRONMENT}\"},
           {\"name\": \"Failed Revision\", \"value\": \"${FAILED_REVISION}\"},
           {\"name\": \"Rollback Time\", \"value\": \"$(date -u)\"}
         ]
       }]
     }"
   ```

2. **Create Incident Ticket**
   ```bash
   # Create incident in tracking system
   gh issue create \
     --title "Production Rollback - $(date +%Y-%m-%d)" \
     --label "incident,production,rollback" \
     --body "Deployment to ${ENVIRONMENT} rolled back. See rollback log for details."
   ```

3. **Preserve Evidence**
   ```bash
   # Save logs from failed revision
   az containerapp logs show \
     --name ascension-${ENVIRONMENT}-ca \
     --resource-group ascension-${ENVIRONMENT}-rg \
     --revision $FAILED_REVISION \
     --type console \
     --tail 1000 > /tmp/failed-revision-logs.txt

   # Export Application Insights data
   az monitor app-insights query \
     --app ascension-${ENVIRONMENT}-ai \
     --analytics-query "
       union requests, exceptions, traces
       | where timestamp > ago(30m)
       | where cloud_RoleInstance contains '${FAILED_REVISION}'
       | order by timestamp desc
       " \
     --offset 30m -o json > /tmp/app-insights-incident-data.json
   ```

#### Follow-up Actions (within 24 hours)

1. **Root Cause Analysis**
   - Analyze logs from failed revision
   - Review Application Insights telemetry
   - Identify code or configuration issue
   - Document findings in incident ticket

2. **Postmortem Meeting**
   - Schedule within 24 hours
   - Include engineering, DevOps, product team
   - Document timeline, impact, root cause
   - Identify action items to prevent recurrence

3. **Update Deployment Procedures**
   - Add new validation checks if needed
   - Update health check thresholds
   - Improve monitoring/alerting
   - Document lessons learned

## Monitoring During Deployment

### Key Metrics to Watch

Monitor these metrics throughout deployment:

#### Application Metrics

```bash
# Real-time dashboard query (run in terminal)
watch -n 10 '
az monitor app-insights query \
  --app ascension-${ENVIRONMENT}-ai \
  --analytics-query "
    requests
    | where timestamp > ago(5m)
    | summarize
        RequestCount = count(),
        ErrorRate = round(100.0 * countif(success == false) / count(), 2),
        P50 = round(percentile(duration, 50), 0),
        P95 = round(percentile(duration, 95), 0),
        P99 = round(percentile(duration, 99), 0)
    " \
  --offset 5m \
  --query "tables[0].rows[0]" -o tsv
'
# Expected: ErrorRate < 1%, P95 < 2000ms, P99 < 3000ms
```

#### Container Metrics

```bash
# Monitor replica health and resource usage
az containerapp replica list \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "[].{
    Name:name,
    State:properties.runningState,
    Health:properties.healthState,
    CPU:properties.runningState,
    Memory:properties.runningState
  }" -o table
```

#### Dependency Metrics

```bash
# Monitor dependency call success rate
az monitor app-insights query \
  --app ascension-${ENVIRONMENT}-ai \
  --analytics-query "
    dependencies
    | where timestamp > ago(5m)
    | summarize
        TotalCalls = count(),
        FailedCalls = countif(success == false),
        FailureRate = round(100.0 * countif(success == false) / count(), 2),
        AvgDuration = round(avg(duration), 0)
        by target
    | order by FailureRate desc
    " \
  --offset 5m -o table
# Expected: FailureRate < 1% for all dependencies
```

### Alert Thresholds

**Abort Deployment If**:

| Metric | Threshold | Action |
|--------|-----------|--------|
| Error Rate | > 5% for 2+ minutes | Immediate rollback |
| P95 Latency | > 3000ms for 5+ minutes | Immediate rollback |
| Availability | < 99% for 5+ minutes | Immediate rollback |
| Dependency Failures | > 10% for critical deps | Immediate rollback |
| Memory Usage | > 90% sustained | Rollback and investigate |
| CPU Usage | > 95% sustained | Rollback and investigate |

**Warn If**:

| Metric | Threshold | Action |
|--------|-----------|--------|
| Error Rate | 1-5% | Monitor closely, prepare rollback |
| P95 Latency | 2000-3000ms | Investigate, may continue if stable |
| Dependency Failures | 1-10% for non-critical | Monitor, may continue |
| Replica Failures | Any replica unhealthy | Investigate, auto-healing should recover |

### Monitoring Queries (KQL)

#### Real-time Error Tracking

```kusto
// Run in Application Insights Analytics
requests
| where timestamp > ago(5m)
| where success == false
| summarize ErrorCount = count() by resultCode, operation_Name
| order by ErrorCount desc
```

#### Latency Distribution

```kusto
requests
| where timestamp > ago(5m)
| summarize
    P50 = percentile(duration, 50),
    P75 = percentile(duration, 75),
    P90 = percentile(duration, 90),
    P95 = percentile(duration, 95),
    P99 = percentile(duration, 99)
    by bin(timestamp, 1m)
| render timechart
```

#### Dependency Health

```kusto
dependencies
| where timestamp > ago(15m)
| summarize
    SuccessRate = 100.0 * countif(success == true) / count(),
    AvgDuration = avg(duration),
    CallCount = count()
    by target, name
| where SuccessRate < 99
| order by SuccessRate asc
```

#### Token Cost Tracking

```kusto
customMetrics
| where name == "openai.token.cost"
| where timestamp > ago(1h)
| summarize TotalCost = sum(value) by bin(timestamp, 5m)
| render timechart
```

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: Container fails to start

**Symptoms**:
- Revision shows "ProvisioningFailed" or "RunningStateFailed"
- Pods crash immediately after start

**Diagnosis**:
```bash
# Check revision status
az containerapp revision show \
  --name ascension-${ENVIRONMENT}-ca--${REVISION_SUFFIX} \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "properties.{State:provisioningState,Health:healthState,Message:provisioningMessage}" -o json

# Check container logs
az containerapp logs show \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --revision ${APP_NAME}--${REVISION_SUFFIX} \
  --type console \
  --tail 100
```

**Solutions**:
1. **Image Pull Failure**: Verify ACR credentials and managed identity permissions
   ```bash
   az role assignment list \
     --assignee $(az identity show --name ascension-${ENVIRONMENT}-identity --resource-group ascension-${ENVIRONMENT}-rg --query principalId -o tsv) \
     --scope $(az acr show --name ascension${ENVIRONMENT}acr --query id -o tsv)
   ```

2. **Environment Variable Error**: Check required env vars are set
   ```bash
   az containerapp show \
     --name ascension-${ENVIRONMENT}-ca \
     --resource-group ascension-${ENVIRONMENT}-rg \
     --query "properties.template.containers[0].env" -o json
   ```

3. **Secret Resolution Failure**: Verify Key Vault permissions
   ```bash
   az keyvault show --name ascension-${ENVIRONMENT}-kv \
     --query "properties.accessPolicies" -o json
   ```

#### Issue 2: Health checks failing

**Symptoms**:
- Readiness probe returns non-200 status
- Application logs show dependency errors

**Diagnosis**:
```bash
# Test health endpoint directly
curl -v https://${FQDN}/health/ready

# Check dependency status in logs
az containerapp logs show \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --type console \
  --tail 50 | grep -i "health\|dependency\|connection"
```

**Solutions**:
1. **Cosmos DB Connection**: Verify endpoint and permissions
   ```bash
   # Test Cosmos DB connectivity
   COSMOS_ENDPOINT=$(az cosmosdb show --name ascension-${ENVIRONMENT}-cosmos --resource-group ascension-${ENVIRONMENT}-rg --query documentEndpoint -o tsv)
   curl -v $COSMOS_ENDPOINT
   ```

2. **OpenAI Connection**: Check deployment and quota
   ```bash
   az cognitiveservices account deployment show \
     --name ascension-${ENVIRONMENT}-openai \
     --resource-group ascension-${ENVIRONMENT}-rg \
     --deployment-name gpt-4
   ```

3. **SignalR Connection**: Verify connection string
   ```bash
   az signalr key list \
     --name ascension-${ENVIRONMENT}-signalr \
     --resource-group ascension-${ENVIRONMENT}-rg
   ```

#### Issue 3: High latency after deployment

**Symptoms**:
- P95/P99 latency significantly increased
- Slow response times reported by users

**Diagnosis**:
```bash
# Analyze latency by operation
az monitor app-insights query \
  --app ascension-${ENVIRONMENT}-ai \
  --analytics-query "
    requests
    | where timestamp > ago(15m)
    | summarize
        P50 = percentile(duration, 50),
        P95 = percentile(duration, 95),
        P99 = percentile(duration, 99),
        Count = count()
        by operation_Name
    | order by P95 desc
    " \
  --offset 15m -o table

# Check for slow dependencies
az monitor app-insights query \
  --app ascension-${ENVIRONMENT}-ai \
  --analytics-query "
    dependencies
    | where timestamp > ago(15m)
    | summarize AvgDuration = avg(duration), Count = count() by target, name
    | where AvgDuration > 1000
    | order by AvgDuration desc
    " \
  --offset 15m -o table
```

**Solutions**:
1. **Cold Start**: Increase minimum replicas
   ```bash
   az containerapp update \
     --name ascension-${ENVIRONMENT}-ca \
     --resource-group ascension-${ENVIRONMENT}-rg \
     --min-replicas 2
   ```

2. **Resource Constraints**: Increase CPU/memory
   ```bash
   az containerapp update \
     --name ascension-${ENVIRONMENT}-ca \
     --resource-group ascension-${ENVIRONMENT}-rg \
     --cpu 1.0 \
     --memory 2Gi
   ```

3. **Connection Pool Exhaustion**: Check application connection settings
   - Review connection pool configuration in app
   - Increase max connections if needed

#### Issue 4: Database migration failures

**Symptoms**:
- Migration job fails or times out
- Data inconsistencies after deployment

**Diagnosis**:
```bash
# Check migration job logs
az containerapp job execution logs show \
  --name ascension-${ENVIRONMENT}-migration \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --execution-name ${EXECUTION_NAME}

# Verify migration status in database
az cosmosdb sql container query \
  --account-name ascension-${ENVIRONMENT}-cosmos \
  --database-name AgentStudio \
  --container-name Migrations \
  --query "SELECT * FROM c WHERE c.id = 'latest'"
```

**Solutions**:
1. **Timeout**: Increase job timeout
   ```bash
   az containerapp job update \
     --name ascension-${ENVIRONMENT}-migration \
     --resource-group ascension-${ENVIRONMENT}-rg \
     --replica-timeout 3600
   ```

2. **Partial Migration**: Rollback and retry
   ```bash
   # Execute rollback migration
   az containerapp job start \
     --name ascension-${ENVIRONMENT}-migration-rollback \
     --resource-group ascension-${ENVIRONMENT}-rg

   # After successful rollback, retry forward migration
   ```

3. **Cosmos DB Throttling**: Check RU consumption
   ```bash
   az cosmosdb sql container throughput show \
     --account-name ascension-${ENVIRONMENT}-cosmos \
     --database-name AgentStudio \
     --container-name ${CONTAINER_NAME} \
     --resource-group ascension-${ENVIRONMENT}-rg
   ```

#### Issue 5: Traffic not routing to new revision

**Symptoms**:
- Traffic still going to old revision
- New revision shows 0% traffic weight

**Diagnosis**:
```bash
# Check current traffic distribution
az containerapp ingress traffic show \
  --name ascension-${ENVIRONMENT}-ca \
  --resource-group ascension-${ENVIRONMENT}-rg -o table

# Verify revision is active and healthy
az containerapp revision show \
  --name ${APP_NAME}--${REVISION_SUFFIX} \
  --resource-group ascension-${ENVIRONMENT}-rg \
  --query "properties.{Active:active,Health:healthState,Traffic:trafficWeight}" -o json
```

**Solutions**:
1. **Revision not activated**: Explicitly set traffic
   ```bash
   az containerapp ingress traffic set \
     --name ascension-${ENVIRONMENT}-ca \
     --resource-group ascension-${ENVIRONMENT}-rg \
     --revision-weight ${APP_NAME}--${REVISION_SUFFIX}=100
   ```

2. **Multiple active revisions mode**: Change to single revision mode if not using multi-revision deployment
   ```bash
   az containerapp revision set-mode \
     --name ascension-${ENVIRONMENT}-ca \
     --resource-group ascension-${ENVIRONMENT}-rg \
     --mode single
   ```

3. **DNS/CDN caching**: Clear cache or wait for TTL
   ```bash
   # Check DNS propagation
   nslookup ${FQDN}

   # If using Azure Front Door, purge cache
   az afd endpoint purge \
     --resource-group ascension-${ENVIRONMENT}-rg \
     --profile-name ${AFD_PROFILE} \
     --endpoint-name ${ENDPOINT_NAME} \
     --content-paths "/*"
   ```

### Emergency Contacts

#### On-Call Rotation

**Primary On-Call**: Check PagerDuty schedule
- PagerDuty: https://your-org.pagerduty.com/schedules
- Phone: Auto-dialed by PagerDuty

**Secondary On-Call**: Check PagerDuty schedule
- Escalates after 15 minutes if primary doesn't respond

**Escalation Path**:
1. Primary On-Call Engineer (0-15 min)
2. Secondary On-Call Engineer (15-30 min)
3. Engineering Manager (30-45 min)
4. Director of Engineering (45+ min)

#### Service Contacts

**Azure Support**:
- Portal: https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade
- Support Plan: Premier (24/7 phone support)
- Severity 1 (Production Down): Immediate response

**GitHub Actions Support**:
- Status Page: https://www.githubstatus.com
- Support: https://support.github.com

**Third-Party Dependencies**:
- OpenAI Status: https://status.openai.com
- Azure Status: https://status.azure.com

## Post-Deployment

### Validation Tests

#### Smoke Tests

Run automated smoke tests to verify critical functionality:

```bash
# Execute smoke test suite
npm run test:smoke -- --env=${ENVIRONMENT}

# Or use curl for basic API validation
# Test agent creation
curl -X POST https://${FQDN}/api/agents \
  -H "Content-Type: application/json" \
  -d '{"name":"test-agent","type":"meta-agent"}' | jq '.'

# Test agent query
curl https://${FQDN}/api/agents | jq '.[] | {id, name, status}'

# Test meta-agent orchestration
curl -X POST https://${FQDN}/api/meta-agents/orchestrate \
  -H "Content-Type: application/json" \
  -d '{"task":"analyze system health"}' | jq '.'
```

#### Integration Tests

```bash
# Run full integration test suite
npm run test:integration -- --env=${ENVIRONMENT}

# Specific integration scenarios
npm run test:integration -- --env=${ENVIRONMENT} --grep "meta-agent workflow"
npm run test:integration -- --env=${ENVIRONMENT} --grep "real-time signalr"
```

#### End-to-End Tests

```bash
# Run E2E tests against deployed environment
npm run test:e2e -- --env=${ENVIRONMENT} --headless

# Critical user journeys
npm run test:e2e -- --env=${ENVIRONMENT} --spec "agent-creation.spec.ts"
npm run test:e2e -- --env=${ENVIRONMENT} --spec "collaboration.spec.ts"
```

### Performance Validation

#### Benchmark Comparison

```bash
# Run performance benchmarks
k6 run --env ENVIRONMENT=${ENVIRONMENT} performance/load-test.js

# Compare with baseline
k6 run --env ENVIRONMENT=${ENVIRONMENT} \
  --out json=results.json \
  performance/load-test.js

# Analyze results
node scripts/compare-performance.js \
  --baseline performance/baseline-${ENVIRONMENT}.json \
  --current results.json
```

#### Load Test

```bash
# Gradual load test (10 -> 100 -> 500 VUs)
k6 run --vus 10 --duration 5m performance/load-test.js
k6 run --vus 100 --duration 10m performance/load-test.js
k6 run --vus 500 --duration 5m performance/load-test.js

# Check for degradation
# P95 latency should remain < 2000ms
# Error rate should remain < 1%
```

#### Stress Test (Production only, off-peak hours)

```bash
# Stress test to find breaking point
k6 run --vus 1000 --duration 10m performance/stress-test.js

# Monitor during stress test
az monitor app-insights query \
  --app ascension-${ENVIRONMENT}-ai \
  --analytics-query "
    requests
    | where timestamp > ago(10m)
    | summarize
        RequestRate = count() / 600.0,
        ErrorRate = 100.0 * countif(success == false) / count(),
        P95 = percentile(duration, 95)
        by bin(timestamp, 1m)
    | render timechart
    " \
  --offset 10m
```

### Documentation Updates

#### Required Updates After Deployment

1. **Update CHANGELOG.md**
   ```bash
   # Add deployment entry
   cat >> docs/CHANGELOG.md << EOF

   ## [${VERSION}] - $(date +%Y-%m-%d)

   ### Deployed to ${ENVIRONMENT}
   - Deployment time: $(date -u)
   - Commit: ${GITHUB_SHA}
   - Revision: ${APP_NAME}--${REVISION_SUFFIX}

   ### Changes
   - [List key changes from release notes]

   ### Performance
   - P95 Latency: [from benchmarks]
   - Error Rate: [from monitoring]
   EOF
   ```

2. **Update Infrastructure Inventory**
   ```bash
   # Export current infrastructure state
   az resource list \
     --resource-group ascension-${ENVIRONMENT}-rg \
     --query "[].{Name:name, Type:type, Location:location}" \
     -o json > docs/infrastructure/inventory-${ENVIRONMENT}.json
   ```

3. **Update Runbook Metrics**
   ```bash
   # Document deployment metrics
   cat >> docs/runbooks/deployment-metrics.md << EOF

   ## Deployment: $(date +%Y-%m-%d)
   - Environment: ${ENVIRONMENT}
   - Duration: ${DEPLOYMENT_DURATION} minutes
   - Strategy: ${DEPLOYMENT_STRATEGY}
   - Rollback: ${ROLLBACK_OCCURRED:-No}
   - Downtime: 0 minutes (zero-downtime deployment)
   EOF
   ```

4. **Update API Documentation**
   ```bash
   # If API changes were deployed
   npm run docs:api:generate
   git add docs/api/
   git commit -m "docs: Update API documentation for ${VERSION}"
   ```

5. **Update Architecture Diagrams**
   - If new services added, update architecture diagrams
   - Update sequence diagrams for changed workflows
   - Update deployment topology diagrams

### Deployment Verification Checklist

Complete this checklist after each production deployment:

- [ ] All smoke tests passed
- [ ] Integration tests passed
- [ ] Performance benchmarks within acceptable range
- [ ] Error rate < 1% for 30 minutes post-deployment
- [ ] P95 latency < 2000ms sustained
- [ ] All dependencies healthy
- [ ] Monitoring dashboards updated
- [ ] Alerts configured for new features
- [ ] Documentation updated (CHANGELOG, API docs)
- [ ] Stakeholders notified of successful deployment
- [ ] Deployment tagged in Git
- [ ] Incident response team briefed on changes
- [ ] Rollback procedure tested and documented
- [ ] Performance baseline updated

---

## Appendix

### Quick Reference Commands

#### Health Check
```bash
curl -f https://ascension-${ENVIRONMENT}.azurecontainerapps.io/health/ready
```

#### Current Revision
```bash
az containerapp revision list --name ascension-${ENVIRONMENT}-ca --resource-group ascension-${ENVIRONMENT}-rg --query "[?properties.active].name" -o tsv
```

#### Traffic Distribution
```bash
az containerapp ingress traffic show --name ascension-${ENVIRONMENT}-ca --resource-group ascension-${ENVIRONMENT}-rg -o table
```

#### Error Rate
```bash
az monitor app-insights query --app ascension-${ENVIRONMENT}-ai --analytics-query "requests | where timestamp > ago(5m) | summarize ErrorRate = 100.0 * countif(success == false) / count()" --offset 5m --query "tables[0].rows[0][0]" -o tsv
```

#### Immediate Rollback
```bash
az containerapp ingress traffic set --name ascension-${ENVIRONMENT}-ca --resource-group ascension-${ENVIRONMENT}-rg --revision-weight $(cat /tmp/deployment-previous-revision.txt)=100
```

### Environment Variables Reference

| Variable | Dev | Staging | Prod | Description |
|----------|-----|---------|------|-------------|
| ENVIRONMENT | dev | staging | prod | Environment name |
| MIN_REPLICAS | 1 | 1 | 2 | Minimum container replicas |
| MAX_REPLICAS | 3 | 5 | 10 | Maximum container replicas |
| CPU | 0.5 | 0.75 | 1.0 | CPU cores per container |
| MEMORY | 1Gi | 1.5Gi | 2Gi | Memory per container |
| COSMOS_RU | 400 | 1000 | 4000 | Cosmos DB RU/s |
| OPENAI_QUOTA | 10K | 50K | 100K | OpenAI TPM quota |

### Monitoring Dashboard Links

- **Development**: https://portal.azure.com/#@tenant/resource/subscriptions/{sub}/resourceGroups/ascension-dev-rg/providers/Microsoft.Insights/components/ascension-dev-ai
- **Staging**: https://portal.azure.com/#@tenant/resource/subscriptions/{sub}/resourceGroups/ascension-staging-rg/providers/Microsoft.Insights/components/ascension-staging-ai
- **Production**: https://portal.azure.com/#@tenant/resource/subscriptions/{sub}/resourceGroups/ascension-prod-rg/providers/Microsoft.Insights/components/ascension-prod-ai

### Useful KQL Queries

Save these queries in your Azure Monitor for quick access:

**Deployment Health Check**:
```kusto
let deploymentTime = datetime(2025-10-08T00:00:00Z); // Update per deployment
requests
| where timestamp > deploymentTime
| summarize
    TotalRequests = count(),
    FailedRequests = countif(success == false),
    ErrorRate = round(100.0 * countif(success == false) / count(), 2),
    P50 = round(percentile(duration, 50), 0),
    P95 = round(percentile(duration, 95), 0),
    P99 = round(percentile(duration, 99), 0)
    by bin(timestamp, 5m)
| render timechart
```

**Canary Analysis**:
```kusto
let canaryRevision = "ascension-prod-ca--canary-20251008";
requests
| where timestamp > ago(30m)
| extend Revision = tostring(customDimensions.Revision)
| summarize
    ErrorRate = 100.0 * countif(success == false) / count(),
    P95Latency = percentile(duration, 95)
    by Revision
| where Revision == canaryRevision or Revision == "current"
```

---

**Document Version**: 1.0
**Last Updated**: 2025-10-08
**Maintained By**: DevOps Team
**Review Cycle**: After each production deployment or quarterly
**Feedback**: Create issue or PR in GitHub repository
