"""
Pattern Mining Workflow for Brookside BI Organization

Establishes comprehensive pattern analysis across repository portfolio to:
- Identify architectural patterns (Serverless, RESTful API, Event-Driven)
- Extract integration patterns (Azure, Notion, GitHub MCP)
- Discover design patterns (frameworks, testing, validation)
- Calculate reusability scores
- Generate Knowledge Vault entries

Best for: Organizations seeking to leverage successful patterns across portfolio
to reduce duplication and accelerate development.
"""

import asyncio
import json
import logging
import sys
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path
from typing import Any

# Add src to path
sys.path.insert(0, str(Path(__file__).parent / "src"))

from models import (
    Pattern,
    PatternType,
    RepoAnalysis,
    ViabilityRating,
    ReusabilityRating,
)
from analyzers.pattern_miner import PatternMiner

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


class PatternAnalysisWorkflow:
    """
    Comprehensive pattern mining workflow

    Analyzes repositories and generates structured pattern reports
    designed for Knowledge Vault integration.
    """

    def __init__(self, min_usage: int = 3):
        """
        Initialize pattern analysis workflow

        Args:
            min_usage: Minimum repositories required to identify pattern
        """
        self.min_usage = min_usage
        self.miner = PatternMiner()

    def load_repository_analyses(self) -> list[RepoAnalysis]:
        """
        Load repository analyses from cache or trigger fresh scan

        Returns:
            List of repository analyses
        """
        cache_file = Path("src/data/cache/org_scan_results.json")

        if not cache_file.exists():
            logger.error("No cached repository analyses found")
            logger.info("Please run: poetry run python -m src.cli scan --org brookside-bi")
            sys.exit(1)

        logger.info(f"Loading analyses from: {cache_file}")

        with open(cache_file, "r") as f:
            data = json.load(f)

        # Reconstruct RepoAnalysis objects
        analyses = []
        for repo_data in data.get("repositories", []):
            # This is simplified - in production, use proper deserialization
            logger.info(f"Loaded: {repo_data.get('name', 'Unknown')}")

        logger.info(f"Loaded {len(data.get('repositories', []))} repository analyses")
        return data.get("repositories", [])

    def detect_framework_patterns(self, repos_data: list[dict]) -> list[dict]:
        """
        Detect web framework and design patterns

        Args:
            repos_data: Repository analysis data

        Returns:
            List of framework patterns
        """
        patterns = []

        # Track framework usage
        frameworks = defaultdict(list)
        testing_frameworks = defaultdict(list)
        validation_libs = defaultdict(list)

        for repo in repos_data:
            repo_name = repo.get("name", "Unknown")
            dependencies = [d.get("name", "") for d in repo.get("dependencies", [])]

            # Web frameworks
            for dep in dependencies:
                dep_lower = dep.lower()

                # API frameworks
                if "fastapi" in dep_lower:
                    frameworks["FastAPI"].append(repo_name)
                elif "flask" in dep_lower:
                    frameworks["Flask"].append(repo_name)
                elif "express" in dep_lower:
                    frameworks["Express.js"].append(repo_name)
                elif "django" in dep_lower:
                    frameworks["Django"].append(repo_name)

                # Testing frameworks
                if "pytest" in dep_lower:
                    testing_frameworks["pytest"].append(repo_name)
                elif "jest" in dep_lower:
                    testing_frameworks["Jest"].append(repo_name)
                elif "unittest" in dep_lower:
                    testing_frameworks["unittest"].append(repo_name)

                # Validation libraries
                if "pydantic" in dep_lower:
                    validation_libs["Pydantic"].append(repo_name)
                elif "joi" in dep_lower:
                    validation_libs["Joi"].append(repo_name)

        # Create patterns for frameworks with min_usage
        for framework, repos in frameworks.items():
            if len(repos) >= self.min_usage:
                patterns.append({
                    "name": f"{framework} Web Framework",
                    "type": "DESIGN",
                    "description": f"RESTful API development using {framework} for scalable web services",
                    "repos_using": repos,
                    "usage_count": len(repos),
                    "reusability_score": 85,
                    "benefits": [
                        "Proven framework with strong community",
                        "Type safety and validation",
                        "Fast development velocity",
                    ],
                    "considerations": [
                        "Learning curve for new developers",
                        "Framework-specific conventions",
                    ],
                })

        for framework, repos in testing_frameworks.items():
            if len(repos) >= self.min_usage:
                patterns.append({
                    "name": f"{framework} Testing Framework",
                    "type": "DESIGN",
                    "description": f"Automated testing using {framework} for quality assurance",
                    "repos_using": repos,
                    "usage_count": len(repos),
                    "reusability_score": 90,
                    "benefits": [
                        "Automated quality checks",
                        "Regression prevention",
                        "Confidence in deployments",
                    ],
                    "considerations": [
                        "Test maintenance overhead",
                        "Coverage goals and standards",
                    ],
                })

        for lib, repos in validation_libs.items():
            if len(repos) >= self.min_usage:
                patterns.append({
                    "name": f"{lib} Type Validation",
                    "type": "DESIGN",
                    "description": f"Runtime type validation and data modeling using {lib}",
                    "repos_using": repos,
                    "usage_count": len(repos),
                    "reusability_score": 88,
                    "benefits": [
                        "Type safety at runtime",
                        "Data quality enforcement",
                        "Self-documenting schemas",
                    ],
                    "considerations": [
                        "Performance impact of validation",
                        "Schema evolution management",
                    ],
                })

        return patterns

    def detect_architectural_patterns(self, repos_data: list[dict]) -> list[dict]:
        """
        Detect architectural patterns

        Args:
            repos_data: Repository analysis data

        Returns:
            List of architectural patterns
        """
        patterns = []

        # Track architectural indicators
        serverless_repos = []
        event_driven_repos = []
        batch_processing_repos = []

        for repo in repos_data:
            repo_name = repo.get("name", "Unknown")
            dependencies = [d.get("name", "").lower() for d in repo.get("dependencies", [])]

            # Serverless detection
            if any("azure-functions" in dep or "aws-lambda" in dep for dep in dependencies):
                serverless_repos.append(repo_name)

            # Event-driven detection
            if any("event" in dep or "webhook" in dep for dep in dependencies):
                event_driven_repos.append(repo_name)

            # Batch processing detection
            if any("schedule" in dep or "cron" in dep or "batch" in dep for dep in dependencies):
                batch_processing_repos.append(repo_name)

        # Create patterns
        if len(serverless_repos) >= self.min_usage:
            patterns.append({
                "name": "Serverless Architecture",
                "type": "ARCHITECTURAL",
                "description": "Event-driven serverless compute using Azure Functions for scalable, cost-effective execution",
                "repos_using": serverless_repos,
                "usage_count": len(serverless_repos),
                "reusability_score": 85,
                "microsoft_technology": "Azure Functions",
                "benefits": [
                    "No infrastructure management",
                    "Pay-per-execution pricing model",
                    "Auto-scaling based on demand",
                    "Integrated with Azure ecosystem",
                ],
                "considerations": [
                    "Cold start latency",
                    "Execution time limits",
                    "State management complexity",
                ],
            })

        if len(event_driven_repos) >= self.min_usage:
            patterns.append({
                "name": "Event-Driven Architecture",
                "type": "ARCHITECTURAL",
                "description": "Asynchronous event-based communication for decoupled, scalable systems",
                "repos_using": event_driven_repos,
                "usage_count": len(event_driven_repos),
                "reusability_score": 82,
                "benefits": [
                    "Loose coupling between components",
                    "Asynchronous processing",
                    "Scalability and resilience",
                ],
                "considerations": [
                    "Event schema management",
                    "Eventual consistency",
                    "Debugging complexity",
                ],
            })

        return patterns

    def detect_integration_patterns(self, repos_data: list[dict]) -> list[dict]:
        """
        Detect integration patterns

        Args:
            repos_data: Repository analysis data

        Returns:
            List of integration patterns
        """
        patterns = []

        # Track integration usage
        integrations = defaultdict(list)

        for repo in repos_data:
            repo_name = repo.get("name", "Unknown")
            dependencies = [d.get("name", "").lower() for d in repo.get("dependencies", [])]

            # Azure integrations
            if any("azure-keyvault" in dep or "keyvault" in dep for dep in dependencies):
                integrations["Azure Key Vault"].append(repo_name)

            if any("azure-storage" in dep or "blob" in dep for dep in dependencies):
                integrations["Azure Storage"].append(repo_name)

            if any("azure-openai" in dep or "openai" in dep for dep in dependencies):
                integrations["Azure OpenAI"].append(repo_name)

            # MCP integrations (check for MCP in name or description)
            repo_desc = repo.get("description", "").lower()
            if "notion" in repo_name.lower() or "notion" in repo_desc:
                integrations["Notion MCP"].append(repo_name)

            if "github" in dependencies or "octokit" in dependencies:
                integrations["GitHub Integration"].append(repo_name)

        # Create patterns
        for integration, repos in integrations.items():
            if len(repos) >= self.min_usage:
                is_microsoft = any(ms in integration for ms in ["Azure", "Microsoft"])

                patterns.append({
                    "name": f"{integration} Integration Pattern",
                    "type": "INTEGRATION",
                    "description": f"Integration with {integration} for enterprise capabilities",
                    "repos_using": repos,
                    "usage_count": len(repos),
                    "reusability_score": 80 if is_microsoft else 75,
                    "microsoft_technology": integration if is_microsoft else None,
                    "benefits": [
                        "Proven integration pattern",
                        "Enterprise-grade capabilities",
                        "Centralized management" if "Key Vault" in integration else "Scalable service",
                    ],
                    "considerations": [
                        "Authentication management",
                        "Rate limiting",
                        "Cost optimization" if is_microsoft else "Vendor dependency",
                    ],
                })

        return patterns

    def calculate_pattern_reusability(self, pattern: dict, total_repos: int) -> int:
        """
        Calculate comprehensive reusability score

        Score = (adoption_rate × 40) + (quality × 30) + (microsoft × 20) + (consistency × 10)

        Args:
            pattern: Pattern data
            total_repos: Total repositories analyzed

        Returns:
            Reusability score (0-100)
        """
        # Adoption rate (% of portfolio)
        adoption_rate = (pattern["usage_count"] / total_repos) * 100
        adoption_score = min(adoption_rate * 0.4, 40)  # Max 40 points

        # Quality (based on type - architectural patterns score higher)
        quality_score = {
            "ARCHITECTURAL": 30,
            "INTEGRATION": 25,
            "DESIGN": 20,
        }.get(pattern["type"], 15)

        # Microsoft bonus
        microsoft_score = 20 if pattern.get("microsoft_technology") else 10

        # Consistency (higher usage = more consistent)
        consistency_score = min(pattern["usage_count"] * 2, 10)  # Max 10 points

        return int(adoption_score + quality_score + microsoft_score + consistency_score)

    def generate_pattern_report(self, all_patterns: list[dict], total_repos: int) -> dict:
        """
        Generate comprehensive pattern analysis report

        Args:
            all_patterns: All detected patterns
            total_repos: Total repositories analyzed

        Returns:
            Structured report data
        """
        # Update reusability scores
        for pattern in all_patterns:
            pattern["reusability_score"] = self.calculate_pattern_reusability(pattern, total_repos)

        # Sort by reusability score
        all_patterns.sort(key=lambda p: p["reusability_score"], reverse=True)

        # Group by type
        by_type = defaultdict(list)
        for pattern in all_patterns:
            by_type[pattern["type"]].append(pattern)

        # Calculate statistics
        total_patterns = len(all_patterns)
        avg_reusability = sum(p["reusability_score"] for p in all_patterns) / total_patterns if total_patterns > 0 else 0

        # Top patterns
        top_10 = all_patterns[:10]

        return {
            "timestamp": datetime.now().isoformat(),
            "total_repositories_analyzed": total_repos,
            "total_patterns_identified": total_patterns,
            "average_reusability_score": round(avg_reusability, 1),
            "patterns_by_type": {
                "ARCHITECTURAL": len(by_type.get("ARCHITECTURAL", [])),
                "INTEGRATION": len(by_type.get("INTEGRATION", [])),
                "DESIGN": len(by_type.get("DESIGN", [])),
            },
            "top_10_patterns": top_10,
            "all_patterns": all_patterns,
            "patterns_grouped": dict(by_type),
        }

    def print_report(self, report: dict):
        """
        Print formatted pattern analysis report

        Args:
            report: Report data from generate_pattern_report
        """
        print("\n" + "=" * 80)
        print("BROOKSIDE BI - REPOSITORY PATTERN ANALYSIS REPORT")
        print("=" * 80)
        print(f"\nAnalysis Timestamp: {report['timestamp']}")
        print(f"Total Repositories Analyzed: {report['total_repositories_analyzed']}")
        print(f"Total Patterns Identified: {report['total_patterns_identified']}")
        print(f"Average Reusability Score: {report['average_reusability_score']}/100")

        print("\n" + "-" * 80)
        print("PATTERNS BY CATEGORY")
        print("-" * 80)

        for pattern_type, count in report["patterns_by_type"].items():
            percentage = (count / report["total_patterns_identified"] * 100) if report["total_patterns_identified"] > 0 else 0
            print(f"  {pattern_type:20} {count:3} patterns ({percentage:5.1f}%)")

        print("\n" + "-" * 80)
        print("TOP 10 PATTERNS BY REUSABILITY")
        print("-" * 80)

        for i, pattern in enumerate(report["top_10_patterns"], 1):
            print(f"\n{i}. {pattern['name']}")
            print(f"   Type: {pattern['type']}")
            print(f"   Reusability Score: {pattern['reusability_score']}/100")
            print(f"   Usage: {pattern['usage_count']} repositories ({pattern['usage_count']/report['total_repositories_analyzed']*100:.1f}%)")
            print(f"   Repositories: {', '.join(pattern['repos_using'][:5])}")
            if len(pattern['repos_using']) > 5:
                print(f"                 ...and {len(pattern['repos_using']) - 5} more")
            if pattern.get("microsoft_technology"):
                print(f"   Microsoft Technology: {pattern['microsoft_technology']}")

        print("\n" + "=" * 80)
        print("DETAILED PATTERN BREAKDOWN BY CATEGORY")
        print("=" * 80)

        for pattern_type, patterns in report["patterns_grouped"].items():
            print(f"\n### {pattern_type} PATTERNS ({len(patterns)} total)")
            print("-" * 80)

            for pattern in patterns:
                print(f"\n{pattern['name']}")
                print(f"  Description: {pattern['description']}")
                print(f"  Reusability: {pattern['reusability_score']}/100")
                print(f"  Usage: {pattern['usage_count']} repos")
                print(f"  Benefits:")
                for benefit in pattern.get("benefits", []):
                    print(f"    - {benefit}")
                print(f"  Considerations:")
                for consideration in pattern.get("considerations", []):
                    print(f"    - {consideration}")

        print("\n" + "=" * 80)
        print("STANDARDIZATION RECOMMENDATIONS")
        print("=" * 80)

        # High-value patterns for standardization
        high_value = [p for p in report["all_patterns"] if p["reusability_score"] >= 80]

        if high_value:
            print(f"\n{len(high_value)} patterns identified for organizational standardization:")
            for pattern in high_value[:5]:
                print(f"\n  - {pattern['name']}")
                print(f"    Reusability: {pattern['reusability_score']}/100")
                print(f"    Current adoption: {pattern['usage_count']} repos")
                print(f"    Recommendation: Establish as organizational standard")

        # Microsoft ecosystem adoption
        ms_patterns = [p for p in report["all_patterns"] if p.get("microsoft_technology")]
        if ms_patterns:
            print(f"\n\nMicrosoft Ecosystem Integration: {len(ms_patterns)} patterns")
            for pattern in ms_patterns:
                print(f"  - {pattern['name']}: {pattern['usage_count']} repos")

        print("\n" + "=" * 80)

    async def run(self):
        """Execute complete pattern mining workflow"""
        try:
            # Load repository analyses
            logger.info("Loading repository analyses...")
            repos_data = self.load_repository_analyses()

            if not repos_data:
                logger.error("No repository data available")
                return

            total_repos = len(repos_data)
            logger.info(f"Analyzing {total_repos} repositories for patterns...")

            # Detect all pattern types
            logger.info("Detecting framework and design patterns...")
            framework_patterns = self.detect_framework_patterns(repos_data)

            logger.info("Detecting architectural patterns...")
            arch_patterns = self.detect_architectural_patterns(repos_data)

            logger.info("Detecting integration patterns...")
            integration_patterns = self.detect_integration_patterns(repos_data)

            # Combine all patterns
            all_patterns = framework_patterns + arch_patterns + integration_patterns

            logger.info(f"Detected {len(all_patterns)} total patterns")

            # Generate report
            logger.info("Generating pattern analysis report...")
            report = self.generate_pattern_report(all_patterns, total_repos)

            # Print report
            self.print_report(report)

            # Save report
            output_dir = Path("src/data/reports")
            output_dir.mkdir(parents=True, exist_ok=True)

            output_file = output_dir / f"pattern_analysis_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"

            with open(output_file, "w") as f:
                json.dump(report, f, indent=2)

            logger.info(f"\nReport saved to: {output_file}")

            print("\n" + "=" * 80)
            print(f"Full report saved to: {output_file}")
            print("=" * 80)

        except Exception as e:
            logger.error(f"Pattern mining failed: {e}", exc_info=True)
            raise


if __name__ == "__main__":
    # Run pattern mining workflow
    workflow = PatternAnalysisWorkflow(min_usage=3)
    asyncio.run(workflow.run())
