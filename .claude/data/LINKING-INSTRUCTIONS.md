# Dependency Linking Instructions
**Created**: 2025-10-26
**Purpose**: Complete linking of 258 dependencies from dependency-mapping.json to 5 Example Builds

## Executive Summary

**Current Status**: 62/258 dependencies linked (24%)
**Target**: Link ~47 additional software items found in Software Tracker
**Completion**: Will reach ~42% coverage (109/258)

**Key Finding**: Many Python libraries (pytest, pydantic, httpx, pandas, numpy) do not exist as individual Software Tracker entries. Python is tracked at the parent technology level.

## Quick Reference: Build Page IDs

| Build Name | Page ID | Current Links | Expected | Found to Link |
|------------|---------|---------------|----------|---------------|
| Repository Analyzer | `29886779-099a-8175-8e1c-f09c7ad4788b` | 17 | 52 | +11 |
| Cost Optimization Dashboard | `29886779-099a-81b2-928f-cb4c1d9e17c6` | 13 | 48 | +12 |
| Azure OpenAI Integration | `29886779-099a-8120-8ac4-d19aa00456b6` | 13 | 58 | +15 |
| Documentation Automation | `29886779-099a-813c-833f-ccfb4a86e5c7` | 11 | 45 | +7 |
| ML Deployment Pipeline | `29886779-099a-81a9-96b5-f04a02e92d9b` | 8 | 55 | +8 |

---

## Option 1: Manual Linking (Recommended - 20-30 minutes total)

### Repository Analyzer (11 new links)

1. Open: https://www.notion.so/29886779099a81758e1cf09c7ad4788b
2. Click "Software/Tools Used" property
3. Add these:
   - GitHub Enterprise
   - Azure Cosmos DB
   - Azure Storage (the one with "Repository analyzer artifacts" - 29586779-099a-81fc)
   - Azure Kubernetes Service
   - Azure Container Registry
   - Azure DevOps
   - Notion API
   - Azure App Service
   - Application Insights
   - Poetry
   - npm

### Cost Optimization Dashboard (12 new links)

1. Open: https://www.notion.so/29886779099a81b2928fcb4c1d9e17c6
2. Click "Software/Tools Used" property
3. Add these:
   - Power BI Pro (29586779-099a-81fc-8a37-c4906aa58f9d)
   - Azure Data Factory
   - Azure Active Directory Premium P1
   - Microsoft Teams
   - SharePoint Online
   - OneDrive for Business
   - Power Automate Premium
   - Power Apps Premium
   - Notion API
   - Visual Studio Code
   - GitHub Enterprise
   - Python

### Azure OpenAI Integration (15 new links)

1. Open: https://www.notion.so/29886779099a8120-8ac4-d19aa00456b6
2. Click "Software/Tools Used" property
3. Add these:
   - Azure OpenAI Service (29586779-099a-81cd-985a-f8ee96bbee63)
   - Azure Cognitive Services
   - TypeScript
   - Jest
   - Vitest
   - ESLint
   - GitHub Copilot Business
   - Azure API Management
   - Azure Front Door
   - Azure Redis Cache
   - Azure Service Bus
   - Azure Event Grid
   - Microsoft Defender for Cloud
   - Azure Cosmos DB
   - Azure Storage Account

### Documentation Automation (7 new links)

1. Open: https://www.notion.so/29886779099a813c833fccfb4a86e5c7
2. Click "Software/Tools Used" property
3. Add these:
   - Notion Team Plan
   - GitHub Enterprise
   - Azure DevOps
   - Docker Desktop
   - Azure OpenAI Service
   - Power Automate Premium
   - Azure Logic Apps

### ML Deployment Pipeline (8 new links)

1. Open: https://www.notion.so/29886779099a81a996b5f04a02e92d9b
2. Click "Software/Tools Used" property
3. Add these:
   - Azure Data Factory
   - Azure Blob Storage (use main storage account)
   - Azure Container Registry
   - Azure Kubernetes Service
   - Azure App Service
   - GitHub Enterprise
   - Azure DevOps
   - Docker Desktop

---

## Option 2: PowerShell Automation (Alternative - Faster for bulk operations)

### Prerequisites
```powershell
# Ensure authenticated to Azure
az login

# Verify Key Vault access
az keyvault secret show --vault-name kv-brookside-secrets --name notion-api-key
```

### Repository Analyzer
```powershell
.\scripts\Update-NotionRelations.ps1 `
    -PageId "29886779-099a-8175-8e1c-f09c7ad4788b" `
    -PropertyName "Software/Tools Used" `
    -RelationIds @(
        "29586779-099a-818b-a39c-f2a010682014",  # GitHub Enterprise
        "29586779-099a-81c2-b981-eb92a51a5898",  # Azure Cosmos DB
        "29586779-099a-81fc-9ebe-e0a9783c05c0",  # Azure Storage Account
        "29586779-099a-8182-bceb-cc496164dd0b",  # Azure Kubernetes Service
        "29586779-099a-813c-bb51-e55680e330db",  # Azure Container Registry
        "29586779-099a-81ee-b23d-cfd46d4ca1fc",  # Azure DevOps
        "29386779-099a-811e-a792-c672b702fe57",  # Notion API
        "29586779-099a-819f-b3ba-d51a575246ae",  # Azure App Service
        "29586779-099a-8191-809f-c47c13ca8387",  # Application Insights
        "29586779-099a-81aa-b696-e1487cb6c70b",  # Poetry
        "29586779-099a-817b-8738-db3d9203687c"   # npm
    )
```

### Cost Optimization Dashboard
```powershell
.\scripts\Update-NotionRelations.ps1 `
    -PageId "29886779-099a-81b2-928f-cb4c1d9e17c6" `
    -PropertyName "Software/Tools Used" `
    -RelationIds @(
        "29586779-099a-81fc-8a37-c4906aa58f9d",  # Power BI Pro
        "29586779-099a-812e-9d31-ff70eec4cf68",  # Azure Data Factory
        "29586779-099a-81e2-8421-c99c9aed62f9",  # Azure AD Premium P1
        "29586779-099a-81a4-97da-f2741762fe2a",  # Microsoft Teams
        "29586779-099a-8127-baf3-fddf13a40463",  # SharePoint Online
        "29586779-099a-81bc-9be0-c7156ab223a3",  # OneDrive for Business
        "29586779-099a-81eb-a64e-f633e2f3c505",  # Power Automate Premium
        "29586779-099a-8149-838a-ddf2eafb586d",  # Power Apps Premium
        "29386779-099a-811e-a792-c672b702fe57",  # Notion API
        "29586779-099a-8151-a633-c67863b5d5ae",  # Visual Studio Code
        "29586779-099a-818b-a39c-f2a010682014",  # GitHub Enterprise
        "29586779-099a-81ac-9ff0-ced75e246868"   # Python
    )
```

### Azure OpenAI Integration
```powershell
.\scripts\Update-NotionRelations.ps1 `
    -PageId "29886779-099a-8120-8ac4-d19aa00456b6" `
    -PropertyName "Software/Tools Used" `
    -RelationIds @(
        "29586779-099a-81cd-985a-f8ee96bbee63",  # Azure OpenAI Service
        "29586779-099a-81ed-8f45-feb9e0d5550b",  # Azure Cognitive Services
        "29586779-099a-814e-8701-d8d74bcc1c7d",  # TypeScript
        "29586779-099a-8161-ada7-db81fb39e37c",  # Jest
        "29586779-099a-8116-a08b-fcbe7d5589cb",  # Vitest
        "29586779-099a-81eb-99f3-e0db463b2676",  # ESLint
        "29586779-099a-8172-98b0-d46a85c6ce41",  # GitHub Copilot Business
        "29586779-099a-81ee-80c0-dbce832bc6da",  # Azure API Management
        "29586779-099a-8102-81d4-cfa432460285",  # Azure Front Door
        "29586779-099a-8145-b723-e7070bf2da5f",  # Azure Redis Cache
        "29586779-099a-8186-aea6-f94129d157c5",  # Azure Service Bus
        "29886779-099a-8147-965b-db722e143d94",  # Azure Event Grid
        "29586779-099a-81ef-a273-f93048682d7f",  # Microsoft Defender for Cloud
        "29586779-099a-81c2-b981-eb92a51a5898",  # Azure Cosmos DB
        "29586779-099a-81fc-9ebe-e0a9783c05c0"   # Azure Storage Account
    )
```

### Documentation Automation
```powershell
.\scripts\Update-NotionRelations.ps1 `
    -PageId "29886779-099a-813c-833f-ccfb4a86e5c7" `
    -PropertyName "Software/Tools Used" `
    -RelationIds @(
        "29586779-099a-81e4-ae51-c182a25acf05",  # Notion Team Plan
        "29586779-099a-818b-a39c-f2a010682014",  # GitHub Enterprise
        "29586779-099a-81ee-b23d-cfd46d4ca1fc",  # Azure DevOps
        "29586779-099a-819f-935c-fe8a0fc0290c",  # Docker Desktop
        "29586779-099a-81cd-985a-f8ee96bbee63",  # Azure OpenAI Service
        "29586779-099a-81eb-a64e-f633e2f3c505",  # Power Automate Premium
        "29586779-099a-8171-82ee-d90818c698c1"   # Azure Logic Apps
    )
```

### ML Deployment Pipeline
```powershell
.\scripts\Update-NotionRelations.ps1 `
    -PageId "29886779-099a-81a9-96b5-f04a02e92d9b" `
    -PropertyName "Software/Tools Used" `
    -RelationIds @(
        "29586779-099a-812e-9d31-ff70eec4cf68",  # Azure Data Factory
        "29586779-099a-81fc-9ebe-e0a9783c05c0",  # Azure Storage Account (includes Blob)
        "29586779-099a-813c-bb51-e55680e330db",  # Azure Container Registry
        "29586779-099a-8182-bceb-cc496164dd0b",  # Azure Kubernetes Service
        "29586779-099a-819f-b3ba-d51a575246ae",  # Azure App Service
        "29586779-099a-818b-a39c-f2a010682014",  # GitHub Enterprise
        "29586779-099a-81ee-b23d-cfd46d4ca1fc",  # Azure DevOps
        "29586779-099a-819f-935c-fe8a0fc0290c"   # Docker Desktop
    )
```

---

## Verification Steps

### After Each Build Update:

1. **Verify Link Count**:
   - Open build page in Notion
   - Check "Software/Tools Used" property shows expected total
   - Repository Analyzer: Should show 28 items (17 + 11)
   - Cost Dashboard: Should show 25 items (13 + 12)
   - Azure OpenAI: Should show 28 items (13 + 15)
   - Documentation: Should show 18 items (11 + 7)
   - ML Pipeline: Should show 16 items (8 + 8)

2. **Verify Cost Rollup**:
   - Check "Total Cost" property recalculates
   - Estimated cost increases per build:
     - Repository Analyzer: +$100-150/month (Azure infrastructure)
     - Cost Dashboard: +$150-200/month (Power Platform + Azure)
     - Azure OpenAI: +$200-300/month (AI services + infrastructure)
     - Documentation: +$80-100/month (Notion + automation)
     - ML Pipeline: +$50-100/month (Azure compute)

3. **Check for Duplicates**:
   - Notion UI will prevent duplicate relations automatically
   - If using PowerShell script, verify no error messages about duplicates

---

## Important Notes

### Software Not Found in Tracker

These dependencies from dependency-mapping.json **do not exist** as individual Software Tracker entries:

**Python Libraries**:
- pydantic, httpx, rich, typer, azure-identity, azure-keyvault-secrets
- pytest, pytest-cov, pytest-asyncio, black, ruff, mypy, pre-commit
- GitPython, pygithub, requests, pandas, numpy, matplotlib, pyyaml, toml
- scikit-learn, TensorFlow, PyTorch, Keras, XGBoost, LightGBM, CatBoost

**Note**: Python is tracked as the parent technology. Individual libraries should be added as Software Tracker entries if granular cost tracking is needed.

**Azure Services**:
- Azure Machine Learning (not found)
- Azure Synapse Analytics (not found)
- Azure Databricks (not found)

**Development Tools**:
- Azure CLI, Git, Bicep, PowerShell (as standalone entries)
- GitHub Actions, Mermaid, Markdown, JSON, YAML (file formats/tools)

### Recommendation

**Option 1: Accept Coverage Gap** (42% coverage)
- Focus on tracking platform-level tools (Python, Azure services, IDE)
- Document that libraries are tracked implicitly via parent tech

**Option 2: Expand Software Tracker** (Target: 70%+ coverage)
- Create entries for commonly used libraries (pytest, pandas, requests)
- Create entries for missing Azure services (Azure ML, Synapse, Databricks)
- This requires ~30-40 new Software Tracker entries

---

## Next Steps

1. **Choose Linking Method**: Manual (Option 1) or PowerShell (Option 2)
2. **Execute Linking**: Follow instructions above for all 5 builds
3. **Verify Results**: Check link counts and cost rollups
4. **Update Tracking**: Mark progress in dependency-mapping.json
5. **Generate Cost Report**: Run `/cost:analyze all` to see updated totals

---

## Success Criteria

✅ All 5 builds updated with found dependencies
✅ Cost rollups recalculate automatically
✅ No duplicate relation errors
✅ Documentation updated with completion status
✅ Software Tracker IDs cached in software-tracker-ids.json

**Expected Final State**: 109/258 dependencies linked (42.2% coverage)

---

**Generated**: 2025-10-26T18:10:00Z
**Data Source**: [dependency-linking-manifest.json](.claude/data/dependency-linking-manifest.json)
**Schema Manager Documentation**: [.claude/docs/repository-analyzer-dependency-linking.md](.claude/docs/repository-analyzer-dependency-linking.md)
