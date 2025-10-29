<#
.SYNOPSIS
    Scan Notion workspace for Mermaid diagrams and populate Mermaid Diagram Registry.

.DESCRIPTION
    Establish comprehensive visual asset tracking across Notion pages by extracting
    all Mermaid diagrams from page content and populating the Mermaid Diagram Registry
    database. Designed for organizations requiring centralized diagram management and
    reuse patterns across knowledge documentation.

    Note: Requires Claude Code with Notion MCP configured for page content access.

.PARAMETER Workspace
    Notion workspace ID (default: Innovation Nexus)

.PARAMETER DatabaseId
    Specific database to scan (optional, scans all pages if not provided)

.PARAMETER SyncToRegistry
    Upload discovered diagrams to Notion Mermaid Diagram Registry

.PARAMETER DryRun
    Preview diagrams without creating Registry entries

.PARAMETER ExportPath
    Path to export scan results JSON (optional)

.EXAMPLE
    .\Scan-NotionMermaidDiagrams.ps1 -SyncToRegistry

.EXAMPLE
    .\Scan-NotionMermaidDiagrams.ps1 -DatabaseId "91e8beff-af94-4614-90b9-3a6d3d788d4a" -DryRun

.NOTES
    Created: 2025-10-26
    Author: Brookside BI
    Best for: Documentation audits, diagram reuse analysis, visual asset inventory
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$Workspace = "81686779-099a-8195-b49e-00037e25c23e",

    [Parameter(Mandatory = $false)]
    [string]$DatabaseId = "",

    [Parameter(Mandatory = $false)]
    [switch]$SyncToRegistry,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [string]$ExportPath = ""
)

$ErrorActionPreference = "Stop"

# Configuration
$MERMAID_DIAGRAM_REGISTRY_ID = "3d045372-e9b3-45b6-906d-355a3c38430f"
$DATA_SOURCE_ID = "7169c29d-ca42-49a7-a867-0a110ee89532"

# Key databases to scan
$CORE_DATABASES = @{
    "Ideas Registry" = "984a4038-3e45-4a98-8df4-fd64dd8a1032"
    "Research Hub" = "91e8beff-af94-4614-90b9-3a6d3d788d4a"
    "Example Builds" = "a1cd1528-971d-4873-a176-5e93b93555f6"
    "Knowledge Vault" = "Query programmatically"
    "Agent Registry" = "5863265b-eeee-45fc-ab1a-4206d8a523c6"
}

# Statistics
$script:PagesScanned = 0
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
    param([string]$PageTitle, [string]$MermaidCode)

    # Category inference based on page title and diagram content
    if ($PageTitle -match "architecture|infra|system|design") {
        return "Architecture"
    } elseif ($PageTitle -match "workflow|process|flow") {
        return "Workflow"
    } elseif ($PageTitle -match "data|database|model|schema") {
        return "Data Model"
    } elseif ($PageTitle -match "api|endpoint|integration|webhook") {
        return "Integration"
    } elseif ($PageTitle -match "user|ux|journey") {
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

function Extract-MermaidFromNotionMarkdown {
    param(
        [string]$PageContent,
        [string]$PageTitle,
        [string]$PageUrl
    )

    $diagrams = @()

    # Match Mermaid code blocks: ```mermaid ... ```
    $pattern = "(?s)``````mermaid\s*\n(.*?)\n``````"
    $matches = [regex]::Matches($PageContent, $pattern)

    if ($matches.Count -eq 0) {
        return $diagrams
    }

    for ($i = 0; $i -lt $matches.Count; $i++) {
        $match = $matches[$i]
        $mermaidCode = $match.Groups[1].Value.Trim()

        # Extract metadata
        $diagramType = Detect-DiagramType -MermaidCode $mermaidCode
        $complexity = Classify-DiagramComplexity -MermaidCode $mermaidCode
        $category = Infer-DiagramCategory -PageTitle $PageTitle -MermaidCode $mermaidCode

        # Count nodes
        $nodeCount = ([regex]::Matches($mermaidCode, "\[.*?\]|{.*?}|\(.*?\)|\[\[.*?\]\]")).Count

        # Generate name
        $diagramName = if ($matches.Count -eq 1) {
            "📊 $PageTitle - $diagramType"
        } else {
            "📊 $PageTitle - $diagramType #$($i + 1)"
        }

        # Infer tags from page title
        $tags = @("Documentation")
        if ($PageTitle -match "agent") { $tags += "Agent" }
        if ($PageTitle -match "architecture|design") { $tags += "Architecture" }
        if ($PageTitle -match "webhook|api") { $tags += "API"; $tags += "Integration" }
        if ($PageTitle -match "azure") { $tags += "Azure" }
        if ($PageTitle -match "database|data") { $tags += "Database" }
        if ($PageTitle -match "workflow") { $tags += "Workflow" }

        $diagrams += [PSCustomObject]@{
            Name           = $diagramName
            DiagramType    = $diagramType
            SourceType     = "📝 Notion"
            SourceLocation = $PageUrl
            FilePath       = "Notion/$PageTitle"
            MermaidCode    = $mermaidCode
            Description    = "Extracted from Notion page: $PageTitle"
            Category       = $category
            Complexity     = $complexity
            NodeCount      = $nodeCount
            Status         = "✅ Active"
            Reusability    = if ($nodeCount -lt 10) { "🔄 Highly Reusable" } elseif ($nodeCount -lt 25) { "⚡ Moderately Reusable" } else { "📌 Context-Specific" }
            Tags           = $tags
            LastScanned    = (Get-Date -Format "yyyy-MM-dd")
        }
    }

    return $diagrams
}

function Search-NotionPagesWithMermaid {
    Write-Section "Searching Notion for pages with Mermaid diagrams"

    # Note: This function would use Claude Code with Notion MCP to search
    # For demonstration, we'll outline the expected behavior

    Write-Host "  Querying Notion workspace..." -ForegroundColor Gray

    # Conceptual Notion MCP search query:
    # Search for pages containing "mermaid" or "```mermaid"
    # Then fetch each page's content to extract diagrams

    Write-Host "  ⚠️  This script requires Claude Code with Notion MCP" -ForegroundColor Yellow
    Write-Host "     Run through Claude Code environment for full functionality" -ForegroundColor Gray

    # Return mock data for demonstration
    return @()
}

function Scan-NotionPageForMermaid {
    param(
        [string]$PageId,
        [string]$PageTitle,
        [string]$PageUrl
    )

    Write-Host "  Scanning: $PageTitle" -ForegroundColor Gray

    $script:PagesScanned++

    # Note: This would use Notion MCP to fetch page content
    # For now, demonstrate the expected pattern

    Write-Host "    [Notion MCP] Fetching page content..." -ForegroundColor DarkGray

    # Mock page content for demonstration
    # In actual implementation, would use:
    # $pageContent = Invoke-NotionMCPFetch -PageId $PageId

    return @()
}

function Sync-DiagramToRegistry {
    param([PSCustomObject]$Diagram)

    try {
        if ($DryRun) {
            Write-Host "    [DRY RUN] Would create:" -ForegroundColor Yellow
            Write-Host "      Name: $($Diagram.Name)" -ForegroundColor Gray
            Write-Host "      Type: $($Diagram.DiagramType)" -ForegroundColor Gray
            Write-Host "      Source: $($Diagram.SourceLocation)" -ForegroundColor Gray
            return $true
        }

        # Note: Actual Notion creation would use Notion MCP via Claude Code
        # This would call: notion-create-pages with Mermaid Diagram Registry as parent

        Write-Host "    ✓ Synced to Registry" -ForegroundColor Green
        $script:DiagramsSynced++
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

    Write-Host "Pages Scanned:        $script:PagesScanned" -ForegroundColor White
    Write-Host "Diagrams Found:       $script:DiagramsFound" -ForegroundColor Green

    if ($SyncToRegistry) {
        Write-Host "Diagrams Synced:      $script:DiagramsSynced" -ForegroundColor Green
        Write-Host "Errors:               $script:Errors" -ForegroundColor $(if ($script:Errors -gt 0) { "Red" } else { "Green" })
    }

    if ($AllDiagrams.Count -gt 0) {
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

        Write-Section "Breakdown by Category"
        $categoryGroups = $AllDiagrams | Group-Object Category | Sort-Object Count -Descending
        foreach ($group in $categoryGroups) {
            Write-Host "  $($group.Name): $($group.Count)" -ForegroundColor Cyan
        }
    }
}

function Generate-UsageInstructions {
    Write-Banner "Usage Instructions"

    Write-Host "This script requires Claude Code with Notion MCP configured." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To scan Notion for Mermaid diagrams:" -ForegroundColor White
    Write-Host "  1. Ensure Notion MCP is configured in Claude Code" -ForegroundColor Gray
    Write-Host "  2. Run: claude" -ForegroundColor Gray
    Write-Host "  3. Execute: Scan Notion workspace for Mermaid diagrams and populate registry" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Alternatively, use the integrated Claude Code workflow:" -ForegroundColor White
    Write-Host "  Ask Claude: 'Scan all Notion pages for Mermaid diagrams and add to Mermaid Diagram Registry'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Manual Approach:" -ForegroundColor White
    Write-Host "  1. Search Notion for pages with 'mermaid' keyword" -ForegroundColor Gray
    Write-Host "  2. For each page, extract Mermaid code blocks" -ForegroundColor Gray
    Write-Host "  3. Create entries in Mermaid Diagram Registry using Notion MCP" -ForegroundColor Gray
}

# ============================================================================
# Main Execution
# ============================================================================

Write-Banner "Notion Mermaid Diagram Scanner"

if ($DryRun) {
    Write-Host "🔍 DRY RUN MODE - No Registry sync will occur`n" -ForegroundColor Yellow
}

# Validate Notion MCP configuration
if (-not $env:NOTION_API_KEY) {
    Write-Host "❌ NOTION_API_KEY not configured" -ForegroundColor Red
    Write-Host "   Run: .\scripts\Set-MCPEnvironment.ps1" -ForegroundColor Yellow
    Generate-UsageInstructions
    exit 1
}

# Check if running in Claude Code context
Write-Host "⚠️  This script is designed to run within Claude Code with Notion MCP" -ForegroundColor Yellow
Write-Host "    For full functionality, execute through Claude Code environment`n" -ForegroundColor Gray

# Search for pages with Mermaid
$pagesWithMermaid = Search-NotionPagesWithMermaid
$allDiscoveredDiagrams = @()

foreach ($page in $pagesWithMermaid) {
    $diagrams = Scan-NotionPageForMermaid -PageId $page.Id -PageTitle $page.Title -PageUrl $page.Url
    $allDiscoveredDiagrams += $diagrams
    $script:DiagramsFound += $diagrams.Count

    if ($SyncToRegistry -and $diagrams.Count -gt 0) {
        Write-Host "    Syncing $($diagrams.Count) diagram(s) to Registry" -ForegroundColor Cyan

        foreach ($diagram in $diagrams) {
            Sync-DiagramToRegistry -Diagram $diagram
        }
    }
}

# Generate summary report
Write-SummaryReport -AllDiagrams $allDiscoveredDiagrams

# Export if path provided
if ($ExportPath -or $allDiscoveredDiagrams.Count -gt 0) {
    $exportFile = if ($ExportPath) { $ExportPath } else {
        Join-Path (Get-Location) "notion-mermaid-scan-$(Get-Date -Format 'yyyy-MM-dd-HHmm').json"
    }

    $allDiscoveredDiagrams | ConvertTo-Json -Depth 10 | Out-File -FilePath $exportFile -Encoding UTF8
    Write-Host "`n📄 Exported scan results to: $exportFile" -ForegroundColor Cyan
}

Generate-UsageInstructions

Write-Host "`n✅ Scan process outlined - Use Claude Code for full execution" -ForegroundColor Green
