#!/usr/bin/env python3
"""
Agent Registry Migration Script
Migrates all parsed agents from Database A to Database B with enriched metadata
and comprehensive tools/capabilities assignments
"""

import json
from pathlib import Path

# Load parsed agent metadata
metadata_file = Path('.claude/data/agent-metadata.json')

with open(metadata_file, 'r', encoding='utf-8') as f:
    agents = json.load(f)

# Database B data source ID
DATABASE_B_DATA_SOURCE = "5863265b-eeee-45fc-ab1a-4206d8a523c6"

print(f"Loaded {len(agents)} agents from metadata file")
print("\nGenerating Notion MCP commands for migration...")
print("=" * 80)

# Generate creation commands for each agent
migration_commands = []

for agent in agents:
    # Map invocation pattern
    agent_type = agent['AgentType']

    # Map to Database B Status format (with emoji)
    status_map = {
        'Active': '🟢 Active',
        'Testing': '🔵 Testing',
        'Deprecated': '🟡 Deprecated',
        'Archived': '⚫ Archived'
    }
    status = status_map.get(agent['Status'].replace('🟢 ', '').strip(), '🟢 Active')

    # Prepare properties for Notion page creation
    properties = {
        'Agent Name': agent['Name'],
        'Agent ID': agent['AgentID'],
        'Agent Type': agent_type,
        'Status': status,
        'Primary Specialization': agent['PrimarySpecialization'],
        'Capabilities': agent['Capabilities'],  # Will be JSON array
        'System Prompt': agent['SystemPrompt'],
        'Best Use Cases': agent['BestUseCases'],  # Will be JSON array
        'Documentation URL': f'https://github.com/brookside-bi/notion/blob/main/.claude/agents/{agent["AgentID"]}.md',
        'Notes': f'Auto-migrated from agent file. Model: {agent["Model"]}. Invocation: {agent["InvocationPattern"]}',
    }

    # Create page content with agent documentation
    content = f"""## Role & Purpose
{agent['Description']}

## System Prompt
{agent['SystemPrompt']}

## Tools & Integrations
This agent has access to the following tools:
"""

    for tool in agent['Tools']:
        content += f"\n- **{tool}**: "
        tool_descriptions = {
            'Notion MCP': 'Database operations, page creation/updates, search',
            'GitHub MCP': 'Repository management, file operations, PR/issue creation',
            'Azure MCP': 'Cloud resource provisioning, deployment automation',
            'Playwright': 'Browser automation and web testing',
            'Bash': 'Shell command execution and system operations',
            'Read': 'File reading and analysis',
            'Write': 'File creation and generation',
            'Edit': 'File modification and updates',
            'Grep': 'Code search and pattern matching',
            'Glob': 'File pattern matching and discovery',
            'WebFetch': 'Web content retrieval and documentation lookup'
        }
        content += tool_descriptions.get(tool, 'Tool operations')

    content += f"""

## Primary Capabilities
"""
    for capability in agent['Capabilities']:
        content += f"\n- {capability}"

    content += f"""

## Best Use Cases
"""
    for use_case in agent['BestUseCases']:
        content += f"\n- {use_case}"

    content += f"""

## Invocation
**Agent ID**: `{agent['AgentID']}`
**Invocation Pattern**: {agent['InvocationPattern']}
**Model**: {agent['Model']}

To invoke this agent, use:
```
Task tool with subagent_type="{agent['AgentID']}"
```

## File Location
Source: `.claude/agents/{agent['AgentID']}.md`
GitHub: [View Source](https://github.com/brookside-bi/notion/blob/main/.claude/agents/{agent['AgentID']}.md)

---
*Last Updated*: Auto-generated during Agent Registry consolidation
*Status*: {status}
"""

    migration_command = {
        'agent_name': agent['Name'],
        'properties': properties,
        'content': content,
        'tools': agent['Tools']
    }

    migration_commands.append(migration_command)

# Save migration commands to file for execution
output_file = Path('.claude/data/migration-commands.json')
with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(migration_commands, f, indent=2, ensure_ascii=False)

print(f"\n[SUCCESS] Generated {len(migration_commands)} migration commands")
print(f"[OUTPUT] Saved to: {output_file}")

# Print summary by agent type
print("\n[SUMMARY] Agents by Type:")
type_counts = {}
for agent in agents:
    agent_type = agent['AgentType']
    type_counts[agent_type] = type_counts.get(agent_type, 0) + 1
for agent_type, count in sorted(type_counts.items(), key=lambda x: -x[1]):
    print(f"  {agent_type}: {count} agents")

# Print agent names to be migrated
print("\n[AGENTS] To be migrated:")
for i, cmd in enumerate(migration_commands, 1):
    print(f"  {i:2d}. {cmd['agent_name']:30s} | Tools: {len(cmd['tools'])} | Type: {cmd['properties']['Agent Type']}")

print("\n" + "=" * 80)
print("[NEXT STEP] Execute migration using Notion MCP create-pages tool")
print("=" * 80)
