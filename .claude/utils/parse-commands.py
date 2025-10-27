#!/usr/bin/env python3
"""
Parse all command files and extract metadata for Actions Registry registration.
This script establishes structured command metadata extraction to support META self-documentation.
"""

import json
import re
from pathlib import Path

commands_path = Path("c:/Users/MarkusAhling/Notion/.claude/commands")
commands = []

# Get all command files (exclude READMEs and summaries)
files = [f for f in commands_path.rglob("*.md")
         if not re.search(r"README|SUMMARY", f.name)]

print(f"Processing {len(files)} command files...")

for file in files:
    content = file.read_text(encoding='utf-8')

    # Extract category from folder path
    relative_path = file.relative_to(commands_path)
    category = relative_path.parts[0] if len(relative_path.parts) > 1 else "Uncategorized"

    # Initialize command object
    cmd = {
        "FilePath": str(file),
        "Category": category.capitalize(),
        "Name": "",
        "Description": "",
        "ArgumentHint": "",
        "AllowedTools": "",
        "Model": "claude-sonnet-4-5-20250929",
        "RelatedDatabases": []
    }

    # Extract frontmatter if exists
    frontmatter_match = re.match(r'^---\s*\n(.*?)\n---', content, re.DOTALL)
    if frontmatter_match:
        frontmatter = frontmatter_match.group(1)

        # Parse YAML-like frontmatter
        for line in frontmatter.split('\n'):
            if match := re.match(r'^\s*name:\s*(.+)$', line):
                cmd["Name"] = match.group(1).strip()
            elif match := re.match(r'^\s*description:\s*(.+)$', line):
                cmd["Description"] = match.group(1).strip()
            elif match := re.match(r'^\s*argument-hint:\s*(.+)$', line):
                cmd["ArgumentHint"] = match.group(1).strip()
            elif match := re.match(r'^\s*allowed-tools:\s*(.+)$', line):
                cmd["AllowedTools"] = match.group(1).strip()
            elif match := re.match(r'^\s*model:\s*(.+)$', line):
                cmd["Model"] = match.group(1).strip()

    # If no name in frontmatter, try to extract from heading
    if not cmd["Name"]:
        if match := re.search(r'#\s+/([a-z0-9\-:]+)', content):
            cmd["Name"] = match.group(1)
        else:
            # Fallback to filename
            cmd["Name"] = f"{category}:{file.stem}"

    # If no description, try to extract from first paragraph after heading
    if not cmd["Description"]:
        lines = content.split('\n')
        in_frontmatter = False
        found_heading = False

        for line in lines:
            if re.match(r'^---\s*$', line):
                in_frontmatter = not in_frontmatter
                continue
            if in_frontmatter:
                continue

            if re.match(r'^#\s+', line):
                found_heading = True
                continue
            if found_heading and line.strip():
                cmd["Description"] = line.strip()
                break

    # Extract Related Databases from content
    if match := re.search(r'\*\*Related Databases\*\*:\s*([^\n]+)', content):
        db_text = match.group(1).strip()
        cmd["RelatedDatabases"] = [
            db.strip().lstrip('- ')
            for db in re.split(r',|\|', db_text)
            if db.strip()
        ]

    commands.append(cmd)

# Output as JSON
output_file = Path("c:/Users/MarkusAhling/Notion/.claude/data/parsed-commands.json")
output_file.parent.mkdir(parents=True, exist_ok=True)
output_file.write_text(json.dumps(commands, indent=2), encoding='utf-8')

print(f"Parsed {len(commands)} commands successfully")
print(f"Output saved to: {output_file}")

# Display summary
print("\nCommand Categories:")
from collections import Counter
category_counts = Counter(cmd["Category"] for cmd in commands)
for category, count in sorted(category_counts.items(), key=lambda x: x[1], reverse=True):
    print(f"   {category}: {count} commands")
