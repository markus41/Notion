import json
import sys
from pathlib import Path

# Read the current agent-state.json
state_file = Path(__file__).parent / "agent-state.json"
temp_file = Path(__file__).parent / "temp-blocked-session.json"

try:
    with open(state_file, 'r', encoding='utf-8') as f:
        state = json.load(f)

    with open(temp_file, 'r', encoding='utf-8') as f:
        new_session = json.load(f)

    # Create blockedSessions array if it doesn't exist
    if 'blockedSessions' not in state:
        state['blockedSessions'] = []

    # Check if this session is already in blockedSessions
    already_exists = any(
        s.get('sessionId') == new_session['sessionId']
        for s in state.get('blockedSessions', [])
    )

    if not already_exists:
        # Add to blocked sessions
        state['blockedSessions'].append(new_session)

        # Update statistics
        state['statistics']['totalSessions'] = state['statistics'].get('totalSessions', 0) + 1
        state['statistics']['blockedSessions'] = len(state['blockedSessions'])
        state['statistics']['lastUpdated'] = '2025-10-26T21:35:00Z'

        # Save with proper formatting
        with open(state_file, 'w', encoding='utf-8') as f:
            json.dump(state, f, indent=4, ensure_ascii=False)

        print("SUCCESS: Merged blocked session into agent-state.json")
        print(f"Total sessions: {state['statistics']['totalSessions']}")
        print(f"Blocked sessions: {state['statistics']['blockedSessions']}")
    else:
        print("INFO: Session already exists in blockedSessions array")
        print(f"Total sessions: {state['statistics']['totalSessions']}")
        print(f"Blocked sessions: {len(state.get('blockedSessions', []))}")

except json.JSONDecodeError as e:
    print(f"ERROR: JSON parsing error: {e}")
    sys.exit(1)
except Exception as e:
    print(f"ERROR: {e}")
    sys.exit(1)
