"""
Azure Function App for Brookside BI Repository Analyzer

Establishes scheduled, automated repository scanning with Notion synchronization,
designed to streamline portfolio management through weekly analysis execution.

Best for: Organizations requiring automated, event-driven repository analysis
with Azure-native deployment and monitoring integration.
"""

import asyncio
import logging
import os
from datetime import datetime

import azure.functions as func

# Configure logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# Create Function App
app = func.FunctionApp()

# NOTE: All application imports deferred to function bodies to ensure
# proper Azure Functions Python V2 discovery during indexing phase.
# This pattern prevents module-level side effects from blocking discovery.


@app.schedule(
    schedule="0 0 0 * * 0",  # Weekly on Sunday at midnight UTC
    arg_name="timer",
    run_on_startup=False,
    use_monitor=True,
)
async def weekly_repository_scan(timer: func.TimerRequest) -> None:
    """
    Weekly scheduled scan of all organization repositories

    Executes comprehensive analysis of all repositories in the brookside-bi
    organization and syncs results to Notion Innovation Nexus databases.

    Schedule: Every Sunday at 00:00 UTC
    Duration: ~5-15 minutes depending on repository count
    Cost: ~$0.10-0.50 per execution (Azure Functions consumption)

    Args:
        timer: Azure Timer trigger with schedule information
    """
    # Defer imports to function body for Python V2 discovery compatibility
    from src.analyzers.claude_detector import ClaudeCapabilitiesDetector
    from src.analyzers.cost_calculator import CostCalculator
    from src.analyzers.pattern_miner import PatternMiner
    from src.analyzers.repo_analyzer import RepositoryAnalyzer
    from src.auth import CredentialManager
    from src.config import get_settings
    from src.github_mcp_client import GitHubMCPClient
    from src.notion_client import NotionIntegrationClient

    logger.info("Starting weekly repository scan...")
    logger.info(f"Timer trigger at: {datetime.utcnow().isoformat()}")

    if timer.past_due:
        logger.warning("Timer is past due - execution may be delayed")

    try:
        # Initialize configuration
        settings = get_settings()
        credentials = CredentialManager(settings)

        # Validate credentials
        cred_status = credentials.validate_credentials()

        if not cred_status["github"]:
            logger.error("GitHub credentials not found in Key Vault")
            raise ValueError("Missing GitHub authentication")

        if not cred_status["notion"]:
            logger.warning("Notion credentials not found - sync will be skipped")

        logger.info("Credentials validated successfully")

        # Execute repository scan
        async with GitHubMCPClient(settings, credentials) as github_client:
            logger.info(f"Scanning organization: {settings.github.organization}")

            # List all repositories
            repos = await github_client.list_organization_repos()
            logger.info(f"Found {len(repos)} repositories to analyze")

            # Initialize analyzers
            analyzer = RepositoryAnalyzer(github_client)
            claude_detector = ClaudeCapabilitiesDetector(github_client)

            analyses = []

            # Analyze each repository
            for idx, repo in enumerate(repos, 1):
                logger.info(f"[{idx}/{len(repos)}] Analyzing: {repo.name}")

                try:
                    # Perform deep analysis
                    analysis = await analyzer.analyze_repository(repo, deep_analysis=True)

                    # Detect Claude capabilities if enabled
                    if settings.analysis.detect_claude_configs:
                        analysis.claude_config = await claude_detector.detect_claude_capabilities(
                            repo
                        )

                    analyses.append(analysis)
                    logger.info(
                        f"  ✓ {repo.name} - Viability: {analysis.viability.rating.value}, "
                        f"Cost: ${analysis.monthly_cost:.2f}/mo"
                    )

                except Exception as e:
                    logger.error(f"  ✗ Failed to analyze {repo.name}: {str(e)}")
                    continue

            logger.info(f"Successfully analyzed {len(analyses)}/{len(repos)} repositories")

            # Pattern extraction
            logger.info("Extracting cross-repository patterns...")
            miner = PatternMiner()
            patterns = miner.extract_patterns(analyses)
            logger.info(f"Identified {len(patterns)} reusable patterns")

            # Cost analysis
            logger.info("Calculating aggregate costs...")
            calculator = CostCalculator()
            cost_stats = calculator.calculate_aggregate_costs(analyses)

            logger.info(
                f"Total monthly cost: ${cost_stats['total_monthly']:.2f}, "
                f"Annual projection: ${cost_stats['total_annual']:.2f}"
            )

            # Sync to Notion if credentials available
            if cred_status["notion"]:
                logger.info("Syncing results to Notion Innovation Nexus...")
                notion_client = NotionIntegrationClient(settings, credentials)

                sync_count = 0
                for analysis in analyses:
                    try:
                        await notion_client.create_build_entry(analysis)
                        sync_count += 1
                    except Exception as e:
                        logger.error(
                            f"Failed to sync {analysis.repository.name} to Notion: {str(e)}"
                        )

                logger.info(f"Synced {sync_count}/{len(analyses)} repositories to Notion")
            else:
                logger.info("Skipping Notion sync (credentials not available)")

        logger.info("Weekly repository scan completed successfully")

        # Log summary metrics
        logger.info(
            f"Summary: {len(analyses)} repos analyzed, "
            f"{len(patterns)} patterns identified, "
            f"${cost_stats['total_monthly']:.2f}/mo total cost"
        )

    except Exception as e:
        logger.exception(f"Weekly repository scan failed: {str(e)}")
        raise


@app.route(route="health", methods=["GET"], auth_level=func.AuthLevel.ANONYMOUS)
async def health_check(req: func.HttpRequest) -> func.HttpResponse:
    """
    Health check endpoint for monitoring

    Returns:
        HTTP 200 with status information
    """
    # Defer imports to function body for Python V2 discovery compatibility
    from src.config import get_settings

    logger.info("Health check requested")

    try:
        settings = get_settings()

        health_status = {
            "status": "healthy",
            "timestamp": datetime.utcnow().isoformat(),
            "version": "0.1.0",
            "organization": settings.github.organization,
            "keyvault": settings.azure.keyvault_name,
        }

        return func.HttpResponse(
            body=str(health_status),
            status_code=200,
            mimetype="application/json",
        )

    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return func.HttpResponse(
            body=f'{{"status": "unhealthy", "error": "{str(e)}"}}',
            status_code=500,
            mimetype="application/json",
        )


@app.route(route="manual-scan", methods=["POST"], auth_level=func.AuthLevel.FUNCTION)
async def manual_repository_scan(req: func.HttpRequest) -> func.HttpResponse:
    """
    Manual trigger for repository scan

    Allows on-demand execution of repository analysis outside scheduled runs.
    Requires function-level authentication for security.

    Request Body (optional):
        {
            "deep_analysis": true,
            "sync_to_notion": true,
            "repository_filter": ["repo1", "repo2"]  // Optional: analyze specific repos
        }

    Returns:
        HTTP 200 with scan results summary
    """
    # Defer imports to function body for Python V2 discovery compatibility
    from src.analyzers.cost_calculator import CostCalculator
    from src.analyzers.repo_analyzer import RepositoryAnalyzer
    from src.auth import CredentialManager
    from src.config import get_settings
    from src.github_mcp_client import GitHubMCPClient
    from src.notion_client import NotionIntegrationClient

    logger.info("Manual repository scan triggered")

    try:
        # Parse request body
        req_body = req.get_json() if req.get_body() else {}

        deep_analysis = req_body.get("deep_analysis", True)
        sync_to_notion = req_body.get("sync_to_notion", True)
        repository_filter = req_body.get("repository_filter", [])

        logger.info(
            f"Scan parameters: deep_analysis={deep_analysis}, "
            f"sync={sync_to_notion}, filter={repository_filter}"
        )

        # Execute scan (similar to scheduled scan)
        settings = get_settings()
        credentials = CredentialManager(settings)

        async with GitHubMCPClient(settings, credentials) as github_client:
            repos = await github_client.list_organization_repos()

            # Apply filter if specified
            if repository_filter:
                repos = [r for r in repos if r.name in repository_filter]
                logger.info(f"Filtered to {len(repos)} repositories")

            # Analyze repositories
            analyzer = RepositoryAnalyzer(github_client)
            analyses = []

            for repo in repos:
                try:
                    analysis = await analyzer.analyze_repository(repo, deep_analysis=deep_analysis)
                    analyses.append(analysis)
                except Exception as e:
                    logger.error(f"Failed to analyze {repo.name}: {str(e)}")

            # Calculate costs
            calculator = CostCalculator()
            cost_stats = calculator.calculate_aggregate_costs(analyses)

            # Sync to Notion if requested
            if sync_to_notion and credentials.validate_credentials()["notion"]:
                notion_client = NotionIntegrationClient(settings, credentials)
                for analysis in analyses:
                    try:
                        await notion_client.create_build_entry(analysis)
                    except Exception as e:
                        logger.error(f"Notion sync failed for {analysis.repository.name}: {str(e)}")

            # Return summary
            response = {
                "status": "completed",
                "repositories_analyzed": len(analyses),
                "total_monthly_cost": cost_stats["total_monthly"],
                "total_annual_cost": cost_stats["total_annual"],
                "timestamp": datetime.utcnow().isoformat(),
            }

            return func.HttpResponse(
                body=str(response),
                status_code=200,
                mimetype="application/json",
            )

    except Exception as e:
        logger.exception(f"Manual scan failed: {str(e)}")
        return func.HttpResponse(
            body=f'{{"status": "error", "message": "{str(e)}"}}',
            status_code=500,
            mimetype="application/json",
        )


# Entry point for local development
if __name__ == "__main__":
    # For local testing with Azure Functions Core Tools
    logger.info("Starting Azure Function App in local development mode")
