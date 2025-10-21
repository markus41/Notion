"""
Cost Database Module for Brookside BI Repository Analyzer

Provides centralized cost lookup for software dependencies and services.
Streamlines cost estimation workflows with comprehensive service pricing data.

Best for: Organizations requiring accurate cost tracking across repository portfolios
with support for Microsoft and third-party service pricing.
"""

import json
import logging
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)


class CostDatabase:
    """
    Centralized cost database for software and services

    Maintains pricing information for:
    - Azure services
    - Microsoft 365 and Power Platform
    - GitHub Enterprise
    - Third-party services
    - Open source software (infrastructure costs)
    """

    def __init__(self, database_path: Optional[Path] = None):
        """
        Initialize cost database

        Args:
            database_path: Path to cost_database.json (optional)

        Example:
            >>> cost_db = CostDatabase()
            >>> cost = cost_db.get_cost("azure-functions")
        """
        if database_path is None:
            # Default to data directory
            database_path = Path(__file__).parent.parent / "data" / "cost_database.json"

        self.database_path = database_path
        self._data = self._load_database()

    def _load_database(self) -> dict:
        """Load cost database from JSON file"""
        try:
            with open(self.database_path, "r", encoding="utf-8") as f:
                data = json.load(f)
                logger.info(f"Loaded cost database version {data.get('version', 'unknown')}")
                return data
        except FileNotFoundError:
            logger.warning(f"Cost database not found: {self.database_path}")
            return {"software": {}}
        except json.JSONDecodeError as e:
            logger.error(f"Invalid cost database JSON: {e}")
            return {"software": {}}

    def get_cost(self, software_name: str) -> float:
        """
        Get monthly cost for software by name

        Args:
            software_name: Software package or service name

        Returns:
            Monthly cost in USD, or 0.0 if not found

        Example:
            >>> cost = cost_db.get_cost("azure-functions")
            >>> print(f"${cost}/month")
            $5.0/month
        """
        software_name_lower = software_name.lower().replace("_", "-")

        # Search all categories
        for category_name, category_data in self._data.get("software", {}).items():
            for key, software in category_data.items():
                if key == software_name_lower or software.get("name", "").lower() == software_name_lower:
                    cost = software.get("monthly_cost_usd", 0.0)
                    logger.debug(f"Found cost for {software_name}: ${cost}/month")
                    return cost

        logger.debug(f"No cost found for {software_name}, returning $0.0")
        return 0.0

    def get_software_info(self, software_name: str) -> Optional[dict]:
        """
        Get complete information for software

        Args:
            software_name: Software package or service name

        Returns:
            Software info dict or None if not found

        Example:
            >>> info = cost_db.get_software_info("azure-openai")
            >>> print(info["category"])
            AI/ML
        """
        software_name_lower = software_name.lower().replace("_", "-")

        for category_name, category_data in self._data.get("software", {}).items():
            for key, software in category_data.items():
                if key == software_name_lower or software.get("name", "").lower() == software_name_lower:
                    return {
                        **software,
                        "database_key": key,
                        "category_group": category_name,
                    }

        return None

    def is_microsoft_service(self, software_name: str) -> bool:
        """
        Check if software is a Microsoft service

        Args:
            software_name: Software package or service name

        Returns:
            True if Microsoft service, False otherwise

        Example:
            >>> is_ms = cost_db.is_microsoft_service("azure-functions")
            >>> print(is_ms)
            True
        """
        info = self.get_software_info(software_name)
        if info:
            ms_service = info.get("microsoft_service", "None")
            return ms_service != "None"

        # Fallback: Check for Microsoft keywords in name
        microsoft_keywords = [
            "azure", "microsoft", "dotnet", "aspnet", "msal",
            "graph", "office", "teams", "sharepoint", "powerapps", "powerbi"
        ]

        name_lower = software_name.lower()
        return any(keyword in name_lower for keyword in microsoft_keywords)

    def get_microsoft_alternative(self, software_name: str) -> Optional[str]:
        """
        Get Microsoft alternative for third-party software

        Args:
            software_name: Third-party software name

        Returns:
            Microsoft alternative name or None

        Example:
            >>> alt = cost_db.get_microsoft_alternative("slack")
            >>> print(alt)
            Microsoft Teams (included in M365)
        """
        info = self.get_software_info(software_name)
        if info:
            return info.get("microsoft_alternative")

        return None

    def get_all_azure_services(self) -> list[dict]:
        """Get list of all Azure services with costs"""
        return list(self._data.get("software", {}).get("azure_services", {}).values())

    def get_all_third_party_services(self) -> list[dict]:
        """Get list of all third-party services with costs"""
        return list(self._data.get("software", {}).get("third_party_services", {}).values())

    def get_total_cost(self, software_names: list[str]) -> float:
        """
        Calculate total monthly cost for list of software

        Args:
            software_names: List of software names

        Returns:
            Total monthly cost in USD

        Example:
            >>> total = cost_db.get_total_cost(["azure-functions", "azure-storage"])
            >>> print(f"${total}/month")
            $7.0/month
        """
        return sum(self.get_cost(name) for name in software_names)

    def search_by_category(self, category: str) -> list[dict]:
        """
        Search software by category

        Args:
            category: Category name (e.g., "Infrastructure", "AI/ML")

        Returns:
            List of software in category

        Example:
            >>> ai_services = cost_db.search_by_category("AI/ML")
            >>> for service in ai_services:
            ...     print(f"{service['name']}: ${service['monthly_cost_usd']}")
        """
        results = []
        category_lower = category.lower()

        for category_group, category_data in self._data.get("software", {}).items():
            for key, software in category_data.items():
                if software.get("category", "").lower() == category_lower:
                    results.append({
                        **software,
                        "database_key": key,
                        "category_group": category_group,
                    })

        return results


# Global instance for easy access
_cost_database_instance: Optional[CostDatabase] = None


def get_cost_database() -> CostDatabase:
    """
    Get global cost database instance

    Returns:
        CostDatabase singleton

    Example:
        >>> from src.analyzers.cost_database import get_cost_database
        >>> cost_db = get_cost_database()
        >>> cost = cost_db.get_cost("azure-openai")
    """
    global _cost_database_instance
    if _cost_database_instance is None:
        _cost_database_instance = CostDatabase()
    return _cost_database_instance
