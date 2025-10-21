# Project Status Dashboard

Comprehensive project health assessment, phase tracking, and intelligent next-step planning for the RealmWorks 20-phase roadmap.

## Purpose

Provides real-time visibility into project health across all dimensions: phase completion, technical debt, resource allocation, sprint velocity, dependency health, and risk management. Generates AI-powered recommendations for next sprint planning based on current status, team capacity, and strategic priorities.

## Multi-Agent Coordination Strategy

Uses **strategic analysis pattern** combining project management analytics, codebase health assessment, dependency analysis, and predictive planning.

### Status Dashboard Architecture
```
┌──────────────────────────────────────────────────┐
│       Project Status Orchestrator                 │
│       (master-strategist)                         │
└────────────┬─────────────────────────────────────┘
             │
    ┌────────┼────────┬────────┬────────┬─────────┐
    ▼        ▼        ▼        ▼        ▼         ▼
  Phase    Sprint   Tech    Depend   Risk    Resource
  Track    Metrics  Debt    Health   Assess  Alloc
```

## Execution Flow

### Phase 1: Phase Completion Analysis (0-15 mins)
1. **phase-tracker** - Analyze 20-phase roadmap completion
2. **milestone-validator** - Validate phase success criteria
3. **dependency-mapper** - Check inter-phase dependencies
4. **blocke-identifier** - Identify phase blockers
5. **completion-forecaster** - Estimate phase completion dates

**Data Sources**:
- [.claude/context/project-phases/00-phase-index.md](.claude/context/project-phases/00-phase-index.md)
- [.claude/context/project-phases/implementation-overview.md](.claude/context/project-phases/implementation-overview.md)
- All 12 phase documentation files

### Phase 2: Git Repository Analysis (15-30 mins)
6. **git-analyzer** - Analyze git status, branches, commits
7. **pr-monitor** - Review open PRs and review status
8. **commit-analyzer** - Analyze commit frequency and quality
9. **branch-health** - Check branch health and merge conflicts
10. **contribution-metrics** - Team contribution analysis

**Metrics**:
- Active branches and PRs
- Merge conflicts
- Commit frequency (daily/weekly)
- Code review velocity
- Branch staleness

### Phase 3: Sprint Velocity & Burndown (30-45 mins)
11. **velocity-calculator** - Calculate sprint velocity
12. **burndown-analyzer** - Analyze sprint burndown
13. **capacity-planner** - Team capacity analysis
14. **scope-tracker** - Sprint scope vs. completion
15. **impediment-detector** - Identify sprint impediments

**Metrics**:
- Story points completed vs. committed
- Sprint burndown trend
- Team capacity (hours available)
- Velocity trend (last 3 sprints)
- Scope creep detection

### Phase 4: Technical Debt Assessment (45-65 mins)
16. **debt-scanner** - Scan codebase for technical debt
17. **code-quality-analyzer** - Analyze code quality metrics
18. **test-coverage-analyzer** - Test coverage analysis
19. **documentation-gap-finder** - Documentation completeness
20. **refactoring-opportunity-finder** - Refactoring recommendations

**Metrics**:
- Code smells and anti-patterns
- Test coverage percentage
- Documentation coverage
- TODO/FIXME count
- Code duplication percentage

### Phase 5: Dependency Health Check (65-85 mins)
21. **dependency-analyzer** - Analyze all dependencies
22. **vulnerability-scanner** - Security vulnerability scan
23. **outdated-package-detector** - Outdated dependency detection
24. **license-compliance-checker** - License compliance
25. **breaking-change-detector** - Breaking change analysis

**Metrics**:
- Outdated dependencies count
- Critical vulnerabilities
- License compliance status
- Dependency tree depth
- Update availability

### Phase 6: Resource Allocation Review (85-105 mins)
26. **resource-mapper** - Map agent allocation
27. **utilization-analyzer** - Agent utilization metrics
28. **bottleneck-detector** - Resource bottleneck identification
29. **capacity-forecaster** - Future capacity needs
30. **cost-analyzer** - Resource cost analysis

**Metrics**:
- Agent utilization (%)
- Compute resource usage
- Cost per sprint
- Idle resource waste
- Scaling recommendations

### Phase 7: Risk Dashboard (105-125 mins)
31. **risk-scanner** - Scan Phase 1 risk register
32. **active-risk-tracker** - Track active risks (R001-R004)
33. **mitigation-validator** - Validate mitigation effectiveness
34. **risk-forecaster** - Predict emerging risks
35. **impact-analyzer** - Risk impact assessment

**Risk Categories** (from Phase 1):
- R001: Security & Compliance Risks
- R002: Technical & Architectural Risks
- R003: Operational & Performance Risks
- R004: Business & Organizational Risks

### Phase 8: Next Sprint Planning (125-155 mins)
36. **priority-ranker** - Rank backlog by priority
37. **capacity-matcher** - Match work to team capacity
38. **dependency-sequencer** - Sequence tasks by dependencies
39. **risk-optimizer** - Optimize for risk mitigation
40. **value-optimizer** - Optimize for business value
41. **ai-planner** - AI-powered sprint planning recommendations

**AI Recommendations**:
- Top 10 backlog items for next sprint
- Recommended team allocation
- Risk mitigation priorities
- Quick wins vs. strategic work balance
- Learning/innovation time allocation

## Agent Coordination Layers

### Strategic Analysis Layer
- **master-strategist**: Overall project orchestration
- **phase-tracker**: Phase completion tracking
- **risk-scanner**: Risk management
- **ai-planner**: Predictive planning

### Project Management Layer
- **velocity-calculator**: Sprint metrics
- **capacity-planner**: Resource planning
- **priority-ranker**: Backlog prioritization
- **dependency-sequencer**: Task sequencing

### Technical Health Layer
- **debt-scanner**: Technical debt
- **code-quality-analyzer**: Code quality
- **test-coverage-analyzer**: Test coverage
- **vulnerability-scanner**: Security health

### Repository Analysis Layer
- **git-analyzer**: Git metrics
- **pr-monitor**: PR health
- **commit-analyzer**: Commit quality
- **branch-health**: Branch management

## Usage Examples

### Example 1: Weekly Status Review
```
/project-status

Output:
=== RealmWorks Project Status Dashboard ===
Generated: 2025-10-07 14:30 UTC

📊 PHASE COMPLETION (20-Phase Roadmap)
✅ Phases 1-12: 100% Complete (Epic Narrative Documentation)
🚧 Phase 13 (Enhancement Wave 1): 0% - Not Started
📅 Estimated Phase 13 Start: 2025-10-15
⚠️  Blocker: Phase 12 ML model validation pending

🔀 GIT STATUS
Active Branches: 5 (main + 4 feature branches)
Open PRs: 3 (2 awaiting review, 1 in review)
Merge Conflicts: 1 (feature/tavern-ui vs. main)
Recent Commits: 47 (last 7 days)
Contributors: 3 active

📈 SPRINT VELOCITY
Current Sprint: Sprint 24 (Oct 1-14)
Velocity: 42 story points (target: 45)
Burndown: On track (3 days remaining, 8 points)
Capacity: 85% utilized (120h available, 102h allocated)
Impediments: None

🔧 TECHNICAL DEBT
Code Quality Score: 87/100 (Good)
Test Coverage: 92% (Target: 90%) ✅
TODO/FIXME: 23 items (5 critical, 18 minor)
Code Duplication: 3.2% (Target: <5%) ✅
Documentation: 78% coverage (needs improvement)

📦 DEPENDENCY HEALTH
Total Dependencies: 487 (npm: 423, pip: 64)
Outdated: 12 minor, 3 major
Vulnerabilities: 0 critical, 2 moderate (non-blocking)
License Compliance: 100% ✅

⚠️  RISK DASHBOARD
Active Risks: 2 of 15
- R002-T03 (MEDIUM): Database migration complexity
- R003-O01 (LOW): Redis memory pressure (monitor)
Mitigations: On track

💡 NEXT SPRINT RECOMMENDATIONS
Top Priorities:
1. Resolve merge conflict in tavern-ui (2h) - BLOCKER
2. Complete Phase 12 ML model validation (13 points)
3. Address 5 critical TODOs (8 points)
4. Begin Phase 13 planning (5 points)
5. Update documentation (8 points)

Recommended Capacity: 42 points
Risk Mitigation Focus: Database migration prep
Innovation Time: 20% (1 day for R&D/learning)
```

### Example 2: Monthly Strategic Review
```
/project-status --scope=monthly --detail=strategic

Output includes:
- 3-month velocity trend
- Phase completion forecast
- Resource utilization patterns
- Cost trend analysis
- Technical debt accumulation rate
- Strategic alignment assessment
```

### Example 3: Pre-Planning Meeting
```
/project-status --focus=planning --next-sprint

Output:
- AI-generated sprint backlog (ranked by priority)
- Team capacity breakdown by role
- Dependency graph for backlog items
- Risk-adjusted timeline
- Quick wins vs. strategic initiatives balance
```

### Example 4: Executive Summary
```
/project-status --format=executive --stakeholder=leadership

Output:
- High-level KPIs (phase completion, velocity, quality)
- Budget vs. actual (resource costs)
- Risk summary (top 3 risks)
- Timeline forecast (phase completion dates)
- Business value delivered (features shipped)
```

## Expected Outputs

### 1. Phase Completion Dashboard
```
=== 20-PHASE ROADMAP STATUS ===

✅ COMPLETED (12 phases - 60%)
Phase 1: Program Mobilization ............................ 100%
Phase 2: RPG Design ..................................... 100%
Phase 3: Architecture & Schemas ......................... 100%
...
Phase 12: Arcane Intelligence & Prophetic Insights ...... 100%

🚧 IN PROGRESS (0 phases)
(None - ready to start Phase 13)

📅 PLANNED (8 phases - 40%)
Phase 13: Enhancement Wave 1 (Advanced RPG) .............. 0%
  Estimated Start: 2025-10-15
  Estimated Duration: 8 weeks
  Dependencies: Phase 12 validation ✅
  Blockers: None

Phase 14-20: (Details collapsed)

📊 OVERALL COMPLETION: 60% (12 of 20 phases)
🎯 ON TRACK for Q1 2026 completion
```

### 2. Git Repository Health
```
=== GIT REPOSITORY METRICS ===

📁 Branches
  main ................................................ 2,347 commits
  feature/tavern-enhancements ......................... 23 commits (3d old)
  feature/quest-orchestrator-v2 ....................... 15 commits (1d old)
  feature/xp-balancing ................................ 8 commits (5d old)
  bugfix/auth-token-refresh ........................... 4 commits (2d old)

🔀 Pull Requests
  #42: Quest Orchestrator v2 .......................... In Review (2 approvals needed)
  #41: Tavern UI Enhancements ......................... Awaiting Review
  #40: Auth Token Refresh Fix ......................... Merge Conflict ⚠️

📊 Commit Metrics (Last 30 Days)
  Total Commits: 187
  Daily Average: 6.2 commits
  Contributors: 4 (MarkusAhling: 65%, Agent-Bot: 25%, Others: 10%)
  Commit Quality: 92/100 (good messages, atomic commits)

⚠️  Issues
  - feature/tavern-enhancements has merge conflict with main
  - feature/xp-balancing is 5 days old (stale)
  - PR #40 needs conflict resolution
```

### 3. Sprint Metrics
```
=== SPRINT 24 STATUS (Oct 1-14) ===

📈 Velocity Trend
  Sprint 22: 38 points
  Sprint 23: 45 points
  Sprint 24: 42 points (projected) ← Current
  Avg Velocity: 41.7 points

🔥 Burndown
  Day 1: 45 points remaining
  Day 7: 18 points remaining
  Day 11: 8 points remaining (current)
  Day 14: 0 points (target) ✅ ON TRACK

👥 Team Capacity
  Total: 120 hours (3 devs × 40h)
  Allocated: 102 hours (85%)
  Available: 18 hours (buffer)
  Meetings: 12 hours
  Focus Time: 90 hours

✅ Completed (37 points)
  - Implement Quest Orchestrator v2 (13 points)
  - Add XP balancing algorithm (8 points)
  - Tavern search optimization (8 points)
  - Fix auth token refresh (5 points)
  - Documentation updates (3 points)

🚧 In Progress (5 points)
  - Buff Manager v2 (5 points) - 80% complete

📋 Remaining (3 points)
  - Update API documentation (3 points)
```

### 4. Technical Debt Report
```
=== TECHNICAL DEBT ASSESSMENT ===

📊 Overall Health: 87/100 (Good) ✅

Code Quality
  Complexity: Low (avg cyclomatic complexity: 4.2)
  Maintainability Index: 82/100
  Code Smells: 15 (3 critical, 12 minor)
  Duplication: 3.2% (Target: <5%) ✅

Test Coverage
  Overall: 92% (Target: 90%) ✅
  Unit Tests: 95%
  Integration Tests: 88%
  E2E Tests: 85%
  Uncovered: src/services/buff-manager/utils.ts (45%)

Documentation
  Code Comments: 82%
  API Documentation: 95% (OpenAPI complete)
  README Files: 100%
  Architecture Docs: 78% ⚠️ (needs update)
  Inline TODOs: 23 items

🔴 CRITICAL ITEMS (5)
  1. src/api/routes/quest.routes.ts:142 - SQL injection risk
  2. src/services/xp-engine/allocator.ts:89 - Race condition
  3. src/config/secrets.ts:23 - Hardcoded API key (dev only)
  4. packages/api-client/src/mock.ts:156 - Deprecated API usage
  5. src/services/quest-orchestrator/processor.ts:234 - Memory leak potential

🟡 REFACTORING OPPORTUNITIES (8)
  - Extract common validation logic (4 files)
  - Consolidate error handling (quest-orchestrator)
  - Simplify XP calculation (reduce complexity from 12 to 6)
  - Remove dead code in buff-manager (234 LOC)
```

### 5. Dependency Health
```
=== DEPENDENCY HEALTH CHECK ===

📦 Summary
  Total: 487 packages (npm: 423, pip: 64)
  Up-to-date: 472 (97%)
  Outdated: 15 (3%)
  Vulnerable: 2 moderate (non-blocking)

🔴 Security Vulnerabilities (2)
  - axios@0.21.1 → 0.21.4 (MODERATE: SSRF)
  - ws@7.4.0 → 7.4.6 (MODERATE: DoS)
  Recommendation: Update immediately (non-breaking)

⚠️  Outdated Major Versions (3)
  - react@17.0.2 → 18.2.0 (MAJOR)
    Breaking Changes: Yes (Concurrent rendering)
    Effort: 2-3 days (testing required)

  - typescript@4.9.5 → 5.2.2 (MAJOR)
    Breaking Changes: Minor (strict mode improvements)
    Effort: 1 day

  - Next.js@12.3.1 → 13.5.1 (MAJOR)
    Breaking Changes: Yes (App Router, Server Components)
    Effort: 5-7 days (significant refactor)

🟡 Outdated Minor Versions (12)
  - @types/node@18.11.9 → 18.18.5
  - eslint@8.45.0 → 8.51.0
  - jest@29.5.0 → 29.7.0
  ... (9 more)

✅ License Compliance
  MIT: 421 (86%)
  Apache-2.0: 48 (10%)
  BSD-3-Clause: 18 (4%)
  No Issues: All licenses compatible ✅
```

### 6. Risk Dashboard
```
=== ACTIVE RISK REGISTER ===

🔴 HIGH PRIORITY (0)
(None - all high-priority risks mitigated)

🟡 MEDIUM PRIORITY (2)

R002-T03: Database Migration Complexity
  Phase: Phase 13 (Enhancement Wave 1)
  Impact: Schedule delay (2-4 weeks)
  Probability: 40%
  Mitigation: Migration testing in progress
  Status: MONITORING
  Last Updated: 2025-10-05
  Owner: database-architect agent

R003-O01: Redis Memory Pressure
  Phase: Current (Production)
  Impact: Performance degradation
  Probability: 25%
  Mitigation: Eviction policy tuned, monitoring active
  Status: MONITORING
  Last Updated: 2025-10-03
  Owner: performance-optimizer agent

🟢 LOW PRIORITY (13)
(Collapsed - all under control)

📊 Risk Trend
  Week 1: 18 active risks
  Week 2: 15 active risks
  Week 3: 12 active risks
  Week 4: 15 active risks ↗ (3 new, low-priority)

✅ Recently Mitigated (3)
  - R001-S02: GDPR compliance gap (Resolved: 2025-10-01)
  - R002-T01: API versioning strategy (Resolved: 2025-09-28)
  - R003-O05: Backup failure (Resolved: 2025-09-25)
```

### 7. AI Planning Recommendations
```
=== NEXT SPRINT PLANNING (Sprint 25: Oct 15-28) ===

🎯 RECOMMENDED SPRINT GOAL
"Complete Phase 12 validation and initiate Phase 13 with enhanced RPG mechanics"

📊 CAPACITY ANALYSIS
  Team Capacity: 120 hours
  Recommended Load: 42 story points (based on velocity: 41.7)
  Buffer: 10% (4 points) for unknowns
  Total Sprint Commitment: 38 points

🏆 TOP PRIORITIES (Ranked by AI)

1. [BLOCKER] Resolve merge conflicts (2 hours) ⚠️
   Why: Blocking PR #40, critical path item
   Agent: conflict-resolver
   Risk: None
   Value: Unblocks 2 other stories

2. Phase 12 ML Model Validation (13 points) 🔴
   Why: Prerequisite for Phase 13 kickoff
   Agent: test-engineer, performance-optimizer
   Risk: MEDIUM (model accuracy unknown)
   Value: HIGH (gates entire Phase 13)

3. Critical Technical Debt (8 points) 🔧
   Items: SQL injection fix, race condition, memory leak
   Why: Security and stability risks
   Agent: security-specialist, senior-reviewer
   Risk: LOW (well-understood fixes)
   Value: MEDIUM (reduces production risk)

4. Phase 13 Planning & Design (5 points) 📋
   Why: Prepare for next phase kickoff
   Agent: master-strategist, architect-supreme
   Risk: LOW
   Value: HIGH (strategic alignment)

5. Documentation Updates (8 points) 📝
   Why: Architecture docs at 78% (target: 95%)
   Agent: documentation-expert
   Risk: NONE
   Value: MEDIUM (team enablement)

6. Quest Forge v1 Implementation (13 points) ✨
   Why: High-value Phase 13 deliverable
   Agent: code-generator-typescript, quest-orchestrator
   Risk: MEDIUM (new feature complexity)
   Value: HIGH (user-facing feature)

🎲 QUICK WINS (Optional - if capacity available)
  - Update outdated dependencies (2 points, 0 risk)
  - Remove dead code in buff-manager (1 point, 0 risk)
  - Add Storybook stories for Tavern components (3 points, low risk)

⚖️  BALANCED SPRINT COMPOSITION
  Bug Fixes: 8% (merge conflicts, critical debt)
  Feature Work: 67% (Phase 12 validation, Quest Forge)
  Technical Debt: 17% (security fixes, documentation)
  Innovation: 8% (Phase 13 planning)
  Total: 38 points ✅

🚨 RISKS & DEPENDENCIES
  - Phase 12 validation may uncover issues (add 2-day buffer)
  - Quest Forge depends on Quest Orchestrator v2 (in review)
  - Documentation updates may reveal architecture gaps

📅 SUGGESTED TIMELINE
  Week 1 (Oct 15-21): Blockers, Phase 12 validation, critical debt
  Week 2 (Oct 22-28): Quest Forge, documentation, Phase 13 planning
```

## Success Criteria

- ✅ Phase completion status accurate (validated against success criteria)
- ✅ Git metrics current (<5 min old)
- ✅ Sprint velocity calculated (last 3 sprints minimum)
- ✅ Technical debt quantified (actionable items identified)
- ✅ Dependency health assessed (security vulnerabilities flagged)
- ✅ Risk register reviewed (active risks identified)
- ✅ Resource allocation analyzed (utilization and waste identified)
- ✅ AI recommendations generated (top 5 priorities with rationale)
- ✅ Next sprint plan proposed (balanced composition)
- ✅ Blockers and dependencies identified
- ✅ Timeline forecast updated (phase completion estimates)

## Configuration Options

### Scope
- `--scope=daily` - Daily standup metrics (default)
- `--scope=weekly` - Weekly review metrics
- `--scope=monthly` - Monthly strategic review
- `--scope=quarterly` - Quarterly business review

### Detail Level
- `--detail=summary` - Executive summary only
- `--detail=standard` - Standard dashboard (default)
- `--detail=detailed` - Comprehensive analysis
- `--detail=strategic` - Strategic planning focus

### Focus Area
- `--focus=phases` - Phase completion focus
- `--focus=sprint` - Sprint metrics focus
- `--focus=debt` - Technical debt focus
- `--focus=planning` - Next sprint planning focus
- `--focus=risk` - Risk management focus

### Stakeholder View
- `--stakeholder=developers` - Developer metrics
- `--stakeholder=pm` - Project manager view
- `--stakeholder=leadership` - Executive view (default)

### Output Format
- `--format=markdown` - Markdown report (default)
- `--format=json` - JSON data export
- `--format=dashboard` - Interactive web dashboard
- `--format=email` - Email-friendly HTML

## Integration Points

### Data Sources
- **Phase Documentation**: `.claude/context/project-phases/*.md`
- **Git Repository**: Local git status, GitHub API (via MCP)
- **Project Files**: `package.json`, `requirements.txt`, `tsconfig.json`
- **Code Analysis**: ESLint, SonarQube, Test coverage reports
- **Dependency Analysis**: `npm audit`, `pip check`, Snyk
- **Risk Register**: `.claude/context/risk-register.md`

### Agent Integration
- **master-strategist**: Overall orchestration and AI planning
- **plan-decomposer**: Sprint planning and task sequencing
- **risk-assessor**: Risk analysis and mitigation tracking
- **database-architect**: Technical health assessment
- **security-specialist**: Vulnerability scanning
- **performance-optimizer**: Resource utilization analysis
- **documentation-expert**: Documentation coverage analysis

### MCP Server Integration
- **mcp__github**: PR status, branch health, contributor metrics
- **mcp__filesystem**: Codebase analysis, file metrics
- **mcp__cosmos-memory**: Historical sprint data, velocity trends
- **mcp__pinecone-vector**: Knowledge base for AI recommendations

## Notes

- **Daily Usage**: Run `/project-status` at start of day for quick health check
- **Weekly Review**: Use `--scope=weekly --detail=detailed` for retrospectives
- **Sprint Planning**: Use `--focus=planning` before planning meetings
- **Executive Updates**: Use `--stakeholder=leadership --format=email` for status emails
- **AI Recommendations**: Based on historical data, team capacity, and strategic priorities
- **Real-time Data**: Git metrics are real-time; dependency scans cached for 24h
- **Customization**: Add custom metrics via `.claude/config/status-metrics.yaml`
- **Historical Tracking**: Status snapshots stored in Cosmos DB for trend analysis

## Estimated Execution Time

- **Quick Check** (`--scope=daily`): 2-3 minutes
- **Standard Dashboard**: 5-8 minutes
- **Weekly Review** (`--scope=weekly`): 10-15 minutes
- **Strategic Planning** (`--detail=strategic`): 15-25 minutes
- **Full Analysis** (all dimensions): 25-35 minutes
