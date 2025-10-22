"""
Data Models for Brookside BI Repository Analyzer

Establishes type-safe data structures for repository analysis, pattern extraction,
and cost calculation. All models use Pydantic for validation and serialization.

Best for: Clear data contracts across analysis pipeline with automatic validation.
"""

from datetime import datetime
from enum import Enum
from typing import Any

from pydantic import BaseModel, Field, HttpUrl, field_validator


class ViabilityRating(str, Enum):
    """Repository viability rating"""

    HIGH = "💎 High"
    MEDIUM = "⚡ Medium"
    LOW = "🔻 Low"
    NEEDS_ASSESSMENT = "❓ Needs Assessment"


class ReusabilityRating(str, Enum):
    """Component reusability assessment"""

    HIGHLY_REUSABLE = "🔄 Highly Reusable"
    PARTIALLY_REUSABLE = "↔️ Partially Reusable"
    ONE_OFF = "🔒 One-Off"


class BuildType(str, Enum):
    """Example Build type classification"""

    PROTOTYPE = "Prototype"
    POC = "POC"
    DEMO = "Demo"
    MVP = "MVP"
    REFERENCE_IMPLEMENTATION = "Reference Implementation"


class PatternType(str, Enum):
    """Pattern classification"""

    ARCHITECTURAL = "Architectural"
    DESIGN = "Design"
    INTEGRATION = "Integration"
    DEPLOYMENT = "Deployment"


# === GitHub Models ===


class Repository(BaseModel):
    """GitHub repository metadata"""

    name: str = Field(..., description="Repository name")
    full_name: str = Field(..., description="Full repository name (org/repo)")
    url: HttpUrl = Field(..., description="Repository URL")
    description: str | None = Field(default=None, description="Repository description")
    primary_language: str | None = Field(default=None, description="Primary programming language")
    is_private: bool = Field(default=False, description="Whether repository is private")
    is_fork: bool = Field(default=False, description="Whether repository is a fork")
    is_archived: bool = Field(default=False, description="Whether repository is archived")
    default_branch: str = Field(default="main", description="Default branch name")
    created_at: datetime = Field(..., description="Repository creation date")
    updated_at: datetime = Field(..., description="Last update date")
    pushed_at: datetime | None = Field(default=None, description="Last push date")
    size_kb: int = Field(default=0, description="Repository size in KB")
    stars_count: int = Field(default=0, description="Number of stars")
    forks_count: int = Field(default=0, description="Number of forks")
    open_issues_count: int = Field(default=0, description="Number of open issues")
    topics: list[str] = Field(default_factory=list, description="Repository topics/tags")

    @property
    def days_since_last_commit(self) -> int:
        """Calculate days since last commit"""
        if not self.pushed_at:
            return 9999  # Very old/no commits

        # Use timezone-aware datetime for comparison
        from datetime import timezone
        now_aware = datetime.now(timezone.utc)

        return (now_aware - self.pushed_at).days

    @property
    def is_active(self) -> bool:
        """Check if repository is actively maintained (commits in last 90 days)"""
        return self.days_since_last_commit <= 90


class Dependency(BaseModel):
    """Software dependency"""

    name: str = Field(..., description="Dependency name")
    version: str | None = Field(default=None, description="Dependency version")
    package_manager: str = Field(..., description="Package manager (npm, pip, etc.)")
    is_dev_dependency: bool = Field(default=False, description="Whether it's a dev dependency")
    estimated_monthly_cost: float = Field(default=0.0, description="Estimated monthly cost (USD)")


class ClaudeConfig(BaseModel):
    """Claude Code configuration (.claude/ directory)"""

    has_claude_dir: bool = Field(default=False, description="Whether .claude/ directory exists")
    agents_count: int = Field(default=0, description="Number of defined agents")
    agents: list[str] = Field(default_factory=list, description="List of agent names")
    commands_count: int = Field(default=0, description="Number of slash commands")
    commands: list[str] = Field(default_factory=list, description="List of command names")
    mcp_servers: list[str] = Field(default_factory=list, description="Configured MCP servers")
    has_claude_md: bool = Field(default=False, description="Whether CLAUDE.md exists")


class CommitStats(BaseModel):
    """Repository commit statistics"""

    total_commits: int = Field(default=0, description="Total number of commits")
    commits_last_30_days: int = Field(default=0, description="Commits in last 30 days")
    commits_last_90_days: int = Field(default=0, description="Commits in last 90 days")
    unique_contributors: int = Field(default=0, description="Number of unique contributors")
    average_commits_per_week: float = Field(default=0.0, description="Average weekly commits")


class ViabilityScore(BaseModel):
    """Repository viability assessment"""

    total_score: int = Field(..., ge=0, le=100, description="Total viability score (0-100)")
    test_coverage_score: int = Field(..., ge=0, le=30, description="Test coverage contribution")
    activity_score: int = Field(..., ge=0, le=20, description="Recent activity contribution")
    documentation_score: int = Field(..., ge=0, le=25, description="Documentation contribution")
    dependency_health_score: int = Field(
        ..., ge=0, le=25, description="Dependency health contribution"
    )
    rating: ViabilityRating = Field(..., description="Overall viability rating")

    @property
    def breakdown(self) -> dict[str, Any]:
        """Get score breakdown"""
        return {
            "total": self.total_score,
            "test_coverage": self.test_coverage_score,
            "activity": self.activity_score,
            "documentation": self.documentation_score,
            "dependency_health": self.dependency_health_score,
            "rating": self.rating.value,
        }


# === Analysis Models ===


class RepoAnalysis(BaseModel):
    """Complete repository analysis result"""

    repository: Repository = Field(..., description="Repository metadata")
    languages: dict[str, int] = Field(
        default_factory=dict, description="Language breakdown (bytes)"
    )
    dependencies: list[Dependency] = Field(
        default_factory=list, description="Dependency list"
    )
    viability: ViabilityScore = Field(..., description="Viability assessment")
    claude_config: ClaudeConfig | None = Field(default=None, description="Claude configuration")
    commit_stats: CommitStats = Field(..., description="Commit statistics")

    # Calculated fields
    monthly_cost: float = Field(default=0.0, description="Total monthly dependency cost")
    reusability_rating: ReusabilityRating = Field(
        ..., description="Reusability assessment"
    )
    microsoft_services: list[str] = Field(
        default_factory=list, description="Microsoft services used"
    )

    # Quality metrics
    has_tests: bool = Field(default=False, description="Whether tests exist")
    test_coverage_percentage: float | None = Field(
        default=None, ge=0, le=100, description="Test coverage %"
    )
    has_ci_cd: bool = Field(default=False, description="Whether CI/CD is configured")
    has_documentation: bool = Field(default=False, description="Whether docs exist")

    @property
    def primary_language_percentage(self) -> float:
        """Calculate primary language percentage"""
        if not self.languages:
            return 0.0
        total_bytes = sum(self.languages.values())
        if total_bytes == 0:
            return 0.0
        primary_bytes = self.languages.get(self.repository.primary_language or "", 0)
        return (primary_bytes / total_bytes) * 100

    @property
    def dependency_count(self) -> int:
        """Get total dependency count"""
        return len(self.dependencies)


# === Pattern Models ===


class Pattern(BaseModel):
    """Reusable pattern extracted from repositories"""

    name: str = Field(..., description="Pattern name")
    pattern_type: PatternType = Field(..., description="Pattern classification")
    description: str = Field(..., description="Pattern description")
    repos_using: list[str] = Field(..., description="Repositories using this pattern")
    reusability_score: int = Field(..., ge=0, le=100, description="Reusability score")
    microsoft_technology: str | None = Field(
        default=None, description="Related Microsoft technology"
    )
    code_example: str | None = Field(default=None, description="Code example")
    benefits: list[str] = Field(default_factory=list, description="Pattern benefits")
    considerations: list[str] = Field(default_factory=list, description="Considerations")

    @property
    def usage_count(self) -> int:
        """Number of repositories using this pattern"""
        return len(self.repos_using)


class Component(BaseModel):
    """Reusable component identified in repository"""

    name: str = Field(..., description="Component name")
    repository: str = Field(..., description="Source repository")
    file_path: str = Field(..., description="File path in repository")
    description: str = Field(..., description="Component description")
    language: str = Field(..., description="Programming language")
    reusability_score: int = Field(..., ge=0, le=100, description="Reusability assessment")
    dependencies: list[str] = Field(default_factory=list, description="Component dependencies")


# === Cost Models ===


class CostBreakdown(BaseModel):
    """Detailed cost analysis"""

    total_monthly_cost: float = Field(..., description="Total monthly cost (USD)")
    dependencies: list[Dependency] = Field(..., description="Costed dependencies")
    unknown_dependencies: list[str] = Field(
        default_factory=list, description="Dependencies without cost data"
    )
    top_5_expensive: list[Dependency] = Field(
        default_factory=list, description="Top 5 most expensive dependencies"
    )

    @property
    def annual_cost(self) -> float:
        """Calculate annual cost"""
        return self.total_monthly_cost * 12


class CostOptimizationOpportunity(BaseModel):
    """Cost optimization recommendation"""

    current_tool: str = Field(..., description="Current tool/dependency")
    alternative_tool: str | None = Field(default=None, description="Suggested alternative")
    current_monthly_cost: float = Field(..., description="Current monthly cost")
    alternative_monthly_cost: float = Field(..., description="Alternative monthly cost")
    monthly_savings: float = Field(..., description="Potential monthly savings")
    annual_savings: float = Field(..., description="Potential annual savings")
    recommendation: str = Field(..., description="Recommendation description")
    trade_offs: list[str] = Field(default_factory=list, description="Trade-off considerations")


# === Notion Models ===


class NotionBuildPage(BaseModel):
    """Data for Notion Example Build page creation"""

    title: str = Field(..., description="Build title")
    build_type: BuildType = Field(..., description="Build type")
    status: str = Field(default="🟢 Active", description="Build status")
    viability: ViabilityRating = Field(..., description="Viability rating")
    reusability: ReusabilityRating = Field(..., description="Reusability rating")
    monthly_cost: float = Field(..., description="Monthly cost")
    github_url: HttpUrl = Field(..., description="GitHub repository URL")
    description: str = Field(..., description="Build description")
    technology_stack: str = Field(..., description="Technology stack summary")
    content_markdown: str = Field(..., description="Full page content in Notion markdown")


class NotionPatternPage(BaseModel):
    """Data for Notion Knowledge Vault pattern page"""

    title: str = Field(..., description="Pattern title")
    content_type: str = Field(default="Technical Doc", description="Knowledge Vault content type")
    pattern_type: PatternType = Field(..., description="Pattern type")
    description: str = Field(..., description="Pattern description")
    repos_using_count: int = Field(..., description="Number of repos using pattern")
    content_markdown: str = Field(..., description="Full page content")
