#!/usr/bin/env python3
"""Update agent-state.json with new completed session"""
import json
from datetime import datetime

# New session entry
new_session = {
    "sessionId": "claude-main-2025-10-27-1600",
    "agent": "claude-main",
    "status": "completed",
    "workDescription": "Comprehensive Webflow website analysis with revised Notion CMS integration strategy",
    "startTime": "2025-10-27T10:00:00Z",
    "endTime": "2025-10-27T16:00:00Z",
    "duration": 360,
    "deliverables": [
        "WEBFLOW-COMPREHENSIVE-ANALYSIS.md (12,000+ word strategic document)",
        "Revised implementation plan with 6 Notion databases",
        "Big Bang migration strategy with Phase 0.5",
        "Updated todo list with 12 actionable tasks"
    ],
    "metrics": {
        "duration_minutes": 360,
        "scope_improvements": 108,
        "functional_areas": 9,
        "documentation_words": 12000,
        "timeline_weeks": 12,
        "effort_hours_min": 320,
        "effort_hours_max": 430,
        "content_items": 50,
        "visual_gaps": 25,
        "budget_increase": 15000
    },
    "nextSteps": [
        "Phase 0.5: Audit all 6 Notion databases",
        "Phase 0.5: Visual asset creation (25-40 hours)",
        "Phase 1: Schema design for 3 NEW databases",
        "Stakeholder review and budget approval"
    ],
    "relatedWork": {
        "databases": [
            "91e8beff-af94-4614-90b9-3a6d3d788d4a",  # Research Hub
            "984a4038-3e45-4a98-8df4-fd64dd8a1032",  # Ideas Registry
            "5863265b-eeee-45fc-ab1a-4206d8a523c6"   # Agent Registry
        ],
        "documents": [
            "WEBFLOW-INTEGRATION-README.md",
            "WEBFLOW-WEBHOOK-ARCHITECTURE.md",
            "WEBFLOW-WEBHOOK-REUSABILITY-ANALYSIS.md"
        ]
    }
}

# Read existing state
file_path = r"C:\Users\MarkusAhling\Notion\.claude\data\agent-state.json"
with open(file_path, 'r', encoding='utf-8') as f:
    state = json.load(f)

# Add to completedSessions
if "completedSessions" not in state:
    state["completedSessions"] = []

state["completedSessions"].append(new_session)

# Update statistics
if "statistics" not in state:
    state["statistics"] = {
        "totalSessions": 0,
        "completedSessions": 0,
        "activeSessions": 0,
        "blockedSessions": 0
    }

state["statistics"]["totalSessions"] = state["statistics"].get("totalSessions", 0) + 1
state["statistics"]["completedSessions"] = state["statistics"].get("completedSessions", 0) + 1

# Write back
with open(file_path, 'w', encoding='utf-8') as f:
    json.dump(state, f, indent=2, ensure_ascii=False)

print("[OK] agent-state.json updated successfully")
print(f"Session ID: {new_session['sessionId']}")
print(f"Status: {new_session['status']}")
print(f"Duration: {new_session['duration']} minutes")
