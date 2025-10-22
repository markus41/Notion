#Requires -Version 5.1
<#
.SYNOPSIS
    Session Context Parser for Brookside BI Innovation Nexus Agent Activity Tracking

.DESCRIPTION
    Helper utility to parse Claude Code session context and extract structured data
    for agent activity logging. Establishes intelligent extraction of deliverables,
    metrics, and work context from tool invocations and file operations.

    Designed for: Organizations requiring accurate AI agent productivity analytics
    through automated parsing of session data to streamline tracking workflows.

.NOTES
    Author: Brookside BI - Claude Code Integration
    Version: 1.0.0
    Last Modified: 2025-10-22
#>

# Configuration
$script:Config = @{
    MaxToolCallsToScan = 50          # Scan last N tool calls for deliverables
    TimeWindowMinutes = 5            # Only scan tool calls within this window
    MinFileSize = 100                # Minimum file size (bytes) to count as deliverable
    EstimatedLinesPerKB = 20         # Rough estimate for lines of code per KB
}

#region File Analysis Functions

<#
.SYNOPSIS
    Extract deliverables from recent file operations

.DESCRIPTION
    Scans recent Edit/Write tool calls to identify files created or modified,
    establishing comprehensive deliverable tracking for productivity analytics.
#>
function Get-SessionDeliverables {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [DateTime]$StartTime = (Get-Date).AddMinutes(-$script:Config.TimeWindowMinutes),

        [Parameter(Mandatory = $false)]
        [string]$WorkingDirectory = (Get-Location).Path
    )

    $deliverables = @{
        FilesCreated = @()
        FilesUpdated = @()
        TotalFiles = 0
        EstimatedLines = 0
        Categories = @{}
    }

    # Scan git log for recent changes (proxy for file operations)
    try {
        $gitLog = git -C $WorkingDirectory log --since="$($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))" --name-status --oneline 2>$null

        if ($gitLog) {
            foreach ($line in $gitLog) {
                # Parse git status lines (A = Added, M = Modified, D = Deleted)
                if ($line -match '^[AMD]\s+(.+)$') {
                    $status = $line[0]
                    $filePath = $Matches[1]

                    if ($status -eq 'A') {
                        $deliverables.FilesCreated += $filePath
                    }
                    elseif ($status -eq 'M') {
                        $deliverables.FilesUpdated += $filePath
                    }

                    # Categorize file
                    $category = Get-FileCategory -FilePath $filePath
                    if (-not $deliverables.Categories.ContainsKey($category)) {
                        $deliverables.Categories[$category] = 0
                    }
                    $deliverables.Categories[$category]++
                }
            }
        }
    }
    catch {
        Write-Warning "Could not parse git log: $_"
    }

    # Fallback: Scan working directory for recently modified files
    if ($deliverables.FilesCreated.Count -eq 0 -and $deliverables.FilesUpdated.Count -eq 0) {
        $recentFiles = Get-ChildItem -Path $WorkingDirectory -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object {
                $_.LastWriteTime -gt $StartTime -and
                $_.Length -gt $script:Config.MinFileSize -and
                $_.FullName -notmatch '\.git|node_modules|__pycache__|\.venv|venv|dist|build'
            } |
            Select-Object -First 20

        foreach ($file in $recentFiles) {
            $relativePath = $file.FullName.Replace("$WorkingDirectory\", "").Replace($WorkingDirectory, "")

            if ($file.CreationTime -gt $StartTime) {
                $deliverables.FilesCreated += $relativePath
            }
            else {
                $deliverables.FilesUpdated += $relativePath
            }

            $category = Get-FileCategory -FilePath $relativePath
            if (-not $deliverables.Categories.ContainsKey($category)) {
                $deliverables.Categories[$category] = 0
            }
            $deliverables.Categories[$category]++
        }
    }

    # Calculate totals
    $deliverables.TotalFiles = $deliverables.FilesCreated.Count + $deliverables.FilesUpdated.Count

    # Estimate lines of code
    foreach ($filePath in ($deliverables.FilesCreated + $deliverables.FilesUpdated)) {
        $fullPath = Join-Path $WorkingDirectory $filePath
        if (Test-Path $fullPath) {
            $fileSize = (Get-Item $fullPath).Length
            $estimatedLines = [Math]::Floor($fileSize / 1024 * $script:Config.EstimatedLinesPerKB)
            $deliverables.EstimatedLines += $estimatedLines
        }
    }

    return $deliverables
}

<#
.SYNOPSIS
    Categorize file by extension and path patterns
#>
function Get-FileCategory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    $fileName = [System.IO.Path]::GetFileName($FilePath).ToLower()

    # Documentation files
    if ($fileName -match '(readme|claude|contributing|license|changelog)\.md' -or
        $FilePath -match 'docs?/|documentation/' -or
        $extension -in @('.md', '.rst', '.txt', '.adoc')) {
        return "Documentation"
    }

    # Code files
    if ($extension -in @('.py', '.js', '.ts', '.tsx', '.jsx', '.cs', '.java', '.go', '.rs', '.cpp', '.c', '.h')) {
        return "Code"
    }

    # Configuration files
    if ($extension -in @('.json', '.yaml', '.yml', '.toml', '.ini', '.conf', '.config', '.xml') -or
        $fileName -in @('dockerfile', '.gitignore', '.env', '.env.example', 'makefile')) {
        return "Configuration"
    }

    # Infrastructure as Code
    if ($extension -in @('.bicep', '.tf', '.tfvars') -or
        $FilePath -match 'infrastructure/|deployment/|terraform/|bicep/') {
        return "Infrastructure"
    }

    # Tests
    if ($FilePath -match 'test|spec|__tests__|\.test\.|\.spec\.' -or
        $extension -in @('.test.js', '.spec.ts', '.test.py')) {
        return "Tests"
    }

    # Scripts
    if ($extension -in @('.ps1', '.sh', '.bash', '.zsh', '.fish', '.bat', '.cmd')) {
        return "Scripts"
    }

    # Data files
    if ($extension -in @('.csv', '.json', '.xml', '.sql', '.db', '.sqlite')) {
        return "Data"
    }

    return "Other"
}

#endregion

#region Session Analysis Functions

<#
.SYNOPSIS
    Calculate session metrics from deliverables and timing data
#>
function Get-SessionMetrics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Deliverables,

        [Parameter(Mandatory = $true)]
        [DateTime]$StartTime,

        [Parameter(Mandatory = $false)]
        [DateTime]$EndTime = (Get-Date)
    )

    $duration = ($EndTime - $StartTime).TotalMinutes

    $metrics = @{
        FilesCreated = $Deliverables.FilesCreated.Count
        FilesUpdated = $Deliverables.FilesUpdated.Count
        TotalFiles = $Deliverables.TotalFiles
        LinesGenerated = $Deliverables.EstimatedLines
        DurationMinutes = [Math]::Round($duration, 2)
        SuccessRate = 100.0  # Default to success unless explicitly marked failed
        Categories = $Deliverables.Categories
    }

    # Calculate productivity metrics
    if ($duration -gt 0) {
        $metrics.FilesPerMinute = [Math]::Round($metrics.TotalFiles / $duration, 2)
        $metrics.LinesPerMinute = [Math]::Round($metrics.LinesGenerated / $duration, 0)
    }
    else {
        $metrics.FilesPerMinute = 0
        $metrics.LinesPerMinute = 0
    }

    return $metrics
}

<#
.SYNOPSIS
    Format deliverables as markdown for logging
#>
function Format-DeliverablesMarkdown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Deliverables
    )

    $markdown = @()

    if ($Deliverables.FilesCreated.Count -gt 0) {
        $markdown += "**Files Created:**"
        foreach ($file in $Deliverables.FilesCreated | Select-Object -First 20) {
            $category = Get-FileCategory -FilePath $file
            $markdown += "- [$file]($file) - $category"
        }
        $markdown += ""
    }

    if ($Deliverables.FilesUpdated.Count -gt 0) {
        $markdown += "**Files Updated:**"
        foreach ($file in $Deliverables.FilesUpdated | Select-Object -First 20) {
            $category = Get-FileCategory -FilePath $file
            $markdown += "- [$file]($file) - $category"
        }
        $markdown += ""
    }

    if ($Deliverables.Categories.Count -gt 0) {
        $markdown += "**Deliverables by Category:**"
        foreach ($category in $Deliverables.Categories.Keys | Sort-Object) {
            $count = $Deliverables.Categories[$category]
            $markdown += "- ${category}: $count files"
        }
    }

    return ($markdown -join "`n")
}

<#
.SYNOPSIS
    Format metrics as markdown for logging
#>
function Format-MetricsMarkdown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Metrics
    )

    $markdown = @(
        "- Files created: $($Metrics.FilesCreated)",
        "- Files updated: $($Metrics.FilesUpdated)",
        "- Total files: $($Metrics.TotalFiles)",
        "- Lines generated: $($Metrics.LinesGenerated.ToString('N0'))",
        "- Duration: $($Metrics.DurationMinutes) minutes",
        "- Success rate: $($Metrics.SuccessRate)%"
    )

    if ($Metrics.FilesPerMinute -gt 0) {
        $markdown += "- Productivity: $($Metrics.FilesPerMinute) files/min, $($Metrics.LinesPerMinute) lines/min"
    }

    return ($markdown -join "`n")
}

#endregion

#region Agent Context Functions

<#
.SYNOPSIS
    Generate session ID for agent work
#>
function New-SessionId {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentName,

        [Parameter(Mandatory = $false)]
        [DateTime]$StartTime = (Get-Date)
    )

    # Remove @ prefix if present
    $agentName = $AgentName.TrimStart('@')

    # Format: agent-name-YYYY-MM-DD-HHMM
    $timestamp = $StartTime.ToString('yyyy-MM-dd-HHmm')
    return "$agentName-$timestamp"
}

<#
.SYNOPSIS
    Detect related Notion items from work description
#>
function Get-RelatedNotionItems {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$WorkDescription = "",

        [Parameter(Mandatory = $false)]
        [hashtable]$Deliverables = @{}
    )

    $related = @{
        Ideas = @()
        Research = @()
        Builds = @()
    }

    # Parse Notion URLs from work description
    if ($WorkDescription -match 'notion\.so/([a-f0-9]{32})') {
        $pageId = $Matches[1]

        # Attempt to categorize based on context
        if ($WorkDescription -match 'idea|concept') {
            $related.Ideas += $pageId
        }
        elseif ($WorkDescription -match 'research|investigation|study') {
            $related.Research += $pageId
        }
        elseif ($WorkDescription -match 'build|prototype|example|deploy') {
            $related.Builds += $pageId
        }
    }

    # Check deliverables for clues about related work
    foreach ($file in ($Deliverables.FilesCreated + $Deliverables.FilesUpdated)) {
        if ($file -match 'idea|concept') {
            # Likely related to an idea
        }
        elseif ($file -match 'research|study|investigation') {
            # Likely related to research
        }
        elseif ($file -match 'build|example|prototype|deploy') {
            # Likely related to a build
        }
    }

    return $related
}

<#
.SYNOPSIS
    Extract next steps from work context
#>
function Get-NextSteps {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$WorkDescription = "",

        [Parameter(Mandatory = $false)]
        [hashtable]$Deliverables = @{}
    )

    $nextSteps = @()

    # Parse work description for explicit next steps
    if ($WorkDescription -match 'next\s+steps?:?\s*(.+)') {
        $nextSteps += $Matches[1]
    }

    # Infer next steps based on deliverables
    if ($Deliverables.Categories.ContainsKey("Infrastructure")) {
        $nextSteps += "Deploy infrastructure to Azure environment"
    }

    if ($Deliverables.Categories.ContainsKey("Code")) {
        $nextSteps += "Test code implementation"
        $nextSteps += "Update documentation"
    }

    if ($Deliverables.Categories.ContainsKey("Documentation")) {
        $nextSteps += "Review documentation for accuracy"
    }

    return $nextSteps
}

#endregion

#region Export Functions

<#
.SYNOPSIS
    Build complete session context for activity logger
#>
function New-SessionContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentName,

        [Parameter(Mandatory = $false)]
        [string]$WorkDescription = "",

        [Parameter(Mandatory = $false)]
        [DateTime]$StartTime = (Get-Date).AddMinutes(-5),

        [Parameter(Mandatory = $false)]
        [DateTime]$EndTime = (Get-Date),

        [Parameter(Mandatory = $false)]
        [string]$Status = "completed",

        [Parameter(Mandatory = $false)]
        [string]$WorkingDirectory = (Get-Location).Path
    )

    # Generate session ID
    $sessionId = New-SessionId -AgentName $AgentName -StartTime $StartTime

    # Extract deliverables
    $deliverables = Get-SessionDeliverables -StartTime $StartTime -WorkingDirectory $WorkingDirectory

    # Calculate metrics
    $metrics = Get-SessionMetrics -Deliverables $deliverables -StartTime $StartTime -EndTime $EndTime

    # Format for logging
    $deliverablesMarkdown = Format-DeliverablesMarkdown -Deliverables $deliverables
    $metricsMarkdown = Format-MetricsMarkdown -Metrics $metrics

    # Detect related work
    $relatedItems = Get-RelatedNotionItems -WorkDescription $WorkDescription -Deliverables $deliverables

    # Extract next steps
    $nextSteps = Get-NextSteps -WorkDescription $WorkDescription -Deliverables $deliverables

    # Build complete context
    $context = @{
        SessionId = $sessionId
        AgentName = $AgentName
        Status = $Status
        WorkDescription = $WorkDescription
        StartTime = $StartTime.ToString('yyyy-MM-ddTHH:mm:ssZ')
        EndTime = $EndTime.ToString('yyyy-MM-ddTHH:mm:ssZ')
        DurationMinutes = $metrics.DurationMinutes

        # Deliverables
        Deliverables = $deliverables
        DeliverablesMarkdown = $deliverablesMarkdown

        # Metrics
        Metrics = $metrics
        MetricsMarkdown = $metricsMarkdown

        # Relations
        RelatedIdeas = $relatedItems.Ideas
        RelatedResearch = $relatedItems.Research
        RelatedBuilds = $relatedItems.Builds

        # Next Steps
        NextSteps = $nextSteps
    }

    return $context
}

#endregion

# Export functions for use in other scripts (via dot-sourcing)
# Note: Use dot-sourcing to load functions: . .\session-parser.ps1
# Available functions:
#   - Get-SessionDeliverables
#   - Get-SessionMetrics
#   - Format-DeliverablesMarkdown
#   - Format-MetricsMarkdown
#   - New-SessionId
#   - Get-RelatedNotionItems
#   - Get-NextSteps
#   - New-SessionContext
#   - Get-FileCategory
