# Test script for auto-log-agent-activity.ps1
# Run this to validate hook functionality

Write-Host "`n=== HOOK SCRIPT TESTS ===" -ForegroundColor Cyan
Write-Host "Testing automatic agent activity logging hook`n" -ForegroundColor Gray

# Test 1: Hook trigger with approved agent
Write-Host "Test 1: Approved Agent (@build-architect)" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

$env:CLAUDE_TOOL_NAME = "Task"
$env:CLAUDE_TOOL_PARAMS = '{"subagent_type":"build-architect","description":"Design architecture for Repository Analyzer"}'

Write-Host "  Invoking hook with:" -ForegroundColor Gray
Write-Host "    Tool: $env:CLAUDE_TOOL_NAME" -ForegroundColor Yellow
Write-Host "    Agent: @build-architect" -ForegroundColor Yellow

try {
    & "$PSScriptRoot\auto-log-agent-activity.ps1" -Verbose
    Write-Host "  Result: Hook executed successfully" -ForegroundColor Green
}
catch {
    Write-Host "  Error: $_" -ForegroundColor Red
}

# Test 2: Hook trigger with unapproved agent
Write-Host "`nTest 2: Unapproved Agent (@test-agent)" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

$env:CLAUDE_TOOL_PARAMS = '{"subagent_type":"test-agent","description":"Test work"}'

Write-Host "  Invoking hook with:" -ForegroundColor Gray
Write-Host "    Tool: $env:CLAUDE_TOOL_NAME" -ForegroundColor Yellow
Write-Host "    Agent: @test-agent" -ForegroundColor Yellow

try {
    & "$PSScriptRoot\auto-log-agent-activity.ps1" -Verbose
    Write-Host "  Result: Hook executed (should be filtered)" -ForegroundColor Green
}
catch {
    Write-Host "  Error: $_" -ForegroundColor Red
}

# Test 3: Hook trigger with non-Task tool
Write-Host "`nTest 3: Non-Task Tool (Bash)" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

$env:CLAUDE_TOOL_NAME = "Bash"
$env:CLAUDE_TOOL_PARAMS = '{"command":"git status"}'

Write-Host "  Invoking hook with:" -ForegroundColor Gray
Write-Host "    Tool: $env:CLAUDE_TOOL_NAME" -ForegroundColor Yellow

try {
    & "$PSScriptRoot\auto-log-agent-activity.ps1" -Verbose
    Write-Host "  Result: Hook executed (should be filtered)" -ForegroundColor Green
}
catch {
    Write-Host "  Error: $_" -ForegroundColor Red
}

# Test 4: Multiple agents in sequence (duplicate detection)
Write-Host "`nTest 4: Duplicate Detection" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

$env:CLAUDE_TOOL_NAME = "Task"
$env:CLAUDE_TOOL_PARAMS = '{"subagent_type":"cost-analyst","description":"Analyze software spend"}'

Write-Host "  First invocation:" -ForegroundColor Gray
try {
    & "$PSScriptRoot\auto-log-agent-activity.ps1" -Verbose
    Write-Host "    Result: Should pass (first time)" -ForegroundColor Green
}
catch {
    Write-Host "    Error: $_" -ForegroundColor Red
}

Write-Host "`n  Second invocation (within 5 minutes):" -ForegroundColor Gray
try {
    & "$PSScriptRoot\auto-log-agent-activity.ps1" -Verbose
    Write-Host "    Result: Should be skipped (duplicate)" -ForegroundColor Green
}
catch {
    Write-Host "    Error: $_" -ForegroundColor Red
}

# Test 5: Check log file
Write-Host "`nTest 5: Log File Validation" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

$logFile = Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "logs") "auto-activity-hook.log"

if (Test-Path $logFile) {
    Write-Host "  Log file exists: $logFile" -ForegroundColor Green
    Write-Host "`n  Last 20 log entries:" -ForegroundColor Gray
    Get-Content $logFile -Tail 20 | ForEach-Object {
        if ($_ -match '\[ERROR\]') {
            Write-Host "    $_" -ForegroundColor Red
        }
        elseif ($_ -match '\[WARNING\]') {
            Write-Host "    $_" -ForegroundColor Yellow
        }
        elseif ($_ -match '\[INFO\]') {
            Write-Host "    $_" -ForegroundColor Green
        }
        else {
            Write-Host "    $_" -ForegroundColor Gray
        }
    }
}
else {
    Write-Host "  Log file not created yet: $logFile" -ForegroundColor Yellow
}

# Test 6: State file check
Write-Host "`nTest 6: State File Validation" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

$stateFile = Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "data") "agent-state.json"

if (Test-Path $stateFile) {
    Write-Host "  State file exists: $stateFile" -ForegroundColor Green

    try {
        $state = Get-Content $stateFile -Raw | ConvertFrom-Json
        Write-Host "`n  Current Statistics:" -ForegroundColor Gray
        Write-Host "    Total Sessions: $($state.statistics.totalSessions)" -ForegroundColor Yellow
        Write-Host "    Active Sessions: $($state.statistics.activeSessions)" -ForegroundColor Yellow
        Write-Host "    Completed Sessions: $($state.statistics.completedSessions)" -ForegroundColor Yellow
        Write-Host "    Success Rate: $($state.statistics.successRate * 100)%" -ForegroundColor Yellow

        if ($state.activeSessions.Count -gt 0) {
            Write-Host "`n  Active Sessions:" -ForegroundColor Gray
            $state.activeSessions | ForEach-Object {
                Write-Host "    - $($_.agentName) (started: $($_.startTime))" -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "  Error reading state file: $_" -ForegroundColor Red
    }
}
else {
    Write-Host "  State file not found: $stateFile" -ForegroundColor Yellow
}

# Clean up environment variables
Remove-Item Env:\CLAUDE_TOOL_NAME -ErrorAction SilentlyContinue
Remove-Item Env:\CLAUDE_TOOL_PARAMS -ErrorAction SilentlyContinue

Write-Host "`n=== ALL HOOK TESTS COMPLETED ===" -ForegroundColor Cyan
Write-Host "Review log file for detailed execution traces`n" -ForegroundColor Green
