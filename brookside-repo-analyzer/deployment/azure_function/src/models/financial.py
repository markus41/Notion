"""
Financial and dependency models for cost tracking

Temporary stub implementation to enable function deployment.
TODO: Implement comprehensive cost tracking models.
"""

from dataclasses import dataclass
from typing import Optional


@dataclass
class Dependency:
    """Represents a software dependency with cost information"""
    name: str
    version: Optional[str] = None
    monthly_cost: float = 0.0
    license_type: Optional[str] = None


@dataclass
class CostItem:
    """Individual cost item"""
    name: str
    amount: float
    category: str


@dataclass
class CostBreakdown:
    """Cost breakdown for a repository"""
    monthly_total: float = 0.0
    annual_total: float = 0.0
    dependencies: list = None

    def __post_init__(self):
        if self.dependencies is None:
            self.dependencies = []
