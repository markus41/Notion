# Agent Registry Guide

**Brookside BI Agent Registry** - Establish systematic specialization through 38+ intelligent agents designed to streamline workflows across innovation, cost management, repository intelligence, Azure infrastructure, and documentation operations.

**Best for**: Organizations seeking to optimize team productivity through intelligent work delegation, automated research coordination, and specialized domain expertise at scale.

---

## Agent Ecosystem Overview

Innovation Nexus leverages specialized AI agents to automate complex workflows, provide domain expertise, and maintain consistency across operations. Each agent is purpose-built for specific tasks with clear invocation patterns, success criteria, and integration points.

### Agent Categories

```mermaid
graph TB
    subgraph Innovation Lifecycle
        A1[💡 @ideas-capture]
        A2[🔬 @research-coordinator]
        A3[🛠️ @build-architect-v2]
        A4[📚 @knowledge-curator]
        A5[🗄️ @archive-manager]
    end

    subgraph Research Swarm
        B1[@market-researcher]
        B2[@technical-analyst]
        B3[@cost-feasibility-analyst]
        B4[@risk-assessor]
    end

    subgraph Build Pipeline
        C1[@code-generator]
        C2[@deployment-orchestrator]
        C3[@quality-assurance]
    end

    subgraph Cost Management
        D1[💰 @cost-analyst]
        D2[@license-optimizer]
        D3[@budget-forecaster]
    end

    subgraph Repository Intelligence
        E1[📊 @repo-scanner]
        E2[@viability-assessor]
        E3[@pattern-miner]
    end

    subgraph Azure Infrastructure
        F1[☁️ @azure-architect]
        F2[@infrastructure-optimizer]
        F3[@security-auditor]
    end

    subgraph Documentation
        G1[📝 @markdown-expert]
        G2[@documentation-orchestrator]
        G3[@api-documenter]
    end

    subgraph Support Agents
        H1[@team-coordinator]
        H2[@activity-logger]
        H3[@style-orchestrator]
    end

    A1 -->|Viability Assessment| A2
    A2 -->|Research Required| B1
    A2 --> B2
    A2 --> B3
    A2 --> B4
    B1 -->|Viability Score >85| A3
    B2 --> A3
    B3 --> A3
    B4 --> A3
    A3 --> C1
    C1 --> C2
    C2 --> C3
    C3 -->|Success| A4
    A4 --> A5

    style A1 fill:#4A90E2,stroke:#2E5C8A,color:#fff
    style A2 fill:#50C878,stroke:#2E8B57,color:#fff
    style A3 fill:#FF6B6B,stroke:#CC5555,color:#fff
    style A4 fill:#9B59B6,stroke:#7D3C98,color:#fff
    style A5 fill:#F39C12,stroke:#D68910,color:#fff
```

---

## Agent Decision Tree

Use this decision tree to select the appropriate agent for your task:

```mermaid
graph TD
    START[What are you trying to accomplish?] --> Q1{Working with Innovation?}

    Q1 -->|New Idea| A1[@ideas-capture]
    Q1 -->|Research Needed| A2[@research-coordinator]
    Q1 -->|Build Solution| A3[@build-architect-v2]
    Q1 -->|Archive Knowledge| A4[@knowledge-curator]

    Q1 -->|No| Q2{Managing Costs?}
    Q2 -->|Analyze Spending| B1[@cost-analyst]
    Q2 -->|Optimize Licenses| B2[@license-optimizer]
    Q2 -->|Forecast Budget| B3[@budget-forecaster]

    Q2 -->|No| Q3{Repository Work?}
    Q3 -->|Scan GitHub Org| C1[@repo-scanner]
    Q3 -->|Assess Viability| C2[@viability-assessor]
    Q3 -->|Extract Patterns| C3[@pattern-miner]

    Q3 -->|No| Q4{Azure Infrastructure?}
    Q4 -->|Design Architecture| D1[@azure-architect]
    Q4 -->|Optimize Resources| D2[@infrastructure-optimizer]
    Q4 -->|Security Audit| D3[@security-auditor]

    Q4 -->|No| Q5{Documentation?}
    Q5 -->|Write Markdown| E1[@markdown-expert]
    Q5 -->|Multi-file Updates| E2[@documentation-orchestrator]
    Q5 -->|API Docs| E3[@api-documenter]

    Q5 -->|No| Q6{Team Coordination?}
    Q6 -->|Assign Work| F1[@team-coordinator]
    Q6 -->|Log Activity| F2[@activity-logger]
    Q6 -->|Choose Output Style| F3[@style-orchestrator]

    style START fill:#34495E,stroke:#2C3E50,color:#fff
    style A1 fill:#4A90E2,stroke:#2E5C8A,color:#fff
    style B1 fill:#50C878,stroke:#2E8B57,color:#fff
    style C1 fill:#FF6B6B,stroke:#CC5555,color:#fff
    style D1 fill:#9B59B6,stroke:#7D3C98,color:#fff
    style E1 fill:#F39C12,stroke:#D68910,color:#fff
    style F1 fill:#E74C3C,stroke:#C0392B,color:#fff
```

---

## Core Agent Categories

### 1. Innovation Lifecycle Agents

**Purpose**: Streamline the complete innovation workflow from idea capture through deployment and archival.

#### @ideas-capture

**Specialization**: New innovation opportunity identification and initial viability assessment

**Use When**:
- Team member suggests "we should build..."
- User mentions "I have an idea for..."
- Ad-hoc innovation concept needs structure

**Capabilities**:
- Create Ideas Registry Notion entries with standard formatting
- Perform initial viability assessment (High/Medium/Low/Needs Research)
- Estimate technical complexity and business value
- Recommend next steps (research, build, or archive)
- Assign team ownership based on domain expertise

**Invocation**:
```bash
# Via slash command (recommended)
/innovation:new-idea "Automated invoice processing with Azure Form Recognizer"

# Via direct delegation
Task @ideas-capture "Capture idea: Real-time Power BI dashboard embedding SDK"
```

**Output Example**:
```markdown
💡 Idea Created: Automated Invoice Processing

**Viability**: Needs Research (requires feasibility analysis)
**Business Value**: High (streamlines 40+ hours/month manual data entry)
**Technical Complexity**: Medium (Azure Form Recognizer integration)
**Estimated Cost**: $200-400/month (Azure cognitive services)

**Recommended Next Steps**:
1. Research competitive solutions (market analysis)
2. Analyze Azure Form Recognizer capabilities (technical feasibility)
3. Calculate ROI vs. manual processing costs

**Team Assignment**: Markus Ahling (AI/ML expertise)
```

#### @research-coordinator

**Specialization**: Orchestrate parallel research swarm execution and viability scoring synthesis

**Use When**:
- Idea has "Needs Research" viability status
- User requests feasibility investigation
- Team needs data-driven build decision

**Capabilities**:
- Create Research Hub Notion entries
- Coordinate 4-agent parallel research swarm:
  - @market-researcher (competitive analysis, demand validation)
  - @technical-analyst (implementation complexity, architecture)
  - @cost-feasibility-analyst (TCO, ROI projections)
  - @risk-assessor (security, compliance, technical debt)
- Synthesize findings into 0-100 viability score
- Generate executive summary with Go/No-Go recommendation
- Link research to originating idea

**Invocation**:
```bash
# Via slash command (recommended)
/innovation:start-research "Azure Form Recognizer feasibility" "Automated Invoice Processing"

# Via direct delegation
Task @research-coordinator "Research feasibility for real-time dashboard embedding idea"
```

**Output Example**:
```markdown
🔬 Research Complete: Azure Form Recognizer Feasibility

**Viability Score**: 87/100 (High Confidence - Auto-Approved for Build)

**Executive Summary**:
Azure Form Recognizer provides pre-built invoice processing models with 94% accuracy for standard invoice formats. Market demand is strong (42% YoY growth in AP automation). Total cost of ownership is $3,200/year with 18-month ROI. Primary risk is custom invoice format handling (requires training data).

**Agent Findings**:
- Market: 12 competitors, but Azure integration provides differentiation
- Technical: 15-20 hours implementation (standard Azure SDK integration)
- Cost: $267/month Azure services, $0 additional licensing
- Risk: Medium - Data residency compliance requires Azure regions review

**Recommendation**: PROCEED TO BUILD (high viability, clear ROI)
```

#### @build-architect-v2

**Specialization**: Technical architecture design and infrastructure-as-code generation for Azure deployments

**Use When**:
- Research shows viability score >85
- User requests autonomous build pipeline
- Need production-ready Azure architecture

**Capabilities**:
- Design scalable Azure architecture (App Service, Functions, AKS, etc.)
- Generate Bicep infrastructure-as-code templates
- Create environment-specific configurations (dev/staging/prod)
- Implement cost-optimized SKU selection (87% savings via environment-based sizing)
- Establish Managed Identity and Key Vault integration
- Design CI/CD pipeline architecture
- Generate comprehensive technical documentation

**Invocation**:
```bash
# Via slash command (recommended)
/autonomous:enable-idea "Automated Invoice Processing"

# Via direct delegation (for architecture only, not full pipeline)
Task @build-architect-v2 "Design Azure architecture for invoice processing with Form Recognizer"
```

**Output Example**:
```markdown
🛠️ Architecture Complete: Invoice Processing Platform

**Azure Resources**:
- App Service Plan (B1 dev, P1v2 prod) - Web API hosting
- Azure Functions (Consumption plan) - Invoice processing triggers
- Azure Form Recognizer (S0 tier) - Invoice data extraction
- Azure Storage (GRS) - Document storage and queuing
- Key Vault (Standard) - Secrets management
- Application Insights (Standard) - Monitoring and logging

**Cost Projection**:
- Development: $23/month
- Production: $267/month
- Estimated ROI: 18 months (vs. $1,200/month manual processing cost)

**Security**:
- Managed Identity for service-to-service authentication
- All secrets in Key Vault (zero hardcoded credentials)
- HTTPS-only with TLS 1.2 minimum
- RBAC for granular access control

**Bicep Template**: [Generated infrastructure-as-code with 347 lines]
```

#### @knowledge-curator

**Specialization**: Extract lessons learned and architectural patterns from completed work for Knowledge Vault archival

**Use When**:
- Build completes successfully
- Project reaches end-of-life
- Team requests retrospective documentation

**Capabilities**:
- Create Knowledge Vault Notion entries
- Extract reusable architectural patterns
- Document lessons learned (successes and failures)
- Calculate cost actuals vs. estimates (accuracy tracking)
- Preserve troubleshooting guides and common issues
- Tag and categorize for searchability
- Link to originating Ideas, Research, and Builds

**Invocation**:
```bash
# Via slash command (recommended)
/knowledge:archive "Automated Invoice Processing" build

# Via direct delegation
Task @knowledge-curator "Archive learnings from invoice processing project"
```

**Output Example**:
```markdown
📚 Knowledge Archived: Automated Invoice Processing

**Lessons Learned**:
✅ Azure Form Recognizer pre-built models work well for standard invoices (94% accuracy)
⚠️ Custom invoice formats require 50-100 training samples (plan for data collection)
✅ Managed Identity eliminated credential management complexity
⚠️ Form Recognizer has 15-second processing latency (not real-time suitable)

**Reusable Patterns**:
- Pattern: Azure Functions + Form Recognizer integration (23 files, 847 lines)
- Pattern: Managed Identity authentication flow (12 files, 334 lines)
- Pattern: Bicep multi-environment deployment (5 files, 412 lines)

**Cost Actuals**:
- Estimated: $267/month
- Actual: $243/month (9% under budget)
- ROI Achieved: 16 months (2 months better than projection)

**Search Tags**: azure-form-recognizer, invoice-processing, document-ai, managed-identity
```

#### @archive-manager

**Specialization**: Complete work lifecycle management and Notion status updates

**Use When**:
- User says "done with this project"
- Build reaches completed or cancelled status
- Need to clean up active work queues

**Capabilities**:
- Update Notion status fields (Active → Completed/Archived)
- Verify all relations are properly linked
- Ensure Knowledge Vault entry exists (create if missing)
- Update cost rollups with final actuals
- Archive related research and idea entries
- Generate final project summary

**Invocation**:
```bash
# Via slash command (recommended)
/knowledge:archive "Automated Invoice Processing" build

# Via direct delegation
Task @archive-manager "Archive invoice processing build and all related work"
```

---

### 2. Research Swarm Agents

**Purpose**: Execute parallel feasibility analysis across market, technical, cost, and risk dimensions to drive data-driven build decisions.

#### @market-researcher

**Specialization**: Competitive analysis, market demand validation, and positioning strategy

**Use When**:
- Need to understand competitive landscape
- Validating market demand before building
- Identifying differentiation opportunities

**Capabilities**:
- Competitive solution analysis (features, pricing, market share)
- Market size and growth trend research
- Customer demand validation (surveys, industry reports)
- Positioning and differentiation recommendations
- Go-to-market strategy considerations

**Typical Research Questions**:
- Who are the top 3-5 competitors in this space?
- What is the market size and growth trajectory?
- What features differentiate our solution?
- Is there validated customer demand?
- What pricing models are standard in this market?

**Output Example**:
```markdown
**Market Analysis: Invoice Processing Automation**

**Competitive Landscape**:
1. UiPath Document Understanding ($$$) - RPA focus, complex setup
2. Rossum ($$$) - AI-first, strong accuracy, expensive
3. AWS Textract ($$) - Good accuracy, AWS ecosystem lock-in

**Market Opportunity**:
- TAM: $2.3B (AP automation software)
- CAGR: 42% (2023-2028)
- Demand Driver: Labor cost reduction (avg $35K/year savings per FTE replaced)

**Differentiation Strategy**:
✅ Azure ecosystem integration (seamless M365 compatibility)
✅ Cost advantage (40% lower than Rossum at scale)
✅ Managed Identity security (enterprise compliance ready)

**Risk**: Market is competitive; differentiation requires strong Azure positioning
**Confidence**: 85% (strong demand, clear differentiation path)
```

#### @technical-analyst

**Specialization**: Implementation complexity assessment, architecture recommendations, and dependency analysis

**Use When**:
- Evaluating technical feasibility
- Need architecture pattern recommendations
- Assessing integration complexity

**Capabilities**:
- Technology stack evaluation (Azure, GitHub, third-party services)
- Architecture pattern recommendations (microservices, serverless, monolith)
- Dependency and integration analysis
- Implementation time estimation
- Technical risk identification
- Scalability and performance considerations

**Typical Research Questions**:
- What is the recommended Azure architecture?
- What are the critical dependencies?
- What is the implementation complexity (hours/weeks)?
- Are there technical blockers or limitations?
- What are the scalability constraints?

**Output Example**:
```markdown
**Technical Analysis: Invoice Processing Automation**

**Recommended Architecture**:
- Azure Functions (Consumption) - Event-driven processing
- Azure Form Recognizer (S0) - Invoice data extraction
- Azure Storage Queue - Asynchronous processing
- App Service (B1/P1v2) - Management UI

**Implementation Complexity**:
- Estimated Effort: 15-20 hours (standard Azure SDK integration)
- Critical Path: Form Recognizer model training (if custom formats required)
- Team Skill Match: High (Markus has Azure AI expertise)

**Dependencies**:
✅ Azure Form Recognizer SDK (official Microsoft library, well-documented)
✅ Azure Storage SDK (mature, stable)
⚠️ Invoice format diversity (requires sample collection for training)

**Scalability**:
- Form Recognizer: 15 requests/second (sufficient for <1M invoices/year)
- Azure Functions: Auto-scaling to 200 instances (handles spikes)
- Storage: Unlimited (no bottleneck)

**Technical Risk**: LOW (mature Azure services, standard integration patterns)
**Confidence**: 92% (clear implementation path, well-documented APIs)
```

#### @cost-feasibility-analyst

**Specialization**: Total cost of ownership calculation, ROI projection, and budget validation

**Use When**:
- Need accurate cost projections before committing budget
- Calculating ROI for executive approval
- Comparing build vs. buy vs. SaaS options

**Capabilities**:
- Azure resource cost estimation (compute, storage, networking, AI services)
- Software licensing cost analysis
- Development and maintenance cost projections
- ROI calculation with break-even timeline
- Cost comparison (build vs. buy vs. third-party SaaS)
- TCO analysis (3-year projection)

**Typical Research Questions**:
- What are the Azure infrastructure costs (dev/staging/prod)?
- What is the total cost of ownership (3-year TCO)?
- What is the ROI timeline and break-even point?
- How do build costs compare to SaaS alternatives?
- What are the ongoing maintenance costs?

**Output Example**:
```markdown
**Cost Feasibility: Invoice Processing Automation**

**Azure Infrastructure Costs**:
- Development: $23/month (B1 App Service, Consumption Functions, S0 Form Recognizer)
- Production: $267/month (P1v2 App Service, S0 Form Recognizer, GRS Storage)
- Annual Total: $3,200/year (infrastructure only)

**Development Costs** (one-time):
- Implementation: 20 hours @ $150/hour = $3,000
- Testing & QA: 5 hours @ $150/hour = $750
- Total Development: $3,750

**3-Year TCO**:
- Year 1: $3,750 (dev) + $3,200 (infra) = $6,950
- Year 2-3: $3,200/year (infra only) = $6,400
- Total 3-Year TCO: $13,350

**ROI Analysis**:
- Current Manual Processing Cost: $1,200/month ($14,400/year)
- Savings: $14,400 - $3,200 = $11,200/year
- Break-Even: 7.4 months
- 3-Year ROI: 223% ($29,850 saved vs. $13,350 invested)

**Build vs. Buy**:
- Build (Innovation Nexus): $13,350 (3-year TCO)
- Rossum SaaS: $28,800 (3-year subscription @ $800/month)
- Savings: $15,450 (54% cost reduction via build)

**Confidence**: 90% (based on Azure pricing calculator + historical project actuals)
```

#### @risk-assessor

**Specialization**: Security, compliance, and technical debt risk identification with mitigation strategies

**Use When**:
- Need security and compliance validation
- Identifying potential project risks
- Planning risk mitigation strategies

**Capabilities**:
- Security risk assessment (authentication, authorization, data protection)
- Compliance requirement analysis (GDPR, SOC2, HIPAA, etc.)
- Technical debt and maintenance risk evaluation
- Dependency vulnerability scanning
- Scalability and performance risk identification
- Mitigation strategy recommendations

**Typical Research Questions**:
- What are the security risks and mitigation strategies?
- What compliance requirements apply (GDPR, SOC2, etc.)?
- What technical debt risks should we anticipate?
- Are there dependency vulnerabilities?
- What are the maintenance and support risks?

**Output Example**:
```markdown
**Risk Assessment: Invoice Processing Automation**

**Security Risks**:
🔴 HIGH: Invoice PII exposure (customer data, banking details)
   → Mitigation: Encrypt at rest (Storage encryption), TLS 1.2 in transit, RBAC access control

🟡 MEDIUM: API authentication bypass potential
   → Mitigation: Managed Identity + Key Vault, no hardcoded credentials, API key rotation

🟢 LOW: DDoS on invoice submission endpoint
   → Mitigation: Azure Front Door with WAF, rate limiting

**Compliance Requirements**:
- GDPR: Invoice data contains PII (requires data residency in EU regions for EU customers)
  → Action: Configure Azure regional deployments (West Europe for EU, East US for NA)
- SOC2: Audit logging required for invoice access and modifications
  → Action: Enable Application Insights with 90-day retention

**Technical Debt Risks**:
🟡 MEDIUM: Form Recognizer model drift (invoice format changes over time)
   → Mitigation: Quarterly model retraining, accuracy monitoring alerts

🟢 LOW: Azure SDK breaking changes
   → Mitigation: Pin SDK versions in dependencies, test before upgrading

**Recommendation**: Proceed with MEDIUM risk rating (manageable with planned mitigations)
**Blockers**: None (all risks have clear mitigation paths)
**Confidence**: 88% (standard enterprise security patterns apply)
```

---

### 3. Build Pipeline Agents

**Purpose**: Execute autonomous code generation, deployment orchestration, and quality assurance for production-ready applications.

#### @code-generator

**Specialization**: Application code generation with unit tests and documentation

**Use When**:
- Architecture design is complete
- Need implementation code for Azure services
- Generating boilerplate and integration code

**Capabilities**:
- Generate application code (Python, TypeScript, C#)
- Create unit tests with 80%+ coverage targets
- Generate integration tests for Azure services
- Write inline documentation and README files
- Implement error handling and logging
- Follow language-specific best practices and linting rules

**Invocation**:
```bash
# Typically invoked automatically by /autonomous:enable-idea pipeline
# Direct delegation for specific code generation:
Task @code-generator "Generate Python Azure Functions code for invoice processing with Form Recognizer"
```

**Output Example**:
```python
# Establish scalable invoice processing with Azure Form Recognizer
# Designed for organizations processing 100-10,000 invoices/month

import logging
import os
from azure.functions import HttpRequest, HttpResponse
from azure.ai.formrecognizer import DocumentAnalysisClient
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

logger = logging.getLogger(__name__)

def main(req: HttpRequest) -> HttpResponse:
    """
    Process invoice submission and extract structured data.

    Best for: Asynchronous invoice processing with audit trail.

    Returns:
        HttpResponse: Extracted invoice data or error details
    """
    try:
        # Establish secure Form Recognizer connection via Managed Identity
        credential = DefaultAzureCredential()
        endpoint = os.environ["FORM_RECOGNIZER_ENDPOINT"]
        client = DocumentAnalysisClient(endpoint=endpoint, credential=credential)

        # Extract invoice data using pre-built invoice model
        invoice_url = req.params.get('url')
        if not invoice_url:
            return HttpResponse("Missing 'url' parameter", status_code=400)

        logger.info(f"Processing invoice from URL: {invoice_url}")

        # Analyze document and extract structured fields
        poller = client.begin_analyze_document_from_url(
            model_id="prebuilt-invoice",
            document_url=invoice_url
        )
        result = poller.result()

        # Extract key invoice fields with confidence scores
        invoice_data = extract_invoice_fields(result)

        logger.info(f"Successfully extracted {len(invoice_data)} invoice fields")
        return HttpResponse(
            body=json.dumps(invoice_data),
            mimetype="application/json",
            status_code=200
        )

    except Exception as e:
        logger.error(f"Invoice processing failed: {str(e)}", exc_info=True)
        return HttpResponse(
            body=json.dumps({"error": str(e)}),
            mimetype="application/json",
            status_code=500
        )

def extract_invoice_fields(analysis_result):
    """
    Extract structured invoice fields from Form Recognizer results.

    Streamlines invoice data extraction with confidence scoring for quality validation.
    """
    # Implementation details...
    pass
```

#### @deployment-orchestrator

**Specialization**: Azure resource provisioning, CI/CD pipeline setup, and production deployment

**Use When**:
- Code generation is complete
- Need automated Azure deployment
- Setting up CI/CD pipeline

**Capabilities**:
- Execute Bicep infrastructure deployment to Azure
- Configure GitHub Actions CI/CD pipelines
- Set up environment-specific configurations (dev/staging/prod)
- Establish Application Insights monitoring
- Configure health checks and alerting
- Deploy application code to Azure
- Verify deployment success with smoke tests

**Invocation**:
```bash
# Typically invoked automatically by /autonomous:enable-idea pipeline
# Direct delegation for deployment only:
Task @deployment-orchestrator "Deploy invoice processing app to Azure with CI/CD pipeline"
```

**Output Example**:
```markdown
🚀 Deployment Complete: Invoice Processing Platform

**Azure Resources Provisioned**:
✅ Resource Group: rg-invoice-processing-prod (East US)
✅ App Service Plan: plan-invoice-prod (P1v2, Linux)
✅ Function App: func-invoice-prod (Python 3.11)
✅ Form Recognizer: formrec-invoice-prod (S0 tier)
✅ Storage Account: stinvoiceprod (GRS, encrypted)
✅ Key Vault: kv-invoice-prod (secrets configured)
✅ Application Insights: appi-invoice-prod (Standard)

**CI/CD Pipeline**:
✅ GitHub Actions workflow created (.github/workflows/deploy.yml)
✅ Branch protection rules enabled (main branch)
✅ Automated deployment on push to main
✅ Environment secrets configured (AZURE_CREDENTIALS, FORM_RECOGNIZER_KEY)

**Deployment Verification**:
✅ Health check endpoint: https://func-invoice-prod.azurewebsites.net/api/health (200 OK)
✅ Form Recognizer connectivity: PASS
✅ Key Vault access: PASS
✅ Storage account access: PASS

**Monitoring**:
📊 Application Insights Dashboard: https://portal.azure.com/#@.../applicationInsights/overview
🔔 Alerts configured: Error rate >5%, Response time >3s, Availability <99%

**Actual Costs** (first month):
- Projected: $267/month
- Actual: $243/month (9% under budget)

**Next Steps**:
1. Configure custom domain and SSL certificate
2. Set up additional environments (staging, UAT)
3. Enable autoscaling rules for peak load handling
```

#### @quality-assurance

**Specialization**: Automated testing, code quality validation, and deployment verification

**Use When**:
- Validating code quality before production
- Need automated test execution
- Verifying deployment health

**Capabilities**:
- Execute unit tests and measure coverage
- Run integration tests against Azure services
- Perform security vulnerability scanning
- Validate code linting and formatting standards
- Execute smoke tests post-deployment
- Generate quality reports and dashboards

**Invocation**:
```bash
# Typically invoked automatically by /autonomous:enable-idea pipeline
# Direct delegation for QA only:
Task @quality-assurance "Run full test suite and quality checks for invoice processing app"
```

**Output Example**:
```markdown
✅ Quality Assurance Report: Invoice Processing Platform

**Unit Tests**:
- Total Tests: 47
- Passed: 47 (100%)
- Failed: 0
- Coverage: 84% (target: 80%)

**Integration Tests**:
- Azure Form Recognizer: PASS (15 test cases)
- Azure Storage: PASS (8 test cases)
- Key Vault: PASS (5 test cases)

**Security Scan**:
- Dependencies: 23 packages scanned
- Vulnerabilities: 0 HIGH, 0 MEDIUM, 2 LOW (acceptable)
- Secrets Detection: PASS (no hardcoded credentials)

**Code Quality**:
- Linting (pylint): 9.2/10 (2 minor warnings, acceptable)
- Formatting (black): PASS (100% compliant)
- Type Hints (mypy): PASS (92% coverage)

**Deployment Smoke Tests**:
✅ Invoice submission endpoint responding (200 OK)
✅ Form Recognizer processing test invoice (94% confidence)
✅ Storage blob upload and retrieval (PASS)
✅ Application Insights telemetry flowing (PASS)

**Overall Quality Score**: 94/100 (PRODUCTION READY)
**Recommendation**: APPROVE for production deployment
```

---

### 4. Cost Management Agents

**Purpose**: Optimize software spending through comprehensive analysis, license management, and budget forecasting.

#### @cost-analyst

**Specialization**: Software spend analysis, waste identification, and consolidation recommendations

**Use When**:
- Need to understand current software spending
- Identifying cost optimization opportunities
- Preparing budget reports for leadership

**Capabilities**:
- Query Software & Cost Tracker database for current spend
- Calculate cost rollups from database relations
- Identify unused software (zero utilization)
- Find consolidation opportunities (duplicate capabilities)
- Analyze expiring contracts (60-day window)
- Generate executive cost reports
- Recommend Microsoft ecosystem alternatives

**Invocation**:
```bash
# Via slash commands (recommended)
/cost:analyze all
/cost:monthly-spend
/cost:unused-software
/cost:consolidation-opportunities

# Via direct delegation
Task @cost-analyst "Analyze Q4 2024 software spending and identify top 5 cost reduction opportunities"
```

**Output Example**:
```markdown
💰 Software Cost Analysis: Q4 2024

**Total Monthly Spend**: $12,347/month ($148,164/year)

**Top 5 Expenses**:
1. Microsoft 365 E5: $4,200/month (15 licenses @ $280/license)
2. Azure Subscription: $3,847/month (multiple services)
3. GitHub Enterprise: $1,680/month (20 licenses @ $84/license)
4. Notion Enterprise: $1,200/month (25 licenses @ $48/license)
5. DataDog: $890/month (monitoring and APM)

**Waste Identified** ($1,047/month potential savings):
🚨 Asana Business ($480/month) - 0% utilization (no tasks created in 90 days)
   → Recommendation: Cancel, migrate to Microsoft Planner (included in M365)

🚨 Slack Standard ($367/month) - 12% active users
   → Recommendation: Consolidate to Microsoft Teams (included in M365)

⚠️ Zoom Pro ($200/month) - Redundant with Teams
   → Recommendation: Cancel, use Teams for video conferencing

**Consolidation Opportunities** ($1,200/month):
- Project Management: Asana + Monday.com → Microsoft Planner (included)
- Communication: Slack → Microsoft Teams (included)
- File Storage: Dropbox → OneDrive (included)

**Total Savings Potential**: $2,247/month ($26,964/year)
**ROI**: Immediate (all alternatives already included in existing M365 licenses)
```

#### @license-optimizer

**Specialization**: License utilization analysis and right-sizing recommendations

**Use When**:
- Optimizing license counts and tiers
- Need utilization data for renewals
- Right-sizing subscriptions

**Capabilities**:
- Analyze license utilization across software portfolio
- Identify over-provisioned licenses (unused seats)
- Recommend tier downgrades where appropriate
- Calculate cost savings from optimization
- Generate utilization reports for vendor negotiations

**Invocation**:
```bash
# Via direct delegation
Task @license-optimizer "Analyze GitHub Enterprise license utilization and recommend right-sizing"
```

**Output Example**:
```markdown
**License Optimization: GitHub Enterprise**

**Current State**:
- Total Licenses: 20
- Active Users (90 days): 14
- Utilization: 70%
- Monthly Cost: $1,680 ($84/license)

**Optimization Recommendations**:
✅ Reduce to 15 licenses (10% buffer for growth)
   → Savings: $420/month ($5,040/year)

⚠️ Consider GitHub Team tier for 8 developers (external contributors don't need Enterprise)
   → Savings: $672/month ($8,064/year)

**Risk Assessment**:
- LOW: 5 inactive users haven't committed in 90+ days (safe to remove)
- MEDIUM: Downgrading to Team tier requires SAML/audit log trade-offs

**Recommendation**: Reduce to 15 licenses immediately, evaluate Team tier in Q1 2025
```

#### @budget-forecaster

**Specialization**: Budget projections, trend analysis, and spend predictions

**Use When**:
- Planning annual budgets
- Need growth-based spend projections
- Tracking against budget targets

**Capabilities**:
- Analyze historical spending trends
- Project future costs based on growth rates
- Calculate budget variance and burn rate
- Identify cost trend anomalies
- Generate annual budget recommendations

**Invocation**:
```bash
# Via direct delegation
Task @budget-forecaster "Project 2025 software spending assuming 30% team growth"
```

**Output Example**:
```markdown
**Budget Forecast: 2025 Software Spending**

**Historical Trends** (Q1-Q4 2024):
- Q1: $10,200/month
- Q2: $11,400/month (+11.8%)
- Q3: $11,900/month (+4.4%)
- Q4: $12,347/month (+3.8%)
- Average Growth: 6.7% per quarter

**2025 Projections** (30% team growth scenario):
- Q1 2025: $13,100/month (based on historical + optimization savings)
- Q2 2025: $15,200/month (team growth impact on per-seat licenses)
- Q3 2025: $16,100/month
- Q4 2025: $16,800/month
- Average 2025: $15,300/month ($183,600/year)

**Recommended 2025 Budget**: $200,000/year (9% buffer for contingencies)

**Cost Drivers**:
1. Microsoft 365 E5: +30% seats ($1,260/month increase)
2. Azure: +25% usage ($962/month increase)
3. GitHub Enterprise: +30% licenses ($504/month increase)
```

---

### 5. Repository Intelligence Agents

**Purpose**: Automate GitHub portfolio analysis, viability scoring, and pattern extraction across organizational repositories.

#### @repo-scanner

**Specialization**: Comprehensive repository analysis with viability scoring and Notion synchronization

**Use When**:
- Need visibility into GitHub portfolio health
- Analyzing repository quality and maturity
- Syncing repository data to Notion Example Builds

**Capabilities**:
- Scan all repositories in GitHub organization
- Calculate 0-100 viability scores (test coverage, activity, documentation, dependencies)
- Detect Claude Code integration maturity (Expert/Advanced/Intermediate/Basic/None)
- Extract technology stack and dependencies
- Identify cost optimization opportunities
- Sync results to Notion Example Builds database

**Invocation**:
```bash
# Via slash command (recommended)
/repo:scan-org --sync --deep

# Via direct delegation
Task @repo-scanner "Scan brookside-bi GitHub organization and sync to Notion"
```

**Viability Scoring Breakdown**:
```
Total Score (0-100) =
  Test Coverage (30 points) +
  Activity Score (20 points) +
  Documentation Quality (25 points) +
  Dependency Health (25 points)
```

**Output Example**:
```markdown
📊 Repository Portfolio Analysis: brookside-bi

**Scanned**: 23 repositories
**High Viability (75-100)**: 8 repositories
**Medium Viability (50-74)**: 11 repositories
**Low Viability (<50)**: 4 repositories

**Top Performers**:
1. innovation-nexus (Score: 94) - Claude Expert, 87% test coverage, active
2. azure-bicep-templates (Score: 89) - Well-documented, comprehensive examples
3. power-bi-governance (Score: 85) - Strong documentation, clear patterns

**Needs Attention**:
1. legacy-reporting-api (Score: 34) - No tests, 0% coverage, inactive 120 days
2. poc-chatbot (Score: 42) - Missing documentation, deprecated dependencies

**Claude Code Integration**:
- Expert (6 repos): Full agent integration, autonomous capabilities
- Advanced (5 repos): Multi-agent coordination, structured workflows
- Intermediate (7 repos): Basic agent usage, slash commands
- Basic (3 repos): Minimal integration
- None (2 repos): No Claude Code detected

**Notion Sync**: 23 repositories synced to Example Builds database
```

#### @viability-assessor

**Specialization**: Repository quality scoring and health assessment

**Use When**:
- Evaluating single repository quality
- Need detailed viability breakdown
- Deciding repository archival vs. improvement

**Capabilities**:
- Calculate comprehensive viability score (0-100)
- Break down score components (tests, docs, activity, dependencies)
- Identify specific improvement opportunities
- Compare against organizational benchmarks
- Recommend archival vs. improvement actions

**Invocation**:
```bash
# Via slash command (recommended)
/repo:analyze innovation-nexus --deep --sync

# Via direct delegation
Task @viability-assessor "Assess viability of legacy-reporting-api repository"
```

**Output Example**:
```markdown
**Viability Assessment: legacy-reporting-api**

**Overall Score**: 34/100 (LOW - Archive Recommended)

**Score Breakdown**:
- Test Coverage: 0/30 (0% coverage, no test files detected)
- Activity: 4/20 (last commit 120 days ago, 1 contributor)
- Documentation: 12/25 (README exists but incomplete, no architecture docs)
- Dependencies: 18/25 (8 outdated packages, 2 security vulnerabilities)

**Specific Issues**:
🔴 CRITICAL: 2 HIGH severity vulnerabilities (CVE-2023-XXXX, CVE-2024-YYYY)
🔴 CRITICAL: No test coverage (production code with zero tests)
🟡 MEDIUM: 8 outdated dependencies (avg 18 months behind latest)
🟡 MEDIUM: No activity in 120 days (stale codebase)

**Improvement Path** (Estimated: 40 hours):
1. Add unit tests (20 hours) → +25 points
2. Update dependencies and fix vulnerabilities (8 hours) → +7 points
3. Complete documentation (6 hours) → +10 points
4. Establish CI/CD pipeline (6 hours) → +5 points
Projected Score After Improvements: 81/100

**Recommendation**: ARCHIVE (cost to improve exceeds rebuild cost)
**Alternative**: Rebuild with modern stack (estimated 25 hours, score 90+)
```

#### @pattern-miner

**Specialization**: Extract reusable architectural patterns across repository portfolio

**Use When**:
- Identifying code reuse opportunities
- Building pattern library for Knowledge Vault
- Standardizing architectural approaches

**Capabilities**:
- Analyze code structure across repositories
- Identify recurring architectural patterns
- Extract reusable code templates
- Calculate pattern reuse potential (usage frequency)
- Generate pattern documentation for Knowledge Vault

**Invocation**:
```bash
# Via slash command (recommended)
/repo:extract-patterns --min-usage 3 --sync

# Via direct delegation
Task @pattern-miner "Extract authentication patterns across all repositories"
```

**Output Example**:
```markdown
**Pattern Mining Results: brookside-bi Organization**

**Extracted Patterns**: 12 (minimum 3 repository usage)

**Top Reusable Patterns**:

1. **Azure Managed Identity Authentication** (Used in 8 repos)
   - Files: 23 files, 847 lines
   - Languages: Python, TypeScript, C#
   - Reuse Potential: HIGH (standard across all Azure apps)
   - Knowledge Vault: [Link to archived pattern]

2. **Bicep Multi-Environment Deployment** (Used in 7 repos)
   - Files: 12 files, 1,134 lines
   - Languages: Bicep, PowerShell
   - Reuse Potential: HIGH (every Azure deployment)
   - Knowledge Vault: [Link to archived pattern]

3. **API Error Handling with Application Insights** (Used in 6 repos)
   - Files: 18 files, 623 lines
   - Languages: TypeScript, Python
   - Reuse Potential: MEDIUM (API-focused projects)
   - Knowledge Vault: [Link to archived pattern]

**Time Savings Estimate**:
- Pattern 1 reuse: 5.2 hours saved per project
- Pattern 2 reuse: 4.8 hours saved per deployment
- Pattern 3 reuse: 3.1 hours saved per API

**Recommendation**: Standardize these patterns as templates in .claude/templates/
```

---

### 6. Azure Infrastructure Agents

**Purpose**: Design, optimize, and secure Azure cloud infrastructure with cost-effectiveness and compliance.

#### @azure-architect

**Specialization**: Azure solution architecture design and infrastructure planning

**Use When**:
- Designing new Azure solutions
- Need infrastructure architecture recommendations
- Planning complex multi-service deployments

**Capabilities**:
- Design scalable Azure architectures (App Service, Functions, AKS, etc.)
- Select appropriate Azure services for requirements
- Plan networking and security architecture
- Design high availability and disaster recovery
- Generate architecture diagrams (Mermaid)
- Estimate infrastructure costs

**Invocation**:
```bash
# Via direct delegation
Task @azure-architect "Design Azure architecture for real-time analytics dashboard with 10K concurrent users"
```

#### @infrastructure-optimizer

**Specialization**: Azure cost optimization and resource right-sizing

**Use When**:
- Reducing Azure spending
- Need SKU right-sizing recommendations
- Optimizing resource utilization

**Capabilities**:
- Analyze Azure resource utilization
- Recommend SKU downsizing or upsizing
- Identify idle or underutilized resources
- Suggest reserved instance purchases
- Calculate optimization savings

**Invocation**:
```bash
# Via direct delegation
Task @infrastructure-optimizer "Analyze Azure subscription for cost optimization opportunities"
```

#### @security-auditor

**Specialization**: Azure security posture assessment and compliance validation

**Use When**:
- Need security audit before production
- Validating compliance requirements (SOC2, ISO 27001)
- Identifying security vulnerabilities

**Capabilities**:
- Audit Azure resource configurations
- Validate RBAC and access controls
- Check for exposed secrets or credentials
- Assess network security (NSGs, firewalls)
- Verify encryption and data protection
- Generate compliance reports

**Invocation**:
```bash
# Via direct delegation
Task @security-auditor "Audit invoice-processing-prod resource group for SOC2 compliance"
```

---

### 7. Documentation Agents

**Purpose**: Create, maintain, and optimize markdown documentation with consistent quality and structure.

#### @markdown-expert

**Specialization**: Markdown syntax excellence, documentation structuring, and readability optimization

**Use When**:
- Creating new documentation from scratch
- Reviewing existing markdown for quality
- Need help with complex markdown formatting

**Capabilities**:
- Write clear, well-structured markdown documents
- Apply proper header hierarchy (H1-H6)
- Optimize code blocks with syntax highlighting
- Create tables with appropriate alignment
- Generate Mermaid diagrams for visual content
- Ensure accessibility (alt text, semantic structure)
- Follow Brookside BI brand voice

**Invocation**:
```bash
# Via direct delegation
Task @markdown-expert "Create comprehensive API documentation for invoice processing endpoints"
```

**Quality Standards**:
- Headers follow logical hierarchy (no skipped levels)
- All code blocks have language specifiers
- Links use descriptive anchor text
- Images include meaningful alt text
- Technical instructions are explicit and executable

#### @documentation-orchestrator

**Specialization**: Multi-file documentation updates with comprehensive coordination

**Use When**:
- Need to update documentation across multiple files
- Comprehensive documentation refresh required
- Creating documentation suites (onboarding, API docs, guides)

**Capabilities**:
- Coordinate updates across multiple markdown files
- Generate Mermaid diagrams for visual workflows
- Create cross-linked documentation suites
- Update table of contents and navigation
- Validate markdown syntax across files
- Sync documentation to Notion if requested
- Generate pull requests with documentation changes

**Invocation**:
```bash
# Via slash command (recommended)
/docs:update-complex "Innovation Nexus onboarding" "Create 4-part onboarding suite" --diagrams --create-pr

# Via direct delegation
Task @documentation-orchestrator "Update all API documentation files to include authentication examples"
```

#### @api-documenter

**Specialization**: API reference documentation with OpenAPI/Swagger integration

**Use When**:
- Documenting REST APIs
- Need OpenAPI/Swagger specifications
- Creating API reference guides

**Capabilities**:
- Generate API endpoint documentation
- Create request/response examples
- Document authentication flows
- Generate OpenAPI 3.0 specifications
- Create Postman collection exports
- Write usage guides with code samples

**Invocation**:
```bash
# Via direct delegation
Task @api-documenter "Document invoice submission API endpoints with request/response examples"
```

---

### 8. Support and Coordination Agents

**Purpose**: Facilitate team coordination, activity tracking, and intelligent output formatting across all operations.

#### @team-coordinator

**Specialization**: Intelligent work assignment based on team specializations and workload

**Use When**:
- Need to assign work to appropriate team member
- Routing work based on domain expertise
- Balancing workload across team

**Capabilities**:
- Analyze work type and required expertise
- Match work to team member specializations
- Consider current workload and availability
- Create team-assigned Notion entries
- Track assignment in Agent Activity Hub

**Team Specializations**:
- **Markus Ahling**: Engineering, AI/ML, Operations, Infrastructure
- **Brad Wright**: Sales, Business, Finance, Marketing
- **Stephan Densby**: Operations, Continuous Improvement, Research
- **Alec Fielding**: DevOps, Security, Integrations, R&D
- **Mitch Bisbee**: DevOps, ML, Master Data, Quality Assurance

**Invocation**:
```bash
# Via slash command (recommended)
/team:assign "Design Azure OpenAI integration architecture" idea

# Via direct delegation
Task @team-coordinator "Assign Power BI governance framework research to appropriate team member"
```

#### @activity-logger

**Specialization**: Automated agent activity tracking with intelligent data extraction

**Use When**:
- Recording agent work for transparency
- Tracking productivity metrics
- Maintaining workflow continuity across sessions

**Capabilities**:
- Parse agent work from session context
- Extract deliverables (files created/updated, categorized by type)
- Calculate metrics (lines generated, duration, file count)
- Identify related Notion items (Ideas, Research, Builds)
- Infer next steps from work context
- Update 3-tier tracking (Notion + Markdown + JSON)

**Invocation**:
```bash
# Automatic via hook (no manual invocation needed)
# Hook triggers when Task tool completes agent delegation

# Manual logging if needed:
/agent:log-activity @cost-analyst "Completed" "Analyzed Q4 spending, identified $2,247/month savings"
```

**Auto-Captured Metrics**:
- Files created/updated (categorized: Code, Docs, Infrastructure, Tests, Scripts)
- Lines generated (estimated from file sizes)
- Session duration (start to completion)
- Deliverables (organized by category with file paths)
- Related Notion items
- Next steps

#### @style-orchestrator

**Specialization**: Intelligent output style recommendation based on task, audience, and context

**Use When**:
- Need to choose appropriate communication style
- Creating content for specific audiences
- Want data-driven style recommendations

**Capabilities**:
- Analyze task type and target audience
- Recommend optimal output style from 5 available styles:
  - **Technical Implementer**: Developers, engineers (code-heavy)
  - **Strategic Advisor**: Executives, leadership (business-focused)
  - **Visual Architect**: Cross-functional teams (diagram-rich)
  - **Interactive Teacher**: New team members, trainees (educational)
  - **Compliance Auditor**: Auditors, compliance officers (formal, evidence-based)
- Score all styles (0-100) based on fit
- Query historical performance data from Agent Style Tests
- Provide rationale for recommendation

**Invocation**:
```bash
# Via direct delegation
Task @style-orchestrator "Recommend output style for @cost-analyst analyzing Q4 spending for executives"

# Automatic in style testing commands
/test-agent-style @viability-assessor ?  # Orchestrator automatically selects styles to test
```

**Scoring Algorithm** (0-100 per style):
```
Total Score =
  (30 × Task-Style Fit) +
  (25 × Agent Compatibility) +
  (20 × Historical Performance) +
  (15 × Audience Alignment) +
  (10 × Capability Match)
```

---

## Agent Delegation Patterns

### Pattern 1: Sequential Delegation (Pipeline)

**Use When**: Work must happen in specific order (dependencies between agents)

**Example**:
```bash
# Innovation lifecycle pipeline
Task @ideas-capture "Capture: Real-time Power BI dashboard embedding SDK"
  ↓ (creates Idea with "Needs Research" viability)
Task @research-coordinator "Research feasibility for Power BI SDK idea"
  ↓ (viability score 89/100 - auto-approved)
/autonomous:enable-idea "Power BI Dashboard SDK"
  ↓ (pipeline invokes @build-architect-v2 → @code-generator → @deployment-orchestrator)
Task @knowledge-curator "Archive Power BI SDK build learnings"
```

### Pattern 2: Parallel Delegation (Swarm)

**Use When**: Multiple independent analyses needed simultaneously

**Example**:
```bash
# Research swarm (4 agents execute in parallel)
Task @market-researcher "Analyze competitive landscape for invoice automation"
Task @technical-analyst "Assess Azure Form Recognizer implementation complexity"
Task @cost-feasibility-analyst "Calculate TCO for invoice automation solution"
Task @risk-assessor "Identify security and compliance risks for invoice processing"

# Results synthesized by @research-coordinator into unified viability score
```

### Pattern 3: Conditional Delegation (Branching)

**Use When**: Next agent depends on previous agent's outcome

**Example**:
```bash
Task @viability-assessor "Assess legacy-reporting-api repository quality"
  ↓ (Score: 34/100 - LOW)

IF score < 50:
  Task @archive-manager "Archive legacy-reporting-api with low viability rationale"
ELSE:
  Task @build-architect-v2 "Plan modernization for legacy-reporting-api"
```

### Pattern 4: Iterative Delegation (Feedback Loop)

**Use When**: Work requires multiple refinement cycles

**Example**:
```bash
Task @markdown-expert "Create API documentation for invoice endpoints"
  ↓ (initial draft)
Task @quality-assurance "Review API documentation for completeness"
  ↓ (feedback: missing authentication examples)
Task @markdown-expert "Update API docs with authentication flow examples"
  ↓ (revised draft)
Task @quality-assurance "Final review of API documentation"
  ↓ (approved)
```

---

## Troubleshooting Agent Issues

### Issue: Agent Not Responding

**Symptoms**: Use `Task @agent-name "work"` but nothing happens

**Resolution**:
1. Verify agent exists: Check `.claude/agents/[agent-name].md`
2. Use correct format: `@agent-name` (not `agent-name` or `@agent-name-extra-words`)
3. Provide specific task description (vague tasks may not trigger)
4. Check for conflicting agents (avoid invoking multiple simultaneously)

### Issue: Agent Delivers Incorrect Results

**Symptoms**: Agent completes work but output doesn't match expectations

**Resolution**:
1. Provide more context in task description (be specific about requirements)
2. Check if correct agent for task (use decision tree above)
3. Review agent specification (`.claude/agents/[agent-name].md`) for capabilities
4. Consider sequential delegation instead of single agent (break into smaller tasks)

### Issue: Agent Takes Too Long

**Symptoms**: Agent work exceeds expected duration

**Resolution**:
1. Check task complexity (may need to break into smaller sub-tasks)
2. Verify MCP server connectivity (delays often due to API timeouts)
3. Consider parallel delegation for independent work (swarm pattern)
4. Review Agent Activity Hub for session duration metrics

### Issue: Duplicate Work Across Agents

**Symptoms**: Multiple agents doing similar work

**Resolution**:
1. Use @research-coordinator for research (don't invoke swarm agents directly)
2. Use /autonomous:enable-idea for builds (don't invoke pipeline agents separately)
3. Check Agent Activity Hub before delegating (avoid duplicate sessions)
4. Leverage Knowledge Vault (search for existing patterns before building)

---

## Agent Registry Maintenance

### Adding New Agents

**When to Create New Agent**:
- Repetitive work pattern identified (>5 occurrences)
- Specialized domain expertise needed (not covered by existing agents)
- Clear success criteria and deliverables defined
- Sufficient documentation to train agent

**Creation Process**:
1. Submit via `/innovation:new-idea "New agent for [specific use case]"`
2. Research phase validates demand and scope
3. Agent specification created in `.claude/agents/[agent-name].md`
4. Register in Notion Agent Registry database
5. Test with `/test-agent-style [agent-name] ?` across all output styles
6. Deploy and monitor via Agent Activity Hub

### Deprecating Agents

**When to Deprecate**:
- Zero usage in 90+ days (check Agent Activity Hub)
- Capabilities absorbed by other agents
- Technology no longer used (e.g., agent for deprecated service)

**Deprecation Process**:
1. Mark agent Status = "Deprecated" in Agent Registry
2. Add deprecation notice to agent specification
3. Redirect users to replacement agent
4. Archive after 180 days of zero usage

---

## Next Steps

Continue to:
- **[Database Architecture](03-database-architecture.md)** - Understand Notion data structures and relations
- **[Quick Start Checklist](04-quick-start-checklist.md)** - Complete your first week tasks
- **[Master Reference](../../CLAUDE.md)** - Comprehensive system documentation

---

**Agent Registry - 38+ Specialized Agents Driving Measurable Productivity Across Innovation Workflows**
