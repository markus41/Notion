# /unused-software - Identify Unused Software & Optimization Opportunities

Detect software subscriptions with no active project links to identify potential cost savings while verifying critical infrastructure dependencies before recommending cancellations.

## Calculation Logic

```
1. Query Software Tracker database
2. Filter WHERE Status = "Active" OR Status = "Trial"
3. For each software entry:
   - Count relations to Ideas Registry
   - Count relations to Research Hub
   - Count relations to Example Builds
   - Total Active Links = SUM(all relation counts)
4. Identify unused: WHERE Total Active Links = 0
5. Calculate potential savings:
   - Monthly Savings = SUM(Total Monthly Cost) for unused tools
   - Annual Savings = Monthly Savings × 12
6. Assess risk level for each:
   - HIGH RISK: Infrastructure, Security, Critical
   - MEDIUM RISK: Productivity, Communication, Important
   - LOW RISK: Nice to Have, Trial, Development tools
7. Check for usage indicators:
   - Last Modified date (if available)
   - Owner assigned (infrastructure responsibility)
   - Authentication method (shared accounts = potentially still used)
8. Sort by potential savings (highest to lowest)
```

## Output Format

```
🔍 Unused Software Analysis - Optimization Opportunities

**Potential Monthly Savings**: $X,XXX
**Potential Annual Savings**: $XX,XXX
**Unused Subscriptions Found**: X tools
**Analysis Date**: [Current Date]

⚠️ **Important**: Some software may be infrastructure dependencies or background services. Verify with team before canceling.

---

## High-Value Optimization Opportunities (>$200/month)

### 1. [Software Name] - $XXX/month ($X,XXX/year) - [RISK LEVEL]

**Details**:
- Category: [Category]
- Microsoft Service: [Yes/No - Service Name]
- Criticality: [Critical/Important/Nice to Have]
- Status: [Active/Trial]
- Licenses: X seats at $XX each
- Owner: [Team Member]
- Authentication: [Method]

**Usage Analysis**:
- Linked Ideas: 0
- Linked Research: 0
- Linked Builds: 0
- Last Modified: [Date - if available]

**Risk Assessment**: [RISK LEVEL]
- [Explanation of why this risk level]
- [Potential dependencies or infrastructure role]

**Recommendation**:
[Specific action: Cancel immediately / Review with team / Verify infrastructure role]

**Verification Questions**:
- [Question 1 to ask before canceling]
- [Question 2 to ask before canceling]

---

[Repeat for each high-value opportunity]

---

## Medium-Value Opportunities ($50-$200/month)

### [Software Name] - $XXX/month ($X,XXX/year) - [RISK LEVEL]
- Category: [Category]
- Linked Projects: 0
- Recommendation: [Action]

[List all medium-value opportunities]

---

## Low-Value Opportunities (<$50/month)

### [Software Name] - $XX/month ($XXX/year) - [RISK LEVEL]
- Category: [Category]
- Linked Projects: 0
- Recommendation: [Action]

[List all low-value opportunities]

---

## Trial Subscriptions with No Usage

⏰ **Action Required**: These trials are not being used and should be canceled before converting to paid.

1. **[Software Name]** - $XXX/month if converted
   - Trial End Date: [Date]
   - Days Remaining: [X]
   - Linked Projects: 0
   - Recommendation: Cancel trial before it converts

**Total Trial Savings if Canceled**: $XXX/month ($X,XXX/year)

---

## Potentially Active Infrastructure (HIGH RISK - Verify Before Canceling)

These tools have no project links but may be critical infrastructure:

1. **[Software Name]** - $XXX/month
   - Category: Infrastructure / Security
   - Criticality: Critical
   - Owner: [Name - likely knows if still needed]
   - Why flagged: [Reason it might still be needed]
   - Action: **Verify with [Owner] before any changes**

---

## Category Breakdown of Unused Software

- Development: $XXX/month ([X] tools)
- Infrastructure: $XXX/month ([X] tools) ⚠️ Verify first
- Productivity: $XXX/month ([X] tools)
- AI/ML: $XXX/month ([X] tools)
- Analytics: $XXX/month ([X] tools)
- Other: $XXX/month ([X] tools)

---

## Microsoft vs Third-Party Unused Tools

**Microsoft Services**: $XXX/month ([X] tools)
- [List Microsoft services that appear unused]
- Note: May be bundled/included in other subscriptions

**Third-Party Tools**: $XXX/month ([X] tools)
- [List third-party tools that appear unused]
- Easier to cancel (no ecosystem dependencies)

---

## Recommended Action Plan

### Immediate Actions (Low Risk - Safe to Cancel)
1. **Cancel [Software Name]** - Save $XXX/month
   - Risk: LOW
   - Action: Update Status to "Cancelled"
   - Verify: [Quick check to do first]

[List all low-risk cancellations]

**Immediate Savings**: $XXX/month ($X,XXX/year)

### Requires Team Review (Medium Risk)
1. **Review [Software Name]** with [Owner/Team Member]
   - Potential savings: $XXX/month
   - Questions to ask: [List]
   - Decision deadline: [Recommended timeframe]

[List all medium-risk items]

**Potential Savings**: $XXX/month ($X,XXX/year)

### Infrastructure Verification Required (High Risk)
1. **Verify [Software Name]** with [Technical Owner]
   - Potential savings: $XXX/month
   - Critical questions: [List]
   - DO NOT cancel without confirmation

[List all high-risk items]

**Potential Savings**: $XXX/month ($X,XXX/year)

---

## Implementation Checklist

- [ ] Review low-risk cancellations with team
- [ ] Schedule review meetings for medium-risk items
- [ ] Verify infrastructure dependencies for high-risk items
- [ ] Document decisions in Software Tracker notes
- [ ] Update Status field for confirmed cancellations
- [ ] Set reminder to verify actual savings next month
- [ ] Create Knowledge Vault entry for lessons learned

---

**Total Optimization Potential**:
- **Confirmed Safe**: $XXX/month ($X,XXX/year)
- **Requires Review**: $XXX/month ($X,XXX/year)
- **Infrastructure Check**: $XXX/month ($X,XXX/year)
- **MAXIMUM POTENTIAL**: $X,XXX/month ($XX,XXX/year)

**Next Steps**:
- Run `/consolidation-opportunities` to find additional savings
- Run `/microsoft-alternatives` to explore ecosystem simplification
- Document all decisions in Software Tracker
```

## Supported Variants

```bash
# All unused software (default)
/unused-software

# Specific category
/unused-software Development
/unused-software Infrastructure

# By risk level
/unused-software low-risk
/unused-software high-value

# Trials only
/unused-software trials
```

## Best for
Organizations seeking to optimize software spending by identifying subscriptions with no active usage while maintaining critical infrastructure and driving measurable cost reduction through systematic review processes.
