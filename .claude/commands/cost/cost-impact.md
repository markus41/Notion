# /cost-impact - Quick Cost Impact Assessment for Changes

Instantly calculate the budget impact of proposed software additions, cancellations, or license changes to support rapid decision-making and maintain cost transparency.

## Calculation Logic

```
1. Identify change type:
   - ADD: New software subscription
   - REMOVE: Cancel existing software
   - MODIFY: Change licenses or tier
   - CONVERT: Trial to Active conversion
2. For ADD/CONVERT:
   - Get proposed cost and license count
   - Calculate Total Monthly Cost (Cost × Licenses)
   - Calculate Annual Cost (Monthly × 12)
   - Check if Microsoft service
   - Identify category
   - Compare to similar existing tools (duplication check)
3. For REMOVE:
   - Get current Total Monthly Cost
   - Calculate savings (monthly and annual)
   - Check linked projects (impact assessment)
   - Identify replacement if needed
4. For MODIFY:
   - Calculate current cost
   - Calculate new cost
   - Calculate delta
5. Show immediate impact and cumulative effect on total spend
6. Flag risks and recommend decision
```

## Output Format

```
💵 Quick Cost Impact Assessment

**Change Type**: [ADD/REMOVE/MODIFY/CONVERT]
**Software**: [Software Name]
**Analysis Date**: [Current Date]

---

## Proposed Change

[For ADD]:
**Adding: [Software Name]**

**Proposed Details**:
- Cost: $XXX/month per license
- Licenses: X seats
- Category: [Category]
- Microsoft Service: [Yes/No - Service Name if yes]
- Owner: [Team Member]
- Criticality: [Critical/Important/Nice to Have]
- Linked Projects: [Idea/Research/Build names]

**Justification**: [Brief reason for addition]

---

[For REMOVE]:
**Removing: [Software Name]**

**Current Details**:
- Cost: $XXX/month (X licenses at $XX each)
- Category: [Category]
- Status: [Active/Trial]
- Linked Projects: [X] active ([Names])
- Users: [Team members]

**Reason for Removal**: [Unused/Duplicate/Replaced/Cost optimization]
**Replacement**: [What will replace it, if anything]

---

[For MODIFY]:
**Modifying: [Software Name]**

**Current State**:
- Licenses: X seats at $XX each = $XXX/month
- Tier: [Current tier]

**Proposed State**:
- Licenses: X seats at $XX each = $XXX/month
- Tier: [New tier]

**Change Reason**: [Right-sizing/Downgrade/Upgrade/Team growth]

---

[For CONVERT]:
**Converting Trial to Active: [Software Name]**

**Trial Details**:
- Trial End Date: [Date]
- Trial Cost: $0/month
- Active Cost: $XXX/month (X licenses)
- Days Remaining: [X]

**Conversion Decision**: [Convert/Cancel before trial ends]

---

## Cost Impact

### Monthly Impact

**Current Total Monthly Spend**: $X,XXX

[For ADD or CONVERT]:
**New Cost**: +$XXX/month
- Software cost: $XXX/month
- [Additional costs if any]

**New Total Monthly Spend**: $X,XXX (+X%)

[For REMOVE]:
**Savings**: -$XXX/month
- Software cost: -$XXX/month
- [Other savings if any]

**New Total Monthly Spend**: $X,XXX (-X%)

[For MODIFY]:
**Change**: [+/-]$XXX/month
- Previous: $XXX/month
- New: $XXX/month
- Delta: [+/-]$XXX/month

**New Total Monthly Spend**: $X,XXX ([+/-]X%)

---

### Annual Impact

**Annual Cost**: [+/-]$X,XXX
**3-Year TCO**: [+/-]$XX,XXX

**Cumulative Budget Impact**:
- Year 1: [+/-]$X,XXX
- Year 2: [+/-]$X,XXX (assuming no price changes)
- Year 3: [+/-]$X,XXX

---

### Category Impact

**Current [Category] Spend**: $X,XXX/month
**New [Category] Spend**: $X,XXX/month ([+/-]X%)

[Category] now represents [XX%] of total spend ([up/down] from XX%)

---

### Microsoft Ecosystem Impact

**Current Microsoft Services**: $X,XXX/month (XX% of total)
**New Microsoft Services**: $X,XXX/month (XX% of total)

[If adding Microsoft service]:
✅ Increases Microsoft ecosystem consolidation by [X] percentage points

[If adding third-party]:
⚠️ Decreases Microsoft ecosystem consolidation by [X] percentage points
- Microsoft alternative available: [Yes/No - Service name if yes]
- Consider: [Microsoft option] at $XXX/month instead

---

## Impact Assessment

### Budget Thresholds

**Monthly Impact**: [+/-]$XXX
- Significance: [MINOR <$100 / MODERATE $100-$500 / MAJOR >$500]
- Budget status: [WITHIN LIMITS / REQUIRES REVIEW / EXCEEDS THRESHOLD]

**Approval Required**: [YES/NO]
- If >$500/month: Requires [Decision Maker] approval
- If <$500/month: Team-level decision

---

### Project Impact

[For ADD/CONVERT]:
**Enables**:
- [Idea Name]: [How this enables the idea]
- [Research Name]: [How this supports research]
- [Build Name]: [How this supports the build]

**Without this software**:
[Impact if not added]

[For REMOVE]:
**Affected Projects**: [X] active
1. **[Project Name]**
   - Impact: [HIGH/MEDIUM/LOW]
   - Mitigation: [How to handle this project without the software]

**User Impact**: [X] team members affected
- [Name]: [Specific impact]
- [Name]: [Specific impact]

**Mitigation Plan**: [What will replace this functionality]

---

### Risk Assessment

**Risk Level**: [LOW/MEDIUM/HIGH]

[For ADD]:
**Risks**:
- Duplicate functionality: [Check if we already have similar tool]
- Lock-in: [Vendor lock-in concerns]
- Utilization: [Will we actually use all X licenses?]
- Integration: [Compatibility with existing tools]

**Mitigation**:
- [Strategy for each risk]

[For REMOVE]:
**Risks**:
- Service disruption: [X] active projects affected
- User productivity: [X] team members need alternative
- Data migration: [Effort to migrate data if applicable]

**Mitigation**:
- [Migration plan]
- [Timeline for transition]
- [Training on alternative]

---

## Duplication Check

[For ADD - check existing software]

**Similar Existing Tools**:
1. **[Existing Software Name]** - $XXX/month
   - Category: [Same category]
   - Overlap: [What features overlap]
   - Could this meet the need?: [Yes/No - Why]

[If duplication found]:
⚠️ **Duplication Alert**: We already have [X] tool(s) in this category

**Consolidation Opportunity**:
- Instead of adding [New Tool] at $XXX/month
- Consider: Expanding use of [Existing Tool] (add X licenses at $XX each = $XXX/month)
- Savings: $XXX/month

**OR**

- Replace [Existing Tool] ($XXX/month) with [New Tool] ($XXX/month)
- Net impact: [+/-]$XXX/month
- Benefits: [Why new tool is better]

[If no duplication]:
✅ **No Similar Tools Found**: This is a new capability

---

## Microsoft Alternative Check

[For ADD - if third-party tool]

**Microsoft Alternative Available**: [Yes/No]

[If Yes]:
**Microsoft Option**: [Azure/M365/Power Platform/GitHub service name]
- Cost: $XXX/month
- Comparison to proposed tool:
  - Feature parity: [EQUIVALENT/BETTER/WORSE]
  - Integration: [SUPERIOR/EQUIVALENT/WORSE]
  - Cost: [CHEAPER/SAME/MORE EXPENSIVE]

**Recommendation**: [Use Microsoft alternative / Proceed with third-party]
**Justification**: [Clear reasoning]

[If proceeding with third-party despite Microsoft alternative]:
**Documented Reason**: [Why third-party is necessary]

---

## Recommendation

**Recommended Action**: [APPROVE/REJECT/MODIFY/DEFER]

### [If APPROVE]:
✅ **Approve Addition**
- Budget impact acceptable: [+/-]$XXX/month
- Clear business need: [Description]
- No better alternative: [Checked Microsoft ecosystem]
- Risk: [LOW/MEDIUM] with mitigation plan

**Implementation Steps**:
1. [Add to Software Tracker with Status = "Active"]
2. [Purchase/subscribe to software]
3. [Link to relevant Ideas/Research/Builds]
4. [Set up contract end date and calendar reminder]
5. [Onboard users and provide training]

---

### [If REJECT]:
❌ **Reject Addition**
- Reason: [Duplicate functionality / Excessive cost / Better alternative available]
- Alternative: [What to do instead]
  - Use existing [Tool Name] instead (no additional cost)
  - Use Microsoft [Service] at $XXX/month (cheaper and better integrated)
  - Defer until [condition met]

---

### [If APPROVE REMOVAL]:
✅ **Approve Removal**
- Savings: $XXX/month ($X,XXX/year)
- Risk: [LOW - No active projects affected / Mitigation in place]
- Timeline: [Cancel immediately / Cancel at contract end on [Date]]

**Cleanup Steps**:
1. [Update Software Tracker Status to "Cancelled"]
2. [Remove relations to Ideas/Research/Builds]
3. [Cancel subscription or set non-renewal]
4. [Communicate to users]
5. [Migrate data if applicable]
6. [Verify savings in next month's spend analysis]

---

### [If MODIFY]:
✅ **Approve Modification**
- Impact: [+/-]$XXX/month
- Justification: [Right-sizing based on actual usage]
- Risk: [LOW/MEDIUM]

**Modification Steps**:
1. [Update Software Tracker with new license count/tier]
2. [Adjust subscription with vendor]
3. [Communicate changes to users]
4. [Monitor to ensure sufficient capacity]

---

### [If DEFER]:
⏸️ **Defer Decision**
- Reason: [Need more information / Waiting for budget approval / Evaluating alternatives]
- Information needed: [Specific questions to answer]
- Decision deadline: [Date]
- Responsible: [Team Member]

---

## Decision Record

**Date**: [Current Date]
**Decision**: [Approve/Reject/Modify/Defer]
**Decision Maker**: [Team Member]
**Implementation Date**: [Date]
**Follow-up Date**: [Date to review impact]

**Notes**:
[Any additional context or conditions]

---

## Quick Reference: Total Spend Impact

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Monthly Spend | $X,XXX | $X,XXX | [+/-]$XXX ([+/-]XX%) |
| Annual Spend | $XX,XXX | $XX,XXX | [+/-]$X,XXX ([+/-]XX%) |
| Active Tools | X | X | [+/-]X |
| Microsoft % | XX% | XX% | [+/-]X pts |
| Cost per Team Member | $XXX | $XXX | [+/-]$XX |

**Budget Status**: [WITHIN BUDGET / APPROACHING THRESHOLD / EXCEEDS BUDGET]

---

**Next Actions**:
1. [Immediate next step based on decision]
2. Update Software Tracker if approved
3. Set calendar reminder for contract review
4. Run `/monthly-spend` next month to verify impact
5. Document decision in relevant project pages
```

## Supported Variants

```bash
# Adding new software
/cost-impact add "[Software Name]" $XXX/month [X] licenses

# Removing software
/cost-impact remove "[Software Name]"

# Modifying licenses
/cost-impact modify "[Software Name]" from [X] to [Y] licenses

# Converting trial
/cost-impact convert "[Software Name]"

# Quick check without full analysis
/cost-impact quick "[Software Name]" $XXX/month
```

## Best for
Organizations requiring rapid cost impact assessments to support day-to-day software decisions, maintain budget discipline, and ensure transparent evaluation of additions, cancellations, or modifications to the software portfolio.
