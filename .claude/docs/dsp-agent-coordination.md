# DSP Agent Coordination Guide

**Purpose**: Establish structured multi-agent collaboration patterns for DSP Command Central development, ensuring specialized agents work cohesively from architecture through deployment while maintaining expertise boundaries.

**Best for**: Organizations building complex, multi-faceted systems requiring coordinated effort across operations, infrastructure, frontend, backend, and quality assurance domains.

---

## Table of Contents

1. [Agent Directory](#agent-directory)
2. [Orchestration Patterns](#orchestration-patterns)
3. [Common Workflows](#common-workflows)
4. [Handoff Protocols](#handoff-protocols)
5. [Decision Trees](#decision-trees)
6. [Integration Points](#integration-points)
7. [Best Practices](#best-practices)

---

## Agent Directory

### 10 Specialized DSP Agents

| Agent | Primary Responsibility | Invocation Triggers | Output Deliverables |
|-------|----------------------|-------------------|-------------------|
| **@dsp-operations-architect** | Business logic, rescue scoring, VTO replacement | "rescue", "VTO", "replacement driver", "route status" | Algorithm specs, business rules, calculation logic |
| **@dsp-real-time-systems-engineer** | WebSocket, Redis pub/sub, 30-second updates | "real-time", "WebSocket", "Socket.io", "Redis", "live updates" | Gateway implementation, Redis config, connection management |
| **@dsp-mobile-ux-specialist** | React Native driver app, geofencing, DVIC | "mobile app", "React Native", "Expo", "geofence", "time clock" | Mobile UI components, navigation, offline sync |
| **@dsp-web-scraping-architect** | Cortex automation, Puppeteer, Electron desktop | "scraping", "Cortex", "Puppeteer", "Electron", "automation" | Scraper services, anti-detection strategies, desktop app |
| **@dsp-payroll-integration-specialist** | ADP/Paycom API, VTO logging, time cards | "payroll", "ADP", "Paycom", "time card", "OAuth" | API integration patterns, authentication flows |
| **@dsp-data-modeling-expert** | Prisma schema, query optimization, indexes | "database", "Prisma", "schema", "PostgreSQL", "query" | Schema.prisma file, migrations, query patterns |
| **@dsp-backend-api-architect** | NestJS API, JWT auth, RBAC, service layer | "API", "NestJS", "backend", "authentication", "REST" | Controllers, services, DTOs, guards |
| **@dsp-azure-devops-specialist** | Bicep IaC, GitHub Actions, SKU optimization | "Azure", "deployment", "Bicep", "CI/CD", "infrastructure" | Bicep templates, GitHub Actions workflows, cost analysis |
| **@dsp-performance-analytics-engineer** | Dashboards, KPIs, driver scorecards, Fantastic Plus | "analytics", "dashboard", "metrics", "performance", "KPI" | Dashboard components, chart configs, calculation logic |
| **@dsp-qa-demo-orchestrator** | Testing, demo mode, dummy data, Sacramento seeding | "demo", "testing", "Playwright", "Detox", "dummy data" | Test suites, mock services, seed scripts |

---

## Orchestration Patterns

### Pattern 1: Feature Development (Full Stack)

**Scenario**: Building a new feature that spans frontend, backend, database, and real-time updates

**Agent Sequence**:
```
1. @dsp-operations-architect
   ↓ Defines business logic and algorithms

2. @dsp-data-modeling-expert
   ↓ Designs database schema

3. @dsp-backend-api-architect
   ↓ Implements REST API endpoints

4. @dsp-real-time-systems-engineer
   ↓ Adds WebSocket event broadcasting

5. @dsp-mobile-ux-specialist + @dsp-performance-analytics-engineer (PARALLEL)
   ↓ Build mobile UI and dashboard components simultaneously

6. @dsp-qa-demo-orchestrator
   ↓ Creates E2E tests and demo data
```

**Example: VTO Acceptance Feature**

```typescript
/**
 * Multi-Agent Collaboration: VTO Acceptance Workflow
 * Demonstrates coordinated effort across 6 agents to deliver complete feature
 */

// AGENT 1: @dsp-operations-architect
// Deliverable: VTO replacement driver selection algorithm
function selectReplacementDriver(routeId: string, excludeDriverId: string): Driver {
  // Business logic for scoring available drivers
  // (See dsp-operations-architect.md for full implementation)
}

// AGENT 2: @dsp-data-modeling-expert
// Deliverable: Prisma schema for VTO offers
model VTOOffer {
  id                String   @id @default(uuid())
  routeId           String
  driverId          String
  replacementDriverId String?
  status            VTOStatus
  expiresAt         DateTime
  // (See dsp-data-modeling-expert.md for full schema)
}

// AGENT 3: @dsp-backend-api-architect
// Deliverable: NestJS VTO service with REST endpoint
@Injectable()
export class VTOService {
  async acceptVTOOffer(vtoOfferId: string, driverId: string) {
    // Orchestrates VTO acceptance workflow
    // (See dsp-backend-api-architect.md for full implementation)
  }
}

// AGENT 4: @dsp-real-time-systems-engineer
// Deliverable: WebSocket event for VTO status updates
@WebSocketGateway()
export class VTOGateway {
  @SubscribeMessage('vto-accepted')
  handleVTOAccepted(client: Socket, vtoOfferId: string) {
    // Broadcasts VTO acceptance to all connected clients
    // (See dsp-real-time-systems-engineer.md for full implementation)
  }
}

// AGENT 5: @dsp-mobile-ux-specialist
// Deliverable: Mobile VTO acceptance screen
export function VTOOfferScreen() {
  // React Native component for driver VTO acceptance
  // (See dsp-mobile-ux-specialist.md for full implementation)
}

// AGENT 6: @dsp-qa-demo-orchestrator
// Deliverable: E2E test for VTO workflow
test('driver can accept VTO within 30-minute window', async ({ page }) => {
  // Playwright test validating complete workflow
  // (See dsp-qa-demo-orchestrator.md for full implementation)
});
```

---

### Pattern 2: Infrastructure First (Bottom-Up)

**Scenario**: Setting up foundation before feature development

**Agent Sequence**:
```
1. @dsp-azure-devops-specialist
   ↓ Provisions Azure infrastructure (PostgreSQL, Redis, App Services)

2. @dsp-data-modeling-expert
   ↓ Designs schema and runs migrations

3. @dsp-backend-api-architect
   ↓ Establishes API foundation (auth, middleware, base controllers)

4. @dsp-qa-demo-orchestrator
   ↓ Seeds demo data for development environment

5. All other agents can now build features on solid foundation
```

**Example: Initial Demo Environment Setup**

Use the `/dsp:demo-prep` command, which orchestrates agents in this sequence automatically.

---

### Pattern 3: Parallel Specialization (Maximum Efficiency)

**Scenario**: Independent work streams that can execute simultaneously

**Agent Parallelization**:
```
PARALLEL TRACK 1: Backend Infrastructure
├── @dsp-azure-devops-specialist (Azure provisioning)
└── @dsp-data-modeling-expert (Schema design)

PARALLEL TRACK 2: Integration Services
├── @dsp-web-scraping-architect (Cortex scraper)
└── @dsp-payroll-integration-specialist (ADP integration)

PARALLEL TRACK 3: User Interfaces
├── @dsp-mobile-ux-specialist (Driver mobile app)
└── @dsp-performance-analytics-engineer (Dispatcher dashboard)

CONVERGENCE: @dsp-backend-api-architect
└── Integrates all parallel work streams into cohesive API

VALIDATION: @dsp-qa-demo-orchestrator
└── Tests complete integrated system
```

**Example: Simultaneous Development**

```bash
# Launch 3 parallel agent tasks
/team:assign "Build Cortex scraping desktop app with Puppeteer" dsp-web-scraping-architect &
/team:assign "Implement ADP time card API integration" dsp-payroll-integration-specialist &
/team:assign "Design React Native driver mobile app UI" dsp-mobile-ux-specialist &

# Wait for all to complete, then integrate
wait

# Integrate outputs
/team:assign "Create unified backend API endpoints consuming scraper and payroll services" dsp-backend-api-architect
```

---

## Common Workflows

### Workflow 1: New Feature Request

**User Request**: "Add automatic route reassignment when driver calls in sick"

**Orchestration Steps**:

1. **Requirements Clarification** (@dsp-operations-architect)
   - How to detect sick callouts? (manual entry by dispatcher vs automated detection)
   - Replacement driver selection criteria? (proximity, performance tier, current load)
   - Notification requirements? (SMS, push, email)

2. **Database Impact Analysis** (@dsp-data-modeling-expert)
   - Need new `SickCallout` model?
   - Or extend existing `VTOOffer` model with `reason` field?
   - Performance implications of additional queries?

3. **Backend API Design** (@dsp-backend-api-architect)
   - New endpoint: `POST /callouts/sick`
   - Reuse existing VTO replacement logic or separate service?
   - Authorization: Who can submit sick callouts? (dispatcher only vs driver self-reporting)

4. **Real-Time Updates** (@dsp-real-time-systems-engineer)
   - WebSocket event: `callout-processed`
   - Update route status color if replacement not found immediately

5. **UI Integration** (Parallel: Mobile + Dashboard)
   - **@dsp-mobile-ux-specialist**: Driver self-reporting screen (optional)
   - **@dsp-performance-analytics-engineer**: Dispatcher callout management dashboard

6. **Testing & Demo** (@dsp-qa-demo-orchestrator)
   - E2E test: Sick callout submission → replacement assignment → notification
   - Demo data: Create sample sick callout scenarios for demonstration

**Handoff Artifacts**:
- Operations Architect → Data Modeler: Business rules document + replacement scoring algorithm
- Data Modeler → Backend Architect: Updated schema.prisma with migrations
- Backend Architect → Real-Time Engineer: Service interface for WebSocket events
- Backend Architect → Mobile/Dashboard: API endpoint specifications (OpenAPI/Swagger)
- All → QA Orchestrator: Feature requirements for test case creation

---

### Workflow 2: Performance Optimization

**User Request**: "Dashboard is slow when loading 100+ routes"

**Orchestration Steps**:

1. **Performance Diagnosis** (@dsp-performance-analytics-engineer)
   - Identify bottleneck: Database query vs frontend rendering vs WebSocket overhead
   - Measure baseline: Current load time, database query duration, memory usage

2. **Database Optimization** (@dsp-data-modeling-expert)
   - Add indexes on frequently queried columns (status, date, driver_id)
   - Optimize N+1 query patterns with Prisma `.include()` batching
   - Consider materialized view for pre-aggregated route status counts

3. **API Optimization** (@dsp-backend-api-architect)
   - Implement pagination (limit 25 routes per page)
   - Add Redis caching for route list with 30-second TTL
   - Compress API response payloads (gzip)

4. **WebSocket Optimization** (@dsp-real-time-systems-engineer)
   - Send delta updates instead of full route objects
   - Implement client-side batching (buffer updates for 1 second before rendering)
   - Use Redis pub/sub to distribute WebSocket load across multiple servers

5. **Frontend Optimization** (@dsp-performance-analytics-engineer)
   - Implement virtual scrolling (react-window) for route grid
   - Memoize expensive calculations (useMemo, React.memo)
   - Lazy load route details on demand

6. **Load Testing** (@dsp-qa-demo-orchestrator)
   - Generate 200+ routes in demo environment
   - Run Lighthouse performance audit (target: LCP < 2.5s)
   - Load test with 50 concurrent dashboard users

**Performance Targets**:
- Initial page load: <2 seconds
- Route status update latency: <500ms
- Database query time: <100ms
- WebSocket message frequency: Max 1 per second per client

---

### Workflow 3: Azure Infrastructure Changes

**User Request**: "Upgrade demo environment to staging tier for client presentation"

**Orchestration Steps**:

1. **Infrastructure Planning** (@dsp-azure-devops-specialist)
   - Update Bicep parameters: `environment=staging`
   - Calculate cost delta: $54/month (demo) → $180/month (staging)
   - Schedule deployment window (requires downtime for database tier upgrade)

2. **Database Migration** (@dsp-data-modeling-expert)
   - Backup current demo data
   - Test migration on local PostgreSQL instance first
   - Verify schema compatibility with staging tier (GP 2 vCores)

3. **Application Configuration** (@dsp-backend-api-architect)
   - Update environment variables for staging
   - Adjust connection pool size for higher concurrency (staging supports more connections)
   - Enable production logging (structured JSON logs to Azure Monitor)

4. **Deployment Automation** (@dsp-azure-devops-specialist)
   ```bash
   # Execute upgrade deployment
   /dsp:deploy-demo --environment staging --skip-tests

   # Verify resource SKUs upgraded
   az resource list --resource-group rg-dsp-staging --output table
   ```

5. **Validation** (@dsp-qa-demo-orchestrator)
   - Run full smoke test suite against staging environment
   - Verify performance improvements (measure route query latency)
   - Test with higher concurrency (50 simulated dashboard users)

6. **Documentation Update** (@dsp-performance-analytics-engineer)
   - Update cost tracking in Notion Software Tracker
   - Document staging environment access URLs
   - Provide client with demo credentials and usage guide

---

## Handoff Protocols

### Clean Handoffs: What to Provide

**From @dsp-operations-architect → @dsp-backend-api-architect**
```markdown
## Handoff: VTO Replacement Driver Selection

**Business Logic Summary**:
- Algorithm: Proximity (40%) + Performance Tier (30%) + Current Load (30%)
- Threshold: Must score >60/100 to be eligible
- Fallback: If no replacement found, notify dispatcher for manual assignment

**Expected Input**:
- `routeId: string` - Route needing replacement
- `excludeDriverId: string` - Driver taking VTO (exclude from selection)

**Expected Output**:
- `Driver | null` - Selected replacement driver or null if none found

**Edge Cases**:
- All drivers already assigned routes → return null
- Multiple drivers tied at same score → select driver with longest tenure
- Replacement driver later requests VTO → re-run selection excluding both drivers

**Implementation File**: `apps/backend-api/src/services/vto/replacement-selector.service.ts`
```

**From @dsp-data-modeling-expert → @dsp-backend-api-architect**
```markdown
## Handoff: Database Schema Changes

**Migration Applied**: `20251026_add_vto_replacement_tracking.sql`

**New Models**:
- `VTOOffer` (see schema.prisma lines 45-62)
- `VTOOffer.replacementDriverId` (nullable relation to Driver)

**Indexes Added**:
- `VTOOffer.status + VTOOffer.expiresAt` (composite index for active offers query)

**Breaking Changes**:
- None (backward compatible)

**Query Patterns**:
```typescript
// Efficient active VTO offers query (uses new index)
const activeOffers = await prisma.vTOOffer.findMany({
  where: {
    status: 'PENDING',
    expiresAt: { gt: new Date() }
  },
  include: { driver: true, route: true }
});
```

**Next Steps**:
- Implement VTO service in NestJS module
- Create REST endpoints: POST /vto/offers, POST /vto/offers/:id/accept
```

**From @dsp-backend-api-architect → @dsp-mobile-ux-specialist**
```markdown
## Handoff: VTO API Endpoints

**Base URL**: `https://app-dsp-api-demo.azurewebsites.net/api/v1`

**Endpoints**:

1. **Get Active VTO Offers**
   - **Method**: GET
   - **Path**: `/vto/offers/active`
   - **Auth**: Bearer JWT (driver role)
   - **Response**:
   ```typescript
   interface VTOOfferResponse {
     id: string;
     route: {
       routeCode: string;
       area: string;
       totalStops: number;
     };
     expiresAt: string; // ISO 8601 timestamp
     remainingMinutes: number;
   }
   ```

2. **Accept VTO Offer**
   - **Method**: POST
   - **Path**: `/vto/offers/:id/accept`
   - **Auth**: Bearer JWT (driver role)
   - **Response**:
   ```typescript
   interface VTOAcceptanceResponse {
     success: boolean;
     replacement?: {
       name: string;
       phone: string;
     };
     message: string;
   }
   ```

**Error Handling**:
- `400 Bad Request`: VTO already accepted or expired
- `403 Forbidden`: Not assigned to this route
- `404 Not Found`: Invalid VTO offer ID

**Swagger Docs**: `https://app-dsp-api-demo.azurewebsites.net/api/docs`

**Next Steps**:
- Implement mobile VTO acceptance screen
- Add countdown timer (30-minute expiration)
- Show push notification when replacement assigned
```

---

## Decision Trees

### Decision Tree 1: "Which Agent Handles Database Work?"

```
Is it schema design or query optimization?
├─ YES → @dsp-data-modeling-expert
│         ├─ New models/fields → Update schema.prisma + create migration
│         └─ Slow queries → Add indexes, optimize Prisma queries
│
└─ NO → Is it API endpoint implementation?
         ├─ YES → @dsp-backend-api-architect
         │         └─ Implements service layer using Prisma client
         │
         └─ Is it Azure database provisioning?
                   └─ YES → @dsp-azure-devops-specialist
                             └─ Bicep template for PostgreSQL Flexible Server
```

---

### Decision Tree 2: "Real-Time Updates or REST API?"

```
Does the client need immediate updates without polling?
├─ YES → @dsp-real-time-systems-engineer
│         ├─ Route status changes every 30 seconds → WebSocket
│         ├─ VTO acceptance notification → WebSocket event
│         └─ Driver location updates → Socket.io + Redis pub/sub
│
└─ NO → Standard CRUD operations
         └─ @dsp-backend-api-architect
                   └─ RESTful endpoints with pagination
```

---

### Decision Tree 3: "Mobile App or Web Dashboard?"

```
Who is the primary user?
├─ DRIVER → @dsp-mobile-ux-specialist
│            ├─ React Native/Expo mobile app
│            ├─ Features: VTO acceptance, time clock, DVIC, route view
│            └─ Offline-first architecture with sync
│
├─ DISPATCHER/OWNER → @dsp-performance-analytics-engineer
│                      ├─ Next.js web dashboard
│                      ├─ Features: Real-time route monitoring, rescue assignment, analytics
│                      └─ Desktop-optimized (large screens, multiple monitors)
│
└─ BOTH → Coordinate between both agents
            ├─ Shared: API contracts, data models, authentication
            └─ Different: UI/UX patterns, device capabilities, workflows
```

---

## Integration Points

### Integration Point 1: Cortex Scraper → Backend API

**Agents Involved**:
- **@dsp-web-scraping-architect**: Builds Puppeteer scraper in Electron desktop app
- **@dsp-backend-api-architect**: Provides REST endpoint to receive scraped data

**Integration Contract**:
```typescript
// Cortex Desktop App (Electron)
// Agent: @dsp-web-scraping-architect
async function scrapeCortexRoutes(): Promise<RouteData[]> {
  // Scrape route data from Cortex UI
  return scrapedRoutes;
}

async function pushToBackendAPI(routes: RouteData[]) {
  await fetch('https://app-dsp-api-demo.azurewebsites.net/api/v1/cortex/sync', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${CORTEX_SYNC_TOKEN}`
    },
    body: JSON.stringify({ routes })
  });
}

// Backend API (NestJS)
// Agent: @dsp-backend-api-architect
@Controller('cortex')
export class CortexController {
  @Post('sync')
  @UseGuards(CortexAuthGuard) // Validates CORTEX_SYNC_TOKEN
  async syncRoutes(@Body() data: { routes: RouteData[] }) {
    return this.cortexService.processScrapedRoutes(data.routes);
  }
}
```

**Coordination**:
1. Web Scraping Architect defines scraping logic and data structure
2. Backend API Architect implements `/cortex/sync` endpoint accepting that structure
3. Both agents agree on authentication method (API key vs JWT)
4. QA Orchestrator creates integration test verifying end-to-end flow

---

### Integration Point 2: Backend API → Real-Time Dashboard

**Agents Involved**:
- **@dsp-backend-api-architect**: Provides WebSocket gateway
- **@dsp-real-time-systems-engineer**: Implements Socket.io server and Redis pub/sub
- **@dsp-performance-analytics-engineer**: Builds dashboard consuming WebSocket events

**Integration Contract**:
```typescript
// Backend: WebSocket Gateway
// Agents: @dsp-backend-api-architect + @dsp-real-time-systems-engineer
@WebSocketGateway({ cors: true })
export class RouteGateway {
  @SubscribeMessage('route-updated')
  handleRouteUpdate(data: RouteUpdateEvent) {
    // Broadcast to all connected clients
    this.server.emit('route-status-changed', data);
  }
}

// Frontend: Dashboard WebSocket Client
// Agent: @dsp-performance-analytics-engineer
export function useRouteWebSocket() {
  const [routes, setRoutes] = useState<Route[]>([]);

  useEffect(() => {
    const socket = io('https://app-dsp-api-demo.azurewebsites.net');

    socket.on('route-status-changed', (update: RouteUpdateEvent) => {
      setRoutes(prev => updateRouteInList(prev, update));
    });

    return () => socket.disconnect();
  }, []);

  return { routes };
}
```

---

## Best Practices

### 1. Clear Responsibility Boundaries

**✅ DO**:
- Operations Architect defines "what" (business logic, algorithms)
- Backend Architect implements "how" (service layer, API endpoints)
- Data Modeler owns schema structure and query patterns
- Real-Time Engineer handles WebSocket infrastructure (not business logic)

**❌ DON'T**:
- Let Operations Architect write NestJS code (that's Backend Architect's domain)
- Have Backend Architect design database schema (Data Modeler's expertise)
- Mix business logic into WebSocket gateway (separation of concerns)

---

### 2. Documentation as Handoff

**✅ DO**:
- Operations Architect creates ADR (Architecture Decision Record) for complex business rules
- Data Modeler documents schema changes in migration comments
- Backend Architect generates OpenAPI/Swagger documentation automatically
- All agents update relevant .md files in `/docs` before handoff

**❌ DON'T**:
- Rely on verbal communication for complex technical decisions
- Assume next agent will "figure it out" from reading code
- Skip documentation because "the code is self-explanatory"

---

### 3. Parallel Work Coordination

**✅ DO**:
- Use clearly defined interfaces (TypeScript types, API contracts)
- Establish mock implementations early (allows parallel frontend/backend development)
- Communicate breaking changes immediately via Notion sync
- Run integration tests frequently to catch coordination issues

**❌ DON'T**:
- Work in isolation for weeks without integration checkpoints
- Change API contracts without notifying consuming agents
- Assume "it will work when we integrate at the end"

---

### 4. Agent Activity Logging

**✅ DO**:
- Log significant handoffs: `/agent:log-activity @source-agent handed-off "Transferring to @target-agent..."`
- Document blockers requiring external help
- Track critical milestones (deployment complete, tests passing)
- Update Notion Agent Activity Hub for stakeholder visibility

**❌ DON'T**:
- Skip logging (causes workflow visibility gaps)
- Log trivial updates (clutters activity feed)
- Use vague descriptions ("worked on stuff")

---

## Example: Complete Feature Lifecycle

### Feature: "Rescue Assignment with Proximity Scoring"

**Phase 1: Requirements & Design (Operations Architect)**
```bash
# Engage operations architect to define rescue logic
/team:assign "Define rescue assignment algorithm with proximity and performance tier scoring" dsp-operations-architect

# Output: Business rules document with scoring formula
```

**Phase 2: Database Schema (Data Modeler)**
```bash
# Create database models for rescue assignments
/team:assign "Design RescueAssignment schema with route relations and status tracking" dsp-data-modeling-expert

# Output: Updated schema.prisma + migration file
```

**Phase 3: Backend Implementation (Backend Architect)**
```bash
# Implement REST API for rescue operations
/team:assign "Create NestJS rescue service with POST /rescue/assign endpoint using proximity scoring algorithm" dsp-backend-api-architect

# Output: Rescue module with controllers, services, DTOs
```

**Phase 4: Real-Time Notifications (Real-Time Engineer)**
```bash
# Add WebSocket event for rescue assignments
/team:assign "Implement WebSocket event 'rescue-assigned' broadcasting to dashboard and mobile app" dsp-real-time-systems-engineer

# Output: WebSocket gateway with rescue event handlers
```

**Phase 5: UI Integration (Parallel)**
```bash
# Dispatcher dashboard rescue panel
/team:assign "Build rescue assignment dashboard panel with route selection and driver proximity visualization" dsp-performance-analytics-engineer &

# Driver mobile app rescue notification
/team:assign "Create mobile push notification and rescue acceptance screen for driver app" dsp-mobile-ux-specialist &

wait
```

**Phase 6: Testing & Demo (QA Orchestrator)**
```bash
# Create E2E tests and demo scenario
/team:assign "Write Playwright test for rescue assignment workflow and generate demo data with 3 RED routes needing rescue" dsp-qa-demo-orchestrator

# Output: E2E test suite + demo seed data
```

**Phase 7: Deployment (Azure DevOps Specialist)**
```bash
# Deploy complete feature to Azure demo environment
/dsp:deploy-demo --environment demo

# Sync documentation to Notion
/dsp:sync-notion --direction github-to-notion --scope all
```

---

## Workflow Automation Scripts

### Script: Orchestrate New Feature Development
```bash
#!/bin/bash
# orchestrate-feature.sh
# Automates multi-agent feature development workflow

FEATURE_NAME=$1
FEATURE_DESCRIPTION=$2

echo "🚀 Orchestrating feature: $FEATURE_NAME"

# Phase 1: Business Logic
echo "📐 Phase 1: Defining business logic..."
/team:assign "Define business rules and algorithms for $FEATURE_DESCRIPTION" dsp-operations-architect

# Phase 2: Database Design
echo "🗄️ Phase 2: Designing database schema..."
/team:assign "Design database schema for $FEATURE_NAME with proper relations and indexes" dsp-data-modeling-expert

# Phase 3: Backend API
echo "🔧 Phase 3: Implementing backend API..."
/team:assign "Create NestJS module with REST endpoints for $FEATURE_NAME" dsp-backend-api-architect

# Phase 4: Real-Time (if needed)
read -p "Does this feature require real-time updates? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "⚡ Phase 4: Adding WebSocket events..."
    /team:assign "Implement WebSocket events for $FEATURE_NAME real-time updates" dsp-real-time-systems-engineer
fi

# Phase 5: UI (Parallel)
echo "🎨 Phase 5: Building UI components..."
/team:assign "Create dashboard components for $FEATURE_NAME" dsp-performance-analytics-engineer &
/team:assign "Create mobile screens for $FEATURE_NAME" dsp-mobile-ux-specialist &
wait

# Phase 6: Testing
echo "🧪 Phase 6: Creating tests and demo data..."
/team:assign "Write E2E tests and generate demo data for $FEATURE_NAME" dsp-qa-demo-orchestrator

echo "✅ Feature orchestration complete!"
echo "📝 Next steps: Review deliverables and deploy with /dsp:deploy-demo"
```

---

## Troubleshooting Agent Coordination

### Issue: Agents Producing Conflicting Implementations

**Symptom**: Backend API expects different data structure than frontend sends

**Root Cause**: No shared contract definition before parallel work

**Solution**:
1. **Pause development** on conflicting components
2. **Convene coordination meeting** (Backend Architect + Mobile/Dashboard specialists)
3. **Define TypeScript interfaces** as shared contracts
4. **Create mock implementations** for parallel work continuation
5. **Establish integration test** validating contract adherence

**Prevention**:
- Always define API contracts (OpenAPI/Swagger) before frontend work begins
- Use shared TypeScript types library (`@dsp/shared-types` package)
- Run integration tests nightly to catch drift early

---

### Issue: Agents Waiting on Blocked Dependencies

**Symptom**: Mobile app can't proceed because backend API endpoints don't exist yet

**Root Cause**: Sequential bottleneck (no parallel work possible)

**Solution**:
1. **Backend Architect creates mock API** (JSON server or MSW)
2. **Mobile/Dashboard teams use mocks** for UI development
3. **Real API implementation happens in parallel**
4. **Integration test validates real API matches mock contract**

**Prevention**:
- Always provide mock implementations for external dependencies
- Use design-by-contract approach (define interfaces first)
- Enable parallel work streams whenever possible

---

## Summary: Effective Multi-Agent Orchestration

**Keys to Success**:
1. ✅ **Clear Boundaries**: Each agent has well-defined expertise domain
2. ✅ **Structured Handoffs**: Documentation and artifacts exchange, not just code
3. ✅ **Parallel Execution**: Maximize efficiency by coordinating independent work streams
4. ✅ **Contract-First Design**: API contracts and interfaces defined before implementation
5. ✅ **Continuous Integration**: Frequent integration tests catch coordination issues early
6. ✅ **Activity Logging**: Visible workflow tracking for stakeholder transparency

**Anti-Patterns to Avoid**:
- ❌ Isolated development without integration checkpoints
- ❌ Ambiguous responsibility boundaries (who owns what?)
- ❌ Sequential bottlenecks when parallel work is possible
- ❌ Missing documentation handoffs
- ❌ Breaking API contracts without communication

---

**Brookside BI** - *Driving measurable outcomes through coordinated multi-agent collaboration*
