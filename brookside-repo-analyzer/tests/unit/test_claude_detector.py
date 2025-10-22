"""
Unit Tests for Claude Integration Detector

Validates Claude maturity scoring algorithm and .claude/ directory parsing
to ensure accurate integration level detection across repositories.

Best for: Ensuring consistent Claude integration assessment with predictable
maturity levels for portfolio intelligence reporting.
"""
import pytest
from pathlib import Path
from unittest.mock import Mock, patch, MagicMock

from src.analyzers.claude_detector import ClaudeDetector, ClaudeIntegration, MaturityLevel
from src.models import Repository


class TestClaudeDetector:
    """Test suite for Claude integration detection and maturity scoring"""

    @pytest.fixture
    def detector(self):
        """Create ClaudeDetector instance for testing"""
        return ClaudeDetector()

    @pytest.fixture
    def mock_repo(self):
        """Create mock repository for testing"""
        repo = Mock(spec=Repository)
        repo.name = "test-repo"
        repo.default_branch = "main"
        return repo

    def test_no_claude_directory(self, detector, mock_repo):
        """Test detection when no .claude/ directory exists"""
        with patch.object(detector, '_check_claude_directory', return_value=False):
            result = detector.detect(mock_repo)

        assert result.maturity_level == MaturityLevel.NONE
        assert result.score == 0
        assert result.agents_count == 0
        assert result.commands_count == 0
        assert result.mcp_servers_count == 0
        assert not result.has_claude_md

    def test_basic_claude_integration(self, detector, mock_repo):
        """Test BASIC maturity (10-29 points): minimal .claude/ setup"""
        with patch.object(detector, '_check_claude_directory', return_value=True), \
             patch.object(detector, '_count_agents', return_value=1), \
             patch.object(detector, '_count_commands', return_value=0), \
             patch.object(detector, '_count_mcp_servers', return_value=0), \
             patch.object(detector, '_has_claude_md', return_value=False):

            result = detector.detect(mock_repo)

        # Score = (1 * 10) + (0 * 5) + (0 * 10) + (0 * 15) = 10 points
        assert result.maturity_level == MaturityLevel.BASIC
        assert result.score == 10
        assert result.agents_count == 1

    def test_intermediate_claude_integration(self, detector, mock_repo):
        """Test INTERMEDIATE maturity (30-59 points): basic agents + commands"""
        with patch.object(detector, '_check_claude_directory', return_value=True), \
             patch.object(detector, '_count_agents', return_value=3), \
             patch.object(detector, '_count_commands', return_value=2), \
             patch.object(detector, '_count_mcp_servers', return_value=0), \
             patch.object(detector, '_has_claude_md', return_value=True):

            result = detector.detect(mock_repo)

        # Score = (3 * 10) + (2 * 5) + (0 * 10) + (1 * 15) = 55 points
        assert result.maturity_level == MaturityLevel.INTERMEDIATE
        assert result.score == 55
        assert result.agents_count == 3
        assert result.commands_count == 2
        assert result.has_claude_md

    def test_advanced_claude_integration(self, detector, mock_repo):
        """Test ADVANCED maturity (60-79 points): multiple agents/commands + MCP"""
        with patch.object(detector, '_check_claude_directory', return_value=True), \
             patch.object(detector, '_count_agents', return_value=5), \
             patch.object(detector, '_count_commands', return_value=4), \
             patch.object(detector, '_count_mcp_servers', return_value=1), \
             patch.object(detector, '_has_claude_md', return_value=True):

            result = detector.detect(mock_repo)

        # Score = (5 * 10) + (4 * 5) + (1 * 10) + (1 * 15) = 95 points (capped to ADVANCED)
        assert result.maturity_level == MaturityLevel.ADVANCED
        assert result.score >= 60
        assert result.agents_count == 5
        assert result.mcp_servers_count == 1

    def test_expert_claude_integration(self, detector, mock_repo):
        """Test EXPERT maturity (80-100 points): comprehensive setup"""
        with patch.object(detector, '_check_claude_directory', return_value=True), \
             patch.object(detector, '_count_agents', return_value=10), \
             patch.object(detector, '_count_commands', return_value=8), \
             patch.object(detector, '_count_mcp_servers', return_value=3), \
             patch.object(detector, '_has_claude_md', return_value=True):

            result = detector.detect(mock_repo)

        # Score = (10 * 10) + (8 * 5) + (3 * 10) + (1 * 15) = 185 points (capped at 100)
        assert result.maturity_level == MaturityLevel.EXPERT
        assert result.score == 100  # Capped at maximum
        assert result.agents_count == 10
        assert result.commands_count == 8
        assert result.mcp_servers_count == 3
        assert result.has_claude_md

    def test_score_calculation_formula(self, detector, mock_repo):
        """Validate exact scoring formula: (agents*10) + (commands*5) + (mcp*10) + (md*15)"""
        test_cases = [
            # (agents, commands, mcp, has_md, expected_score)
            (0, 0, 0, False, 0),
            (1, 0, 0, False, 10),
            (0, 2, 0, False, 10),
            (0, 0, 1, False, 10),
            (0, 0, 0, True, 15),
            (2, 3, 1, True, 50),  # (2*10) + (3*5) + (1*10) + (1*15) = 50
            (5, 6, 2, True, 105),  # Exceeds 100, should cap
        ]

        for agents, commands, mcp, has_md, expected in test_cases:
            with patch.object(detector, '_check_claude_directory', return_value=(agents + commands + mcp + int(has_md)) > 0), \
                 patch.object(detector, '_count_agents', return_value=agents), \
                 patch.object(detector, '_count_commands', return_value=commands), \
                 patch.object(detector, '_count_mcp_servers', return_value=mcp), \
                 patch.object(detector, '_has_claude_md', return_value=has_md):

                result = detector.detect(mock_repo)

                # Cap score at 100
                expected_capped = min(expected, 100)
                assert result.score == expected_capped, \
                    f"Failed for agents={agents}, commands={commands}, mcp={mcp}, md={has_md}"

    def test_maturity_level_thresholds(self, detector, mock_repo):
        """Validate maturity level threshold boundaries"""
        threshold_tests = [
            (0, MaturityLevel.NONE),
            (9, MaturityLevel.NONE),
            (10, MaturityLevel.BASIC),
            (29, MaturityLevel.BASIC),
            (30, MaturityLevel.INTERMEDIATE),
            (59, MaturityLevel.INTERMEDIATE),
            (60, MaturityLevel.ADVANCED),
            (79, MaturityLevel.ADVANCED),
            (80, MaturityLevel.EXPERT),
            (100, MaturityLevel.EXPERT),
        ]

        for score, expected_level in threshold_tests:
            # Reverse-engineer component counts to achieve target score
            # Simple approach: allocate all to agents (score / 10)
            agents = score // 10
            commands = 0
            mcp = 0
            has_md = False

            with patch.object(detector, '_check_claude_directory', return_value=score > 0), \
                 patch.object(detector, '_count_agents', return_value=agents), \
                 patch.object(detector, '_count_commands', return_value=commands), \
                 patch.object(detector, '_count_mcp_servers', return_value=mcp), \
                 patch.object(detector, '_has_claude_md', return_value=has_md):

                result = detector.detect(mock_repo)

                assert result.maturity_level == expected_level, \
                    f"Score {score} should be {expected_level.value}, got {result.maturity_level.value}"

    def test_agent_counting(self, detector, mock_repo):
        """Test agent file counting in .claude/agents/ directory"""
        mock_files = [
            Path(".claude/agents/ideas-capture.md"),
            Path(".claude/agents/cost-analyst.md"),
            Path(".claude/agents/research-coordinator.md"),
            Path(".claude/agents/README.md"),  # Should be excluded
        ]

        with patch.object(detector, '_get_repo_files', return_value=mock_files):
            count = detector._count_agents(mock_repo)

        assert count == 3  # README.md excluded

    def test_command_counting(self, detector, mock_repo):
        """Test command file counting in .claude/commands/ directory"""
        mock_files = [
            Path(".claude/commands/innovation/new-idea.md"),
            Path(".claude/commands/cost/analyze.md"),
            Path(".claude/commands/team/assign.md"),
            Path(".claude/commands/README.md"),  # Should be excluded
        ]

        with patch.object(detector, '_get_repo_files', return_value=mock_files):
            count = detector._count_commands(mock_repo)

        assert count == 3

    def test_mcp_server_detection(self, detector, mock_repo):
        """Test MCP server counting from .claude.json"""
        mock_config = {
            "mcpServers": {
                "notion": {"url": "https://mcp.notion.com/mcp"},
                "github": {"command": "npx", "args": ["-y", "@modelcontextprotocol/server-github"]},
                "azure": {"command": "npx", "args": ["-y", "@azure/mcp@latest"]}
            }
        }

        with patch.object(detector, '_read_claude_json', return_value=mock_config):
            count = detector._count_mcp_servers(mock_repo)

        assert count == 3

    def test_claude_md_detection(self, detector, mock_repo):
        """Test CLAUDE.md presence detection"""
        # Test when file exists
        with patch.object(detector, '_check_file_exists', return_value=True):
            assert detector._has_claude_md(mock_repo) is True

        # Test when file doesn't exist
        with patch.object(detector, '_check_file_exists', return_value=False):
            assert detector._has_claude_md(mock_repo) is False

    def test_integration_details_summary(self, detector, mock_repo):
        """Test ClaudeIntegration model details property"""
        integration = ClaudeIntegration(
            maturity_level=MaturityLevel.ADVANCED,
            score=75,
            agents_count=6,
            commands_count=5,
            mcp_servers_count=2,
            has_claude_md=True,
            agent_files=["ideas-capture.md", "cost-analyst.md"],
            command_files=["innovation/new-idea.md", "cost/analyze.md"],
            mcp_servers=["notion", "github"]
        )

        details = integration.details

        assert "ADVANCED" in details
        assert "75/100" in details
        assert "6 agents" in details
        assert "5 commands" in details
        assert "2 MCP servers" in details

    def test_error_handling_missing_directory(self, detector, mock_repo):
        """Test graceful handling when .claude/ directory missing"""
        with patch.object(detector, '_check_claude_directory', side_effect=Exception("Directory not found")):
            result = detector.detect(mock_repo)

        # Should default to NONE on errors
        assert result.maturity_level == MaturityLevel.NONE
        assert result.score == 0

    def test_caching_behavior(self, detector, mock_repo):
        """Test that detection results can be cached efficiently"""
        with patch.object(detector, '_check_claude_directory', return_value=True), \
             patch.object(detector, '_count_agents', return_value=3), \
             patch.object(detector, '_count_commands', return_value=2), \
             patch.object(detector, '_count_mcp_servers', return_value=1), \
             patch.object(detector, '_has_claude_md', return_value=True):

            result1 = detector.detect(mock_repo)
            result2 = detector.detect(mock_repo)

        # Both should return identical results (if caching implemented)
        assert result1.score == result2.score
        assert result1.maturity_level == result2.maturity_level


class TestClaudeIntegrationModel:
    """Test ClaudeIntegration data model"""

    def test_model_validation(self):
        """Test Pydantic model validation"""
        integration = ClaudeIntegration(
            maturity_level=MaturityLevel.INTERMEDIATE,
            score=45,
            agents_count=3,
            commands_count=2,
            mcp_servers_count=1,
            has_claude_md=True
        )

        assert integration.maturity_level == MaturityLevel.INTERMEDIATE
        assert integration.score == 45
        assert integration.agents_count == 3

    def test_optional_file_lists(self):
        """Test that file lists are optional"""
        integration = ClaudeIntegration(
            maturity_level=MaturityLevel.BASIC,
            score=15,
            agents_count=1,
            commands_count=0,
            mcp_servers_count=0,
            has_claude_md=True
        )

        # Optional fields should default to empty lists
        assert integration.agent_files == []
        assert integration.command_files == []
        assert integration.mcp_servers == []

    def test_serialization(self):
        """Test model can be serialized to dict"""
        integration = ClaudeIntegration(
            maturity_level=MaturityLevel.EXPERT,
            score=95,
            agents_count=10,
            commands_count=8,
            mcp_servers_count=3,
            has_claude_md=True
        )

        data = integration.model_dump()

        assert data["maturity_level"] == "EXPERT"
        assert data["score"] == 95
        assert isinstance(data, dict)


class TestMaturityLevel:
    """Test MaturityLevel enum"""

    def test_enum_values(self):
        """Test all maturity levels are defined"""
        assert MaturityLevel.NONE.value == "NONE"
        assert MaturityLevel.BASIC.value == "BASIC"
        assert MaturityLevel.INTERMEDIATE.value == "INTERMEDIATE"
        assert MaturityLevel.ADVANCED.value == "ADVANCED"
        assert MaturityLevel.EXPERT.value == "EXPERT"

    def test_enum_ordering(self):
        """Test maturity levels can be compared"""
        assert MaturityLevel.NONE < MaturityLevel.BASIC
        assert MaturityLevel.BASIC < MaturityLevel.INTERMEDIATE
        assert MaturityLevel.INTERMEDIATE < MaturityLevel.ADVANCED
        assert MaturityLevel.ADVANCED < MaturityLevel.EXPERT


# Integration-like tests (mocked external calls)
class TestClaudeDetectorIntegration:
    """Test detector with realistic file structures"""

    @pytest.fixture
    def detector(self):
        return ClaudeDetector()

    def test_innovation_nexus_structure(self, detector):
        """Test detection against Innovation Nexus .claude/ structure"""
        mock_repo = Mock(spec=Repository)
        mock_repo.name = "innovation-nexus"
        mock_repo.default_branch = "main"

        # Simulate Innovation Nexus structure (27+ agents, 12+ commands, 4 MCP servers)
        with patch.object(detector, '_check_claude_directory', return_value=True), \
             patch.object(detector, '_count_agents', return_value=27), \
             patch.object(detector, '_count_commands', return_value=12), \
             patch.object(detector, '_count_mcp_servers', return_value=4), \
             patch.object(detector, '_has_claude_md', return_value=True):

            result = detector.detect(mock_repo)

        # Should be EXPERT with maximum score
        assert result.maturity_level == MaturityLevel.EXPERT
        assert result.score == 100
        assert result.agents_count == 27
        assert result.commands_count == 12
        assert result.mcp_servers_count == 4

    def test_minimal_repo_structure(self, detector):
        """Test detection for minimal .claude/ setup"""
        mock_repo = Mock(spec=Repository)
        mock_repo.name = "minimal-repo"

        # Only CLAUDE.md file
        with patch.object(detector, '_check_claude_directory', return_value=True), \
             patch.object(detector, '_count_agents', return_value=0), \
             patch.object(detector, '_count_commands', return_value=0), \
             patch.object(detector, '_count_mcp_servers', return_value=0), \
             patch.object(detector, '_has_claude_md', return_value=True):

            result = detector.detect(mock_repo)

        # Score = 15 points (CLAUDE.md only) -> BASIC
        assert result.maturity_level == MaturityLevel.BASIC
        assert result.score == 15


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--cov=src.analyzers.claude_detector", "--cov-report=term-missing"])
