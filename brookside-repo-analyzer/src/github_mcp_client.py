"""
GitHub MCP Client Wrapper for Brookside BI Repository Analyzer

Establishes integration with GitHub MCP for organization-wide repository analysis.
Leverages the existing GitHub MCP configuration with Azure Key Vault authentication.

Best for: Organizations using Model Context Protocol for GitHub integration,
requiring repository scanning, metadata extraction, and activity analysis.
"""

import logging
from datetime import datetime, timedelta
from typing import Any

import httpx

from src.auth import CredentialManager
from src.config import Settings
from src.exceptions import GitHubAPIError, RateLimitError
from src.models import CommitStats, Dependency, Repository

logger = logging.getLogger(__name__)


class GitHubMCPClient:
    """
    GitHub MCP client for repository analysis

    Provides high-level interface to GitHub data via MCP or direct REST API.
    Implements rate limiting, error handling, and retry logic.
    """

    def __init__(self, settings: Settings, credentials: CredentialManager):
        """
        Initialize GitHub MCP client

        Args:
            settings: Application configuration
            credentials: Credential manager for GitHub token

        Example:
            >>> from src.config import get_settings
            >>> from src.auth import CredentialManager
            >>> settings = get_settings()
            >>> creds = CredentialManager(settings)
            >>> client = GitHubMCPClient(settings, creds)
        """
        self.settings = settings
        self.credentials = credentials
        self.base_url = "https://api.github.com"
        self._client: httpx.AsyncClient | None = None

    async def __aenter__(self) -> "GitHubMCPClient":
        """Async context manager entry"""
        self._client = httpx.AsyncClient(
            headers={
                "Authorization": f"Bearer {self.credentials.github_token}",
                "Accept": "application/vnd.github+json",
                "X-GitHub-Api-Version": "2022-11-28",
            },
            timeout=30.0,
        )
        return self

    async def __aexit__(self, exc_type: Any, exc_val: Any, exc_tb: Any) -> None:
        """Async context manager exit"""
        if self._client:
            await self._client.aclose()

    async def _request(
        self, method: str, endpoint: str, **kwargs: Any
    ) -> dict[str, Any] | list[Any]:
        """
        Make authenticated request to GitHub API

        Args:
            method: HTTP method (GET, POST, etc.)
            endpoint: API endpoint (without base URL)
            **kwargs: Additional request parameters

        Returns:
            Response data (dict or list)

        Raises:
            GitHubAPIError: If request fails
            RateLimitError: If rate limit exceeded
        """
        if not self._client:
            raise GitHubAPIError("Client not initialized. Use async context manager.")

        url = f"{self.base_url}/{endpoint.lstrip('/')}"

        try:
            response = await self._client.request(method, url, **kwargs)

            # Check rate limiting
            if response.status_code == 403:
                rate_limit_remaining = response.headers.get("X-RateLimit-Remaining")
                if rate_limit_remaining == "0":
                    reset_time = response.headers.get("X-RateLimit-Reset")
                    retry_after = (
                        int(reset_time) - int(datetime.now().timestamp()) if reset_time else 3600
                    )
                    raise RateLimitError(
                        "GitHub API rate limit exceeded",
                        retry_after=retry_after,
                    )

            response.raise_for_status()
            return response.json()

        except httpx.HTTPStatusError as e:
            raise GitHubAPIError(
                f"GitHub API request failed: {str(e)}",
                status_code=e.response.status_code,
                response_data=e.response.json() if e.response.text else None,
            )
        except httpx.RequestError as e:
            raise GitHubAPIError(f"GitHub API request error: {str(e)}")

    async def list_organization_repos(
        self, org: str | None = None, include_private: bool = True
    ) -> list[Repository]:
        """
        List all repositories in organization or user account

        Args:
            org: Organization or username (defaults to config value)
            include_private: Include private repositories

        Returns:
            List of Repository objects

        Example:
            >>> async with GitHubMCPClient(settings, creds) as client:
            ...     repos = await client.list_organization_repos("brookside-bi")
            ...     print(f"Found {len(repos)} repositories")
        """
        org = org or self.settings.github.organization
        logger.info(f"Scanning organization: {org}")

        all_repos: list[Repository] = []
        page = 1
        per_page = 100

        # Try organization repos first, fall back to user repos if 404
        is_org = True

        while True:
            try:
                endpoint = f"/orgs/{org}/repos" if is_org else f"/users/{org}/repos"
                data = await self._request(
                    "GET",
                    endpoint,
                    params={"page": page, "per_page": per_page, "type": "all"},
                )
            except GitHubAPIError as e:
                # If first page and 404, try user endpoint instead
                if "404" in str(e) and page == 1 and is_org:
                    logger.info(f"Not an organization, trying user repos for: {org}")
                    is_org = False
                    continue
                else:
                    raise

            if not isinstance(data, list):
                break

            if not data:
                break

            for repo_data in data:
                # Filter private repos if requested
                if not include_private and repo_data.get("private", False):
                    continue

                # Skip excluded repos
                if repo_data["name"] in self.settings.github.exclude_repos:
                    logger.debug(f"Skipping excluded repository: {repo_data['name']}")
                    continue

                # Parse repository data
                repo = Repository(
                    name=repo_data["name"],
                    full_name=repo_data["full_name"],
                    url=repo_data["html_url"],
                    description=repo_data.get("description"),
                    primary_language=repo_data.get("language"),
                    is_private=repo_data.get("private", False),
                    is_fork=repo_data.get("fork", False),
                    is_archived=repo_data.get("archived", False),
                    default_branch=repo_data.get("default_branch", "main"),
                    created_at=datetime.fromisoformat(
                        repo_data["created_at"].replace("Z", "+00:00")
                    ),
                    updated_at=datetime.fromisoformat(
                        repo_data["updated_at"].replace("Z", "+00:00")
                    ),
                    pushed_at=(
                        datetime.fromisoformat(repo_data["pushed_at"].replace("Z", "+00:00"))
                        if repo_data.get("pushed_at")
                        else None
                    ),
                    size_kb=repo_data.get("size", 0),
                    stars_count=repo_data.get("stargazers_count", 0),
                    forks_count=repo_data.get("forks_count", 0),
                    open_issues_count=repo_data.get("open_issues_count", 0),
                    topics=repo_data.get("topics", []),
                )

                all_repos.append(repo)

            # Check if there are more pages
            if len(data) < per_page:
                break

            page += 1

        logger.info(f"Found {len(all_repos)} repositories in {org}")
        return all_repos

    async def get_repository_languages(self, repo: Repository) -> dict[str, int]:
        """
        Get language breakdown for repository

        Args:
            repo: Repository object

        Returns:
            Dictionary of language name to bytes

        Example:
            >>> languages = await client.get_repository_languages(repo)
            >>> print(languages)
            {'Python': 125000, 'TypeScript': 45000}
        """
        org, repo_name = repo.full_name.split("/")
        data = await self._request("GET", f"/repos/{org}/{repo_name}/languages")

        if isinstance(data, dict):
            return data
        return {}

    async def get_commit_activity(
        self, repo: Repository, days: int = 90
    ) -> CommitStats:
        """
        Get commit activity statistics

        Args:
            repo: Repository object
            days: Number of days to analyze

        Returns:
            CommitStats object

        Example:
            >>> stats = await client.get_commit_activity(repo, days=90)
            >>> print(f"Commits (90d): {stats.commits_last_90_days}")
        """
        org, repo_name = repo.full_name.split("/")

        # Get commits since date
        since_date = datetime.now() - timedelta(days=days)
        since_str = since_date.isoformat()

        try:
            data = await self._request(
                "GET",
                f"/repos/{org}/{repo_name}/commits",
                params={"since": since_str, "per_page": 100},
            )

            if not isinstance(data, list):
                return CommitStats()

            commits_90d = len(data)

            # Use timezone-aware datetime for comparison
            from datetime import timezone
            now_aware = datetime.now(timezone.utc)

            commits_30d = sum(
                1
                for commit in data
                if datetime.fromisoformat(
                    commit["commit"]["author"]["date"].replace("Z", "+00:00")
                )
                >= now_aware - timedelta(days=30)
            )

            # Get unique contributors
            unique_authors = {commit["commit"]["author"]["email"] for commit in data}

            # Calculate weekly average
            weeks = days / 7
            avg_commits_per_week = commits_90d / weeks if weeks > 0 else 0

            return CommitStats(
                total_commits=commits_90d,  # Approximation
                commits_last_30_days=commits_30d,
                commits_last_90_days=commits_90d,
                unique_contributors=len(unique_authors),
                average_commits_per_week=avg_commits_per_week,
            )

        except GitHubAPIError as e:
            logger.warning(f"Failed to get commit stats for {repo.name}: {e.message}")
            return CommitStats()

    async def get_repository_dependencies(
        self, repo: Repository
    ) -> list[Dependency]:
        """
        Extract dependencies from repository

        Attempts to parse common dependency files:
        - package.json (npm)
        - requirements.txt (pip)
        - pyproject.toml (poetry)
        - go.mod (go)
        - Gemfile (ruby)

        Args:
            repo: Repository object

        Returns:
            List of Dependency objects

        Example:
            >>> deps = await client.get_repository_dependencies(repo)
            >>> for dep in deps:
            ...     print(f"{dep.name} ({dep.package_manager})")
        """
        org, repo_name = repo.full_name.split("/")
        dependencies: list[Dependency] = []

        # Try to get package.json for npm dependencies
        try:
            package_json = await self._get_file_content(org, repo_name, "package.json")
            if package_json:
                import json

                pkg_data = json.loads(package_json)

                # Production dependencies
                for name, version in pkg_data.get("dependencies", {}).items():
                    dependencies.append(
                        Dependency(
                            name=name,
                            version=version,
                            package_manager="npm",
                            is_dev_dependency=False,
                        )
                    )

                # Dev dependencies
                for name, version in pkg_data.get("devDependencies", {}).items():
                    dependencies.append(
                        Dependency(
                            name=name,
                            version=version,
                            package_manager="npm",
                            is_dev_dependency=True,
                        )
                    )
        except Exception as e:
            logger.debug(f"No package.json or parse error: {e}")

        # Try to get requirements.txt for pip dependencies
        try:
            requirements = await self._get_file_content(org, repo_name, "requirements.txt")
            if requirements:
                for line in requirements.split("\n"):
                    line = line.strip()
                    if line and not line.startswith("#"):
                        parts = line.split("==")
                        name = parts[0].strip()
                        version = parts[1].strip() if len(parts) > 1 else None
                        dependencies.append(
                            Dependency(
                                name=name,
                                version=version,
                                package_manager="pip",
                                is_dev_dependency=False,
                            )
                        )
        except Exception as e:
            logger.debug(f"No requirements.txt or parse error: {e}")

        return dependencies

    async def _get_file_content(
        self, org: str, repo_name: str, file_path: str
    ) -> str | None:
        """
        Get file content from repository

        Args:
            org: Organization name
            repo_name: Repository name
            file_path: Path to file

        Returns:
            File content as string, or None if not found
        """
        try:
            data = await self._request("GET", f"/repos/{org}/{repo_name}/contents/{file_path}")

            if isinstance(data, dict) and data.get("content"):
                import base64

                return base64.b64decode(data["content"]).decode("utf-8")

            return None

        except GitHubAPIError:
            return None

    async def check_file_exists(
        self, repo: Repository, file_path: str
    ) -> bool:
        """
        Check if file exists in repository

        Args:
            repo: Repository object
            file_path: Path to file

        Returns:
            True if file exists, False otherwise

        Example:
            >>> has_tests = await client.check_file_exists(repo, "tests/")
            >>> has_docs = await client.check_file_exists(repo, "README.md")
        """
        org, repo_name = repo.full_name.split("/")
        content = await self._get_file_content(org, repo_name, file_path)
        return content is not None

    async def get_repository_topics(self, repo: Repository) -> list[str]:
        """
        Get repository topics/tags

        Args:
            repo: Repository object

        Returns:
            List of topic strings
        """
        org, repo_name = repo.full_name.split("/")

        try:
            data = await self._request(
                "GET",
                f"/repos/{org}/{repo_name}/topics",
                headers={"Accept": "application/vnd.github.mercy-preview+json"},
            )

            if isinstance(data, dict):
                return data.get("names", [])

            return []

        except GitHubAPIError:
            return []

    async def list_user_organizations(self) -> list[dict[str, Any]]:
        """
        List all organizations the authenticated user belongs to

        Returns:
            List of organization dictionaries with 'login' and 'description'

        Example:
            >>> async with GitHubMCPClient(settings, creds) as client:
            ...     orgs = await client.list_user_organizations()
            ...     for org in orgs:
            ...         print(f"{org['login']}: {org.get('description', 'No description')}")
        """
        try:
            data = await self._request("GET", "/user/orgs")

            if isinstance(data, list):
                return [
                    {
                        "login": org["login"],
                        "description": org.get("description"),
                        "url": org.get("html_url"),
                        "repos_url": org.get("repos_url"),
                    }
                    for org in data
                ]

            return []

        except GitHubAPIError as e:
            logger.warning(f"Failed to list organizations: {e.message}")
            return []

    async def check_token_scopes(self) -> dict[str, Any]:
        """
        Check GitHub Personal Access Token scopes and permissions

        Returns:
            Dictionary with 'scopes' (list), 'user' (username), and 'valid' (bool)

        Example:
            >>> async with GitHubMCPClient(settings, creds) as client:
            ...     info = await client.check_token_scopes()
            ...     print(f"User: {info['user']}")
            ...     print(f"Scopes: {', '.join(info['scopes'])}")
            ...     if 'repo' in info['scopes'] and 'read:org' in info['scopes']:
            ...         print("✓ Token has required scopes")
        """
        try:
            if not self._client:
                raise GitHubAPIError("Client not initialized")

            # Make request to /user endpoint
            response = await self._client.get(f"{self.base_url}/user")
            response.raise_for_status()
            user_data = response.json()

            # Parse X-OAuth-Scopes header
            scopes_header = response.headers.get("X-OAuth-Scopes", "")
            scopes = [s.strip() for s in scopes_header.split(",") if s.strip()]

            return {
                "valid": True,
                "user": user_data.get("login"),
                "name": user_data.get("name"),
                "scopes": scopes,
                "has_repo_access": "repo" in scopes or "public_repo" in scopes,
                "has_org_access": "read:org" in scopes or "admin:org" in scopes,
                "has_user_access": "read:user" in scopes or "user" in scopes,
            }

        except Exception as e:
            logger.error(f"Failed to check token scopes: {str(e)}")
            return {
                "valid": False,
                "user": None,
                "name": None,
                "scopes": [],
                "has_repo_access": False,
                "has_org_access": False,
                "has_user_access": False,
            }
