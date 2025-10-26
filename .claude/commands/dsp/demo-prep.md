# /dsp:demo-prep - Complete Demo Environment Setup

**Purpose**: Orchestrate complete DSP Command Central demo environment preparation including infrastructure provisioning, dummy data generation, mock service configuration, and validation testing.

**Best for**: DSP owner demonstrations requiring production-quality UX without real operational data.

---

## Command Syntax

```bash
/dsp:demo-prep [--skip-azure] [--skip-mobile] [--skip-data]
```

### Options

- `--skip-azure`: Skip Azure infrastructure deployment (use if already deployed)
- `--skip-mobile`: Skip mobile app configuration (dashboard only)
- `--skip-data`: Skip dummy data generation (use existing data)

---

## Execution Workflow

When this command is invoked, perform the following steps in sequence:

### Phase 1: Environment Validation (2-3 minutes)

1. **Verify Prerequisites**
   ```bash
   # Check Node.js version
   node --version  # Must be 20.x LTS

   # Check Azure CLI authentication
   az account show

   # Check npm dependencies installed
   npm list --depth=0

   # Check environment variables configured
   echo $DATABASE_URL
   echo $REDIS_URL
   echo $DEMO_MODE  # Must be "true"
   ```

2. **Validate Project Structure**
   - Confirm `dsp-command-central/` monorepo exists
   - Verify `apps/backend-api`, `apps/web-dashboard`, `apps/mobile-app` directories
   - Check `packages/mock-services/` exists with `cortex-mock`, `adp-mock`, `sacramento-data`

**Expected Output**: ✅ All prerequisites validated, ready for demo setup

---

### Phase 2: Azure Infrastructure Deployment (5-7 minutes)

**Skip if `--skip-azure` flag provided**

1. **Engage @dsp-azure-devops-specialist**
   - Deploy Bicep templates with `environment=demo` parameter
   - Provision App Service Plan (B1), PostgreSQL (B1ms), Redis (C0)
   - Configure App Service with demo environment variables
   - Retrieve connection strings and update `.env` file

2. **Execute Deployment**
   ```bash
   cd dsp-command-central/infra

   # Deploy infrastructure
   az deployment group create \
     --resource-group rg-dsp-demo \
     --template-file main.bicep \
     --parameters environment=demo

   # Capture outputs
   BACKEND_URL=$(az deployment group show \
     --resource-group rg-dsp-demo \
     --name main \
     --query properties.outputs.backendApiUrl.value -o tsv)

   POSTGRES_HOST=$(az deployment group show \
     --resource-group rg-dsp-demo \
     --name main \
     --query properties.outputs.postgresHost.value -o tsv)

   REDIS_HOST=$(az deployment group show \
     --resource-group rg-dsp-demo \
     --name main \
     --query properties.outputs.redisHost.value -o tsv)
   ```

3. **Update Environment Configuration**
   - Create/update `apps/backend-api/.env` with Azure connection strings
   - Set `DEMO_MODE=true`
   - Configure CORS to allow dashboard origin

**Expected Output**: ✅ Azure infrastructure deployed at ~$54/month, connection strings configured

---

### Phase 3: Database Setup & Migrations (2-3 minutes)

1. **Engage @dsp-data-modeling-expert**
   - Run Prisma migrations against demo PostgreSQL
   - Verify all tables created (drivers, routes, vto_offers, rescue_assignments)
   - Create database indexes for performance

2. **Execute Migrations**
   ```bash
   cd apps/backend-api

   # Apply migrations
   npx prisma migrate deploy

   # Verify schema
   npx prisma db pull

   # Generate Prisma client
   npx prisma generate
   ```

**Expected Output**: ✅ Database schema deployed, 8 tables created with indexes

---

### Phase 4: Sacramento Dummy Data Generation (3-5 minutes)

**Skip if `--skip-data` flag provided**

1. **Engage @dsp-qa-demo-orchestrator**
   - Generate realistic Sacramento-specific dummy data
   - Create 30 drivers with performance distribution (20% top, 50% avg, 30% struggling)
   - Generate 32 routes for today (Elk Grove, Rancho Cordova, Galt distribution)
   - Create 5 VTO offers (2 pending, 2 accepted, 1 expired)
   - Generate 3 rescue assignments (1 in progress, 2 completed)

2. **Execute Data Seeding**
   ```bash
   cd packages/mock-services/sacramento-data

   # Run seed script
   npm run seed:demo

   # Verify data created
   npx prisma studio  # Open Prisma Studio to inspect data
   ```

3. **Data Validation Checks**
   - All records have `_isDummyData = true`
   - All driver names include "(DUMMY)" suffix
   - Geographic coordinates within Sacramento bounds
   - Performance tiers distributed correctly (6 top, 15 avg, 9 struggling)
   - Route status colors distributed (15 green, 12 yellow, 5 red)

**Expected Output**: ✅ 30 drivers, 32 routes, 5 VTO offers, 3 rescues created with dummy markers

---

### Phase 5: Mock Service Configuration (1-2 minutes)

1. **Engage @dsp-web-scraping-architect** for Cortex mock
   - Configure `CortexMockService` to simulate 30-second route updates
   - Enable automatic route progress simulation
   - Set up demo authentication bypass (no real Midway SSO)

2. **Engage @dsp-payroll-integration-specialist** for ADP mock
   - Configure `ADPMockService` for VTO logging
   - Set up mock time card creation endpoints
   - Enable demo payroll sync (no real ADP API calls)

3. **Update Backend Configuration**
   ```typescript
   // apps/backend-api/src/app.module.ts
   @Module({
     imports: [
       // Use mock services in demo mode
       process.env.DEMO_MODE === 'true' ? CortexMockModule : CortexModule,
       process.env.DEMO_MODE === 'true' ? ADPMockModule : ADPModule,
     ]
   })
   export class AppModule {}
   ```

**Expected Output**: ✅ Mock services configured, no real API dependencies required

---

### Phase 6: Application Deployment (5-8 minutes)

1. **Build Applications**
   ```bash
   # Build backend API
   cd apps/backend-api
   npm run build

   # Build web dashboard
   cd ../web-dashboard
   npm run build

   # Build mobile app (if not --skip-mobile)
   cd ../mobile-app
   npx expo export
   ```

2. **Deploy Backend to Azure App Service**
   ```bash
   cd apps/backend-api

   # Create deployment package
   zip -r deploy.zip dist node_modules package.json

   # Deploy to Azure
   az webapp deployment source config-zip \
     --resource-group rg-dsp-demo \
     --name app-dsp-api-demo \
     --src deploy.zip

   # Restart app service
   az webapp restart \
     --resource-group rg-dsp-demo \
     --name app-dsp-api-demo
   ```

3. **Deploy Dashboard to Azure App Service**
   ```bash
   cd apps/web-dashboard

   # Deploy Next.js app
   az webapp deployment source config-zip \
     --resource-group rg-dsp-demo \
     --name app-dsp-dashboard-demo \
     --src .next.zip
   ```

**Expected Output**: ✅ Backend API live at https://app-dsp-api-demo.azurewebsites.net, dashboard at https://app-dsp-dashboard-demo.azurewebsites.net

---

### Phase 7: Demo Visual Indicators (1 minute)

1. **Verify Demo Mode Banner**
   - Confirm banner displays: "🎭 DEMO MODE - Using Simulated Sacramento Data"
   - Check all driver names show "(DUMMY)" suffix
   - Validate dummy data markers visible in UI

2. **Test Demo Login Credentials**
   ```
   Owner Account:
   - Email: owner@demo.dsp-command.com
   - Password: DemoOwner123!

   Dispatcher Account:
   - Email: dispatcher@demo.dsp-command.com
   - Password: DemoDispatcher123!

   Driver Account (Mobile):
   - Email: dummy.driver1@example.com
   - Password: DemoDriver123!
   ```

**Expected Output**: ✅ Demo indicators visible, test accounts functional

---

### Phase 8: Validation Testing (3-5 minutes)

1. **Engage @dsp-qa-demo-orchestrator** for smoke tests
   - Test authentication (login as owner, dispatcher, driver)
   - Verify real-time dashboard loads with 32 routes
   - Test WebSocket updates (routes refresh every 30 seconds)
   - Validate VTO acceptance workflow (accept pending offer)
   - Test rescue assignment (assign rescue to RED route)
   - Verify mobile app geofence time clock (if not --skip-mobile)

2. **Execute Automated Tests**
   ```bash
   # Run E2E tests in demo mode
   npm run test:e2e:demo

   # Test mobile app (if not --skip-mobile)
   npm run test:mobile:demo
   ```

3. **Manual Verification Checklist**
   - [ ] Dashboard displays 32 routes with color-coded status
   - [ ] Real-time updates working (completedStops incrementing)
   - [ ] VTO countdown timer functional (30-minute expiration)
   - [ ] Rescue assignment triggers notification
   - [ ] Driver performance tiers displayed correctly
   - [ ] Geographic map shows Sacramento area routes
   - [ ] Demo mode banner visible on all pages

**Expected Output**: ✅ All smoke tests passed, demo environment fully functional

---

### Phase 9: Documentation & Handoff (1 minute)

1. **Generate Demo Environment Summary**
   ```markdown
   # DSP Command Central - Demo Environment

   **Deployed**: [Current Date]
   **Environment**: Demo (DEMO_MODE=true)
   **Region**: Azure East US

   ## Access URLs
   - Dashboard: https://app-dsp-dashboard-demo.azurewebsites.net
   - Backend API: https://app-dsp-api-demo.azurewebsites.net
   - API Docs: https://app-dsp-api-demo.azurewebsites.net/api/docs

   ## Demo Accounts
   - Owner: owner@demo.dsp-command.com / DemoOwner123!
   - Dispatcher: dispatcher@demo.dsp-command.com / DemoDispatcher123!
   - Driver: dummy.driver1@example.com / DemoDriver123!

   ## Demo Data Summary
   - Drivers: 30 (all marked as dummy)
   - Routes Today: 32 (Elk Grove: 15, Rancho Cordova: 12, Galt: 5)
   - VTO Offers: 5 (2 pending, 2 accepted, 1 expired)
   - Rescue Assignments: 3 (1 active, 2 completed)

   ## Monthly Cost: ~$54 (Azure B1/C0 tiers)

   ## Next Steps
   - Share dashboard URL with DSP owner for demonstration
   - Schedule demo walkthrough session
   - Plan production deployment timeline
   - Gather feedback for feature prioritization
   ```

2. **Update Notion DSP Command Center**
   - Sync deployment summary to Notion
   - Link to Azure resource group
   - Document demo credentials (encrypted)

**Expected Output**: ✅ Demo environment documented, ready for stakeholder demonstration

---

## Success Criteria

**Demo environment is ready when:**

✅ Azure infrastructure deployed (~$54/month cost)
✅ Database schema migrated (8 tables with indexes)
✅ 30 drivers, 32 routes, 5 VTO offers, 3 rescues created
✅ All dummy data flagged with `_isDummyData = true`
✅ Mock services configured (no real Cortex/ADP dependencies)
✅ Backend API deployed and accessible
✅ Web dashboard deployed with demo banner
✅ Real-time updates working (30-second WebSocket refresh)
✅ Authentication functional (owner, dispatcher, driver accounts)
✅ Smoke tests passed (VTO workflow, rescue assignment)
✅ Documentation generated and synced to Notion

---

## Estimated Total Time

- **Full Setup**: 25-35 minutes (no flags)
- **With --skip-azure**: 18-25 minutes (infrastructure already deployed)
- **With --skip-mobile**: 20-28 minutes (dashboard only)
- **With --skip-data**: 15-20 minutes (using existing dummy data)

---

## Troubleshooting

### Azure Deployment Fails
**Symptom**: Bicep deployment errors
**Solution**: Verify Azure CLI authenticated (`az login`), check resource group exists, review quota limits

### Database Migration Errors
**Symptom**: Prisma migrate fails
**Solution**: Check DATABASE_URL environment variable, verify PostgreSQL accessible, ensure firewall rules allow connection

### Dummy Data Generation Fails
**Symptom**: Seed script errors
**Solution**: Verify database schema deployed, check for existing data conflicts, review faker.js dependencies installed

### WebSocket Not Updating
**Symptom**: Dashboard routes not refreshing
**Solution**: Check Redis connection, verify Socket.io server running, test WebSocket connection in browser console

### Demo Mode Banner Not Showing
**Symptom**: Banner missing on dashboard
**Solution**: Verify `NEXT_PUBLIC_DEMO_MODE=true` in `.env.local`, rebuild Next.js app, clear browser cache

---

## Related Commands

- `/dsp:deploy-demo` - Deploy to Azure without full prep workflow
- `/dsp:sync-notion` - Sync demo environment details to Notion
- `/innovation:new-idea` - Capture feedback as new idea for iteration

---

**Brookside BI** - *Driving measurable outcomes through production-quality demo environments*
