# Resource Allocation & Capacity Planning

**Brookside BI Innovation Nexus - AMS Platform Initiative**

**Document Status**: Complete
**Generated**: 2025-10-28
**Version**: 1.0

---

## Executive Summary

Establish strategic workforce planning spanning 10-year lifecycle from lean 5-person startup team (Year 1, 60-80% allocation) through mid-size software company (Year 5, 50 people) to IPO-ready enterprise (Year 10, 300-400 people). This document provides granular resource allocation by phase, role, and work package to ensure sustainable team capacity and prevent burnout while achieving aggressive growth targets.

**Key Insights**:
- **Current Capacity Crisis**: Team currently OVER-ALLOCATED at 100-140 hours/week committed (Innovation Nexus + consulting)
- **AMS Platform Requirement**: 120-160 hours/week (60-80% allocation) for MVP success
- **Mitigation Required**: Archive 5-8 lower-priority builds, hire 2-3 contractors by Month 3
- **Hiring Velocity**: 5 people (Year 1) → 15 people (Year 2) → 35 people (Year 3) → 50 people (Year 5) → 400 people (Year 10)
- **Cost of Team**: $500K/year (Year 1) → $8M/year (Year 5) → $80M/year (Year 10, ~20% of revenue)

**Critical Hiring Milestones**:
- **Month 3**: Hire frontend contractor + AI engineer (unblock Markus from 80% → 60% allocation)
- **Month 9**: Hire full-time product designer + QA engineer (quality gates for launch)
- **Year 2 Q1**: Hire 5-person 501(c)(3) team (unblock Brad, Stephan from product work)
- **Year 3 Q1**: Hire 3-person security team (FedRAMP compliance requirement)
- **Year 5 Q1**: Hire VP Engineering (Markus transition to CTO, strategic role)

---

## Table of Contents

- [Current Team Capacity Analysis](#current-team-capacity-analysis)
- [Tier 1 (MVP) Resource Plan](#tier-1-mvp-resource-plan)
- [Tier 2 (Strategic) Resource Plan](#tier-2-strategic-resource-plan)
- [Tier 3 (Walled Garden) Resource Plan](#tier-3-walled-garden-resource-plan)
- [Organizational Structure by Phase](#organizational-structure-by-phase)
- [Hiring Plan & Timeline](#hiring-plan--timeline)
- [Compensation & Benefits Strategy](#compensation--benefits-strategy)
- [Capacity Management & Burnout Prevention](#capacity-management--burnout-prevention)
- [Skills Matrix & Training Plan](#skills-matrix--training-plan)
- [Contingency Planning](#contingency-planning)
- [Dependencies & References](#dependencies--references)

---

## Current Team Capacity Analysis

### Existing Team Members (Pre-AMS Platform)

| Name | Role | Weekly Hours Available | Current Commitments | Available for AMS |
|------|------|----------------------|---------------------|-------------------|
| **Markus Ahling** | Tech Lead, AI/ML, Infrastructure | 40 hours | Innovation Nexus (20h), Consulting (10h) | 10 hours (25%) ⚠️ |
| **Brad Wright** | Sales, Business Strategy, Finance | 40 hours | Sales pipeline (15h), Consulting (15h) | 10 hours (25%) ⚠️ |
| **Stephan Densby** | Operations, Research, Process Optimization | 40 hours | Research projects (12h), Consulting (8h) | 20 hours (50%) ⚠️ |
| **Alec Fielding** | DevOps, Security, Integrations | 40 hours | Infrastructure (15h), Consulting (5h) | 20 hours (50%) ⚠️ |
| **Mitch Bisbee** | Data Engineering, ML, QA | 40 hours | Data pipelines (10h), Consulting (10h) | 20 hours (50%) ⚠️ |

**Total Available Capacity**: 80 hours/week (40% of team capacity)
**AMS Platform Requirement** (from WBS): 120-160 hours/week (60-80% allocation)
**GAP**: 40-80 hours/week (**CRITICAL SHORTFALL**)

### Capacity Crisis Analysis

**Problem Statement**: Team is currently over-allocated. Total commitments (Innovation Nexus + consulting + AMS) exceed available hours by 20-60 hours/week.

**Immediate Actions Required** (Pre-MVP Kickoff):
1. **Archive Lower-Priority Innovation Nexus Builds** (Free up 20-30 hours/week):
   - Identify 5-8 builds with low viability scores (<60/100) or long timelines
   - Move to "Archived" status with learnings documented
   - Target: Markus 10h, Brad 5h, Stephan 5h, Alec 5h, Mitch 5h freed up

2. **Reduce Consulting Commitments** (Free up 10-20 hours/week):
   - Finish existing client projects, do not renew contracts
   - Transition clients to other consultants
   - Target: Brad 10h, Markus 5h, Stephan 5h freed up

3. **Hire Contractors Immediately** (Month 1-3, add 60-80 hours/week):
   - Frontend developer (60% allocation, 24 hours/week)
   - AI/ML engineer (40% allocation, 16 hours/week, Months 6-9)
   - Product designer (20% allocation, 8 hours/week, Months 2-4)

**Post-Mitigation Capacity**:
- **Internal Team**: 120 hours/week (60% allocation)
- **Contractors**: 48 hours/week (frontend + AI + designer)
- **Total**: 168 hours/week ✅ SUFFICIENT for MVP

---

## Tier 1 (MVP) Resource Plan

**Duration**: 12 months (Weeks 1-48)
**Team Size**: 5 internal + 2-3 contractors = 7-8 people
**Total Effort**: 7,000 hours (3.5 FTE-years)

### Phase 1: Project Initiation & Planning (Weeks 1-4)

| Work Package | Resource | Allocation % | Hours | Deliverables |
|--------------|----------|--------------|-------|--------------|
| WP 1.1.1 - Requirements | Brad (Lead) | 80% | 128h | Interview summaries, competitive analysis |
| | Markus | 40% | 64h | Technical requirements, SRS |
| | Stephan | 20% | 32h | Research synthesis |
| WP 1.1.2 - Architecture | Markus (Lead) | 100% | 160h | C4 diagrams, Prisma schema, API design |
| | Alec | 40% | 64h | Security architecture, threat model |
| | Mitch | 40% | 64h | Database ERD, migration plan |
| | External Designer | 100% | 160h | Figma designs, component library |
| WP 1.1.3 - Planning | Markus (Lead) | 60% | 96h | Sprint backlog, resource loading |
| | Brad | 60% | 96h | Budget, stakeholder comm plan |

**Phase 1 Total**: 864 hours (5.4 FTE-weeks)
**Peak Loading**: Week 3 (all team members active simultaneously)

---

### Phase 2: Foundation & Core Platform (Weeks 5-10)

| Work Package | Resource | Allocation % | Hours | Deliverables |
|--------------|----------|--------------|-------|--------------|
| WP 1.2.1 - Dev Environment | Alec (Lead) | 80% | 192h | CI/CD, Docker, code quality tools |
| | Markus | 20% | 48h | Review and guidance |
| WP 1.2.2 - Azure Infra | Alec (Lead) | 100% | 240h | App Service, SQL, Functions, Key Vault |
| | Mitch | 20% | 48h | Database setup, connection strings |
| WP 1.2.3 - Integrations | Markus (Lead) | 60% | 144h | Auth0, Stripe, SendGrid, Azure OpenAI |
| | Alec | 40% | 96h | Sentry, App Insights |
| WP 1.2.4 - Security | Alec (Lead) | 80% | 192h | SSL/TLS, pentest, SOC 2 kickoff |

**Phase 2 Total**: 960 hours (6 FTE-weeks)
**Peak Loading**: Week 7 (Alec at capacity, Markus supporting)
**Risk**: Alec is single point of failure for infrastructure; mitigation = detailed documentation

---

### Phase 3: Hierarchical Membership (Weeks 5-16, parallel with Phase 2)

| Work Package | Resource | Allocation % | Hours | Deliverables |
|--------------|----------|--------------|-------|--------------|
| WP 1.3.1 - Data Model | Markus (Lead) | 80% | 384h | Organization, Member, Content models |
| | Mitch | 60% | 288h | Prisma schema, migrations |
| WP 1.3.2 - Backend API | Markus (Lead) | 80% | 768h | CRUD APIs, content inheritance engine |
| | Mitch | 40% | 192h | Testing, optimization |
| WP 1.3.3 - Frontend UI | Frontend Dev (Lead) | 100% | 960h | All membership UI screens |
| | Markus | 20% | 96h | Code review, API integration support |
| WP 1.3.4 - Testing | Mitch (Lead) | 80% | 384h | Unit, integration, E2E tests |
| | Markus | 40% | 192h | Load testing, UAT coordination |
| | Brad | 40% | 192h | UAT with 3 beta associations |

**Phase 3 Total**: 3,456 hours (21.6 FTE-weeks, 12 weeks duration)
**Peak Loading**: Weeks 11-14 (Markus 80%, Mitch 60%, Frontend 100%, Brad 40% = 280% = 2.8 FTE)
**Critical Path**: WP 1.3.2 (backend API) is bottleneck; Markus at capacity

---

### Phase 4: Events & Conference Management (Weeks 11-18, parallel with 1.3)

| Work Package | Resource | Allocation % | Hours | Deliverables |
|--------------|----------|--------------|-------|--------------|
| WP 1.4.1 - Data Model | Mitch (Lead) | 80% | 256h | Event, Registration, Attendee models |
| WP 1.4.2 - Backend API | Mitch (Lead) | 80% | 512h | Event CRUD, registration, CEU tracking |
| | Markus | 40% | 128h | Stripe integration, code review |
| WP 1.4.3 - Frontend UI | Frontend Dev (Lead) | 60% | 384h | Event management, registration, check-in |
| | Mitch | 20% | 64h | API integration support |
| WP 1.4.4 - Testing | Mitch (Lead) | 60% | 192h | Jest tests, payment flow testing |
| | Brad | 40% | 128h | UAT with 2 event organizers |

**Phase 4 Total**: 1,664 hours (10.4 FTE-weeks, 8 weeks duration)
**Peak Loading**: Weeks 13-16 (Mitch 80%, Frontend 60%, Markus 40% = 180% = 1.8 FTE)
**Dependency**: Mitch must split time between Phase 3 (membership testing) and Phase 4 (events development)

---

### Phase 5: AI Command Palette (Weeks 13-22)

| Work Package | Resource | Allocation % | Hours | Deliverables |
|--------------|----------|--------------|-------|--------------|
| WP 1.5.1 - AI Engine | Markus (Lead) | 80% | 640h | Intent classification, entity extraction |
| | AI Engineer | 80% | 640h | NER model, fuzzy matching |
| WP 1.5.2 - Backend API | Markus (Lead) | 80% | 320h | Command API, history, permissions |
| WP 1.5.3 - Frontend UI | Frontend Dev (Lead) | 80% | 640h | Command palette overlay, NLP input |
| | Markus | 20% | 160h | API integration, WebSocket streaming |
| WP 1.5.4 - Training | Markus (Lead) | 60% | 240h | Prompt engineering, accuracy testing |
| | AI Engineer | 60% | 240h | Model optimization |
| | Brad | 40% | 160h | UAT with 10 power users |

**Phase 5 Total**: 3,040 hours (19 FTE-weeks, 10 weeks duration)
**Peak Loading**: Weeks 15-20 (Markus 80%, AI Eng 80%, Frontend 80% = 240% = 2.4 FTE)
**Critical Success Factor**: AI Engineer must have NLP/LLM experience (GPT-4 fine-tuning, prompt engineering)

---

### Phase 6: Testing, Launch & Stabilization (Weeks 19-26)

| Work Package | Resource | Allocation % | Hours | Deliverables |
|--------------|----------|--------------|-------|--------------|
| WP 1.6.1 - Integration Testing | Mitch (Lead) | 80% | 512h | Full system tests, security, performance |
| | Alec | 60% | 384h | Load testing, accessibility |
| WP 1.6.2 - Beta Onboarding | Brad (Lead) | 80% | 512h | 50 customer recruitment, training |
| | Stephan | 80% | 512h | Data migration, white-glove support |
| | Markus | 20% | 128h | Migration script development |
| | Mitch | 20% | 128h | Data validation |
| WP 1.6.3 - Marketing | Brad (Lead) | 60% | 384h | Website, videos, press release |
| | External Agency | 100% | 640h | Marketing site, collateral |
| WP 1.6.4 - Launch | Alec (Lead) | 100% | 160h | Production deployment, DNS, monitoring |
| | Full Team | 20% each | 640h | Smoke testing, launch support |
| WP 1.6.5 - Stabilization | Alec (Lead, On-Call) | 40% | 256h | 24/7 monitoring, hot-fixes |
| | Markus (On-Call) | 40% | 256h | P0/P1 bug fixes |
| | Full Team | 20% each | 640h | Bug triage, customer feedback |

**Phase 6 Total**: 5,152 hours (32.2 FTE-weeks, 8 weeks duration)
**Peak Loading**: Weeks 23-24 (Beta onboarding, all hands on deck: 6 people × 60% avg = 360% = 3.6 FTE)
**Burnout Risk**: HIGH during launch phase; mitigation = rotate on-call shifts, mandatory time off after launch

---

### Tier 1 Resource Summary

**Total Effort**: 15,136 hours (7.6 FTE-years)
**Duration**: 48 weeks (12 months)
**Average Team Size**: 7-8 people (5 internal + 2-3 contractors)
**Peak Loading**: Weeks 23-24 (launch phase, 3.6 FTE simultaneous)

**Cost Breakdown**:
- Internal team (5 people × 60% avg × $150K/year × 1 year) = $450K
- Frontend contractor (24 hours/week × 48 weeks × $100/hour) = $115K
- AI engineer contractor (16 hours/week × 16 weeks × $150/hour) = $38K
- Designer contractor (8 hours/week × 12 weeks × $80/hour) = $8K
- External agency (marketing site) = $50K
- **Total Labor Cost**: $661K (falls within $1.5M-2.5M MVP budget)

**Hiring Requirements**:
- **Month 1**: Frontend developer (contractor, 60%)
- **Month 2**: Product designer (contractor, 20%)
- **Month 6**: AI/ML engineer (contractor, 40%)
- **Month 9**: QA engineer (full-time hire, 100%) ← **CRITICAL** for quality before launch
- **Month 10**: Product manager (full-time hire, 100%) ← Relieve Brad from product work

---

## Tier 2 (Strategic) Resource Plan

**Duration**: 36 months (Years 2-5)
**Team Growth**: 10 people (Year 2) → 15 people (Year 3) → 35 people (Year 4) → 50 people (Year 5)
**Total Effort**: ~50,000 hours (25 FTE-years)

### Year 2: 501(c)(3) Expansion

**Objective**: Build 501(c)(3) features, expand to 3,000 customers, achieve $85M ARR

**Team Structure** (10-12 people):

| Department | Roles | Count | Allocation | Key Responsibilities |
|------------|-------|-------|------------|---------------------|
| **Engineering** | Backend Lead | 1 | 100% | 501(c)(3) API architecture |
| | Backend Engineer | 1 | 100% | Donor management, grant APIs |
| | Frontend Lead | 1 | 100% | UI component library |
| | Frontend Engineers | 2 | 100% | 501(c)(3) UI screens |
| | QA Engineer | 1 | 100% | Test automation, quality gates |
| **Product** | Product Manager | 1 | 100% | Roadmap, user stories, UAT |
| | Product Designer | 1 | 80% | UX research, design system |
| **Operations** | Customer Success Manager | 2 | 100% | Onboarding, support, retention |
| **Leadership** | Markus (CTO) | 1 | 60% | Architecture, code review, hiring |
| | Brad (CEO) | 1 | 40% | Sales, fundraising, strategy |

**Total**: 12 people (10 FTE equivalent)

**Resource Allocation by Work Package**:

| Work Package | Lead | Team | Duration | Effort (hours) |
|--------------|------|------|----------|---------------|
| WP 2.1.1 - Donor Management | Backend Lead | 2 BE, 2 FE, 1 QA, 1 PM | 3 months | 3,840h |
| WP 2.1.2 - Grant Management | Backend Lead | 2 BE, 3 FE, 1 QA, 1 PM | 4 months | 5,760h |
| WP 2.1.3 - Impact Measurement | Markus | 1 BE, 1 FE, 1 QA, 1 PM | 3 months | 2,880h |
| WP 2.1.4 - Volunteer Management | Backend Eng | 1 BE, 2 FE, 1 QA | 2 months | 1,920h |

**Year 2 Total**: 14,400 hours (7.2 FTE-years, 12 months)

**Hiring Plan** (Year 2):
- **Q1**: Hire backend lead, frontend lead (Month 13-14)
- **Q2**: Hire 2nd backend engineer, 2nd frontend engineer (Month 16-17)
- **Q3**: Hire 2nd CSM (Month 20)
- **Q4**: No new hires (focus on efficiency)

---

### Year 3: 501(c)(4), 501(c)(5), FedRAMP Kickoff

**Objective**: Build 501(c)(4) + 501(c)(5) features, start FedRAMP, 20,000 customers, $323M ARR

**Team Structure** (15-20 people):

| Department | Roles | Count | Allocation | Key Responsibilities |
|------------|-------|-------|------------|---------------------|
| **Engineering** | Engineering Manager | 1 | 100% | Team lead, architecture decisions |
| | Backend Engineers | 3 | 100% | 501(c)(4), 501(c)(5), compliance APIs |
| | Frontend Engineers | 3 | 100% | Political activity, labor union UIs |
| | QA Engineers | 2 | 100% | Regression testing, automation |
| | DevOps Engineer | 1 | 100% | Infrastructure scaling, monitoring |
| **Security** | CISO (Part-Time) | 1 | 50% | FedRAMP oversight, security strategy |
| | Security Engineer | 2 | 100% | FedRAMP controls, penetration testing |
| | Compliance Analyst | 1 | 100% | SSP documentation, audits |
| **Product** | Product Managers | 2 | 100% | 501(c)(4) and 501(c)(5) products |
| | Product Designers | 2 | 100% | Complex workflows, design system |
| **Operations** | CSMs | 3 | 100% | Support 20K customers (1:6,600 ratio) |
| **Leadership** | Markus (CTO) | 1 | 40% | Technical vision, FedRAMP sponsor |
| | Brad (CEO) | 1 | 30% | Sales expansion, Series A fundraise |

**Total**: 18 people (16.2 FTE equivalent)

**Hiring Plan** (Year 3):
- **Q1**: Hire CISO (part-time), 2 security engineers, 1 compliance analyst (FedRAMP team)
- **Q2**: Hire engineering manager, 3rd backend engineer, 3rd frontend engineer
- **Q3**: Hire 2nd QA engineer, DevOps engineer
- **Q4**: Hire 2nd product manager, 2nd designer, 3rd CSM

---

### Year 4: Advanced Analytics, Mobile Apps, FedRAMP Completion

**Objective**: Complete FedRAMP, launch mobile apps, advanced analytics, 50,000 customers, $750M ARR

**Team Structure** (25-35 people):

| Department | Roles | Count | Key Notes |
|------------|-------|-------|-----------|
| **Engineering** | Engineering Manager | 1 | Full-stack oversight |
| | Backend Engineers | 5 | Analytics APIs, mobile backend |
| | Frontend Engineers | 4 | Web app, dashboards |
| | Mobile Engineers (iOS/Android) | 4 | React Native mobile apps |
| | Data Engineers | 2 | ETL, data warehouse, ML pipelines |
| | QA Engineers | 3 | Web, mobile, API testing |
| | DevOps Engineers | 2 | Azure scaling, CI/CD, monitoring |
| **Security** | CISO (Full-Time) | 1 | FedRAMP ATO, continuous monitoring |
| | Security Engineers | 2 | Vulnerability mgmt, SOC |
| | Compliance Analyst | 1 | FedRAMP, StateRAMP, SOC 2 |
| **Product** | VP Product | 1 | Product strategy, roadmap |
| | Product Managers | 3 | Analytics, mobile, core platform |
| | Product Designers | 3 | Web, mobile, design system |
| **Government** | Gov Sales Lead | 1 | Federal, state, local sales |
| | Capture Managers | 2 | RFP response, proposal writing |
| | Solutions Architects | 2 | Pre-sales, technical demos |
| **Operations** | VP Customer Success | 1 | Customer success strategy |
| | CSMs | 8 | Support 50K customers (1:6,250 ratio) |
| **Leadership** | Markus (CTO) | 1 | 30% allocation (strategic, hiring) |
| | Brad (CEO) | 1 | 20% allocation (board, fundraising) |

**Total**: 34 people (33 FTE equivalent)

**Hiring Plan** (Year 4):
- **Q1**: Hire VP Product, 2 mobile engineers, 2 data engineers, 2 capture managers
- **Q2**: Hire 2 mobile engineers, 2nd DevOps engineer, 3rd QA engineer, gov sales lead
- **Q3**: Hire 2 solutions architects, VP Customer Success, 3 CSMs
- **Q4**: Hire 4th backend engineer, 5th frontend engineer, 2 CSMs, 3rd PM

---

### Year 5: Scale to 150,000 Customers, $1.19B ARR

**Team Structure** (40-50 people):

| Department | Count | Notes |
|------------|-------|-------|
| **Engineering** | 20 | Add backend, frontend, mobile, QA, DevOps |
| **Security/Compliance** | 4 | FedRAMP continuous monitoring |
| **Product** | 6 | 4 PMs, 2 designers |
| **Government** | 8 | 3 BDMs, 3 capture, 2 solutions architects |
| **Sales (Commercial)** | 10 | Inside sales, account executives |
| **Customer Success** | 15 | Support 150K customers (1:10K ratio) |
| **Marketing** | 5 | Content, demand gen, events |
| **Leadership** | 2 | Markus (CTO), Brad (CEO) |

**Total**: 50 people

**Hiring Plan** (Year 5):
- **Q1**: Hire 3 BDMs (commercial sales), 2 AEs, VP Engineering (Markus reports to board)
- **Q2**: Hire 4 backend engineers, 3 frontend engineers, 2 mobile engineers, 3 CSMs
- **Q3**: Hire VP Marketing, 3 marketing specialists, 2 CSMs, 2 QA engineers
- **Q4**: Hire 2 DevOps engineers, 1 PM, 1 designer, 2 CSMs

---

### Tier 2 Summary

**Team Growth**: 10 → 15 → 35 → 50 people over 4 years
**Total Effort**: ~50,000 hours (25 FTE-years, averaging 15 people × 36 months)
**Total Labor Cost**: $8M-12M (Years 2-5 cumulative)
- Year 2: $1.5M (10 people × $150K avg)
- Year 3: $2.5M (15 people × $167K avg)
- Year 4: $5M (30 people × $167K avg)
- Year 5: $8M (50 people × $160K avg)

**Hiring Velocity**: 5 new hires/year (Year 2) → 8/year (Year 3) → 12/year (Year 4) → 16/year (Year 5)

---

## Tier 3 (Walled Garden) Resource Plan

**Duration**: 60 months (Years 5-10)
**Team Growth**: 50 (Year 5) → 400 (Year 10)
**Total Effort**: ~200,000+ hours (100+ FTE-years)

### Year 6: Financial Services Platform

**Team Scale**: 60-80 people
**New Hires** (20-30 people):
- **FinTech Team** (15 people): Product, engineering, compliance specialists
- **Sales & CS** (10 people): Scale commercial and government teams
- **Leadership** (5 people): VP Engineering, VP Sales, VP CS, CFO, General Counsel

**Hiring Focus**:
- Fintech-specific roles (banking, payments, compliance)
- Expand engineering (20 → 30 people)
- Scale customer success (15 → 25 people)
- Build finance and legal teams (5 people)

---

### Year 7: Insurance Marketplace + Healthcare

**Team Scale**: 100-120 people
**New Hires** (40 people):
- **Insurance Team** (10 people): Product, partnerships, compliance
- **Healthcare Team** (10 people): Benefits administration, HIPAA compliance
- **Engineering** (10 people): Platform scaling, performance
- **Sales & Marketing** (10 people): Enterprise sales, brand marketing

---

### Year 8: Professional Networking + Data Intelligence

**Team Scale**: 140-180 people
**New Hires** (40-60 people):
- **Data Science Team** (15 people): ML engineers, data scientists, analysts
- **Networking Team** (10 people): Social features, content moderation
- **Engineering** (15 people): Backend, frontend, mobile
- **Sales & CS** (10 people): Global expansion, enterprise accounts

---

### Year 9: Platform Maturity + IPO Prep

**Team Scale**: 200-250 people
**New Hires** (60 people):
- **IPO Readiness Team** (10 people): Investor relations, financial reporting, SOX compliance
- **Engineering** (20 people): Platform stability, tech debt reduction
- **Sales & Marketing** (15 people): Brand awareness, enterprise land-and-expand
- **Customer Success** (15 people): Enterprise success managers, support

---

### Year 10: IPO-Ready Organization

**Team Scale**: 300-400 people
**New Hires** (100-150 people):
- **Public Company Functions** (30 people): FP&A, SEC reporting, legal
- **Engineering** (40 people): Global expansion, localization
- **Sales** (30 people): Regional sales teams (Americas, EMEA, APAC)
- **Operations** (50 people): IT, HR, finance, facilities, security

---

### Tier 3 Summary

**Team Growth**: 50 → 400 people over 5 years (8x increase)
**Annual Hiring Velocity**: 20 (Year 6) → 40 (Year 7) → 60 (Year 8) → 60 (Year 9) → 100+ (Year 10)
**Total Labor Cost**: $80M/year by Year 10 (~20% of $400M+ revenue)

**Organizational Maturity**:
- **Year 5-7**: Mid-size software company, VP-level leadership
- **Year 8-9**: Enterprise software company, C-suite expansion
- **Year 10**: Public company readiness, board governance, investor relations

---

## Organizational Structure by Phase

### Phase 1: Startup (Year 1-2) - Flat Structure

```
CEO (Brad)
├─ CTO (Markus)
│  ├─ Backend Engineers (2)
│  ├─ Frontend Engineers (2)
│  ├─ QA Engineer (1)
│  └─ DevOps (Alec)
├─ Product Manager (1)
└─ Customer Success (2)
```

**Characteristics**:
- Flat hierarchy, direct reporting to CEO/CTO
- Everyone wears multiple hats
- Rapid decision-making, minimal process
- All-hands meetings weekly

---

### Phase 2: Growth (Year 3-4) - Functional Teams

```
CEO (Brad)
├─ CTO (Markus)
│  ├─ Engineering Manager
│  │  ├─ Backend Team (5)
│  │  ├─ Frontend Team (4)
│  │  ├─ Mobile Team (4)
│  │  ├─ Data Team (2)
│  │  └─ QA Team (3)
│  ├─ DevOps Team (2)
│  └─ Security Team (CISO, 2 engineers, 1 analyst)
├─ VP Product
│  ├─ Product Managers (3)
│  └─ Designers (3)
├─ VP Government Sales
│  ├─ BDMs (3)
│  ├─ Capture Managers (3)
│  └─ Solutions Architects (2)
└─ VP Customer Success
   └─ CSMs (8)
```

**Characteristics**:
- Functional departments (Engineering, Product, Sales, CS)
- Middle management layer (Engineering Manager, VPs)
- Defined processes (sprint planning, code review, QA gates)
- Department-level OKRs

---

### Phase 3: Scale (Year 5-7) - Divisional Structure

```
CEO (Brad)
├─ CTO (Markus)
│  ├─ VP Engineering
│  │  ├─ Core Platform Team (20)
│  │  ├─ FinTech Team (15)
│  │  ├─ Mobile Team (8)
│  │  └─ Data & ML Team (10)
│  ├─ VP DevOps & Security (10)
│  └─ VP Product (15)
├─ Chief Revenue Officer (CRO)
│  ├─ VP Sales - Commercial (20)
│  ├─ VP Sales - Government (10)
│  └─ VP Marketing (10)
├─ VP Customer Success (30)
├─ CFO (Finance & Accounting, 10)
└─ General Counsel (Legal & Compliance, 5)
```

**Characteristics**:
- Divisional structure by product line (Core, FinTech, Gov)
- C-suite expansion (CTO, CRO, CFO, GC)
- Centralized functions (Finance, Legal, HR)
- Company-wide OKRs cascading to divisions

---

### Phase 4: Enterprise (Year 8-10) - Matrix Organization

```
Board of Directors
├─ CEO (Brad)
├─ COO (Operations & Efficiency)
├─ CTO (Markus)
│  ├─ VP Engineering - Platform
│  ├─ VP Engineering - Products
│  ├─ VP Engineering - FinTech
│  └─ VP Data & AI
├─ Chief Revenue Officer
│  ├─ VP Sales - Americas
│  ├─ VP Sales - EMEA
│  ├─ VP Sales - APAC
│  └─ VP Marketing
├─ Chief Customer Officer
│  ├─ VP Customer Success
│  └─ VP Support
├─ CFO
│  ├─ VP Finance
│  ├─ VP FP&A
│  └─ VP Investor Relations
├─ General Counsel
│  ├─ VP Legal
│  └─ VP Compliance
└─ CHRO (Human Resources, 20)
```

**Characteristics**:
- Matrix organization (product divisions × functional departments)
- C-suite with 8-10 executives
- Board of Directors, independent directors
- Public company governance (SOX, SEC filings)
- Global operations (Americas, EMEA, APAC)

---

## Hiring Plan & Timeline

### Hiring Velocity by Year

| Year | Starting Headcount | New Hires | Ending Headcount | Attrition (10%) | Net Growth |
|------|-------------------|-----------|------------------|-----------------|------------|
| **1** | 5 | 2 | 7 | 0 | +2 |
| **2** | 7 | 5 | 12 | 1 | +4 |
| **3** | 12 | 8 | 20 | 2 | +6 |
| **4** | 20 | 16 | 36 | 4 | +12 |
| **5** | 36 | 18 | 54 | 5 | +13 |
| **6** | 54 | 26 | 80 | 8 | +18 |
| **7** | 80 | 45 | 125 | 13 | +32 |
| **8** | 125 | 68 | 193 | 19 | +49 |
| **9** | 193 | 77 | 270 | 27 | +50 |
| **10** | 270 | 157 | 427 | 43 | +114 |

**Total New Hires** (Years 1-10): 422 people
**Ending Headcount**: 427 people (accounting for 10% annual attrition)

---

### Critical Hiring Milestones

**Year 1**:
- **Month 1**: Frontend developer (contractor)
- **Month 2**: Product designer (contractor)
- **Month 6**: AI/ML engineer (contractor)
- **Month 9**: QA engineer (full-time) ← **CRITICAL for launch quality**
- **Month 10**: Product manager (full-time)

**Year 2**:
- **Month 13-14**: Backend lead, frontend lead ← **CRITICAL for 501(c)(3) development**
- **Month 16-17**: 2nd backend engineer, 2nd frontend engineer
- **Month 20**: 2nd CSM

**Year 3**:
- **Month 25**: CISO (part-time), 2 security engineers, compliance analyst ← **CRITICAL for FedRAMP**
- **Month 27**: Engineering manager, 3rd backend engineer
- **Month 30**: 2nd QA engineer, DevOps engineer

**Year 4**:
- **Month 37**: VP Product, 2 mobile engineers, 2 data engineers ← **CRITICAL for mobile + analytics**
- **Month 40**: Gov sales lead, 2 capture managers
- **Month 43**: VP Customer Success, 3 CSMs

**Year 5**:
- **Month 49**: VP Engineering (Markus transition to CTO, strategic) ← **CRITICAL for scaling**
- **Month 52**: 3 BDMs (commercial sales), VP Marketing

---

## Compensation & Benefits Strategy

### Compensation Philosophy

**Market Positioning**: **60th percentile** for cash (base + bonus), **75th percentile** for equity (competitive for tech startups in Midwest/remote)

**Rationale**:
- Compete with coastal tech companies for remote talent
- Equity upside compensates for below-market cash (pre-funding)
- Post-Series A, increase cash to 75th percentile

---

### Compensation Bands by Role (Year 1-2, Pre-Series A)

| Role | Base Salary | Bonus/Commission | Equity (% of company) | Total Cash Comp |
|------|-------------|------------------|---------------------|----------------|
| **Engineering** | | | | |
| Junior Engineer (0-2 years) | $80K-100K | N/A | 0.10-0.25% | $80K-100K |
| Mid-Level Engineer (3-5 years) | $110K-140K | N/A | 0.15-0.40% | $110K-140K |
| Senior Engineer (6-10 years) | $140K-180K | N/A | 0.25-0.60% | $140K-180K |
| Staff Engineer (10+ years) | $180K-220K | N/A | 0.40-1.00% | $180K-220K |
| Engineering Manager | $160K-200K | 10-20% | 0.40-0.80% | $176K-240K |
| VP Engineering | $200K-250K | 20-30% | 0.80-1.50% | $240K-325K |
| **Product** | | | | |
| Product Manager | $120K-150K | 10-20% | 0.20-0.50% | $132K-180K |
| Senior PM | $150K-180K | 15-25% | 0.30-0.70% | $173K-225K |
| VP Product | $180K-220K | 20-30% | 0.60-1.20% | $216K-286K |
| **Sales** | | | | |
| BDM (Inside Sales) | $60K base | 50-100% OTE | 0.05-0.15% | $90K-120K |
| Account Executive | $90K base | 50-100% OTE | 0.10-0.25% | $135K-180K |
| VP Sales | $150K base | 50-100% OTE | 0.60-1.20% | $225K-300K |
| **Customer Success** | | | | |
| CSM | $60K-80K | 10-20% | 0.05-0.15% | $66K-96K |
| Senior CSM | $80K-100K | 15-25% | 0.10-0.25% | $92K-125K |
| VP Customer Success | $130K-160K | 20-30% | 0.40-0.80% | $156K-208K |
| **Leadership** | | | | |
| CTO (Markus) | $180K | 30-50% | 15-20% (founder) | $234K-270K |
| CEO (Brad) | $150K | 30-50% | 15-20% (founder) | $195K-225K |
| CFO (Year 5+) | $200K | 30-50% | 1.00-2.00% | $260K-300K |

**Note**: Equity percentages decrease as company matures (dilution from fundraising). Early hires receive higher equity grants.

---

### Benefits Package

**Year 1-2** (Lean Startup):
- Health insurance: 80% employer-paid (employee only), 50% (family)
- Dental/vision: 50% employer-paid
- 401(k): Available, no match (Years 1-2)
- PTO: Unlimited (honor system, minimum 15 days encouraged)
- Parental leave: 8 weeks (primary caregiver), 4 weeks (secondary)
- Remote work: 100% remote (no office)
- Equipment: $2,000 laptop/monitor budget
- Professional development: $1,000/year (conferences, courses)

**Year 3-5** (Growth Stage, Post-Series A):
- Health insurance: 90% employer-paid (employee), 70% (family)
- Dental/vision: 75% employer-paid
- 401(k): 4% match (vested immediately)
- PTO: Unlimited (minimum 20 days)
- Parental leave: 12 weeks (primary), 6 weeks (secondary)
- Remote/hybrid: Offices in 2-3 cities, remote still default
- Equipment: $3,000 budget
- Professional development: $2,500/year

**Year 6-10** (Scale-Up, Public Company Track):
- Health insurance: 100% employer-paid (employee), 80% (family)
- Dental/vision: 100% employer-paid
- 401(k): 6% match
- PTO: 25 days (capped, for SOX compliance)
- Parental leave: 16 weeks (primary), 8 weeks (secondary)
- Offices: Global offices (Americas, EMEA, APAC)
- Equipment: $4,000 budget
- Professional development: $5,000/year
- **New**: Stock options → RSUs (post-IPO)

---

## Capacity Management & Burnout Prevention

### Warning Signs of Over-Allocation

**Individual Level**:
- Working >50 hours/week consistently (3+ weeks)
- Missing deadlines or delivering low-quality work
- Declining code review participation
- Low engagement in standups/retros
- Increased sick days or PTO requests

**Team Level**:
- Velocity declining 20%+ sprint-over-sprint
- Bug count increasing
- Test coverage declining
- Technical debt accumulating
- High attrition (2+ departures within 3 months)

---

### Mitigation Strategies

**1. Capacity Buffer (20% Rule)**:
- Plan sprints at 80% capacity (not 100%)
- Reserve 20% for unplanned work (bugs, customer escalations, technical debt)
- If team consistently hits 100% velocity, increase capacity targets slowly

**2. On-Call Rotation**:
- No individual on-call more than 1 week/month
- On-call = reduced development work (50% allocation to dev, 50% to support)
- Compensate on-call with comp time (1 day off per week on-call) or $500 bonus

**3. Mandatory Time Off**:
- Minimum 15 days PTO required (enforce in Year 1-2)
- 1-week shutdown between Christmas and New Year's (company-wide)
- Post-launch stabilization: Mandatory 1 week off for core team after go-live

**4. Work-Life Balance Norms**:
- No meetings before 9 AM or after 5 PM (accommodate time zones)
- No Slack messages expected evenings/weekends (disable notifications)
- Encourage async communication (Loom videos, written docs)

**5. Regular Check-Ins**:
- Weekly 1-on-1s with direct reports (30 minutes)
- Monthly skip-level 1-on-1s (CTO → individual contributors)
- Quarterly engagement surveys (anonymous)

---

## Skills Matrix & Training Plan

### Critical Skills Gaps (Year 1)

| Skill | Current Team Proficiency | Required Level | Gap | Mitigation |
|-------|-------------------------|----------------|-----|------------|
| **React/Next.js** | Medium (Markus) | High | Medium | Hire frontend contractor, training for Mitch |
| **GraphQL** | Low (team) | High | High | GraphQL training (Markus, Mitch), external course |
| **Azure Infrastructure** | High (Alec) | High | None | No action needed |
| **AI/NLP (GPT-4)** | Medium (Markus) | High | Medium | Hire AI engineer, OpenAI workshops |
| **Security (FedRAMP)** | Low (team) | High | High | Hire CISO (Year 3), FedRAMP consultant |
| **Sales (B2B SaaS)** | Low (Brad) | High | High | Sales training (MEDDIC, Challenger), hire AEs (Year 3) |

---

### Training Programs

**Year 1-2** (Technical Skills):
- **GraphQL Fundamentals** (Markus, Mitch, new hires) - 1 week, online course
- **Azure Architecture** (Markus, Alec, new engineers) - Microsoft Learn, AZ-305 cert
- **React/Next.js** (Mitch, backend engineers) - Frontend Masters, 2 weeks
- **Security Best Practices** (All engineers) - OWASP Top 10, secure coding

**Year 3-4** (Leadership & Process):
- **Engineering Management** (New EMs) - Manager bootcamp (Reforge, FirstRound)
- **Product Management** (PMs) - Product School, roadmap planning
- **Sales Methodology** (Sales team) - MEDDIC, Sandler, Challenger training

**Year 5+** (Executive Development):
- **Executive Leadership** (VPs, C-suite) - Executive coaching, Stanford LEAD program
- **Public Company Readiness** (CFO, GC, CEO) - IPO preparation courses

---

## Contingency Planning

### Scenario 1: Key Person Departure

**Risk**: Markus (CTO) departs during MVP development

**Impact**: CRITICAL - Markus is 80% of MVP development, no immediate replacement

**Mitigation**:
1. **Immediate**: Alec steps up as interim tech lead (has 50% context)
2. **Week 1-2**: Hire senior architect contractor (emergency hire, $200/hour)
3. **Week 4**: Recruit permanent CTO replacement (3-6 month process)
4. **Extend Timeline**: Add 8-12 weeks to MVP timeline

**Prevention**:
- Vesting schedule (4-year vest, 1-year cliff) retains key people
- Document all architecture decisions in ADRs
- Cross-train Alec and Mitch on critical components

---

### Scenario 2: Slow Hiring (Cannot Fill Roles)

**Risk**: Cannot hire frontend contractor in Month 1 (competitive market)

**Impact**: HIGH - Markus stuck at 80% allocation, cannot scale

**Mitigation**:
1. **Week 1-2**: Expand search to 3 agencies/platforms (Toptal, Upwork, Gun.io)
2. **Week 3**: Increase hourly rate 20% ($100 → $120/hour)
3. **Week 4**: Consider offshore contractors (Eastern Europe, Latin America)
4. **Extend Timeline**: Add 2-4 weeks to frontend development

**Prevention**:
- Start hiring 3 months before needed (not 1 month)
- Build talent pipeline continuously (networking, referrals)
- Maintain relationships with contractors/agencies

---

### Scenario 3: Budget Shortfall (Cannot Afford Hires)

**Risk**: MVP costs exceed budget, cannot hire Year 2 team

**Impact**: HIGH - Cannot build 501(c)(3) features, miss $85M ARR target

**Mitigation**:
1. **Immediate**: Cut non-essential features (defer events management to post-MVP)
2. **Month 1-2**: Accelerate fundraising (angel round or bridge loan)
3. **Month 3**: Negotiate contractor rates down, or reduce hours (60% → 40%)
4. **Revenue Focus**: Prioritize high-value customers, increase pricing 10-20%

**Prevention**:
- Build 30% contingency into MVP budget ($1.5M → $2M target)
- Secure Series A funding commitment before Year 2 hiring spree

---

## Dependencies & References

**Required Before Hiring Execution**:
- [MVP-PLAN.md](./MVP-PLAN.md) - Detailed feature specs inform role requirements
- [WBS-COMPLETE.md](./WBS-COMPLETE.md) - Task breakdown drives resource allocation
- [VIABILITY-ASSESSMENT.md](./VIABILITY-ASSESSMENT.md) - Team capacity (5/10) scored as risk
- [RISK-REGISTER.md](./RISK-REGISTER.md) - Risk R4 (Team Capacity & Capability) mitigation

**Related Documents**:
- [PHASED-INVESTMENT.md](./PHASED-INVESTMENT.md) - Labor costs aligned to investment phases
- [FUNDING-STRATEGY.md](./FUNDING-STRATEGY.md) - Fundraising timeline aligned to hiring needs
- [TEAM-STRUCTURE.md](.claude/docs/team-structure.md) - Current Innovation Nexus team structure

**External Resources**:
- **Compensation Data**: Pave, Option Impact, Carta Total Comp
- **Hiring Platforms**: LinkedIn, AngelList, Toptal, Gun.io, Upwork
- **Training**: Reforge, Product School, Frontend Masters, Microsoft Learn
- **Management**: Manager bootcamps, FirstRound Review, Lenny's Newsletter

---

**Document Status**: Complete | Wave 3 (2 of 4) | Ready for Review
**Next**: [PHASED-INVESTMENT.md](./PHASED-INVESTMENT.md), [FUNDING-STRATEGY.md](./FUNDING-STRATEGY.md)

---

*Brookside BI Innovation Nexus - Where Ideas Become Examples, and Examples Become Knowledge.*
