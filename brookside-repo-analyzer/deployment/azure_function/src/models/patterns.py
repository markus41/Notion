"""
Pattern extraction models for architectural reusability

Temporary stub implementation to enable function deployment.
TODO: Implement comprehensive pattern mining models.
"""

from dataclasses import dataclass
from enum import Enum
from typing import Optional


class PatternType(str, Enum):
    """Types of architectural patterns"""
    API_INTEGRATION = "api_integration"
    DATA_PROCESSING = "data_processing"
    AUTHENTICATION = "authentication"
    DEPLOYMENT = "deployment"
    TESTING = "testing"


@dataclass
class Pattern:
    """Represents a reusable architectural pattern"""
    name: str
    type: PatternType
    description: str
    usage_count: int = 0
    repositories: list = None

    def __post_init__(self):
        if self.repositories is None:
            self.repositories = []


@dataclass
class PatternUsage:
    """Usage of a pattern in a repository"""
    pattern_name: str
    repository_name: str
    confidence_score: float = 1.0


@dataclass
class Component:
    """Represents a software component"""
    name: str
    type: str
    description: Optional[str] = None
