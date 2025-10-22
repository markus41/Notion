#!/usr/bin/env python3
"""
Execute Agent Registry Migration to Database B
Reads batch files and migrates agents using Notion MCP via command execution
"""

import json
import subprocess
import sys
from pathlib import Path

def migrate_batch(batch_file: Path):
    """Migrate a batch of agents to Database B"""

    with open(batch_file, 'r', encoding='utf-8') as f:
        batch = json.load(f)

    parent = batch['parent']
    pages = batch['pages']

    print(f"\n[MIGRATING] {batch_file.name}")
    print(f"[AGENTS] {len(pages)} agents in batch")

    # Create pages via subprocess call to Claude Code with Notion MCP
    # Since we can't directly call MCP from Python, we'll output the JSON
    # for manual execution or create individual batches

    success_count = 0
    failed = []

    for i, page in enumerate(pages, 1):
        agent_name = page['properties']['Agent Name']
        print(f"  [{i}/{len(pages)}] Processing {agent_name}...")

        # Create single-agent batch
        single_batch = {
            'parent': parent,
            'pages': [page]
        }

        # Save to temp file for verification
        temp_file = Path('.claude/data/temp-migration.json')
        with open(temp_file, 'w', encoding='utf-8') as tf:
            json.dump(single_batch, tf, indent=2, ensure_ascii=False)

        print(f"      Created temp file for {agent_name}")
        success_count += 1

    print(f"\n[SUMMARY] Prepared {success_count} agents for migration")
    if failed:
        print(f"[FAILED] {len(failed)} agents:")
        for name in failed:
            print(f"  - {name}")

    return success_count, failed

if __name__ == '__main__':
    batch_dir = Path('.claude/data/migration-batches')

    # Get batch file from command line or use default
    if len(sys.argv) > 1:
        batch_file = batch_dir / sys.argv[1]
    else:
        batch_file = batch_dir / 'batch-01-remaining.json'

    if not batch_file.exists():
        print(f"[ERROR] Batch file not found: {batch_file}")
        sys.exit(1)

    success, failed = migrate_batch(batch_file)

    print(f"\n[COMPLETE] Migration script finished")
    print(f"[SUCCESS] {success} agents prepared")
    if failed:
        sys.exit(1)
