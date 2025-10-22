# /cost-by-category - Detailed Category Spending Analysis

Analyze software spending by category to identify concentration patterns, optimization opportunities, and strategic investment areas that drive measurable outcomes.

## Calculation Logic

```
1. Query Software Tracker database
2. Filter WHERE Status = "Active"
3. Group by Category field:
   - Development
   - Infrastructure
   - Productivity
   - Analytics
   - Communication
   - Security
   - Storage
   - AI/ML
   - Design
4. For each category:
   - Calculate: SUM(Total Monthly Cost)
   - Count: Number of tools
   - List: All software in category
   - Calculate: Average cost per tool
   - Identify: Most expensive tool in category
   - Count: Total licenses in category
   - Assess: Criticality distribution
5. Calculate percentage of total spend
6. Rank categories by spend (highest to lowest)
7. Identify Microsoft vs third-party split per category
```

## Output Format

```
📁 Software Spending by Category

**Total Monthly Spend**: $X,XXX
**Total Active Tools**: X across [X] categories
**Analysis Date**: [Current Date]

---

## Category Breakdown (Ranked by Spend)

### 1. [Category Name] - $X,XXX/month ($XX,XXX/year) - XX% of total

**Tools in Category**: X
**Average Cost per Tool**: $XXX/month
**Total Licenses**: X seats
**Criticality**: X Critical, X Important, X Nice to Have

**Microsoft Services**: $XXX/month (XX% of category)
**Third-Party Tools**: $XXX/month (XX% of category)

**Tools List**:
1. **[Software Name]** - $XXX/month (X licenses)
   - Microsoft Service: [Yes/No - Service Name]
   - Criticality: [Level]
   - Users: [Names]
   - Linked Projects: [Count] active

2. [Repeat for all tools in category]

**Optimization Opportunities**:
- [Consolidation possibilities]
- [Microsoft alternatives for third-party tools]
- [License optimization opportunities]

---

[Repeat structure for each category]

---

## Category Investment Summary

### High Investment Categories (>20% of total)
- **[Category]**: $X,XXX/month - [Strategic justification or optimization recommendation]

### Medium Investment Categories (10-20% of total)
- **[Category]**: $X,XXX/month - [Assessment]

### Low Investment Categories (<10% of total)
- **[Category]**: $X,XXX/month - [Potential gaps or appropriate sizing]

---

## Microsoft Ecosystem Coverage by Category

### Development
- Microsoft Coverage: XX% ($XXX/month)
- Key Microsoft Services: [GitHub, Azure DevOps, etc.]
- Third-Party Dependencies: [List with costs]
- Consolidation Opportunity: [Yes/No - Details]

### Infrastructure
- Microsoft Coverage: XX% ($XXX/month)
- Key Microsoft Services: [Azure services]
- Third-Party Dependencies: [List with costs]
- Consolidation Opportunity: [Yes/No - Details]

[Repeat for each category]

---

## Cross-Category Insights

**Most Expensive Category**: [Category] ($X,XXX/month)
- Represents XX% of total spend
- Assessment: [Justified by critical infrastructure / Opportunity for optimization]

**Least Expensive Category**: [Category] ($XXX/month)
- Represents XX% of total spend
- Assessment: [Potential gap / Appropriately sized]

**Highest Microsoft Adoption**: [Category] (XX% Microsoft)
- Ecosystem integration: [Strong/Moderate/Weak]

**Lowest Microsoft Adoption**: [Category] (XX% Microsoft)
- Microsoft Alternatives Available: [List options]
- Estimated Savings if Migrated: $XXX/month

**Most Tool-Heavy Category**: [Category] (X tools)
- Consolidation Potential: [High/Medium/Low]
- Duplicate Functionality: [Yes/No - Details]

**Highest Cost per Tool**: [Category] ($XXX average)
- Driven by: [Enterprise licensing / Specialized tools]

---

## Strategic Recommendations

### Immediate Actions
1. **[Category]**: [Specific optimization recommendation]
   - Potential Savings: $XXX/month
   - Risk Level: [Low/Medium/High]
   - Implementation Effort: [Low/Medium/High]

### Medium-Term Opportunities
1. **[Category]**: [Consolidation or migration recommendation]
   - Potential Savings: $XXX/month
   - Timeline: [Estimated duration]
   - Dependencies: [What needs to happen first]

### Strategic Investments
1. **[Category]**: [Area requiring increased investment]
   - Current Spend: $XXX/month
   - Recommended Spend: $XXX/month
   - Business Justification: [Why this matters]

---

**Next Steps**:
- Run `/consolidation-opportunities` to identify specific tool overlaps
- Run `/microsoft-alternatives [category]` to explore ecosystem options
- Run `/unused-software` to find category-specific optimization
```

## Supported Variants

```bash
# All categories (default)
/cost-by-category

# Specific category deep-dive
/cost-by-category Development
/cost-by-category Infrastructure
/cost-by-category AI/ML

# Compare two categories
/cost-by-category Development vs Infrastructure
```

## Best for
Organizations seeking to optimize software portfolios by understanding category-level spending patterns, identifying consolidation opportunities, and ensuring strategic alignment between investment and business priorities.
