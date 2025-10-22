"""
Custom exceptions for Brookside BI Repository Analyzer

Establishes clear error hierarchy to support robust error handling and
provide actionable resolution guidance across the system.
"""

from typing import Any


class RepositoryAnalyzerError(Exception):
    """Base exception for all repository analyzer errors"""

    def __init__(self, message: str, details: dict[str, Any] | None = None):
        self.message = message
        self.details = details or {}
        super().__init__(self.message)


class AuthenticationError(RepositoryAnalyzerError):
    """Raised when authentication fails for GitHub or Notion"""

    pass


class KeyVaultError(RepositoryAnalyzerError):
    """Raised when Azure Key Vault secret retrieval fails"""

    pass


class GitHubAPIError(RepositoryAnalyzerError):
    """Raised when GitHub API requests fail"""

    def __init__(
        self,
        message: str,
        status_code: int | None = None,
        response_data: dict[str, Any] | None = None,
    ):
        super().__init__(message, {"status_code": status_code, "response": response_data})
        self.status_code = status_code


class NotionAPIError(RepositoryAnalyzerError):
    """Raised when Notion API requests fail"""

    def __init__(
        self,
        message: str,
        status_code: int | None = None,
        response_data: dict[str, Any] | None = None,
    ):
        super().__init__(message, {"status_code": status_code, "response": response_data})
        self.status_code = status_code


class AnalysisError(RepositoryAnalyzerError):
    """Raised when repository analysis fails"""

    def __init__(self, message: str, repository: str | None = None):
        super().__init__(message, {"repository": repository})
        self.repository = repository


class ConfigurationError(RepositoryAnalyzerError):
    """Raised when configuration is invalid or missing"""

    pass


class RateLimitError(RepositoryAnalyzerError):
    """Raised when API rate limits are exceeded"""

    def __init__(self, message: str, retry_after: int | None = None):
        super().__init__(message, {"retry_after": retry_after})
        self.retry_after = retry_after
