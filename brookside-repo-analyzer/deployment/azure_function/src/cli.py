"""
CLI Interface for Brookside BI Repository Analyzer

Provides command-line interface for repository scanning, analysis, and Notion synchronization.
Uses Click for command structure and Rich for beautiful terminal output.

Best for: Organizations requiring flexible, scriptable repository analysis with
manual or automated execution via CLI.
"""

import asyncio
import logging
import sys
from pathlib import Path

import click
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.table import Table

from src.analyzers.claude_detector import ClaudeCapabilitiesDetector
from src.analyzers.cost_calculator import CostCalculator
from src.analyzers.pattern_miner import PatternMiner
from src.analyzers.repo_analyzer import RepositoryAnalyzer
from src.auth import CredentialManager
from src.config import get_settings
from src.github_mcp_client import GitHubMCPClient
from src.notion_client import NotionIntegrationClient

# Establish Windows-compatible console output to avoid encoding errors
console = Console(legacy_windows=False, no_color=False, force_terminal=True)
logger = logging.getLogger(__name__)


def setup_logging(level: str = "INFO") -> None:
    """Configure logging for CLI"""
    logging.basicConfig(
        level=getattr(logging, level.upper()),
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    )


@click.group()
@click.option(
    "--log-level",
    type=click.Choice(["DEBUG", "INFO", "WARNING", "ERROR"], case_sensitive=False),
    default="INFO",
    help="Set logging level",
)
@click.version_option(version="0.1.0")
def cli(log_level: str) -> None:
    """
    Brookside BI Repository Analyzer

    Analyzes GitHub repositories and syncs insights to Notion Innovation Nexus.

    Examples:

      brookside-analyze scan --full
      brookside-analyze repo my-repo --deep
      brookside-analyze patterns
      brookside-analyze costs
    """
    setup_logging(log_level)


@cli.command()
@click.option(
    "--org",
    default=None,
    help="GitHub organization (defaults to brookside-bi)",
)
@click.option(
    "--all-orgs/--single-org",
    default=False,
    help="Scan all organizations user has access to",
)
@click.option(
    "--full/--quick",
    default=False,
    help="Full deep analysis or quick scan",
)
@click.option(
    "--sync/--no-sync",
    default=True,
    help="Sync results to Notion",
)
def scan(org: str | None, all_orgs: bool, full: bool, sync: bool) -> None:
    """
    Scan entire GitHub organization

    Analyzes all repositories in the organization and optionally syncs to Notion.

    Examples:
      brookside-analyze scan --full --sync
      brookside-analyze scan --org my-org --full
      brookside-analyze scan --all-orgs --full
    """
    asyncio.run(_scan_organization(org, all_orgs, full, sync))


async def _scan_organization(org: str | None, all_orgs: bool, full: bool, sync: bool) -> None:
    """Async implementation of organization scan"""
    console.print("\n[bold blue]Brookside BI Repository Analyzer[/bold blue]")
    console.print("[dim]Scanning GitHub organization...[/dim]\n")

    try:
        # Initialize
        settings = get_settings()
        credentials = CredentialManager(settings)

        # Validate credentials
        console.print("[yellow]Validating credentials...[/yellow]")
        cred_status = credentials.validate_credentials()

        if not cred_status["github"]:
            console.print("[bold red]ERROR[/bold red] GitHub credentials not found")
            sys.exit(1)

        console.print("[green]OK[/green] GitHub credentials validated")

        if sync and not cred_status["notion"]:
            console.print("[yellow]WARN[/yellow] Notion credentials not found (--sync disabled)")
            sync = False

        # Scan organization(s)
        async with GitHubMCPClient(settings, credentials) as github_client:
            # Determine which organizations to scan
            orgs_to_scan = []

            if all_orgs:
                # Discover all organizations
                console.print("\n[yellow]Discovering organizations...[/yellow]")
                discovered_orgs = await github_client.list_user_organizations()

                if not discovered_orgs:
                    console.print("[yellow]No organizations found, scanning personal repos[/yellow]")
                    token_info = await github_client.check_token_scopes()
                    orgs_to_scan = [token_info.get("user")]
                else:
                    orgs_to_scan = [org_data["login"] for org_data in discovered_orgs]
                    console.print(f"[green]Found {len(orgs_to_scan)} organizations[/green]")
            else:
                # Single organization scan
                orgs_to_scan = [org or settings.github.organization]

            # Aggregate all repositories across organizations
            all_repos = []

            for idx, org_name in enumerate(orgs_to_scan, 1):
                if len(orgs_to_scan) > 1:
                    console.print(f"\n[yellow]Scanning organization {idx}/{len(orgs_to_scan)}: {org_name}[/yellow]")
                else:
                    console.print(f"\n[yellow]Scanning organization: {org_name}[/yellow]")

                repos = await github_client.list_organization_repos(org_name)
                all_repos.extend(repos)
                console.print(f"[green]Found {len(repos)} repositories in {org_name}[/green]")

            console.print(f"\n[bold green]Total repositories to analyze: {len(all_repos)}[/bold green]\n")

            # Analyze repositories
            analyzer = RepositoryAnalyzer(github_client)
            claude_detector = ClaudeCapabilitiesDetector(github_client)

            analyses = []

            # Analyze repositories without spinner to avoid Windows encoding issues
            console.print(f"\n[yellow]Analyzing {len(all_repos)} repositories...[/yellow]")

            for idx, repo in enumerate(all_repos, 1):
                console.print(f"  [{idx}/{len(all_repos)}] {repo.name}...")

                # Analyze repository
                analysis = await analyzer.analyze_repository(repo, deep_analysis=full)

                # Detect Claude capabilities if requested
                if settings.analysis.detect_claude_configs:
                    analysis.claude_config = await claude_detector.detect_claude_capabilities(
                        repo
                    )

                analyses.append(analysis)

            # Display results
            console.print("\n[bold green]Analysis Complete![/bold green]\n")

            _display_summary_table(analyses)

            # Pattern mining
            if full:
                console.print("\n[yellow]Extracting patterns...[/yellow]")
                miner = PatternMiner()
                patterns = miner.extract_patterns(analyses)
                console.print(f"[green]Identified {len(patterns)} patterns[/green]\n")

            # Cost analysis
            console.print("[yellow]Calculating costs...[/yellow]")
            calculator = CostCalculator()
            cost_stats = calculator.calculate_aggregate_costs(analyses)
            _display_cost_summary(cost_stats)

            # Sync to Notion
            if sync:
                console.print("\n[yellow]Syncing to Notion...[/yellow]")
                notion_client = NotionIntegrationClient(settings, credentials)

                for analysis in analyses:
                    await notion_client.create_build_entry(analysis)

                console.print("[green]OK[/green] Synced to Notion Innovation Nexus")

    except Exception as e:
        console.print(f"\n[bold red]Error:[/bold red] {str(e)}")
        logger.exception("Scan failed")
        sys.exit(1)


@cli.command()
@click.argument("repo_name")
@click.option(
    "--deep/--shallow",
    default=False,
    help="Deep analysis with full metrics",
)
def analyze(repo_name: str, deep: bool) -> None:
    """
    Analyze single repository

    Example:
      brookside-analyze repo my-repo --deep
    """
    asyncio.run(_analyze_single_repo(repo_name, deep))


async def _analyze_single_repo(repo_name: str, deep: bool) -> None:
    """Async implementation of single repo analysis"""
    console.print(f"\n[bold blue]Analyzing: {repo_name}[/bold blue]\n")

    try:
        settings = get_settings()
        credentials = CredentialManager(settings)

        async with GitHubMCPClient(settings, credentials) as github_client:
            # Get organization repos
            repos = await github_client.list_organization_repos()

            # Find target repo
            target_repo = next((r for r in repos if r.name == repo_name), None)

            if not target_repo:
                console.print(f"[red]Repository '{repo_name}' not found[/red]")
                sys.exit(1)

            # Analyze
            analyzer = RepositoryAnalyzer(github_client)
            analysis = await analyzer.analyze_repository(target_repo, deep_analysis=deep)

            # Display detailed results
            _display_repo_analysis(analysis)

    except Exception as e:
        console.print(f"\n[bold red]Error:[/bold red] {str(e)}")
        sys.exit(1)


@cli.command()
def organizations() -> None:
    """
    List all GitHub organizations the user belongs to

    Shows organizations with repository counts and access information.
    Useful for discovering which orgs to scan with --all-orgs flag.

    Example:
      brookside-analyze organizations
    """
    asyncio.run(_list_organizations())


async def _list_organizations() -> None:
    """Async implementation of organization listing"""
    console.print("\n[bold blue]GitHub Organizations[/bold blue]\n")

    try:
        settings = get_settings()
        credentials = CredentialManager(settings)

        async with GitHubMCPClient(settings, credentials) as github_client:
            # Check token scopes
            console.print("[yellow]Checking token permissions...[/yellow]")
            token_info = await github_client.check_token_scopes()

            if not token_info["valid"]:
                console.print("[bold red]ERROR[/bold red] Invalid GitHub token")
                sys.exit(1)

            console.print(f"[green]OK[/green] Authenticated as: {token_info['user']}")
            console.print(f"[dim]Scopes: {', '.join(token_info['scopes'])}[/dim]\n")

            # Warn if missing required scopes
            if not token_info["has_org_access"]:
                console.print("[yellow]WARNING[/yellow] Token missing 'read:org' scope")
                console.print("[dim]Organization repositories may not be accessible[/dim]\n")

            # List organizations
            console.print("[yellow]Discovering organizations...[/yellow]")
            orgs = await github_client.list_user_organizations()

            if not orgs:
                console.print("[yellow]No organizations found[/yellow]")
                console.print(f"[dim]Scanning personal repos for: {token_info['user']}[/dim]\n")
                return

            # Display organizations table
            table = Table(title=f"Organizations for {token_info['user']}")
            table.add_column("Organization", style="cyan")
            table.add_column("Description", style="white")
            table.add_column("URL", style="blue", no_wrap=True)

            for org in orgs:
                table.add_row(
                    org["login"],
                    org.get("description") or "[dim]No description[/dim]",
                    org.get("url") or "",
                )

            console.print()
            console.print(table)
            console.print()

            console.print(f"[green]Found {len(orgs)} organizations[/green]")
            console.print("\n[dim]To scan all organizations:[/dim]")
            console.print("[cyan]  brookside-analyze scan --all-orgs --full[/cyan]")
            console.print("\n[dim]To scan specific organization:[/dim]")
            console.print("[cyan]  brookside-analyze scan --org <org-name> --full[/cyan]\n")

    except Exception as e:
        console.print(f"\n[bold red]Error:[/bold red] {str(e)}")
        logger.exception("Failed to list organizations")
        sys.exit(1)


@cli.command()
def patterns() -> None:
    """
    Extract cross-repository patterns

    Example:
      brookside-analyze patterns
    """
    console.print("\n[bold blue]Pattern Extraction[/bold blue]\n")
    console.print("[yellow]This command requires organization scan data[/yellow]")
    console.print("Run: [cyan]brookside-analyze scan --full[/cyan] first\n")


@cli.command()
@click.option(
    "--threshold",
    default=90,
    help="Minimum days until cost optimization review",
)
def costs(threshold: int) -> None:
    """
    Calculate and optimize costs

    Example:
      brookside-analyze costs --threshold 90
    """
    console.print(f"\n[bold blue]Cost Analysis (threshold: {threshold} days)[/bold blue]\n")
    console.print("[yellow]This command requires organization scan data[/yellow]")
    console.print("Run: [cyan]brookside-analyze scan --full[/cyan] first\n")


def _display_summary_table(analyses: list) -> None:
    """Display summary table of analyzed repositories"""
    table = Table(title="Repository Analysis Summary")

    table.add_column("Repository", style="cyan")
    table.add_column("Viability", style="green")
    table.add_column("Reusability", style="yellow")
    table.add_column("Cost/mo", justify="right", style="magenta")
    table.add_column("Language", style="blue")

    for analysis in analyses[:20]:  # Top 20
        table.add_row(
            analysis.repository.name,
            analysis.viability.rating.value,
            analysis.reusability_rating.value.split()[0],  # Just emoji
            f"${analysis.monthly_cost:.2f}",
            analysis.repository.primary_language or "Unknown",
        )

    console.print(table)


def _display_cost_summary(stats: dict) -> None:
    """Display cost summary statistics"""
    console.print(f"\n[bold]Total Monthly Cost:[/bold] [green]${stats['total_monthly']:.2f}[/green]")
    console.print(f"[bold]Total Annual Cost:[/bold] [green]${stats['total_annual']:.2f}[/green]")
    console.print(f"[bold]Average per Repo:[/bold] ${stats['average_per_repo']:.2f}")
    console.print(f"[bold]Repos with Costs:[/bold] {stats['repos_with_costs']}/{stats['repos_analyzed']}\n")


def _display_repo_analysis(analysis: any) -> None:
    """Display detailed repository analysis"""
    console.print(f"[bold]{analysis.repository.name}[/bold]")
    console.print(f"[dim]{analysis.repository.description or 'No description'}[/dim]\n")

    console.print(f"[bold]Viability:[/bold] {analysis.viability.rating.value} ({analysis.viability.total_score}/100)")
    console.print(f"[bold]Reusability:[/bold] {analysis.reusability_rating.value}")
    console.print(f"[bold]Monthly Cost:[/bold] ${analysis.monthly_cost:.2f}\n")

    console.print(f"[bold]Quality Metrics:[/bold]")
    console.print(f"  Tests: {'YES' if analysis.has_tests else 'NO'}")
    console.print(f"  CI/CD: {'YES' if analysis.has_ci_cd else 'NO'}")
    console.print(f"  Docs: {'YES' if analysis.has_documentation else 'NO'}\n")


if __name__ == "__main__":
    cli()
