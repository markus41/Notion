"""
Repository Analyzer Engine for Brookside BI

Orchestrates multi-dimensional repository analysis including viability scoring,
quality metrics, and reusability assessment to establish comprehensive understanding.

Best for: Organizations requiring systematic repository evaluation to drive
informed decisions about maintenance, investment, and knowledge extraction.
"""

import logging
from pathlib import Path
from typing import Any

from src.github_mcp_client import GitHubMCPClient
from src.models import (
    RepoAnalysis,
    Repository,
    ReusabilityRating,
    ViabilityRating,
    ViabilityScore,
)

logger = logging.getLogger(__name__)


class RepositoryAnalyzer:
    """
    Multi-dimensional repository analysis engine

    Coordinates analysis across multiple domains:
    - Viability assessment (test coverage, activity, documentation, dependencies)
    - Quality metrics (CI/CD, testing, documentation)
    - Reusability evaluation
    - Microsoft ecosystem detection
    """

    def __init__(self, github_client: GitHubMCPClient):
        """
        Initialize repository analyzer

        Args:
            github_client: GitHub MCP client for data retrieval

        Example:
            >>> async with GitHubMCPClient(settings, creds) as client:
            ...     analyzer = RepositoryAnalyzer(client)
            ...     analysis = await analyzer.analyze_repository(repo)
        """
        self.github_client = github_client

    async def analyze_repository(
        self, repo: Repository, deep_analysis: bool = True
    ) -> RepoAnalysis:
        """
        Perform comprehensive repository analysis

        Args:
            repo: Repository to analyze
            deep_analysis: Enable deep code analysis (slower but more thorough)

        Returns:
            Complete RepoAnalysis object

        Example:
            >>> analysis = await analyzer.analyze_repository(repo, deep_analysis=True)
            >>> print(f"Viability: {analysis.viability.rating.value}")
            >>> print(f"Monthly Cost: ${analysis.monthly_cost}")
        """
        logger.info(f"Analyzing repository: {repo.name}")

        # Gather repository data
        languages = await self.github_client.get_repository_languages(repo)
        dependencies = await self.github_client.get_repository_dependencies(repo)
        commit_stats = await self.github_client.get_commit_activity(repo, days=90)

        # Quality metrics
        has_tests = await self._check_has_tests(repo)
        has_ci_cd = await self._check_has_ci_cd(repo)
        has_documentation = await self._check_has_documentation(repo)

        # Calculate test coverage (approximation based on file structure)
        test_coverage = await self._estimate_test_coverage(repo) if has_tests else None

        # Calculate viability score
        viability = self.calculate_viability_score(
            repo=repo,
            has_tests=has_tests,
            test_coverage=test_coverage,
            has_documentation=has_documentation,
            dependencies_count=len(dependencies),
            commit_stats=commit_stats,
        )

        # Determine reusability rating
        reusability = self._calculate_reusability_rating(
            repo=repo,
            viability_score=viability.total_score,
            has_tests=has_tests,
            has_documentation=has_documentation,
        )

        # Detect Microsoft services
        microsoft_services = self._detect_microsoft_services(
            dependencies=dependencies,
            languages=languages,
        )

        # Calculate monthly cost (will be enhanced by cost_calculator module)
        monthly_cost = sum(dep.estimated_monthly_cost for dep in dependencies)

        # Build analysis result
        analysis = RepoAnalysis(
            repository=repo,
            languages=languages,
            dependencies=dependencies,
            viability=viability,
            claude_config=None,  # Will be populated by claude_detector if .claude/ exists
            commit_stats=commit_stats,
            monthly_cost=monthly_cost,
            reusability_rating=reusability,
            microsoft_services=microsoft_services,
            has_tests=has_tests,
            test_coverage_percentage=test_coverage,
            has_ci_cd=has_ci_cd,
            has_documentation=has_documentation,
        )

        logger.info(
            f"Analysis complete for {repo.name}: "
            f"Viability={viability.rating.value}, "
            f"Reusability={reusability.value}"
        )

        return analysis

    def calculate_viability_score(
        self,
        repo: Repository,
        has_tests: bool,
        test_coverage: float | None,
        has_documentation: bool,
        dependencies_count: int,
        commit_stats: Any,
    ) -> ViabilityScore:
        """
        Calculate repository viability score (0-100)

        Scoring breakdown:
        - Test Coverage: 30 points max
          - No tests: 0 points
          - Tests exist: 10 points base
          - 70%+ coverage: 30 points
          - Scaled between 10-30 for coverage 0-70%

        - Recent Activity: 20 points max
          - Commits in last 30 days: 20 points
          - Commits in last 90 days: 10 points
          - No recent commits: 0 points

        - Documentation: 25 points max
          - README.md: 15 points
          - Additional docs: 10 points

        - Dependency Health: 25 points max
          - 0-10 dependencies: 25 points
          - 11-30 dependencies: 15 points
          - 31+ dependencies: 5 points

        Args:
            repo: Repository object
            has_tests: Whether repository has tests
            test_coverage: Test coverage percentage (0-100)
            has_documentation: Whether documentation exists
            dependencies_count: Number of dependencies
            commit_stats: Commit statistics

        Returns:
            ViabilityScore object with detailed breakdown

        Example:
            >>> score = analyzer.calculate_viability_score(
            ...     repo=repo,
            ...     has_tests=True,
            ...     test_coverage=75.0,
            ...     has_documentation=True,
            ...     dependencies_count=15,
            ...     commit_stats=stats
            ... )
            >>> print(score.total_score)  # 85
        """
        # Test coverage scoring (0-30 points)
        test_score = 0
        if has_tests:
            test_score = 10  # Base score for having tests
            if test_coverage is not None:
                if test_coverage >= 70:
                    test_score = 30
                else:
                    # Scale from 10 to 30 based on coverage
                    test_score = 10 + int((test_coverage / 70) * 20)

        # Activity scoring (0-20 points)
        activity_score = 0
        if commit_stats.commits_last_30_days > 0:
            activity_score = 20
        elif commit_stats.commits_last_90_days > 0:
            activity_score = 10

        # Documentation scoring (0-25 points)
        doc_score = 0
        if has_documentation:
            doc_score = 15  # README exists
            # TODO: Check for additional documentation (docs/, wiki, etc.)
            # For now, add 10 points if repo is active and has README
            if repo.is_active:
                doc_score = 25

        # Dependency health scoring (0-25 points)
        dep_score = 25
        if dependencies_count > 30:
            dep_score = 5
        elif dependencies_count > 10:
            dep_score = 15

        # Calculate total
        total = test_score + activity_score + doc_score + dep_score

        # Determine rating
        if total >= 75:
            rating = ViabilityRating.HIGH
        elif total >= 50:
            rating = ViabilityRating.MEDIUM
        else:
            rating = ViabilityRating.LOW

        return ViabilityScore(
            total_score=total,
            test_coverage_score=test_score,
            activity_score=activity_score,
            documentation_score=doc_score,
            dependency_health_score=dep_score,
            rating=rating,
        )

    def _calculate_reusability_rating(
        self,
        repo: Repository,
        viability_score: int,
        has_tests: bool,
        has_documentation: bool,
    ) -> ReusabilityRating:
        """
        Determine reusability rating based on multiple factors

        Args:
            repo: Repository object
            viability_score: Overall viability score (0-100)
            has_tests: Whether repository has tests
            has_documentation: Whether documentation exists

        Returns:
            ReusabilityRating enum value

        Logic:
        - Highly Reusable: Viability >= 75, has tests, has docs, not a fork
        - Partially Reusable: Viability >= 50, some quality indicators
        - One-Off: Everything else
        """
        if (
            viability_score >= 75
            and has_tests
            and has_documentation
            and not repo.is_fork
            and repo.is_active
        ):
            return ReusabilityRating.HIGHLY_REUSABLE

        if viability_score >= 50 and (has_tests or has_documentation):
            return ReusabilityRating.PARTIALLY_REUSABLE

        return ReusabilityRating.ONE_OFF

    def _detect_microsoft_services(
        self,
        dependencies: list[Any],
        languages: dict[str, int],
    ) -> list[str]:
        """
        Detect Microsoft services and technologies

        Args:
            dependencies: List of dependencies
            languages: Language breakdown

        Returns:
            List of detected Microsoft services

        Example:
            >>> services = analyzer._detect_microsoft_services(deps, langs)
            >>> print(services)  # ['Azure Functions', 'TypeScript']
        """
        services: set[str] = set()

        # Check dependencies for Azure/Microsoft packages
        azure_patterns = [
            ("azure-functions", "Azure Functions"),
            ("azure-storage", "Azure Storage"),
            ("azure-keyvault", "Azure Key Vault"),
            ("@azure/", "Azure SDK"),
            ("msal", "Microsoft Authentication Library"),
            ("microsoft-graph", "Microsoft Graph API"),
        ]

        for dep in dependencies:
            for pattern, service in azure_patterns:
                if pattern in dep.name.lower():
                    services.add(service)

        # Check languages
        if "C#" in languages or "F#" in languages:
            services.add(".NET")
        if "TypeScript" in languages:
            services.add("TypeScript")

        return sorted(list(services))

    async def _check_has_tests(self, repo: Repository) -> bool:
        """Check if repository has test directory or files"""
        test_indicators = ["tests/", "test/", "__tests__/", "spec/"]

        for indicator in test_indicators:
            if await self.github_client.check_file_exists(repo, indicator):
                return True

        return False

    async def _check_has_ci_cd(self, repo: Repository) -> bool:
        """Check if repository has CI/CD configuration"""
        ci_indicators = [
            ".github/workflows/",
            ".gitlab-ci.yml",
            "azure-pipelines.yml",
            ".circleci/config.yml",
        ]

        for indicator in ci_indicators:
            if await self.github_client.check_file_exists(repo, indicator):
                return True

        return False

    async def _check_has_documentation(self, repo: Repository) -> bool:
        """Check if repository has documentation"""
        # README is the primary indicator
        return await self.github_client.check_file_exists(repo, "README.md")

    async def _estimate_test_coverage(self, repo: Repository) -> float | None:
        """
        Estimate test coverage based on available indicators

        This is an approximation. True coverage requires running tests
        or parsing coverage reports.

        Returns:
            Estimated coverage percentage (0-100) or None
        """
        # Simple heuristic: if tests exist and CI/CD is configured, assume decent coverage
        has_ci_cd = await self._check_has_ci_cd(repo)

        if has_ci_cd:
            return 70.0  # Optimistic estimate for CI/CD repos

        return 40.0  # Conservative estimate for repos with tests but no CI/CD
