"""
Brookside BI Repository Analyzer - Data Models

Establishes comprehensive data structures for repository intelligence,
pattern extraction, and cost tracking to support sustainable portfolio
management across Microsoft ecosystem integrations.

Best for: Type-safe data validation and consistent API contracts across
CLI, Azure Functions, and Notion synchronization workflows.
"""

from .repository import (
    RepositoryMetadata,
    RepositoryDetails,
    RepositoryAnalysis
)

from .scoring import (
    ViabilityScore,
    ClaudeMaturity,
    Reusability
)

from .financial import (
#     Dependency,
#     CostBreakdown,
#     CostItem
# )

from .patterns import (
#     Pattern,
#     PatternType,
#     PatternUsage
# )

from .notion import (
#     NotionSyncResult,
#     NotionBuildEntry,
#     NotionSoftwareEntry,
#     NotionPatternEntry
# )

from .reporting import (
#     AnalysisReport,
#     PortfolioSummary,
#     CostOptimizationOpportunity
# )

__all__ = [
    # Repository models
    "RepositoryMetadata",
    "RepositoryDetails",
    "RepositoryAnalysis",

    # Scoring models
    "ViabilityScore",
    "ClaudeMaturity",
    "Reusability",

    # Financial models
    "Dependency",
    "CostBreakdown",
    "CostItem",

    # Pattern models
    "Pattern",
    "PatternType",
    "PatternUsage",

    # Notion integration
    "NotionSyncResult",
    "NotionBuildEntry",
    "NotionSoftwareEntry",
    "NotionPatternEntry",

    # Reporting
    "AnalysisReport",
    "PortfolioSummary",
    "CostOptimizationOpportunity",
    # Additional models
    "Repository",
    "ClaudeConfig",
    "RepoAnalysis",
    "CommitStats",
    "NotionBuildPage",
    "BuildType",
    "Component",
]
