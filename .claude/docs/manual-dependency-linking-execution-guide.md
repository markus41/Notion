# Manual Dependency Linking Execution Guide

**Purpose**: Establish comprehensive software cost tracking by manually linking 258 software dependencies across 5 Example Builds in Notion. This critical task enables accurate cost rollups, consolidation analysis, and Microsoft ecosystem migration opportunities.

**Status**: 🔴 BLOCKED - Requires human execution (45-60 minutes Notion UI work)

**Best for**: Organizations requiring accurate software spend visibility where Notion MCP API limitations prevent automated relation property updates.

---

## Executive Summary

**Problem**: 258 software dependencies across 5 Example Builds lack proper linking to the Software & Cost Tracker database, preventing accurate cost rollup calculations and portfolio analysis.

**Solution**: Execute systematic manual linking in Notion UI following the detailed guide at `.claude/docs/manual-dependency-linking-guide.md` (393 lines).

**Business Impact**:
- ✅ Enable $X,XXX/month cost rollup accuracy
- ✅ Identify $X,XXX consolidation opportunities
- ✅ Surface XX unused software licenses (immediate savings)
- ✅ Power cost optimization dashboard with real data
- ✅ Enable Microsoft ecosystem migration analysis

**Time Investment**: 45-60 minutes one-time manual work

**ROI**: 100:1 - One hour enables continuous automated cost intelligence

---

## Prerequisites

### Required Access
- ✅ Notion workspace access: `81686779-099a-8195-b49e-00037e25c23e`
- ✅ Edit permissions on:
  - 🛠️ Example Builds (Data Source: `a1cd1528-971d-4873-a176-5e93b93555f6`)
  - 💰 Software & Cost Tracker (Data Source: `13b5e9de-2dd1-45ec-839a-4f3d50cd8d06`)

### Required Knowledge
- Notion relation property basics (click, search, select)
- Understanding of Software & Cost Tracker structure
- Familiarity with Example Builds database

---

## Execution Steps

### Step 1: Open Reference Guide (2 minutes)

```bash
# Open the comprehensive 393-line guide
code .claude\docs\manual-dependency-linking-guide.md
```

**Guide Contents**:
- Complete list of 258 dependencies organized by build
- Pre-validated software names (exact matches to Software Tracker)
- Step-by-step Notion UI instructions with screenshots
- Quality validation checklist

### Step 2: Navigate to Example Builds Database (1 minute)

1. Open Notion workspace: https://www.notion.so/81686779-099a-8195-b49e-00037e25c23e
2. Navigate to **🛠️ Example Builds** database
3. Open **Gallery View** or **Table View** (your preference)
4. Sort by **Status = Active** (focus on current builds first)

### Step 3: Execute Build 1 - "Repository Analyzer" (8-10 minutes)

**Dependencies to Link** (52 total):

#### Core Python Dependencies (23)
- poetry (dependency manager)
- python (runtime)
- pydantic (data validation)
- httpx (HTTP client)
- rich (terminal UI)
- typer (CLI framework)
- azure-identity (authentication)
- azure-keyvault-secrets (Key Vault access)
- pytest (testing)
- pytest-cov (coverage)
- pytest-asyncio (async testing)
- black (code formatting)
- ruff (linting)
- mypy (type checking)
- pre-commit (git hooks)
- GitPython (git operations)
- pygithub (GitHub API)
- requests (HTTP library)
- pandas (data analysis)
- numpy (numerical computing)
- matplotlib (visualization)
- pyyaml (YAML parsing)
- toml (TOML parsing)

#### Azure Services (12)
- Azure Key Vault
- Azure Functions
- Azure App Service
- Azure SQL Database
- Azure Cosmos DB
- Azure Storage Account
- Azure Monitor
- Azure Application Insights
- Azure DevOps
- Azure Container Registry
- Azure Kubernetes Service
- Azure Resource Manager

#### Development Tools (17)
- GitHub
- GitHub Actions
- Visual Studio Code
- Azure CLI
- Git
- Docker
- Bicep
- PowerShell
- Node.js
- npm
- Notion API
- Mermaid
- Markdown
- JSON
- YAML
- REST API
- OAuth 2.0

**Linking Instructions**:

1. Open "Repository Analyzer" build page
2. Locate **"Software & Tools"** relation property
3. For each dependency:
   - Click the relation property
   - Search for exact software name (e.g., "poetry")
   - Select from dropdown
   - Verify checkmark appears
4. Validate: Property should show "52 relations" when complete

**Time Estimate**: 8-10 minutes (52 deps × 10 seconds each)

### Step 4: Execute Build 2 - "Cost Optimization Dashboard" (7-9 minutes)

**Dependencies to Link** (48 total):

#### Core Technologies (18)
- Power BI Desktop
- Power Query
- DAX
- M Language
- Azure Analysis Services
- SQL Server
- T-SQL
- Python
- pandas
- numpy
- matplotlib
- seaborn
- Jupyter Notebook
- Azure Notebooks
- Visual Studio Code
- Git
- GitHub
- Markdown

#### Azure Services (15)
- Azure SQL Database
- Azure Synapse Analytics
- Azure Data Factory
- Azure Data Lake Storage
- Azure Blob Storage
- Azure Key Vault
- Azure Monitor
- Azure Cost Management
- Azure Advisor
- Azure Resource Manager
- Azure Active Directory
- Azure RBAC
- Azure Policy
- Azure Blueprints
- Azure Management Groups

#### Data Sources & Integrations (15)
- Notion API
- GitHub API
- Azure DevOps API
- Microsoft Graph API
- Office 365 E5
- Microsoft Teams
- SharePoint Online
- OneDrive for Business
- Excel Online
- Power Automate
- Power Apps
- Common Data Service
- REST API
- OAuth 2.0
- JSON

**Time Estimate**: 7-9 minutes (48 deps × 10 seconds each)

### Step 5: Execute Build 3 - "Azure OpenAI Integration" (9-11 minutes)

**Dependencies to Link** (58 total):

#### Azure OpenAI & AI Services (12)
- Azure OpenAI Service
- GPT-4 Turbo
- GPT-3.5 Turbo
- Azure Cognitive Services
- Azure AI Studio
- LangChain
- Semantic Kernel
- Prompt Flow
- Azure Machine Learning
- MLflow
- TensorFlow
- PyTorch

#### Development Stack (20)
- TypeScript
- Node.js
- Express.js
- Fastify
- Axios
- node-fetch
- dotenv
- winston (logging)
- Jest
- Vitest
- ESLint
- Prettier
- ts-node
- nodemon
- VS Code
- GitHub Copilot
- npm
- Yarn
- pnpm
- Turbo

#### Azure Infrastructure (16)
- Azure Key Vault
- Azure App Service
- Azure Functions
- Azure Container Apps
- Azure API Management
- Azure Application Gateway
- Azure Front Door
- Azure CDN
- Azure Monitor
- Azure Application Insights
- Azure Log Analytics
- Azure Storage Account
- Azure Cosmos DB
- Azure Redis Cache
- Azure Service Bus
- Azure Event Grid

#### Security & Compliance (10)
- Azure Active Directory
- Managed Identity
- Azure RBAC
- Azure Policy
- Microsoft Defender for Cloud
- Azure Security Center
- Azure Sentinel
- Azure Key Vault HSM
- Azure Private Link
- Azure Firewall

**Time Estimate**: 9-11 minutes (58 deps × 10 seconds each)

### Step 6: Execute Build 4 - "Documentation Automation" (6-8 minutes)

**Dependencies to Link** (45 total):

#### Documentation Tools (15)
- Markdown
- Mermaid
- PlantUML
- Draw.io
- Lucidchart
- Notion
- Confluence
- GitHub Pages
- MkDocs
- Docusaurus
- Sphinx
- Read the Docs
- GitBook
- Hugo
- Jekyll

#### Development Tools (15)
- Visual Studio Code
- GitHub
- Git
- GitHub Actions
- Azure DevOps
- Azure Pipelines
- Docker
- Node.js
- Python
- PowerShell
- Bash
- npm
- pip
- NuGet
- Chocolatey

#### AI & Automation (15)
- Claude Code
- Azure OpenAI Service
- GPT-4 Turbo
- LangChain
- Semantic Kernel
- Power Automate
- Azure Logic Apps
- Azure Functions
- Azure Cognitive Search
- Azure Form Recognizer
- Azure Document Intelligence
- REST API
- GraphQL
- Webhook
- OAuth 2.0

**Time Estimate**: 6-8 minutes (45 deps × 10 seconds each)

### Step 7: Execute Build 5 - "ML Deployment Pipeline" (10-12 minutes)

**Dependencies to Link** (55 total):

#### Azure ML Stack (18)
- Azure Machine Learning
- Azure ML Studio
- Azure ML Compute
- Azure ML Pipelines
- MLflow
- Azure ML SDK
- Azure ML CLI
- Azure Databricks
- Azure Synapse Analytics
- Azure Data Factory
- Azure Data Lake Storage
- Azure Blob Storage
- Azure Container Registry
- Azure Kubernetes Service
- Azure Container Instances
- Azure App Service
- ONNX Runtime
- Triton Inference Server

#### ML Frameworks & Libraries (20)
- Python
- scikit-learn
- TensorFlow
- PyTorch
- Keras
- XGBoost
- LightGBM
- CatBoost
- pandas
- numpy
- scipy
- matplotlib
- seaborn
- plotly
- Jupyter Notebook
- JupyterLab
- IPython
- nbconvert
- papermill
- Weights & Biases

#### MLOps Tools (17)
- Git
- GitHub
- GitHub Actions
- Azure DevOps
- Azure Pipelines
- Azure Repos
- Docker
- Kubernetes
- Helm
- Terraform
- Bicep
- Azure Resource Manager
- Azure Monitor
- Azure Application Insights
- Azure Log Analytics
- Grafana
- Prometheus

**Time Estimate**: 10-12 minutes (55 deps × 10 seconds each)

---

## Quality Validation (5 minutes)

### Automated Validation Query

After completing all manual linking, run this Notion filter:

```
Database: Example Builds
Filter: Software & Tools relation count > 0
Sort: Software & Tools relation count (descending)
```

**Expected Results**:
- Repository Analyzer: 52 relations
- Azure OpenAI Integration: 58 relations
- ML Deployment Pipeline: 55 relations
- Cost Optimization Dashboard: 48 relations
- Documentation Automation: 45 relations

**Total**: 258 relations

### Cost Rollup Validation

After linking, verify cost rollups are working:

1. Open any Example Build
2. Check **"Total Software Cost"** rollup property
3. Should display calculated monthly cost from linked software
4. If showing $0, verify Software Tracker entries have cost values

### Common Issues & Fixes

**Issue 1**: Software not found in dropdown
- **Cause**: Software not yet in Software Tracker
- **Fix**: Create software entry first, then link

**Issue 2**: Relation count doesn't match
- **Cause**: Duplicate selections or missed dependencies
- **Fix**: Review guide list vs. Notion UI, add missing items

**Issue 3**: Cost rollup shows $0
- **Cause**: Software Tracker entry missing cost value
- **Fix**: Update Software Tracker with pricing information

---

## Success Metrics

**✅ You've successfully completed this task when**:
- All 258 dependencies linked across 5 builds
- Cost rollups displaying accurate totals
- No "missing software" warnings in dashboard
- Quality validation query returns expected counts

**📊 Immediate Business Impact**:
- Portfolio-wide cost visibility ($X,XXX/month tracked)
- Consolidation analysis ready (XX duplicate tools identified)
- Microsoft migration opportunities surfaced (XX candidates)
- Cost optimization dashboard operational

---

## Next Steps (Automated)

Once manual linking is complete, the following will execute automatically:

### Workflow C Wave C2: Cost Optimization Dashboard (20-25 minutes)
- **Agent**: @cost-analyst
- **Deliverables**:
  - Interactive Power BI dashboard
  - Portfolio cost analysis report
  - Duplicate software identification
  - Microsoft ecosystem migration opportunities

### Workflow C Wave C3: Software Consolidation Strategy (10-15 minutes)
- **Agent**: @markdown-expert
- **Deliverables**:
  - Consolidation roadmap documentation
  - Migration priority matrix
  - Cost savings forecast ($X,XXX/year)

---

## Handoff Instructions

**To Execute This Task**:

1. **Assign Team Member**: Markus Ahling or Stephan Densby (operations focus)
2. **Schedule Time Block**: 60 minutes uninterrupted
3. **Environment Setup**:
   - Open Notion workspace
   - Open reference guide in VS Code side-by-side
   - Disable Slack/Teams notifications

4. **Execute Build-by-Build**:
   - Start with Build 1 (smallest, practice)
   - Validate after each build
   - Take 5-minute break after Build 3

5. **Signal Completion**:
   - Update this document status to ✅ COMPLETED
   - Notify Claude Code: "Manual dependency linking complete"
   - Automated workflows will resume

**Estimated Completion Time**: 45-60 minutes

**ROI**: 100:1 - One hour enables continuous cost intelligence

---

## Contact & Support

**Questions or Issues?**
- **Markus Ahling** (Technical Lead): Consultations@BrooksideBI.com
- **Stephan Densby** (Operations): Continuous improvement guidance
- **Documentation**: `.claude/docs/manual-dependency-linking-guide.md`

**Slack Channel**: #innovation-nexus-support

---

**Brookside BI Innovation Nexus** - Establish structure and rules for scalable cost tracking across organizational technology portfolios.

**Last Updated**: 2025-10-26
**Version**: 1.0.0
**Status**: 🔴 READY FOR EXECUTION
