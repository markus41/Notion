# Manual Dependency Linking Guide

**Purpose**: Establish complete software cost tracking by linking all identified dependencies to their respective Example Build entries in the Brookside BI Innovation Nexus.

**Context**: Wave 4 of repository portfolio analysis discovered a Notion MCP limitation - relation properties cannot be updated programmatically. This guide provides the manual workaround to complete the dependency linking process.

**Estimated Time**: 45-60 minutes (258 dependencies across 5 builds)

---

## Background: Notion MCP Limitation

### Issue Discovered

**Date**: October 22, 2025
**Context**: Automated Wave 4 execution - linking Software & Cost Tracker entries to Example Builds
**Tool Used**: Notion MCP `notion-update-page` tool
**Error**: Tool only supports content updates and title property updates, **not database relation properties**

### Available Notion MCP Operations

| Tool | Create Pages | Update Content | Update Properties | Update Relations |
|------|-------------|----------------|-------------------|------------------|
| `notion-create-pages` | ✅ | N/A | ✅ (at creation) | ✅ (at creation) |
| `notion-update-page` | N/A | ✅ | ✅ (title only) | ❌ **Not Supported** |

### Workaround

**Manual UI linking via Notion interface** - leveraging bi-directional relations to minimize effort.

**Efficiency**: Update from **Example Builds** side (1 action per build) rather than Software Tracker side (258 individual actions).

---

## Dependency Inventory

### Summary Statistics

| Repository | Production Deps | Dev Deps | Total | Build Entry Status |
|------------|----------------|----------|-------|--------------------|
| **Brookside-Website** | 27 | 53 | 80 | ✅ Created (🟢 Active) |
| **realmworks-productiv** | 61 | 14 | 75 | ✅ Created (🟢 Active) |
| **Project-Ascension** | 0 | 14 | 14 | ✅ Created (🟢 Active) |
| **RealmOS** | 23 | 41 | 64 | ✅ Created (📦 Archived) |
| **markus41/Notion** | 18 | 7 | 25 | ✅ Created (🟢 Active) |
| **TOTAL** | **129** | **129** | **258** | **5 builds ready** |

### Software Tracker Entries Status

| Status | Count | Details |
|--------|-------|---------|
| **Created (Wave 4)** | 6 | Next.js, React, TypeScript, Tailwind CSS, Vitest, Playwright |
| **Pre-existing** | 6 | Power BI Pro, Notion API, GitHub Enterprise, Azure Storage, Azure OpenAI, Azure Functions |
| **To Be Created** | 246 | Remaining unique dependencies across all repositories |

---

## Step-by-Step Linking Process

### Phase 1: Create Missing Software Tracker Entries (Estimated: 30-40 minutes)

**Objective**: Establish Software Tracker entries for 246 dependencies before linking to builds.

#### 1.1 Open Software & Cost Tracker Database

**URL**: https://www.notion.so/30725fce2b7c4b3eb7ff26a07eec325e

#### 1.2 Create Entries by Repository

**Process** (per dependency):
1. Click "+ New" in Software Tracker database
2. Fill properties:
   - **Name**: Package name with version (e.g., "lodash 4.17.21")
   - **Category**: Development (most common), Infrastructure, AI/ML, Design, Other
   - **Cost**: $0 (free open-source)
   - **Payment Frequency**: Free
   - **Status**: 🟢 Active
   - **Subscription Type**: Free
   - **Microsoft Service**: None (unless Azure/M365/Power Platform/GitHub/Dynamics)
   - **Criticality**: 🔴 Critical (if core framework), 🟡 Important (if commonly used), 🟢 Nice to Have (if rarely used)
3. Click "Create" - do NOT link builds yet (handled in Phase 2)

**Recommended Order**:
1. **Brookside-Website** (74 remaining): Focus on React ecosystem, UI libraries, testing tools
2. **realmworks-productiv** (75 total): Radix UI components, data visualization, utilities
3. **Project-Ascension** (14 dev-only): Testing frameworks, build tools, type definitions
4. **RealmOS** (64 total): Express.js ecosystem, PostgreSQL drivers, Redis, Socket.io
5. **markus41/Notion** (25 total): Notion SDK, Azure integrations, validation libraries

**Bulk Creation Tip**: Group similar dependencies (all React libraries together, all TypeScript types together) for efficiency.

---

### Phase 2: Link Dependencies to Builds (Estimated: 15-20 minutes)

**Objective**: Establish bi-directional relations between Software Tracker entries and Example Build entries.

#### 2.1 Update from Example Builds (Most Efficient)

**Reason**: 5 actions (one per build) vs. 258 actions (one per dependency).

#### 2.2 Brookside-Website Linking

**Build URL**: https://www.notion.so/29486779099a8159965fc5d84ec26ff4

**Steps**:
1. Open Brookside-Website Example Build entry
2. Scroll to **"Software/Tools Used"** property
3. Click to edit the relation field
4. Search and select ALL Brookside-Website dependencies:
   - **Core Framework**: Next.js 15.0.2, React 19.0.0-rc, TypeScript 5.5.4
   - **Styling**: Tailwind CSS 3.4.13, PostCSS, Autoprefixer
   - **Testing**: Vitest, Playwright, @testing-library/react
   - **UI Libraries**: Radix UI components, Framer Motion, React Three Fiber
   - **Build Tools**: Turbo, ESLint, Prettier
   - **Development**: ts-node, nodemon, dotenv
   - *[Continue with all 80 dependencies from analysis]*
5. Save (bi-directional relation auto-updates Software Tracker entries)

**Expected Result**:
- Brookside-Website shows 80 linked software entries
- Each of those 80 Software Tracker entries shows Brookside-Website in "Used In Builds"
- Total Cost rollup calculates (should be $0 as all are free open-source)

#### 2.3 realmworks-productiv Linking

**Build URL**: https://www.notion.so/29486779099a810f92aaf1f91d09a750

**Steps**:
1. Open realmworks-productiv Example Build entry
2. Edit **"Software/Tools Used"** property
3. Select ALL realmworks-productiv dependencies:
   - **UI Components**: Radix UI suite, Lucide React icons
   - **Data Visualization**: D3.js, Recharts, @visx libraries
   - **Utilities**: clsx, tailwind-merge, date-fns
   - **Forms**: react-hook-form, Zod validation
   - *[Continue with all 75 dependencies]*
4. Save

#### 2.4 Project-Ascension Linking

**Build URL**: https://www.notion.so/29486779099a81469923fd1690c85b55

**Steps**:
1. Open Project-Ascension Example Build entry
2. Edit **"Software/Tools Used"** property
3. Select ALL Project-Ascension dev dependencies:
   - **Testing**: Vitest, @vitest/ui, vitest-fetch-mock
   - **Build Tools**: Vite, TypeScript, esbuild
   - **Type Definitions**: @types/* packages
   - *[Only 14 dependencies - fastest to link]*
4. Save

**Note**: Project-Ascension has **0 production dependencies** - highlight this exceptional architecture in build notes.

#### 2.5 RealmOS Linking

**Build URL**: https://www.notion.so/29486779099a81bab4e3fe9214581f57

**Steps**:
1. Open RealmOS Example Build entry
2. Edit **"Software/Tools Used"** property
3. Select ALL RealmOS dependencies:
   - **Backend**: Express.js, Knex (PostgreSQL ORM), pg driver
   - **Caching**: Redis, ioredis client
   - **Queue Processing**: Bull, bull-board
   - **Real-time**: Socket.io
   - **Utilities**: lodash, dayjs, uuid
   - *[Continue with all 64 dependencies]*
4. Save

**Note**: Repository is **archived** - ensure Status property reflects this.

#### 2.6 markus41/Notion (Innovation Nexus) Linking

**Build URL**: https://www.notion.so/29486779099a81d191b7cc6658a059f3

**Steps**:
1. Open Innovation Nexus Platform Example Build entry
2. Edit **"Software/Tools Used"** property
3. Select ALL markus41/Notion dependencies:
   - **Notion SDK**: @notionhq/client
   - **Azure Integrations**: @azure/* packages
   - **MCP Servers**: Notion, GitHub, Azure, Playwright clients
   - **Validation**: Zod
   - *[Continue with all 25 dependencies]*
4. Save

---

## Verification Steps

### After Each Build Linking

1. **Check Total Cost Rollup**:
   - Open Example Build entry
   - Verify "Total Cost" property populated
   - Expected: ~$0-10/month for open-source projects, higher for commercial tools

2. **Spot-Check Software Tracker**:
   - Open 3-5 random Software Tracker entries
   - Verify "Used In Builds" shows correct build name(s)
   - Confirm bi-directional relation working

3. **Validate Dependency Count**:
   - Count linked dependencies in build entry
   - Compare against repository analysis (80, 75, 14, 64, 25)
   - Ensure no missing dependencies

### Final Validation (All Builds Complete)

```sql
-- Notion formula to verify (theoretical - for reference)
-- "Software/Tools Used" relation count should match repository analysis

Brookside-Website: 80 dependencies linked
realmworks-productiv: 75 dependencies linked
Project-Ascension: 14 dependencies linked
RealmOS: 64 dependencies linked
markus41/Notion: 25 dependencies linked
TOTAL: 258 dependencies across 5 builds
```

**Manual Verification**:
1. Open each Example Build
2. Click "Software/Tools Used" property
3. Count displayed relations
4. Compare against expected totals above

---

## Dependency Reference Lists

### Brookside-Website (80 Dependencies)

**Production Dependencies (27)**:
```
next (15.0.2), react (19.0.0-rc), react-dom (19.0.0-rc), @radix-ui/react-* (25 components),
framer-motion, @react-three/fiber, @react-three/drei, clsx, tailwind-merge, lucide-react
```

**Dev Dependencies (53)**:
```
typescript (5.5.4), @types/react, @types/node, vitest, playwright, @testing-library/react,
eslint, prettier, tailwindcss (3.4.13), postcss, autoprefixer, turbo, ts-node, dotenv
```

### realmworks-productiv (75 Dependencies)

**Production Dependencies (61)**:
```
@radix-ui/react-* (30+ components), d3, recharts, @visx/*, react-hook-form, zod,
date-fns, clsx, tailwind-merge, lucide-react, cmdk, vaul, sonner, next-themes
```

**Dev Dependencies (14)**:
```
typescript, @types/react, @types/node, eslint, prettier, tailwindcss, postcss, autoprefixer
```

### Project-Ascension (14 Dependencies)

**Production Dependencies**: *0 (zero - exceptional architecture)*

**Dev Dependencies (14)**:
```
vitest, @vitest/ui, vitest-fetch-mock, @types/node, typescript, vite, esbuild,
eslint, prettier, @typescript-eslint/*
```

### RealmOS (64 Dependencies)

**Production Dependencies (23)**:
```
express, knex, pg, ioredis, bull, bull-board, socket.io, lodash, dayjs, uuid,
bcrypt, jsonwebtoken, express-validator, cors, helmet, morgan, winston
```

**Dev Dependencies (41)**:
```
typescript, @types/*, jest, supertest, eslint, prettier, nodemon, ts-node, dotenv,
@types/express, @types/node, @types/pg, @types/redis, @types/socket.io
```

### markus41/Notion (25 Dependencies)

**Production Dependencies (18)**:
```
@notionhq/client, @azure/identity, @azure/keyvault-secrets, @azure/storage-blob,
@azure/openai, zod, dotenv, express, cors
```

**Dev Dependencies (7)**:
```
typescript, @types/node, @types/express, ts-node, nodemon, eslint, prettier
```

---

## Common Issues & Solutions

### Issue 1: Dependency Not Found in Software Tracker

**Symptom**: Cannot find dependency when searching in "Software/Tools Used" field.

**Solution**:
1. Return to Phase 1 (Create Missing Software Tracker Entries)
2. Create the missing entry
3. Return to Phase 2 linking step

### Issue 2: Duplicate Dependencies Across Builds

**Symptom**: Same dependency (e.g., "TypeScript 5.5.4") used in multiple builds.

**Expected Behavior**: This is correct! One Software Tracker entry can link to multiple builds.

**Result**: Software Tracker entry shows all builds in "Used In Builds" property.

### Issue 3: Total Cost Rollup Shows $0 Despite Dependencies

**Cause**: All linked dependencies are free open-source software.

**Expected**: This is correct for most development projects.

**Action**: No fix needed unless commercial software (e.g., GitHub Enterprise, Power BI Pro) missing.

### Issue 4: Archived Repository (RealmOS) Concerns

**Question**: Should archived repository dependencies be linked?

**Answer**: **YES**. Even archived repositories provide reference value. Cost tracking remains important for:
- Historical spend analysis
- License compliance
- Future reactivation cost estimates
- Knowledge preservation

---

## Success Metrics

### Completion Criteria

✅ **All 258 dependencies have Software Tracker entries**
✅ **All 5 Example Builds link to their respective dependencies**
✅ **Bi-directional relations verified** (both directions show correct data)
✅ **Total Cost rollups calculated** for each build
✅ **Dependency counts match** repository analysis (80, 75, 14, 64, 25)

### Business Value Delivered

- **Complete Cost Visibility**: All software dependencies tracked with cost attribution
- **Portfolio Analysis**: Identify duplicate dependencies across builds (consolidation opportunities)
- **License Compliance**: Full inventory of open-source licenses across organization
- **Security Audit**: Foundation for CVE tracking and supply chain security
- **Vendor Management**: Centralized view of all software vendors and contracts

---

## Future Enhancement: Notion MCP Improvement

### Feature Request Opportunity

**Issue**: Notion MCP `notion-update-page` tool does not support relation property updates.

**Impact**: Requires manual UI actions for 258 dependencies across 5 builds (45-60 minutes).

**Proposed Enhancement**:
```typescript
// Desired Notion MCP capability
notion-update-page --page-id <build-id> --relation-property "Software/Tools Used" --add-relations <comma-separated-ids>
```

**Benefit**: Fully automated Wave 4 execution (45-60 minutes → 5 minutes).

**Feedback Channel**: Notion MCP GitHub repository or Notion developer community.

---

## Conclusion

While Wave 4 automation hit a Notion MCP limitation, this guide establishes a streamlined manual process to complete dependency linking. The bi-directional relation strategy reduces 258 individual actions to just 5 build-level updates, minimizing manual effort.

**Estimated Total Time**: 45-60 minutes (30-40 min entry creation + 15-20 min linking)

**Outcome**: Complete software cost tracking enabling portfolio-wide analysis, license compliance, and vendor management across the Brookside BI Innovation Nexus.

---

**Document Version**: 1.0
**Created**: October 22, 2025
**Author**: @repo-analyzer (automated) + Claude Code Agent (documentation)
**Status**: Ready for Execution
