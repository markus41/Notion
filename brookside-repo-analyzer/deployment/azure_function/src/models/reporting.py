"""
Reporting and analysis summary models

Temporary stub implementation to enable function deployment.
TODO: Implement comprehensive reporting models.
"""

from dataclasses import dataclass
from typing import List, Optional


@dataclass
class AnalysisReport:
    """Comprehensive analysis report"""
    repository_name: str
    viability_score: int
    cost_monthly: float
    summary: str
    recommendations: List[str] = None

    def __post_init__(self):
        if self.recommendations is None:
            self.recommendations = []


@dataclass
class PortfolioSummary:
    """Summary of portfolio-wide analysis"""
    total_repositories: int
    average_viability: float
    total_monthly_cost: float
    total_annual_cost: float
    high_value_repos: List[str] = None

    def __post_init__(self):
        if self.high_value_repos is None:
            self.high_value_repos = []


@dataclass
class CostOptimizationOpportunity:
    """Represents a cost optimization opportunity"""
    repository_name: str
    current_cost: float
    potential_savings: float
    recommendation: str
    priority: str = "Medium"


@dataclass
class RepoAnalysis:
    """Repository analysis results"""
    name: str
    viability_score: int
    monthly_cost: float
    patterns: List = None

    def __post_init__(self):
        if self.patterns is None:
            self.patterns = []


@dataclass
class Repository:
    """Repository metadata"""
    name: str
    full_name: str
    url: str
    description: Optional[str] = None


@dataclass
class ClaudeConfig:
    """Claude Code configuration"""
    exists: bool
    maturity_level: str = "None"


@dataclass
class CommitStats:
    """Commit statistics"""
    total_commits: int
    last_commit_date: Optional[str] = None
