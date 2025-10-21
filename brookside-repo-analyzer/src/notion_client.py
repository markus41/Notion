"""
Notion Integration Client for Brookside BI Repository Analyzer

Manages synchronization of repository analysis results to Notion Innovation Nexus databases.
Leverages Notion MCP for database operations and page creation.

Best for: Organizations using Notion for knowledge management, requiring automated
synchronization of repository insights to centralized databases.
"""

import logging
from typing import Any

from src.auth import CredentialManager
from src.config import Settings
from src.exceptions import NotionAPIError
from src.models import NotionBuildPage, Pattern, RepoAnalysis

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

        # Note: In production, this would use the Notion MCP via Claude Code
        # For now, we'll create a placeholder structure

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

        # Prepare page data
        build_page = self._prepare_build_page(analysis)

        # In production, this would call Notion MCP to create the page
        # For now, we'll log the operation and return a placeholder ID

        logger.info(f"Build entry prepared: {build_page.title}")
        logger.info(f"Monthly cost: ${build_page.monthly_cost}")
        logger.info(f"Viability: {build_page.viability.value}")
        logger.info(f"Reusability: {build_page.reusability.value}")

        # Placeholder: Would return actual Notion page ID from MCP
        return f"notion-page-{analysis.repository.name}"

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

        # In production, would use Notion MCP
        logger.info(f"Pattern type: {pattern.pattern_type.value}")
        logger.info(f"Used in {pattern.usage_count} repositories")

        return f"notion-pattern-{pattern.name}"

    async def sync_software_dependencies(
        self, analysis: RepoAnalysis
    ) -> list[str]:
        """
        Sync dependencies to Software Tracker

        Args:
            analysis: Repository analysis with dependencies

        Returns:
            List of created/updated software entry IDs

        Example:
            >>> entry_ids = await notion_client.sync_software_dependencies(analysis)
        """
        logger.info(
            f"Syncing {len(analysis.dependencies)} dependencies to Software Tracker"
        )

        # In production, would check existing entries and create/update as needed
        return [f"software-{dep.name}" for dep in analysis.dependencies]
