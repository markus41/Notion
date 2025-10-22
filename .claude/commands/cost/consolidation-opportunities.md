# /consolidation-opportunities - Identify Tool Overlap & Consolidation Potential

Detect multiple tools serving similar purposes and recommend consolidation strategies to reduce complexity, lower costs, and streamline workflows through Microsoft ecosystem integration.

## Calculation Logic

```
1. Query Software Tracker database
2. Filter WHERE Status = "Active"
3. Group tools by functionality patterns:
   - Category overlap (multiple tools in same category)
   - Description/purpose similarity analysis
   - User overlap (same team members using multiple similar tools)
4. For each potential consolidation:
   - Calculate combined current cost
   - Research Microsoft alternative
   - Estimate consolidated cost
   - Calculate savings potential
   - Assess migration complexity
5. Identify consolidation types:
   - DUPLICATE: Multiple tools doing exactly the same thing
   - OVERLAP: Tools with significant functional overlap
   - FRAGMENTATION: Similar needs spread across many tools
   - MICROSOFT OPPORTUNITY: Third-party tools replaceable by Microsoft services
6. Rank by savings potential and implementation feasibility
7. Calculate total consolidation savings
```

## Output Format

```
🔗 Software Consolidation Opportunities

**Total Consolidation Potential**: $X,XXX/month ($XX,XXX/year)
**Opportunities Identified**: X consolidations
**Analysis Date**: [Current Date]

**Strategic Priority**: Streamline tool portfolio to reduce complexity, improve integration, and drive cost efficiency through Microsoft ecosystem consolidation.

---

## High-Impact Consolidations (>$500/month savings potential)

### 1. [Consolidation Name]: Consolidate [Tool A] + [Tool B] + [Tool C]

**Current State**:
- **[Tool A]**: $XXX/month (X licenses) - [Category]
  - Users: [Names]
  - Linked Projects: [Count]
  - Primary Use: [Description]

- **[Tool B]**: $XXX/month (X licenses) - [Category]
  - Users: [Names]
  - Linked Projects: [Count]
  - Primary Use: [Description]

- **[Tool C]**: $XXX/month (X licenses) - [Category]
  - Users: [Names]
  - Linked Projects: [Count]
  - Primary Use: [Description]

**Total Current Cost**: $XXX/month ($X,XXX/year)

**Consolidation Type**: [DUPLICATE/OVERLAP/FRAGMENTATION/MICROSOFT OPPORTUNITY]

**Overlap Analysis**:
- Functionality Overlap: XX%
- User Overlap: [X out of X team members use both/all]
- Use Case Overlap: [Specific overlapping use cases]

**Recommended Solution**:
**Migrate to: [Microsoft Service Name] / [Single Consolidated Tool]**

**Proposed Configuration**:
- Service/Tool: [Name]
- Tier/SKU: [Specific tier]
- Licenses Needed: X seats
- Estimated Cost: $XXX/month ($X,XXX/year)

**Savings Calculation**:
- Current Combined Cost: $XXX/month
- Proposed Cost: $XXX/month
- **Monthly Savings**: $XXX
- **Annual Savings**: $X,XXX
- **Savings Percentage**: XX%

**Microsoft Ecosystem Benefits**:
- [Integration with Azure/M365/Power Platform]
- [SSO/Authentication simplification]
- [Unified billing and management]
- [Data residency and compliance]

**Migration Complexity**: [LOW/MEDIUM/HIGH]
- Timeline Estimate: [X weeks/months]
- Technical Effort: [Description]
- Training Required: [Description]
- Risk Factors: [List key risks]

**Implementation Steps**:
1. [Specific step with responsible party]
2. [Specific step with responsible party]
3. [Specific step with responsible party]
4. [Verification step]

**Affected Projects**:
- [Idea/Research/Build Name]: [Migration notes]
- [Idea/Research/Build Name]: [Migration notes]

**Team Impact**:
- [Team Member]: [Change description]
- [Team Member]: [Change description]

**Recommendation**: [IMMEDIATE/PLANNED/EVALUATE]
- Priority: [HIGH/MEDIUM/LOW]
- Decision Owner: [Name]
- Review by: [Date]

---

[Repeat structure for each high-impact consolidation]

---

## Medium-Impact Consolidations ($100-$500/month savings)

### [Consolidation Name] - $XXX/month savings potential
- Current: [Tool A] ($XXX) + [Tool B] ($XXX)
- Proposed: [Microsoft Service / Alternative]
- Savings: $XXX/month ($X,XXX/year)
- Complexity: [LOW/MEDIUM/HIGH]
- Recommendation: [Action]

[List all medium-impact opportunities]

---

## Low-Impact Consolidations (<$100/month savings)

### [Consolidation Name] - $XX/month savings potential
- Current: [Tools]
- Proposed: [Solution]
- Savings: $XX/month ($XXX/year)
- Complexity: [Level]
- Recommendation: [May not be worth effort / Good for simplification]

[List all low-impact opportunities]

---

## Microsoft Ecosystem Migration Opportunities

Focus on third-party tools with strong Microsoft alternatives:

### Azure Migration Opportunities

**Current Third-Party Infrastructure**: $X,XXX/month
**Equivalent Azure Services**: $XXX/month
**Potential Savings**: $XXX/month ($X,XXX/year)

1. **Migrate [Third-Party Hosting] → Azure App Services**
   - Current: $XXX/month
   - Azure: $XXX/month
   - Savings: $XXX/month
   - Benefits: [Integration, scaling, compliance]

2. **Migrate [Third-Party Database] → Azure SQL Database**
   - Current: $XXX/month
   - Azure: $XXX/month
   - Savings: $XXX/month
   - Benefits: [Backup, security, integration]

[List all Azure opportunities]

### M365 Ecosystem Opportunities

**Current Third-Party Productivity Tools**: $XXX/month
**M365 Included Services**: $0 additional (already licensed)
**Potential Savings**: $XXX/month ($X,XXX/year)

1. **Replace [Tool] with Microsoft Teams / SharePoint / OneNote**
   - Current: $XXX/month
   - M365: Already included
   - Savings: $XXX/month (100%)
   - Migration: [Complexity level]

[List all M365 opportunities]

### Power Platform Opportunities

**Current Third-Party Low-Code Tools**: $XXX/month
**Power Platform Alternative**: $XXX/month
**Potential Savings**: $XXX/month ($X,XXX/year)

1. **Replace [Tool] with Power Apps / Power Automate**
   - Current: $XXX/month
   - Power Platform: $XXX/month
   - Savings: $XXX/month
   - Benefits: [Dataverse integration, unified platform]

[List all Power Platform opportunities]

---

## License Optimization Opportunities

Consolidate user licenses across tools:

### Shared License Pools
1. **[Software Name]**: Currently X individual licenses at $XX each
   - Actual simultaneous users: [Typically X]
   - Opportunity: Shift to X floating licenses
   - Savings: $XXX/month

### Bulk Discount Opportunities
1. **Consolidate [Category] tools**: X separate subscriptions
   - Current total: $XXX/month
   - Bulk licensing option: $XXX/month
   - Savings: $XXX/month

---

## Category-Specific Consolidation Analysis

### Development Tools
- Current tools: [X] at $X,XXX/month
- Consolidation opportunities: [X] identified
- Potential savings: $XXX/month
- Microsoft GitHub Enterprise coverage: [Coverage analysis]

### Communication & Collaboration
- Current tools: [X] at $XXX/month
- Consolidation opportunities: [X] identified
- Potential savings: $XXX/month
- Microsoft Teams coverage: [Coverage analysis]

### Infrastructure
- Current tools: [X] at $X,XXX/month
- Consolidation opportunities: [X] identified
- Potential savings: $XXX/month
- Azure coverage: [Coverage analysis]

[Repeat for each category]

---

## Implementation Roadmap

### Phase 1: Quick Wins (0-3 months)
**Target Savings**: $XXX/month ($X,XXX/year)

1. **[Consolidation Name]** - [Timeline]
   - Savings: $XXX/month
   - Complexity: LOW
   - Owner: [Name]
   - Start: [Date]

[List all Phase 1 items]

### Phase 2: Strategic Migrations (3-6 months)
**Target Savings**: $XXX/month ($X,XXX/year)

1. **[Consolidation Name]** - [Timeline]
   - Savings: $XXX/month
   - Complexity: MEDIUM
   - Owner: [Name]
   - Dependencies: [Phase 1 completions]

[List all Phase 2 items]

### Phase 3: Complex Consolidations (6-12 months)
**Target Savings**: $XXX/month ($X,XXX/year)

1. **[Consolidation Name]** - [Timeline]
   - Savings: $XXX/month
   - Complexity: HIGH
   - Owner: [Name]
   - Dependencies: [Earlier phases]

[List all Phase 3 items]

---

## Risk Assessment & Mitigation

### High-Risk Consolidations
1. **[Consolidation Name]**
   - Risk: [Specific risk]
   - Mitigation: [Specific mitigation strategy]
   - Fallback Plan: [What to do if it fails]

### Medium-Risk Consolidations
1. **[Consolidation Name]**
   - Risk: [Specific risk]
   - Mitigation: [Specific mitigation strategy]

---

## Total Consolidation Value

**Immediate Opportunities (Low Complexity)**:
- Monthly Savings: $XXX
- Annual Savings: $X,XXX
- Implementation Time: [X] weeks

**Medium-Term Opportunities (Medium Complexity)**:
- Monthly Savings: $XXX
- Annual Savings: $X,XXX
- Implementation Time: [X] months

**Strategic Opportunities (High Complexity)**:
- Monthly Savings: $XXX
- Annual Savings: $X,XXX
- Implementation Time: [X] months

**TOTAL CONSOLIDATION POTENTIAL**:
- Monthly Savings: $X,XXX
- Annual Savings: $XX,XXX
- Percentage of Current Spend: XX%

---

## Decision Framework

**Evaluate each consolidation using**:
1. **Financial Impact**: Savings vs implementation cost
2. **Strategic Alignment**: Microsoft ecosystem preference
3. **User Impact**: Training and change management needs
4. **Technical Risk**: Migration complexity and dependencies
5. **Timeline**: Urgency and resource availability

**Prioritization Matrix**:
- High Savings + Low Complexity = IMMEDIATE
- High Savings + High Complexity = PLANNED (roadmap)
- Low Savings + Low Complexity = EVALUATE (worth the effort?)
- Low Savings + High Complexity = DEFER (not worth it)

---

**Next Steps**:
1. Review consolidation opportunities with team
2. Select Phase 1 quick wins for immediate action
3. Create detailed migration plans for strategic consolidations
4. Update Software Tracker with consolidation decisions
5. Schedule regular reviews to track progress
6. Run `/microsoft-alternatives` for specific tool replacements
7. Document lessons learned in Knowledge Vault
```

## Supported Variants

```bash
# All consolidations (default)
/consolidation-opportunities

# Specific category
/consolidation-opportunities Development
/consolidation-opportunities Infrastructure

# By savings potential
/consolidation-opportunities high-impact
/consolidation-opportunities quick-wins

# Microsoft-specific
/consolidation-opportunities microsoft-only
```

## Best for
Organizations seeking to streamline software portfolios, reduce tool sprawl, and drive cost efficiency through strategic consolidation while prioritizing Microsoft ecosystem integration for improved productivity and sustainable growth.
