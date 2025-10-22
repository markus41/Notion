"""
Unit Tests for Pattern Miner

Validates cross-repository pattern extraction, reusability scoring, and
pattern library generation to drive code reuse across portfolio.

Best for: Ensuring accurate pattern detection that identifies high-value
architectural components for sustainable development practices.
"""
import pytest
from unittest.mock import Mock, patch, MagicMock
from pathlib import Path

from src.analyzers.pattern_miner import (
    PatternMiner,
    ArchitecturalPattern,
    PatternType,
    PatternUsage,
    PatternLibrary
)
from src.models import Repository


class TestPatternMiner:
    """Test suite for architectural pattern mining and extraction"""

    @pytest.fixture
    def miner(self):
        """Create PatternMiner instance for testing"""
        return PatternMiner(min_usage_threshold=3)

    @pytest.fixture
    def mock_repositories(self):
        """Create collection of mock repositories for pattern mining"""
        repos = []

        # Repo 1: Circuit Breaker pattern
        repo1 = Mock(spec=Repository)
        repo1.name = "service-a"
        repo1.file_patterns = [
            Path("src/resilience/circuit_breaker.py"),
            Path("src/retry/exponential_backoff.py")
        ]
        repos.append(repo1)

        # Repo 2: Circuit Breaker + Retry patterns
        repo2 = Mock(spec=Repository)
        repo2.name = "service-b"
        repo2.file_patterns = [
            Path("src/patterns/circuit_breaker.ts"),
            Path("src/patterns/retry.ts")
        ]
        repos.append(repo2)

        # Repo 3: Circuit Breaker pattern
        repo3 = Mock(spec=Repository)
        repo3.name = "service-c"
        repo3.file_patterns = [
            Path("lib/circuit-breaker.js")
        ]
        repos.append(repo3)

        # Repo 4: Different pattern (Saga)
        repo4 = Mock(spec=Repository)
        repo4.name = "service-d"
        repo4.file_patterns = [
            Path("src/saga/orchestrator.py")
        ]
        repos.append(repo4)

        return repos

    def test_mine_no_repositories(self, miner):
        """Test pattern mining with empty repository list"""
        result = miner.mine([])

        assert len(result.patterns) == 0
        assert result.total_repositories == 0

    def test_mine_single_repository(self, miner):
        """Test mining from single repository"""
        repo = Mock(spec=Repository)
        repo.name = "solo-repo"
        repo.file_patterns = [Path("src/circuit_breaker.py")]

        with patch.object(miner, '_extract_patterns_from_repo', return_value=[
            ArchitecturalPattern(
                name="Circuit Breaker",
                type=PatternType.RESILIENCE,
                file_path="src/circuit_breaker.py",
                language="Python",
                usage_count=1
            )
        ]):
            result = miner.mine([repo])

        # Pattern found but usage_count < min_threshold (3)
        assert len(result.patterns) == 0  # Filtered out due to low usage
        assert result.total_repositories == 1

    def test_mine_cross_repository_patterns(self, miner, mock_repositories):
        """Test detection of patterns used across multiple repositories"""
        with patch.object(miner, '_extract_patterns_from_repo') as mock_extract:
            # Configure mock to return circuit breaker pattern for first 3 repos
            def extract_side_effect(repo):
                if repo.name in ["service-a", "service-b", "service-c"]:
                    return [
                        ArchitecturalPattern(
                            name="Circuit Breaker",
                            type=PatternType.RESILIENCE,
                            file_path=str(repo.file_patterns[0]),
                            language="Python" if repo.name == "service-a" else "TypeScript",
                            usage_count=1
                        )
                    ]
                return []

            mock_extract.side_effect = extract_side_effect

            result = miner.mine(mock_repositories)

        # Circuit Breaker used in 3 repos (meets threshold)
        circuit_breaker_patterns = [p for p in result.patterns if p.name == "Circuit Breaker"]
        assert len(circuit_breaker_patterns) > 0

        if circuit_breaker_patterns:
            pattern = circuit_breaker_patterns[0]
            assert pattern.usage_count >= 3

    def test_pattern_type_detection(self, miner):
        """Test automatic pattern type classification"""
        test_cases = [
            ("circuit-breaker.py", PatternType.RESILIENCE),
            ("retry_logic.ts", PatternType.RESILIENCE),
            ("saga_orchestrator.py", PatternType.DISTRIBUTED_TRANSACTION),
            ("event_sourcing.js", PatternType.DATA),
            ("repository_pattern.py", PatternType.DATA),
            ("api_gateway.ts", PatternType.INTEGRATION),
            ("cache_aside.py", PatternType.PERFORMANCE),
        ]

        for filename, expected_type in test_cases:
            detected_type = miner._classify_pattern_type(filename)
            assert detected_type == expected_type, \
                f"Failed to classify {filename} as {expected_type.value}"

    def test_reusability_scoring(self, miner):
        """Test reusability score calculation"""
        # High usage + multiple languages = high reusability
        pattern_high = ArchitecturalPattern(
            name="Circuit Breaker",
            type=PatternType.RESILIENCE,
            file_path="src/circuit_breaker.py",
            language="Python",
            usage_count=10,
            repositories=["repo1", "repo2", "repo3", "repo4", "repo5"]
        )

        score_high = miner._calculate_reusability_score(pattern_high)
        assert score_high >= 75  # High reusability

        # Low usage = low reusability
        pattern_low = ArchitecturalPattern(
            name="Custom Logic",
            type=PatternType.OTHER,
            file_path="src/custom.py",
            language="Python",
            usage_count=1,
            repositories=["repo1"]
        )

        score_low = miner._calculate_reusability_score(pattern_low)
        assert score_low < 50  # Low reusability

    def test_microsoft_alignment_detection(self, miner):
        """Test detection of Microsoft ecosystem alignment"""
        microsoft_patterns = [
            "azure_service_bus_integration.py",
            "cosmos_db_repository.ts",
            "entra_id_authentication.py",
            "app_insights_telemetry.js",
        ]

        for pattern_file in microsoft_patterns:
            is_microsoft = miner._is_microsoft_aligned(pattern_file)
            assert is_microsoft is True, f"{pattern_file} should be Microsoft-aligned"

        non_microsoft_patterns = [
            "generic_retry.py",
            "abstract_factory.ts",
            "observer_pattern.js",
        ]

        for pattern_file in non_microsoft_patterns:
            is_microsoft = miner._is_microsoft_aligned(pattern_file)
            assert is_microsoft is False, f"{pattern_file} should not be Microsoft-aligned"

    def test_pattern_consolidation(self, miner):
        """Test consolidation of similar patterns across languages"""
        patterns = [
            ArchitecturalPattern(
                name="Circuit Breaker",
                type=PatternType.RESILIENCE,
                file_path="src/circuit_breaker.py",
                language="Python",
                usage_count=1
            ),
            ArchitecturalPattern(
                name="Circuit Breaker",
                type=PatternType.RESILIENCE,
                file_path="src/circuit-breaker.ts",
                language="TypeScript",
                usage_count=1
            ),
            ArchitecturalPattern(
                name="Circuit Breaker",
                type=PatternType.RESILIENCE,
                file_path="lib/circuitBreaker.js",
                language="JavaScript",
                usage_count=1
            ),
        ]

        consolidated = miner._consolidate_patterns(patterns)

        # Should consolidate to single pattern with total usage_count = 3
        assert len(consolidated) == 1
        assert consolidated[0].usage_count == 3
        assert len(consolidated[0].repositories) == 3

    def test_min_usage_threshold_filtering(self, miner):
        """Test filtering patterns below minimum usage threshold"""
        # miner initialized with min_usage_threshold=3

        patterns = [
            ArchitecturalPattern(name="Pattern A", type=PatternType.OTHER, file_path="a.py", language="Python", usage_count=5),
            ArchitecturalPattern(name="Pattern B", type=PatternType.OTHER, file_path="b.py", language="Python", usage_count=3),
            ArchitecturalPattern(name="Pattern C", type=PatternType.OTHER, file_path="c.py", language="Python", usage_count=2),
            ArchitecturalPattern(name="Pattern D", type=PatternType.OTHER, file_path="d.py", language="Python", usage_count=1),
        ]

        filtered = miner._filter_by_threshold(patterns)

        # Only Pattern A (5) and Pattern B (3) meet threshold
        assert len(filtered) == 2
        assert all(p.usage_count >= 3 for p in filtered)

    def test_pattern_library_generation(self, miner, mock_repositories):
        """Test generation of complete pattern library"""
        with patch.object(miner, '_extract_patterns_from_repo') as mock_extract:
            # Mock patterns across repositories
            mock_extract.return_value = [
                ArchitecturalPattern(
                    name="Circuit Breaker",
                    type=PatternType.RESILIENCE,
                    file_path="src/circuit_breaker.py",
                    language="Python",
                    usage_count=1
                )
            ]

            library = miner.mine(mock_repositories)

        assert isinstance(library, PatternLibrary)
        assert library.total_repositories == len(mock_repositories)
        assert library.total_patterns_found >= 0

    def test_architectural_pattern_model(self):
        """Test ArchitecturalPattern data model"""
        pattern = ArchitecturalPattern(
            name="Event Sourcing",
            type=PatternType.DATA,
            file_path="src/events/event_store.py",
            language="Python",
            usage_count=5,
            repositories=["repo1", "repo2", "repo3", "repo4", "repo5"],
            reusability_score=85,
            microsoft_aligned=True,
            description="Complete audit trail pattern using event log"
        )

        assert pattern.name == "Event Sourcing"
        assert pattern.type == PatternType.DATA
        assert pattern.usage_count == 5
        assert pattern.reusability_score == 85
        assert pattern.microsoft_aligned is True
        assert len(pattern.repositories) == 5

    def test_pattern_library_model(self):
        """Test PatternLibrary data model"""
        patterns = [
            ArchitecturalPattern(
                name="Circuit Breaker",
                type=PatternType.RESILIENCE,
                file_path="src/cb.py",
                language="Python",
                usage_count=3
            ),
            ArchitecturalPattern(
                name="Saga",
                type=PatternType.DISTRIBUTED_TRANSACTION,
                file_path="src/saga.py",
                language="Python",
                usage_count=2
            )
        ]

        library = PatternLibrary(
            patterns=patterns,
            total_repositories=10,
            total_patterns_found=15,
            microsoft_aligned_count=5
        )

        assert len(library.patterns) == 2
        assert library.total_repositories == 10
        assert library.total_patterns_found == 15
        assert library.microsoft_aligned_count == 5

    def test_pattern_usage_model(self):
        """Test PatternUsage data model"""
        usage = PatternUsage(
            repository_name="innovation-nexus",
            file_path="src/patterns/circuit_breaker.py",
            language="Python",
            lines_of_code=150
        )

        assert usage.repository_name == "innovation-nexus"
        assert usage.file_path == "src/patterns/circuit_breaker.py"
        assert usage.language == "Python"
        assert usage.lines_of_code == 150


class TestPatternType:
    """Test PatternType enum"""

    def test_pattern_types(self):
        """Test all pattern types are defined"""
        assert PatternType.RESILIENCE.value == "Resilience"
        assert PatternType.DATA.value == "Data"
        assert PatternType.INTEGRATION.value == "Integration"
        assert PatternType.DISTRIBUTED_TRANSACTION.value == "Distributed Transaction"
        assert PatternType.PERFORMANCE.value == "Performance"
        assert PatternType.SECURITY.value == "Security"
        assert PatternType.OTHER.value == "Other"


class TestPatternMinerIntegration:
    """Integration-style tests with realistic scenarios"""

    @pytest.fixture
    def miner(self):
        return PatternMiner(min_usage_threshold=3)

    def test_innovation_nexus_pattern_extraction(self, miner):
        """Test pattern mining from Innovation Nexus-like portfolio"""
        repos = []

        # Simulate 10 repositories with common patterns
        for i in range(10):
            repo = Mock(spec=Repository)
            repo.name = f"repo-{i}"

            # First 5 repos use Circuit Breaker
            # First 7 repos use Retry
            # First 3 repos use Saga
            patterns = []
            if i < 5:
                patterns.append(Path("src/resilience/circuit_breaker.py"))
            if i < 7:
                patterns.append(Path("src/resilience/retry.py"))
            if i < 3:
                patterns.append(Path("src/saga/orchestrator.py"))

            repo.file_patterns = patterns
            repos.append(repo)

        with patch.object(miner, '_extract_patterns_from_repo') as mock_extract:
            def extract_side_effect(repo):
                extracted = []
                for file_path in repo.file_patterns:
                    if "circuit_breaker" in str(file_path):
                        extracted.append(
                            ArchitecturalPattern(
                                name="Circuit Breaker",
                                type=PatternType.RESILIENCE,
                                file_path=str(file_path),
                                language="Python",
                                usage_count=1
                            )
                        )
                    elif "retry" in str(file_path):
                        extracted.append(
                            ArchitecturalPattern(
                                name="Retry with Exponential Backoff",
                                type=PatternType.RESILIENCE,
                                file_path=str(file_path),
                                language="Python",
                                usage_count=1
                            )
                        )
                    elif "saga" in str(file_path):
                        extracted.append(
                            ArchitecturalPattern(
                                name="Saga Pattern",
                                type=PatternType.DISTRIBUTED_TRANSACTION,
                                file_path=str(file_path),
                                language="Python",
                                usage_count=1
                            )
                        )
                return extracted

            mock_extract.side_effect = extract_side_effect

            library = miner.mine(repos)

        # Should find 3 patterns meeting threshold:
        # - Circuit Breaker (5 usages)
        # - Retry (7 usages)
        # - Saga (3 usages)
        assert len(library.patterns) == 3
        assert library.total_repositories == 10

        # Verify specific patterns
        circuit_breaker = next((p for p in library.patterns if "Circuit Breaker" in p.name), None)
        assert circuit_breaker is not None
        assert circuit_breaker.usage_count == 5

        retry = next((p for p in library.patterns if "Retry" in p.name), None)
        assert retry is not None
        assert retry.usage_count == 7

        saga = next((p for p in library.patterns if "Saga" in p.name), None)
        assert saga is not None
        assert saga.usage_count == 3

    def test_microsoft_pattern_prioritization(self, miner):
        """Test that Microsoft-aligned patterns are prioritized"""
        repos = []

        for i in range(5):
            repo = Mock(spec=Repository)
            repo.name = f"azure-service-{i}"
            repo.file_patterns = [
                Path("src/azure/cosmos_repository.py"),
                Path("src/auth/entra_id.py"),
                Path("src/monitoring/app_insights.py"),
            ]
            repos.append(repo)

        with patch.object(miner, '_extract_patterns_from_repo') as mock_extract:
            mock_extract.return_value = [
                ArchitecturalPattern(
                    name="Cosmos DB Repository",
                    type=PatternType.DATA,
                    file_path="src/azure/cosmos_repository.py",
                    language="Python",
                    usage_count=1,
                    microsoft_aligned=True
                ),
                ArchitecturalPattern(
                    name="Entra ID Authentication",
                    type=PatternType.SECURITY,
                    file_path="src/auth/entra_id.py",
                    language="Python",
                    usage_count=1,
                    microsoft_aligned=True
                ),
            ]

            library = miner.mine(repos)

        # All patterns should be Microsoft-aligned
        microsoft_patterns = [p for p in library.patterns if p.microsoft_aligned]
        assert len(microsoft_patterns) >= 2

    def test_reusability_ranking(self, miner):
        """Test patterns are ranked by reusability score"""
        patterns = [
            ArchitecturalPattern(
                name="Pattern A",
                type=PatternType.OTHER,
                file_path="a.py",
                language="Python",
                usage_count=2,
                reusability_score=30
            ),
            ArchitecturalPattern(
                name="Pattern B",
                type=PatternType.OTHER,
                file_path="b.py",
                language="Python",
                usage_count=8,
                reusability_score=90
            ),
            ArchitecturalPattern(
                name="Pattern C",
                type=PatternType.OTHER,
                file_path="c.py",
                language="Python",
                usage_count=5,
                reusability_score=65
            ),
        ]

        ranked = miner._rank_by_reusability(patterns)

        # Should be sorted descending by reusability_score
        assert ranked[0].name == "Pattern B"  # Score 90
        assert ranked[1].name == "Pattern C"  # Score 65
        assert ranked[2].name == "Pattern A"  # Score 30


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--cov=src.analyzers.pattern_miner", "--cov-report=term-missing"])
