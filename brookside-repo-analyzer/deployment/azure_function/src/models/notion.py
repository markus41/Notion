"""
Notion integration models for synchronization

Temporary stub implementation to enable function deployment.
TODO: Implement comprehensive Notion sync models.
"""

from dataclasses import dataclass
from typing import Optional


@dataclass
class NotionSyncResult:
    """Result of Notion synchronization operation"""
    success: bool
    page_id: Optional[str] = None
    error_message: Optional[str] = None


@dataclass
class NotionBuildEntry:
    """Notion Example Build entry"""
    title: str
    repository_url: str
    viability_score: int
    status: str = "Active"


@dataclass
class NotionSoftwareEntry:
    """Notion Software Tracker entry"""
    name: str
    category: str
    monthly_cost: float
    status: str = "Active"


@dataclass
class NotionPatternEntry:
    """Notion Pattern entry"""
    name: str
    type: str
    usage_count: int
    description: str


@dataclass
class NotionBuildPage:
    """Represents a Notion build page"""
    id: str
    title: str
    url: str
    properties: dict = None

    def __post_init__(self):
        if self.properties is None:
            self.properties = {}


@dataclass
class BuildType:
    """Type of build"""
    name: str
    category: str
