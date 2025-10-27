# Merge blocked session into agent-state.json
$state = Get-Content "$PSScriptRoot\agent-state.json" | ConvertFrom-Json
$newSession = Get-Content "$PSScriptRoot\temp-blocked-session.json" | ConvertFrom-Json

# Create blockedSessions array if it doesn't exist
if (-not ($state.PSObject.Properties.Name -contains 'blockedSessions')) {
    $state | Add-Member -NotePropertyName 'blockedSessions' -NotePropertyValue @()
}

# Add to blocked sessions
$state.blockedSessions += $newSession

# Update statistics
$state.statistics.totalSessions++
if ($null -eq $state.statistics.blockedSessions) {
    $state.statistics.blockedSessions = 1
} else {
    $state.statistics.blockedSessions = $state.statistics.blockedSessions + 1
}
$state.statistics.lastUpdated = '2025-10-26T21:35:00Z'

# Save updated state
$state | ConvertTo-Json -Depth 10 | Set-Content "$PSScriptRoot\agent-state.json"

Write-Host "✅ Successfully merged blocked session into agent-state.json"
Write-Host "Total sessions: $($state.statistics.totalSessions)"
Write-Host "Blocked sessions: $($state.statistics.blockedSessions)"
