"""
Configuration Management for Brookside BI Repository Analyzer

Establishes centralized configuration from environment variables and Azure Key Vault,
supporting multiple deployment modes (local, Azure Functions, GitHub Actions).

Best for: Secure credential management with fallback to environment variables for
development flexibility.
"""

import os
from functools import lru_cache
from pathlib import Path
from typing import Any

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class GitHubSettings(BaseSettings):
    """GitHub-specific configuration"""

    organization: str = Field(default="brookside-bi", description="GitHub organization to analyze")
    personal_access_token: str | None = Field(
        default=None, description="GitHub PAT (retrieved from Key Vault if not set)"
    )
    exclude_repos: list[str] = Field(
        default_factory=list, description="Repository names to exclude from analysis"
    )

    model_config = SettingsConfigDict(env_prefix="GITHUB_")


class NotionSettings(BaseSettings):
    """Notion-specific configuration"""

    api_key: str | None = Field(
        default=None, description="Notion API key (retrieved from Key Vault if not set)"
    )
    workspace_id: str = Field(
        default="81686779-099a-8195-b49e-00037e25c23e", description="Notion workspace ID"
    )

    # Database IDs from Innovation Nexus (from CLAUDE.md documentation)
    builds_database_id: str = Field(
        default="a1cd1528-971d-4873-a176-5e93b93555f6",
        description="Example Builds database ID"
    )
    software_database_id: str = Field(
        default="13b5e9de-2dd1-45ec-839a-4f3d50cd8d06",
        description="Software & Cost Tracker database ID"
    )
    knowledge_vault_database_id: str | None = Field(
        default=None, description="Knowledge Vault database ID"
    )
    integrations_database_id: str | None = Field(
        default=None, description="Integration Registry database ID"
    )

    model_config = SettingsConfigDict(env_prefix="NOTION_")


class AzureSettings(BaseSettings):
    """Azure-specific configuration"""

    keyvault_name: str = Field(
        default="kv-brookside-secrets", description="Azure Key Vault name"
    )
    tenant_id: str = Field(
        default="2930489e-9d8a-456b-9de9-e4787faeab9c", description="Azure AD tenant ID"
    )
    subscription_id: str = Field(
        default="cfacbbe8-a2a3-445f-a188-68b3b35f0c84", description="Azure subscription ID"
    )

    model_config = SettingsConfigDict(env_prefix="AZURE_")


class AnalysisSettings(BaseSettings):
    """Analysis-specific configuration"""

    cache_ttl_hours: int = Field(
        default=168, description="Cache TTL in hours (default: 1 week)", ge=1
    )
    max_concurrent_analyses: int = Field(
        default=10, description="Maximum concurrent repository analyses", ge=1, le=50
    )
    deep_analysis_enabled: bool = Field(
        default=True, description="Enable deep code analysis (slower but more comprehensive)"
    )
    detect_claude_configs: bool = Field(
        default=True, description="Detect and parse .claude/ configurations"
    )
    calculate_costs: bool = Field(
        default=True, description="Calculate dependency costs via Software Tracker"
    )

    model_config = SettingsConfigDict(env_prefix="ANALYSIS_")


class LoggingSettings(BaseSettings):
    """Logging configuration"""

    level: str = Field(default="INFO", description="Log level")
    format: str = Field(default="json", description="Log format: json or text")

    @field_validator("level")
    @classmethod
    def validate_log_level(cls, v: str) -> str:
        valid_levels = ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]
        v_upper = v.upper()
        if v_upper not in valid_levels:
            raise ValueError(f"Invalid log level. Must be one of: {valid_levels}")
        return v_upper

    @field_validator("format")
    @classmethod
    def validate_log_format(cls, v: str) -> str:
        valid_formats = ["json", "text"]
        v_lower = v.lower()
        if v_lower not in valid_formats:
            raise ValueError(f"Invalid log format. Must be one of: {valid_formats}")
        return v_lower

    model_config = SettingsConfigDict(env_prefix="LOG_")


class Settings(BaseSettings):
    """
    Master configuration for Brookside BI Repository Analyzer

    Loads configuration from environment variables with Azure Key Vault integration
    for secure credential management.

    Configuration precedence:
    1. Environment variables
    2. .env file (development only)
    3. Azure Key Vault (production)
    4. Default values
    """

    # Sub-configurations
    github: GitHubSettings = Field(default_factory=GitHubSettings)
    notion: NotionSettings = Field(default_factory=NotionSettings)
    azure: AzureSettings = Field(default_factory=AzureSettings)
    analysis: AnalysisSettings = Field(default_factory=AnalysisSettings)
    logging: LoggingSettings = Field(default_factory=LoggingSettings)

    # Deployment mode detection
    environment: str = Field(default="development", description="Deployment environment")

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    @property
    def is_production(self) -> bool:
        """Check if running in production mode"""
        return self.environment.lower() == "production"

    @property
    def is_development(self) -> bool:
        """Check if running in development mode"""
        return self.environment.lower() == "development"

    @property
    def project_root(self) -> Path:
        """Get project root directory"""
        return Path(__file__).parent.parent

    def model_post_init(self, __context: Any) -> None:
        """Post-initialization hook for additional setup"""
        # Ensure required secrets are available (will be loaded from Key Vault in auth.py)
        pass


@lru_cache
def get_settings() -> Settings:
    """
    Get cached settings instance

    Returns cached Settings to avoid repeated parsing of environment variables.
    Decorated with @lru_cache for singleton pattern.

    Returns:
        Settings: Application configuration

    Example:
        >>> settings = get_settings()
        >>> print(settings.github.organization)
        'brookside-bi'
    """
    return Settings()
