# Frame 1: Daily Operations Summary (Deck)

**Frame Type**: Deck (Executive Summary Slide Deck)
**Version**: 1.0.0
**Category**: Operations Reporting
**Target Users**: DSP Operations Managers, OTR Area Managers
**Frequency**: Daily (1x per day, typically end-of-shift)
**Estimated Time Savings**: 80-85% (30-45 min → 5-8 min)

---

## Problem Statement

**Current State**: DSP Operations Managers and OTR Area Managers spend 30-45 minutes daily compiling operational performance summaries from multiple systems (WST, Netradyne, AMZL dashboards, incident logs). This manual aggregation is:
- ❌ Time-consuming (30-45 min daily × 260 workdays = 130-195 hours/year per manager)
- ❌ Inconsistent (varying formats across managers)
- ❌ Error-prone (manual data entry from multiple sources)
- ❌ Delayed (often completed 2-4 hours after shift end)

**Pain Points**:
- Juggling 5-7 different systems to gather metrics
- Copying/pasting data into PowerPoint or email
- Forgetting to include critical incidents or exceptions
- Missing leadership deadlines for daily reporting
- No standardized format for cross-station comparisons

**User Quotes** (from user research):
> "I spend the last hour of my shift clicking through systems to build my daily report. By the time I send it, leadership has already moved on to the next issue." — DSP Operations Manager, 3 years experience

> "Every Area Manager formats their daily summary differently. When I review 10 stations, I can't compare apples to apples." — Regional Operations Director

---

## Proposed Solution: Daily Operations Summary Frame

**One-Click Workflow**: Generate a standardized 5-slide executive summary deck covering key performance metrics, incidents, route exceptions, and next-day priorities—ready to present in 5-8 minutes.

### Frame Structure (YAML Blueprint)

```yaml
frame: daily-operations-summary.v1
intent: "Summarize operational performance for leadership reporting"
structure:
  - slide: Executive Summary
    content:
      - Overall DCR (Delivered Customer Received) %
      - On-Time Delivery (OTD) %
      - Route completion rate
      - Safety incidents (count + severity)
      - Top 3 wins of the day
      - Top 3 challenges requiring action

  - slide: Performance Metrics
    content:
      - DA (Delivery Associate) performance distribution
      - Route drops and rescues (count + reasons)
      - ROBL (Received on Business Location) defects
      - Customer feedback summary (positive/negative themes)
      - Vehicle utilization and downtime

  - slide: Safety & Compliance
    content:
      - Safety incidents (near-misses, violations, injuries)
      - Netradyne alerts and driver coaching actions
      - Pre-DVCR and Post-DVCR completion rates
      - Uniform and badge compliance observations
      - Weather or route hazard impacts

  - slide: Operational Exceptions
    content:
      - RTS (Return-to-Station) volume and reasons
      - WST disputes submitted and status
      - Late route cancellations impact
      - EV charging issues or fleet problems
      - Staffing shortages or attendance concerns

  - slide: Next-Day Priorities
    content:
      - Route allocations and staffing plan
      - Carry-over action items from today
      - Anticipated challenges (weather, volume surge, training)
      - Resource needs or escalations required
      - Recognition opportunities for high performers

tone: concise, data-driven, action-oriented
format: PowerPoint slide deck (5 slides)
brand_voice: Brookside BI professional tone
output_delivery: Email attachment + Teams channel post
```

---

## User Workflow (One-Click Execution)

### Step 1: Frame Selection
**User Action**: Opens Power Automate template library → Selects "Daily Operations Summary"
**System Response**: Displays input form with data source connections

### Step 2: Input Specification
**Required Inputs**:
- Date range: [Auto-filled to "Today's shift"]
- Station ID: [Auto-detected from user profile or dropdown]
- Shift type: [Morning / Afternoon / Night]
- Manager name: [Auto-filled from Azure AD]

**Optional Inputs**:
- Include detailed DA performance breakdown? [Yes/No]
- Highlight specific routes or DAs? [Free text field]
- Add custom notes or context? [Free text area, max 500 chars]

**Data Source Connections** (automated via Power Automate):
- WST (Work Summary Tool) API
- AMZL Dashboard metrics export
- Netradyne alerts API
- Incident management system
- RTS tracking database
- Route planning system

### Step 3: AI Processing (Azure OpenAI GPT-4 Turbo)
**Duration**: 15-30 seconds
**System Prompt** (embedded in Frame):

```
You are an operations reporting assistant for Amazon Logistics (AMZL) delivery station operations.
Generate a concise, executive-ready 5-slide summary deck based on the operational data provided.

BRAND VOICE: Professional, data-driven, action-oriented (Brookside BI standards)
AUDIENCE: Station leadership, regional operations managers, executive stakeholders
FORMAT: PowerPoint-ready slide content (bullet points, not paragraphs)

For each slide:
1. Executive Summary: Highlight the most critical metrics and 3 wins + 3 challenges
2. Performance Metrics: Show trends (↑↓) vs. yesterday and weekly average
3. Safety & Compliance: Flag any RED items requiring immediate action
4. Operational Exceptions: Prioritize by impact (HIGH/MEDIUM/LOW)
5. Next-Day Priorities: Actionable items with owners assigned

CRITICAL RULES:
- Use percentages with 1 decimal place (e.g., 94.7% DCR)
- Flag metrics below target with ⚠️ symbol
- Highlight improvements with ✅ symbol
- Keep bullets to 8-10 words max (concise, scannable)
- Include specific numbers (not "many routes" but "12 routes")
- Identify root causes for exceptions (not just symptoms)
- Suggest corrective actions for each challenge
```

**Processing Steps**:
1. Query WST API for route performance data
2. Fetch Netradyne alerts for safety incidents
3. Aggregate RTS volume and reasons from tracking system
4. Retrieve incident reports from incident management system
5. Calculate performance trends (day-over-day, week-over-week)
6. Apply Frame structure to organize data into 5 slides
7. Generate slide content with brand voice and formatting
8. Insert data visualizations (simple charts for trends)

### Step 4: Output Review & Refinement
**System Response**: Displays slide preview in Teams or email
**User Options**:
- ✅ Approve and send (auto-distributes to leadership distribution list)
- ✏️ Edit specific slides (opens in PowerPoint for manual adjustments)
- 🔄 Regenerate with different focus (e.g., "emphasize safety incidents")
- 💾 Save as draft for later review

**Default Distribution** (if approved):
- Email to: [Station Manager, Regional Ops Manager, Business Coach]
- Post to: [Station Operations Teams channel]
- Archive to: [SharePoint Daily Reports library]

### Step 5: Feedback Collection
**Post-Execution Survey** (embedded in email):
- Rating: "How useful was this summary?" [1-5 stars]
- Time saved: "How much time did this save you?" [0-15 min | 15-30 min | 30-60 min | 60+ min]
- Accuracy: "Were all critical issues included?" [Yes / No → specify what's missing]
- Suggestions: "What would improve this Frame?" [Free text, optional]

---

## Technical Implementation

### Azure OpenAI Configuration
**Model**: GPT-4 Turbo (128K context)
**Deployment**: `gpt-4-turbo-2024-04-09`
**Temperature**: 0.3 (low variability for consistent reporting)
**Max Tokens**: 2,000 (sufficient for 5-slide content)
**System Prompt**: [See above]

### Power Automate Workflow
**Trigger**: Manual button click ("Generate Daily Summary")
**Actions**:
1. Collect user inputs (date, station, shift)
2. Query WST API (HTTP GET with auth token)
3. Query Netradyne API (HTTP GET)
4. Query incident management system (SQL query or API)
5. Aggregate data into structured JSON payload
6. Call Azure OpenAI API (HTTP POST with BYOK credentials)
7. Parse AI response and format as PowerPoint slides
8. Generate slide deck using Office 365 connector
9. Email slide deck to distribution list
10. Post summary to Teams channel
11. Archive to SharePoint
12. Log execution to Application Insights

**Error Handling**:
- If WST API fails → Retry 3x with exponential backoff → Notify user to input data manually
- If Azure OpenAI quota exceeded → Queue request for next available capacity → Notify user of delay
- If slide generation fails → Email raw data summary as fallback → Escalate to technical support

### Data Sources & Integrations
**Required API Connections**:
- WST API (Work Summary Tool) - Route performance data
- AMZL Dashboard API - Delivery metrics (DCR, OTD, exceptions)
- Netradyne API - Safety alerts and driver coaching events
- Incident Management System - Safety incidents and near-misses
- RTS Tracking Database - Undelivered package data
- Route Planning System - Next-day staffing and allocations

**Authentication**: Azure AD service principal with RBAC permissions
**Data Retention**: Input data stored 7 days, output slides archived indefinitely in SharePoint

---

## Cost Analysis

### Per-Execution Cost Breakdown
**Azure OpenAI (GPT-4 Turbo)**:
- Input tokens: ~3,000 tokens (API query responses + user context)
- Output tokens: ~1,500 tokens (5-slide deck content)
- Cost: $0.01/1K input tokens + $0.03/1K output tokens
- **Total AI cost per execution**: $0.03 + $0.045 = **$0.075**

**Power Automate**:
- HTTP requests: 6 API calls × $0.0001 = $0.0006
- Office 365 connector: $0.001 (slide generation)
- Email send: $0.0001
- **Total automation cost**: **$0.002**

**Application Insights**:
- Logging and telemetry: $0.001 per execution
- **Total monitoring cost**: **$0.001**

**Total Cost Per Execution**: **$0.078** (~$0.08)

### ROI Calculation

**Time Savings Per User**:
- **Before**: 30-45 min daily manual aggregation
- **After**: 5-8 min review and approval
- **Time Saved**: 25-37 min per execution (avg 31 min)

**Value Per Execution**:
- Manager hourly rate: $50/hr (loaded cost)
- Time saved: 31 min = 0.52 hours
- **Value per execution**: 0.52 hrs × $50/hr = **$26**

**ROI Per Execution**:
- Value: $26
- Cost: $0.08
- **ROI**: 325:1 (for every $1 spent, $325 in value delivered)

**Annual Impact (Per User)**:
- Executions per year: 260 workdays
- Total time saved: 31 min × 260 days = 8,060 min = **134 hours/year**
- Total value: $26 × 260 = **$6,760/year per user**
- Total cost: $0.08 × 260 = **$20.80/year per user**
- **Annual ROI**: 325:1

**Pilot Program (20 users, 4 weeks)**:
- Executions: 20 users × 20 workdays = 400 executions
- Total value: 400 × $26 = **$10,400**
- Total cost: 400 × $0.08 = **$32**
- Pilot ROI: 325:1

**Full Deployment (100 users, 1 year)**:
- Total value: 100 users × $6,760/year = **$676,000/year**
- Total cost: 100 users × $20.80/year = **$2,080/year**
- Full deployment ROI: 325:1

---

## Success Metrics

### Adoption Metrics
**Target**: ≥ 70% of DSP Operations Managers and OTR Area Managers use Frame ≥ 3 days/week

**Measurement**:
- Daily active users (DAU) tracked via Application Insights
- Execution frequency per user (weekly average)
- Week-over-week adoption trend (target: +10% weekly growth during pilot)

### Performance Metrics
**Target**: ≥ 90% successful executions (no errors, complete slide decks generated)

**Measurement**:
- Power Automate run history (success vs. failure rate)
- Average processing time (target: <30 seconds end-to-end)
- Error types and frequency (API failures, AI timeouts, data quality issues)

### Quality Metrics
**Target**: ≥ 4/5 average user satisfaction rating

**Measurement**:
- Post-execution survey responses (1-5 star rating)
- Feedback themes (what users like, what needs improvement)
- Manual edit rate (how often users edit slides before sending)
- Accuracy validation (spot-check 10% of summaries against source data)

### Business Impact Metrics
**Target**: ≥ $500/user/year measured productivity gains

**Measurement**:
- Self-reported time savings (post-execution survey)
- Calculated value: (Time saved in hours) × ($50/hr manager rate)
- Trend analysis: Compare time saved Week 1 vs. Week 4 (should stabilize)

### Cost Metrics
**Target**: ≤ $0.10/execution average Azure OpenAI cost

**Measurement**:
- Application Insights cost tracking (AI API calls)
- Token usage per execution (input + output)
- Monthly cost projection vs. budget

---

## Pilot Deployment Plan

### Week 1: Setup & Onboarding (5 pilot users)
**Participants**: 3 DSP Ops Managers + 2 OTR Area Managers (hand-picked early adopters)

**Activities**:
- Power Automate flow deployment to pilot users
- API connection configuration (WST, Netradyne, incident system)
- 15-minute training session: "How to generate your first Daily Operations Summary"
- Provide quick reference guide (1-page cheat sheet)

**Success Criteria**:
- All 5 users complete ≥ 1 successful execution
- No critical technical blockers identified
- Positive initial feedback (≥ 3/5 stars)

### Week 2: Refinement & Expansion (10 pilot users)
**New Participants**: Add 5 more DSP Ops Managers

**Activities**:
- Incorporate Week 1 feedback (adjust slide content, fix data issues)
- Weekly office hours (Thursdays 2-3 PM) for questions and troubleshooting
- Monitor adoption metrics (target: ≥ 3 executions/week per user)

**Success Criteria**:
- ≥ 70% of pilot users executing ≥ 3 days/week
- Average satisfaction rating ≥ 4/5
- Technical issues resolved within 24 hours

### Week 3: Optimization & Validation (15 pilot users)
**New Participants**: Add 5 OTR Area Managers

**Activities**:
- A/B test variations (e.g., 5-slide vs. 3-slide deck)
- Validate time savings claims with time-tracking data
- Document best practices and user tips
- Prepare for full rollout decision

**Success Criteria**:
- Measured time savings ≥ 25 min/execution
- ≥ 85% successful execution rate (minimal errors)
- Positive feedback from regional leadership

### Week 4: Go/No-Go Decision (20 pilot users)
**Final Evaluation**:
- Review all success metrics against targets
- Calculate actual ROI (time saved × manager rate)
- Present pilot results to leadership
- Decision: Full rollout vs. iterate vs. discontinue

**Go Decision Criteria** (must achieve 4 out of 5):
- ✅ ≥ 70% adoption rate (users executing ≥ 3 days/week)
- ✅ ≥ 4/5 average satisfaction rating
- ✅ ≥ $500/user measured value over 4 weeks
- ✅ ≤ $0.10/execution average cost
- ✅ ≥ 90% successful execution rate

---

## User Training & Support

### Training Materials
**15-Minute Video Tutorial**: "Generating Your First Daily Operations Summary"
- Overview of Frame capabilities (1 min)
- Step-by-step walkthrough of input form (3 min)
- Demo of AI processing and slide preview (2 min)
- How to review, edit, and approve slides (4 min)
- Troubleshooting common issues (3 min)
- Q&A and next steps (2 min)

**Quick Reference Guide** (1-page PDF):
- Frame overview and benefits
- Required inputs and where to find them
- Expected processing time and output format
- How to customize slides before sending
- Who to contact for support

**Weekly Office Hours** (Thursdays 2-3 PM):
- Drop-in support for technical questions
- Share best practices from power users
- Preview upcoming Frame enhancements
- Collect feedback for continuous improvement

### Support Channels
**Technical Issues**:
- **Tier 1**: Teams channel (#ai-adoption-accelerator) for peer support
- **Tier 2**: Email Alec Fielding (alec.fielding@brooksidebi.com) for integration problems
- **Tier 3**: Email Markus Ahling (markus.ahling@brooksidebi.com) for AI/Azure issues

**Functional Questions**:
- **Primary**: Stephan Densby (stephan.densby@brooksidebi.com) for workflow guidance
- **Secondary**: Weekly office hours (Thursdays 2-3 PM)

**Escalation Path**:
- Critical blocker (Frame not working) → Alec Fielding (response SLA: 4 hours)
- Data accuracy issue → Stephan Densby (response SLA: 24 hours)
- Feature request → Submit via feedback survey → prioritized for next sprint

---

## Future Enhancements (Post-Pilot)

### Phase 2 Features (Weeks 5-12)
1. **Customizable Slide Templates**: Allow users to add/remove/reorder slides
2. **Trend Visualization**: Auto-generate charts showing week-over-week performance
3. **Predictive Insights**: AI-powered recommendations (e.g., "Route 45 at risk for OODT tomorrow")
4. **Multi-Station Rollup**: Regional managers can generate aggregated summaries across 5-10 stations
5. **Voice Input**: Speak notes/context instead of typing (Azure Speech Services integration)

### Phase 3 Features (Months 4-6)
1. **Smart Prioritization**: AI ranks action items by urgency and impact
2. **Automated Distribution**: Send summaries automatically at shift end (no button click needed)
3. **Mobile App**: Generate summaries from phone during route monitoring
4. **Integration with Project Alliance**: Auto-populate action items into tracking system
5. **Natural Language Queries**: "Show me all safety incidents this week" → AI generates ad-hoc slide

---

## Competitive Differentiation

**vs. Manual PowerPoint Creation**:
- ✅ 80-85% time savings (30-45 min → 5-8 min)
- ✅ Standardized format (consistency across all managers)
- ✅ Always includes critical metrics (no forgotten items)
- ✅ Real-time data (no stale copy/paste)

**vs. Generic AI Tools (ChatGPT, Copilot)**:
- ✅ Pre-integrated with AMZL systems (WST, Netradyne, etc.)
- ✅ Optimized for operations reporting (not generic summarization)
- ✅ Brookside BI brand voice embedded (professional tone)
- ✅ Compliance and security built-in (Azure AD, RBAC)

**vs. Custom Development**:
- ✅ Faster time-to-value (weeks vs. months)
- ✅ Lower cost ($0.08/execution vs. $50K+ dev effort)
- ✅ Proven architecture (Builder Button patterns)
- ✅ Continuous improvement (Frame updates don't require dev sprints)

---

## Lessons Learned & Best Practices

### From Builder Button MVP
1. **Start Simple**: 5-slide deck is easier to adopt than 10-slide comprehensive report
2. **Invisible Training**: Frame name "Daily Operations Summary" is self-explanatory
3. **Quick Wins**: Focus on time savings (30 min → 5 min) as primary value prop
4. **User Ownership**: Let users customize before sending (builds trust in AI output)

### From User Research
1. **Data Source Reliability**: API failures are the #1 user complaint → build robust retry logic
2. **Formatting Matters**: Bullet points > paragraphs for executive consumption
3. **Context is Critical**: Including "why" (root cause) matters more than "what" (the metric)
4. **Recognition Opportunity**: Highlighting "Top 3 wins" boosts morale and engagement

---

**Frame Owner**: Stephan Densby (Operations, Continuous Improvement)
**Technical Lead**: Markus Ahling (AI Engineering)
**Integration Lead**: Alec Fielding (DevOps, Power Platform)
**Pilot Start Date**: Week 3 (after Frame selection workshop)
**Estimated Pilot Cost**: $32 (400 executions × $0.08)
**Estimated Pilot Value**: $10,400 (400 executions × $26)
**Pilot ROI**: 325:1

---

**Built with Microsoft Azure + Power Platform | Version 1.0.0 | Last Updated: October 22, 2025**
