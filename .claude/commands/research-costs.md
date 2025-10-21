# /research-costs - Research Thread Cost Analysis & Budget Tracking

Calculate comprehensive software costs for active research threads by aggregating all linked tools and services to provide transparent research budget visibility and support informed feasibility decisions.

## Calculation Logic

```
1. Query Software Tracker database
2. For specified research thread (or all research if no argument):
   - Get all software linked to the Research Hub entry
   - For each linked software:
     - Get Total Monthly Cost (Cost × License Count)
     - Get Annual Cost (Total Monthly Cost × 12)
     - Get Criticality level
     - Get Category
     - Check if Microsoft Service
3. Calculate research-specific costs:
   - Total Monthly Cost = SUM(all linked software monthly costs)
   - Total Annual Cost = Total Monthly × 12
4. Calculate research duration costs:
   - If research has started/completed dates, calculate total spent
   - If active, project remaining costs
5. Compare costs to:
   - Origin Idea costs
   - Viability Assessment (is research worth the cost?)
   - Potential build costs if research leads to prototype
6. Break down by category and service type
7. Identify optimization opportunities
```

## Output Format

```
🔬 Research Cost Analysis: [Research Topic]

**Research Details**:
- Status: [Concept/Active/Not Active/Completed]
- Viability Assessment: [Highly Viable/Moderately Viable/Not Viable/Inconclusive]
- Next Steps: [Build Example/More Research/Archive/Abandon]
- Researchers: [Team Members]
- Hypothesis: [Brief statement]

---

## 💰 Total Research Cost

**Monthly Software Cost**: $XXX
**Research Duration**: [X months] [Estimated/Actual]
**Total Research Investment**: $X,XXX

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

**Research Usage**:
- Primary Use: [What this research uses it for]
- Researchers: [Team members using for this research]
- Necessity: [ESSENTIAL / HELPFUL / OPTIONAL]

**Shared or Dedicated**:
- Also used by: [X other research / Ideas / Builds]
- Allocation: [100% this research / Shared across [X] projects]

**Cost Efficiency**:
- Free tier available: [Yes/No]
- Free tier sufficient: [Yes/No - If no, why]
- Alternative: [Cheaper option if exists]

---

[Repeat for each software tool linked to the research]

---

## Cost Summary by Category

| Category | Monthly Cost | Research Total | Tools | % of Total |
|----------|--------------|----------------|-------|------------|
| Research Tools | $XXX | $X,XXX | X | XX% |
| AI/ML Services | $XXX | $X,XXX | X | XX% |
| Analytics | $XXX | $X,XXX | X | XX% |
| Infrastructure | $XXX | $X,XXX | X | XX% |
| Other | $XXX | $X,XXX | X | XX% |
| **TOTAL** | **$XXX** | **$X,XXX** | **X** | **100%** |

---

## Research Timeline & Cost Projection

### Research Phases

**Phase 1: Initial Investigation** ([Duration])
- Monthly cost: $XXX
- Phase total: $X,XXX
- Status: [Completed/Active/Upcoming]

**Phase 2: Deep Dive Analysis** ([Duration])
- Monthly cost: $XXX (tools added: [List])
- Phase total: $X,XXX
- Status: [Completed/Active/Upcoming]

**Phase 3: Viability Assessment** ([Duration])
- Monthly cost: $XXX
- Phase total: $XXX
- Status: [Completed/Active/Upcoming]

### Cost Summary by Phase
- **Total Spent to Date**: $X,XXX ([X months] completed)
- **Projected Remaining**: $XXX ([X months] estimated)
- **Total Research Budget**: $X,XXX

---

## Microsoft Ecosystem Analysis

**Microsoft Services**: $XXX/month (XX% of research cost)
- Azure: $XXX/month (e.g., Azure OpenAI, Cognitive Services)
- M365: $XXX/month (e.g., SharePoint, OneNote for documentation)
- Power Platform: $XXX/month (e.g., Power BI for analysis)
- Other Microsoft: $XXX/month

**Third-Party Tools**: $XXX/month (XX% of research cost)
- [Tool 1]: $XXX/month
- [Tool 2]: $XXX/month
- [Tool 3]: $XXX/month

**Ecosystem Optimization**:
- Microsoft alternatives available: [Yes/No - List if yes]
- Potential savings: $XXX/month
- Research-phase note: [May be worth keeping third-party for evaluation]

---

## Cost Efficiency Analysis

### Research ROI Assessment

**Total Research Investment**: $X,XXX ([X months])
**Viability Assessment**: [Highly Viable/Moderately Viable/Not Viable/Inconclusive]

**Value Generated**:
- Key Findings Documented: [Yes/No]
- Prototypes Created: [Count]
- Knowledge Vault Entries: [Count]
- Reusable Insights: [High/Medium/Low]

**Cost vs Value**:
[If Highly Viable]:
- Investment: $X,XXX
- Next phase: Build prototype (estimated $X,XXX)
- Justified: [Yes - Strong viability / Reconsider - High cost for uncertain outcome]

[If Not Viable]:
- Investment: $X,XXX
- Outcome: Determined not viable (valuable negative result)
- Lessons learned: [Key takeaways documented in Knowledge Vault]
- Decision: Archive research, cancel dedicated tools (save $XXX/month)

[If Inconclusive]:
- Investment to date: $X,XXX
- Estimated additional: $XXX ([X more months])
- Decision point: Continue or pivot? (Cost-benefit assessment)

---

## Related Project Costs

### Origin Idea: [Idea Name]
**Total Idea Cost**: $X,XXX/month (all linked software)
- This research's portion: $XXX/month ([XX%])
- Other research from this idea: $XXX/month
- Builds from this idea: $X,XXX/month

**Idea-Level Investment**:
- Total spent on idea (research + builds): $XX,XXX
- Viability status: [Assessment]

### Related Builds
[If Next Steps = "Build Example" or builds already exist]

**Existing Builds**:
- [Build Name]: $X,XXX/month
- Tool overlap with research: [X] shared tools
- New tools needed for build: [Estimate]

**Projected Build Cost** (if moving to prototype):
- Research tools still needed: $XXX/month
- Additional build tools: $XXX/month (estimated)
- **Total Build Cost Estimate**: $X,XXX/month

---

## Cost Optimization Opportunities

### For Active Research

1. **Use Free Tiers Where Possible** - Save $XXX/month
   - [Tool]: Currently paid ($XXX/month), free tier available
   - Free tier limits: [Details]
   - Sufficient for research: [Yes/No]
   - Risk: Minimal for research phase

2. **Time-box Expensive Tools** - Save $XXX
   - [Tool]: $XXX/month, only needed for [specific phase]
   - Proposed: Use for [X weeks] only, then cancel
   - Savings: $XXX over research duration

3. **Share Licenses with Other Research** - Save $XXX/month
   - [Tool]: Currently X dedicated licenses
   - Other research also using: [Research Name]
   - Proposed: Consolidate to X shared licenses
   - Savings: $XXX/month

**Total Optimization Potential**: $XXX/month ($XXX over research duration)

### For Completed Research

[If Status = Completed and Next Steps = Archive/Abandon]:

**Cancel Research-Specific Tools** - Save $XXX/month
1. [Tool]: $XXX/month - Only used for this research
   - Action: Update Software Tracker Status to "Inactive"
   - Impact: None (research complete)

2. [Tool]: $XXX/month - Shared with [X] other projects
   - Action: Remove relation, keep active
   - Impact: None on other projects

**Total Recoverable**: $XXX/month ($X,XXX/year)

---

## Research Cost Benchmarking

### Comparison to Similar Research

**This Research**: $XXX/month ([X months] = $X,XXX total)
- Topic: [Category/Domain]
- Complexity: [Simple/Medium/Complex]
- Cost Efficiency: [BELOW/AT/ABOVE average]

**Similar Research Threads Average**: $XXX/month
- [Research A]: $XXX/month ([X months]) - [Outcome]
- [Research B]: $XXX/month ([X months]) - [Outcome]
- [Research C]: $XXX/month ([X months]) - [Outcome]

**Analysis**:
- [This research is XX% more/less expensive than average]
- [Key cost drivers: Specific tools or long duration]
- [Recommendation based on comparison]

---

## Budget vs Actual Tracking

[If budget was set for research]

**Planned Budget**: $X,XXX
**Actual Spend**: $X,XXX
**Variance**: [Over/Under] by $XXX ([XX%])

**Variance Analysis**:
- [Primary drivers of over/under spending]
- [Lessons learned for future research budgets]
- [Action: Adjust remaining research budget / Request additional funds]

---

## Decision Support

### If Status = Active

**Continue, Pivot, or Stop?**

**Continue Research** (Current Path):
- Monthly cost: $XXX
- Estimated remaining: [X months]
- Additional investment: $X,XXX
- Confidence in outcome: [HIGH/MEDIUM/LOW]

**Pivot Research** (Adjust Scope):
- Reduce scope to focus on: [Specific aspect]
- Reduced cost: $XXX/month (save $XXX)
- Cancel: [Expensive tools no longer needed]

**Stop Research** (Cut Losses):
- Total invested: $X,XXX
- Sunk cost: Accept and archive
- Monthly savings: $XXX (cancel all research-specific tools)
- Justification: [Reason to stop - not viable / cost exceeds value / etc.]

**Recommendation**: [Action] based on [Reasoning]

### If Status = Completed

**Next Steps Assessment**:

[If Next Steps = Build Example]:
- Research investment: $X,XXX
- Estimated build cost: $X,XXX/month ([X months] = $XX,XXX)
- Total idea investment: $XX,XXX
- Proceed: [YES/RECONSIDER] based on [viability vs total cost]

[If Next Steps = Archive]:
- Research cost: $X,XXX
- Value: [Learnings documented, negative result is valuable]
- Action: Cancel research-specific tools (save $XXX/month)

[If Next Steps = More Research]:
- Investment to date: $X,XXX
- Additional estimated: $XXX
- Total: $X,XXX
- Threshold question: Is additional investment justified? [Assessment]

---

## Software Cleanup Actions

### If Research Completed or Abandoned

**Tools to Cancel** (Research-specific only):
1. [Software Name]: $XXX/month
   - Usage: Only this research
   - Action: Update Status to "Cancelled" in Software Tracker
   - Savings: $XXX/month

**Tools to Keep** (Shared with other projects):
1. [Software Name]: $XXX/month
   - Usage: Also used by [X] other projects
   - Action: Remove relation to this research only
   - Savings: $0 (still needed elsewhere)

**Total Monthly Savings from Cleanup**: $XXX ($X,XXX/year)

---

## Knowledge Capture & Value

**Documentation Created**:
- Research Hub entry: [Comprehensive/Partial/Minimal]
- SharePoint/OneNote documentation: [Link if available]
- Key Findings: [Documented/In Progress/Missing]
- Knowledge Vault entries: [X] created

**Reusability Potential**:
- Future research can leverage: [Methodology/Tools/Findings]
- Estimated value of captured knowledge: [Cost avoidance for future work]

**Lessons Learned**:
1. [Cost lesson - e.g., "Free tier of [Tool] sufficient for research"]
2. [Efficiency lesson - e.g., "Time-boxing expensive tools saved $XXX"]
3. [Process lesson - e.g., "Earlier viability checkpoint would have saved $XXX"]

---

**Cost Management Actions**:
1. Review research budget and timeline regularly
2. Update Software Tracker links as tools are added/removed
3. Consider free tiers and time-limited subscriptions for research
4. Document cost lessons in Knowledge Vault
5. Clean up research-specific tools when research completes
6. Compare actual vs estimated costs to improve future budgets

**Next Steps**:
- Run `/consolidation-opportunities` if multiple research threads exist
- Run `/microsoft-alternatives [tool-name]` for expensive third-party tools
- Run `/build-costs [build-name]` to analyze related prototype expenses
- Update Research Hub with cost information and optimization notes
```

## Supported Variants

```bash
# Specific research thread
/research-costs [Research Name]
/research-costs "AI Agent Feasibility Study"

# All research summary
/research-costs all

# Research by status
/research-costs active
/research-costs completed

# Research by cost threshold
/research-costs high-cost    # Only research >$500/month
/research-costs low-cost     # Research <$200/month

# Research by viability
/research-costs highly-viable
/research-costs not-viable

# Cost comparison
/research-costs compare [Research1] vs [Research2]
```

## Best for
Organizations requiring transparent research budget visibility to support informed feasibility decisions, optimize research spending, and demonstrate value of research investments through comprehensive software cost tracking and ROI analysis.
