# /dsp:deploy-demo - One-Command Azure Deployment

**Purpose**: Establish streamlined Azure deployment automation for DSP Command Central demo environment, condensing infrastructure provisioning, application build, and validation into single command execution.

**Best for**: Rapid demo environment deployment when infrastructure code and dummy data already exist, targeting sub-15-minute deployment cycles.

---

## Command Syntax

```bash
/dsp:deploy-demo [--environment <demo|staging|production>] [--skip-tests] [--auto-approve]
```

### Options

- `--environment`: Target Azure environment (default: demo)
  - `demo`: B1/C0 SKUs (~$54/month)
  - `staging`: S1/C1 SKUs (~$180/month)
  - `production`: P1v2/C2 SKUs (~$280/month) with blue-green deployment

- `--skip-tests`: Skip smoke tests after deployment (faster but risky)

- `--auto-approve`: Bypass manual approval prompts (use with caution)

---

## Execution Workflow

When this command is invoked, perform the following steps in sequence:

### Phase 1: Pre-Deployment Validation (1-2 minutes)

1. **Verify Prerequisites**
   ```bash
   # Check Azure CLI authentication
   az account show || {
       echo "❌ Not authenticated to Azure"
       echo "Run: az login"
       exit 1
   }

   # Verify Node.js version
   node_version=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
   if [ "$node_version" -lt 20 ]; then
       echo "❌ Node.js 20.x LTS required (current: $(node --version))"
       exit 1
   fi

   # Check npm dependencies installed
   if [ ! -d "node_modules" ]; then
       echo "❌ Dependencies not installed"
       echo "Run: npm install"
       exit 1
   fi

   # Verify environment variables configured
   required_vars=("DATABASE_URL" "REDIS_URL" "JWT_SECRET")
   for var in "${required_vars[@]}"; do
       if [ -z "${!var}" ]; then
           echo "⚠️ Missing environment variable: $var"
       fi
   done
   ```

2. **Retrieve Azure Secrets from Key Vault**
   ```powershell
   # Establish secure credential retrieval from Azure Key Vault
   # Ensures zero hardcoded secrets in deployment pipeline
   $keyVaultName = "kv-brookside-secrets"

   # Retrieve database credentials
   $dbUser = az keyvault secret show `
       --vault-name $keyVaultName `
       --name "dsp-postgres-admin-user" `
       --query value -o tsv

   $dbPassword = az keyvault secret show `
       --vault-name $keyVaultName `
       --name "dsp-postgres-admin-password" `
       --query value -o tsv

   # Retrieve JWT secret
   $jwtSecret = az keyvault secret show `
       --vault-name $keyVaultName `
       --name "dsp-jwt-secret" `
       --query value -o tsv

   # Export for deployment
   $env:POSTGRES_ADMIN_USER = $dbUser
   $env:POSTGRES_ADMIN_PASSWORD = $dbPassword
   $env:JWT_SECRET = $jwtSecret
   ```

3. **Validate Bicep Templates**
   ```bash
   cd dsp-command-central/infra

   # Validate Bicep syntax
   az bicep build --file main.bicep

   # Perform what-if analysis
   az deployment group what-if \
       --resource-group rg-dsp-demo \
       --template-file main.bicep \
       --parameters environment=demo

   echo "✅ Bicep validation passed"
   ```

**Expected Output**: ✅ Prerequisites validated, secrets retrieved, Bicep templates validated

---

### Phase 2: Infrastructure Provisioning (4-6 minutes)

1. **Engage @dsp-azure-devops-specialist**
   - Deploy Bicep templates with environment-based SKU selection
   - Provision App Service Plan, PostgreSQL Flexible Server, Redis Cache
   - Configure networking and firewall rules
   - Set up Managed Identity for secure database access

2. **Execute Bicep Deployment**
   ```bash
   cd dsp-command-central/infra

   # Deploy infrastructure
   deployment_output=$(az deployment group create \
       --resource-group rg-dsp-demo \
       --template-file main.bicep \
       --parameters \
           environment=demo \
           postgresAdminUser=$POSTGRES_ADMIN_USER \
           postgresAdminPassword=$POSTGRES_ADMIN_PASSWORD \
       --output json)

   # Extract outputs
   BACKEND_URL=$(echo $deployment_output | jq -r '.properties.outputs.backendApiUrl.value')
   DASHBOARD_URL=$(echo $deployment_output | jq -r '.properties.outputs.dashboardUrl.value')
   POSTGRES_HOST=$(echo $deployment_output | jq -r '.properties.outputs.postgresHost.value')
   REDIS_HOST=$(echo $deployment_output | jq -r '.properties.outputs.redisHost.value')

   echo "✅ Infrastructure deployed:"
   echo "  Backend API: https://$BACKEND_URL"
   echo "  Dashboard: https://$DASHBOARD_URL"
   echo "  PostgreSQL: $POSTGRES_HOST"
   echo "  Redis: $REDIS_HOST"
   ```

3. **Configure App Service Settings**
   ```bash
   # Set environment variables on App Service
   az webapp config appsettings set \
       --resource-group rg-dsp-demo \
       --name app-dsp-api-demo \
       --settings \
           DATABASE_URL="postgresql://$POSTGRES_ADMIN_USER:$POSTGRES_ADMIN_PASSWORD@$POSTGRES_HOST:5432/dsp_command" \
           REDIS_URL="$REDIS_HOST:6380" \
           DEMO_MODE="true" \
           JWT_SECRET="$JWT_SECRET" \
           NODE_ENV="production"

   # Enable HTTPS only
   az webapp update \
       --resource-group rg-dsp-demo \
       --name app-dsp-api-demo \
       --set httpsOnly=true

   # Configure CORS
   az webapp cors add \
       --resource-group rg-dsp-demo \
       --name app-dsp-api-demo \
       --allowed-origins "https://$DASHBOARD_URL"
   ```

**Expected Output**: ✅ Azure infrastructure provisioned (~$54/month demo, ~$280/month production)

---

### Phase 3: Application Build & Packaging (3-4 minutes)

1. **Build All Applications**
   ```bash
   cd dsp-command-central

   # Clean previous builds
   npm run clean

   # Install dependencies (if not already)
   npm install

   # Build backend API
   cd apps/backend-api
   npm run build

   # Build web dashboard
   cd ../web-dashboard
   npm run build

   # Build mobile app (Expo export)
   cd ../mobile-app
   npx expo export --platform all

   cd ../..
   echo "✅ All applications built successfully"
   ```

2. **Create Deployment Packages**
   ```bash
   # Package backend API
   cd apps/backend-api
   zip -r deploy-backend.zip dist node_modules package.json package-lock.json prisma/

   # Package web dashboard
   cd ../web-dashboard
   zip -r deploy-dashboard.zip .next public package.json package-lock.json next.config.js

   # Package mobile app (for OTA updates)
   cd ../mobile-app
   zip -r deploy-mobile.zip dist expo-updates.json

   cd ../..
   echo "✅ Deployment packages created"
   ```

**Expected Output**: ✅ Applications built and packaged for deployment

---

### Phase 4: Database Migration & Seeding (2-3 minutes)

1. **Run Prisma Migrations**
   ```bash
   cd apps/backend-api

   # Set DATABASE_URL for migration
   export DATABASE_URL="postgresql://$POSTGRES_ADMIN_USER:$POSTGRES_ADMIN_PASSWORD@$POSTGRES_HOST:5432/dsp_command"

   # Apply migrations
   npx prisma migrate deploy

   # Generate Prisma client
   npx prisma generate

   echo "✅ Database schema migrated"
   ```

2. **Seed Demo Data (if demo environment)**
   ```bash
   if [ "$ENVIRONMENT" = "demo" ]; then
       # Engage @dsp-qa-demo-orchestrator for Sacramento dummy data
       npm run seed:demo

       echo "✅ Demo data seeded (30 drivers, 32 routes, 5 VTO offers)"
   else
       echo "⏭️ Skipping demo data seed (production environment)"
   fi
   ```

**Expected Output**: ✅ Database schema deployed, demo data seeded (if applicable)

---

### Phase 5: Application Deployment (4-5 minutes)

1. **Deploy Backend API to Azure App Service**
   ```bash
   # Deploy using ZIP deployment (faster than Git deployment)
   az webapp deployment source config-zip \
       --resource-group rg-dsp-demo \
       --name app-dsp-api-demo \
       --src apps/backend-api/deploy-backend.zip

   # Restart app to apply changes
   az webapp restart \
       --resource-group rg-dsp-demo \
       --name app-dsp-api-demo

   echo "✅ Backend API deployed to https://$BACKEND_URL"
   ```

2. **Deploy Web Dashboard to Azure App Service**
   ```bash
   az webapp deployment source config-zip \
       --resource-group rg-dsp-demo \
       --name app-dsp-dashboard-demo \
       --src apps/web-dashboard/deploy-dashboard.zip

   az webapp restart \
       --resource-group rg-dsp-demo \
       --name app-dsp-dashboard-demo

   echo "✅ Web dashboard deployed to https://$DASHBOARD_URL"
   ```

3. **Configure Mobile App OTA Updates (Expo)**
   ```bash
   # Publish mobile app update to Expo
   cd apps/mobile-app

   npx expo publish --release-channel demo

   echo "✅ Mobile app OTA update published"
   ```

**Expected Output**: ✅ All applications deployed and accessible

---

### Phase 6: Post-Deployment Validation (2-3 minutes)

**Skip if `--skip-tests` flag provided**

1. **Health Check Endpoints**
   ```bash
   # Check backend API health
   backend_health=$(curl -s -o /dev/null -w "%{http_code}" https://$BACKEND_URL/health)

   if [ "$backend_health" -eq 200 ]; then
       echo "✅ Backend API health check passed"
   else
       echo "❌ Backend API health check failed (HTTP $backend_health)"
       exit 1
   fi

   # Check dashboard health
   dashboard_health=$(curl -s -o /dev/null -w "%{http_code}" https://$DASHBOARD_URL)

   if [ "$dashboard_health" -eq 200 ]; then
       echo "✅ Dashboard health check passed"
   else
       echo "❌ Dashboard health check failed (HTTP $dashboard_health)"
       exit 1
   fi
   ```

2. **Smoke Tests**
   ```typescript
   /**
    * Establish post-deployment smoke tests validating critical workflows.
    * Ensures deployed environment is production-ready for stakeholder demonstrations.
    */
   import { test, expect } from '@playwright/test';

   test('API authentication endpoint functional', async ({ request }) => {
       const response = await request.post(`https://${process.env.BACKEND_URL}/auth/login`, {
           data: {
               email: 'owner@demo.dsp-command.com',
               password: 'DemoOwner123!'
           }
       });

       expect(response.status()).toBe(200);
       const body = await response.json();
       expect(body).toHaveProperty('access_token');
   });

   test('Dashboard loads with demo mode banner', async ({ page }) => {
       await page.goto(`https://${process.env.DASHBOARD_URL}`);

       // Verify demo mode banner visible
       await expect(page.locator('text=🎭 DEMO MODE')).toBeVisible();

       // Verify routes dashboard loads
       await expect(page.locator('[data-testid="routes-grid"]')).toBeVisible();
   });

   test('Real-time WebSocket connection established', async ({ page }) => {
       await page.goto(`https://${process.env.DASHBOARD_URL}/dashboard`);

       // Wait for WebSocket connection
       await page.waitForSelector('[data-testid="websocket-connected"]', { timeout: 5000 });

       expect(await page.locator('[data-testid="websocket-connected"]').isVisible()).toBe(true);
   });
   ```

3. **Execute Smoke Tests**
   ```bash
   # Run Playwright smoke tests
   cd apps/web-dashboard
   npx playwright test --grep @smoke

   echo "✅ Smoke tests passed"
   ```

**Expected Output**: ✅ Health checks passed, smoke tests successful

---

### Phase 7: Deployment Summary & Handoff (1 minute)

1. **Generate Deployment Report**
   ```markdown
   # DSP Command Central - Deployment Report

   **Environment**: Demo
   **Deployed**: 2025-10-26 14:30 UTC
   **Duration**: 12 minutes
   **Status**: ✅ Successful

   ## Deployed Resources
   - **Backend API**: https://app-dsp-api-demo.azurewebsites.net
   - **Web Dashboard**: https://app-dsp-dashboard-demo.azurewebsites.net
   - **PostgreSQL**: psql-dsp-demo.postgres.database.azure.com
   - **Redis**: redis-dsp-demo.redis.cache.windows.net

   ## Demo Credentials
   - Owner: owner@demo.dsp-command.com / DemoOwner123!
   - Dispatcher: dispatcher@demo.dsp-command.com / DemoDispatcher123!
   - Driver: dummy.driver1@example.com / DemoDriver123!

   ## Cost Summary
   - App Service Plan (B1): $13/month
   - PostgreSQL (B1ms): $25/month
   - Redis (C0): $16/month
   - **Total**: $54/month

   ## Health Checks
   - ✅ Backend API responsive (200 OK)
   - ✅ Dashboard accessible (200 OK)
   - ✅ Database migrations applied (8 tables)
   - ✅ Demo data seeded (30 drivers, 32 routes)
   - ✅ WebSocket connections functional

   ## Next Steps
   1. Share dashboard URL with DSP owner for demonstration
   2. Schedule demo walkthrough session
   3. Plan production deployment timeline
   4. Gather feedback for feature prioritization
   ```

2. **Sync to Notion DSP Command Center**
   ```bash
   # Automatically sync deployment report to Notion
   /dsp:sync-notion --direction github-to-notion --scope builds

   echo "✅ Deployment report synced to Notion"
   ```

**Expected Output**: ✅ Deployment report generated and synced to Notion

---

## Success Criteria

**Deployment is successful when:**

✅ Azure infrastructure provisioned with correct SKUs
✅ Database migrations applied successfully
✅ Demo data seeded (if demo environment)
✅ Backend API deployed and health check passing
✅ Web dashboard deployed and accessible
✅ Mobile app OTA update published (Expo)
✅ Smoke tests passed (authentication, WebSocket, dashboard)
✅ Deployment report generated and synced
✅ Total deployment time <15 minutes

---

## Estimated Execution Time

| Environment | Time | Notes |
|------------|------|-------|
| **Demo** (first deployment) | 12-15 min | Includes infrastructure provisioning |
| **Demo** (redeployment) | 5-7 min | Infrastructure already exists |
| **Staging** | 15-18 min | Larger SKUs take longer to provision |
| **Production** | 18-22 min | Blue-green deployment + approval gate |

---

## Environment Comparison

| Resource | Demo (B1/C0) | Staging (S1/C1) | Production (P1v2/C2) |
|----------|-------------|-----------------|----------------------|
| **App Service** | 1 core, 1.75 GB | 1 core, 1.75 GB | 2 cores, 3.5 GB |
| **PostgreSQL** | Burstable 1 vCore | GP 2 vCores | GP 4 vCores |
| **Redis** | 250 MB | 1 GB | 2.5 GB |
| **Cost/Month** | $54 | $180 | $280 |
| **Uptime SLA** | 99.0% | 99.5% | 99.95% |
| **Auto-Scaling** | ❌ | ✅ | ✅ |
| **Backup Retention** | 7 days | 14 days | 30 days |

---

## Rollback Procedures

### If Deployment Fails

**Option 1: Automatic Rollback (Production Only)**
```bash
# Production uses blue-green deployment with automatic rollback
az webapp deployment slot swap \
    --name app-dsp-api-prod \
    --resource-group rg-dsp-prod \
    --slot staging \
    --target-slot production \
    --action swap  # Revert to previous version
```

**Option 2: Redeploy Previous Version**
```bash
# Retrieve last successful deployment commit
last_commit=$(git log --grep="deploy: DSP" --format="%H" -n 1)

# Checkout previous version
git checkout $last_commit

# Redeploy
/dsp:deploy-demo --environment demo --auto-approve
```

**Option 3: Database Migration Rollback**
```bash
# If database migration caused failure, rollback schema
cd apps/backend-api

# Revert to previous migration
npx prisma migrate resolve --rolled-back <migration-name>
```

---

## Troubleshooting

### Azure CLI Not Authenticated
**Symptom**: `ERROR: Please run 'az login' to setup account.`
**Solution**: Run `az login` and select correct subscription

### Bicep Deployment Fails
**Symptom**: Resource quota exceeded or validation errors
**Solution**:
- Check subscription quota limits: `az vm list-usage --location eastus`
- Verify resource names are globally unique
- Review Bicep what-if output for errors

### Database Connection Timeout
**Symptom**: Prisma migration fails with connection timeout
**Solution**:
- Verify PostgreSQL firewall allows Azure services
- Check DATABASE_URL environment variable format
- Ensure Managed Identity has database permissions

### App Service Deployment Hangs
**Symptom**: ZIP deployment never completes
**Solution**:
- Reduce deployment package size (exclude dev dependencies)
- Use Kudu REST API for diagnostics: `https://<app-name>.scm.azurewebsites.net`
- Increase deployment timeout: `az webapp config set --startup-timeout 600`

### Smoke Tests Fail
**Symptom**: Playwright tests timeout or fail
**Solution**:
- Verify app fully started: `az webapp log tail --name app-dsp-api-demo`
- Check CORS configuration allows dashboard origin
- Validate WebSocket connection: Browser DevTools → Network → WS

---

## Security Best Practices

### Pre-Deployment Security Checks
```bash
# Scan for secrets in codebase
git secrets --scan

# Check for vulnerable dependencies
npm audit --production

# Validate environment variables
if grep -r "password\s*=\s*['\"]" .; then
    echo "❌ Hardcoded password detected"
    exit 1
fi
```

### Post-Deployment Security Hardening
```bash
# Enable App Service authentication (Azure AD)
az webapp auth update \
    --resource-group rg-dsp-demo \
    --name app-dsp-api-demo \
    --enabled true \
    --action RedirectToLoginPage

# Configure network restrictions
az webapp config access-restriction add \
    --resource-group rg-dsp-demo \
    --name app-dsp-api-demo \
    --rule-name "AllowOnlyDashboard" \
    --action Allow \
    --ip-address "$DASHBOARD_IP/32" \
    --priority 100

# Enable diagnostic logging
az monitor diagnostic-settings create \
    --resource "/subscriptions/.../app-dsp-api-demo" \
    --name "DiagnosticLogs" \
    --logs '[{"category": "AppServiceHTTPLogs", "enabled": true}]'
```

---

## Related Commands

- `/dsp:demo-prep` - Full demo environment preparation (includes data generation)
- `/dsp:sync-notion` - Sync deployment documentation to Notion
- `/innovation:new-idea` - Capture deployment improvements as new ideas

---

## Deployment Automation (GitHub Actions)

**Manual Trigger via GitHub CLI:**
```bash
# Trigger deployment workflow manually
gh workflow run deploy-dsp.yml \
    --ref main \
    --field environment=demo \
    --field skip-tests=false
```

**Automated Workflow (`.github/workflows/deploy-dsp.yml`):**
```yaml
name: Deploy DSP Command Central

on:
  push:
    branches: [main, staging, demo]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Deployment environment'
        required: true
        default: 'demo'
        type: choice
        options:
          - demo
          - staging
          - production

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment || 'demo' }}

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20.x'

      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Deploy DSP Command Central
        run: |
          /dsp:deploy-demo \
            --environment ${{ github.event.inputs.environment || 'demo' }} \
            --auto-approve

      - name: Run Smoke Tests
        run: npm run test:smoke

      - name: Notify Deployment Success
        if: success()
        uses: slackapi/slack-github-action@v1
        with:
          channel-id: 'deployments'
          slack-message: "✅ DSP ${{ github.event.inputs.environment }} deployed successfully"
```

---

**Brookside BI** - *Driving measurable outcomes through streamlined deployment automation*
