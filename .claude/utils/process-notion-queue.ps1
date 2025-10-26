<#
.SYNOPSIS
    Notion Queue Processor - Processes queued agent activity entries and syncs to Notion

.DESCRIPTION
    Establish automated synchronization between local agent activity logs and Notion Agent Activity Hub.
    Processes entries from notion-sync-queue.jsonl, creates/updates Notion database entries, and handles
    failures with retry logic. Designed for organizations scaling agent activity tracking with resilient
    data synchronization.

.PARAMETER MaxRetries
    Maximum number of retry attempts per entry (default: 3)

.PARAMETER RetryDelaySeconds
    Initial delay between retries in seconds, with exponential backoff (default: 2)

.PARAMETER BatchSize
    Number of entries to process in one run (default: 10)

.PARAMETER DryRun
    If specified, parses queue but doesn't sync to Notion or delete entries

.EXAMPLE
    .\process-notion-queue.ps1
    Processes up to 10 queued entries with default retry settings

.EXAMPLE
    .\process-notion-queue.ps1 -BatchSize 50 -MaxRetries 5
    Processes up to 50 entries with 5 retry attempts each

.EXAMPLE
    .\process-notion-queue.ps1 -DryRun
    Validates queue entries without syncing to Notion

.NOTES
    Author: Brookside BI Innovation Nexus
    Purpose: Automated Notion synchronization for agent activity tracking
    Best for: Organizations requiring reliable multi-tier activity tracking with async Notion sync
#>

param(
    [Parameter(Mandatory = $false)]
    [int]$MaxRetries = 3,

    [Parameter(Mandatory = $false)]
    [int]$RetryDelaySeconds = 2,

    [Parameter(Mandatory = $false)]
    [int]$BatchSize = 10,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

# Configuration
$script:Config = @{
    QueueFile = Join-Path (Split-Path -Parent $PSScriptRoot) "data\notion-sync-queue.jsonl"
    TempQueueFile = Join-Path (Split-Path -Parent $PSScriptRoot) "data\notion-sync-queue.tmp"
    ProcessorLogFile = Join-Path (Split-Path -Parent $PSScriptRoot) "logs\notion-queue-processor.log"
    StateFile = Join-Path (Split-Path -Parent $PSScriptRoot) "data\agent-state.json"
    # Agent Activity Hub Database ID (page ID, not data source ID)
    # Data Source ID: 7163aa38-f3d9-444b-9674-bde61868bd2b (for MCP reference)
    AgentActivityHubDataSourceId = "72b879f213bd4edb9c59b43089dbef21"
    AgentRegistryDataSourceId = "5863265b-eeee-45fc-ab1a-4206d8a523c6"
}

# Initialize logging
function Write-ProcessorLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "DEBUG")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # Ensure log directory exists
    $logDir = Split-Path -Parent $script:Config.ProcessorLogFile
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    Add-Content -Path $script:Config.ProcessorLogFile -Value $logMessage

    # Console output with color coding
    $color = switch ($Level) {
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "DEBUG" { "Gray" }
        default { "White" }
    }

    Write-Host $logMessage -ForegroundColor $color
}

# Parse JSONL queue file
function Get-QueueEntries {
    Write-ProcessorLog "Reading queue file: $($script:Config.QueueFile)" -Level DEBUG

    if (-not (Test-Path $script:Config.QueueFile)) {
        Write-ProcessorLog "Queue file does not exist - nothing to process" -Level INFO
        return @()
    }

    try {
        $entries = @()
        $lineNumber = 0

        Get-Content -Path $script:Config.QueueFile | ForEach-Object {
            $lineNumber++
            $line = $_.Trim()

            if ([string]::IsNullOrWhiteSpace($line)) {
                Write-ProcessorLog "Skipping empty line $lineNumber" -Level DEBUG
                return
            }

            try {
                $entry = $_ | ConvertFrom-Json -ErrorAction Stop
                $entry | Add-Member -NotePropertyName "LineNumber" -NotePropertyValue $lineNumber -Force
                $entries += $entry
                Write-ProcessorLog "Parsed entry ${lineNumber}: SessionId=$($entry.sessionId)" -Level DEBUG
            }
            catch {
                Write-ProcessorLog "Failed to parse line $lineNumber as JSON: $_" -Level ERROR
                Write-ProcessorLog "Line content: $line" -Level ERROR
            }
        }

        # Filter out entries already synced via webhook (dual-path optimization)
        $totalEntries = $entries.Count
        $entries = $entries | Where-Object {
            if ($_.webhookSynced -eq $true) {
                Write-ProcessorLog "Skipping entry ${_}.LineNumber (SessionId=$($_.sessionId)) - Already synced via webhook" -Level DEBUG
                return $false
            }
            return $true
        }

        $webhookSyncedCount = $totalEntries - $entries.Count
        if ($webhookSyncedCount -gt 0) {
            Write-ProcessorLog "Skipped $webhookSyncedCount entries already synced via webhook" -Level INFO
        }

        Write-ProcessorLog "Successfully parsed $totalEntries queue entries ($($entries.Count) require processing)" -Level INFO
        return $entries
    }
    catch {
        Write-ProcessorLog "Failed to read queue file: $_" -Level ERROR
        return @()
    }
}

# Sync single entry to Notion Agent Activity Hub
function Sync-ToNotion {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Entry,

        [Parameter(Mandatory = $false)]
        [int]$AttemptNumber = 1
    )

    Write-ProcessorLog "Syncing entry to Notion (attempt $AttemptNumber/$MaxRetries): SessionId=$($Entry.sessionId)" -Level INFO

    if ($DryRun) {
        Write-ProcessorLog "[DRY RUN] Would sync to Notion: AgentName=$($Entry.agentName), Status=$($Entry.status)" -Level INFO
        return @{ Success = $true; DryRun = $true }
    }

    try {
        # Build Notion page properties
        $properties = @{
            "Agent Name" = $Entry.agentName
            "Status" = $Entry.status
            "Session ID" = $Entry.sessionId
            "Start Time" = $Entry.startTime
            "Work Description" = if ($Entry.workDescription) { $Entry.workDescription } else { "" }
            "Deliverables Count" = if ($Entry.deliverablesCount) { [int]$Entry.deliverablesCount } else { 0 }
            "Files Created" = if ($Entry.filesCreated) { [int]$Entry.filesCreated } else { 0 }
            "Files Updated" = if ($Entry.filesUpdated) { [int]$Entry.filesUpdated } else { 0 }
        }

        # Add optional properties if present
        if ($Entry.endTime) {
            $properties["End Time"] = $Entry.endTime
        }

        if ($Entry.durationMinutes) {
            $properties["Duration (Minutes)"] = [int]$Entry.durationMinutes
        }

        if ($Entry.linesGenerated) {
            $properties["Lines Generated"] = [int]$Entry.linesGenerated
        }

        if ($Entry.performanceMetrics) {
            $properties["Performance Metrics"] = $Entry.performanceMetrics
        }

        if ($Entry.relatedNotionItems) {
            $properties["Related Notion Items"] = $Entry.relatedNotionItems
        }

        # Build Notion page content (deliverables and next steps)
        $content = "## Session Summary`n`n"
        $content += "**Session ID**: ``$($Entry.sessionId)```n"
        $content += "**Agent**: $($Entry.agentName)`n"
        $content += "**Status**: $($Entry.status)`n`n"

        if ($Entry.deliverables -and $Entry.deliverables.Count -gt 0) {
            $content += "## Deliverables`n`n"
            foreach ($deliverable in $Entry.deliverables) {
                $content += "- $deliverable`n"
            }
            $content += "`n"
        }

        if ($Entry.nextSteps) {
            $content += "## Next Steps`n`n$($Entry.nextSteps)`n`n"
        }

        # Create Notion page using MCP
        # Note: This uses the notion-create-pages MCP tool which should be available via Claude Code
        Write-ProcessorLog "Creating Notion page with properties: $($properties.Keys -join ', ')" -Level DEBUG

        # For now, this is a placeholder - actual Notion MCP integration would go here
        # In production, you would call: mcp__notion__notion-create-pages with proper parameters
        $notionResult = Invoke-NotionMCP -Action "CreatePage" -DataSourceId $script:Config.AgentActivityHubDataSourceId -Properties $properties -Content $content

        if ($notionResult.Success) {
            Write-ProcessorLog "Successfully synced to Notion: $($notionResult.PageUrl)" -Level SUCCESS
            return @{ Success = $true; PageUrl = $notionResult.PageUrl }
        }
        else {
            Write-ProcessorLog "Notion sync failed: $($notionResult.Error)" -Level ERROR
            return @{ Success = $false; Error = $notionResult.Error }
        }
    }
    catch {
        Write-ProcessorLog "Exception during Notion sync: $_" -Level ERROR
        Write-ProcessorLog "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

# Invoke Notion API to create page in Agent Activity Hub
function Invoke-NotionMCP {
    param(
        [string]$Action,
        [string]$DataSourceId,
        [hashtable]$Properties,
        [string]$Content
    )

    Write-ProcessorLog "Creating Notion page via API: Action=$Action, DataSource=$DataSourceId" -Level DEBUG

    try {
        # Retrieve Notion API token from environment variable
        $notionToken = $env:NOTION_API_KEY
        if ([string]::IsNullOrWhiteSpace($notionToken)) {
            Write-ProcessorLog "NOTION_API_KEY environment variable not set - attempting Key Vault retrieval" -Level WARNING

            # Attempt to retrieve from Azure Key Vault
            $keyVaultScript = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "scripts\Get-KeyVaultSecret.ps1"
            if (Test-Path $keyVaultScript) {
                $secretResult = & $keyVaultScript -SecretName "notion-api-key" 2>&1
                if ($LASTEXITCODE -eq 0 -and $secretResult) {
                    $notionToken = $secretResult
                    Write-ProcessorLog "Retrieved Notion API key from Azure Key Vault" -Level SUCCESS
                }
            }

            if ([string]::IsNullOrWhiteSpace($notionToken)) {
                throw "Notion API token not available. Set NOTION_API_KEY environment variable or ensure Key Vault access."
            }
        }

        # Build Notion API request body
        $parent = @{
            type = "database_id"
            database_id = $DataSourceId
        }

        # Convert properties to Notion API format
        $notionProperties = @{}

        foreach ($key in $Properties.Keys) {
            $value = $Properties[$key]

            # Map property types based on Agent Activity Hub schema
            switch ($key) {
                "Agent Name" {
                    $notionProperties[$key] = @{
                        select = @{ name = $value }
                    }
                }
                "Status" {
                    $notionProperties[$key] = @{
                        select = @{ name = $value }
                    }
                }
                "Session ID" {
                    $notionProperties[$key] = @{
                        title = @(
                            @{
                                text = @{ content = $value }
                            }
                        )
                    }
                }
                { $_ -in @("Start Time", "End Time") } {
                    $notionProperties[$key] = @{
                        date = @{ start = $value }
                    }
                }
                { $_ -in @("Files Created", "Files Updated", "Lines Generated", "Deliverables Count", "Duration (Minutes)") } {
                    $notionProperties[$key] = @{
                        number = $value
                    }
                }
                default {
                    # Rich text for other fields
                    $notionProperties[$key] = @{
                        rich_text = @(
                            @{
                                text = @{ content = [string]$value }
                            }
                        )
                    }
                }
            }
        }

        # Build request body
        $body = @{
            parent = $parent
            properties = $notionProperties
        } | ConvertTo-Json -Depth 10

        # Add content as page body if provided
        if (-not [string]::IsNullOrWhiteSpace($Content)) {
            # Convert markdown content to Notion blocks (simplified - just paragraph blocks)
            $contentLines = $Content -split "`n"
            $children = @()

            foreach ($line in $contentLines) {
                if (-not [string]::IsNullOrWhiteSpace($line)) {
                    $children += @{
                        object = "block"
                        type = "paragraph"
                        paragraph = @{
                            rich_text = @(
                                @{
                                    type = "text"
                                    text = @{ content = $line }
                                }
                            )
                        }
                    }
                }
            }

            $bodyObj = $body | ConvertFrom-Json
            $bodyObj | Add-Member -NotePropertyName "children" -NotePropertyValue $children -Force
            $body = $bodyObj | ConvertTo-Json -Depth 10
        }

        Write-ProcessorLog "Notion API request body prepared (${body.Length} bytes)" -Level DEBUG

        # Call Notion API
        $headers = @{
            "Authorization" = "Bearer $notionToken"
            "Content-Type" = "application/json"
            "Notion-Version" = "2022-06-28"
        }

        $response = Invoke-RestMethod -Uri "https://api.notion.com/v1/pages" -Method Post -Headers $headers -Body $body -ErrorAction Stop

        # Extract page URL
        $pageUrl = $response.url
        $pageId = $response.id

        Write-ProcessorLog "Notion page created successfully: ID=$pageId" -Level SUCCESS

        return @{
            Success = $true
            PageUrl = $pageUrl
            PageId = $pageId
        }
    }
    catch {
        $errorMessage = $_.Exception.Message
        if ($_.ErrorDetails.Message) {
            try {
                $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
                $errorMessage = "$errorMessage - Notion API: $($errorDetails.message)"
            }
            catch {
                $errorMessage = "$errorMessage - $($_.ErrorDetails.Message)"
            }
        }

        Write-ProcessorLog "Failed to create Notion page: $errorMessage" -Level ERROR
        Write-ProcessorLog "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG

        return @{
            Success = $false
            Error = $errorMessage
        }
    }
}

# Process single entry with retry logic
function Process-Entry {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Entry
    )

    $attempt = 0
    $lastError = $null

    while ($attempt -lt $MaxRetries) {
        $attempt++

        $result = Sync-ToNotion -Entry $Entry -AttemptNumber $attempt

        if ($result.Success) {
            Write-ProcessorLog "Entry processed successfully: SessionId=$($Entry.sessionId)" -Level SUCCESS
            return @{ Success = $true; PageUrl = $result.PageUrl }
        }

        $lastError = $result.Error
        Write-ProcessorLog "Attempt $attempt failed for SessionId=$($Entry.sessionId): $lastError" -Level WARNING

        if ($attempt -lt $MaxRetries) {
            $delay = $RetryDelaySeconds * [Math]::Pow(2, $attempt - 1)
            Write-ProcessorLog "Retrying in $delay seconds..." -Level INFO
            Start-Sleep -Seconds $delay
        }
    }

    Write-ProcessorLog "All $MaxRetries attempts failed for SessionId=$($Entry.sessionId)" -Level ERROR
    return @{ Success = $false; Error = $lastError }
}

# Remove processed entries from queue
function Remove-ProcessedEntries {
    param(
        [Parameter(Mandatory = $true)]
        [array]$ProcessedLineNumbers
    )

    if ($DryRun) {
        Write-ProcessorLog "[DRY RUN] Would remove $($ProcessedLineNumbers.Count) processed entries from queue" -Level INFO
        return
    }

    if ($ProcessedLineNumbers.Count -eq 0) {
        Write-ProcessorLog "No entries to remove from queue" -Level DEBUG
        return
    }

    try {
        Write-ProcessorLog "Removing $($ProcessedLineNumbers.Count) processed entries from queue" -Level INFO

        # Read all lines
        $allLines = Get-Content -Path $script:Config.QueueFile

        # Filter out processed lines
        $remainingLines = @()
        for ($i = 0; $i -lt $allLines.Count; $i++) {
            $lineNumber = $i + 1
            if ($lineNumber -notin $ProcessedLineNumbers) {
                $remainingLines += $allLines[$i]
            }
        }

        # Write remaining lines to temp file
        $remainingLines | Set-Content -Path $script:Config.TempQueueFile

        # Replace original queue file
        Move-Item -Path $script:Config.TempQueueFile -Destination $script:Config.QueueFile -Force

        Write-ProcessorLog "Queue file updated: $($remainingLines.Count) entries remaining" -Level SUCCESS
    }
    catch {
        Write-ProcessorLog "Failed to remove processed entries: $_" -Level ERROR
    }
}

# Main processing logic
function Main {
    Write-ProcessorLog "========== Notion Queue Processor Started ==========" -Level INFO
    Write-ProcessorLog "Configuration: BatchSize=$BatchSize, MaxRetries=$MaxRetries, DryRun=$DryRun" -Level INFO

    # Get queued entries
    $entries = Get-QueueEntries

    if ($entries.Count -eq 0) {
        Write-ProcessorLog "No entries in queue - exiting" -Level INFO
        return
    }

    # Limit to batch size
    $entriesToProcess = $entries | Select-Object -First $BatchSize

    Write-ProcessorLog "Processing $($entriesToProcess.Count) of $($entries.Count) queued entries" -Level INFO

    # Process each entry
    $results = @{
        Successful = @()
        Failed = @()
    }

    foreach ($entry in $entriesToProcess) {
        $result = Process-Entry -Entry $entry

        if ($result.Success) {
            $results.Successful += $entry.LineNumber
        }
        else {
            $results.Failed += @{
                LineNumber = $entry.LineNumber
                SessionId = $entry.sessionId
                Error = $result.Error
            }
        }
    }

    # Remove successfully processed entries
    if ($results.Successful.Count -gt 0) {
        Remove-ProcessedEntries -ProcessedLineNumbers $results.Successful
    }

    # Summary
    Write-ProcessorLog "========== Processing Complete ==========" -Level INFO
    Write-ProcessorLog "Successfully processed: $($results.Successful.Count)" -Level SUCCESS
    Write-ProcessorLog "Failed: $($results.Failed.Count)" -Level $(if ($results.Failed.Count -gt 0) { "WARNING" } else { "INFO" })

    if ($results.Failed.Count -gt 0) {
        Write-ProcessorLog "Failed entries:" -Level ERROR
        foreach ($failed in $results.Failed) {
            Write-ProcessorLog "  - Line $($failed.LineNumber), SessionId=$($failed.SessionId): $($failed.Error)" -Level ERROR
        }
    }

    # Exit code: 0 = all successful, 1 = some failed, 2 = all failed
    if ($results.Failed.Count -eq 0) {
        exit 0
    }
    elseif ($results.Successful.Count -gt 0) {
        exit 1
    }
    else {
        exit 2
    }
}

# Execute
Main
