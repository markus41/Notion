"""
Claude Capabilities Detector for Brookside BI Repository Analyzer

Analyzes .claude/ directory structure to extract agent configurations, slash commands,
and MCP server setups to understand Claude Code integration capabilities.

Best for: Organizations using Claude Code across repositories, requiring visibility
into configured agents, custom commands, and automation workflows.
"""

import json
import logging
from pathlib import Path

from src.github_mcp_client import GitHubMCPClient
from src.models import ClaudeConfig, Repository

logger = logging.getLogger(__name__)


class ClaudeCapabilitiesDetector:
    """
    Detector for Claude Code configurations

    Parses .claude/ directory to extract:
    - Agent definitions (.claude/agents/*.md)
    - Slash commands (.claude/commands/*.md)
    - MCP server configurations (.claude.json)
    - Project memory (CLAUDE.md)
    """

    def __init__(self, github_client: GitHubMCPClient):
        """
        Initialize Claude capabilities detector

        Args:
            github_client: GitHub MCP client for file access

        Example:
            >>> detector = ClaudeCapabilitiesDetector(github_client)
            >>> config = await detector.detect_claude_capabilities(repo)
            >>> print(f"Found {config.agents_count} agents")
        """
        self.github_client = github_client

    async def detect_claude_capabilities(self, repo: Repository) -> ClaudeConfig:
        """
        Detect and parse Claude Code configuration

        Args:
            repo: Repository to analyze

        Returns:
            ClaudeConfig object with all detected capabilities

        Example:
            >>> config = await detector.detect_claude_capabilities(repo)
            >>> if config.has_claude_dir:
            ...     print(f"Agents: {', '.join(config.agents)}")
            ...     print(f"Commands: {', '.join(config.commands)}")
            ...     print(f"MCPs: {', '.join(config.mcp_servers)}")
        """
        logger.info(f"Detecting Claude configuration for: {repo.name}")

        config = ClaudeConfig()

        # Check if .claude/ directory exists
        org, repo_name = repo.full_name.split("/")

        # Try to get .claude.json (MCP and project-level config)
        claude_json_content = await self.github_client._get_file_content(
            org, repo_name, ".claude.json"
        )

        if claude_json_content:
            config.has_claude_dir = True
            mcp_servers = self._parse_claude_json(claude_json_content)
            config.mcp_servers = mcp_servers

        # Check for CLAUDE.md
        claude_md_content = await self.github_client._get_file_content(
            org, repo_name, "CLAUDE.md"
        )
        if claude_md_content:
            config.has_claude_md = True

        # Try to detect agents directory
        # Note: GitHub API doesn't allow directory listing easily,
        # so we'll use a heuristic approach

        # Try common agent file patterns
        potential_agents = [
            "build-architect",
            "cost-analyst",
            "github-repo-analyst",
            "ideas-capture",
            "integration-specialist",
            "knowledge-curator",
            "markdown-expert",
            "notion-mcp-specialist",
            "research-coordinator",
            "schema-manager",
            "viability-assessor",
            "workflow-router",
            "archive-manager",
            "mermaid-diagram-expert",
        ]

        detected_agents = []
        for agent_name in potential_agents:
            agent_file = f".claude/agents/{agent_name}.md"
            content = await self.github_client._get_file_content(org, repo_name, agent_file)
            if content:
                detected_agents.append(agent_name)

        config.agents = detected_agents
        config.agents_count = len(detected_agents)

        # Try common command patterns
        potential_commands = [
            "cost-analyze",
            "innovation-new-idea",
            "innovation-start-research",
            "knowledge-archive",
            "team-assign",
        ]

        detected_commands = []
        for cmd_name in potential_commands:
            cmd_file = f".claude/commands/{cmd_name}.md"
            content = await self.github_client._get_file_content(org, repo_name, cmd_file)
            if content:
                detected_commands.append(cmd_name)

        config.commands = detected_commands
        config.commands_count = len(detected_commands)

        logger.info(
            f"Claude detection complete for {repo.name}: "
            f"{config.agents_count} agents, "
            f"{config.commands_count} commands, "
            f"{len(config.mcp_servers)} MCP servers"
        )

        return config

    def _parse_claude_json(self, content: str) -> list[str]:
        """
        Parse .claude.json to extract MCP server names

        Args:
            content: Raw .claude.json content

        Returns:
            List of MCP server names

        Example:
            >>> servers = detector._parse_claude_json(json_content)
            >>> print(servers)  # ['notion', 'github', 'azure']
        """
        try:
            data = json.loads(content)

            # Extract MCP servers from various locations
            mcp_servers: set[str] = set()

            # Check for project-specific MCP servers
            if isinstance(data, dict):
                # Handle different .claude.json formats
                for key in data.keys():
                    if "mcpServers" in key.lower():
                        servers_data = data[key]
                        if isinstance(servers_data, dict):
                            mcp_servers.update(servers_data.keys())

                # Also check direct mcpServers key
                if "mcpServers" in data:
                    servers = data["mcpServers"]
                    if isinstance(servers, dict):
                        mcp_servers.update(servers.keys())

            return sorted(list(mcp_servers))

        except json.JSONDecodeError as e:
            logger.warning(f"Failed to parse .claude.json: {e}")
            return []

    async def get_agent_details(
        self, repo: Repository, agent_name: str
    ) -> dict[str, str] | None:
        """
        Get detailed information about a specific agent

        Args:
            repo: Repository containing the agent
            agent_name: Name of the agent

        Returns:
            Dictionary with agent metadata or None if not found

        Example:
            >>> details = await detector.get_agent_details(repo, "cost-analyst")
            >>> print(details["description"])
        """
        org, repo_name = repo.full_name.split("/")
        agent_file = f".claude/agents/{agent_name}.md"

        content = await self.github_client._get_file_content(org, repo_name, agent_file)

        if not content:
            return None

        # Parse markdown frontmatter for agent metadata
        metadata = self._parse_agent_frontmatter(content)

        return metadata

    def _parse_agent_frontmatter(self, content: str) -> dict[str, str]:
        """
        Parse agent markdown frontmatter

        Args:
            content: Raw markdown content

        Returns:
            Dictionary of metadata

        Example:
            >>> metadata = detector._parse_agent_frontmatter(md_content)
            >>> print(metadata["name"])
            'cost-analyst'
        """
        metadata: dict[str, str] = {}

        # Simple frontmatter parser (assumes --- delimiters)
        if content.startswith("---"):
            parts = content.split("---", 2)
            if len(parts) >= 2:
                frontmatter = parts[1].strip()

                for line in frontmatter.split("\n"):
                    if ":" in line:
                        key, value = line.split(":", 1)
                        metadata[key.strip()] = value.strip()

        return metadata

    async def analyze_claude_maturity(self, config: ClaudeConfig) -> dict[str, any]:
        """
        Assess Claude Code integration maturity level

        Args:
            config: ClaudeConfig object

        Returns:
            Dictionary with maturity assessment

        Maturity Levels:
        - None: No .claude/ directory
        - Basic: Has CLAUDE.md but no agents/commands
        - Intermediate: Has agents or commands
        - Advanced: Has agents, commands, and MCP servers
        - Expert: Full integration with 5+ agents and custom MCPs

        Example:
            >>> maturity = await detector.analyze_claude_maturity(config)
            >>> print(maturity["level"])  # "Advanced"
            >>> print(maturity["score"])  # 75
        """
        if not config.has_claude_dir and not config.has_claude_md:
            return {
                "level": "None",
                "score": 0,
                "description": "No Claude Code integration detected",
            }

        score = 0

        # CLAUDE.md: 10 points
        if config.has_claude_md:
            score += 10

        # .claude/ directory: 10 points
        if config.has_claude_dir:
            score += 10

        # Agents: 5 points each (max 30)
        score += min(config.agents_count * 5, 30)

        # Commands: 3 points each (max 20)
        score += min(config.commands_count * 3, 20)

        # MCP servers: 10 points each (max 30)
        score += min(len(config.mcp_servers) * 10, 30)

        # Determine level
        if score >= 80:
            level = "Expert"
            description = "Comprehensive Claude Code integration with extensive automation"
        elif score >= 60:
            level = "Advanced"
            description = "Well-integrated with agents, commands, and MCP servers"
        elif score >= 30:
            level = "Intermediate"
            description = "Basic integration with some agents or commands"
        elif score >= 10:
            level = "Basic"
            description = "Minimal integration with CLAUDE.md documentation"
        else:
            level = "None"
            description = "No Claude Code integration"

        return {
            "level": level,
            "score": score,
            "description": description,
            "breakdown": {
                "has_claude_md": config.has_claude_md,
                "agents_count": config.agents_count,
                "commands_count": config.commands_count,
                "mcp_servers_count": len(config.mcp_servers),
            },
        }
