"""
Test Fixtures and Configuration for Brookside BI Repository Analyzer

Establishes reusable test fixtures, mocks, and utilities to streamline test development
and ensure consistent test data across all test suites.

Best for: Organizations requiring comprehensive test coverage with minimal duplication
through centralized fixture management.
"""

import json
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any
from unittest.mock import AsyncMock, Mock

import pytest
from pydantic import HttpUrl

from src.config import Settings
from src.models import (
    ClaudeConfig,
    CommitStats,
    Dependency,
    Pattern,
    PatternType,
    RepoAnalysis,
    Repository,
    ReusabilityRating,
    ViabilityRating,
    ViabilityScore,
)


@pytest.fixture
def mock_settings() -> Settings:
    """
    Create mock Settings object for testing

    Returns:
        Settings with test configuration
    """
    return Settings(
        azure=Mock(
            keyvault_name="kv-brookside-test",
            tenant_id="test-tenant-id",
            subscription_id="test-subscription-id",
        ),
        github=Mock(
            organization="test-org",
            exclude_repos=["test-excluded-repo"],
        ),
        notion=Mock(
            workspace_id="test-workspace-id",
            database_id_ideas="test-ideas-db",
            database_id_research="test-research-db",
            database_id_builds="test-builds-db",
            database_id_software="test-software-db",
        ),
        analysis=Mock(
            cache_ttl_hours=168,
            max_concurrent_analyses=10,
            deep_analysis_enabled=True,
            detect_claude_configs=True,
            calculate_costs=True,
        ),
    )


@pytest.fixture
def mock_credentials():
    """
    Create mock CredentialManager for testing

    Returns:
        Mock with github_token and notion_api_key
    """
    mock = Mock()
    mock.github_token = "ghp_test_token_12345"
    mock.notion_api_key = "ntn_test_key_67890"
    mock.validate_credentials.return_value = {
        "github": True,
        "notion": True,
        "azure_keyvault": True,
    }
    return mock


@pytest.fixture
def sample_repository() -> Repository:
    """
    Create sample Repository object for testing

    Returns:
        Repository with realistic test data
    """
    return Repository(
        name="sample-repo",
        full_name="test-org/sample-repo",
        url=HttpUrl("https://github.com/test-org/sample-repo"),
        description="Sample repository for testing",
        primary_language="Python",
        is_private=False,
        is_fork=False,
        is_archived=False,
        default_branch="main",
        created_at=datetime.now() - timedelta(days=365),
        updated_at=datetime.now() - timedelta(days=7),
        pushed_at=datetime.now() - timedelta(days=2),
        size_kb=5000,
        stars_count=42,
        forks_count=8,
        open_issues_count=3,
        topics=["python", "automation", "testing"],
    )


@pytest.fixture
def sample_repository_inactive() -> Repository:
    """
    Create inactive/abandoned Repository for testing edge cases

    Returns:
        Repository with no recent activity
    """
    return Repository(
        name="abandoned-repo",
        full_name="test-org/abandoned-repo",
        url=HttpUrl("https://github.com/test-org/abandoned-repo"),
        description="Abandoned repository",
        primary_language="JavaScript",
        is_private=False,
        is_fork=False,
        is_archived=True,
        default_branch="master",
        created_at=datetime.now() - timedelta(days=730),
        updated_at=datetime.now() - timedelta(days=365),
        pushed_at=datetime.now() - timedelta(days=400),
        size_kb=1200,
        stars_count=5,
        forks_count=1,
        open_issues_count=12,
        topics=[],
    )


@pytest.fixture
def sample_dependencies() -> list[Dependency]:
    """
    Create sample dependency list for testing

    Returns:
        List of dependencies with varied characteristics
    """
    return [
        Dependency(
            name="azure-functions",
            version="1.18.0",
            package_manager="pip",
            is_dev_dependency=False,
            estimated_monthly_cost=5.0,
        ),
        Dependency(
            name="httpx",
            version="0.25.2",
            package_manager="pip",
            is_dev_dependency=False,
            estimated_monthly_cost=0.0,
        ),
        Dependency(
            name="pytest",
            version="7.4.3",
            package_manager="pip",
            is_dev_dependency=True,
            estimated_monthly_cost=0.0,
        ),
        Dependency(
            name="@azure/openai",
            version="1.0.0",
            package_manager="npm",
            is_dev_dependency=False,
            estimated_monthly_cost=50.0,
        ),
    ]


@pytest.fixture
def sample_claude_config() -> ClaudeConfig:
    """
    Create sample Claude configuration for testing

    Returns:
        ClaudeConfig with agents and commands
    """
    return ClaudeConfig(
        has_claude_dir=True,
        agents_count=3,
        agents=["@ideas-capture", "@cost-analyst", "@build-architect"],
        commands_count=5,
        commands=[
            "/innovation:new-idea",
            "/cost:analyze",
            "/team:assign",
            "/knowledge:archive",
            "/innovation:start-research",
        ],
        mcp_servers=["notion", "github", "azure"],
        has_claude_md=True,
    )


@pytest.fixture
def sample_commit_stats() -> CommitStats:
    """
    Create sample commit statistics for testing

    Returns:
        CommitStats with realistic activity data
    """
    return CommitStats(
        total_commits=234,
        commits_last_30_days=12,
        commits_last_90_days=45,
        unique_contributors=4,
        average_commits_per_week=3.5,
    )


@pytest.fixture
def sample_viability_score() -> ViabilityScore:
    """
    Create sample viability score for testing

    Returns:
        ViabilityScore with high rating
    """
    return ViabilityScore(
        total_score=85,
        test_coverage_score=25,
        activity_score=18,
        documentation_score=22,
        dependency_health_score=20,
        rating=ViabilityRating.HIGH,
    )


@pytest.fixture
def sample_repo_analysis(
    sample_repository: Repository,
    sample_dependencies: list[Dependency],
    sample_claude_config: ClaudeConfig,
    sample_commit_stats: CommitStats,
    sample_viability_score: ViabilityScore,
) -> RepoAnalysis:
    """
    Create complete RepoAnalysis object for testing

    Returns:
        RepoAnalysis with all fields populated
    """
    return RepoAnalysis(
        repository=sample_repository,
        languages={"Python": 125000, "Markdown": 5000, "YAML": 2000},
        dependencies=sample_dependencies,
        viability=sample_viability_score,
        claude_config=sample_claude_config,
        commit_stats=sample_commit_stats,
        monthly_cost=55.0,
        reusability_rating=ReusabilityRating.HIGHLY_REUSABLE,
        microsoft_services=["Azure Functions", "Azure OpenAI"],
        has_tests=True,
        test_coverage_percentage=85.0,
        has_ci_cd=True,
        has_documentation=True,
    )


@pytest.fixture
def sample_pattern() -> Pattern:
    """
    Create sample Pattern object for testing

    Returns:
        Pattern with architectural classification
    """
    return Pattern(
        name="Serverless Function Pattern",
        pattern_type=PatternType.ARCHITECTURAL,
        description="Azure Functions with HTTP triggers for serverless APIs",
        repos_using=["api-gateway", "webhook-processor", "data-transformer"],
        reusability_score=90,
        microsoft_technology="Azure Functions",
        code_example="def main(req: func.HttpRequest) -> func.HttpResponse:\n    return func.HttpResponse('OK')",
        benefits=[
            "Automatic scaling",
            "Pay-per-execution pricing",
            "Integrated monitoring",
        ],
        considerations=[
            "Cold start latency",
            "Stateless execution model",
            "Timeout limits",
        ],
    )


@pytest.fixture
def mock_github_api_response() -> dict[str, Any]:
    """
    Create mock GitHub API response for repository listing

    Returns:
        Dictionary matching GitHub API structure
    """
    return {
        "name": "test-repo",
        "full_name": "test-org/test-repo",
        "html_url": "https://github.com/test-org/test-repo",
        "description": "Test repository",
        "language": "Python",
        "private": False,
        "fork": False,
        "archived": False,
        "default_branch": "main",
        "created_at": "2023-01-01T00:00:00Z",
        "updated_at": "2024-10-01T00:00:00Z",
        "pushed_at": "2024-10-15T00:00:00Z",
        "size": 5000,
        "stargazers_count": 42,
        "forks_count": 8,
        "open_issues_count": 3,
        "topics": ["python", "automation"],
    }


@pytest.fixture
def mock_github_languages_response() -> dict[str, int]:
    """
    Create mock GitHub languages API response

    Returns:
        Dictionary of language to bytes
    """
    return {
        "Python": 125000,
        "TypeScript": 45000,
        "Markdown": 5000,
        "YAML": 2000,
    }


@pytest.fixture
def mock_github_commit_response() -> list[dict[str, Any]]:
    """
    Create mock GitHub commits API response

    Returns:
        List of commit objects
    """
    base_date = datetime.now()
    return [
        {
            "sha": f"commit{i}",
            "commit": {
                "author": {
                    "name": "Developer",
                    "email": "dev@example.com",
                    "date": (base_date - timedelta(days=i)).isoformat(),
                },
                "message": f"Commit message {i}",
            },
        }
        for i in range(50)
    ]


@pytest.fixture
async def mock_httpx_client():
    """
    Create mock async httpx client for testing

    Returns:
        AsyncMock with request method
    """
    mock = AsyncMock()
    mock.request = AsyncMock()
    return mock


@pytest.fixture
def temp_test_dir(tmp_path: Path) -> Path:
    """
    Create temporary directory for file-based tests

    Args:
        tmp_path: Pytest temporary path fixture

    Returns:
        Path to temporary test directory
    """
    test_dir = tmp_path / "test_repo"
    test_dir.mkdir()

    # Create sample .claude/ directory structure
    claude_dir = test_dir / ".claude"
    claude_dir.mkdir()

    agents_dir = claude_dir / "agents"
    agents_dir.mkdir()
    (agents_dir / "ideas-capture.md").write_text("# Ideas Capture Agent")

    commands_dir = claude_dir / "commands"
    commands_dir.mkdir()
    (commands_dir / "new-idea.md").write_text("# New Idea Command")

    (claude_dir / ".claude.json").write_text(
        json.dumps({"mcpServers": {"notion": {}, "github": {}}})
    )

    (test_dir / "CLAUDE.md").write_text("# Project Memory")
    (test_dir / "README.md").write_text("# Test Repository")

    return test_dir


@pytest.fixture
def mock_azure_keyvault_secret():
    """
    Create mock Azure Key Vault secret response

    Returns:
        Mock with value attribute
    """
    mock = Mock()
    mock.value = "secret_value_12345"
    return mock


# Async test utilities


@pytest.fixture
def event_loop_policy():
    """Set event loop policy for async tests"""
    import asyncio

    return asyncio.get_event_loop_policy()


# Assertion helpers


def assert_repository_valid(repo: Repository) -> None:
    """
    Validate Repository object has required fields

    Args:
        repo: Repository to validate
    """
    assert repo.name
    assert repo.full_name
    assert repo.url
    assert isinstance(repo.is_private, bool)
    assert isinstance(repo.is_fork, bool)
    assert isinstance(repo.is_archived, bool)
    assert repo.created_at
    assert repo.updated_at


def assert_analysis_complete(analysis: RepoAnalysis) -> None:
    """
    Validate RepoAnalysis has all required components

    Args:
        analysis: RepoAnalysis to validate
    """
    assert analysis.repository
    assert analysis.viability
    assert analysis.commit_stats
    assert isinstance(analysis.monthly_cost, float)
    assert analysis.reusability_rating in ReusabilityRating
    assert isinstance(analysis.has_tests, bool)
    assert isinstance(analysis.has_ci_cd, bool)
    assert isinstance(analysis.has_documentation, bool)
