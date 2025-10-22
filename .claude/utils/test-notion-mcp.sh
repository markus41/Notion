#!/bin/bash
# Notion MCP Connectivity Test Suite
# Purpose: Validate Notion MCP authentication and database access
# Best for: Teams establishing consistent Notion integration across repositories

set -e  # Exit on error

echo "🧪 Notion MCP Connectivity Test Suite"
echo "======================================"
echo ""

# Test 1: MCP Server Connection
echo "Test 1: MCP Server Connection Status"
if claude mcp list | grep -q "notion.*✓ Connected"; then
    echo "✅ PASS: Notion MCP server connected"
else
    echo "❌ FAIL: Notion MCP server not connected"
    echo "   Solution: Run 'claude' and authenticate when prompted"
    exit 1
fi
echo ""

# Test 2: Workspace Search
echo "Test 2: Workspace-Level Search"
SEARCH_RESULT=$(notion-search "Ideas Registry" 2>&1)
if echo "$SEARCH_RESULT" | grep -q "Ideas\|results"; then
    echo "✅ PASS: Workspace search functional"
else
    echo "⚠️  WARN: No results for 'Ideas Registry' search"
    echo "   This may be expected if database doesn't exist yet"
fi
echo ""

# Test 3: Database Fetch (Ideas Registry)
echo "Test 3: Ideas Registry Database Access"
IDEAS_DS="collection://984a4038-3e45-4a98-8df4-fd64dd8a1032"
FETCH_RESULT=$(notion-fetch "$IDEAS_DS" 2>&1)
if echo "$FETCH_RESULT" | grep -q "Ideas\|database\|properties"; then
    echo "✅ PASS: Ideas Registry accessible"
else
    echo "❌ FAIL: Cannot access Ideas Registry"
    echo "   Verify data source ID and permissions"
fi
echo ""

# Test 4: Research Hub Database
echo "Test 4: Research Hub Database Access"
RESEARCH_DS="collection://91e8beff-af94-4614-90b9-3a6d3d788d4a"
RESEARCH_RESULT=$(notion-fetch "$RESEARCH_DS" 2>&1)
if echo "$RESEARCH_RESULT" | grep -q "Research\|database\|properties"; then
    echo "✅ PASS: Research Hub accessible"
else
    echo "⚠️  WARN: Cannot access Research Hub"
    echo "   Verify permissions in Notion workspace"
fi
echo ""

# Test 5: Example Builds Database
echo "Test 5: Example Builds Database Access"
BUILDS_DS="collection://a1cd1528-971d-4873-a176-5e93b93555f6"
BUILDS_RESULT=$(notion-fetch "$BUILDS_DS" 2>&1)
if echo "$BUILDS_RESULT" | grep -q "Build\|database\|properties"; then
    echo "✅ PASS: Example Builds accessible"
else
    echo "⚠️  WARN: Cannot access Example Builds"
    echo "   Verify permissions in Notion workspace"
fi
echo ""

# Test 6: Software & Cost Tracker
echo "Test 6: Software & Cost Tracker Database Access"
SOFTWARE_DS="collection://13b5e9de-2dd1-45ec-839a-4f3d50cd8d06"
SOFTWARE_RESULT=$(notion-fetch "$SOFTWARE_DS" 2>&1)
if echo "$SOFTWARE_RESULT" | grep -q "Software\|database\|properties"; then
    echo "✅ PASS: Software & Cost Tracker accessible"
else
    echo "⚠️  WARN: Cannot access Software & Cost Tracker"
    echo "   Verify permissions in Notion workspace"
fi
echo ""

# Test 7: OAuth Token Expiration Check
echo "Test 7: OAuth Token Expiration Status"
CREDENTIALS_FILE="$HOME/.claude/mcp-credentials.json"

if [ -f "$CREDENTIALS_FILE" ]; then
    # Try to extract expiration date (format varies)
    EXPIRES_AT=$(grep -oP '"expires_at":\s*"\K[^"]+' "$CREDENTIALS_FILE" 2>/dev/null | head -1)

    if [ -n "$EXPIRES_AT" ]; then
        echo "✅ PASS: Token found in credentials"
        echo "   Expires: $EXPIRES_AT"

        # Check if expiring soon (within 7 days) - works on Linux/macOS
        if command -v date &> /dev/null; then
            EXPIRES_EPOCH=$(date -d "$EXPIRES_AT" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "${EXPIRES_AT:0:19}" +%s 2>/dev/null || echo "0")
            NOW_EPOCH=$(date +%s)

            if [ "$EXPIRES_EPOCH" -gt 0 ]; then
                DAYS_UNTIL_EXPIRY=$(( ($EXPIRES_EPOCH - $NOW_EPOCH) / 86400 ))

                if [ $DAYS_UNTIL_EXPIRY -lt 7 ] && [ $DAYS_UNTIL_EXPIRY -ge 0 ]; then
                    echo "⚠️  WARN: Token expiring in $DAYS_UNTIL_EXPIRY days"
                    echo "   Claude Code will auto-refresh soon"
                elif [ $DAYS_UNTIL_EXPIRY -lt 0 ]; then
                    echo "❌ FAIL: Token expired $((0 - $DAYS_UNTIL_EXPIRY)) days ago"
                    echo "   Re-authenticate: rm ~/.claude/mcp-credentials.json && claude"
                else
                    echo "   Token valid for $DAYS_UNTIL_EXPIRY days"
                fi
            fi
        fi
    else
        echo "⚠️  WARN: Cannot parse token expiration"
        echo "   Token may still be valid - check manually"
    fi
else
    echo "❌ FAIL: No credentials file found at $CREDENTIALS_FILE"
    echo "   Run 'claude' to authenticate"
    exit 1
fi
echo ""

# Summary
echo "======================================"
echo "✅ Test Suite Complete"
echo ""
echo "Next Steps:"
echo "  - If all tests passed: Notion MCP fully operational"
echo "  - If warnings: Check database permissions in Notion"
echo "  - If failures: Re-authenticate with 'claude' command"
echo ""
echo "Troubleshooting:"
echo "  1. Verify MCP connection: claude mcp list"
echo "  2. Test search: notion-search \"test query\""
echo "  3. Re-auth if needed: rm ~/.claude/mcp-credentials.json && claude"
echo ""
