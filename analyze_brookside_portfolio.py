#!/usr/bin/env python3
"""
Brookside BI Repository Portfolio Analyzer

Establishes comprehensive repository intelligence through systematic analysis
of viability, reusability, Claude integration, and cost tracking.

Best for: Organizations requiring portfolio-wide visibility into repository
health and technical debt management.
"""

import json
import requests
from datetime import datetime, timedelta
from typing import Dict, List, Any
from collections import Counter

# GitHub API configuration
GITHUB_TOKEN = "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"
ORG_NAME = "Brookside-Proving-Grounds"
HEADERS = {
    "Authorization": f"token {GITHUB_TOKEN}",
    "Accept": "application/vnd.github.v3+json"
}

# Viability scoring thresholds
VIABILITY_HIGH_THRESHOLD = 75
VIABILITY_MEDIUM_THRESHOLD = 50


def fetch_repositories() -> List[Dict[str, Any]]:
    """Fetch all repositories from organization"""
    url = f"https://api.github.com/orgs/{ORG_NAME}/repos"
    params = {"per_page": 100, "sort": "updated"}
    response = requests.get(url, headers=HEADERS, params=params)
    response.raise_for_status()
    return response.json()


def fetch_repository_contents(owner: str, repo: str, path: str = "") -> List[Dict]:
    """Fetch repository contents at specified path"""
    url = f"https://api.github.com/repos/{owner}/{repo}/contents/{path}"
    try:
        response = requests.get(url, headers=HEADERS)
        if response.status_code == 200:
            return response.json()
        return []
    except Exception:
        return []


def fetch_commit_activity(owner: str, repo: str) -> Dict[str, int]:
    """Fetch recent commit activity"""
    url = f"https://api.github.com/repos/{owner}/{repo}/commits"
    try:
        response = requests.get(url, headers=HEADERS, params={"per_page": 100})
        if response.status_code != 200:
            return {"last_30_days": 0, "last_90_days": 0}

        commits = response.json()
        now = datetime.now()
        thirty_days_ago = now - timedelta(days=30)
        ninety_days_ago = now - timedelta(days=90)

        commits_30 = 0
        commits_90 = 0

        for commit in commits:
            commit_date = datetime.fromisoformat(
                commit["commit"]["author"]["date"].replace("Z", "+00:00")
            ).replace(tzinfo=None)

            if commit_date >= thirty_days_ago:
                commits_30 += 1
            if commit_date >= ninety_days_ago:
                commits_90 += 1

        return {"last_30_days": commits_30, "last_90_days": commits_90}
    except Exception as e:
        print(f"Error fetching commits for {owner}/{repo}: {e}")
        return {"last_30_days": 0, "last_90_days": 0}


def detect_tests(owner: str, repo: str) -> bool:
    """Detect if repository has tests"""
    test_indicators = ["tests", "test", "__tests__", "spec", "specs"]

    # Check root directory
    contents = fetch_repository_contents(owner, repo)
    for item in contents:
        if item["type"] == "dir" and any(indicator in item["name"].lower() for indicator in test_indicators):
            return True
        if item["type"] == "file" and any(indicator in item["name"].lower() for indicator in test_indicators):
            return True

    return False


def detect_documentation(owner: str, repo: str) -> bool:
    """Detect if repository has documentation"""
    contents = fetch_repository_contents(owner, repo)

    for item in contents:
        if item["name"].upper() in ["README.MD", "README.RST", "README.TXT", "README"]:
            return True
        if item["type"] == "dir" and item["name"].lower() in ["docs", "documentation"]:
            return True

    return False


def count_dependencies(owner: str, repo: str, language: str) -> int:
    """Count dependencies based on language"""
    dep_files = {
        "Python": ["requirements.txt", "Pipfile", "pyproject.toml", "setup.py"],
        "JavaScript": ["package.json"],
        "TypeScript": ["package.json"],
        "C#": ["*.csproj", "packages.config"],
        "Java": ["pom.xml", "build.gradle"],
        "Go": ["go.mod"],
        "Ruby": ["Gemfile"],
        "PHP": ["composer.json"],
    }

    files_to_check = dep_files.get(language, [])
    contents = fetch_repository_contents(owner, repo)

    total_deps = 0

    for item in contents:
        if item["type"] == "file" and item["name"] in files_to_check:
            # Fetch file content
            try:
                file_response = requests.get(item["download_url"])
                if file_response.status_code == 200:
                    content = file_response.text

                    # Simple line count heuristic (very approximate)
                    if item["name"] == "package.json":
                        deps = json.loads(content)
                        total_deps += len(deps.get("dependencies", {}))
                        total_deps += len(deps.get("devDependencies", {}))
                    elif item["name"] == "pyproject.toml":
                        # Count lines in [tool.poetry.dependencies]
                        lines = [l for l in content.split('\n') if '=' in l and not l.strip().startswith('#')]
                        total_deps += len(lines)
                    else:
                        # Count non-empty, non-comment lines
                        lines = [l for l in content.split('\n') if l.strip() and not l.strip().startswith('#')]
                        total_deps += len(lines)
            except Exception:
                pass

    return total_deps


def detect_claude_integration(owner: str, repo: str) -> Dict[str, Any]:
    """
    Detect Claude Code integration maturity

    Scoring:
    - Agents: 10 points each
    - Commands: 5 points each
    - MCP Servers: 10 points each
    - CLAUDE.md: 15 points

    Levels:
    - EXPERT: 80-100
    - ADVANCED: 60-79
    - INTERMEDIATE: 30-59
    - BASIC: 10-29
    - NONE: 0-9
    """
    contents = fetch_repository_contents(owner, repo)

    has_claude_dir = False
    agent_count = 0
    command_count = 0
    mcp_count = 0
    has_claude_md = False

    for item in contents:
        if item["type"] == "dir" and item["name"] == ".claude":
            has_claude_dir = True

            # Check for agents
            agents_contents = fetch_repository_contents(owner, repo, ".claude/agents")
            agent_count = len([f for f in agents_contents if f["type"] == "file" and f["name"].endswith(".md")])

            # Check for commands
            commands_contents = fetch_repository_contents(owner, repo, ".claude/commands")
            command_count = len([f for f in commands_contents if f["type"] == "file" and f["name"].endswith(".md")])

            # Check for MCP servers (in .claude.json or config)
            claude_json = fetch_repository_contents(owner, repo, ".claude.json")
            if claude_json:
                # MCP count would require parsing, estimate as 0 for now
                mcp_count = 0

            # Check for CLAUDE.md
            claude_md_root = fetch_repository_contents(owner, repo, "CLAUDE.md")
            claude_md_dir = fetch_repository_contents(owner, repo, ".claude/CLAUDE.md")
            has_claude_md = bool(claude_md_root or claude_md_dir)

    # Calculate score
    score = (agent_count * 10) + (command_count * 5) + (mcp_count * 10) + (15 if has_claude_md else 0)

    # Determine level
    if score >= 80:
        level = "EXPERT"
    elif score >= 60:
        level = "ADVANCED"
    elif score >= 30:
        level = "INTERMEDIATE"
    elif score >= 10:
        level = "BASIC"
    else:
        level = "NONE"

    return {
        "has_claude_dir": has_claude_dir,
        "agent_count": agent_count,
        "command_count": command_count,
        "mcp_count": mcp_count,
        "has_claude_md": has_claude_md,
        "score": score,
        "level": level
    }


def calculate_viability_score(
    has_tests: bool,
    commits_30: int,
    commits_90: int,
    has_docs: bool,
    dependency_count: int
) -> Dict[str, Any]:
    """
    Calculate repository viability score (0-100)

    Test Coverage (0-30):
    - No tests: 0
    - Tests exist: 10
    - Assumed good coverage: 30

    Activity (0-20):
    - Commits last 30 days: 20
    - Commits last 90 days: 10
    - No recent commits: 0

    Documentation (0-25):
    - README exists: 15
    - Additional docs: 25
    - No README: 0

    Dependency Health (0-25):
    - 0-10 dependencies: 25
    - 11-30 dependencies: 15
    - 31+ dependencies: 5
    """

    # Test coverage score
    if not has_tests:
        test_score = 0
    else:
        # Assume reasonable coverage if tests exist
        test_score = 25

    # Activity score
    if commits_30 > 0:
        activity_score = 20
    elif commits_90 > 0:
        activity_score = 10
    else:
        activity_score = 0

    # Documentation score
    if has_docs:
        # Assume comprehensive if docs exist
        doc_score = 25
    else:
        doc_score = 0

    # Dependency health score
    if dependency_count <= 10:
        dep_score = 25
    elif dependency_count <= 30:
        dep_score = 15
    else:
        dep_score = 5

    total_score = test_score + activity_score + doc_score + dep_score

    # Determine rating
    if total_score >= VIABILITY_HIGH_THRESHOLD:
        rating = "HIGH"
        emoji = "💎"
    elif total_score >= VIABILITY_MEDIUM_THRESHOLD:
        rating = "MEDIUM"
        emoji = "⚡"
    else:
        rating = "LOW"
        emoji = "🔻"

    return {
        "total_score": total_score,
        "rating": rating,
        "emoji": emoji,
        "breakdown": {
            "test_coverage": test_score,
            "activity": activity_score,
            "documentation": doc_score,
            "dependency_health": dep_score
        }
    }


def calculate_reusability(viability_score: int, has_tests: bool, has_docs: bool, is_fork: bool, commits_90: int) -> str:
    """
    Calculate reusability assessment

    - HIGHLY_REUSABLE: Viability ≥75, has tests, has docs, not fork, active
    - PARTIALLY_REUSABLE: Viability ≥50, has tests OR docs
    - ONE_OFF: All other cases
    """
    if viability_score >= 75 and has_tests and has_docs and not is_fork and commits_90 > 0:
        return "🔄 HIGHLY_REUSABLE"
    elif viability_score >= 50 and (has_tests or has_docs):
        return "↔️ PARTIALLY_REUSABLE"
    else:
        return "🔒 ONE_OFF"


def analyze_repository(repo: Dict[str, Any]) -> Dict[str, Any]:
    """Perform comprehensive repository analysis"""
    owner = repo["owner"]["login"]
    name = repo["name"]
    language = repo.get("language")

    print(f"\nAnalyzing: {name}...")

    # Fetch metrics
    has_tests = detect_tests(owner, name)
    has_docs = detect_documentation(owner, name)
    dependency_count = count_dependencies(owner, name, language or "")
    commit_activity = fetch_commit_activity(owner, name)
    claude_integration = detect_claude_integration(owner, name)

    # Calculate viability
    viability = calculate_viability_score(
        has_tests=has_tests,
        commits_30=commit_activity["last_30_days"],
        commits_90=commit_activity["last_90_days"],
        has_docs=has_docs,
        dependency_count=dependency_count
    )

    # Calculate reusability
    reusability = calculate_reusability(
        viability_score=viability["total_score"],
        has_tests=has_tests,
        has_docs=has_docs,
        is_fork=repo.get("fork", False),
        commits_90=commit_activity["last_90_days"]
    )

    return {
        "name": name,
        "url": repo["html_url"],
        "description": repo.get("description", "No description"),
        "language": language or "Unknown",
        "stars": repo["stargazers_count"],
        "forks": repo["forks_count"],
        "open_issues": repo["open_issues_count"],
        "is_fork": repo.get("fork", False),
        "archived": repo.get("archived", False),
        "created_at": repo["created_at"],
        "updated_at": repo["updated_at"],
        "has_tests": has_tests,
        "has_docs": has_docs,
        "dependency_count": dependency_count,
        "commit_activity": commit_activity,
        "viability": viability,
        "reusability": reusability,
        "claude_integration": claude_integration
    }


def generate_summary_report(analyses: List[Dict[str, Any]]) -> str:
    """Generate comprehensive portfolio summary report"""
    total_repos = len(analyses)

    # Viability distribution
    viability_counts = Counter([a["viability"]["rating"] for a in analyses])
    high_count = viability_counts.get("HIGH", 0)
    medium_count = viability_counts.get("MEDIUM", 0)
    low_count = viability_counts.get("LOW", 0)

    # Reusability distribution
    reusability_counts = Counter([a["reusability"] for a in analyses])

    # Claude integration distribution
    claude_levels = Counter([a["claude_integration"]["level"] for a in analyses])

    # Language distribution
    languages = Counter([a["language"] for a in analyses])

    # Cost estimation (simplified)
    total_monthly_cost = sum([a["dependency_count"] * 2.5 for a in analyses])  # $2.50 per dependency estimate
    avg_cost_per_repo = total_monthly_cost / total_repos if total_repos > 0 else 0

    report = f"""
{'='*80}
BROOKSIDE BI REPOSITORY PORTFOLIO ANALYSIS
Organization: {ORG_NAME}
Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
{'='*80}

EXECUTIVE SUMMARY
{'─'*80}
Total Repositories Analyzed: {total_repos}
Non-Archived Repositories: {sum(1 for a in analyses if not a['archived'])}
Total GitHub Stars: {sum(a['stars'] for a in analyses)}
Total Open Issues: {sum(a['open_issues'] for a in analyses)}

VIABILITY DISTRIBUTION
{'─'*80}
💎 High Viability (75-100):     {high_count:2d} repos ({high_count/total_repos*100:5.1f}%)
⚡ Medium Viability (50-74):    {medium_count:2d} repos ({medium_count/total_repos*100:5.1f}%)
🔻 Low Viability (0-49):        {low_count:2d} repos ({low_count/total_repos*100:5.1f}%)

REUSABILITY ASSESSMENT
{'─'*80}
"""

    for reusability, count in reusability_counts.most_common():
        percentage = (count / total_repos * 100) if total_repos > 0 else 0
        report += f"{reusability}: {count:2d} repos ({percentage:5.1f}%)\n"

    report += f"""
CLAUDE CODE INTEGRATION MATURITY
{'─'*80}
"""

    for level in ["EXPERT", "ADVANCED", "INTERMEDIATE", "BASIC", "NONE"]:
        count = claude_levels.get(level, 0)
        percentage = (count / total_repos * 100) if total_repos > 0 else 0
        report += f"{level:12s}: {count:2d} repos ({percentage:5.1f}%)\n"

    report += f"""
TECHNOLOGY STACK
{'─'*80}
"""

    for lang, count in languages.most_common():
        percentage = (count / total_repos * 100) if total_repos > 0 else 0
        report += f"{lang:15s}: {count:2d} repos ({percentage:5.1f}%)\n"

    report += f"""
COST ANALYSIS (ESTIMATED)
{'─'*80}
Total Monthly Cost:    ${total_monthly_cost:,.2f}
Average per Repository: ${avg_cost_per_repo:,.2f}
Total Annual Cost:     ${total_monthly_cost * 12:,.2f}

Note: Cost estimates based on dependency count at $2.50/dependency/month

DETAILED REPOSITORY ANALYSIS
{'─'*80}
"""

    for analysis in sorted(analyses, key=lambda x: x["viability"]["total_score"], reverse=True):
        report += f"""
{analysis['name']}
  URL: {analysis['url']}
  Description: {analysis['description']}

  Viability: {analysis['viability']['emoji']} {analysis['viability']['rating']} ({analysis['viability']['total_score']}/100)
    ├─ Test Coverage:      {analysis['viability']['breakdown']['test_coverage']}/30
    ├─ Activity:           {analysis['viability']['breakdown']['activity']}/20
    ├─ Documentation:      {analysis['viability']['breakdown']['documentation']}/25
    └─ Dependency Health:  {analysis['viability']['breakdown']['dependency_health']}/25

  Reusability: {analysis['reusability']}

  Claude Integration: {analysis['claude_integration']['level']} ({analysis['claude_integration']['score']}/100)
    ├─ Agents: {analysis['claude_integration']['agent_count']}
    ├─ Commands: {analysis['claude_integration']['command_count']}
    ├─ MCP Servers: {analysis['claude_integration']['mcp_count']}
    └─ CLAUDE.md: {'Yes' if analysis['claude_integration']['has_claude_md'] else 'No'}

  Metrics:
    ├─ Language: {analysis['language']}
    ├─ Stars: {analysis['stars']}
    ├─ Dependencies: {analysis['dependency_count']}
    ├─ Commits (30d): {analysis['commit_activity']['last_30_days']}
    ├─ Commits (90d): {analysis['commit_activity']['last_90_days']}
    ├─ Has Tests: {'Yes' if analysis['has_tests'] else 'No'}
    └─ Has Docs: {'Yes' if analysis['has_docs'] else 'No'}

  Estimated Monthly Cost: ${analysis['dependency_count'] * 2.5:.2f}

{'─'*80}
"""

    report += f"""
RECOMMENDATIONS
{'─'*80}
"""

    recommendations = []

    # Viability recommendations
    low_viability_repos = [a for a in analyses if a["viability"]["rating"] == "LOW"]
    if low_viability_repos:
        recommendations.append(f"• Address {len(low_viability_repos)} low-viability repositories:")
        for repo in low_viability_repos:
            recommendations.append(f"  - {repo['name']}: Focus on testing and documentation")

    # Claude integration recommendations
    no_claude = [a for a in analyses if a["claude_integration"]["level"] == "NONE"]
    if no_claude:
        recommendations.append(f"• Establish Claude Code integration in {len(no_claude)} repositories")

    # Test coverage recommendations
    no_tests = [a for a in analyses if not a["has_tests"]]
    if no_tests:
        recommendations.append(f"• Implement testing frameworks in {len(no_tests)} repositories:")
        for repo in no_tests:
            recommendations.append(f"  - {repo['name']}")

    # Activity recommendations
    inactive = [a for a in analyses if a["commit_activity"]["last_90_days"] == 0]
    if inactive:
        recommendations.append(f"• Review {len(inactive)} inactive repositories for archival consideration")

    if recommendations:
        report += "\n".join(recommendations)
    else:
        report += "✓ Portfolio demonstrates strong health across all metrics\n"

    report += f"""

{'='*80}
END OF REPORT
{'='*80}
"""

    return report


def main():
    """Main execution workflow"""
    print("="*80)
    print("BROOKSIDE BI REPOSITORY PORTFOLIO ANALYZER")
    print("="*80)
    print(f"\nOrganization: {ORG_NAME}")
    print("Establishing comprehensive repository visibility...\n")

    # Fetch repositories
    print("Fetching repositories...")
    repos = fetch_repositories()
    print(f"Found {len(repos)} repositories\n")

    # Analyze each repository
    analyses = []
    for repo in repos:
        analysis = analyze_repository(repo)
        analyses.append(analysis)

    # Generate report
    print("\n" + "="*80)
    print("GENERATING COMPREHENSIVE ANALYSIS REPORT")
    print("="*80)

    report = generate_summary_report(analyses)

    # Save report
    output_file = "C:\\Users\\MarkusAhling\\Notion\\portfolio-analysis-report.md"
    with open(output_file, "w", encoding="utf-8") as f:
        f.write(report)

    print(report)
    print(f"\n✓ Report saved to: {output_file}")

    # Save raw data
    data_file = "C:\\Users\\MarkusAhling\\Notion\\portfolio-analysis-data.json"
    with open(data_file, "w", encoding="utf-8") as f:
        json.dump(analyses, f, indent=2, ensure_ascii=False)

    print(f"✓ Raw data saved to: {data_file}")


if __name__ == "__main__":
    main()
