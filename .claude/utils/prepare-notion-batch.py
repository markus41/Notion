import json

# Read the commands
with open('.claude/data/new-commands-to-create.json', 'r', encoding='utf-8') as f:
    commands = json.load(f)

# Transform Related Databases from JSON string to comma-separated string
for cmd in commands:
    related_db_str = cmd['properties'].get('Related Databases', '[]')
    try:
        related_db_array = json.loads(related_db_str)
        # Convert array to comma-separated string for Notion multi-select
        if related_db_array:
            cmd['properties']['Related Databases'] = ', '.join(related_db_array)
        else:
            cmd['properties']['Related Databases'] = ''
    except:
        cmd['properties']['Related Databases'] = ''

# Write transformed data
with open('.claude/data/notion-pages-to-create.json', 'w', encoding='utf-8') as f:
    json.dump(commands, f, indent=2)

print(f"Prepared {len(commands)} commands for Notion creation")
print(f"Sample entry: {json.dumps(commands[0], indent=2)}")
