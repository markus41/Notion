"""
Unit Tests for Data Models

Validates Pydantic model structure, validation rules, computed properties,
and serialization behavior to ensure data integrity across the analysis pipeline.

Best for: Comprehensive validation of type-safe data contracts with edge case coverage.
"""

import pytest
from datetime import datetime, timedelta
from pydantic import ValidationError, HttpUrl

from src.models import (
    BuildType,
    ClaudeConfig,
    CommitStats,
    Component,
    CostBreakdown,
    CostOptimizationOpportunity,
    Dependency,
    NotionBuildPage,
    NotionPatternPage,
    Pattern,
    PatternType,
    RepoAnalysis,
    Repository,
    ReusabilityRating,
    ViabilityRating,
    ViabilityScore,
)


class TestRepository:
    """Test Repository model validation and properties"""

    def test_repository_creation_valid(self, sample_repository):
        """Test valid repository creation"""
        assert sample_repository.name == "sample-repo"
        assert sample_repository.full_name == "test-org/sample-repo"
        assert sample_repository.primary_language == "Python"
        assert sample_repository.is_private is False

    def test_repository_required_fields(self):
        """Test repository creation fails without required fields"""
        with pytest.raises(ValidationError):
            Repository()

    def test_repository_days_since_last_commit(self):
        """Test days_since_last_commit property calculation"""
        repo = Repository(
            name="test",
            full_name="org/test",
            url=HttpUrl("https://github.com/org/test"),
            created_at=datetime.now(),
            updated_at=datetime.now(),
            pushed_at=datetime.now() - timedelta(days=15),
        )
        assert repo.days_since_last_commit == 15

    def test_repository_days_since_last_commit_no_pushes(self):
        """Test days_since_last_commit when pushed_at is None"""
        repo = Repository(
            name="test",
            full_name="org/test",
            url=HttpUrl("https://github.com/org/test"),
            created_at=datetime.now(),
            updated_at=datetime.now(),
            pushed_at=None,
        )
        assert repo.days_since_last_commit == 9999

    def test_repository_is_active_true(self):
        """Test is_active property for recently updated repo"""
        repo = Repository(
            name="test",
            full_name="org/test",
            url=HttpUrl("https://github.com/org/test"),
            created_at=datetime.now(),
            updated_at=datetime.now(),
            pushed_at=datetime.now() - timedelta(days=30),
        )
        assert repo.is_active is True

    def test_repository_is_active_false(self):
        """Test is_active property for stale repo"""
        repo = Repository(
            name="test",
            full_name="org/test",
            url=HttpUrl("https://github.com/org/test"),
            created_at=datetime.now(),
            updated_at=datetime.now(),
            pushed_at=datetime.now() - timedelta(days=180),
        )
        assert repo.is_active is False


class TestDependency:
    """Test Dependency model"""

    def test_dependency_creation(self):
        """Test valid dependency creation"""
        dep = Dependency(
            name="httpx",
            version="0.25.2",
            package_manager="pip",
            is_dev_dependency=False,
            estimated_monthly_cost=0.0,
        )
        assert dep.name == "httpx"
        assert dep.version == "0.25.2"
        assert dep.package_manager == "pip"

    def test_dependency_defaults(self):
        """Test dependency default values"""
        dep = Dependency(name="test-package", package_manager="npm")
        assert dep.version is None
        assert dep.is_dev_dependency is False
        assert dep.estimated_monthly_cost == 0.0


class TestClaudeConfig:
    """Test ClaudeConfig model"""

    def test_claude_config_defaults(self):
        """Test ClaudeConfig default values"""
        config = ClaudeConfig()
        assert config.has_claude_dir is False
        assert config.agents_count == 0
        assert config.agents == []
        assert config.commands_count == 0
        assert config.commands == []
        assert config.mcp_servers == []
        assert config.has_claude_md is False

    def test_claude_config_with_data(self, sample_claude_config):
        """Test ClaudeConfig with complete data"""
        assert sample_claude_config.has_claude_dir is True
        assert sample_claude_config.agents_count == 3
        assert len(sample_claude_config.agents) == 3
        assert sample_claude_config.commands_count == 5
        assert len(sample_claude_config.mcp_servers) == 3


class TestCommitStats:
    """Test CommitStats model"""

    def test_commit_stats_creation(self):
        """Test commit statistics creation"""
        stats = CommitStats(
            total_commits=500,
            commits_last_30_days=25,
            commits_last_90_days=85,
            unique_contributors=10,
            average_commits_per_week=5.2,
        )
        assert stats.total_commits == 500
        assert stats.commits_last_30_days == 25
        assert stats.unique_contributors == 10

    def test_commit_stats_defaults(self):
        """Test CommitStats default values"""
        stats = CommitStats()
        assert stats.total_commits == 0
        assert stats.commits_last_30_days == 0
        assert stats.commits_last_90_days == 0
        assert stats.unique_contributors == 0
        assert stats.average_commits_per_week == 0.0


class TestViabilityScore:
    """Test ViabilityScore model and validation"""

    def test_viability_score_creation(self):
        """Test valid viability score creation"""
        score = ViabilityScore(
            total_score=85,
            test_coverage_score=25,
            activity_score=18,
            documentation_score=22,
            dependency_health_score=20,
            rating=ViabilityRating.HIGH,
        )
        assert score.total_score == 85
        assert score.rating == ViabilityRating.HIGH

    def test_viability_score_validation_total_exceeds_100(self):
        """Test viability score rejects total > 100"""
        with pytest.raises(ValidationError):
            ViabilityScore(
                total_score=101,
                test_coverage_score=30,
                activity_score=20,
                documentation_score=25,
                dependency_health_score=25,
                rating=ViabilityRating.HIGH,
            )

    def test_viability_score_validation_negative(self):
        """Test viability score rejects negative values"""
        with pytest.raises(ValidationError):
            ViabilityScore(
                total_score=-5,
                test_coverage_score=0,
                activity_score=0,
                documentation_score=0,
                dependency_health_score=0,
                rating=ViabilityRating.LOW,
            )

    def test_viability_score_breakdown_property(self):
        """Test breakdown property returns correct structure"""
        score = ViabilityScore(
            total_score=75,
            test_coverage_score=20,
            activity_score=15,
            documentation_score=20,
            dependency_health_score=20,
            rating=ViabilityRating.MEDIUM,
        )
        breakdown = score.breakdown
        assert breakdown["total"] == 75
        assert breakdown["test_coverage"] == 20
        assert breakdown["activity"] == 15
        assert breakdown["rating"] == "⚡ Medium"


class TestRepoAnalysis:
    """Test complete RepoAnalysis model"""

    def test_repo_analysis_creation(self, sample_repo_analysis):
        """Test complete repository analysis creation"""
        assert sample_repo_analysis.repository.name == "sample-repo"
        assert sample_repo_analysis.viability.total_score == 85
        assert sample_repo_analysis.monthly_cost == 55.0
        assert sample_repo_analysis.reusability_rating == ReusabilityRating.HIGHLY_REUSABLE

    def test_repo_analysis_primary_language_percentage(self):
        """Test primary language percentage calculation"""
        analysis = RepoAnalysis(
            repository=Repository(
                name="test",
                full_name="org/test",
                url=HttpUrl("https://github.com/org/test"),
                primary_language="Python",
                created_at=datetime.now(),
                updated_at=datetime.now(),
            ),
            languages={"Python": 100000, "JavaScript": 25000, "YAML": 5000},
            dependencies=[],
            viability=ViabilityScore(
                total_score=50,
                test_coverage_score=15,
                activity_score=10,
                documentation_score=15,
                dependency_health_score=10,
                rating=ViabilityRating.MEDIUM,
            ),
            commit_stats=CommitStats(),
            reusability_rating=ReusabilityRating.PARTIALLY_REUSABLE,
        )
        # Python is 100,000 out of 130,000 total = 76.92%
        assert abs(analysis.primary_language_percentage - 76.92) < 0.1

    def test_repo_analysis_dependency_count(self, sample_repo_analysis):
        """Test dependency_count property"""
        assert sample_repo_analysis.dependency_count == 4


class TestPattern:
    """Test Pattern model"""

    def test_pattern_creation(self, sample_pattern):
        """Test pattern creation"""
        assert sample_pattern.name == "Serverless Function Pattern"
        assert sample_pattern.pattern_type == PatternType.ARCHITECTURAL
        assert sample_pattern.reusability_score == 90
        assert sample_pattern.microsoft_technology == "Azure Functions"

    def test_pattern_usage_count(self, sample_pattern):
        """Test usage_count property"""
        assert sample_pattern.usage_count == 3


class TestComponent:
    """Test Component model"""

    def test_component_creation(self):
        """Test reusable component creation"""
        component = Component(
            name="AuthMiddleware",
            repository="api-gateway",
            file_path="src/middleware/auth.py",
            description="JWT authentication middleware for Azure AD",
            language="Python",
            reusability_score=85,
            dependencies=["azure-identity", "pyjwt"],
        )
        assert component.name == "AuthMiddleware"
        assert component.reusability_score == 85
        assert len(component.dependencies) == 2


class TestCostBreakdown:
    """Test CostBreakdown model"""

    def test_cost_breakdown_creation(self, sample_dependencies):
        """Test cost breakdown creation"""
        breakdown = CostBreakdown(
            total_monthly_cost=55.0,
            dependencies=sample_dependencies,
            unknown_dependencies=["some-unknown-package"],
            top_5_expensive=sample_dependencies[:2],
        )
        assert breakdown.total_monthly_cost == 55.0
        assert len(breakdown.dependencies) == 4
        assert len(breakdown.unknown_dependencies) == 1

    def test_cost_breakdown_annual_cost(self):
        """Test annual_cost property calculation"""
        breakdown = CostBreakdown(
            total_monthly_cost=100.0,
            dependencies=[],
        )
        assert breakdown.annual_cost == 1200.0


class TestCostOptimizationOpportunity:
    """Test CostOptimizationOpportunity model"""

    def test_optimization_opportunity_creation(self):
        """Test cost optimization recommendation creation"""
        opportunity = CostOptimizationOpportunity(
            current_tool="Slack",
            alternative_tool="Microsoft Teams",
            current_monthly_cost=15.0,
            alternative_monthly_cost=0.0,
            monthly_savings=15.0,
            annual_savings=180.0,
            recommendation="Switch to Microsoft Teams (included in M365 subscription)",
            trade_offs=[
                "Migration effort required",
                "User retraining needed",
            ],
        )
        assert opportunity.monthly_savings == 15.0
        assert opportunity.annual_savings == 180.0
        assert len(opportunity.trade_offs) == 2


class TestNotionBuildPage:
    """Test Notion build page model"""

    def test_notion_build_page_creation(self):
        """Test Notion build page data structure"""
        build_page = NotionBuildPage(
            title="🛠️ Cost Analyzer API",
            build_type=BuildType.PROTOTYPE,
            status="🟢 Active",
            viability=ViabilityRating.HIGH,
            reusability=ReusabilityRating.HIGHLY_REUSABLE,
            monthly_cost=25.0,
            github_url=HttpUrl("https://github.com/test-org/cost-analyzer"),
            description="API for analyzing repository costs",
            technology_stack="Python 3.11, Azure Functions, Azure OpenAI",
            content_markdown="# Cost Analyzer API\n\nThis solution establishes...",
        )
        assert build_page.title == "🛠️ Cost Analyzer API"
        assert build_page.build_type == BuildType.PROTOTYPE
        assert build_page.monthly_cost == 25.0


class TestNotionPatternPage:
    """Test Notion pattern page model"""

    def test_notion_pattern_page_creation(self):
        """Test Notion pattern page data structure"""
        pattern_page = NotionPatternPage(
            title="Serverless API Pattern",
            content_type="Technical Doc",
            pattern_type=PatternType.ARCHITECTURAL,
            description="HTTP-triggered Azure Functions for RESTful APIs",
            repos_using_count=5,
            content_markdown="# Pattern\n\n## Overview\n...",
        )
        assert pattern_page.title == "Serverless API Pattern"
        assert pattern_page.pattern_type == PatternType.ARCHITECTURAL
        assert pattern_page.repos_using_count == 5


class TestEnums:
    """Test enum definitions"""

    def test_viability_rating_enum(self):
        """Test ViabilityRating enum values"""
        assert ViabilityRating.HIGH.value == "💎 High"
        assert ViabilityRating.MEDIUM.value == "⚡ Medium"
        assert ViabilityRating.LOW.value == "🔻 Low"
        assert ViabilityRating.NEEDS_ASSESSMENT.value == "❓ Needs Assessment"

    def test_reusability_rating_enum(self):
        """Test ReusabilityRating enum values"""
        assert ReusabilityRating.HIGHLY_REUSABLE.value == "🔄 Highly Reusable"
        assert ReusabilityRating.PARTIALLY_REUSABLE.value == "↔️ Partially Reusable"
        assert ReusabilityRating.ONE_OFF.value == "🔒 One-Off"

    def test_build_type_enum(self):
        """Test BuildType enum values"""
        assert BuildType.PROTOTYPE == "Prototype"
        assert BuildType.POC == "POC"
        assert BuildType.DEMO == "Demo"
        assert BuildType.MVP == "MVP"
        assert BuildType.REFERENCE_IMPLEMENTATION == "Reference Implementation"

    def test_pattern_type_enum(self):
        """Test PatternType enum values"""
        assert PatternType.ARCHITECTURAL == "Architectural"
        assert PatternType.DESIGN == "Design"
        assert PatternType.INTEGRATION == "Integration"
        assert PatternType.DEPLOYMENT == "Deployment"
