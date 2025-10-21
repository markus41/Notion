# API Documentation

**Brookside BI Repository Analyzer** - Comprehensive API reference designed to establish clear interfaces for programmatic repository analysis and integration workflows.

**Best for**: Organizations requiring automated repository intelligence gathering through CLI commands, Python SDK, or HTTP endpoints.

## Table of Contents

- [CLI Interface](#cli-interface)
- [Python SDK](#python-sdk)
- [Azure Function HTTP API](#azure-function-http-api)
- [Data Models](#data-models)
- [Error Handling](#error-handling)
- [Rate Limits](#rate-limits)
- [Examples](#examples)

## CLI Interface

### Installation

```bash
poetry install
```

### Global Options

All commands support these global flags:

| Flag | Description | Default |
|------|-------------|---------|
| `--config PATH` | Custom configuration file path | `.env` |
| `--verbose` | Enable verbose logging | `False` |
| `--quiet` | Suppress non-error output | `False` |
| `--no-cache` | Disable result caching | `False` |

### Commands

#### `scan` - Scan Organization Repositories

Analyzes all repositories in the configured GitHub organization.

**Usage:**
```bash
brookside-analyze scan [OPTIONS]
```

**Options:**

| Option | Type | Description | Default |
|--------|------|-------------|---------|
| `--full` | Flag | Perform deep analysis with all features | `False` |
| `--sync` | Flag | Synchronize results to Notion | `False` |
| `--no-sync` | Flag | Skip Notion synchronization | `False` |
| `--exclude REPO` | Multiple | Repository names to exclude | `[]` |
| `--deep` | Flag | Enable deep code analysis (slower) | `False` |
| `--max-concurrent INT` | Integer | Maximum concurrent analyses | `10` |

**Examples:**

```bash
# Quick scan without Notion sync
poetry run brookside-analyze scan

# Full analysis with Notion sync
poetry run brookside-analyze scan --full --sync

# Scan with specific exclusions
poetry run brookside-analyze scan --exclude test-repo --exclude old-prototype

# Deep analysis with custom concurrency
poetry run brookside-analyze scan --deep --max-concurrent 5
```

**Output:**

```
🔍 Scanning organization: brookside-bi
   Found 47 repositories

📊 Analyzing repositories...
   ✓ repo-1: Viability HIGH (85/100), Reusability HIGHLY_REUSABLE
   ✓ repo-2: Viability MEDIUM (62/100), Reusability PARTIALLY_REUSABLE
   ...

📈 Analysis Summary:
   Total Repositories: 47
   High Viability: 12 (25.5%)
   Medium Viability: 28 (59.6%)
   Low Viability: 7 (14.9%)

   Highly Reusable: 15 (31.9%)
   Partially Reusable: 22 (46.8%)
   One-Off: 10 (21.3%)

   Total Monthly Cost: $1,247.00
   Average Cost per Repo: $26.53

💾 Syncing to Notion...
   ✓ Created/updated 47 Example Build entries
   ✓ Linked 183 software dependencies
   ✓ Cost rollups verified

✅ Scan complete in 4m 32s
```

#### `analyze` - Analyze Single Repository

Analyzes a specific repository in detail.

**Usage:**
```bash
brookside-analyze analyze REPO_NAME [OPTIONS]
```

**Arguments:**

| Argument | Type | Description | Required |
|----------|------|-------------|----------|
| `REPO_NAME` | String | Repository name (without org prefix) | Yes |

**Options:**

| Option | Type | Description | Default |
|--------|------|-------------|---------|
| `--deep` | Flag | Enable deep code analysis | `False` |
| `--sync` | Flag | Sync result to Notion | `False` |
| `--output FILE` | Path | Save JSON result to file | `None` |

**Examples:**

```bash
# Basic analysis
poetry run brookside-analyze analyze my-repo

# Deep analysis with Notion sync
poetry run brookside-analyze analyze my-repo --deep --sync

# Save results to JSON file
poetry run brookside-analyze analyze my-repo --output results.json
```

**Output:**

```
📦 Repository: brookside-bi/my-repo
🔗 URL: https://github.com/brookside-bi/my-repo

📊 Viability Analysis:
   Total Score: 85/100 (HIGH)
   ├─ Test Coverage: 28/30 (93% coverage)
   ├─ Activity: 20/20 (15 commits in last 30 days)
   ├─ Documentation: 25/25 (Comprehensive)
   └─ Dependencies: 12/25 (42 dependencies)

🔄 Reusability: HIGHLY_REUSABLE

🤖 Claude Integration:
   Maturity: EXPERT (95/100)
   ├─ Agents: 8
   ├─ Commands: 12
   ├─ MCP Servers: 3 (notion, github, azure)
   └─ Project Memory: Yes

💰 Cost Analysis:
   Monthly Cost: $67.00
   ├─ Azure Functions: $5.00
   ├─ Azure OpenAI: $50.00
   └─ GitHub Actions: $12.00

📈 Statistics:
   Primary Language: Python (78%)
   Stars: 24
   Forks: 5
   Open Issues: 3
   Last Updated: 2 days ago

✅ Analysis complete
```

#### `patterns` - Extract Cross-Repository Patterns

Analyzes all repositories to identify common architectural patterns.

**Usage:**
```bash
brookside-analyze patterns [OPTIONS]
```

**Options:**

| Option | Type | Description | Default |
|--------|------|-------------|---------|
| `--min-usage INT` | Integer | Minimum repos using pattern | `3` |
| `--output FILE` | Path | Save JSON results to file | `None` |
| `--sync` | Flag | Sync patterns to Knowledge Vault | `False` |

**Examples:**

```bash
# Extract patterns with default settings
poetry run brookside-analyze patterns

# Only show patterns used in 5+ repos
poetry run brookside-analyze patterns --min-usage 5

# Save and sync to Notion
poetry run brookside-analyze patterns --output patterns.json --sync
```

**Output:**

```
🔍 Extracting cross-repository patterns...

📊 Pattern Analysis:

🏗️  Architectural Patterns:
   ├─ Serverless Functions (Azure Functions)
   │  Used in: 12 repositories
   │  Reusability Score: 90/100
   │
   ├─ RESTful API Design
   │  Used in: 18 repositories
   │  Reusability Score: 85/100
   │
   └─ Microservices Architecture
      Used in: 7 repositories
      Reusability Score: 75/100

🔗 Integration Patterns:
   ├─ Azure Key Vault (Credential Management)
   │  Used in: 15 repositories
   │  Reusability Score: 95/100
   │
   └─ Notion MCP Integration
      Used in: 8 repositories
      Reusability Score: 80/100

🎨 Design Patterns:
   ├─ FastAPI Framework
   │  Used in: 14 repositories
   │  Reusability Score: 88/100
   │
   └─ Pydantic Data Validation
      Used in: 19 repositories
      Reusability Score: 92/100

✅ Found 8 patterns across 47 repositories
```

#### `costs` - Calculate Portfolio Costs

Aggregates and analyzes costs across all repositories.

**Usage:**
```bash
brookside-analyze costs [OPTIONS]
```

**Options:**

| Option | Type | Description | Default |
|--------|------|-------------|---------|
| `--detailed` | Flag | Show per-repository breakdown | `False` |
| `--category CATEGORY` | String | Filter by category | `None` |
| `--microsoft-only` | Flag | Only show Microsoft services | `False` |
| `--output FILE` | Path | Save JSON results to file | `None` |

**Examples:**

```bash
# Summary costs
poetry run brookside-analyze costs

# Detailed per-repository breakdown
poetry run brookside-analyze costs --detailed

# Only infrastructure costs
poetry run brookside-analyze costs --category Infrastructure

# Microsoft services only
poetry run brookside-analyze costs --microsoft-only
```

**Output:**

```
💰 Portfolio Cost Analysis

📊 Total Monthly Costs: $1,247.00
   Annual Projection: $14,964.00

📈 Cost Breakdown by Category:
   ├─ Infrastructure: $487.00 (39.1%)
   ├─ AI/ML: $425.00 (34.1%)
   ├─ Development: $198.00 (15.9%)
   ├─ Communication: $87.00 (7.0%)
   └─ Security: $50.00 (4.0%)

🏢 Microsoft Services: $892.00 (71.5%)
   ├─ Azure Functions: $247.00
   ├─ Azure OpenAI: $475.00
   ├─ Azure Key Vault: $12.00
   ├─ Azure SQL: $108.00
   └─ Microsoft 365: $50.00

🔧 Third-Party Services: $355.00 (28.5%)
   ├─ SendGrid: $67.00
   ├─ Stripe: $125.00
   ├─ Auth0: $98.00
   └─ Datadog: $65.00

💡 Optimization Opportunities:
   ├─ 3 unused tools detected (save $45/month)
   ├─ 2 consolidation opportunities (save $78/month)
   └─ 4 Microsoft alternatives available (save $115/month)

✅ Total Potential Savings: $238/month ($2,856/year)
```

## Python SDK

### Installation

```python
from src.config import get_settings
from src.auth import CredentialManager
from src.github_mcp_client import GitHubMCPClient
from src.analyzers.repo_analyzer import RepositoryAnalyzer
```

### Basic Usage

```python
import asyncio
from src.config import get_settings
from src.auth import CredentialManager
from src.github_mcp_client import GitHubMCPClient
from src.analyzers.repo_analyzer import RepositoryAnalyzer

async def analyze_organization():
    """Analyze all repositories in organization."""

    # Initialize configuration and credentials
    settings = get_settings()
    creds = CredentialManager(settings)

    # Create GitHub client
    async with GitHubMCPClient(settings, creds) as github:

        # List all repositories
        repos = await github.list_org_repositories(settings.github.organization)

        # Initialize analyzer
        analyzer = RepositoryAnalyzer(github)

        # Analyze each repository
        for repo in repos:
            analysis = await analyzer.analyze_repository(repo, deep_analysis=True)

            print(f"Repository: {repo.name}")
            print(f"Viability: {analysis.viability.rating.value}")
            print(f"Monthly Cost: ${analysis.monthly_cost}")
            print()

# Run analysis
asyncio.run(analyze_organization())
```

### Core Classes

#### `GitHubMCPClient`

**Purpose**: GitHub API wrapper with MCP protocol support.

**Constructor:**
```python
GitHubMCPClient(settings: Settings, credentials: CredentialManager)
```

**Methods:**

```python
async def list_org_repositories(org: str) -> list[Repository]:
    """
    List all repositories in organization.

    Args:
        org: Organization name

    Returns:
        List of Repository objects

    Raises:
        GitHubAPIError: If API request fails
        AuthenticationError: If credentials invalid
    """

async def get_repository_languages(repo: Repository) -> dict[str, int]:
    """
    Get language statistics for repository.

    Args:
        repo: Repository object

    Returns:
        Dictionary mapping language -> bytes of code

    Example:
        {"Python": 125000, "TypeScript": 45000}
    """

async def get_repository_dependencies(repo: Repository) -> list[Dependency]:
    """
    Extract dependencies from package files.

    Supports:
    - Python: pyproject.toml, requirements.txt
    - JavaScript/TypeScript: package.json
    - .NET: *.csproj

    Args:
        repo: Repository object

    Returns:
        List of Dependency objects
    """

async def get_commit_activity(repo: Repository, days: int = 90) -> CommitStats:
    """
    Analyze commit history and activity.

    Args:
        repo: Repository object
        days: Number of days to analyze (default 90)

    Returns:
        CommitStats with activity metrics
    """

async def check_file_exists(repo: Repository, path: str) -> bool:
    """
    Check if file or directory exists in repository.

    Args:
        repo: Repository object
        path: File/directory path

    Returns:
        True if exists, False otherwise
    """
```

#### `RepositoryAnalyzer`

**Purpose**: Multi-dimensional repository analysis engine.

**Constructor:**
```python
RepositoryAnalyzer(github_client: GitHubMCPClient)
```

**Methods:**

```python
async def analyze_repository(
    repo: Repository,
    deep_analysis: bool = True
) -> RepoAnalysis:
    """
    Perform comprehensive repository analysis.

    Args:
        repo: Repository to analyze
        deep_analysis: Enable deep code analysis (slower but thorough)

    Returns:
        RepoAnalysis with complete assessment

    Example:
        >>> analysis = await analyzer.analyze_repository(repo)
        >>> print(f"Viability: {analysis.viability.rating.value}")
        HIGH
    """

def calculate_viability_score(
    repo: Repository,
    has_tests: bool,
    test_coverage: float | None,
    has_documentation: bool,
    dependencies_count: int,
    commit_stats: CommitStats,
) -> ViabilityScore:
    """
    Calculate repository viability score (0-100).

    Scoring breakdown:
    - Test Coverage: 30 points max
    - Recent Activity: 20 points max
    - Documentation: 25 points max
    - Dependency Health: 25 points max

    Args:
        repo: Repository object
        has_tests: Whether repository has tests
        test_coverage: Test coverage percentage (0-100)
        has_documentation: Whether documentation exists
        dependencies_count: Number of dependencies
        commit_stats: Commit statistics

    Returns:
        ViabilityScore with detailed breakdown

    Example:
        >>> score = analyzer.calculate_viability_score(
        ...     repo=repo,
        ...     has_tests=True,
        ...     test_coverage=85.0,
        ...     has_documentation=True,
        ...     dependencies_count=12,
        ...     commit_stats=stats
        ... )
        >>> print(score.total_score)
        87
    """
```

#### `ClaudeDetector`

**Purpose**: Detect and analyze Claude Code integration maturity.

**Constructor:**
```python
ClaudeDetector(github_client: GitHubMCPClient)
```

**Methods:**

```python
async def detect_claude_config(repo: Repository) -> ClaudeConfig | None:
    """
    Detect Claude Code configuration in repository.

    Analyzes:
    - .claude/ directory structure
    - Agent definitions
    - Slash commands
    - MCP server configurations
    - Project memory (CLAUDE.md)

    Args:
        repo: Repository object

    Returns:
        ClaudeConfig if integration found, None otherwise

    Example:
        >>> config = await detector.detect_claude_config(repo)
        >>> if config:
        ...     print(f"Maturity: {config.maturity_level.value}")
        EXPERT
    """
```

## Azure Function HTTP API

### Base URL

```
https://func-repo-analyzer.azurewebsites.net
```

### Authentication

All endpoints require function key authentication:

```
Authorization: Bearer <FUNCTION_KEY>
```

Or query parameter:

```
?code=<FUNCTION_KEY>
```

### Endpoints

#### `GET /health`

Health check endpoint for monitoring.

**Authentication**: None (anonymous)

**Request:**
```http
GET /health HTTP/1.1
Host: func-repo-analyzer.azurewebsites.net
```

**Response:**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "timestamp": "2024-10-21T12:34:56Z",
  "services": {
    "azure_keyvault": "connected",
    "github_api": "connected",
    "notion_api": "connected"
  }
}
```

**Status Codes:**
- `200 OK`: Service healthy
- `503 Service Unavailable`: Service unhealthy

#### `POST /manual-scan`

Trigger manual repository scan.

**Authentication**: Function key required

**Request:**
```http
POST /manual-scan HTTP/1.1
Host: func-repo-analyzer.azurewebsites.net
Authorization: Bearer <FUNCTION_KEY>
Content-Type: application/json

{
  "deep_analysis": true,
  "sync_to_notion": true,
  "exclude_repos": ["test-repo", "archive-old"],
  "only_repos": ["specific-repo"]
}
```

**Request Body Schema:**

```typescript
{
  deep_analysis?: boolean;      // Enable deep analysis (default: true)
  sync_to_notion?: boolean;     // Sync results to Notion (default: true)
  exclude_repos?: string[];     // Repository names to exclude
  only_repos?: string[];        // Only analyze these repositories
}
```

**Response:**
```json
{
  "status": "success",
  "scan_id": "scan_20241021_123456",
  "repositories_analyzed": 47,
  "execution_time_seconds": 287,
  "results_summary": {
    "high_viability": 12,
    "medium_viability": 28,
    "low_viability": 7,
    "total_monthly_cost": 1247.00
  },
  "notion_sync": {
    "builds_created": 15,
    "builds_updated": 32,
    "dependencies_linked": 183
  }
}
```

**Status Codes:**
- `200 OK`: Scan completed successfully
- `400 Bad Request`: Invalid request parameters
- `401 Unauthorized`: Missing or invalid function key
- `500 Internal Server Error`: Scan failed

#### Timer Trigger (Internal)

Weekly scheduled scan - not exposed as HTTP endpoint.

**Schedule**: Every Sunday at 00:00 UTC (`0 0 0 * * 0`)

**Behavior**:
- Scans all organization repositories
- Deep analysis enabled
- Automatic Notion synchronization
- Results logged to Application Insights

## Data Models

### Repository

```typescript
{
  name: string;                    // Repository name
  full_name: string;               // Org/repository
  url: string;                     // GitHub URL
  description: string | null;      // Repository description
  primary_language: string | null; // Primary language
  is_private: boolean;             // Private repository
  is_fork: boolean;                // Is fork
  is_archived: boolean;            // Archived status
  default_branch: string;          // Default branch name
  created_at: string;              // ISO 8601 datetime
  updated_at: string;              // ISO 8601 datetime
  pushed_at: string | null;        // ISO 8601 datetime
  size_kb: number;                 // Size in kilobytes
  stars_count: number;             // GitHub stars
  forks_count: number;             // Fork count
  open_issues_count: number;       // Open issues
  topics: string[];                // Repository topics
}
```

### ViabilityScore

```typescript
{
  total_score: number;              // 0-100
  test_coverage_score: number;      // 0-30
  activity_score: number;           // 0-20
  documentation_score: number;      // 0-25
  dependency_health_score: number;  // 0-25
  rating: "HIGH" | "MEDIUM" | "LOW";
}
```

### RepoAnalysis

```typescript
{
  repository: Repository;
  languages: { [key: string]: number };  // Language -> bytes
  dependencies: Dependency[];
  viability: ViabilityScore;
  claude_config: ClaudeConfig | null;
  commit_stats: CommitStats;
  monthly_cost: number;
  reusability_rating: "HIGHLY_REUSABLE" | "PARTIALLY_REUSABLE" | "ONE_OFF";
  microsoft_services: string[];
  has_tests: boolean;
  test_coverage_percentage: number | null;
  has_ci_cd: boolean;
  has_documentation: boolean;
}
```

### ClaudeConfig

```typescript
{
  has_claude_dir: boolean;
  agents_count: number;
  agents: string[];               // Agent names
  commands_count: number;
  commands: string[];             // Command names
  mcp_servers: string[];          // MCP server names
  has_claude_md: boolean;
  maturity_level: "EXPERT" | "ADVANCED" | "INTERMEDIATE" | "BASIC" | "NONE";
}
```

## Error Handling

### Error Response Format

```json
{
  "error": {
    "code": "GITHUB_API_ERROR",
    "message": "Failed to fetch repository data",
    "details": "Rate limit exceeded. Retry after 3600 seconds.",
    "timestamp": "2024-10-21T12:34:56Z"
  }
}
```

### Error Codes

| Code | Description | HTTP Status |
|------|-------------|-------------|
| `AUTHENTICATION_ERROR` | Invalid or missing credentials | 401 |
| `GITHUB_API_ERROR` | GitHub API request failed | 502 |
| `NOTION_API_ERROR` | Notion API request failed | 502 |
| `REPOSITORY_NOT_FOUND` | Repository does not exist | 404 |
| `VALIDATION_ERROR` | Invalid request parameters | 400 |
| `RATE_LIMIT_EXCEEDED` | API rate limit exceeded | 429 |
| `INTERNAL_ERROR` | Unexpected server error | 500 |

### Python Exception Hierarchy

```python
BrooksideAnalyzerError           # Base exception
├─ AuthenticationError           # Credential issues
├─ ConfigurationError            # Invalid configuration
├─ GitHubAPIError                # GitHub API failures
│  ├─ RepositoryNotFoundError
│  └─ RateLimitExceededError
├─ NotionAPIError                # Notion API failures
└─ AnalysisError                 # Analysis failures
   ├─ PatternDetectionError
   └─ CostCalculationError
```

## Rate Limits

### GitHub API

- **Authenticated**: 5,000 requests/hour
- **Search**: 30 requests/minute
- **Recommendation**: Use organization-level PAT for higher limits

### Notion API

- **Rate Limit**: 3 requests/second
- **Recommendation**: Implement request queuing with delays

### Azure Function

- **Consumption Plan**: No request limits
- **Timeout**: 10 minutes per execution

## Examples

### Full Organization Analysis

```python
import asyncio
from src.config import get_settings
from src.auth import CredentialManager
from src.github_mcp_client import GitHubMCPClient
from src.analyzers.repo_analyzer import RepositoryAnalyzer
from src.notion_client import NotionClient

async def full_analysis():
    """Complete organization analysis with Notion sync."""

    # Initialize
    settings = get_settings()
    creds = CredentialManager(settings)

    async with GitHubMCPClient(settings, creds) as github:
        # List repositories
        repos = await github.list_org_repositories("brookside-bi")
        print(f"Found {len(repos)} repositories")

        # Analyze each
        analyzer = RepositoryAnalyzer(github)
        analyses = []

        for repo in repos:
            print(f"Analyzing {repo.name}...")
            analysis = await analyzer.analyze_repository(repo, deep_analysis=True)
            analyses.append(analysis)

            print(f"  Viability: {analysis.viability.rating.value}")
            print(f"  Cost: ${analysis.monthly_cost}/month")

        # Sync to Notion
        notion = NotionClient(settings, creds)
        for analysis in analyses:
            await notion.sync_build_entry(analysis)

        print("Analysis complete!")

asyncio.run(full_analysis())
```

### Custom Viability Scoring

```python
from src.analyzers.repo_analyzer import RepositoryAnalyzer
from src.models import Repository, CommitStats

# Create analyzer
analyzer = RepositoryAnalyzer(github_client)

# Custom scoring
score = analyzer.calculate_viability_score(
    repo=my_repo,
    has_tests=True,
    test_coverage=75.0,
    has_documentation=True,
    dependencies_count=15,
    commit_stats=CommitStats(
        total_commits=250,
        commits_last_30_days=12,
        commits_last_90_days=45,
        unique_contributors=4,
        average_commits_per_week=3.2
    )
)

print(f"Total Score: {score.total_score}")
print(f"Rating: {score.rating.value}")
print(f"Breakdown: {score.breakdown}")
```

---

**Brookside BI Repository Analyzer API** - Comprehensive interface designed to establish seamless integration with automated repository intelligence workflows.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
