#!/usr/bin/env python3
"""
Convert parsed commands to Notion page creation format for Actions Registry.
"""

import json
from pathlib import Path
from datetime import date

# Load parsed commands
commands_file = Path("c:/Users/MarkusAhling/Notion/.claude/data/parsed-commands.json")
commands = json.loads(commands_file.read_text(encoding='utf-8'))

# Database field mapping to Notion multi-select options
db_mapping = {
    "Ideas Registry": "Ideas",
    "Research Hub": "Research",
    "Example Builds": "Builds",
    "Software & Cost Tracker": "Software",
    "Software Tracker": "Software",
    "Knowledge Vault": "Knowledge",
    "Integration Registry": "Integration",
    "OKRs": "OKRs",
    "Agent Registry": "Agents",
    "Actions Registry": "Actions",
    "Agent Activity Hub": "Agents",
    "Output Styles Registry": "Agents"
}

# Convert commands to Notion page format
pages = []
for cmd in commands:
    # Map related databases to Notion multi-select options
    related_dbs = []
    for db_text in cmd.get("RelatedDatabases", []):
        # Clean up the database text
        for key, value in db_mapping.items():
            if key in db_text:
                if value not in related_dbs:
                    related_dbs.append(value)
                break

    # Format as JSON for Notion multi-select
    related_dbs_str = json.dumps(related_dbs) if related_dbs else "[]"

    # Create page properties
    page = {
        "properties": {
            "Name": f"/{cmd['Name']}",
            "Category": cmd["Category"],
            "Description": cmd["Description"][:2000] if cmd["Description"] else "",  # Limit to 2000 chars
            "Parameters": cmd["ArgumentHint"],
            "Status": "Active",
            "Example Usage": f"/{cmd['Name']} {cmd['ArgumentHint']}" if cmd["ArgumentHint"] else f"/{cmd['Name']}",
            "Related Databases": related_dbs_str,
            "date:Last Updated:start": str(date.today()),
            "date:Last Updated:is_datetime": 0
        }
    }

    pages.append(page)

# Save to JSON for use with Notion MCP
output_file = Path("c:/Users/MarkusAhling/Notion/.claude/data/notion-pages-to-create.json")
output_file.write_text(json.dumps(pages, indent=2), encoding='utf-8')

print(f"Prepared {len(pages)} pages for creation")
print(f"Output saved to: {output_file}")

# Show summary
print(f"\nCategories:")
from collections import Counter
categories = Counter(p["properties"]["Category"] for p in pages)
for cat, count in sorted(categories.items(), key=lambda x: x[1], reverse=True):
    print(f"  {cat}: {count}")
