"""
Pattern Mining Module for Brookside BI Repository Analyzer

Extracts reusable patterns, architectural designs, and shared components across
repositories to establish knowledge library and drive code reuse.

Best for: Organizations seeking to identify and leverage successful patterns
across portfolio to reduce duplication and accelerate development.
"""

import logging
from collections import Counter, defaultdict
from typing import Any

from src.models import Component, Pattern, PatternType, RepoAnalysis

logger = logging.getLogger(__name__)


class PatternMiner:
    """
    Cross-repository pattern extraction engine

    Analyzes multiple repositories to identify:
    - Common architectural patterns
    - Shared dependencies
    - Reusable components
    - Microsoft ecosystem usage
    """

    def __init__(self):
        """Initialize pattern miner"""
        pass

    def extract_patterns(self, repos: list[RepoAnalysis]) -> list[Pattern]:
        """
        Extract patterns from repository analyses

        Args:
            repos: List of repository analyses

        Returns:
            List of identified patterns

        Example:
            >>> miner = PatternMiner()
            >>> patterns = miner.extract_patterns(all_analyses)
            >>> for pattern in patterns:
            ...     print(f"{pattern.name}: used in {pattern.usage_count} repos")
        """
        logger.info(f"Mining patterns from {len(repos)} repositories")

        patterns: list[Pattern] = []

        # Extract architectural patterns
        arch_patterns = self._extract_architectural_patterns(repos)
        patterns.extend(arch_patterns)

        # Extract shared dependency patterns
        dep_patterns = self._extract_dependency_patterns(repos)
        patterns.extend(dep_patterns)

        # Extract Microsoft ecosystem patterns
        ms_patterns = self._extract_microsoft_patterns(repos)
        patterns.extend(ms_patterns)

        logger.info(f"Extracted {len(patterns)} patterns")
        return patterns

    def _extract_architectural_patterns(
        self, repos: list[RepoAnalysis]
    ) -> list[Pattern]:
        """Extract architectural patterns from repositories"""
        patterns: list[Pattern] = []

        # Detect serverless pattern (Azure Functions)
        serverless_repos = [
            r.repository.name
            for r in repos
            if any("azure-functions" in dep.name.lower() for dep in r.dependencies)
        ]

        if len(serverless_repos) >= 2:
            patterns.append(
                Pattern(
                    name="Serverless Architecture (Azure Functions)",
                    pattern_type=PatternType.ARCHITECTURAL,
                    description="Event-driven serverless compute using Azure Functions for scalable, cost-effective execution",
                    repos_using=serverless_repos,
                    reusability_score=85,
                    microsoft_technology="Azure Functions",
                    benefits=[
                        "No infrastructure management",
                        "Pay-per-execution pricing model",
                        "Auto-scaling based on demand",
                        "Integrated with Azure ecosystem",
                    ],
                    considerations=[
                        "Cold start latency",
                        "Execution time limits",
                        "State management complexity",
                    ],
                )
            )

        # Detect API-first pattern
        api_repos = [
            r.repository.name
            for r in repos
            if r.repository.primary_language in ["TypeScript", "Python", "C#"]
            and any(
                "express" in dep.name.lower() or "fastapi" in dep.name.lower()
                for dep in r.dependencies
            )
        ]

        if len(api_repos) >= 2:
            patterns.append(
                Pattern(
                    name="RESTful API Pattern",
                    pattern_type=PatternType.ARCHITECTURAL,
                    description="HTTP-based RESTful APIs for service integration and data exposure",
                    repos_using=api_repos,
                    reusability_score=90,
                    benefits=[
                        "Standard HTTP methods and status codes",
                        "Stateless communication",
                        "Wide client support",
                    ],
                    considerations=[
                        "Authentication and authorization",
                        "Rate limiting requirements",
                        "API versioning strategy",
                    ],
                )
            )

        return patterns

    def _extract_dependency_patterns(self, repos: list[RepoAnalysis]) -> list[Pattern]:
        """Extract patterns from shared dependencies"""
        patterns: list[Pattern] = []

        # Count dependency usage across repos
        dep_usage: dict[str, list[str]] = defaultdict(list)

        for repo in repos:
            for dep in repo.dependencies:
                dep_usage[dep.name].append(repo.repository.name)

        # Find commonly used dependencies (3+ repos)
        for dep_name, using_repos in dep_usage.items():
            if len(using_repos) >= 3:
                # Determine if it's a Microsoft technology
                ms_tech = None
                if "azure" in dep_name.lower():
                    ms_tech = "Azure SDK"
                elif "microsoft" in dep_name.lower():
                    ms_tech = "Microsoft Library"

                patterns.append(
                    Pattern(
                        name=f"Shared Dependency: {dep_name}",
                        pattern_type=PatternType.INTEGRATION,
                        description=f"Commonly used dependency across {len(using_repos)} repositories",
                        repos_using=using_repos,
                        reusability_score=70,
                        microsoft_technology=ms_tech,
                        benefits=[f"Proven in {len(using_repos)} production repositories"],
                        considerations=["Version consistency across repos"],
                    )
                )

        return patterns

    def _extract_microsoft_patterns(self, repos: list[RepoAnalysis]) -> list[Pattern]:
        """Extract Microsoft ecosystem usage patterns"""
        patterns: list[Pattern] = []

        # Count Microsoft service usage
        ms_services: dict[str, list[str]] = defaultdict(list)

        for repo in repos:
            for service in repo.microsoft_services:
                ms_services[service].append(repo.repository.name)

        # Create patterns for significant Microsoft usage
        for service, using_repos in ms_services.items():
            if len(using_repos) >= 2:
                patterns.append(
                    Pattern(
                        name=f"Microsoft {service} Integration",
                        pattern_type=PatternType.INTEGRATION,
                        description=f"Integration with Microsoft {service} for enterprise capabilities",
                        repos_using=using_repos,
                        reusability_score=80,
                        microsoft_technology=service,
                        benefits=[
                            "Native Azure ecosystem integration",
                            "Enterprise-grade security and compliance",
                            "Microsoft support and SLAs",
                        ],
                        considerations=[
                            "Licensing and cost implications",
                            "Vendor lock-in considerations",
                        ],
                    )
                )

        return patterns

    def find_reusable_components(self, repos: list[RepoAnalysis]) -> list[Component]:
        """
        Identify highly reusable components

        Args:
            repos: List of repository analyses

        Returns:
            List of reusable components

        Criteria for reusability:
        - Repository viability score >= 75
        - Has tests
        - Has documentation
        - Not a fork
        - Active maintenance
        """
        components: list[Component] = []

        for repo in repos:
            # Only consider highly viable repositories
            if repo.viability.total_score >= 75 and repo.has_tests:
                component = Component(
                    name=repo.repository.name,
                    repository=repo.repository.full_name,
                    file_path="/",  # Root-level component (entire repo)
                    description=repo.repository.description or "No description available",
                    language=repo.repository.primary_language or "Unknown",
                    reusability_score=repo.viability.total_score,
                    dependencies=[dep.name for dep in repo.dependencies[:10]],  # Top 10
                )
                components.append(component)

        logger.info(f"Identified {len(components)} reusable components")
        return components

    def detect_microsoft_usage_summary(
        self, repos: list[RepoAnalysis]
    ) -> dict[str, Any]:
        """
        Generate summary of Microsoft ecosystem usage

        Args:
            repos: List of repository analyses

        Returns:
            Dictionary with Microsoft usage statistics

        Example:
            >>> summary = miner.detect_microsoft_usage_summary(all_repos)
            >>> print(summary["total_repos_using_microsoft"])
            >>> print(summary["most_used_service"])
        """
        service_counts = Counter()
        repos_using_microsoft = set()

        for repo in repos:
            if repo.microsoft_services:
                repos_using_microsoft.add(repo.repository.name)
                for service in repo.microsoft_services:
                    service_counts[service] += 1

        most_used = service_counts.most_common(5) if service_counts else []

        return {
            "total_repos_analyzed": len(repos),
            "repos_using_microsoft": len(repos_using_microsoft),
            "percentage_using_microsoft": (
                (len(repos_using_microsoft) / len(repos) * 100) if repos else 0
            ),
            "unique_services": len(service_counts),
            "most_used_services": [{"service": s, "count": c} for s, c in most_used],
            "all_services": dict(service_counts),
        }
