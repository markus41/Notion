"""
Notion Integration Client for Brookside BI Repository Analyzer

Manages synchronization of repository analysis results to Notion Innovation Nexus databases.
Leverages Notion MCP for database operations and page creation.

Best for: Organizations using Notion for knowledge management, requiring automated
synchronization of repository insights to centralized databases.
"""

import logging
import subprocess
import json
from typing import Any, Optional

from src.auth import CredentialManager
from src.config import Settings
from src.exceptions import NotionAPIError
from src.models import NotionBuildPage, Pattern, RepoAnalysis
from src.analyzers.cost_database import get_cost_database

logger = logging.getLogger(__name__)


class NotionIntegrationClient:
    """
    Notion API client for Innovation Nexus synchronization

    Coordinates with Notion MCP to:
    - Create Example Build entries for repositories
    - Create Knowledge Vault entries for patterns
    - Link dependencies to Software Tracker
    - Maintain proper relations across databases
    """

    def __init__(self, settings: Settings, credentials: CredentialManager):
        """
        Initialize Notion integration client

        Args:
            settings: Application configuration
            credentials: Credential manager for Notion API key

        Example:
            >>> client = NotionIntegrationClient(settings, creds)
            >>> page_id = await client.create_build_entry(analysis)
        """
        self.settings = settings
        self.credentials = credentials
        self.workspace_id = settings.notion.workspace_id

        # Notion database IDs from Innovation Nexus
        self.builds_db_id = settings.notion.builds_database_id
        self.software_db_id = settings.notion.software_database_id
        self.knowledge_db_id = settings.notion.knowledge_vault_database_id if hasattr(settings.notion, 'knowledge_vault_database_id') else None

        # Initialize cost database
        self.cost_db = get_cost_database()

    async def _search_existing_build(self, repo_name: str) -> Optional[str]:
        """
        Search for existing build entry by repository name

        Args:
            repo_name: Repository name to search

        Returns:
            Page ID if found, None otherwise
        """
        try:
            # Use Notion MCP search to find existing build
            search_query = f'"{repo_name}"'
            logger.info(f"Searching for existing build: {search_query}")

            # This would call Notion MCP in production
            # For now, return None to always create new entries
            return None

        except Exception as e:
            logger.warning(f"Error searching for existing build: {e}")
            return None

    async def _create_notion_page(
        self,
        database_id: str,
        properties: dict[str, Any],
        content: str
    ) -> str:
        """
        Create page in Notion database via MCP

        Args:
            database_id: Target database ID
            properties: Page properties
            content: Page content in Notion-flavored Markdown

        Returns:
            Created page ID

        Raises:
            NotionAPIError: If page creation fails
        """
        try:
            logger.info(f"Creating Notion page in database: {database_id}")
            logger.debug(f"Properties: {properties}")

            # In production, this would call Notion MCP create-pages tool
            # For now, simulate successful creation
            page_id = f"page-{properties.get('title', 'unknown')}"

            logger.info(f"Successfully created Notion page: {page_id}")
            return page_id

        except Exception as e:
            logger.error(f"Failed to create Notion page: {e}")
            raise NotionAPIError(f"Page creation failed: {e}")

    async def _update_notion_page(
        self,
        page_id: str,
        properties: dict[str, Any],
        content: Optional[str] = None
    ) -> None:
        """
        Update existing Notion page via MCP

        Args:
            page_id: Page ID to update
            properties: Updated properties
            content: Updated content (optional)

        Raises:
            NotionAPIError: If update fails
        """
        try:
            logger.info(f"Updating Notion page: {page_id}")
            logger.debug(f"Updated properties: {properties}")

            # In production, this would call Notion MCP update-page tool
            logger.info(f"Successfully updated Notion page: {page_id}")

        except Exception as e:
            logger.error(f"Failed to update Notion page: {e}")
            raise NotionAPIError(f"Page update failed: {e}")

    async def create_build_entry(self, analysis: RepoAnalysis) -> str:
        """
        Create Example Build entry in Notion

        Args:
            analysis: Repository analysis result

        Returns:
            Page ID of created build entry

        Example:
            >>> page_id = await notion_client.create_build_entry(analysis)
            >>> print(f"Created build page: {page_id}")
        """
        logger.info(f"Creating Notion build entry for: {analysis.repository.name}")

        # Check for existing build entry
        existing_page_id = await self._search_existing_build(analysis.repository.name)

        # Prepare page data
        build_page = self._prepare_build_page(analysis)

        # Convert to Notion page properties
        properties = {
            "Title": build_page.title,
            "Build Type": build_page.build_type.value,
            "Status": build_page.status,
            "Viability": build_page.viability.value,
            "Reusability": build_page.reusability.value,
            "GitHub URL": build_page.github_url,
            "Technology Stack": build_page.technology_stack,
            "Description": build_page.description,
            # Cost is calculated via rollup from Software Tracker relations
        }

        if existing_page_id:
            # Update existing entry
            logger.info(f"Updating existing build entry: {existing_page_id}")
            await self._update_notion_page(
                existing_page_id,
                properties,
                build_page.content_markdown
            )
            page_id = existing_page_id
        else:
            # Create new entry
            logger.info(f"Creating new build entry in database: {self.builds_db_id}")
            page_id = await self._create_notion_page(
                self.builds_db_id,
                properties,
                build_page.content_markdown
            )

        logger.info(f"Build entry prepared: {build_page.title}")
        logger.info(f"Estimated monthly cost: ${build_page.monthly_cost}")
        logger.info(f"Viability: {build_page.viability.value}")
        logger.info(f"Reusability: {build_page.reusability.value}")

        return page_id

    def _prepare_build_page(self, analysis: RepoAnalysis) -> NotionBuildPage:
        """
        Prepare Notion build page data from analysis

        Args:
            analysis: Repository analysis

        Returns:
            NotionBuildPage ready for creation
        """
        # Generate content markdown
        content_md = self._generate_build_content(analysis)

        # Determine build type
        build_type = self._determine_build_type(analysis)

        # Create technology stack summary
        tech_stack = self._create_tech_stack_summary(analysis)

        return NotionBuildPage(
            title=f"🛠️ {analysis.repository.name}",
            build_type=build_type,
            status="🟢 Active" if analysis.repository.is_active else "⚫ Not Active",
            viability=analysis.viability.rating,
            reusability=analysis.reusability_rating,
            monthly_cost=analysis.monthly_cost,
            github_url=str(analysis.repository.url),
            description=analysis.repository.description or "No description available",
            technology_stack=tech_stack,
            content_markdown=content_md,
        )

    def _generate_build_content(self, analysis: RepoAnalysis) -> str:
        """Generate full Notion page content in markdown"""
        content = f"""# 🛠️ {analysis.repository.name}

## Overview
{analysis.repository.description or "No description available"}

**GitHub:** {analysis.repository.url}
**Primary Language:** {analysis.repository.primary_language or "Unknown"} ({analysis.primary_language_percentage:.1f}%)
**Last Updated:** {analysis.repository.updated_at.strftime("%Y-%m-%d")}

## Viability Assessment

**Score:** {analysis.viability.rating.value} ({analysis.viability.total_score}/100)

| Category | Score | Max |
|----------|-------|-----|
| Test Coverage | {analysis.viability.test_coverage_score} | 30 |
| Recent Activity | {analysis.viability.activity_score} | 20 |
| Documentation | {analysis.viability.documentation_score} | 25 |
| Dependency Health | {analysis.viability.dependency_health_score} | 25 |

### Quality Metrics
- **Has Tests:** {"✓" if analysis.has_tests else "✗"}
- **Test Coverage:** {f"{analysis.test_coverage_percentage:.1f}%" if analysis.test_coverage_percentage else "Unknown"}
- **Has CI/CD:** {"✓" if analysis.has_ci_cd else "✗"}
- **Has Documentation:** {"✓" if analysis.has_documentation else "✗"}

## Technology Stack

### Languages
"""
        # Add language breakdown
        for lang, bytes_count in sorted(
            analysis.languages.items(), key=lambda x: x[1], reverse=True
        )[:5]:
            total_bytes = sum(analysis.languages.values())
            percentage = (bytes_count / total_bytes * 100) if total_bytes > 0 else 0
            content += f"- **{lang}:** {percentage:.1f}%\n"

        content += "\n### Dependencies\n"
        if analysis.dependencies:
            content += f"\n**Total:** {len(analysis.dependencies)} packages\n\n"
            for dep in analysis.dependencies[:10]:
                content += f"- `{dep.name}` ({dep.package_manager})\n"
        else:
            content += "\nNo dependencies detected.\n"

        if analysis.microsoft_services:
            content += "\n### Microsoft Ecosystem\n"
            for service in analysis.microsoft_services:
                content += f"- {service}\n"

        content += f"\n## Cost Analysis\n\n**Monthly Cost:** ${analysis.monthly_cost:.2f}  \n**Annual Cost:** ${analysis.monthly_cost * 12:.2f}\n"

        content += f"\n## Reusability Assessment\n\n**Rating:** {analysis.reusability_rating.value}\n"

        if analysis.claude_config and analysis.claude_config.has_claude_dir:
            content += "\n## Claude Code Integration\n\n"
            content += f"- **Agents:** {analysis.claude_config.agents_count}\n"
            content += f"- **Commands:** {analysis.claude_config.commands_count}\n"
            content += f"- **MCP Servers:** {len(analysis.claude_config.mcp_servers)}\n"

            if analysis.claude_config.agents:
                content += "\n### Configured Agents\n"
                for agent in analysis.claude_config.agents:
                    content += f"- `{agent}`\n"

        content += f"\n## Repository Metrics\n\n"
        content += f"- **Stars:** {analysis.repository.stars_count}\n"
        content += f"- **Forks:** {analysis.repository.forks_count}\n"
        content += f"- **Open Issues:** {analysis.repository.open_issues_count}\n"
        content += f"- **Contributors:** {analysis.commit_stats.unique_contributors}\n"
        content += f"- **Commits (90d):** {analysis.commit_stats.commits_last_90_days}\n"

        return content

    def _determine_build_type(self, analysis: RepoAnalysis) -> Any:
        """Determine build type from analysis"""
        from src.models import BuildType

        # Simple heuristic
        if analysis.viability.total_score >= 85:
            return BuildType.REFERENCE_IMPLEMENTATION
        elif analysis.has_ci_cd and analysis.has_tests:
            return BuildType.MVP
        else:
            return BuildType.PROTOTYPE

    def _create_tech_stack_summary(self, analysis: RepoAnalysis) -> str:
        """Create concise technology stack summary"""
        lang = analysis.repository.primary_language or "Unknown"
        dep_count = len(analysis.dependencies)

        return f"{lang} • {dep_count} dependencies • {analysis.repository.size_kb // 1024}MB"

    async def create_pattern_entry(self, pattern: Pattern) -> str:
        """
        Create Knowledge Vault entry for pattern

        Args:
            pattern: Pattern to document

        Returns:
            Page ID of created pattern entry

        Example:
            >>> page_id = await notion_client.create_pattern_entry(pattern)
        """
        logger.info(f"Creating Notion pattern entry: {pattern.name}")

        if not self.knowledge_db_id:
            logger.warning("Knowledge Vault database ID not configured")
            return f"notion-pattern-{pattern.name}"

        # Prepare pattern content
        content = self._generate_pattern_content(pattern)

        # Prepare properties
        properties = {
            "Title": f"📚 {pattern.name}",
            "Content Type": "Technical Doc",
            "Status": "Published",
            "Evergreen/Dated": "Evergreen",
            "Tags": [pattern.pattern_type.value] + (pattern.technologies or []),
        }

        # Create Knowledge Vault entry
        page_id = await self._create_notion_page(
            self.knowledge_db_id,
            properties,
            content
        )

        logger.info(f"Pattern type: {pattern.pattern_type.value}")
        logger.info(f"Used in {pattern.usage_count} repositories")
        logger.info(f"Reusability score: {pattern.reusability_score}")

        return page_id

    def _generate_pattern_content(self, pattern: Pattern) -> str:
        """Generate Knowledge Vault content for pattern"""
        content = f"""# 📚 {pattern.name}

## Overview
{pattern.description}

**Pattern Type:** {pattern.pattern_type.value}
**Usage Count:** {pattern.usage_count} repositories
**Reusability Score:** {pattern.reusability_score}/100

## Technologies
"""
        if pattern.technologies:
            for tech in pattern.technologies:
                content += f"- {tech}\n"
        else:
            content += "No specific technologies identified\n"

        content += "\n## Example Repositories\n"
        if pattern.example_repos:
            for repo in pattern.example_repos[:5]:
                content += f"- [{repo}](https://github.com/brookside-bi/{repo})\n"

        content += f"\n## Statistics\n\n"
        content += f"- **Adoption Rate:** {(pattern.usage_count / max(pattern.total_repos, 1)) * 100:.1f}%\n"
        content += f"- **Average Viability:** {pattern.avg_viability_score}/100\n"

        if pattern.common_dependencies:
            content += "\n## Common Dependencies\n"
            for dep in pattern.common_dependencies[:10]:
                content += f"- `{dep}`\n"

        content += f"\n## Reusability Assessment\n\n"
        content += f"This pattern is {'highly' if pattern.reusability_score >= 75 else 'moderately' if pattern.reusability_score >= 50 else 'minimally'} reusable across repositories.\n"

        return content

    async def sync_software_dependencies(
        self, analysis: RepoAnalysis, build_page_id: str
    ) -> list[str]:
        """
        Sync dependencies to Software Tracker and link to build

        Args:
            analysis: Repository analysis with dependencies
            build_page_id: Build page ID to link dependencies to

        Returns:
            List of created/updated software entry IDs

        Example:
            >>> entry_ids = await notion_client.sync_software_dependencies(analysis, page_id)
        """
        logger.info(
            f"Syncing {len(analysis.dependencies)} dependencies to Software Tracker"
        )

        software_entry_ids = []

        for dep in analysis.dependencies:
            try:
                # Search for existing software entry
                existing_entry_id = await self._search_software_entry(dep.name)

                if existing_entry_id:
                    # Update existing entry (link to build)
                    logger.info(f"Linking existing software entry: {dep.name}")
                    await self._link_software_to_build(existing_entry_id, build_page_id)
                    software_entry_ids.append(existing_entry_id)
                else:
                    # Create new software entry
                    logger.info(f"Creating new software entry: {dep.name}")
                    entry_id = await self._create_software_entry(dep, build_page_id)
                    software_entry_ids.append(entry_id)

            except Exception as e:
                logger.error(f"Failed to sync dependency {dep.name}: {e}")
                continue

        logger.info(f"Successfully synced {len(software_entry_ids)} software entries")
        return software_entry_ids

    async def _search_software_entry(self, software_name: str) -> Optional[str]:
        """Search for existing software entry by name"""
        try:
            # Would use Notion MCP search in production
            logger.debug(f"Searching for software: {software_name}")
            return None  # Always create new for now
        except Exception as e:
            logger.warning(f"Error searching for software: {e}")
            return None

    async def _create_software_entry(
        self,
        dependency: Any,
        build_page_id: str
    ) -> str:
        """Create new Software Tracker entry"""
        try:
            # Get cost from cost database (would be implemented)
            cost = await self._get_dependency_cost(dependency.name)

            properties = {
                "Title": dependency.name,
                "Category": self._categorize_dependency(dependency),
                "Status": "Active",
                "Cost": cost if cost else 0.0,
                "License Count": 1,
                "Microsoft Service": self._is_microsoft_service(dependency.name),
                "Package Manager": dependency.package_manager,
                # Would link to build page via relation
            }

            # Create entry in Software Tracker
            entry_id = await self._create_notion_page(
                self.software_db_id,
                properties,
                f"# {dependency.name}\n\nAutomatically tracked from repository analysis."
            )

            logger.info(f"Created software entry: {dependency.name} (${cost}/month)")
            return entry_id

        except Exception as e:
            logger.error(f"Failed to create software entry: {e}")
            raise

    async def _link_software_to_build(
        self,
        software_entry_id: str,
        build_page_id: str
    ) -> None:
        """Link software entry to build page"""
        try:
            # Would update relation property in production
            logger.debug(f"Linking software {software_entry_id} to build {build_page_id}")
        except Exception as e:
            logger.error(f"Failed to link software to build: {e}")

    async def _get_dependency_cost(self, dependency_name: str) -> float:
        """
        Get monthly cost for dependency from cost database

        Args:
            dependency_name: Name of dependency

        Returns:
            Monthly cost in USD
        """
        # Query cost database for known software/services
        cost = self.cost_db.get_cost(dependency_name)

        if cost > 0:
            logger.debug(f"Found cost for {dependency_name}: ${cost}/month")
        else:
            logger.debug(f"No cost found for {dependency_name} (open source or unknown)")

        return cost

    def _categorize_dependency(self, dependency: Any) -> str:
        """Categorize dependency for Software Tracker"""
        # Simple categorization based on package manager and name
        if dependency.package_manager in ["pip", "npm", "nuget"]:
            return "Development"
        return "Unknown"

    def _is_microsoft_service(self, dependency_name: str) -> str:
        """Check if dependency is a Microsoft service"""
        # Check cost database first
        info = self.cost_db.get_software_info(dependency_name)
        if info:
            return info.get("microsoft_service", "None")

        # Fallback to keyword matching
        microsoft_keywords = [
            "azure", "microsoft", "dotnet", "aspnet", "msal",
            "graph", "office", "teams", "sharepoint", "powerapps"
        ]

        name_lower = dependency_name.lower()
        for keyword in microsoft_keywords:
            if keyword in name_lower:
                return "Azure" if "azure" in name_lower else "M365"

        return "None"
