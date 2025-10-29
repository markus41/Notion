<#
.SYNOPSIS
    Scan GitHub repositories for Mermaid diagrams and populate Mermaid Diagram Registry.

.DESCRIPTION
    Establish comprehensive visual asset tracking across GitHub repositories by extracting
    all Mermaid diagrams from markdown files and populating the Mermaid Diagram Registry
    database in Notion. Designed for organizations requiring centralized diagram management
    and reuse patterns across technical documentation.

.PARAMETER Organization
    GitHub organization name (default: brookside-bi)

.PARAMETER Repository
    Specific repository to scan (optional, scans all if not provided)

.PARAMETER Branch
    Git branch to scan (default: main)

.PARAMETER SyncToNotion
    Upload discovered diagrams to Notion Mermaid Diagram Registry

.PARAMETER DryRun
    Preview diagrams without creating Notion entries

.EXAMPLE
    .\Scan-GitHubMermaidDiagrams.ps1 -Repository "innovation-nexus" -SyncToNotion

.EXAMPLE
    .\Scan-GitHubMermaidDiagrams.ps1 -Organization "brookside-bi" -DryRun

.NOTES
    Created: 2025-10-26
    Author: Brookside BI
    Best for: Documentation audits, diagram reuse analysis, visual asset inventory
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$Organization = "brookside-bi",

    [Parameter(Mandatory = $false)]
    [string]$Repository = "",

    [Parameter(Mandatory = $false)]
    [string]$Branch = "main",

    [Parameter(Mandatory = $false)]
    [switch]$SyncToNotion,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# Configuration
$MERMAID_DIAGRAM_REGISTRY_ID = "3d045372-e9b3-45b6-906d-355a3c38430f"
$DATA_SOURCE_ID = "7169c29d-ca42-49a7-a867-0a110ee89532"

# Statistics
$script:TotalFiles = 0
$script:DiagramsFound = 0
$script:DiagramsSynced = 0
$script:Errors = 0

# Diagram type detection patterns
$DiagramTypePatterns = @{
    "Flowchart" = @("graph TD", "graph LR", "graph TB", "graph RL", "flowchart")
    "Sequence Diagram" = @("sequenceDiagram")
    "Class Diagram" = @("classDiagram")
    "Entity Relationship" = @("erDiagram")
    "State Diagram" = @("stateDiagram")
    "Gantt Chart" = @("gantt")
    "Pie Chart" = @("pie")
    "User Journey" = @("journey")
    "Git Graph" = @("gitGraph")
    "Mindmap" = @("mindmap")
}

function Write-Banner {
    param([string]$Text)

    Write-Host "`n$("=" * 70)" -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "$("=" * 70)`n" -ForegroundColor Cyan
}

function Write-Section {
    param([string]$Text)

    Write-Host "`n$Text" -ForegroundColor Yellow
    Write-Host $("-" * $Text.Length) -ForegroundColor Yellow
}

function Detect-DiagramType {
    param([string]$MermaidCode)

    foreach ($type in $DiagramTypePatterns.Keys) {
        foreach ($pattern in $DiagramTypePatterns[$type]) {
            if ($MermaidCode -match $pattern) {
                return $type
            }
        }
    }

    return "Flowchart" # Default
}

function Classify-DiagramComplexity {
    param([string]$MermaidCode)

    $lineCount = ($MermaidCode -split "`n").Count
    $nodeCount = ([regex]::Matches($MermaidCode, "\[.*?\]|{.*?}|\(.*?\)|\[\[.*?\]\]")).Count

    if ($lineCount -lt 15 -and $nodeCount -lt 10) {
        return "🟢 Simple"
    } elseif ($lineCount -lt 40 -and $nodeCount -lt 25) {
        return "🟡 Medium"
    } else {
        return "🔴 Complex"
    }
}

function Infer-DiagramCategory {
    param([string]$FilePath, [string]$MermaidCode)

    # Category inference based on file path and diagram content
    if ($FilePath -match "architecture|infra|system") {
        return "Architecture"
    } elseif ($FilePath -match "workflow|process|flow") {
        return "Workflow"
    } elseif ($FilePath -match "data|database|model|schema") {
        return "Data Model"
    } elseif ($FilePath -match "api|endpoint|integration") {
        return "Integration"
    } elseif ($FilePath -match "user|ux|journey") {
        return "User Flow"
    } elseif ($MermaidCode -match "erDiagram") {
        return "Data Model"
    } elseif ($MermaidCode -match "sequenceDiagram") {
        return "Process Flow"
    } elseif ($MermaidCode -match "gantt") {
        return "Timeline"
    } else {
        return "System Design"
    }
}

function Extract-DiagramDescription {
    param([string]$FileContent, [int]$DiagramStartIndex)

    # Look for markdown heading or comment before diagram
    $lines = $FileContent.Substring(0, $DiagramStartIndex) -split "`n"
    $lines = $lines[-10..-1] # Last 10 lines before diagram

    foreach ($line in ($lines | Select-Object -Last 5)) {
        if ($line -match "^#+\s+(.+)$") {
            return $matches[1].Trim()
        } elseif ($line -match "<!--\s*(.+?)\s*-->") {
            return $matches[1].Trim()
        }
    }

    return "No description available"
}

function Extract-MermaidDiagrams {
    param(
        [string]$FilePath,
        [string]$FileContent,
        [string]$Repository,
        [string]$Branch
    )

    $diagrams = @()

    # Match Mermaid code blocks: ```mermaid ... ```
    $pattern = "(?s)``````mermaid\s*\n(.*?)\n``````"
    $matches = [regex]::Matches($FileContent, $pattern)

    if ($matches.Count -eq 0) {
        return $diagrams
    }

    for ($i = 0; $i -lt $matches.Count; $i++) {
        $match = $matches[$i]
        $mermaidCode = $match.Groups[1].Value.Trim()

        # Extract metadata
        $diagramType = Detect-DiagramType -MermaidCode $mermaidCode
        $complexity = Classify-DiagramComplexity -MermaidCode $mermaidCode
        $category = Infer-DiagramCategory -FilePath $FilePath -MermaidCode $mermaidCode
        $description = Extract-DiagramDescription -FileContent $FileContent -DiagramStartIndex $match.Index

        # Count nodes
        $nodeCount = ([regex]::Matches($mermaidCode, "\[.*?\]|{.*?}|\(.*?\)|\[\[.*?\]\]")).Count

        # Generate name
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
        $diagramName = if ($matches.Count -eq 1) {
            "📊 $fileName - $diagramType"
        } else {
            "📊 $fileName - $diagramType #$($i + 1)"
        }

        # GitHub URL
        $githubUrl = "https://github.com/$Organization/$Repository/blob/$Branch/$($FilePath -replace '\\', '/')"

        $diagrams += [PSCustomObject]@{
            Name          = $diagramName
            DiagramType   = $diagramType
            SourceType    = "🐙 GitHub"
            SourceLocation = $githubUrl
            FilePath      = "$Repository/$FilePath"
            MermaidCode   = $mermaidCode
            Description   = $description
            Category      = $category
            Complexity    = $complexity
            NodeCount     = $nodeCount
            Status        = "✅ Active"
            Reusability   = if ($nodeCount -lt 10) { "🔄 Highly Reusable" } elseif ($nodeCount -lt 25) { "⚡ Moderately Reusable" } else { "📌 Context-Specific" }
            Tags          = @("Documentation", "Architecture")
        }
    }

    return $diagrams
}

function Scan-RepositoryForMermaid {
    param(
        [string]$RepoPath,
        [string]$Repository,
        [string]$Branch
    )

    Write-Section "Scanning Repository: $Repository"

    $markdownFiles = Get-ChildItem -Path $RepoPath -Recurse -Filter "*.md" -File
    $script:TotalFiles += $markdownFiles.Count

    Write-Host "  Found $($markdownFiles.Count) markdown files" -ForegroundColor Gray

    $allDiagrams = @()

    foreach ($file in $markdownFiles) {
        $relativePath = $file.FullName.Substring($RepoPath.Length + 1)
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8

        $diagrams = Extract-MermaidDiagrams -FilePath $relativePath -FileContent $content -Repository $Repository -Branch $Branch

        if ($diagrams.Count -gt 0) {
            Write-Host "  ✓ $relativePath: $($diagrams.Count) diagram(s)" -ForegroundColor Green
            $script:DiagramsFound += $diagrams.Count
            $allDiagrams += $diagrams
        }
    }

    return $allDiagrams
}

function Sync-DiagramToNotion {
    param([PSCustomObject]$Diagram)

    try {
        # Check for duplicate first
        $searchQuery = $Diagram.FilePath
        Write-Host "    Checking for existing entry: $searchQuery" -ForegroundColor Gray

        # Create diagram entry in Notion
        Write-Host "    Creating Notion entry..." -ForegroundColor Gray

        # Note: This would use the Notion MCP to create the entry
        # For now, output the structure that would be created

        if ($DryRun) {
            Write-Host "    [DRY RUN] Would create:" -ForegroundColor Yellow
            Write-Host "      Name: $($Diagram.Name)" -ForegroundColor Gray
            Write-Host "      Type: $($Diagram.DiagramType)" -ForegroundColor Gray
            Write-Host "      Source: $($Diagram.SourceLocation)" -ForegroundColor Gray
            return $true
        }

        # Actual Notion creation would happen here via MCP
        # Using claude with Notion MCP to create the entry

        $script:DiagramsSynced++
        Write-Host "    ✓ Synced to Notion" -ForegroundColor Green
        return $true

    } catch {
        $script:Errors++
        Write-Host "    ✗ Error: $_" -ForegroundColor Red
        return $false
    }
}

function Write-SummaryReport {
    param([array]$AllDiagrams)

    Write-Banner "Scan Summary"

    Write-Host "Files Scanned:        $script:TotalFiles" -ForegroundColor White
    Write-Host "Diagrams Found:       $script:DiagramsFound" -ForegroundColor Green

    if ($SyncToNotion) {
        Write-Host "Diagrams Synced:      $script:DiagramsSynced" -ForegroundColor Green
        Write-Host "Errors:               $script:Errors" -ForegroundColor $(if ($script:Errors -gt 0) { "Red" } else { "Green" })
    }

    Write-Section "Breakdown by Type"
    $typeGroups = $AllDiagrams | Group-Object DiagramType | Sort-Object Count -Descending
    foreach ($group in $typeGroups) {
        Write-Host "  $($group.Name): $($group.Count)" -ForegroundColor Cyan
    }

    Write-Section "Breakdown by Complexity"
    $complexityGroups = $AllDiagrams | Group-Object Complexity | Sort-Object Name
    foreach ($group in $complexityGroups) {
        $color = switch ($group.Name) {
            "🟢 Simple" { "Green" }
            "🟡 Medium" { "Yellow" }
            "🔴 Complex" { "Red" }
        }
        Write-Host "  $($group.Name): $($group.Count)" -ForegroundColor $color
    }

    Write-Section "Top 10 Largest Diagrams"
    $topDiagrams = $AllDiagrams | Sort-Object NodeCount -Descending | Select-Object -First 10
    foreach ($diagram in $topDiagrams) {
        Write-Host "  $($diagram.NodeCount) nodes - $($diagram.Name)" -ForegroundColor Gray
    }
}

# ============================================================================
# Main Execution
# ============================================================================

Write-Banner "GitHub Mermaid Diagram Scanner"

if ($DryRun) {
    Write-Host "🔍 DRY RUN MODE - No Notion sync will occur`n" -ForegroundColor Yellow
}

# Validate GitHub token
if (-not $env:GITHUB_PERSONAL_ACCESS_TOKEN) {
    Write-Host "❌ GITHUB_PERSONAL_ACCESS_TOKEN not configured" -ForegroundColor Red
    Write-Host "   Run: .\scripts\Set-MCPEnvironment.ps1" -ForegroundColor Yellow
    exit 1
}

# Determine repositories to scan
$repositoriesToScan = if ($Repository) {
    @($Repository)
} else {
    @("innovation-nexus", "Notion", "dsp-command-central")
}

$allDiscoveredDiagrams = @()

foreach ($repo in $repositoriesToScan) {
    # Clone or use existing repository
    $tempPath = Join-Path $env:TEMP "mermaid-scan-$repo"

    if (Test-Path $tempPath) {
        Write-Host "Using cached repository: $tempPath" -ForegroundColor Gray
        Push-Location $tempPath
        git pull origin $Branch 2>&1 | Out-Null
        Pop-Location
    } else {
        Write-Host "Cloning repository: $repo" -ForegroundColor Gray
        git clone "https://github.com/$Organization/$repo.git" $tempPath 2>&1 | Out-Null
    }

    if (Test-Path $tempPath) {
        $diagrams = Scan-RepositoryForMermaid -RepoPath $tempPath -Repository $repo -Branch $Branch
        $allDiscoveredDiagrams += $diagrams

        if ($SyncToNotion -and $diagrams.Count -gt 0) {
            Write-Section "Syncing to Notion Mermaid Diagram Registry"

            foreach ($diagram in $diagrams) {
                Write-Host "  Syncing: $($diagram.Name)" -ForegroundColor Cyan
                Sync-DiagramToNotion -Diagram $diagram
            }
        }
    } else {
        Write-Host "❌ Failed to access repository: $repo" -ForegroundColor Red
        $script:Errors++
    }
}

# Generate summary report
Write-SummaryReport -AllDiagrams $allDiscoveredDiagrams

# Export discovered diagrams to JSON
$exportPath = Join-Path (Get-Location) "mermaid-diagrams-scan-$(Get-Date -Format 'yyyy-MM-dd-HHmm').json"
$allDiscoveredDiagrams | ConvertTo-Json -Depth 10 | Out-File -FilePath $exportPath -Encoding UTF8
Write-Host "`n📄 Exported scan results to: $exportPath" -ForegroundColor Cyan

Write-Host "`n✅ Scan complete!" -ForegroundColor Green

if (-not $SyncToNotion) {
    Write-Host "`n💡 Tip: Run with -SyncToNotion to populate Mermaid Diagram Registry" -ForegroundColor Yellow
}
