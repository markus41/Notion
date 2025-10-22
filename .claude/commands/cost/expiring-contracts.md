# /expiring-contracts - Contract Expiration Monitoring & Renewal Planning

Monitor upcoming contract expirations to enable proactive renewal decisions, prevent service disruptions, and identify renegotiation opportunities that drive cost optimization.

## Calculation Logic

```
1. Query Software Tracker database
2. Filter WHERE Status = "Active" OR Status = "Trial"
3. For each entry with Contract End Date:
   - Calculate days until expiration: Contract End Date - Today
   - Categorize urgency:
     - URGENT: 0-30 days (immediate action required)
     - WARNING: 31-60 days (decision needed soon)
     - NOTICE: 61-90 days (planning window)
     - FUTURE: 91+ days (upcoming in next quarter)
4. For each expiring contract:
   - Get current monthly/annual cost
   - Count linked projects (usage assessment)
   - Identify owner/decision maker
   - Check for Microsoft alternatives
   - Note auto-renewal status (if tracked)
5. Sort by urgency, then by cost (highest first)
6. Calculate total renewal cost for each period
7. Identify optimization opportunities at renewal time
```

## Output Format

```
⏰ Contract Expiration & Renewal Analysis

**Expiring in Next 90 Days**: X contracts totaling $X,XXX/month
**Renewal Decisions Required**: X contracts
**Analysis Date**: [Current Date]

---

## 🚨 URGENT - Expiring Within 30 Days (Immediate Action Required)

### Total Expiring: $X,XXX/month ($XX,XXX/year) across [X] contracts

---

### 1. [Software Name] - EXPIRES IN [X] DAYS

**Contract Details**:
- Expiration Date: [Date]
- Current Cost: $XXX/month ($X,XXX/year)
- Licenses: X seats at $XX each
- Contract Type: [Monthly/Annual/Multi-year]
- Auto-Renewal: [Yes/No/Unknown]
- Owner: [Team Member - Decision Maker]

**Usage Assessment**:
- Status: [Active/Trial]
- Linked Ideas: [X]
- Linked Research: [X]
- Linked Builds: [X]
- Total Active Projects: [X]
- Users: [Team members actively using]
- Criticality: [Critical/Important/Nice to Have]

**Utilization Analysis**:
- License Usage: X of X seats active ([XX%] utilization)
- Primary Users: [Names]
- Last Active: [Recent usage indicator if available]
- Business Value: [HIGH/MEDIUM/LOW based on links and criticality]

**Renewal Recommendation**: [RENEW/CANCEL/NEGOTIATE/REPLACE]

**Justification**:
- [Reason 1 supporting recommendation]
- [Reason 2 supporting recommendation]
- [Risk if not renewed / Savings if canceled]

**Alternative Options**:

**Option 1: Renew as-is**
- Cost: $XXX/month ($X,XXX/year)
- Pros: [Continuity, no migration effort]
- Cons: [Missed optimization opportunity]

**Option 2: Negotiate/Optimize**
- Reduce licenses from X to X seats
- Downgrade tier from [Current] to [Lower]
- Potential Cost: $XXX/month (Save $XXX/month)
- Risk: [Assessment]

**Option 3: Replace with [Microsoft Alternative]**
- Microsoft Service: [Azure/M365/Power Platform/GitHub]
- Estimated Cost: $XXX/month
- Migration Effort: [LOW/MEDIUM/HIGH]
- Timeline: [X weeks - May need temporary overlap]
- Savings: $XXX/month ($X,XXX/year)

**Option 4: Cancel**
- Savings: $XXX/month ($X,XXX/year)
- Impact: [Projects affected]
- Migration Plan: [What to move to]
- Risk: [HIGH/MEDIUM/LOW]

**Decision Required By**: [Date - typically 2 weeks before expiration]
**Action Owner**: [Team Member]
**Next Steps**:
1. [Immediate action item 1]
2. [Immediate action item 2]
3. [Decision deadline]

---

[Repeat for each urgent expiration]

---

## ⚠️ WARNING - Expiring Within 31-60 Days (Decision Needed Soon)

### Total Expiring: $X,XXX/month ($XX,XXX/year) across [X] contracts

---

### [Software Name] - EXPIRES IN [X] DAYS

**Contract Details**:
- Expiration Date: [Date]
- Current Cost: $XXX/month ($X,XXX/year)
- Licenses: X seats

**Usage**: [X] active projects, [Criticality level]

**Recommendation**: [RENEW/NEGOTIATE/REPLACE/CANCEL]

**Options**:
1. Renew as-is: $XXX/month
2. [Optimization option]: $XXX/month (Save $XXX)
3. [Microsoft alternative]: $XXX/month (Save $XXX)

**Decision Timeline**:
- Review by: [Date - 30 days before expiration]
- Decision by: [Date - 2 weeks before expiration]
- Owner: [Team Member]

---

[Repeat for each warning-level expiration]

---

## 📋 NOTICE - Expiring Within 61-90 Days (Planning Window)

### Total Expiring: $X,XXX/month ($XX,XXX/year) across [X] contracts

| Software | Expires | Current Cost | Projects | Recommendation | Owner |
|----------|---------|--------------|----------|----------------|-------|
| [Name] | [Date] | $XXX/mo | X | [Action] | [Name] |
| [Name] | [Date] | $XXX/mo | X | [Action] | [Name] |

**Planning Actions**:
- Evaluate usage over next 60 days
- Research Microsoft alternatives
- Gather team feedback on value
- Prepare negotiation points if renewing
- Schedule decision meeting 30 days before expiration

---

## 📅 Future Expirations (91-365 days)

### Expiring in Next Quarter

| Quarter | Contracts Expiring | Total Monthly Cost | Major Renewals |
|---------|-------------------|-------------------|----------------|
| Q1 | X | $X,XXX | [Top 3 by cost] |
| Q2 | X | $X,XXX | [Top 3 by cost] |
| Q3 | X | $X,XXX | [Top 3 by cost] |
| Q4 | X | $X,XXX | [Top 3 by cost] |

**Major Upcoming Renewals**:
1. **[Software Name]** - Expires [Date] - $X,XXX/year
   - Start review: [Date - 90 days before]
   - High-value contract: Plan comprehensive evaluation

---

## Contracts with Unknown End Dates

⚠️ **Action Required**: These active subscriptions have no contract end date tracked.

| Software | Cost | Status | Owner | Action |
|----------|------|--------|-------|--------|
| [Name] | $XXX/mo | Active | [Name] | Verify contract terms |

**Total Untracked**: $X,XXX/month

**Recommended Actions**:
1. Contact vendors/review invoices for contract terms
2. Update Software Tracker with Contract End Date
3. Set calendar reminders for review periods

---

## Auto-Renewal Tracking

### Auto-Renewing Contracts (Require Active Cancelation)

⚠️ These will renew automatically unless canceled:

1. **[Software Name]** - Auto-renews [Date] at $XXX/month
   - Cancelation Deadline: [Date - typically 30 days before]
   - Current Usage: [Assessment]
   - Recommendation: [ALLOW AUTO-RENEWAL / CANCEL BEFORE RENEWAL]

---

## Renewal Cost Summary

### Next 30 Days
- Contracts Expiring: [X]
- Total Monthly Cost: $X,XXX
- Total Annual Cost: $XX,XXX
- Recommended to Renew: $X,XXX/month
- Recommended to Optimize: $XXX/month (Save $XXX)
- Recommended to Cancel: $XXX/month (Save $XXX)

### Next 60 Days (Cumulative)
- Contracts Expiring: [X]
- Total Monthly Cost: $X,XXX
- Total Annual Cost: $XX,XXX
- Optimization Potential: $XXX/month

### Next 90 Days (Cumulative)
- Contracts Expiring: [X]
- Total Monthly Cost: $X,XXX
- Total Annual Cost: $XX,XXX
- Optimization Potential: $XXX/month

### Annual Renewal Forecast
- Total Contracts Expiring in Next 12 Months: [X]
- Total Annual Renewal Value: $XX,XXX
- Identified Optimization Opportunities: $X,XXX (XX% savings)

---

## Optimization Opportunities at Renewal

Renewal time is the best opportunity to optimize:

### License Right-Sizing
1. **[Software Name]**: X licenses, only X actively used
   - Current: $XXX/month
   - Right-sized: $XXX/month
   - Savings: $XXX/month ($X,XXX/year)

### Tier Optimization
1. **[Software Name]**: Currently on [Tier], using [XX%] of features
   - Current: $XXX/month
   - Downgraded tier: $XXX/month
   - Savings: $XXX/month ($X,XXX/year)

### Microsoft Migration at Renewal
1. **[Software Name]**: Expiring [Date]
   - Current: $XXX/month
   - Microsoft Alternative: [Azure/M365/etc.] at $XXX/month
   - Savings: $XXX/month ($X,XXX/year)
   - Migration window: [X] days before expiration

---

## Decision Workflow & Timeline

### For Each Expiring Contract:

**90 Days Before**: Initial Review
- Assess current usage and value
- Research alternatives (especially Microsoft options)
- Gather team feedback
- Identify optimization opportunities

**60 Days Before**: Decision Preparation
- Analyze cost/benefit of renewal vs alternatives
- Prepare negotiation points if renewing
- Estimate migration effort if switching
- Get stakeholder input

**30 Days Before**: Final Decision
- Make renew/optimize/replace/cancel decision
- Initiate vendor negotiations if needed
- Start migration planning if replacing
- Submit cancelation if not renewing

**14 Days Before**: Execution
- Confirm renewal terms or
- Execute cancelation or
- Begin migration to alternative

**Expiration Date**: Verify Completion
- Confirm service status
- Update Software Tracker Status field
- Archive or update project links
- Document lessons learned

---

## Action Items by Owner

### [Team Member 1]
- [ ] **[Software Name]** (Expires [Date]): [Decision needed]
- [ ] **[Software Name]** (Expires [Date]): [Action required]

### [Team Member 2]
- [ ] **[Software Name]** (Expires [Date]): [Decision needed]

[List all action items organized by responsible owner]

---

## Notification Setup Recommendations

Set calendar reminders for:
- **90 days before expiration**: Start evaluation
- **60 days before expiration**: Prepare decision
- **30 days before expiration**: Make final decision
- **14 days before expiration**: Execute action
- **7 days before expiration**: Final verification

**For auto-renewing contracts**: Set reminder for cancelation deadline (typically 30 days before renewal)

---

**Next Steps**:
1. Review urgent expirations (30 days) immediately
2. Schedule decision meetings for warning-level contracts
3. Update Contract End Date for unknown expirations
4. Set up calendar reminders for all upcoming renewals
5. Run `/microsoft-alternatives [software-name]` for replacement options
6. Document all renewal decisions in Software Tracker
7. Track actual savings achieved vs projected
```

## Supported Variants

```bash
# Next 90 days (default)
/expiring-contracts

# Specific timeframe
/expiring-contracts 30    # Next 30 days only (urgent)
/expiring-contracts 60    # Next 60 days
/expiring-contracts 180   # Next 6 months

# By cost threshold
/expiring-contracts high-value    # Only contracts >$500/month

# Auto-renewals only
/expiring-contracts auto-renew

# Missing contract dates
/expiring-contracts unknown
```

## Best for
Organizations requiring proactive contract management to prevent service disruptions, optimize renewal negotiations, and identify strategic opportunities for cost reduction and Microsoft ecosystem consolidation at natural contract transition points.
