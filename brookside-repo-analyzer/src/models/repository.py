"""
Repository data models for GitHub portfolio analysis.

Establishes comprehensive schema for repository metadata, analysis results,
and multi-dimensional health scoring to drive sustainable portfolio intelligence.
"""

from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, HttpUrl, Field, computed_field

from .scoring import ViabilityScore, ClaudeMaturity, Reusability
from .financial import CostBreakdown
from .patterns import Pattern


class RepositoryMetadata(BaseModel):
    """
    Establishes base repository information extracted from GitHub API.

    Best for: Initial repository discovery and filtering operations across
    large GitHub organizations requiring systematic portfolio visibility.
    """
    name: str = Field(..., description="Repository name (without org prefix)")
    full_name: str = Field(..., description="Full repository name (org/repo)")
    url: HttpUrl = Field(..., description="GitHub repository URL")
    description: Optional[str] = Field(None, description="Repository description")

    # GitHub statistics
    stars: int = Field(default=0, ge=0, description="GitHub star count")
    forks: int = Field(default=0, ge=0, description="Fork count")
    open_issues: int = Field(default=0, ge=0, description="Open issue count")
    watchers: int = Field(default=0, ge=0, description="Watcher count")

    # Repository characteristics
    is_fork: bool = Field(default=False, description="Is this a forked repository")
    is_archived: bool = Field(default=False, description="Is repository archived")
    is_private: bool = Field(default=False, description="Is repository private")
    language: Optional[str] = Field(None, description="Primary programming language")

    # Temporal metadata
    last_pushed: datetime = Field(..., description="Last git push timestamp")
    created_at: datetime = Field(..., description="Repository creation timestamp")
    updated_at: datetime = Field(..., description="Last metadata update timestamp")

    @computed_field
    @property
    def is_active(self) -> bool:
        """
        Repository is active if pushed within 90 days.

        Best for: Filtering maintenance candidates and archival decisions.
        """
        days_since_push = (datetime.now() - self.last_pushed).days
        return days_since_push <= 90

    @computed_field
    @property
    def age_days(self) -> int:
        """Calculate repository age in days"""
        return (datetime.now() - self.created_at).days

    class Config:
        json_schema_extra = {
            "example": {
                "name": "repo-analyzer",
                "full_name": "brookside-bi/repo-analyzer",
                "url": "https://github.com/brookside-bi/repo-analyzer",
                "description": "Automated GitHub repository intelligence",
                "stars": 15,
                "forks": 3,
                "language": "Python",
                "last_pushed": "2025-10-20T10:30:00Z",
                "created_at": "2025-01-15T09:00:00Z"
            }
        }


class RepositoryDetails(RepositoryMetadata):
    """
    Extends base metadata with detailed code structure analysis.

    Best for: Deep repository intelligence requiring dependency analysis,
    test coverage assessment, and .claude/ integration detection.
    """
    # Code structure
    primary_language_percentage: Optional[float] = Field(
        None,
        ge=0,
        le=100,
        description="Percentage of codebase in primary language"
    )
    total_lines_of_code: Optional[int] = Field(None, ge=0)
    file_count: Optional[int] = Field(None, ge=0)

    # Testing infrastructure
    has_tests: bool = Field(default=False, description="Repository includes test suite")
    test_coverage_percentage: Optional[float] = Field(
        None,
        ge=0,
        le=100,
        description="Code coverage percentage if available"
    )
    test_framework: Optional[str] = Field(None, description="Test framework (pytest, jest, etc.)")

    # Documentation
    has_readme: bool = Field(default=False, description="Has README.md file")
    has_docs_directory: bool = Field(default=False, description="Has docs/ directory")
    has_contributing_guide: bool = Field(default=False, description="Has CONTRIBUTING.md")
    has_license: bool = Field(default=False, description="Has LICENSE file")
    license_type: Optional[str] = Field(None, description="License type (MIT, Apache, etc.)")

    # Dependency management
    package_manager: Optional[str] = Field(
        None,
        description="Package manager (npm, poetry, maven, etc.)"
    )
    dependency_count: int = Field(default=0, ge=0, description="Total dependency count")
    outdated_dependency_count: int = Field(
        default=0,
        ge=0,
        description="Outdated dependency count"
    )

    # Claude Code integration
    has_claude_directory: bool = Field(
        default=False,
        description="Has .claude/ directory"
    )
    claude_agent_count: int = Field(default=0, ge=0, description="Number of Claude agents")
    claude_command_count: int = Field(default=0, ge=0, description="Number of slash commands")
    claude_mcp_server_count: int = Field(default=0, ge=0, description="Number of MCP servers")
    has_claude_md: bool = Field(default=False, description="Has CLAUDE.md project instructions")

    # GitHub Actions / CI/CD
    has_github_actions: bool = Field(default=False, description="Has .github/workflows/")
    workflow_count: int = Field(default=0, ge=0, description="Number of GitHub Actions workflows")

    @computed_field
    @property
    def has_documentation(self) -> bool:
        """Repository has meaningful documentation"""
        return self.has_readme or self.has_docs_directory

    @computed_field
    @property
    def dependency_health_score(self) -> int:
        """
        Calculate dependency health (0-100).

        Algorithm:
        - 0-10 deps with no outdated: 100
        - 11-30 deps with <10% outdated: 80
        - 31-50 deps with <20% outdated: 60
        - >50 deps or >20% outdated: 40
        """
        if self.dependency_count == 0:
            return 100

        outdated_percentage = (self.outdated_dependency_count / self.dependency_count) * 100

        if self.dependency_count <= 10 and outdated_percentage == 0:
            return 100
        elif self.dependency_count <= 30 and outdated_percentage < 10:
            return 80
        elif self.dependency_count <= 50 and outdated_percentage < 20:
            return 60
        else:
            return 40


class RepositoryAnalysis(BaseModel):
    """
    Comprehensive repository analysis aggregating all intelligence dimensions.

    Best for: Complete portfolio intelligence reports driving maintenance
    prioritization, reuse decisions, and cost optimization strategies.
    """
    # Core metadata and details
    metadata: RepositoryMetadata = Field(..., description="Base repository metadata")
    details: RepositoryDetails = Field(..., description="Detailed code analysis")

    # Multi-dimensional scoring
    viability: ViabilityScore = Field(..., description="Repository health score")
    claude_maturity: ClaudeMaturity = Field(..., description="Claude Code integration maturity")
    reusability: Reusability = Field(..., description="Reusability assessment")

    # Financial analysis
    costs: CostBreakdown = Field(..., description="Dependency cost breakdown")

    # Pattern extraction
    patterns: List[Pattern] = Field(
        default_factory=list,
        description="Architectural patterns detected"
    )

    # Analysis metadata
    analyzed_at: datetime = Field(
        default_factory=datetime.now,
        description="Analysis execution timestamp"
    )
    analysis_version: str = Field(
        default="1.0.0",
        description="Analyzer version for traceability"
    )

    @computed_field
    @property
    def is_production_ready(self) -> bool:
        """
        Repository is production-ready if:
        - Viability score >= 75
        - Has tests with coverage >= 70%
        - Has documentation
        - Active (pushed within 90 days)
        """
        return all([
            self.viability.total >= 75,
            self.details.has_tests,
            self.details.test_coverage_percentage and self.details.test_coverage_percentage >= 70,
            self.details.has_documentation,
            self.metadata.is_active
        ])

    @computed_field
    @property
    def is_template_candidate(self) -> bool:
        """
        Repository is template candidate if:
        - Highly reusable
        - Not a fork
        - Has documentation and tests
        - Claude maturity >= INTERMEDIATE
        """
        return all([
            self.reusability.assessment == "Highly Reusable",
            not self.metadata.is_fork,
            self.details.has_documentation,
            self.details.has_tests,
            self.claude_maturity.level in ["EXPERT", "ADVANCED", "INTERMEDIATE"]
        ])

    @computed_field
    @property
    def needs_attention(self) -> bool:
        """
        Repository needs attention if:
        - Active but low viability (<50)
        - OR active with >20% outdated dependencies
        - OR active with no tests
        """
        if not self.metadata.is_active:
            return False  # Archived repos don't need attention

        return any([
            self.viability.total < 50,
            self.details.outdated_dependency_count > 0 and
            (self.details.outdated_dependency_count / max(self.details.dependency_count, 1)) > 0.2,
            not self.details.has_tests
        ])

    class Config:
        json_schema_extra = {
            "example": {
                "metadata": {
                    "name": "repo-analyzer",
                    "full_name": "brookside-bi/repo-analyzer",
                    "url": "https://github.com/brookside-bi/repo-analyzer",
                    "stars": 15,
                    "language": "Python",
                    "last_pushed": "2025-10-20T10:30:00Z"
                },
                "viability": {
                    "total": 85,
                    "rating": "HIGH"
                },
                "claude_maturity": {
                    "level": "EXPERT",
                    "score": 90
                },
                "costs": {
                    "total_monthly": 7.0
                },
                "reusability": {
                    "assessment": "Highly Reusable"
                }
            }
        }
