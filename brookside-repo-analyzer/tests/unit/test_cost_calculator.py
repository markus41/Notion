"""
Unit Tests for Cost Calculator

Validates dependency cost calculation, Software Tracker integration, and
optimization recommendation logic to ensure accurate portfolio cost analysis.

Best for: Ensuring reliable cost aggregation and Microsoft-first optimization
recommendations that drive measurable cost reduction outcomes.
"""
import pytest
from decimal import Decimal
from unittest.mock import Mock, patch, MagicMock

from src.analyzers.cost_calculator import (
    CostCalculator,
    DependencyCost,
    CostSummary,
    OptimizationOpportunity,
    CostCategory
)
from src.models import Repository, Dependency


class TestCostCalculator:
    """Test suite for cost calculation and optimization logic"""

    @pytest.fixture
    def calculator(self):
        """Create CostCalculator instance for testing"""
        return CostCalculator()

    @pytest.fixture
    def mock_repo(self):
        """Create mock repository with dependencies"""
        repo = Mock(spec=Repository)
        repo.name = "test-repo"
        repo.language = "Python"
        repo.dependencies = [
            Dependency(name="fastapi", version="0.109.0", category="production"),
            Dependency(name="azure-identity", version="1.15.0", category="production"),
            Dependency(name="pytest", version="7.4.4", category="development"),
        ]
        return repo

    def test_calculate_no_dependencies(self, calculator):
        """Test cost calculation for repository with no dependencies"""
        repo = Mock(spec=Repository)
        repo.name = "empty-repo"
        repo.dependencies = []

        result = calculator.calculate(repo)

        assert result.total_monthly_cost == Decimal("0.00")
        assert result.total_annual_cost == Decimal("0.00")
        assert len(result.dependencies) == 0
        assert len(result.optimization_opportunities) == 0

    def test_calculate_with_free_dependencies(self, calculator, mock_repo):
        """Test calculation when all dependencies are free/open-source"""
        # Mock cost database with $0 costs
        mock_costs = {
            "fastapi": {"monthly_cost": 0.0, "category": "Development", "microsoft_service": None},
            "azure-identity": {"monthly_cost": 0.0, "category": "Infrastructure", "microsoft_service": "Azure SDK"},
            "pytest": {"monthly_cost": 0.0, "category": "Development", "microsoft_service": None},
        }

        with patch.object(calculator, '_load_cost_database', return_value=mock_costs):
            result = calculator.calculate(mock_repo)

        assert result.total_monthly_cost == Decimal("0.00")
        assert result.total_annual_cost == Decimal("0.00")
        assert len(result.dependencies) == 3

    def test_calculate_with_paid_dependencies(self, calculator, mock_repo):
        """Test calculation with mix of free and paid dependencies"""
        mock_costs = {
            "fastapi": {"monthly_cost": 0.0, "category": "Development", "microsoft_service": None},
            "azure-identity": {"monthly_cost": 5.0, "category": "Infrastructure", "microsoft_service": "Azure SDK"},
            "pytest": {"monthly_cost": 0.0, "category": "Development", "microsoft_service": None},
        }

        with patch.object(calculator, '_load_cost_database', return_value=mock_costs):
            result = calculator.calculate(mock_repo)

        assert result.total_monthly_cost == Decimal("5.00")
        assert result.total_annual_cost == Decimal("60.00")

    def test_cost_breakdown_by_category(self, calculator, mock_repo):
        """Test cost aggregation by category"""
        mock_costs = {
            "fastapi": {"monthly_cost": 10.0, "category": "Development", "microsoft_service": None},
            "azure-identity": {"monthly_cost": 5.0, "category": "Infrastructure", "microsoft_service": "Azure SDK"},
            "pytest": {"monthly_cost": 3.0, "category": "Development", "microsoft_service": None},
        }

        with patch.object(calculator, '_load_cost_database', return_value=mock_costs):
            result = calculator.calculate(mock_repo)

        # Total = $18/month
        assert result.total_monthly_cost == Decimal("18.00")

        # Check category breakdown
        assert result.cost_by_category[CostCategory.DEVELOPMENT] == Decimal("13.00")
        assert result.cost_by_category[CostCategory.INFRASTRUCTURE] == Decimal("5.00")

    def test_microsoft_alternative_identification(self, calculator, mock_repo):
        """Test identification of Microsoft alternatives for third-party tools"""
        mock_costs = {
            "fastapi": {"monthly_cost": 15.0, "category": "Development", "microsoft_service": None},
            "azure-identity": {"monthly_cost": 0.0, "category": "Infrastructure", "microsoft_service": "Azure SDK"},
            "pytest": {"monthly_cost": 0.0, "category": "Development", "microsoft_service": None},
        }

        mock_alternatives = {
            "fastapi": {
                "microsoft_alternative": "Azure Functions Python SDK",
                "monthly_cost_savings": 15.0,
                "migration_effort": "Medium"
            }
        }

        with patch.object(calculator, '_load_cost_database', return_value=mock_costs), \
             patch.object(calculator, '_find_microsoft_alternatives', return_value=mock_alternatives):

            result = calculator.calculate(mock_repo)

        # Should have optimization opportunity
        assert len(result.optimization_opportunities) > 0
        opportunity = result.optimization_opportunities[0]
        assert "Microsoft" in opportunity.description or "Azure" in opportunity.description

    def test_duplicate_dependency_detection(self, calculator):
        """Test detection of duplicate dependencies with different versions"""
        repo = Mock(spec=Repository)
        repo.name = "duplicate-repo"
        repo.dependencies = [
            Dependency(name="requests", version="2.28.0", category="production"),
            Dependency(name="requests", version="2.31.0", category="production"),  # Duplicate
            Dependency(name="httpx", version="0.24.0", category="production"),  # Alternative HTTP client
        ]

        mock_costs = {
            "requests": {"monthly_cost": 5.0, "category": "Development", "microsoft_service": None},
            "httpx": {"monthly_cost": 5.0, "category": "Development", "microsoft_service": None},
        }

        with patch.object(calculator, '_load_cost_database', return_value=mock_costs):
            result = calculator.calculate(repo)

        # Should detect duplicate requests versions
        duplicates = [opp for opp in result.optimization_opportunities if "duplicate" in opp.description.lower()]
        assert len(duplicates) > 0

    def test_high_cost_dependency_flagging(self, calculator, mock_repo):
        """Test flagging of high-cost dependencies for review"""
        HIGH_COST_THRESHOLD = 50.0  # $50/month threshold

        mock_costs = {
            "fastapi": {"monthly_cost": 75.0, "category": "Development", "microsoft_service": None},
            "azure-identity": {"monthly_cost": 5.0, "category": "Infrastructure", "microsoft_service": "Azure SDK"},
            "pytest": {"monthly_cost": 2.0, "category": "Development", "microsoft_service": None},
        }

        with patch.object(calculator, '_load_cost_database', return_value=mock_costs):
            result = calculator.calculate(mock_repo)

        # FastAPI at $75/month should be flagged
        high_cost_opps = [
            opp for opp in result.optimization_opportunities
            if opp.estimated_savings >= HIGH_COST_THRESHOLD
        ]
        assert len(high_cost_opps) > 0

    def test_dependency_cost_model(self):
        """Test DependencyCost data model"""
        cost = DependencyCost(
            name="azure-openai",
            version="1.0.0",
            category=CostCategory.AI_ML,
            monthly_cost=Decimal("100.00"),
            annual_cost=Decimal("1200.00"),
            microsoft_service="Azure OpenAI Service",
            is_microsoft=True
        )

        assert cost.name == "azure-openai"
        assert cost.monthly_cost == Decimal("100.00")
        assert cost.annual_cost == Decimal("1200.00")
        assert cost.is_microsoft is True

    def test_cost_summary_model(self):
        """Test CostSummary data model"""
        deps = [
            DependencyCost(
                name="dep1",
                version="1.0.0",
                category=CostCategory.DEVELOPMENT,
                monthly_cost=Decimal("10.00"),
                annual_cost=Decimal("120.00")
            ),
            DependencyCost(
                name="dep2",
                version="2.0.0",
                category=CostCategory.INFRASTRUCTURE,
                monthly_cost=Decimal("20.00"),
                annual_cost=Decimal("240.00")
            )
        ]

        summary = CostSummary(
            total_monthly_cost=Decimal("30.00"),
            total_annual_cost=Decimal("360.00"),
            dependencies=deps,
            cost_by_category={
                CostCategory.DEVELOPMENT: Decimal("10.00"),
                CostCategory.INFRASTRUCTURE: Decimal("20.00")
            },
            optimization_opportunities=[]
        )

        assert summary.total_monthly_cost == Decimal("30.00")
        assert len(summary.dependencies) == 2
        assert summary.cost_by_category[CostCategory.DEVELOPMENT] == Decimal("10.00")

    def test_optimization_opportunity_model(self):
        """Test OptimizationOpportunity data model"""
        opportunity = OptimizationOpportunity(
            type="microsoft_alternative",
            description="Replace Slack with Microsoft Teams",
            current_cost=Decimal("120.00"),
            estimated_savings=Decimal("120.00"),
            migration_effort="Low",
            recommendation="Migrate to Microsoft Teams (included in M365)"
        )

        assert opportunity.type == "microsoft_alternative"
        assert opportunity.estimated_savings == Decimal("120.00")
        assert "Teams" in opportunity.description

    def test_annual_cost_calculation(self, calculator, mock_repo):
        """Test annual cost is correctly calculated as monthly * 12"""
        mock_costs = {
            "fastapi": {"monthly_cost": 10.0, "category": "Development", "microsoft_service": None},
            "azure-identity": {"monthly_cost": 5.0, "category": "Infrastructure", "microsoft_service": "Azure SDK"},
            "pytest": {"monthly_cost": 3.0, "category": "Development", "microsoft_service": None},
        }

        with patch.object(calculator, '_load_cost_database', return_value=mock_costs):
            result = calculator.calculate(mock_repo)

        # Monthly: $18, Annual: $18 * 12 = $216
        assert result.total_monthly_cost == Decimal("18.00")
        assert result.total_annual_cost == Decimal("216.00")

    def test_zero_cost_optimization_skipped(self, calculator):
        """Test that zero-cost dependencies don't generate optimization opportunities"""
        repo = Mock(spec=Repository)
        repo.name = "free-repo"
        repo.dependencies = [
            Dependency(name="open-source-lib", version="1.0.0", category="production")
        ]

        mock_costs = {
            "open-source-lib": {"monthly_cost": 0.0, "category": "Development", "microsoft_service": None}
        }

        with patch.object(calculator, '_load_cost_database', return_value=mock_costs):
            result = calculator.calculate(repo)

        # No optimization opportunities for $0 cost
        assert len(result.optimization_opportunities) == 0

    def test_cost_database_caching(self, calculator):
        """Test cost database is cached after first load"""
        mock_costs = {"dep": {"monthly_cost": 5.0, "category": "Development"}}

        with patch.object(calculator, '_load_cost_database', return_value=mock_costs) as mock_load:
            # First call
            calculator._get_cost_for_dependency("dep")
            # Second call (should use cache)
            calculator._get_cost_for_dependency("dep")

        # Should only load once due to caching
        assert mock_load.call_count == 1

    def test_unknown_dependency_handling(self, calculator):
        """Test graceful handling of dependencies not in cost database"""
        repo = Mock(spec=Repository)
        repo.name = "unknown-deps"
        repo.dependencies = [
            Dependency(name="obscure-package", version="0.1.0", category="production")
        ]

        mock_costs = {}  # Empty cost database

        with patch.object(calculator, '_load_cost_database', return_value=mock_costs):
            result = calculator.calculate(repo)

        # Should handle gracefully with $0 cost assumption
        assert result.total_monthly_cost == Decimal("0.00")

    def test_microsoft_service_filtering(self, calculator, mock_repo):
        """Test filtering for Microsoft services vs. third-party"""
        mock_costs = {
            "fastapi": {"monthly_cost": 10.0, "category": "Development", "microsoft_service": None},
            "azure-identity": {"monthly_cost": 0.0, "category": "Infrastructure", "microsoft_service": "Azure SDK"},
            "azure-functions": {"monthly_cost": 20.0, "category": "Infrastructure", "microsoft_service": "Azure Functions"},
        }

        repo = Mock(spec=Repository)
        repo.dependencies = [
            Dependency(name="fastapi", version="0.109.0", category="production"),
            Dependency(name="azure-identity", version="1.15.0", category="production"),
            Dependency(name="azure-functions", version="1.0.0", category="production"),
        ]

        with patch.object(calculator, '_load_cost_database', return_value=mock_costs):
            result = calculator.calculate(repo)

        # Count Microsoft vs. third-party costs
        microsoft_deps = [d for d in result.dependencies if d.is_microsoft]
        third_party_deps = [d for d in result.dependencies if not d.is_microsoft]

        assert len(microsoft_deps) == 2  # azure-identity, azure-functions
        assert len(third_party_deps) == 1  # fastapi


class TestCostCategory:
    """Test CostCategory enum"""

    def test_category_values(self):
        """Test all cost categories are defined"""
        assert CostCategory.DEVELOPMENT.value == "Development"
        assert CostCategory.INFRASTRUCTURE.value == "Infrastructure"
        assert CostCategory.AI_ML.value == "AI/ML"
        assert CostCategory.ANALYTICS.value == "Analytics"
        assert CostCategory.SECURITY.value == "Security"
        assert CostCategory.PRODUCTIVITY.value == "Productivity"
        assert CostCategory.STORAGE.value == "Storage"
        assert CostCategory.COMMUNICATION.value == "Communication"


class TestCostCalculatorIntegration:
    """Integration-style tests with realistic scenarios"""

    @pytest.fixture
    def calculator(self):
        return CostCalculator()

    def test_innovation_nexus_cost_scenario(self, calculator):
        """Test cost calculation for Innovation Nexus-like repository"""
        repo = Mock(spec=Repository)
        repo.name = "innovation-nexus"
        repo.language = "Python"
        repo.dependencies = [
            # Azure services (Microsoft)
            Dependency(name="azure-identity", version="1.15.0", category="production"),
            Dependency(name="azure-keyvault-secrets", version="4.7.0", category="production"),
            Dependency(name="azure-monitor-opentelemetry", version="1.2.0", category="production"),

            # Third-party (potential Microsoft alternatives)
            Dependency(name="fastapi", version="0.109.0", category="production"),
            Dependency(name="sqlalchemy", version="2.0.25", category="production"),

            # Development tools
            Dependency(name="pytest", version="7.4.4", category="development"),
            Dependency(name="black", version="24.1.0", category="development"),
        ]

        mock_costs = {
            "azure-identity": {"monthly_cost": 0.0, "category": "Infrastructure", "microsoft_service": "Azure SDK"},
            "azure-keyvault-secrets": {"monthly_cost": 5.0, "category": "Security", "microsoft_service": "Azure Key Vault"},
            "azure-monitor-opentelemetry": {"monthly_cost": 10.0, "category": "Analytics", "microsoft_service": "Application Insights"},
            "fastapi": {"monthly_cost": 0.0, "category": "Development", "microsoft_service": None},
            "sqlalchemy": {"monthly_cost": 0.0, "category": "Development", "microsoft_service": None},
            "pytest": {"monthly_cost": 0.0, "category": "Development", "microsoft_service": None},
            "black": {"monthly_cost": 0.0, "category": "Development", "microsoft_service": None},
        }

        with patch.object(calculator, '_load_cost_database', return_value=mock_costs):
            result = calculator.calculate(repo)

        # Total: $15/month ($5 Key Vault + $10 App Insights)
        assert result.total_monthly_cost == Decimal("15.00")
        assert result.total_annual_cost == Decimal("180.00")

        # Verify Microsoft service costs are properly categorized
        assert result.cost_by_category[CostCategory.SECURITY] == Decimal("5.00")
        assert result.cost_by_category[CostCategory.ANALYTICS] == Decimal("10.00")

    def test_high_cost_portfolio_optimization(self, calculator):
        """Test optimization recommendations for high-cost portfolio"""
        repo = Mock(spec=Repository)
        repo.name = "expensive-repo"
        repo.dependencies = [
            Dependency(name="slack-sdk", version="3.0.0", category="production"),
            Dependency(name="jira-python", version="3.5.0", category="production"),
            Dependency(name="trello-python", version="0.19.0", category="production"),
        ]

        mock_costs = {
            "slack-sdk": {"monthly_cost": 120.0, "category": "Communication", "microsoft_service": None},
            "jira-python": {"monthly_cost": 80.0, "category": "Productivity", "microsoft_service": None},
            "trello-python": {"monthly_cost": 60.0, "category": "Productivity", "microsoft_service": None},
        }

        mock_alternatives = {
            "slack-sdk": {
                "microsoft_alternative": "Microsoft Teams",
                "monthly_cost_savings": 120.0,
                "migration_effort": "Medium"
            },
            "jira-python": {
                "microsoft_alternative": "Azure DevOps",
                "monthly_cost_savings": 80.0,
                "migration_effort": "High"
            },
            "trello-python": {
                "microsoft_alternative": "Microsoft Planner",
                "monthly_cost_savings": 60.0,
                "migration_effort": "Low"
            }
        }

        with patch.object(calculator, '_load_cost_database', return_value=mock_costs), \
             patch.object(calculator, '_find_microsoft_alternatives', return_value=mock_alternatives):

            result = calculator.calculate(repo)

        # Total cost: $260/month
        assert result.total_monthly_cost == Decimal("260.00")

        # Should have 3 optimization opportunities (all third-party with Microsoft alternatives)
        assert len(result.optimization_opportunities) >= 3

        # Total potential savings: $260/month
        total_savings = sum(opp.estimated_savings for opp in result.optimization_opportunities)
        assert total_savings >= Decimal("260.00")


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--cov=src.analyzers.cost_calculator", "--cov-report=term-missing"])
