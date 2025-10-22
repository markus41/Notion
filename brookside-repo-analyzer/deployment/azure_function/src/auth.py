"""
Authentication Module for Brookside BI Repository Analyzer

Establishes secure credential retrieval from Azure Key Vault for GitHub and Notion APIs.
Supports both managed identity (Azure Functions) and Azure CLI (local development).

Best for: Organizations requiring centralized secret management with Azure Key Vault
integration across multiple deployment environments.
"""

import logging
from functools import lru_cache
from typing import Any

from azure.core.exceptions import ResourceNotFoundError
from azure.identity import DefaultAzureCredential, ManagedIdentityCredential
from azure.keyvault.secrets import SecretClient

from src.config import Settings
from src.exceptions import AuthenticationError, KeyVaultError

logger = logging.getLogger(__name__)


class KeyVaultClient:
    """
    Azure Key Vault client for secure credential retrieval

    Uses DefaultAzureCredential to support multiple authentication methods:
    1. Managed Identity (Azure Functions production)
    2. Azure CLI (local development)
    3. Environment variables (CI/CD pipelines)
    """

    def __init__(self, settings: Settings):
        """
        Initialize Key Vault client

        Args:
            settings: Application configuration

        Raises:
            AuthenticationError: If Azure authentication fails
        """
        self.settings = settings
        self.vault_url = f"https://{settings.azure.keyvault_name}.vault.azure.net/"

        try:
            # Establish Azure authentication with automatic fallback
            self.credential = DefaultAzureCredential()
            self.client = SecretClient(vault_url=self.vault_url, credential=self.credential)

            # Test connection
            self._test_connection()

            logger.info(f"Successfully connected to Key Vault: {settings.azure.keyvault_name}")

        except Exception as e:
            error_msg = f"Failed to authenticate with Azure Key Vault: {str(e)}"
            logger.error(error_msg)
            raise AuthenticationError(error_msg, {"vault": settings.azure.keyvault_name})

    def _test_connection(self) -> None:
        """
        Test Key Vault connection with a simple operation

        Raises:
            AuthenticationError: If connection test fails
        """
        try:
            # Attempt to list secrets (requires get + list permissions)
            list(self.client.list_properties_of_secrets())
        except Exception as e:
            raise AuthenticationError(
                f"Key Vault connection test failed: {str(e)}",
                {"vault_url": self.vault_url},
            )

    def get_secret(self, secret_name: str) -> str:
        """
        Retrieve secret value from Key Vault

        Args:
            secret_name: Name of the secret to retrieve

        Returns:
            str: Secret value

        Raises:
            KeyVaultError: If secret retrieval fails

        Example:
            >>> client = KeyVaultClient(settings)
            >>> token = client.get_secret("github-personal-access-token")
        """
        try:
            logger.debug(f"Retrieving secret: {secret_name}")
            secret = self.client.get_secret(secret_name)
            return secret.value

        except ResourceNotFoundError:
            error_msg = f"Secret '{secret_name}' not found in Key Vault"
            logger.error(error_msg)
            raise KeyVaultError(
                error_msg,
                {
                    "secret_name": secret_name,
                    "vault": self.settings.azure.keyvault_name,
                    "resolution": f"Add secret via: az keyvault secret set --vault-name {self.settings.azure.keyvault_name} --name {secret_name} --value '<value>'",
                },
            )

        except Exception as e:
            error_msg = f"Failed to retrieve secret '{secret_name}': {str(e)}"
            logger.error(error_msg)
            raise KeyVaultError(error_msg, {"secret_name": secret_name})


def get_keyvault_client(settings: Settings) -> KeyVaultClient:
    """
    Get Key Vault client instance

    Creates a new KeyVaultClient for secure credential retrieval.
    Settings are cached via get_settings(), so recreation is minimal overhead.

    Args:
        settings: Application configuration

    Returns:
        KeyVaultClient: Authenticated Key Vault client

    Example:
        >>> from src.config import get_settings
        >>> settings = get_settings()
        >>> kv_client = get_keyvault_client(settings)
        >>> github_token = kv_client.get_secret("github-personal-access-token")
    """
    return KeyVaultClient(settings)


class CredentialManager:
    """
    Manages credentials for GitHub and Notion APIs

    Automatically retrieves credentials from Key Vault if not provided in environment.
    Provides centralized credential access across the application.
    """

    def __init__(self, settings: Settings, keyvault_client: KeyVaultClient | None = None):
        """
        Initialize credential manager

        Args:
            settings: Application configuration
            keyvault_client: Optional Key Vault client (auto-created if None)
        """
        self.settings = settings
        self.kv_client = keyvault_client or get_keyvault_client(settings)
        self._github_token: str | None = None
        self._notion_api_key: str | None = None

    @property
    def github_token(self) -> str:
        """
        Get GitHub Personal Access Token

        Returns token from environment or retrieves from Key Vault.

        Returns:
            str: GitHub PAT

        Raises:
            AuthenticationError: If token retrieval fails

        Example:
            >>> creds = CredentialManager(settings)
            >>> token = creds.github_token
        """
        if self._github_token:
            return self._github_token

        # Try environment variable first
        if self.settings.github.personal_access_token:
            logger.info("Using GitHub token from environment variable")
            self._github_token = self.settings.github.personal_access_token
            return self._github_token

        # Fallback to Key Vault
        try:
            logger.info("Retrieving GitHub token from Azure Key Vault")
            self._github_token = self.kv_client.get_secret("github-personal-access-token")
            return self._github_token
        except KeyVaultError as e:
            raise AuthenticationError(
                "GitHub token not found in environment or Key Vault. "
                "Set GITHUB_PERSONAL_ACCESS_TOKEN environment variable or "
                "add 'github-personal-access-token' to Key Vault.",
                e.details,
            )

    @property
    def notion_api_key(self) -> str:
        """
        Get Notion API Key

        Returns key from environment or retrieves from Key Vault.

        Returns:
            str: Notion API key

        Raises:
            AuthenticationError: If key retrieval fails
        """
        if self._notion_api_key:
            return self._notion_api_key

        # Try environment variable first
        if self.settings.notion.api_key:
            logger.info("Using Notion API key from environment variable")
            self._notion_api_key = self.settings.notion.api_key
            return self._notion_api_key

        # Fallback to Key Vault
        try:
            logger.info("Retrieving Notion API key from Azure Key Vault")
            self._notion_api_key = self.kv_client.get_secret("notion-api-key")
            return self._notion_api_key
        except KeyVaultError as e:
            raise AuthenticationError(
                "Notion API key not found in environment or Key Vault. "
                "Set NOTION_API_KEY environment variable or "
                "add 'notion-api-key' to Key Vault.",
                e.details,
            )

    def validate_credentials(self) -> dict[str, bool]:
        """
        Validate all required credentials are available

        Returns:
            dict[str, bool]: Credential availability status

        Example:
            >>> creds = CredentialManager(settings)
            >>> status = creds.validate_credentials()
            >>> print(status)
            {'github': True, 'notion': True}
        """
        status = {}

        try:
            _ = self.github_token
            status["github"] = True
        except AuthenticationError:
            status["github"] = False

        try:
            _ = self.notion_api_key
            status["notion"] = True
        except AuthenticationError:
            status["notion"] = False

        return status
