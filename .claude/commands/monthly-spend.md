# /monthly-spend - Total Monthly Software Spend Analysis

Analyze total monthly software spending across all active subscriptions to establish transparent cost visibility and drive informed budget decisions.

## Calculation Logic

```
1. Query Software Tracker database
2. Filter WHERE Status = "Active"
3. Calculate: SUM(Total Monthly Cost) for all active entries
4. Group by:
   - Category (Development, Infrastructure, AI/ML, Analytics, etc.)
   - Microsoft Service (Azure, M365, Power Platform, GitHub, Dynamics, None)
   - Criticality (Critical, Important, Nice to Have)
5. Calculate percentages for each grouping
6. Identify top 5 most expensive tools
7. Show license utilization summary
```

## Output Format

```
💰 Monthly Software Spend Analysis

**Total Monthly Spend**: $X,XXX
**Annual Projection**: $XX,XXX
**Active Subscriptions**: X tools
**Analysis Date**: [Current Date]

---

### Spending by Category
- Development: $X,XXX/month (XX%)
- Infrastructure: $X,XXX/month (XX%)
- AI/ML: $X,XXX/month (XX%)
- Analytics: $X,XXX/month (XX%)
- Productivity: $X,XXX/month (XX%)
- Communication: $X,XXX/month (XX%)
- Security: $X,XXX/month (XX%)
- Storage: $X,XXX/month (XX%)
- Design: $X,XXX/month (XX%)

### Microsoft vs Third-Party Breakdown
- Microsoft Services: $X,XXX/month (XX%)
  - Azure: $XXX/month
  - M365: $XXX/month
  - Power Platform: $XXX/month
  - GitHub: $XXX/month
  - Dynamics: $XXX/month
- Third-Party Tools: $X,XXX/month (XX%)

### Spending by Criticality
- Critical: $X,XXX/month (XX%) - [X] tools
- Important: $X,XXX/month (XX%) - [X] tools
- Nice to Have: $X,XXX/month (XX%) - [X] tools

### Top 5 Most Expensive Tools
1. **[Software Name]** - $X,XXX/month ($XX,XXX/year)
   - Licenses: X seats
   - Category: [Category]
   - Criticality: [Level]
   - Users: [Count] team members
   - Linked Projects: [Count] active

2. [Repeat for top 5]

### License Utilization Summary
- Total Licenses: X seats across all software
- Average Cost per License: $XXX/month
- Most Licensed Tool: [Name] (X seats)

---

**Next Steps**:
- Run `/unused-software` to identify optimization opportunities
- Run `/consolidation-opportunities` to find potential savings
- Run `/expiring-contracts` to plan for upcoming renewals
```

## Best for
Organizations requiring monthly budget visibility to track software spending patterns and ensure sustainable growth through transparent cost management.
