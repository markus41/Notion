# /annual-projection - Annual Cost Projection & Trending

Project annual software costs based on current spend and identify trending patterns to support strategic budget planning and long-term financial sustainability.

## Calculation Logic

```
1. Query Software Tracker database
2. Filter WHERE Status = "Active"
3. Calculate current state:
   - Total Monthly = SUM(Total Monthly Cost)
   - Annual Projection = Total Monthly × 12
4. Identify trending factors:
   - Trial subscriptions likely to convert
   - Contracts with known increases
   - Seasonal variations (if tracked)
5. Calculate adjusted projection:
   - Add: Trial → Active conversions (Status = "Trial")
   - Add: Planned new software (Status = "Concept")
   - Subtract: Known cancellations (contracts ending, not renewing)
6. Compare to previous periods (if historical data available)
7. Calculate cost per team member (Total / 5 team members)
```

## Output Format

```
📊 Annual Software Cost Projection

**Current Monthly Spend**: $X,XXX
**Base Annual Projection**: $XX,XXX (12 × monthly)
**Adjusted Annual Projection**: $XX,XXX
**Adjustment Factors**: +$X,XXX from trials, -$XXX from planned cancellations

**Cost per Team Member**: $X,XXX/year (based on 5 members)

---

### Projected Spending by Quarter

**Q1 (Jan-Mar)**: $XX,XXX
- Known contract renewals: [List]
- New subscriptions starting: [List]

**Q2 (Apr-Jun)**: $XX,XXX
- Known contract renewals: [List]
- Trial conversions expected: [List]

**Q3 (Jul-Sep)**: $XX,XXX
- Known contract renewals: [List]
- Planned additions: [List]

**Q4 (Oct-Dec)**: $XX,XXX
- Known contract renewals: [List]
- Planned cancellations: [List]

### Trial Subscriptions (Potential Additions)
[If Status = "Trial"]
1. **[Software Name]** - $XXX/month potential addition
   - Trial End Date: [Date]
   - Decision Needed: [Days until end]
   - Impact if converted: +$X,XXX annually

**Total Trial Impact**: +$X,XXX/year if all convert to Active

### Planned Software (Concept Stage)
[If Status = "Concept"]
1. **[Software Name]** - $XXX/month planned
   - Estimated Start: [Date/Quarter]
   - Linked Projects: [Ideas/Research/Builds]

**Total Planned Impact**: +$X,XXX/year when activated

### Trend Analysis
- Month-over-month change: +X% / -X%
- Year-over-year change: +X% / -X% (if historical data available)
- Fastest growing category: [Category] (+X%)
- Cost reduction opportunities: $X,XXX identified

---

### Budget Allocation Recommendation

**Critical Infrastructure** (XX% of total)
- Recommended allocation: $XX,XXX/year
- Current spend: $XX,XXX/year
- Status: [Under/Over/On Budget]

**Development & Innovation** (XX% of total)
- Recommended allocation: $XX,XXX/year
- Current spend: $XX,XXX/year
- Status: [Under/Over/On Budget]

**Productivity & Collaboration** (XX% of total)
- Recommended allocation: $XX,XXX/year
- Current spend: $XX,XXX/year
- Status: [Under/Over/On Budget]

---

**Strategic Recommendations**:
1. [Specific budget action based on trends]
2. [Consolidation or expansion recommendation]
3. [Risk mitigation for cost increases]

**Next Steps**:
- Run `/what-if-analysis` to model different scenarios
- Run `/consolidation-opportunities` to identify potential savings
- Review trials with `/expiring-contracts 30` for pending decisions
```

## Best for
Organizations planning annual budgets and requiring visibility into software cost trends to support sustainable growth and informed strategic decisions.
