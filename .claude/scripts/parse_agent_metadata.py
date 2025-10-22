#!/usr/bin/env python3
"""
Parse Agent Metadata Script
Establishes comprehensive metadata extraction from agent definition files
to streamline Agent Registry population with accurate tool assignments and capabilities
"""

import os
import re
import json
from pathlib import Path
from typing import Dict, List, Any

def parse_agent_file(file_path: Path) -> Dict[str, Any]:
    """Parse a single agent markdown file and extract metadata"""

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Extract YAML frontmatter
    frontmatter_match = re.match(r'^---\s*\n(.*?)\n---\s*\n(.*)$', content, re.DOTALL)
    if not frontmatter_match:
        return None

    frontmatter = frontmatter_match.group(1)
    body = frontmatter_match.group(2)

    # Parse name
    name_match = re.search(r'name:\s*(.+)', frontmatter)
    name = name_match.group(1).strip() if name_match else file_path.stem

    # Parse description
    desc_match = re.search(r'description:\s*(.+?)(?=\n\w+:|$)', frontmatter, re.DOTALL)
    description = re.sub(r'\s+', ' ', desc_match.group(1).strip()) if desc_match else ""

    # Parse model
    model_match = re.search(r'model:\s*(.+)', frontmatter)
    model = model_match.group(1).strip() if model_match else "sonnet"

    # Extract first 200 words for System Prompt
    body_clean = re.sub(r'<[^>]+>', '', body)
    words = [w for w in body_clean.split() if w]
    system_prompt = ' '.join(words[:200])
    if len(system_prompt) > 500:
        system_prompt = system_prompt[:497] + "..."

    # Detect tools from description and content
    tools = []
    tool_keywords = {
        'Notion MCP': ['notion', 'database', 'page', 'Ideas Registry', 'Research Hub', 'Example Builds', 'Software Tracker', 'Knowledge Vault'],
        'GitHub MCP': ['github', 'repository', 'repo', 'commit', 'pull request', 'branch'],
        'Azure MCP': ['azure', 'App Service', 'Function', 'SQL', 'deployment', 'infrastructure', 'Bicep'],
        'Playwright': ['playwright', 'browser', 'web automation', 'testing'],
        'Bash': ['bash', 'shell', 'command', 'script', 'execute'],
        'Read': ['read file', 'analyze', 'parse', 'examine'],
        'Write': ['write file', 'create file', 'generate file'],
        'Edit': ['edit file', 'modify', 'update file'],
        'Grep': ['search', 'find', 'grep', 'pattern'],
        'Glob': ['glob', 'file pattern', 'match files'],
        'WebFetch': ['web', 'fetch', 'http', 'URL', 'documentation', 'research online']
    }

    combined_text = (description + ' ' + body).lower()
    for tool, keywords in tool_keywords.items():
        if any(keyword.lower() in combined_text for keyword in keywords):
            if tool not in tools:
                tools.append(tool)

    # Determine Agent Type
    agent_type = "Specialized"
    if re.search(r'orchestrat|coordinat|router', name, re.I):
        agent_type = "Orchestrator"
    elif re.search(r'style|meta', name, re.I):
        agent_type = "Meta-Agent"
    elif re.search(r'expert|specialist', name, re.I) and 'specialized' not in description.lower():
        agent_type = "Utility"

    # Determine Primary Specialization
    specialization = "Engineering"
    if re.search(r'cost|budget|financial', name, re.I):
        specialization = "Business"
    elif re.search(r'research|market|viability', name, re.I):
        specialization = "Research"
    elif re.search(r'architecture|architect|design', name, re.I):
        specialization = "Architecture"
    elif re.search(r'deploy|infra|ops|monitor', name, re.I):
        specialization = "DevOps"
    elif re.search(r'security|compliance|risk', name, re.I):
        specialization = "Security"
    elif re.search(r'data|database|schema', name, re.I):
        specialization = "Data"
    elif re.search(r'ai|ml|openai', name, re.I):
        specialization = "AI/ML"

    # Determine Capabilities
    capabilities = []
    if re.search(r'code|generate|develop|build', combined_text, re.I):
        capabilities.append("Code Generation")
    if re.search(r'architect|design|system|pattern', combined_text, re.I):
        capabilities.append("System Design")
    if re.search(r'document|markdown|write|content', combined_text, re.I):
        capabilities.append("Documentation")
    if re.search(r'test|validate|verify|quality', combined_text, re.I):
        capabilities.append("Testing")
    if re.search(r'troubleshoot|debug|diagnose|fix', combined_text, re.I):
        capabilities.append("Troubleshooting")
    if re.search(r'analy|assess|evaluat|review', combined_text, re.I):
        capabilities.append("Analysis")
    if re.search(r'plan|strategy|organize|coordinate', combined_text, re.I):
        capabilities.append("Planning")
    if re.search(r'orchestrat|coordinate|route|workflow', combined_text, re.I):
        capabilities.append("Orchestration")
    if re.search(r'style|format|transform', combined_text, re.I):
        capabilities.append("Style Transformation")

    # Determine Best Use Cases
    best_use_cases = []
    if specialization in ["Engineering", "AI/ML", "DevOps"]:
        best_use_cases.append("Code Development")
    if specialization in ["Architecture", "DevOps"]:
        best_use_cases.append("System Architecture")
    if "Documentation" in capabilities:
        best_use_cases.append("Documentation")
    if specialization == "Research":
        best_use_cases.append("Research")
    if re.search(r'compliance|audit|security', name, re.I):
        best_use_cases.append("Compliance")
    if re.search(r'troubleshoot|fix|debug', name, re.I):
        best_use_cases.append("Troubleshooting")
    if re.search(r'plan|architect|strategy', name, re.I):
        best_use_cases.append("Planning")

    # Determine Invocation Pattern
    invocation_pattern = "On-Demand"
    if re.search(r'proactive|automatic|autonomous|monitor', description, re.I):
        invocation_pattern = "Proactive"
    elif re.search(r'multi-agent|workflow|swarm|parallel', description, re.I):
        invocation_pattern = "Multi-Agent Workflow"

    return {
        'Name': f'@{name}',
        'AgentID': name,
        'FilePath': str(file_path),
        'Description': description,
        'Model': model,
        'SystemPrompt': system_prompt,
        'Tools': tools,
        'AgentType': agent_type,
        'PrimarySpecialization': specialization,
        'Capabilities': capabilities,
        'BestUseCases': best_use_cases,
        'Status': '🟢 Active',
        'InvocationPattern': invocation_pattern
    }

def main():
    agent_dir = Path('.claude/agents')
    output_file = Path('.claude/data/agent-metadata.json')

    print("Parsing Agent Metadata from .claude/agents/...")

    agents = []
    agent_files = sorted(agent_dir.glob('*.md'))

    for file_path in agent_files:
        print(f"  Processing: {file_path.stem}...")
        metadata = parse_agent_file(file_path)
        if metadata:
            agents.append(metadata)

    # Ensure output directory exists
    output_file.parent.mkdir(parents=True, exist_ok=True)

    # Export to JSON
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(agents, f, indent=2, ensure_ascii=False)

    print(f"\n[SUCCESS] Parsed {len(agents)} agents successfully!")
    print(f"[OUTPUT] Saved to: {output_file}")

    # Display summary
    print("\n[SUMMARY] By Specialization:")
    spec_counts = {}
    for agent in agents:
        spec = agent['PrimarySpecialization']
        spec_counts[spec] = spec_counts.get(spec, 0) + 1
    for spec, count in sorted(spec_counts.items(), key=lambda x: -x[1]):
        print(f"  {spec}: {count} agents")

    print("\n[SUMMARY] By Tools:")
    tool_counts = {}
    for agent in agents:
        for tool in agent['Tools']:
            tool_counts[tool] = tool_counts.get(tool, 0) + 1
    for tool, count in sorted(tool_counts.items(), key=lambda x: -x[1]):
        print(f"  {tool}: {count} agents")

if __name__ == '__main__':
    main()
