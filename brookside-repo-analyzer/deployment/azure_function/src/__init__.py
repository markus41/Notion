"""
Brookside BI Innovation Nexus Repository Analyzer

Automated GitHub repository analysis and Notion integration designed to establish
comprehensive portfolio visibility and drive measurable outcomes through systematic
viability assessment, pattern mining, and cost optimization.

Best for: Organizations scaling innovation workflows across teams who require
enterprise-grade repository health monitoring and knowledge management integration.

Architecture:
- Multi-dimensional viability scoring (0-100 points)
- Claude Code integration maturity detection
- Cross-repository pattern extraction
- Dependency cost calculation with Microsoft alternatives
- Automated Notion synchronization (Example Builds, Software Tracker)

Author: Brookside BI
Contact: consultations@brooksidebi.com
Version: 1.0.0
"""

__version__ = "1.0.0"
__author__ = "Brookside BI"
__email__ = "consultations@brooksidebi.com"

# Export key components for programmatic access
from src.config import Settings, get_settings
from src.models.repository import Repository, RepositoryMetadata
from src.models.scoring import ViabilityScore, ClaudeMaturity, ReusabilityLevel

__all__ = [
    "Settings",
    "get_settings",
    "Repository",
    "RepositoryMetadata",
    "ViabilityScore",
    "ClaudeMaturity",
    "ReusabilityLevel",
]
