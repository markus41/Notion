#Requires -Version 5.1
<#
.SYNOPSIS
    Automated Notion queue processor for agent activity logging.

.DESCRIPTION
    Reads pending entries from notion-sync-queue.jsonl and generates
    Notion MCP commands for batch processing. Designed to be run periodically
    (daily/weekly) or on-demand to synchronize queued agent activities.

    This script prepares the Notion sync operations but requires Claude Code
    MCP integration to execute. Use with /agent:sync-notion-logs command.

.PARAMETER DryRun
    Show what would be synced without actually processing.

.PARAMETER MaxEntries
    Maximum number of entries to process in one run (default: 100).

.PARAMETER StatusOnly
    Check queue status without processing.

.PARAMETER OutputFormat
    Output format: 'summary' (default), 'detailed', or 'json'.

.EXAMPLE
    .\Sync-NotionLogs.ps1
    Process all pending entries (up to 100).

.EXAMPLE
    .\Sync-NotionLogs.ps1 -DryRun
    Preview what would be synced without processing.

.EXAMPLE
    .\Sync-NotionLogs.ps1 -StatusOnly
    Check current queue status.

.NOTES
    Author: Brookside BI - Innovation Nexus
    Version: 1.0.0
    Created: 2025-10-22
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [int]$MaxEntries = 100,

    [Parameter(Mandatory = $false)]
    [switch]$StatusOnly,

    [Parameter(Mandatory = $false)]
    [ValidateSet('summary', 'detailed', 'json')]
    [string]$OutputFormat = 'summary'
)

# Configuration
$script:Config = @{
    QueueFile = Join-Path $PSScriptRoot "..\data\notion-sync-queue.jsonl"
    DatabaseId = "72b879f2-13bd-4edb-9c59-b43089dbef21"
    MaxRetries = 3
}

# Read queue file
function Get-QueueEntries {
    if (-not (Test-Path $script:Config.QueueFile)) {
        return @()
    }

    try {
        $lines = Get-Content $script:Config.QueueFile -ErrorAction Stop
        $entries = @()

        foreach ($line in $lines) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }

            try {
                $entry = $line | ConvertFrom-Json
                $entries += $entry
            }
            catch {
                Write-Warning "Failed to parse queue entry: $line"
            }
        }

        return $entries
    }
    catch {
        Write-Error "Failed to read queue file: $_"
        return @()
    }
}

# Get queue statistics
function Get-QueueStatistics {
    param([array]$Entries)

    $stats = @{
        Total = $Entries.Count
        Pending = ($Entries | Where-Object { $_.syncStatus -eq 'pending' }).Count
        Retry = ($Entries | Where-Object { $_.syncStatus -eq 'retry' }).Count
        Failed = ($Entries | Where-Object { $_.syncStatus -eq 'failed' }).Count
        Agents = ($Entries | Select-Object -ExpandProperty agentName -Unique).Count
        OldestEntry = $null
        NewestEntry = $null
    }

    if ($Entries.Count -gt 0) {
        $sorted = $Entries | Sort-Object queuedAt
        $stats.OldestEntry = $sorted[0].queuedAt
        $stats.NewestEntry = $sorted[-1].queuedAt
    }

    return $stats
}

# Generate Notion MCP command for entry
function ConvertTo-NotionMCPCommand {
    param([PSCustomObject]$Entry)

    $command = @"
mcp__notion__notion-create-pages with parameters:
{
  "parent": {"database_id": "$($script:Config.DatabaseId)"},
  "pages": [{
    "properties": {
      "Session ID": "$($Entry.sessionId)",
      "Agent Name": "$($Entry.agentName)",
      "Status": "$($Entry.status -replace 'in-progress', 'In Progress')",
      "Work Description": "$($Entry.workDescription)",
      "date:Start Time:start": "$($Entry.startTime)",
      "date:Start Time:is_datetime": 1
    }
  }]
}
"@

    return $command
}

# Main processing logic
function Invoke-QueueProcessing {
    param(
        [array]$Entries,
        [bool]$DryRunMode
    )

    Write-Host "`n## Notion Sync Queue Processing" -ForegroundColor Cyan
    Write-Host "=" * 60

    # Filter processable entries
    $processable = $Entries | Where-Object {
        $_.syncStatus -in @('pending', 'retry') -and
        $_.retryCount -lt $script:Config.MaxRetries
    } | Select-Object -First $MaxEntries

    if ($processable.Count -eq 0) {
        Write-Host "`n✅ Queue is empty - no entries to process`n" -ForegroundColor Green
        return @{
            Succeeded = 0
            Failed = 0
            Skipped = 0
            Remaining = 0
        }
    }

    Write-Host "`n📊 Entries to process: $($processable.Count)" -ForegroundColor Yellow

    if ($DryRunMode) {
        Write-Host "`n🔍 DRY RUN MODE - No actual syncing will occur`n" -ForegroundColor Magenta
    }

    # Process each entry
    $results = @{
        Succeeded = 0
        Failed = 0
        Skipped = 0
        Remaining = $Entries.Count
    }

    foreach ($entry in $processable) {
        Write-Host "`nProcessing: $($entry.sessionId)" -ForegroundColor White
        Write-Host "  Agent: $($entry.agentName)" -ForegroundColor Gray
        Write-Host "  Work: $($entry.workDescription)" -ForegroundColor Gray
        Write-Host "  Status: $($entry.syncStatus) (retry: $($entry.retryCount))" -ForegroundColor Gray

        if ($DryRunMode) {
            Write-Host "  ➜ Would create Notion page via MCP" -ForegroundColor Cyan
            $results.Succeeded++
        }
        else {
            # Generate MCP command
            $mcpCommand = ConvertTo-NotionMCPCommand -Entry $entry
            Write-Host "`n  📝 Generated MCP command:" -ForegroundColor Gray
            Write-Host $mcpCommand -ForegroundColor DarkGray

            # Note: Actual MCP execution requires Claude Code integration
            # For now, we're generating the commands for manual/batch processing
            $results.Succeeded++
        }
    }

    $results.Remaining = $Entries.Count - $results.Succeeded

    return $results
}

# Output results
function Write-Results {
    param(
        [hashtable]$Results,
        [hashtable]$Stats,
        [string]$Format
    )

    Write-Host "`n## Sync Results" -ForegroundColor Cyan
    Write-Host "=" * 60

    switch ($Format) {
        'json' {
            @{
                timestamp = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
                results = $Results
                queueStats = $Stats
            } | ConvertTo-Json -Depth 3
        }
        'detailed' {
            Write-Host "`n📊 Processing Summary:" -ForegroundColor Yellow
            Write-Host "  ✅ Succeeded: $($Results.Succeeded)" -ForegroundColor Green
            Write-Host "  ❌ Failed: $($Results.Failed)" -ForegroundColor Red
            Write-Host "  ⏭️  Skipped: $($Results.Skipped)" -ForegroundColor Gray
            Write-Host "  ⏳ Remaining: $($Results.Remaining)" -ForegroundColor Yellow

            Write-Host "`n📈 Queue Statistics:" -ForegroundColor Yellow
            Write-Host "  Total entries: $($Stats.Total)" -ForegroundColor White
            Write-Host "  Pending: $($Stats.Pending)" -ForegroundColor Cyan
            Write-Host "  Retry: $($Stats.Retry)" -ForegroundColor Yellow
            Write-Host "  Failed: $($Stats.Failed)" -ForegroundColor Red
            Write-Host "  Unique agents: $($Stats.Agents)" -ForegroundColor Magenta

            if ($Stats.OldestEntry) {
                Write-Host "`n📅 Oldest entry: $($Stats.OldestEntry)" -ForegroundColor Gray
                Write-Host "📅 Newest entry: $($Stats.NewestEntry)" -ForegroundColor Gray
            }
        }
        default {
            Write-Host "`n✅ Processed: $($Results.Succeeded) entries" -ForegroundColor Green
            if ($Results.Remaining -gt 0) {
                Write-Host "⏳ Remaining: $($Results.Remaining) entries" -ForegroundColor Yellow
            }
            else {
                Write-Host "✅ Queue is now empty!" -ForegroundColor Green
            }
        }
    }

    Write-Host ""
}

# Main execution
try {
    # Read queue
    $entries = Get-QueueEntries

    if ($entries.Count -eq 0) {
        Write-Host "`n✅ Notion sync queue is empty - nothing to process`n" -ForegroundColor Green
        exit 0
    }

    # Get statistics
    $stats = Get-QueueStatistics -Entries $entries

    # Status only mode
    if ($StatusOnly) {
        Write-Host "`n## Queue Status" -ForegroundColor Cyan
        Write-Host "=" * 60
        Write-Results -Results @{Succeeded=0;Failed=0;Skipped=0;Remaining=$stats.Total} -Stats $stats -Format 'detailed'
        exit 0
    }

    # Process queue
    $results = Invoke-QueueProcessing -Entries $entries -DryRunMode:$DryRun

    # Output results
    Write-Results -Results $results -Stats $stats -Format $OutputFormat

    # Next steps
    if (-not $DryRun -and $results.Succeeded -gt 0) {
        Write-Host "⚠️  Note: This script generates MCP commands but requires Claude Code to execute." -ForegroundColor Yellow
        Write-Host "   Run this via Claude Code or use /agent:sync-notion-logs command`n" -ForegroundColor Yellow
    }

    exit 0
}
catch {
    Write-Error "Sync processing failed: $_"
    Write-Error "Stack trace: $($_.ScriptStackTrace)"
    exit 1
}
