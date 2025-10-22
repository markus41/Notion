"""
Cost Calculator for Brookside BI Repository Analyzer

Calculates dependency costs and identifies optimization opportunities by integrating
with Notion Software Tracker to establish comprehensive cost visibility.

Best for: Organizations requiring automated cost tracking across repositories
to drive optimization decisions and budget planning.
"""

import logging
from typing import Any

from src.models import CostBreakdown, CostOptimizationOpportunity, Dependency, RepoAnalysis

logger = logging.getLogger(__name__)


class CostCalculator:
    """
    Dependency cost calculation and optimization engine

    Integrates with Notion Software Tracker to:
    - Map dependencies to known costs
    - Calculate aggregate repository costs
    - Identify cost optimization opportunities
    - Suggest Microsoft alternatives
    """

    # Known dependency costs (monthly USD)
    # This would be populated from Notion Software Tracker in production
    KNOWN_COSTS: dict[str, float] = {
        # Azure Services
        "azure-functions": 5.0,
        "azure-storage": 2.0,
        "azure-keyvault": 0.03,  # Per secret per month
        "@azure/functions": 5.0,
        # Popular services (estimates)
        "stripe": 0.0,  # Free tier available
        "sendgrid": 15.0,  # Typical plan
        "twilio": 20.0,  # Typical usage
        "datadog": 15.0,  # Per host
        "sentry": 26.0,  # Team plan
        "auth0": 23.0,  # Developer plan
        # Most open-source packages: $0
    }

    # Microsoft alternatives for common third-party tools
    MICROSOFT_ALTERNATIVES: dict[str, dict[str, Any]] = {
        "auth0": {
            "alternative": "Azure Active Directory B2C",
            "monthly_cost": 0.0,  # Free tier for most use cases
            "savings": 23.0,
        },
        "sendgrid": {
            "alternative": "Azure Communication Services",
            "monthly_cost": 0.0,  # Pay-per-use
            "savings": 15.0,
        },
        "datadog": {
            "alternative": "Azure Monitor + Application Insights",
            "monthly_cost": 5.0,
            "savings": 10.0,
        },
        "sentry": {
            "alternative": "Azure Application Insights",
            "monthly_cost": 2.33,  # Basic tier
            "savings": 23.67,
        },
    }

    def __init__(self):
        """Initialize cost calculator"""
        pass

    async def calculate_repository_costs(
        self, analysis: RepoAnalysis
    ) -> CostBreakdown:
        """
        Calculate total costs for repository dependencies

        Args:
            analysis: Repository analysis with dependencies

        Returns:
            Detailed cost breakdown

        Example:
            >>> calc = CostCalculator()
            >>> breakdown = await calc.calculate_repository_costs(analysis)
            >>> print(f"Monthly: ${breakdown.total_monthly_cost}")
            >>> print(f"Annual: ${breakdown.annual_cost}")
        """
        total_cost = 0.0
        costed_deps: list[Dependency] = []
        unknown_deps: list[str] = []

        for dep in analysis.dependencies:
            # Check if we have cost data
            cost = self._get_dependency_cost(dep.name)

            if cost > 0:
                dep.estimated_monthly_cost = cost
                costed_deps.append(dep)
                total_cost += cost
            else:
                unknown_deps.append(dep.name)

        # Sort by cost (descending) and get top 5
        sorted_deps = sorted(costed_deps, key=lambda d: d.estimated_monthly_cost, reverse=True)
        top_5 = sorted_deps[:5]

        breakdown = CostBreakdown(
            total_monthly_cost=total_cost,
            dependencies=costed_deps,
            unknown_dependencies=unknown_deps,
            top_5_expensive=top_5,
        )

        logger.info(
            f"Cost calculation complete for {analysis.repository.name}: "
            f"${total_cost:.2f}/month"
        )

        return breakdown

    def _get_dependency_cost(self, dep_name: str) -> float:
        """
        Get monthly cost for dependency

        Args:
            dep_name: Dependency name

        Returns:
            Monthly cost in USD (0.0 if unknown or free)
        """
        # Exact match
        if dep_name in self.KNOWN_COSTS:
            return self.KNOWN_COSTS[dep_name]

        # Partial match (e.g., @azure/storage matches azure-storage)
        dep_lower = dep_name.lower()
        for known_dep, cost in self.KNOWN_COSTS.items():
            if known_dep.lower() in dep_lower or dep_lower in known_dep.lower():
                return cost

        # Unknown or free
        return 0.0

    async def identify_cost_optimization_opportunities(
        self, repos: list[RepoAnalysis]
    ) -> list[CostOptimizationOpportunity]:
        """
        Identify cost optimization opportunities across repositories

        Args:
            repos: List of repository analyses

        Returns:
            List of optimization opportunities

        Example:
            >>> opportunities = await calc.identify_cost_optimization_opportunities(all_repos)
            >>> for opp in opportunities:
            ...     print(f"{opp.current_tool} → {opp.alternative_tool}: ${opp.monthly_savings}/mo")
        """
        opportunities: list[CostOptimizationOpportunity] = []

        # Check each repository for third-party tools with Microsoft alternatives
        for repo in repos:
            for dep in repo.dependencies:
                if dep.name.lower() in self.MICROSOFT_ALTERNATIVES:
                    alt_info = self.MICROSOFT_ALTERNATIVES[dep.name.lower()]

                    current_cost = self._get_dependency_cost(dep.name)

                    opportunity = CostOptimizationOpportunity(
                        current_tool=dep.name,
                        alternative_tool=alt_info["alternative"],
                        current_monthly_cost=current_cost,
                        alternative_monthly_cost=alt_info["monthly_cost"],
                        monthly_savings=current_cost - alt_info["monthly_cost"],
                        annual_savings=(current_cost - alt_info["monthly_cost"]) * 12,
                        recommendation=f"Consider migrating from {dep.name} to {alt_info['alternative']} for better Azure ecosystem integration",
                        trade_offs=[
                            "Migration effort required",
                            "Team learning curve",
                            "Feature parity assessment needed",
                        ],
                    )

                    opportunities.append(opportunity)

        # Sort by annual savings (descending)
        opportunities.sort(key=lambda o: o.annual_savings, reverse=True)

        logger.info(f"Identified {len(opportunities)} cost optimization opportunities")
        return opportunities

    def calculate_aggregate_costs(
        self, repos: list[RepoAnalysis]
    ) -> dict[str, Any]:
        """
        Calculate aggregate costs across all repositories

        Args:
            repos: List of repository analyses

        Returns:
            Dictionary with aggregate cost statistics

        Example:
            >>> stats = calc.calculate_aggregate_costs(all_repos)
            >>> print(f"Total monthly: ${stats['total_monthly']}")
            >>> print(f"Average per repo: ${stats['average_per_repo']}")
        """
        total_monthly = sum(repo.monthly_cost for repo in repos)
        total_annual = total_monthly * 12

        repos_with_costs = [repo for repo in repos if repo.monthly_cost > 0]

        average_per_repo = (
            total_monthly / len(repos_with_costs) if repos_with_costs else 0.0
        )

        # Find most expensive repositories
        sorted_repos = sorted(repos, key=lambda r: r.monthly_cost, reverse=True)
        top_5_expensive = [
            {
                "name": repo.repository.name,
                "monthly_cost": repo.monthly_cost,
                "annual_cost": repo.monthly_cost * 12,
            }
            for repo in sorted_repos[:5]
        ]

        return {
            "total_monthly": round(total_monthly, 2),
            "total_annual": round(total_annual, 2),
            "repos_analyzed": len(repos),
            "repos_with_costs": len(repos_with_costs),
            "average_per_repo": round(average_per_repo, 2),
            "top_5_expensive_repos": top_5_expensive,
        }
