import json

# Read the commands
with open('.claude/data/notion-pages-to-create.json', 'r', encoding='utf-8') as f:
    commands = json.load(f)

# Convert Related Databases from comma-separated string to JSON array
for cmd in commands:
    related_db_str = cmd['properties'].get('Related Databases', '')
    if related_db_str:
        # Split by comma and strip whitespace
        related_db_array = [db.strip() for db in related_db_str.split(',')]
        cmd['properties']['Related Databases'] = json.dumps(related_db_array)
    else:
        cmd['properties']['Related Databases'] = '[]'

# Write fixed data
with open('.claude/data/notion-pages-final.json', 'w', encoding='utf-8') as f:
    json.dump(commands, f, indent=2)

print(f"Fixed {len(commands)} commands")
print(f"Sample: {json.dumps(commands[0]['properties']['Related Databases'])}")
