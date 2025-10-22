"""
Repository scoring models for multi-dimensional health assessment.

Establishes consistent scoring algorithms across viability, Claude maturity,
and reusability dimensions to drive sustainable portfolio intelligence.
"""

from typing import Literal
from pydantic import BaseModel, Field, computed_field


class ViabilityScore(BaseModel):
    """
    Multi-dimensional repository health assessment.

    Scoring Algorithm:
    - Test Coverage (0-30): Based on test presence and coverage percentage
    - Activity (0-20): Based on recency of last push
    - Documentation (0-25): Based on README, docs/, API documentation
    - Dependencies (0-25): Based on dependency count and health

    Best for: Prioritizing maintenance investments and archival decisions
    across large repository portfolios.
    """
    total: int = Field(ge=0, le=100, description="Aggregate viability score")
    test_coverage: int = Field(ge=0, le=30, description="Test coverage component")
    activity: int = Field(ge=0, le=20, description="Activity component")
    documentation: int = Field(ge=0, le=25, description="Documentation component")
    dependencies: int = Field(ge=0, le=25, description="Dependency health component")

    @computed_field
    @property
    def rating(self) -> Literal["HIGH", "MEDIUM", "LOW"]:
        """
        Categorical viability rating.

        - HIGH (75-100): Production-ready, well-maintained
        - MEDIUM (50-74): Functional but needs work
        - LOW (0-49): Reference only or abandoned
        """
        if self.total >= 75:
            return "HIGH"
        elif self.total >= 50:
            return "MEDIUM"
        else:
            return "LOW"

    @computed_field
    @property
    def rating_emoji(self) -> str:
        """Visual rating indicator for Notion display"""
        return {
            "HIGH": "💎",
            "MEDIUM": "⚡",
            "LOW": "🔻"
        }[self.rating]

    @computed_field
    @property
    def rating_description(self) -> str:
        """Human-readable viability assessment"""
        return {
            "HIGH": "Production-ready with strong maintenance indicators",
            "MEDIUM": "Functional repository requiring quality improvements",
            "LOW": "Reference implementation or inactive project"
        }[self.rating]

    @classmethod
    def calculate(
        cls,
        has_tests: bool,
        test_coverage_pct: float | None,
        days_since_push: int,
        has_readme: bool,
        has_docs: bool,
        dependency_count: int,
        outdated_count: int
    ) -> "ViabilityScore":
        """
        Calculate viability score from repository characteristics.

        Best for: Systematic scoring across entire GitHub organization.
        """
        # Test Coverage (0-30 points)
        if not has_tests:
            test_score = 0
        elif test_coverage_pct is None:
            test_score = 10  # Has tests but no coverage data
        elif test_coverage_pct >= 70:
            test_score = 30
        elif test_coverage_pct >= 50:
            test_score = 20
        elif test_coverage_pct >= 30:
            test_score = 10
        else:
            test_score = 5

        # Activity (0-20 points)
        if days_since_push <= 30:
            activity_score = 20
        elif days_since_push <= 90:
            activity_score = 10
        elif days_since_push <= 180:
            activity_score = 5
        else:
            activity_score = 0

        # Documentation (0-25 points)
        doc_score = 0
        if has_readme:
            doc_score += 15
        if has_docs:
            doc_score += 10

        # Dependency Health (0-25 points)
        if dependency_count == 0:
            dep_score = 25
        elif dependency_count <= 10 and outdated_count == 0:
            dep_score = 25
        elif dependency_count <= 30 and outdated_count <= 3:
            dep_score = 15
        else:
            dep_score = 5

        total = test_score + activity_score + doc_score + dep_score

        return cls(
            total=total,
            test_coverage=test_score,
            activity=activity_score,
            documentation=doc_score,
            dependencies=dep_score
        )

    class Config:
        json_schema_extra = {
            "example": {
                "total": 85,
                "test_coverage": 30,
                "activity": 20,
                "documentation": 25,
                "dependencies": 10
            }
        }


class ClaudeMaturity(BaseModel):
    """
    Assesses Claude Code integration sophistication.

    Scoring Algorithm:
    - Agents: 10 points each
    - Commands: 5 points each
    - MCP Servers: 10 points each
    - CLAUDE.md: 15 points
    - Project Memory: 10 points

    Maturity Levels:
    - EXPERT (80-100): Comprehensive integration
    - ADVANCED (60-79): Solid foundation
    - INTERMEDIATE (30-59): Basic integration
    - BASIC (10-29): Minimal presence
    - NONE (0-9): No integration

    Best for: Identifying repositories for Claude Code adoption and
    measuring AI-assisted development maturity across portfolio.
    """
    level: Literal["EXPERT", "ADVANCED", "INTERMEDIATE", "BASIC", "NONE"] = Field(
        ...,
        description="Claude integration maturity level"
    )
    score: int = Field(ge=0, le=100, description="Numeric maturity score")

    agent_count: int = Field(default=0, ge=0, description="Number of Claude agents")
    command_count: int = Field(default=0, ge=0, description="Number of slash commands")
    mcp_server_count: int = Field(default=0, ge=0, description="Number of MCP servers")
    has_claude_md: bool = Field(default=False, description="Has CLAUDE.md instructions")
    has_project_memory: bool = Field(default=False, description="Has .claude/memory/")

    @computed_field
    @property
    def maturity_description(self) -> str:
        """Human-readable maturity assessment"""
        return {
            "EXPERT": "Comprehensive Claude integration with agents, commands, MCP servers",
            "ADVANCED": "Solid Claude foundation with multiple agents/commands",
            "INTERMEDIATE": "Basic Claude integration starting to take shape",
            "BASIC": "Minimal Claude presence, exploration phase",
            "NONE": "No Claude Code integration detected"
        }[self.level]

    @classmethod
    def calculate(
        cls,
        has_claude_dir: bool,
        agent_count: int,
        command_count: int,
        mcp_server_count: int,
        has_claude_md: bool,
        has_project_memory: bool
    ) -> "ClaudeMaturity":
        """
        Calculate Claude maturity from .claude/ directory analysis.

        Best for: Systematic Claude adoption tracking across organization.
        """
        if not has_claude_dir:
            return cls(
                level="NONE",
                score=0,
                agent_count=0,
                command_count=0,
                mcp_server_count=0,
                has_claude_md=False,
                has_project_memory=False
            )

        # Calculate score
        score = 0
        score += agent_count * 10
        score += command_count * 5
        score += mcp_server_count * 10
        if has_claude_md:
            score += 15
        if has_project_memory:
            score += 10

        # Cap at 100
        score = min(score, 100)

        # Determine level
        if score >= 80:
            level = "EXPERT"
        elif score >= 60:
            level = "ADVANCED"
        elif score >= 30:
            level = "INTERMEDIATE"
        elif score >= 10:
            level = "BASIC"
        else:
            level = "NONE"

        return cls(
            level=level,
            score=score,
            agent_count=agent_count,
            command_count=command_count,
            mcp_server_count=mcp_server_count,
            has_claude_md=has_claude_md,
            has_project_memory=has_project_memory
        )

    class Config:
        json_schema_extra = {
            "example": {
                "level": "EXPERT",
                "score": 90,
                "agent_count": 5,
                "command_count": 8,
                "mcp_server_count": 3,
                "has_claude_md": True,
                "has_project_memory": True
            }
        }


class Reusability(BaseModel):
    """
    Assesses repository suitability for reuse across projects.

    Criteria for "Highly Reusable":
    - Viability score >= 75
    - Has tests
    - Has documentation
    - Not a fork
    - Active (pushed within 90 days)

    Best for: Identifying template repositories and reference implementations
    to accelerate development through standardized starting points.
    """
    assessment: Literal["Highly Reusable", "Partially Reusable", "One-Off"] = Field(
        ...,
        description="Categorical reusability assessment"
    )

    has_tests: bool = Field(..., description="Repository includes test suite")
    has_documentation: bool = Field(..., description="Repository has meaningful docs")
    is_active: bool = Field(..., description="Pushed within 90 days")
    is_not_fork: bool = Field(..., description="Original repository, not fork")
    viability_score: int = Field(..., ge=0, le=100, description="Overall viability")

    @computed_field
    @property
    def reusability_emoji(self) -> str:
        """Visual reusability indicator for Notion"""
        return {
            "Highly Reusable": "🌟",
            "Partially Reusable": "⚙️",
            "One-Off": "🔧"
        }[self.assessment]

    @computed_field
    @property
    def reusability_description(self) -> str:
        """Human-readable reusability guidance"""
        return {
            "Highly Reusable": "Excellent template for new projects with comprehensive quality markers",
            "Partially Reusable": "Some reusable components but requires adaptation",
            "One-Off": "Project-specific implementation, reference only"
        }[self.assessment]

    @classmethod
    def calculate(
        cls,
        viability_score: int,
        has_tests: bool,
        has_documentation: bool,
        is_fork: bool,
        is_active: bool
    ) -> "Reusability":
        """
        Calculate reusability from repository characteristics.

        Best for: Systematic identification of template candidates across
        GitHub organization portfolio.
        """
        is_not_fork = not is_fork

        # Highly Reusable criteria
        is_highly_reusable = all([
            viability_score >= 75,
            has_tests,
            has_documentation,
            is_not_fork,
            is_active
        ])

        # Partially Reusable criteria
        is_partially_reusable = (
            viability_score >= 50 and
            (has_tests or has_documentation)
        )

        if is_highly_reusable:
            assessment = "Highly Reusable"
        elif is_partially_reusable:
            assessment = "Partially Reusable"
        else:
            assessment = "One-Off"

        return cls(
            assessment=assessment,
            has_tests=has_tests,
            has_documentation=has_documentation,
            is_active=is_active,
            is_not_fork=is_not_fork,
            viability_score=viability_score
        )

    class Config:
        json_schema_extra = {
            "example": {
                "assessment": "Highly Reusable",
                "has_tests": True,
                "has_documentation": True,
                "is_active": True,
                "is_not_fork": True,
                "viability_score": 85
            }
        }
