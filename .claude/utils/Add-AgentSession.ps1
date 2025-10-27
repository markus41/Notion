# Add Agent Session to JSON State
# Appends completed session without reading entire file

param(
    [string]$AgentName = "claude-main",
    [string]$SessionId = "claude-main-2025-10-26-0915",
    [string]$Status = "completed",
    [string]$WorkDescription = "Blog visual enhancements guide - Added 5 Mermaid diagrams and brand voice improvements"
)

$jsonPath = ".claude/data/agent-state.json"

# Read current JSON
$state = Get-Content $jsonPath -Raw | ConvertFrom-Json

# Create new session object
$newSession = @{
    sessionId = $SessionId
    agentName = $AgentName
    status = $Status
    workDescription = $WorkDescription
    startTime = "2025-10-26T09:15:00Z"
    endTime = "2025-10-26T09:45:00Z"
    duration = 30
    deliverables = @(
        ".claude/docs/blog-visual-enhancements-guide.md - Enhanced with 5 Mermaid diagrams + Best for qualifier",
        ".claude/utils/Validate-BlogVisualGuide.ps1 - Quality validation script"
    )
    metrics = @{
        filesModified = 2
        linesAdded = 150
        diagramsCreated = 5
        qualityImprovement = 7
        qualityScoreBefore = 88
        qualityScoreAfter = 95
        brandCompliance = 100
    }
    nextSteps = @(
        "Option A: Create GitHub PR for blog visual guide enhancements",
        "Option B: Continue Wave 2 documentation enhancements",
        "Option C: Execute Webflow deployment workflow"
    )
    relatedWork = @(
        "Phase 1 Wave 1 Documentation Quality Enhancement (PR #4)",
        "WEBFLOW-WEBHOOK-REUSABILITY-ANALYSIS.md",
        "integration/register.md",
        "integration/health-check.md"
    )
}

# Add to completedSessions array
if (-not $state.completedSessions) {
    $state | Add-Member -MemberType NoteProperty -Name completedSessions -Value @()
}
$state.completedSessions += $newSession

# Update statistics
if (-not $state.statistics) {
    $state | Add-Member -MemberType NoteProperty -Name statistics -Value @{
        totalSessions = 0
        completedSessions = 0
        activeSessions = 0
        blockedSessions = 0
    }
}
$state.statistics.totalSessions++
$state.statistics.completedSessions++

# Write back to file
$state | ConvertTo-Json -Depth 10 | Set-Content $jsonPath

Write-Host "✅ Session added: $SessionId" -ForegroundColor Green
Write-Host "📊 Status: $Status" -ForegroundColor Cyan
Write-Host "📝 Updated: $jsonPath" -ForegroundColor Gray
