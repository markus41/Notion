# /what-if-analysis - Budget Forecasting & Scenario Modeling

Model different software spending scenarios to forecast budget impact, evaluate strategic decisions, and support data-driven planning through comprehensive what-if cost analysis.

## Calculation Logic

```
1. Query Software Tracker database for current baseline
2. Based on scenario type requested:
   - NEW_IDEA: Model adding software for a proposed idea/build
   - CANCEL: Model impact of canceling specific software
   - CONSOLIDATE: Model cost impact of consolidation strategy
   - MIGRATION: Model Microsoft ecosystem migration
   - GROWTH: Model team growth impact on licenses
   - OPTIMIZATION: Model combined optimization strategies
3. Calculate current state baseline
4. Apply scenario changes
5. Calculate new state after changes
6. Compare baseline vs scenario (delta analysis)
7. Project impacts over time (monthly, quarterly, annual)
8. Identify risks and dependencies
9. Recommend decision criteria
```

## Output Format

```
📊 What-If Cost Analysis: [Scenario Name]

**Scenario Type**: [NEW_IDEA/CANCEL/CONSOLIDATE/MIGRATION/GROWTH/OPTIMIZATION]
**Analysis Date**: [Current Date]

---

## Current Baseline

**Total Monthly Spend**: $X,XXX
**Total Annual Spend**: $XX,XXX
**Active Subscriptions**: [X] tools
**Team Size**: [X] members

**Breakdown**:
- Development: $X,XXX/month
- Infrastructure: $X,XXX/month
- AI/ML: $XXX/month
- Productivity: $XXX/month
- Other: $XXX/month

**Microsoft vs Third-Party**:
- Microsoft: $X,XXX/month (XX%)
- Third-Party: $XXX/month (XX%)

---

## Scenario: [Scenario Description]

### Proposed Changes

[For NEW_IDEA scenario]:
**Add software for: [Idea/Research/Build Name]**

**New Software Required**:
1. **[Software Name]**
   - Cost: $XXX/month ($X,XXX/year)
   - Licenses: X seats
   - Category: [Category]
   - Microsoft Service: [Yes/No]
   - Justification: [Why needed]
   - Alternative considered: [Cheaper option if exists]

2. [Repeat for each new tool]

**Existing Software to Leverage**:
- [Software Name]: Already licensed, no additional cost
- [Software Name]: Add X licenses at $XX each = $XXX/month

**Total New Investment**: $XXX/month ($X,XXX/year)

---

[For CANCEL scenario]:
**Cancel: [Software Name(s)]**

**Software to Cancel**:
1. **[Software Name]**
   - Current Cost: $XXX/month ($X,XXX/year)
   - Reason for cancellation: [Unused/Replaced/Duplicate]
   - Linked Projects: [X] (impact assessment)
   - Alternative: [What replaces it]
   - Risk: [LOW/MEDIUM/HIGH]

2. [Repeat for each cancellation]

**Total Savings**: $XXX/month ($X,XXX/year)

---

[For CONSOLIDATE scenario]:
**Consolidate: [Description of consolidation]**

**Current State**:
- [Tool A]: $XXX/month
- [Tool B]: $XXX/month
- [Tool C]: $XXX/month
- **Total**: $XXX/month

**Proposed State**:
- [Consolidated Tool/Microsoft Service]: $XXX/month
- Licenses: [Configuration]
- **Total**: $XXX/month

**Net Change**: -$XXX/month (SAVINGS) / +$XXX/month (INCREASE)

---

[For MIGRATION scenario]:
**Migrate to Microsoft Ecosystem**

**Third-Party Tools to Replace**:
1. **[Tool Name]** → **[Microsoft Service]**
   - Current: $XXX/month
   - Microsoft: $XXX/month
   - Delta: [+/-]$XXX/month
   - Migration effort: [LOW/MEDIUM/HIGH]
   - Timeline: [X weeks]

[Repeat for each migration]

**Total Migration Impact**: [+/-]$XXX/month

---

[For GROWTH scenario]:
**Team Growth Impact**

**Current Team**: [X] members
**Projected Team**: [X] members (+[X] new hires)
**Timeline**: [Quarter/Date]

**License Impact**:
1. **[Software Name]**
   - Current: X licenses at $XX each = $XXX/month
   - New: X licenses at $XX each = $XXX/month
   - Increase: $XXX/month

[Repeat for each tool requiring additional licenses]

**Total Growth Cost**: +$XXX/month ($X,XXX/year)

---

## Projected New State

**Total Monthly Spend**: $X,XXX
**Total Annual Spend**: $XX,XXX
**Active Subscriptions**: [X] tools
**Team Size**: [X] members

**Breakdown**:
- Development: $X,XXX/month
- Infrastructure: $X,XXX/month
- AI/ML: $XXX/month
- Productivity: $XXX/month
- Other: $XXX/month

**Microsoft vs Third-Party**:
- Microsoft: $X,XXX/month (XX%)
- Third-Party: $XXX/month (XX%)

---

## Delta Analysis: Baseline vs Scenario

**Monthly Impact**: [+/-]$XXX ([+/-]XX%)
**Annual Impact**: [+/-]$X,XXX

**Spending Changes by Category**:
| Category | Baseline | Scenario | Change | % Change |
|----------|----------|----------|--------|----------|
| Development | $X,XXX | $X,XXX | [+/-]$XXX | [+/-]XX% |
| Infrastructure | $X,XXX | $X,XXX | [+/-]$XXX | [+/-]XX% |
| AI/ML | $XXX | $XXX | [+/-]$XXX | [+/-]XX% |
| Productivity | $XXX | $XXX | [+/-]$XXX | [+/-]XX% |
| **TOTAL** | **$X,XXX** | **$X,XXX** | **[+/-]$XXX** | **[+/-]XX%** |

**Microsoft Ecosystem Impact**:
- Baseline Microsoft: $X,XXX/month (XX%)
- Scenario Microsoft: $X,XXX/month (XX%)
- Change: [+/-]$XXX ([Increased/Decreased] ecosystem consolidation)

**Cost Efficiency Metrics**:
- Cost per team member (baseline): $XXX/month
- Cost per team member (scenario): $XXX/month
- Change: [+/-]$XXX per person

---

## Timeline Projection

### Monthly Breakdown (First 12 Months)

| Month | Baseline | Scenario | Delta | Notes |
|-------|----------|----------|-------|-------|
| Month 1 | $X,XXX | $X,XXX | [+/-]$XXX | [Implementation starts] |
| Month 2 | $X,XXX | $X,XXX | [+/-]$XXX | [Migration phase] |
| Month 3 | $X,XXX | $X,XXX | [+/-]$XXX | [Full scenario active] |
| Month 4-12 | $X,XXX | $X,XXX | [+/-]$XXX | [Steady state] |

**Year 1 Total Impact**: [+/-]$XX,XXX

**Implementation Costs** (One-time):
- Migration effort: $X,XXX (estimated labor)
- Overlap period: $XXX (running both old and new for [X] weeks)
- Training: $XXX
- **Total Implementation**: $X,XXX

**Net Year 1**: [+/-]$XX,XXX (recurring savings - implementation costs)

### Multi-Year Projection

| Year | Annual Cost | Change from Baseline | Cumulative Savings/Cost |
|------|-------------|----------------------|-------------------------|
| Year 1 | $XX,XXX | [+/-]$XX,XXX | [+/-]$XX,XXX |
| Year 2 | $XX,XXX | [+/-]$XX,XXX | [+/-]$XX,XXX |
| Year 3 | $XX,XXX | [+/-]$XX,XXX | [+/-]$XX,XXX |

**3-Year TCO Impact**: [+/-]$XXX,XXX

---

## Risk Assessment

### Implementation Risks

**HIGH RISK**:
1. **[Risk Description]**
   - Likelihood: [HIGH/MEDIUM/LOW]
   - Impact: [Description of what could go wrong]
   - Mitigation: [Specific mitigation strategy]
   - Contingency: [Fallback plan]

**MEDIUM RISK**:
1. **[Risk Description]**
   - Likelihood: [HIGH/MEDIUM/LOW]
   - Impact: [Description]
   - Mitigation: [Strategy]

**LOW RISK**:
1. **[Risk Description]**
   - Impact: Minimal
   - Mitigation: [Simple strategy]

### Financial Risks

**Budget Overrun Risk**: [LOW/MEDIUM/HIGH]
- Scenario assumes: [Assumptions]
- Could increase if: [Conditions that would increase cost]
- Buffer recommendation: [X% or $XXX]

**Savings Realization Risk**: [LOW/MEDIUM/HIGH]
- Dependent on: [Conditions for savings to materialize]
- Risk factors: [What could prevent full savings]
- Probability of full savings: [XX%]

---

## Dependencies & Prerequisites

### Required for Scenario Success

1. **[Dependency 1]**
   - Type: [Technical/Business/Resource]
   - Owner: [Team Member]
   - Timeline: [When needed]
   - Risk if not met: [Impact]

2. **[Dependency 2]**
   - Type: [Technical/Business/Resource]
   - Owner: [Team Member]
   - Timeline: [When needed]
   - Risk if not met: [Impact]

### Blocking Issues
- [Issue 1]: Must resolve before proceeding
- [Issue 2]: Could delay implementation by [X weeks]

---

## Alternative Scenarios Comparison

### Scenario A: [This Scenario]
- Monthly impact: [+/-]$XXX
- Annual impact: [+/-]$X,XXX
- Implementation effort: [LOW/MEDIUM/HIGH]
- Risk: [LOW/MEDIUM/HIGH]

### Scenario B: [Alternative Approach]
- Monthly impact: [+/-]$XXX
- Annual impact: [+/-]$X,XXX
- Implementation effort: [LOW/MEDIUM/HIGH]
- Risk: [LOW/MEDIUM/HIGH]

### Scenario C: [Do Nothing]
- Monthly impact: $0
- Annual impact: $0
- Risk: [Opportunity cost, technical debt, etc.]

**Recommended Scenario**: [A/B/C]
**Justification**: [Clear reasoning based on cost, risk, and strategic value]

---

## Strategic Alignment

### Microsoft Ecosystem Strategy
**Current Microsoft %**: XX%
**Scenario Microsoft %**: XX%
**Change**: [+/-]XX percentage points

**Alignment Assessment**: [STRONG/MODERATE/WEAK]
- [How this scenario aligns with Microsoft-first strategy]
- [Integration benefits or concerns]

### Business Priorities
**Alignment with**:
- Cost optimization: [HIGH/MEDIUM/LOW]
- Innovation enablement: [HIGH/MEDIUM/LOW]
- Team productivity: [HIGH/MEDIUM/LOW]
- Technical sustainability: [HIGH/MEDIUM/LOW]

---

## Decision Criteria

### Approve Scenario If:
- [ ] Total cost impact < $XXX/month (within budget)
- [ ] Implementation risks are LOW or have clear mitigation
- [ ] Dependencies are in place or achievable
- [ ] Strategic alignment score: [Score/10]
- [ ] Team capacity available for implementation
- [ ] Positive ROI within [X] months
- [ ] [Custom criterion based on scenario]

### Reject or Defer If:
- [ ] Cost impact exceeds budget threshold
- [ ] High risks without mitigation
- [ ] Critical dependencies unmet
- [ ] Negative ROI or payback > [X] months
- [ ] Team capacity constraints
- [ ] [Custom criterion]

### Key Questions to Answer Before Proceeding:
1. [Question 1 - e.g., "Do we have budget approval for $X,XXX increase?"]
2. [Question 2 - e.g., "Is team trained on Microsoft alternative?"]
3. [Question 3 - e.g., "Can we migrate within [X] weeks without disruption?"]

---

## Implementation Plan

[If scenario is approved/likely to be approved]

### Phase 1: Preparation ([Timeline])
**Activities**:
1. [Specific task]
2. [Specific task]
3. [Specific task]

**Cost Impact**: $XXX
**Owner**: [Team Member]

### Phase 2: Execution ([Timeline])
**Activities**:
1. [Specific task]
2. [Specific task]
3. [Specific task]

**Cost Impact**: [+/-]$XXX/month starts
**Owner**: [Team Member]

### Phase 3: Validation ([Timeline])
**Activities**:
1. Verify actual costs match projection
2. Confirm savings realized (if applicable)
3. Document lessons learned
4. Update Software Tracker

**Success Criteria**:
- Actual monthly cost = $X,XXX (±[X%])
- [Other measurable criteria]

---

## Monitoring & Adjustment

### Track Monthly:
- Actual spend vs projected
- Variance analysis
- Early indicators of risks materializing
- User adoption (if new tools)
- Savings realization (if optimization)

### Adjustment Triggers:
**If actual cost exceeds projection by XX%**:
- Action: [Corrective measure]

**If savings not realized within X months**:
- Action: [Reassess or rollback]

**If high-risk event occurs**:
- Action: [Contingency plan]

---

## Recommendation

**Recommended Action**: [PROCEED/DEFER/REJECT/MODIFY]

**Executive Summary**:
[2-3 sentence summary of scenario, impact, and recommendation]

**Justification**:
1. [Primary reason for recommendation]
2. [Secondary reason]
3. [Risk/opportunity consideration]

**Next Steps**:
1. [Immediate action item]
2. [Follow-up action]
3. [Decision deadline]
4. [Stakeholders to involve]

**Decision Owner**: [Team Member]
**Decision Deadline**: [Date - when this scenario becomes moot]

---

**Follow-Up Actions**:
- Update Software Tracker if scenario approved
- Schedule implementation kickoff
- Set up cost monitoring dashboard
- Document decision in Knowledge Vault
- Run `/monthly-spend` after implementation to verify impact
```

## Supported Variants

```bash
# New idea cost impact
/what-if-analysis new-idea "[Idea Name]"

# Cancellation impact
/what-if-analysis cancel "[Software Name]"
/what-if-analysis cancel-multiple "[Software1, Software2, Software3]"

# Consolidation scenario
/what-if-analysis consolidate "[Tool Category]"
/what-if-analysis consolidate-to-microsoft

# Microsoft migration
/what-if-analysis migrate-to-azure
/what-if-analysis migrate-to-m365

# Team growth
/what-if-analysis grow-team [current-size] to [new-size]

# Combined optimization
/what-if-analysis optimize-all

# Custom scenario
/what-if-analysis custom "[Description of changes]"

# Compare multiple scenarios
/what-if-analysis compare "[Scenario1]" vs "[Scenario2]"
```

## Best for
Organizations requiring data-driven budget forecasting to evaluate strategic decisions, model different spending scenarios, and support informed planning through comprehensive what-if cost analysis that aligns with business priorities and Microsoft ecosystem strategy.
