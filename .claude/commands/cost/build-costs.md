# /build-costs - Example Build Cost Analysis & Rollup

Calculate comprehensive software costs for specific Example Builds by aggregating all linked tools and services to provide transparent project-level financial visibility and support sustainable development decisions.

## Calculation Logic

```
1. Query Software Tracker database
2. For specified build (or all builds if no argument):
   - Get all software linked to the Example Build
   - For each linked software:
     - Get Total Monthly Cost (Cost × License Count)
     - Get Annual Cost (Total Monthly Cost × 12)
     - Get Criticality level
     - Get Category
     - Check if Microsoft Service
3. Calculate build-specific costs:
   - Total Monthly Cost = SUM(all linked software monthly costs)
   - Total Annual Cost = Total Monthly × 12
4. Break down by:
   - Category (Development, Infrastructure, AI/ML, etc.)
   - Microsoft vs Third-Party
   - Criticality (Critical, Important, Nice to Have)
   - Shared vs Dedicated (count other builds using same software)
5. Compare to similar builds for benchmarking
6. Identify cost optimization opportunities specific to this build
```

## Output Format

```
🛠️ Example Build Cost Analysis: [Build Name]

**Build Details**:
- Status: [Concept/Active/Completed/Archived]
- Build Type: [Prototype/POC/Demo/MVP/Reference]
- Viability: [Production Ready/Needs Work/Reference Only]
- Reusability: [Highly Reusable/Partially Reusable/One-Off]
- Lead Builder: [Team Member]
- Core Team: [Team Members]

---

## 💰 Total Build Cost

**Monthly Software Cost**: $X,XXX
**Annual Projection**: $XX,XXX

**Software Tools**: [X] linked services
**Analysis Date**: [Current Date]

---

## Detailed Cost Breakdown

### Software & Services Used

#### 1. [Software Name] - $XXX/month ($X,XXX/year)

**Service Details**:
- Category: [Category]
- Microsoft Service: [Yes/No - Service Name]
- Licenses: X seats at $XX each
- Criticality: [Critical/Important/Nice to Have]

**Build Usage**:
- Primary Use: [What this build uses it for]
- Users: [Team members using for this build]
- Necessity: [REQUIRED / OPTIONAL / OPTIMIZATION CANDIDATE]

**Shared or Dedicated**:
- Also used by: [X other builds / Ideas / Research]
- Allocation: [100% this build / Shared across [X] projects]

**Microsoft Alternative**: [If third-party]
- Alternative: [Azure/M365/Power Platform service]
- Estimated Cost: $XXX/month
- Migration Effort: [LOW/MEDIUM/HIGH]
- Potential Savings: $XXX/month

---

[Repeat for each software tool linked to the build]

---

## Cost Summary by Category

| Category | Monthly Cost | Annual Cost | Tools | % of Total |
|----------|--------------|-------------|-------|------------|
| Development | $XXX | $X,XXX | X | XX% |
| Infrastructure | $XXX | $X,XXX | X | XX% |
| AI/ML | $XXX | $X,XXX | X | XX% |
| Analytics | $XXX | $X,XXX | X | XX% |
| Other | $XXX | $X,XXX | X | XX% |
| **TOTAL** | **$X,XXX** | **$XX,XXX** | **X** | **100%** |

---

## Microsoft Ecosystem Analysis

**Microsoft Services**: $XXX/month (XX% of build cost)
- Azure: $XXX/month
- M365: $XXX/month
- Power Platform: $XXX/month
- GitHub: $XXX/month
- Other Microsoft: $XXX/month

**Third-Party Tools**: $XXX/month (XX% of build cost)
- [Tool 1]: $XXX/month
- [Tool 2]: $XXX/month
- [Tool 3]: $XXX/month

**Ecosystem Consolidation Opportunity**:
- Current third-party spend: $XXX/month
- Microsoft alternative options: $XXX/month
- Potential savings: $XXX/month ($X,XXX/year)

---

## Cost by Criticality

**Critical Tools** (Cannot remove without major impact):
- Monthly: $XXX ([X] tools)
- Annual: $X,XXX
- Examples: [Tool names]

**Important Tools** (Significant value, alternatives possible):
- Monthly: $XXX ([X] tools)
- Annual: $X,XXX
- Examples: [Tool names]

**Nice to Have** (Enhancement, not essential):
- Monthly: $XXX ([X] tools)
- Annual: $X,XXX
- Examples: [Tool names]
- **Optimization Opportunity**: Consider removing to reduce build cost

---

## Shared vs Dedicated Cost Analysis

### Dedicated to This Build (100% allocation)
- [Software Name]: $XXX/month - Only used for this build
- [Software Name]: $XXX/month - Only used for this build

**Total Dedicated**: $XXX/month ($X,XXX/year)

### Shared Across Projects (Allocated cost)
- [Software Name]: $XXX/month total, used by [X] projects
  - Allocated to this build: $XXX/month ([XX%] of usage)
- [Software Name]: $XXX/month total, used by [X] projects
  - Allocated to this build: $XXX/month ([XX%] of usage)

**Total Shared (Full Cost)**: $XXX/month ($X,XXX/year)
**Allocated to This Build**: $XXX/month ($X,XXX/year)

**Note**: Total build cost uses full shared costs, not allocated. Allocated costs shown for reference only.

---

## Build Lifecycle Cost Projection

### Development Phase (Current: [Active/Completed])
**Monthly Burn Rate**: $X,XXX
**Phase Duration**: [X months]
**Phase Total**: $XX,XXX

### Production Phase (If applicable)
**Estimated Monthly Cost**: $XXX
- Reduced licenses: [Assumptions]
- Infrastructure scaling: [Assumptions]

**Annual Production Cost**: $X,XXX

### Total Build Investment
**Development Cost**: $XX,XXX ([X months] at $X,XXX/month)
**Production Cost (Year 1)**: $X,XXX (if deployed)
**3-Year TCO**: $XX,XXX

---

## Cost Optimization Opportunities

### Immediate Savings (Low Effort)

1. **Remove [Nice-to-Have Tool]** - Save $XXX/month
   - Current: $XXX/month
   - Impact: Minimal - used for [non-essential feature]
   - Risk: LOW
   - Action: Update Software Tracker, remove relation

2. **Downgrade [Tool] tier** - Save $XXX/month
   - Current: [Tier] at $XXX/month
   - Using: [XX%] of features
   - Proposed: [Lower tier] at $XXX/month
   - Risk: LOW

**Total Immediate Savings**: $XXX/month ($X,XXX/year)

### Strategic Optimization (Medium Effort)

1. **Migrate [Third-Party Tool] → [Microsoft Service]** - Save $XXX/month
   - Current: $XXX/month
   - Microsoft alternative: $XXX/month
   - Migration effort: [X weeks]
   - Savings: $XXX/month ($X,XXX/year)
   - Benefits: [Ecosystem integration advantages]

2. **Consolidate with [Other Build]** - Share costs
   - Current: Each build pays $XXX/month
   - Consolidated: Shared $XXX/month license
   - Per-build savings: $XXX/month

**Total Strategic Savings**: $XXX/month ($X,XXX/year)

### Long-Term Optimization (High Effort)

1. **Re-architect to reduce [Expensive Service] dependency**
   - Current: $XXX/month
   - Alternative approach: $XXX/month
   - Savings: $XXX/month ($X,XXX/year)
   - Effort: [Significant refactoring required]

**Total Long-Term Savings**: $XXX/month ($X,XXX/year)

---

## Comparison to Similar Builds

### Build Cost Benchmarking

**This Build**: $X,XXX/month
- Type: [Prototype/POC/Demo/MVP]
- Complexity: [Simple/Medium/Complex]
- Cost Efficiency: [BELOW/AT/ABOVE average]

**Similar Builds Average**: $XXX/month
- [Build A]: $XXX/month ([Type])
- [Build B]: $XXX/month ([Type])
- [Build C]: $XXX/month ([Type])

**Analysis**:
- [This build is XX% more/less expensive than average]
- [Key cost drivers: Specific expensive tools]
- [Optimization recommendation based on comparison]

---

## Related Project Costs

### Origin Idea: [Idea Name]
**Total Idea Cost**: $X,XXX/month (all linked software)
- This build's portion: $X,XXX/month ([XX%])
- Other builds from this idea: $XXX/month
- Research costs: $XXX/month

### Related Research: [Research Name]
**Research Cost**: $XXX/month
- Overlap with this build: [X] shared tools
- Research-specific tools: $XXX/month

### Knowledge Created
If build status = Completed/Archived:
- Knowledge Vault entries: [X] linked
- Reusability potential: [Assessment]
- Value: Build cost of $XX,XXX generated [X] reusable assets

---

## ROI Considerations

**Total Investment**: $XX,XXX ([X months] of development)
**Reusability**: [Highly Reusable/Partially Reusable/One-Off]

**Value Created**:
- Lessons learned documented: [Yes/No - Link to Knowledge Vault]
- Reusable components: [List key components]
- Future builds that can leverage: [Estimate]

**Cost Avoidance**:
- If this build is reused by [X] future projects: $XX,XXX saved (avoid rebuilding)
- Knowledge captured prevents redundant research: $X,XXX value

---

## Decision Support

### If Build Status = Concept or Active

**Continue or Optimize?**
- Current monthly burn: $X,XXX
- Optimization potential: $XXX/month (XX% reduction)
- Recommended action: [Continue as-is / Optimize tools / Reconsider approach]

### If Build Status = Completed

**Maintain or Archive?**
- Current monthly cost: $X,XXX
- Active usage: [Assessment based on linked projects]
- Recommended action: [Keep active / Reduce to maintenance mode / Archive and cancel services]

**Maintenance Mode Costs**:
- Reduced to minimal infrastructure: $XXX/month
- Savings vs full build: $XXX/month

### If Build Status = Archived

**Software Cleanup**:
- Build-specific tools to cancel: [List]
- Potential savings: $XXX/month
- Action: Update Software Tracker Status to "Inactive" for unused tools

---

**Cost Management Actions**:
1. Review optimization opportunities with build team
2. Update Software Tracker links if tools have changed
3. Implement immediate savings (remove nice-to-have tools)
4. Plan strategic migrations to Microsoft ecosystem
5. Document cost lessons in Knowledge Vault
6. Compare to budget/expectations, adjust if needed

**Next Steps**:
- Run `/consolidation-opportunities` to identify shared tool optimization
- Run `/microsoft-alternatives [tool-name]` for specific replacements
- Run `/research-costs [research-name]` to analyze related research expenses
- Update Build documentation with cost information
```

## Supported Variants

```bash
# Specific build
/build-costs [Build Name]
/build-costs "AI Content Generator Prototype"

# All builds summary
/build-costs all

# Builds by status
/build-costs active
/build-costs completed
/build-costs archived

# Builds by cost threshold
/build-costs high-cost    # Only builds >$1,000/month
/build-costs low-cost     # Builds <$500/month

# Builds by type
/build-costs prototypes
/build-costs mvp

# Cost comparison
/build-costs compare [Build1] vs [Build2]
```

## Best for
Organizations requiring transparent project-level cost visibility to support build/buy/optimize decisions, resource allocation, and demonstration of ROI for innovation investments through comprehensive software cost tracking.
