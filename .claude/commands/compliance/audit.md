# Compliance Audit

Comprehensive compliance assessment for software licensing, data privacy, and third-party security across the Innovation Nexus ecosystem.

## Purpose

Conduct systematic compliance review to ensure adherence to software licensing obligations, data privacy regulations, and security best practices. This command establishes audit-ready evidence collection and generates actionable remediation plans to protect Brookside BI from regulatory risk while supporting sustainable innovation growth.

**Best for**: Organizations managing diverse software portfolios with licensing complexity, regulatory obligations (GDPR, CCPA), and third-party integrations requiring security oversight.

## Multi-Agent Coordination Strategy

Uses **parallel compliance assessment pattern** where domain-specific compliance checks execute in parallel, then synthesize findings for cross-domain optimization.

### Compliance Audit Architecture
```
┌──────────────────────────────────────────────────┐
│       Compliance Command Center                   │
│       (compliance-orchestrator)                   │
└────────────┬─────────────────────────────────────┘
             │
    ┌────────┼────────┬────────┬─────────┐
    ▼        ▼        ▼        ▼         ▼
Software  Data     Third-   Policy   Evidence
Licensing Privacy  Party    Review   Collection
                   Risk
```

## Execution Flow

### Phase 1: Compliance Scoping (0-10 mins)
1. **compliance-orchestrator** - Determine applicable compliance frameworks
2. **@cost-analyst** - Query Software & Cost Tracker for all active software
3. **@integration-specialist** - Query Integration Registry for third-party tools
4. **@knowledge-curator** - Assess Knowledge Vault for sensitive data classification
5. **@database-architect** - Review Notion database access controls

**Data Sources**:
- Software & Cost Tracker (`13b5e9de-2dd1-45ec-839a-4f3d50cd8d06`)
- Integration Registry
- Knowledge Vault
- Ideas Registry, Research Hub, Example Builds (for data handling analysis)

### Phase 2: Software Licensing Compliance Audit (10-30 mins)
6. **compliance-orchestrator** - Audit all software licenses against actual usage
7. **@cost-analyst** - Compare License Count vs. actual Users (identify over/under licensing)
8. **license-validator** - Validate open-source license compliance (MIT, Apache, GPL, etc.)
9. **contract-monitor** - Check contract expiration dates (flag renewals within 60 days)
10. **usage-analyzer** - Identify unused software (no relations to Ideas/Research/Builds)

**License Types Audited**:
- **Open Source**: MIT, Apache 2.0, GPL, AGPL (attribution requirements)
- **Commercial**: Per-user, per-device, enterprise (seat count compliance)
- **Freemium**: Usage limits, feature restrictions
- **Trial**: Time-limited licenses requiring conversion or cancellation

### Phase 3: Data Privacy Compliance Assessment (30-50 mins)
11. **data-privacy-auditor** - Assess GDPR applicability (EU clients/employees)
12. **ccpa-evaluator** - Assess CCPA applicability (California residents)
13. **knowledge-vault-scanner** - Classify sensitive data (PII, proprietary, financial)
14. **data-retention-validator** - Validate data retention policies
15. **consent-manager-auditor** - Check consent collection practices (if applicable)

**Privacy Frameworks**:
- **GDPR** (General Data Protection Regulation - EU): Applicable if processing EU resident data
- **CCPA** (California Consumer Privacy Act): Applicable if California resident data
- **Data Classification**: Public, Internal, Confidential, Restricted

### Phase 4: Third-Party Security Review (50-70 mins)
16. **integration-security-auditor** - Audit all Integration Registry entries
17. **authentication-validator** - Verify authentication methods (Azure AD > OAuth > API Key)
18. **encryption-validator** - Validate encryption standards (TLS 1.3, AES-256)
19. **vendor-risk-assessor** - Evaluate vendor security posture (SOC 2, ISO 27001 status)
20. **security-review-tracker** - Identify integrations with Pending/N/A security review status

**Security Review Status**:
- **Approved**: Security review complete, meets standards
- **Pending**: Security review in progress
- **N/A**: Security review not yet initiated ⚠️

### Phase 5: Policy & Documentation Review (70-90 mins)
21. **policy-completeness-checker** - Verify governance policy existence
22. **documentation-reviewer** - Assess policy documentation adequacy
23. **training-validator** - Check team security awareness (if training exists)
24. **procedure-validator** - Validate operational procedures

**Required Policies**:
- Software procurement policy
- Data classification and handling policy
- Acceptable use policy for tools
- Access control and least privilege policy
- Vendor management policy

### Phase 6: Evidence Collection & Gap Analysis (90-110 mins)
25. **evidence-collector** - Collect compliance evidence for audit readiness
26. **gap-analyzer** - Identify compliance gaps by severity
27. **risk-quantifier** - Quantify financial and regulatory risk exposure
28. **remediation-planner** - Create prioritized remediation roadmap
29. **compliance-orchestrator** - Final synthesis and recommendations

## Agent Coordination Layers

### Compliance Assessment Layer
- **compliance-orchestrator**: Overall audit orchestration and synthesis
- **@cost-analyst**: Software Tracker financial and licensing analysis
- **@integration-specialist**: Integration Registry security assessment
- **@knowledge-curator**: Knowledge Vault data classification

### Domain-Specific Audit Layer
- **license-validator**: Software licensing compliance
- **data-privacy-auditor**: GDPR, CCPA assessment
- **integration-security-auditor**: Third-party security review
- **policy-completeness-checker**: Policy framework audit

### Evidence & Reporting Layer
- **evidence-collector**: Audit evidence gathering
- **gap-analyzer**: Compliance gap identification
- **remediation-planner**: Actionable remediation plans
- **risk-quantifier**: Risk scoring and prioritization

## Usage Examples

### Example 1: Quarterly Software Licensing Audit
```
/compliance:audit software

Output:
=== SOFTWARE LICENSING COMPLIANCE AUDIT ===
Date: 2025-10-21
Scope: All software in Software & Cost Tracker (67 tools audited)

SUMMARY
  ✅ Compliant: 58 tools (87%)
  ⚠️  At Risk: 7 tools (10%)
  🔴 Non-Compliant: 2 tools (3%)

NON-COMPLIANT SOFTWARE (URGENT)
1. GitHub Enterprise Cloud
   License Type: Per-user (Commercial)
   Licensed Seats: 10
   Actual Users: 14
   Violation: Under-licensed by 4 seats
   Risk: HIGH - Audit risk, potential back-billing
   Action: Purchase 4 additional seats ($168/month) OR remove 4 users
   Deadline: Immediate

2. Power BI Pro
   License Type: Per-user (Microsoft 365)
   Licensed Seats: 5
   Actual Usage: Development only (not production-approved)
   Violation: Usage rights violation
   Risk: MEDIUM - License terms violation
   Action: Upgrade to Power BI Premium OR limit to licensed development use
   Deadline: 30 days

AT-RISK SOFTWARE (REVIEW REQUIRED)
- Azure OpenAI: Contract expires in 45 days → Renew or cancel
- Notion Enterprise: No contract documentation in SharePoint
- Slack Business: Overlaps with Microsoft Teams (consolidation opportunity)
- 4 additional tools flagged

OPTIMIZATION OPPORTUNITIES
  - Over-licensed: 3 tools with unused seats → Save $284/month
  - Consolidation: 2 tools with duplicate functionality → Save $150/month
  - Total Potential Savings: $434/month ($5,208/year)

NEXT ACTIONS
  Priority 1 (Immediate): Resolve GitHub under-licensing (compliance risk)
  Priority 2 (30 days): Address Power BI usage rights violation
  Priority 3 (60 days): Process contract renewals (5 contracts expiring)
  Priority 4 (90 days): Execute optimization opportunities ($5K annual savings)

AUDIT READINESS
  Evidence Collected: ✅ Complete
  Contract Documentation: ⚠️  67% (improve to 95%)
  License Tracking: ✅ Excellent (all licenses tracked in Software Tracker)
```

### Example 2: Pre-Client Audit Preparation
```
/compliance:audit --comprehensive

Output:
=== COMPREHENSIVE COMPLIANCE AUDIT ===
Date: 2025-10-21
Scope: Software licensing, data privacy, third-party security, policy framework

EXECUTIVE SUMMARY
  Overall Compliance Score: 82/100 (Good)
  Critical Gaps: 2
  High-Priority Recommendations: 5
  Audit Readiness: 78% (Target: 95%)

SOFTWARE LICENSING: 87% Compliant ✅
  (Detailed report as Example 1)

DATA PRIVACY: 75% Compliant ⚠️
  GDPR Applicability: YES (EU client: Brookside GmbH)
    ✅ Lawful Basis: Legitimate business interest
    ⚠️  Data Subject Rights: No documented process for access requests
    ⚠️  Privacy Policy: Generic template, needs customization
    ❌ DPIA: Not conducted for Knowledge Vault (REQUIRED)
    ✅ Data Retention: Policy exists, needs enforcement mechanism

  CCPA Applicability: NO (no California residents in customer base)

  CRITICAL ACTIONS
    1. Conduct Data Protection Impact Assessment (DPIA) for Knowledge Vault
    2. Establish data subject rights fulfillment process
    3. Customize privacy policy for Innovation Nexus

THIRD-PARTY SECURITY: 68% Compliant ⚠️
  Total Integrations: 12 (Integration Registry)
  Security Review Status:
    ✅ Approved: 5 (42%)
    ⏳ Pending: 3 (25%)
    ❌ N/A: 4 (33%) ← NEEDS ATTENTION

  HIGH-RISK INTEGRATIONS (Security Review N/A)
    1. Snowflake Data Warehouse
       Authentication: Service Principal (Good)
       Encryption: TLS 1.3 (Good)
       Vendor Certs: SOC 2 Type II ✅
       Issue: No formal security review documented
       Action: Conduct security review within 30 days

    2. Azure OpenAI
       (Similar assessment)

    3-4. (Additional integrations)

  RECOMMENDATIONS
    - Complete security reviews for 4 pending integrations
    - Implement quarterly security review schedule
    - Document vendor risk assessments in Integration Registry

POLICY FRAMEWORK: 60% Complete ⚠️
  Required Policies (5):
    ❌ Software Procurement Policy: MISSING
    ⚠️  Data Classification Policy: DRAFT (needs approval)
    ✅ Acceptable Use Policy: Complete
    ❌ Access Control Policy: MISSING
    ⚠️  Vendor Management Policy: PARTIAL

  PRIORITY ACTIONS
    1. Create Software Procurement Policy (template provided)
    2. Finalize Data Classification Policy (ready for approval)
    3. Create Access Control Policy (based on least privilege principle)

AUDIT READINESS SCORE: 78/100
  Gap to Target (95%): 17 points
  Timeline to Audit-Ready: 60-90 days (with focused effort)
  Blockers: DPIA, security reviews, policy finalization

RECOMMENDED ROADMAP
  Month 1 (Days 1-30):
    - Resolve critical software licensing gaps
    - Conduct DPIA for Knowledge Vault
    - Complete pending security reviews (4 integrations)
    - Create Software Procurement Policy

  Month 2 (Days 31-60):
    - Establish data subject rights process
    - Finalize all policy documentation
    - Implement contract expiration monitoring
    - Address over-licensing opportunities

  Month 3 (Days 61-90):
    - Quarterly compliance review process
    - Team security awareness training
    - Audit evidence organization
    - Final audit readiness validation

BUDGET ESTIMATE
  Policy Development: 40 hours @ $150/hr = $6,000
  Security Reviews: 20 hours @ $200/hr = $4,000
  DPIA: 16 hours @ $200/hr = $3,200
  Training: 8 hours @ $100/hr = $800
  Total: $14,000 (one-time investment for audit readiness)
```

### Example 3: Integration Security Review
```
/compliance:audit integrations

Output:
=== INTEGRATION REGISTRY SECURITY AUDIT ===
Date: 2025-10-21
Scope: 12 integrations in Integration Registry

SECURITY REVIEW STATUS SUMMARY
  ✅ Approved: 5 integrations (42%)
  ⏳ Pending: 3 integrations (25%)
  ❌ N/A (Not Reviewed): 4 integrations (33%)

AUTHENTICATION METHOD BREAKDOWN
  ✅ Azure AD (Preferred): 7 integrations
  ⚠️  OAuth 2.0: 3 integrations
  ❌ API Key: 2 integrations (least secure)

ENCRYPTION VALIDATION
  ✅ TLS 1.3: 10 integrations
  ⚠️  TLS 1.2: 2 integrations (acceptable but should upgrade)

VENDOR SECURITY CERTIFICATIONS
  ✅ SOC 2 Type II: 8 vendors
  ✅ ISO 27001: 6 vendors
  ⚠️  No Certifications: 2 vendors

CRITICAL FINDINGS
  1. Slack Integration
     - Authentication: OAuth (acceptable)
     - Security Review: N/A ❌
     - Risk: MEDIUM (overlaps with Microsoft Teams)
     - Recommendation: Complete security review OR migrate to Teams
     - Business Justification: Evaluate if Slack provides unique value

  2. Legacy API Integration
     - Authentication: API Key ❌ (least secure)
     - Encryption: TLS 1.2 ⚠️
     - Security Review: N/A ❌
     - Recommendation: Migrate to Azure AD authentication OR decommission

RECOMMENDATIONS
  Priority 1: Complete security reviews for 4 N/A integrations
  Priority 2: Migrate 2 API Key integrations to Azure AD
  Priority 3: Upgrade 2 TLS 1.2 integrations to TLS 1.3
  Priority 4: Establish quarterly integration security review schedule
```

## Expected Outputs

### 1. Compliance Scope Document
- Applicable regulatory frameworks (GDPR, CCPA, or N/A with rationale)
- In-scope systems: Software Tracker, Integration Registry, Knowledge Vault
- Data classification summary
- Compliance timeline and milestones

### 2. Software Licensing Audit Report
- Compliant vs. at-risk vs. non-compliant tool counts
- Under-licensed tools (immediate action required)
- Over-licensed tools (cost optimization opportunities)
- Expiring contracts (30/60/90 day pipeline)
- Unused software (consolidation candidates)
- License type breakdown (open-source, commercial, freemium, trial)
- Annual cost impact of licensing issues

### 3. Data Privacy Assessment
- GDPR applicability determination
- CCPA applicability determination
- Data classification (Knowledge Vault, Notion databases)
- Data subject rights fulfillment process status
- Privacy policy adequacy
- DPIA requirements (Data Protection Impact Assessment)
- Data retention policy validation

### 4. Third-Party Security Review
- Integration Registry security status (Approved/Pending/N/A counts)
- Authentication method analysis (Azure AD, OAuth, API Key breakdown)
- Encryption validation (TLS 1.3, TLS 1.2, AES-256)
- Vendor security certifications (SOC 2, ISO 27001)
- High-risk integrations requiring immediate review
- Security review backlog

### 5. Compliance Gap Analysis
- Identified gaps by domain (licensing, privacy, security, policy)
- Gap severity (Critical, High, Medium, Low)
- Non-compliant items with evidence
- Missing policies and documentation
- Technical control deficiencies

### 6. Risk Assessment
- Compliance risk scoring (Critical, High, Medium, Low)
- Regulatory enforcement risk (GDPR fines, CCPA penalties)
- Financial exposure (licensing penalties, over-spend)
- Reputational risk
- Business impact analysis

### 7. Remediation Roadmap
- Prioritized remediation plan (by risk and effort)
- Quick wins (high impact, low effort)
- 30/60/90 day action plan
- Resource requirements (budget, time, personnel)
- Timeline with milestones
- Dependencies and prerequisites

### 8. Policy & Procedure Recommendations
- Required policy creation (Software Procurement, Access Control, Vendor Management)
- Policy template library
- Procedure documentation gaps
- Training and awareness programs
- Governance framework establishment

### 9. Audit Readiness Assessment
- Overall compliance readiness score (0-100)
- Readiness by domain (licensing, privacy, security, policy)
- Estimated timeline to audit-ready state
- Critical blockers to address
- Evidence collection status

## Success Criteria

- ✅ All Software Tracker entries audited for licensing compliance
- ✅ Integration Registry security review status validated
- ✅ Knowledge Vault data classification assessed
- ✅ GDPR/CCPA applicability determined with rationale
- ✅ All compliance gaps identified with severity ratings
- ✅ Risk-prioritized remediation roadmap created
- ✅ Policy framework gaps documented
- ✅ Evidence collection completed for audit readiness
- ✅ Cost optimization opportunities identified
- ✅ Timeline to compliance established
- ✅ Budget requirements estimated
- ✅ Executive summary for stakeholders

## Configuration Options

### Audit Scope
- `--scope=software` - Software licensing compliance only
- `--scope=privacy` - Data privacy compliance only
- `--scope=integrations` - Third-party security review only
- `--scope=policy` - Policy framework review only
- `--comprehensive` - Full compliance audit (all scopes)

### Detail Level
- `--summary` - Executive summary only
- `--standard` - Standard audit report (default)
- `--detailed` - Comprehensive analysis with evidence

### Output Format
- `--format=markdown` - Markdown report (default)
- `--format=executive` - Executive summary (stakeholder-friendly)
- `--format=remediation` - Remediation-focused action plan

## Notes

- **Quarterly Cadence**: Run `/compliance:audit --comprehensive` quarterly for continuous compliance
- **Pre-Audit Preparation**: Use comprehensive scope 60-90 days before client/regulatory audits
- **Microsoft Licensing**: Validate Microsoft 365, Azure, Power Platform licensing optimization
- **Software Tracker Integration**: All findings link back to Software & Cost Tracker entries
- **Integration Registry**: Security review status drives third-party risk management
- **Knowledge Vault**: Data classification drives privacy compliance requirements
- **Evidence Collection**: Automatically generates audit-ready evidence documentation
- **Cost Optimization**: Compliance audit identifies licensing waste and consolidation opportunities
- **Policy Templates**: Provides governance policy templates aligned with Brookside BI brand voice

## Estimated Execution Time

- **Software Licensing Only** (`--scope=software`): 15-20 minutes
- **Data Privacy Only** (`--scope=privacy`): 20-30 minutes
- **Integration Security Only** (`--scope=integrations`): 15-25 minutes
- **Policy Review Only** (`--scope=policy`): 10-15 minutes
- **Comprehensive Audit** (`--comprehensive`): 45-60 minutes

---

**This command establishes sustainable governance practices that protect Brookside BI while enabling innovation growth through structured compliance frameworks.**
