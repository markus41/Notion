"""
End-to-End Tests for Complete Workflow

Tests complete repository analysis workflow from GitHub scan to Notion synchronization.
Validates CLI commands, analysis pipeline, and knowledge base generation.

Best for: Full system validation before deployment to production environments.

NOTE: These tests require:
- Azure CLI authentication
- GitHub MCP configured and accessible
- Notion MCP configured in Claude Code
- Access to brookside-bi GitHub organization
"""

import pytest
import subprocess
from pathlib import Path

from src.config import get_settings


@pytest.fixture
def e2e_settings():
    """Get settings configured for E2E tests"""
    settings = get_settings()
    assert settings.github.organization, "GITHUB_ORG must be set"
    assert settings.azure.keyvault_name, "AZURE_KEYVAULT_NAME must be set"
    assert settings.notion.workspace_id, "NOTION_WORKSPACE_ID must be set"
    return settings


class TestCLICommands:
    """Test CLI command execution"""

    @pytest.mark.e2e
    def test_cli_help_command(self):
        """Test that CLI help command works"""
        result = subprocess.run(
            ["poetry", "run", "brookside-analyze", "--help"],
            capture_output=True,
            text=True,
            cwd=Path(__file__).parent.parent.parent,
        )

        assert result.returncode == 0
        assert "Brookside BI Repository Analyzer" in result.stdout

    @pytest.mark.e2e
    def test_cli_version_command(self):
        """Test CLI version display"""
        result = subprocess.run(
            ["poetry", "run", "brookside-analyze", "--version"],
            capture_output=True,
            text=True,
            cwd=Path(__file__).parent.parent.parent,
        )

        assert result.returncode == 0
        assert "version" in result.stdout.lower()


class TestSingleRepositoryAnalysis:
    """Test analyzing a single repository"""

    @pytest.mark.e2e
    @pytest.mark.slow
    def test_analyze_single_repo_basic(self, e2e_settings):
        """Test basic single repository analysis"""
        result = subprocess.run(
            [
                "poetry",
                "run",
                "brookside-analyze",
                "analyze",
                "brookside-repo-analyzer",  # This repo
            ],
            capture_output=True,
            text=True,
            cwd=Path(__file__).parent.parent.parent,
            timeout=120,  # 2 minute timeout
        )

        # Should complete successfully
        assert result.returncode == 0
        assert "Viability" in result.stdout
        assert "Score" in result.stdout

    @pytest.mark.e2e
    @pytest.mark.slow
    def test_analyze_repo_with_deep_analysis(self, e2e_settings):
        """Test deep analysis of repository"""
        result = subprocess.run(
            [
                "poetry",
                "run",
                "brookside-analyze",
                "analyze",
                "brookside-repo-analyzer",
                "--deep",
            ],
            capture_output=True,
            text=True,
            cwd=Path(__file__).parent.parent.parent,
            timeout=180,  # 3 minute timeout for deep analysis
        )

        assert result.returncode == 0
        assert "Claude" in result.stdout or "dependencies" in result.stdout.lower()

    @pytest.mark.e2e
    @pytest.mark.slow
    @pytest.mark.skip(reason="Requires Notion MCP fully configured")
    def test_analyze_repo_with_notion_sync(self, e2e_settings):
        """Test repository analysis with Notion synchronization"""
        result = subprocess.run(
            [
                "poetry",
                "run",
                "brookside-analyze",
                "analyze",
                "brookside-repo-analyzer",
                "--sync",
            ],
            capture_output=True,
            text=True,
            cwd=Path(__file__).parent.parent.parent,
            timeout=180,
        )

        assert result.returncode == 0
        assert "Notion" in result.stdout or "synced" in result.stdout.lower()


class TestOrganizationScan:
    """Test full organization scanning"""

    @pytest.mark.e2e
    @pytest.mark.slow
    @pytest.mark.skip(reason="Scans entire org - run manually only")
    def test_scan_organization_basic(self, e2e_settings):
        """Test basic organization scan without Notion sync"""
        result = subprocess.run(
            [
                "poetry",
                "run",
                "brookside-analyze",
                "scan",
            ],
            capture_output=True,
            text=True,
            cwd=Path(__file__).parent.parent.parent,
            timeout=600,  # 10 minute timeout
        )

        assert result.returncode == 0
        assert "repositories" in result.stdout.lower()
        assert "viability" in result.stdout.lower()

    @pytest.mark.e2e
    @pytest.mark.slow
    @pytest.mark.skip(reason="Full scan with sync - expensive operation")
    def test_scan_organization_with_sync(self, e2e_settings):
        """Test full organization scan with Notion synchronization"""
        result = subprocess.run(
            [
                "poetry",
                "run",
                "brookside-analyze",
                "scan",
                "--full",
                "--sync",
            ],
            capture_output=True,
            text=True,
            cwd=Path(__file__).parent.parent.parent,
            timeout=1800,  # 30 minute timeout for full scan
        )

        assert result.returncode == 0
        assert "synced" in result.stdout.lower() or "notion" in result.stdout.lower()


class TestPatternExtraction:
    """Test pattern mining across repositories"""

    @pytest.mark.e2e
    @pytest.mark.slow
    @pytest.mark.skip(reason="Requires previous scan data")
    def test_extract_patterns_basic(self, e2e_settings):
        """Test basic pattern extraction"""
        result = subprocess.run(
            [
                "poetry",
                "run",
                "brookside-analyze",
                "patterns",
            ],
            capture_output=True,
            text=True,
            cwd=Path(__file__).parent.parent.parent,
            timeout=180,
        )

        assert result.returncode == 0
        assert "pattern" in result.stdout.lower()

    @pytest.mark.e2e
    @pytest.mark.slow
    @pytest.mark.skip(reason="Requires Notion MCP")
    def test_extract_patterns_with_sync(self, e2e_settings):
        """Test pattern extraction with Knowledge Vault sync"""
        result = subprocess.run(
            [
                "poetry",
                "run",
                "brookside-analyze",
                "patterns",
                "--sync",
            ],
            capture_output=True,
            text=True,
            cwd=Path(__file__).parent.parent.parent,
            timeout=180,
        )

        assert result.returncode == 0


class TestCostCalculation:
    """Test portfolio cost calculation"""

    @pytest.mark.e2e
    def test_calculate_costs_basic(self, e2e_settings):
        """Test basic cost calculation"""
        result = subprocess.run(
            [
                "poetry",
                "run",
                "brookside-analyze",
                "costs",
            ],
            capture_output=True,
            text=True,
            cwd=Path(__file__).parent.parent.parent,
            timeout=60,
        )

        # Should work even without scan data (will show $0)
        assert result.returncode == 0
        assert "cost" in result.stdout.lower() or "$" in result.stdout

    @pytest.mark.e2e
    @pytest.mark.skip(reason="Requires previous scan data")
    def test_calculate_costs_detailed(self, e2e_settings):
        """Test detailed cost breakdown"""
        result = subprocess.run(
            [
                "poetry",
                "run",
                "brookside-analyze",
                "costs",
                "--detailed",
            ],
            capture_output=True,
            text=True,
            cwd=Path(__file__).parent.parent.parent,
            timeout=60,
        )

        assert result.returncode == 0
        assert "category" in result.stdout.lower() or "breakdown" in result.stdout.lower()


class TestErrorHandling:
    """Test error handling in various scenarios"""

    @pytest.mark.e2e
    def test_analyze_nonexistent_repo(self, e2e_settings):
        """Test error handling for non-existent repository"""
        result = subprocess.run(
            [
                "poetry",
                "run",
                "brookside-analyze",
                "analyze",
                "this-repo-does-not-exist-12345",
            ],
            capture_output=True,
            text=True,
            cwd=Path(__file__).parent.parent.parent,
            timeout=30,
        )

        # Should fail gracefully
        assert result.returncode != 0 or "not found" in result.stdout.lower()

    @pytest.mark.e2e
    def test_invalid_command(self):
        """Test handling of invalid CLI command"""
        result = subprocess.run(
            [
                "poetry",
                "run",
                "brookside-analyze",
                "invalid-command",
            ],
            capture_output=True,
            text=True,
            cwd=Path(__file__).parent.parent.parent,
            timeout=10,
        )

        assert result.returncode != 0


class TestCompleteWorkflow:
    """Test complete end-to-end workflow"""

    @pytest.mark.e2e
    @pytest.mark.slow
    @pytest.mark.skip(reason="Complete workflow - run manually for validation")
    def test_complete_innovation_workflow(self, e2e_settings):
        """
        Test complete workflow:
        1. Scan organization
        2. Extract patterns
        3. Calculate costs
        4. Sync to Notion
        """
        # Step 1: Scan organization
        scan_result = subprocess.run(
            [
                "poetry",
                "run",
                "brookside-analyze",
                "scan",
                "--full",
            ],
            capture_output=True,
            text=True,
            cwd=Path(__file__).parent.parent.parent,
            timeout=600,
        )

        assert scan_result.returncode == 0

        # Step 2: Extract patterns
        patterns_result = subprocess.run(
            [
                "poetry",
                "run",
                "brookside-analyze",
                "patterns",
            ],
            capture_output=True,
            text=True,
            cwd=Path(__file__).parent.parent.parent,
            timeout=180,
        )

        assert patterns_result.returncode == 0

        # Step 3: Calculate costs
        costs_result = subprocess.run(
            [
                "poetry",
                "run",
                "brookside-analyze",
                "costs",
                "--detailed",
            ],
            capture_output=True,
            text=True,
            cwd=Path(__file__).parent.parent.parent,
            timeout=60,
        )

        assert costs_result.returncode == 0

        # All steps should complete successfully
        assert "viability" in scan_result.stdout.lower()
        assert "pattern" in patterns_result.stdout.lower()
        assert "$" in costs_result.stdout or "cost" in costs_result.stdout.lower()


class TestOutputFormats:
    """Test various output formats and options"""

    @pytest.mark.e2e
    @pytest.mark.skip(reason="Requires scan data")
    def test_json_output_format(self, e2e_settings):
        """Test JSON output format"""
        result = subprocess.run(
            [
                "poetry",
                "run",
                "brookside-analyze",
                "scan",
                "--output",
                "json",
            ],
            capture_output=True,
            text=True,
            cwd=Path(__file__).parent.parent.parent,
            timeout=600,
        )

        assert result.returncode == 0
        # Should be valid JSON
        assert "{" in result.stdout and "}" in result.stdout

    @pytest.mark.e2e
    @pytest.mark.skip(reason="Requires scan data")
    def test_verbose_output(self, e2e_settings):
        """Test verbose output mode"""
        result = subprocess.run(
            [
                "poetry",
                "run",
                "brookside-analyze",
                "analyze",
                "brookside-repo-analyzer",
                "-v",
            ],
            capture_output=True,
            text=True,
            cwd=Path(__file__).parent.parent.parent,
            timeout=120,
        )

        assert result.returncode == 0
        # Verbose should show more details
        assert len(result.stdout) > 100


@pytest.mark.e2e
def test_environment_variables_loaded(e2e_settings):
    """Test that all required environment variables are loaded"""
    assert e2e_settings.github.organization is not None
    assert e2e_settings.azure.keyvault_name is not None
    assert e2e_settings.notion.workspace_id is not None


@pytest.mark.e2e
def test_azure_authentication_active():
    """Test that Azure CLI authentication is active"""
    result = subprocess.run(
        ["az", "account", "show"],
        capture_output=True,
        text=True,
        timeout=10,
    )

    assert result.returncode == 0
    assert "id" in result.stdout  # Account ID present
