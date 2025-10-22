#!/usr/bin/env python3
"""
Execute Agent Registry Migration in Batches
Creates formatted Notion MCP payloads for batch migration
"""

import json
from pathlib import Path

# Load migration commands
migration_file = Path('.claude/data/migration-commands.json')
with open(migration_file, 'r', encoding='utf-8') as f:
    commands = json.load(f)

# Database B data source ID
DATA_SOURCE_ID = "5863265b-eeee-45fc-ab1a-4206d8a523c6"

# Batch size
BATCH_SIZE = 10

print(f"Loaded {len(commands)} agents for migration")
print(f"Creating {(len(commands) + BATCH_SIZE - 1) // BATCH_SIZE} batches of max {BATCH_SIZE} agents each\n")

# Create batches
batches = [commands[i:i + BATCH_SIZE] for i in range(0, len(commands), BATCH_SIZE)]

# Create output directory
output_dir = Path('.claude/data/migration-batches')
output_dir.mkdir(parents=True, exist_ok=True)

for batch_num, batch in enumerate(batches, 1):
    print(f"Creating Batch {batch_num} ({len(batch)} agents)...")

    # Format pages for Notion MCP
    pages = []
    for cmd in batch:
        page = {
            'properties': {},
            'content': cmd['content']
        }

        # Map properties to Notion format
        props = cmd['properties']
        page['properties']['Agent Name'] = props['Agent Name']
        page['properties']['Agent ID'] = props['Agent ID']
        page['properties']['Agent Type'] = props['Agent Type']
        page['properties']['Status'] = props['Status']
        page['properties']['Primary Specialization'] = props['Primary Specialization']
        page['properties']['Capabilities'] = json.dumps(props['Capabilities'])  # Multi-select as JSON string
        page['properties']['System Prompt'] = props['System Prompt']
        page['properties']['Best Use Cases'] = json.dumps(props['Best Use Cases'])  # Multi-select as JSON string
        page['properties']['Documentation URL'] = props['Documentation URL']
        page['properties']['Notes'] = props['Notes']

        pages.append(page)

    # Create batch payload
    batch_payload = {
        'parent': {
            'type': 'data_source_id',
            'data_source_id': DATA_SOURCE_ID
        },
        'pages': pages
    }

    # Save batch to file
    batch_file = output_dir / f'batch-{batch_num:02d}.json'
    with open(batch_file, 'w', encoding='utf-8') as f:
        json.dump(batch_payload, f, indent=2, ensure_ascii=False)

    print(f"  Saved to: {batch_file}")
    print(f"  Agents: {', '.join([p['properties']['Agent Name'] for p in pages])}")
    print()

print("=" * 80)
print(f"[SUCCESS] Created {len(batches)} batch files")
print(f"[LOCATION] {output_dir}")
print("=" * 80)
print("\n[NEXT STEPS]")
print("Execute each batch using Notion MCP notion-create-pages tool")
print("Example: Pass batch-01.json content to notion-create-pages")
print("=" * 80)
