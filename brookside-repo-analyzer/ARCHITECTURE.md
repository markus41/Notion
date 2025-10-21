# Architecture Documentation

**Brookside BI Repository Analyzer** - Enterprise-grade architecture designed to establish comprehensive repository portfolio visibility and drive measurable outcomes through systematic analysis.

**Best for**: Organizations scaling repository management across teams requiring automated intelligence gathering, cost tracking, and knowledge preservation with sustainable deployment patterns.

## Table of Contents

- [System Overview](#system-overview)
- [Core Architecture](#core-architecture)
- [Data Models](#data-models)
- [Component Details](#component-details)
- [Deployment Architecture](#deployment-architecture)
- [Security Architecture](#security-architecture)
- [Data Flow](#data-flow)
- [Integration Points](#integration-points)
- [Performance Considerations](#performance-considerations)
- [Future Enhancements](#future-enhancements)

## System Overview

### Purpose

The Brookside BI Repository Analyzer establishes automated intelligence gathering across GitHub organization repositories, providing multi-dimensional analysis to support:

- **Innovation Management**: Identify reusable patterns and architectural decisions
- **Cost Optimization**: Track dependency costs and identify optimization opportunities
- **Knowledge Preservation**: Automatically document valuable implementation patterns
- **Team Enablement**: Surface Claude Code configurations for enhanced developer productivity

### Design Principles

1. **Microsoft-First Ecosystem**: Prioritize Azure services and M365 integrations
2. **Security by Default**: All credentials via Azure Key Vault, Managed Identity authentication
3. **Cost Transparency**: Track and optimize all software dependencies
4. **Agentic Development**: All outputs structured for AI agent consumption
5. **Scalable Architecture**: Support concurrent analysis across large repository portfolios
6. **Multi-Modal Deployment**: Local CLI, serverless functions, and CI/CD workflows

## Core Architecture

### High-Level Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                      Deployment Layer                          │
├─────────────────┬──────────────────┬───────────────────────────┤
│   Local CLI     │ Azure Functions  │   GitHub Actions          │
│  (on-demand)    │  (scheduled)     │  (event-triggered)        │
└────────┬────────┴────────┬─────────┴─────────┬─────────────────┘
         │                 │                   │
         └─────────────────┼───────────────────┘
                           │
         ┌─────────────────▼────────────────┐
         │   Core Analysis Orchestrator     │
         │  - Repository Discovery          │
         │  - Concurrent Analysis           │
         │  - Result Aggregation            │
         └─────────────────┬────────────────┘
                           │
      ┌────────────────────┼────────────────────┐
      │                    │                    │
┌─────▼──────┐   ┌────────▼────────┐   ┌──────▼──────┐
│ GitHub MCP │   │ Repository      │   │ Notion MCP  │
│ Client     │   │ Analyzers       │   │ Sync Engine │
│ ─────────  │   │ ─────────────   │   │ ─────────── │
│ • Repo     │   │ • Viability     │   │ • Example   │
│   Discovery│   │   Scoring       │   │   Builds    │
│ • Metadata │   │ • Claude        │   │ • Knowledge │
│   Fetch    │   │   Detection     │   │   Vault     │
│ • File     │   │ • Pattern       │   │ • Software  │
│   Reading  │   │   Mining        │   │   Tracker   │
│ • Commit   │   │ • Cost          │   │             │
│   History  │   │   Calculation   │   │             │
└────────────┘   └─────────────────┘   └─────────────┘
                           │
                 ┌─────────▼──────────┐
                 │  Data Persistence  │
                 │  ───────────────   │
                 │  • Analysis Cache  │
                 │  • Cost Database   │
                 │  • Pattern Library │
                 └────────────────────┘
```

### Technology Stack

**Core Framework:**
- Python 3.11
- Poetry for dependency management
- Pydantic for data validation
- httpx for async HTTP operations
- Click for CLI interface

**Azure Services:**
- Azure Key Vault (credential management)
- Azure Functions (serverless execution)
- Azure Application Insights (monitoring)
- Azure Storage (caching)

**External Integrations:**
- GitHub MCP Server (repository operations)
- Notion MCP Server (knowledge base sync)
- Azure MCP Server (cloud operations)

## Data Models

### Core Pydantic Models

#### Repository Model

```python
class Repository(BaseModel):
    """
    Represents a GitHub repository with metadata and computed properties.

    Best for: Type-safe repository data with automatic validation.
    """
    name: str
    full_name: str
    url: HttpUrl
    description: str | None
    primary_language: str | None
    is_private: bool
    is_fork: bool
    is_archived: bool
    default_branch: str
    created_at: datetime
    updated_at: datetime
    pushed_at: datetime | None
    size_kb: int
    stars_count: int
    forks_count: int
    open_issues_count: int
    topics: list[str]

    @property
    def days_since_last_commit(self) -> int:
        """Calculate days since last push"""

    @property
    def is_active(self) -> bool:
        """Active if pushed within last 90 days"""
```

#### ViabilityScore Model

```python
class ViabilityScore(BaseModel):
    """
    Multi-dimensional repository viability assessment (0-100 points).

    Scoring Breakdown:
    - Test Coverage: 30 points
    - Activity: 20 points
    - Documentation: 25 points
    - Dependency Health: 25 points

    Best for: Objective repository prioritization and resource allocation.
    """
    total_score: int = Field(ge=0, le=100)
    test_coverage_score: int = Field(ge=0, le=30)
    activity_score: int = Field(ge=0, le=20)
    documentation_score: int = Field(ge=0, le=25)
    dependency_health_score: int = Field(ge=0, le=25)
    rating: ViabilityRating  # HIGH | MEDIUM | LOW

    @property
    def breakdown(self) -> dict[str, int]:
        """Return component scores for visualization"""
```

#### RepoAnalysis Model

```python
class RepoAnalysis(BaseModel):
    """
    Complete repository analysis result aggregating all dimensions.

    Best for: Comprehensive repository assessment with full context.
    """
    repository: Repository
    languages: dict[str, int]  # Language -> bytes of code
    dependencies: list[Dependency]
    viability: ViabilityScore
    claude_config: ClaudeConfig | None
    commit_stats: CommitStats
    monthly_cost: float
    reusability_rating: ReusabilityRating
    microsoft_services: list[str]
    has_tests: bool
    test_coverage_percentage: float | None
    has_ci_cd: bool
    has_documentation: bool

    @property
    def language_percentages(self) -> dict[str, float]:
        """Calculate language distribution percentages"""
```

#### ClaudeConfig Model

```python
class ClaudeConfig(BaseModel):
    """
    Claude Code configuration detection results.

    Best for: AI agent capability assessment and productivity tracking.
    """
    has_claude_dir: bool
    agents_count: int
    agents: list[str]  # Agent names
    commands_count: int
    commands: list[str]  # Command names
    mcp_servers: list[str]  # Configured MCP servers
    has_claude_md: bool
    maturity_level: ClaudeMaturityLevel  # EXPERT | ADVANCED | INTERMEDIATE | BASIC | NONE

    @property
    def maturity_score(self) -> int:
        """Calculate maturity score (0-100)"""
```

## Component Details

### 1. GitHub MCP Client (`github_mcp_client.py`)

**Purpose**: Abstracts GitHub API operations through MCP protocol with authentication, rate limiting, and error handling.

**Key Responsibilities:**
- Organization repository discovery
- Repository metadata fetching
- File content retrieval (README, dependencies, .claude/)
- Commit history analysis
- Language statistics

**Design Patterns:**
- Async/await for concurrent operations
- Exponential backoff retry logic
- Response caching for reduced API calls
- Context manager for resource cleanup

**Example Usage:**

```python
async with GitHubMCPClient(settings, credentials) as client:
    repos = await client.list_org_repositories("brookside-bi")

    for repo in repos:
        languages = await client.get_repository_languages(repo)
        dependencies = await client.get_repository_dependencies(repo)
        commit_stats = await client.get_commit_activity(repo, days=90)
```

### 2. Repository Analyzer (`analyzers/repo_analyzer.py`)

**Purpose**: Orchestrates multi-dimensional repository analysis and viability scoring.

**Viability Scoring Algorithm:**

```
Total Score (0-100) = Test Coverage + Activity + Documentation + Dependencies

Test Coverage (0-30):
  - No tests: 0
  - Tests exist (base): 10
  - 70%+ coverage: 30
  - Scaled 0-70%: 10 + (coverage / 70 * 20)

Activity (0-20):
  - Commits last 30 days: 20
  - Commits last 90 days: 10
  - No recent commits: 0

Documentation (0-25):
  - README exists: 15
  - Additional docs + active: 25
  - No README: 0

Dependency Health (0-25):
  - 0-10 dependencies: 25
  - 11-30 dependencies: 15
  - 31+ dependencies: 5
```

**Reusability Logic:**

```
Highly Reusable:
  ✓ Viability >= 75
  ✓ Has tests
  ✓ Has documentation
  ✓ Not a fork
  ✓ Active (pushed within 90 days)

Partially Reusable:
  ✓ Viability >= 50
  ✓ Has tests OR documentation

One-Off:
  All other cases
```

### 3. Claude Detector (`analyzers/claude_detector.py`)

**Purpose**: Detect and analyze Claude Code integration maturity.

**Detection Process:**

1. **Directory Scan**: Check for `.claude/` directory
2. **Agent Detection**: Parse `.claude/agents/*.md` files
3. **Command Detection**: Parse `.claude/commands/*.md` files
4. **MCP Configuration**: Parse `.claude.json` for MCP servers
5. **Project Memory**: Check for `CLAUDE.md` or `.claude/CLAUDE.md`

**Maturity Calculation:**

```
Score = (agents_count * 10) + (commands_count * 5) + (mcp_servers * 10) + (has_claude_md * 15)

Levels:
  80-100: Expert    - Comprehensive Claude integration
  60-79:  Advanced  - Well-integrated, multiple agents/commands
  30-59:  Intermediate - Basic agents or commands
  10-29:  Basic     - Minimal integration
  0-9:    None      - No meaningful integration
```

### 4. Pattern Miner (`analyzers/pattern_miner.py`)

**Purpose**: Extract cross-repository patterns for reusability assessment.

**Pattern Types:**

1. **Architectural Patterns**:
   - Serverless functions (Azure Functions)
   - RESTful APIs
   - Microservices
   - Event-driven architecture

2. **Integration Patterns**:
   - Microsoft ecosystem services
   - Common third-party integrations
   - Authentication methods (Azure AD, OAuth)

3. **Design Patterns**:
   - Shared frameworks (FastAPI, Flask, Express)
   - Common libraries (httpx, requests, axios)
   - Testing frameworks (pytest, jest)

**Detection Logic:**

```python
def detect_patterns(analyses: list[RepoAnalysis]) -> list[Pattern]:
    """
    Analyze multiple repositories to extract common patterns.

    Process:
    1. Group by technology stack
    2. Identify shared dependencies
    3. Detect architectural similarities
    4. Calculate reusability scores
    5. Generate usage statistics
    """
```

### 5. Cost Calculator (`analyzers/cost_calculator.py`)

**Purpose**: Calculate monthly costs based on dependencies and software usage.

**Cost Database Structure:**

```json
{
  "azure-functions": {
    "monthly_cost": 5.00,
    "category": "Infrastructure",
    "microsoft_service": "Azure"
  },
  "azure-openai": {
    "monthly_cost": 50.00,
    "category": "AI/ML",
    "microsoft_service": "Azure"
  },
  "sendgrid": {
    "monthly_cost": 15.00,
    "category": "Communication",
    "microsoft_service": "None",
    "microsoft_alternative": "Azure Communication Services"
  }
}
```

**Calculation Logic:**

```python
def calculate_repository_cost(dependencies: list[Dependency]) -> float:
    """
    Calculate total monthly cost for repository dependencies.

    Returns:
        Total monthly cost in USD

    Best for: Transparent cost tracking and optimization opportunities.
    """
    total = 0.0
    for dep in dependencies:
        cost_info = COST_DATABASE.get(dep.name.lower(), {})
        total += cost_info.get("monthly_cost", 0.0)
    return total
```

### 6. Notion Client (`notion_client.py`)

**Purpose**: Synchronize analysis results to Notion databases through MCP protocol.

**Target Databases:**

1. **Example Builds** (`a1cd1528-971d-4873-a176-5e93b93555f6`)
   - Repository name and URL
   - Viability rating
   - Reusability assessment
   - Cost breakdown
   - Claude integration maturity
   - GitHub statistics

2. **Knowledge Vault** (if pattern library created)
   - Pattern descriptions
   - Usage statistics
   - Reusability scores
   - Code examples

3. **Software & Cost Tracker** (`13b5e9de-2dd1-45ec-839a-4f3d50cd8d06`)
   - Dependency tracking
   - Monthly cost aggregation
   - License count
   - Microsoft alternative suggestions

**Sync Strategy:**

```python
async def sync_to_notion(analysis: RepoAnalysis) -> NotionBuildPage:
    """
    Synchronize repository analysis to Notion Example Builds.

    Process:
    1. Search for existing build by repository name
    2. Create or update build entry
    3. Link to Software Tracker dependencies
    4. Calculate cost rollups
    5. Set viability and reusability properties
    6. Add GitHub link and statistics
    """
```

## Deployment Architecture

### 1. Local CLI Deployment

**Use Case**: On-demand analysis by team members

**Architecture:**

```
┌─────────────┐
│  Developer  │
│  Workstation│
└──────┬──────┘
       │
       │ poetry run brookside-analyze scan
       │
┌──────▼──────────────┐
│  CLI Interface      │
│  (Click)            │
└──────┬──────────────┘
       │
       │ Azure Key Vault (credentials)
       │ GitHub MCP (repository data)
       │ Notion MCP (sync)
       │
┌──────▼──────────────┐
│  Analysis Engine    │
│  (sync execution)   │
└─────────────────────┘
```

**Credentials**: Azure CLI authentication → Key Vault

**Execution Time**: 2-5 minutes for full organization scan

### 2. Azure Function Deployment

**Use Case**: Scheduled weekly analysis without manual intervention

**Architecture:**

```
┌─────────────────────────────────────────┐
│  Azure Function App                     │
│  (Consumption Plan)                     │
│  ──────────────────────────────────     │
│                                          │
│  Timer Trigger (weekly)                 │
│  └─ 0 0 0 * * 0 (Sunday midnight UTC)   │
│                                          │
│  HTTP Trigger (manual)                  │
│  └─ POST /manual-scan                   │
│                                          │
│  Health Check                           │
│  └─ GET /health                         │
└─────────────────┬───────────────────────┘
                  │
                  │ Managed Identity
                  │
       ┌──────────┼──────────┐
       │          │          │
┌──────▼────┐  ┌─▼────┐  ┌──▼─────────┐
│ Key Vault │  │GitHub│  │ App Insights│
│ (secrets) │  │ MCP  │  │ (telemetry) │
└───────────┘  └──────┘  └────────────┘
```

**Trigger Schedule**: Weekly on Sundays at 00:00 UTC

**Authentication**: Managed Identity → Key Vault access policy

**Monitoring**: Application Insights for execution tracking

**Cost**: ~$5-7/month (Consumption Plan)

**Configuration:**

```json
{
  "host.json": {
    "functionTimeout": "00:10:00",
    "healthMonitor": {
      "enabled": true
    },
    "logging": {
      "applicationInsights": {
        "samplingSettings": {
          "isEnabled": true,
          "maxTelemetryItemsPerSecond": 5
        }
      }
    }
  }
}
```

### 3. GitHub Actions Deployment

**Use Case**: Event-triggered analysis on repository changes

**Architecture:**

```
┌─────────────────────────────────┐
│  GitHub Actions Workflows       │
└─────────────────┬───────────────┘
                  │
      ┌───────────┼───────────┐
      │           │           │
┌─────▼──────┐ ┌──▼──────┐ ┌─▼──────────┐
│ Test & QA  │ │ Deploy  │ │ Repository │
│ Workflow   │ │ Workflow│ │ Analysis   │
│            │ │         │ │ Workflow   │
│ • pytest   │ │ • Build │ │ • Full scan│
│ • ruff     │ │ • Azure │ │ • Pattern  │
│ • mypy     │ │   deploy│ │   mining   │
│ • bandit   │ │ • Health│ │ • Cost     │
│            │ │   check │ │   calc     │
└────────────┘ └─────────┘ └────────────┘
```

**Triggers:**
- **Test Workflow**: Every push to main/develop, all PRs
- **Deploy Workflow**: Push to main (after tests pass)
- **Analysis Workflow**: Weekly schedule + manual dispatch

**Secrets Required**:
- `AZURE_CREDENTIALS`: Service Principal JSON
- `AZURE_KEYVAULT_NAME`: kv-brookside-secrets
- `AZURE_TENANT_ID`: Tenant GUID
- `AZURE_SUBSCRIPTION_ID`: Subscription GUID
- `GITHUB_ORG`: brookside-bi
- `NOTION_WORKSPACE_ID`: Workspace GUID

## Security Architecture

### Credential Management

**Azure Key Vault Integration:**

```
┌──────────────────────────────────────────┐
│  Azure Key Vault                         │
│  (kv-brookside-secrets)                  │
│  ────────────────────────────────────    │
│                                           │
│  Secrets:                                │
│  ├─ github-personal-access-token         │
│  ├─ notion-api-key                       │
│  └─ azure-openai-api-key (future)        │
│                                           │
│  Access Policies:                        │
│  ├─ User (Markus Ahling): Get, List     │
│  ├─ Function Managed Identity: Get       │
│  └─ GitHub Actions SP: Get               │
└──────────────────────────────────────────┘
```

**Authentication Flow:**

1. **Local Development**:
   ```
   Developer → Azure CLI Login → DefaultAzureCredential → Key Vault
   ```

2. **Azure Function**:
   ```
   Function → Managed Identity → Key Vault Access Policy → Secrets
   ```

3. **GitHub Actions**:
   ```
   Workflow → Service Principal (secret) → Azure Login → Key Vault
   ```

### Data Security

**In Transit:**
- All API calls over HTTPS
- MCP protocol encryption
- GitHub PAT authentication
- Notion API key authentication

**At Rest:**
- Secrets in Azure Key Vault (encrypted)
- No credentials in source code
- No credentials in environment files committed to Git
- `.env` files git-ignored

**Access Control:**
- Azure RBAC for Key Vault access
- GitHub organization-level permissions
- Notion workspace-level permissions
- Principle of least privilege

## Data Flow

### Full Organization Scan Flow

```
1. Initialization
   ├─ Load Settings (config.py)
   ├─ Authenticate Azure (auth.py)
   └─ Retrieve Credentials (Key Vault)

2. Repository Discovery
   ├─ GitHub MCP: List organization repositories
   ├─ Filter out archived/excluded repos
   └─ Store repository metadata

3. Concurrent Analysis (async)
   ├─ For each repository (max 10 concurrent):
   │   ├─ Fetch languages (GitHub API)
   │   ├─ Fetch dependencies (package.json, pyproject.toml, etc.)
   │   ├─ Analyze commit history (90 days)
   │   ├─ Check for tests (tests/, test/, __tests__/)
   │   ├─ Check for CI/CD (.github/workflows/)
   │   ├─ Check for documentation (README.md)
   │   ├─ Detect Claude config (.claude/)
   │   ├─ Calculate viability score
   │   ├─ Assess reusability rating
   │   └─ Calculate monthly cost
   │
   └─ Aggregate results

4. Pattern Mining
   ├─ Group repositories by technology
   ├─ Identify shared dependencies
   ├─ Detect architectural patterns
   └─ Calculate pattern reusability scores

5. Notion Synchronization
   ├─ For each analyzed repository:
   │   ├─ Search Example Builds for existing entry
   │   ├─ Create or update build entry
   │   ├─ Link to Software Tracker dependencies
   │   └─ Verify cost rollup calculation
   │
   └─ Create Knowledge Vault pattern entries

6. Reporting
   ├─ Generate summary statistics
   ├─ Log execution metrics
   └─ Return results to caller
```

### Viability Scoring Data Flow

```
Repository Metadata
   │
   ├─> Test Detection
   │   ├─ Check for test directories
   │   ├─ Estimate coverage (heuristic)
   │   └─> Test Coverage Score (0-30)
   │
   ├─> Activity Analysis
   │   ├─ Parse commit history
   │   ├─ Count commits (30/90 days)
   │   └─> Activity Score (0-20)
   │
   ├─> Documentation Check
   │   ├─ Verify README exists
   │   ├─ Check for additional docs
   │   └─> Documentation Score (0-25)
   │
   ├─> Dependency Health
   │   ├─ Count total dependencies
   │   ├─ Assess complexity risk
   │   └─> Dependency Score (0-25)
   │
   └─> Aggregate Scores
       ├─ Total = Sum of components
       ├─ Rating = HIGH | MEDIUM | LOW
       └─> ViabilityScore Model
```

## Integration Points

### GitHub MCP Integration

**Protocol**: Model Context Protocol (MCP) over HTTP
**Authentication**: Personal Access Token via Authorization header
**Rate Limiting**: 5000 requests/hour (GitHub API)
**Retry Strategy**: Exponential backoff with max 3 retries

**Key Endpoints Used:**
- `GET /orgs/{org}/repos` - List organization repositories
- `GET /repos/{owner}/{repo}` - Repository metadata
- `GET /repos/{owner}/{repo}/languages` - Language statistics
- `GET /repos/{owner}/{repo}/commits` - Commit history
- `GET /repos/{owner}/{repo}/contents/{path}` - File content

### Notion MCP Integration

**Protocol**: Model Context Protocol (MCP) over HTTP
**Authentication**: Bearer token (Integration secret)
**Rate Limiting**: 3 requests/second (Notion API)

**Operations:**
- `notion-search`: Semantic search across workspace
- `notion-fetch`: Retrieve page/database content
- `notion-create-pages`: Create database entries
- `notion-update-page`: Update existing pages

**Target Databases:**
- Example Builds: `a1cd1528-971d-4873-a176-5e93b93555f6`
- Software Tracker: `13b5e9de-2dd1-45ec-839a-4f3d50cd8d06`
- Knowledge Vault: (ID to be configured)

## Performance Considerations

### Concurrent Processing

**Strategy**: Async/await with semaphore-based concurrency control

```python
MAX_CONCURRENT_ANALYSES = 10

async with asyncio.Semaphore(MAX_CONCURRENT_ANALYSES):
    tasks = [analyze_repository(repo) for repo in repositories]
    results = await asyncio.gather(*tasks)
```

**Benefits**:
- Full organization scan (50 repos): ~3-5 minutes
- Single-threaded equivalent: ~30-40 minutes
- Network I/O optimization through concurrent requests

### Caching Strategy

**Cache TTL**: 168 hours (1 week) by default

**Cached Data:**
- Repository metadata (name, URL, description)
- Language statistics
- Dependency lists
- Commit statistics

**Cache Invalidation**:
- Time-based (TTL expiration)
- Manual invalidation via CLI flag `--no-cache`
- Automatic on repository push (GitHub webhook, future)

### Memory Optimization

**Large Repository Handling:**
- Stream file content instead of loading fully into memory
- Limit commit history queries (90 days max)
- Paginate API requests (100 items per page)
- Garbage collection after each repository analysis

## Future Enhancements

### Planned Features

1. **Real-Time Analysis** (Phase 2)
   - GitHub webhook integration
   - Event-driven architecture
   - Azure Event Grid for notifications

2. **Machine Learning Integration** (Phase 3)
   - Pattern prediction using historical data
   - Automated viability scoring improvements
   - Dependency vulnerability prediction

3. **Advanced Cost Analytics** (Phase 4)
   - Real-time cost tracking dashboards
   - Budget alerts and thresholds
   - Cost optimization recommendations
   - TCO analysis by project

4. **Team Collaboration Features** (Phase 5)
   - Shared analysis dashboards
   - Collaborative annotation
   - Team-level metrics and leaderboards

5. **Azure DevOps Integration** (Phase 6)
   - CI/CD pipeline metrics
   - Work item correlation
   - Release frequency tracking
   - DORA metrics calculation

### Scalability Roadmap

**Current Capacity**: 50-100 repositories per scan
**Target Capacity**: 1000+ repositories per scan

**Scaling Strategies:**
1. Distributed processing (Azure Durable Functions)
2. Result caching (Azure Redis Cache)
3. Database sharding (if moving to SQL)
4. CDN for static content (GitHub Pages)

---

**Brookside BI Repository Analyzer** - Enterprise architecture designed to establish comprehensive repository intelligence and drive measurable outcomes through systematic, scalable analysis approaches.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
