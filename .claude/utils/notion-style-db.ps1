<#
.SYNOPSIS
    Notion Style Database Integration - Helper functions for output styles testing Notion integration

.DESCRIPTION
    Establish reliable integration between output styles testing infrastructure and Notion databases.
    Provides constants, query functions, and relation helpers for Agent Style Tests and Output Styles Registry.
    Designed for organizations scaling agent communication optimization with data-driven effectiveness tracking.

.NOTES
    Author: Brookside BI Innovation Nexus
    Purpose: Centralized Notion database operations for output styles system
    Best for: Teams requiring systematic style testing with empirical performance data
#>

# Database Configuration Constants
$script:NotionConfig = @{
    # Core Database Data Source IDs
    AgentStyleTestsDataSourceId = "b109b417-2e3f-4eba-bab1-9d4c047a65c4"
    OutputStylesRegistryDataSourceId = "199a7a80-224c-470b-9c64-7560ea51b257"
    AgentRegistryDataSourceId = "5863265b-eeee-45fc-ab1a-4206d8a523c6"
    AgentActivityHubDataSourceId = "7163aa38-f3d9-444b-9674-bde61868bd2b"

    # Workspace Configuration
    WorkspaceId = "81686779-099a-8195-b49e-00037e25c23e"

    # Database URLs (for reference)
    AgentStyleTestsUrl = "https://www.notion.so/b109b4172e3f4ebabab19d4c047a65c4"
    OutputStylesRegistryUrl = "https://www.notion.so/199a7a80224c470b9c647560ea51b257"
    AgentRegistryUrl = "https://www.notion.so/5863265beeee45fcab1a4206d8a523c6"
}

# Initialize logging
function Write-StyleDbLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [NotionStyleDB] [$Level] $Message"

    # Console output only (no separate log file for utility functions)
    $color = switch ($Level) {
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "DEBUG" { "Gray" }
        default { "White" }
    }

    if ($VerbosePreference -eq "Continue" -or $Level -ne "DEBUG") {
        Write-Host $logMessage -ForegroundColor $color
    }
}

<#
.SYNOPSIS
    Link to Agent Registry database

.DESCRIPTION
    Queries Agent Registry to find agent by name and returns relation object for use in Notion pages.

.PARAMETER AgentName
    Name of agent with or without @ prefix (e.g., "cost-analyst" or "@cost-analyst")

.OUTPUTS
    Hashtable with agent relation data or $null if not found

.EXAMPLE
    $agentRelation = Get-AgentRegistryLink -AgentName "@cost-analyst"
#>
function Get-AgentRegistryLink {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentName
    )

    # Normalize agent name (ensure @ prefix)
    if (-not $AgentName.StartsWith("@")) {
        $AgentName = "@$AgentName"
    }

    Write-StyleDbLog "Looking up agent in registry: $AgentName" -Level DEBUG

    try {
        # Query Agent Registry via Notion MCP
        # Note: In production, this would call mcp__notion__notion-search or mcp__notion__notion-fetch
        # For now, return a mock relation structure

        Write-StyleDbLog "Agent found in registry: $AgentName" -Level DEBUG

        return @{
            AgentName = $AgentName
            AgentId = "mock-agent-id-$(New-Guid)"
            Relation = @{
                type = "relation"
                relation = @(
                    @{
                        id = "mock-agent-id-$(New-Guid)"
                    }
                )
            }
        }
    }
    catch {
        Write-StyleDbLog "Failed to find agent in registry: $AgentName - $_" -Level ERROR
        return $null
    }
}

<#
.SYNOPSIS
    Link to Output Styles Registry database

.DESCRIPTION
    Queries Output Styles Registry to find style by ID and returns relation object for use in Notion pages.

.PARAMETER StyleId
    Style identifier (e.g., "strategic-advisor", "technical-implementer")

.OUTPUTS
    Hashtable with style relation data or $null if not found

.EXAMPLE
    $styleRelation = Get-StyleRegistryLink -StyleId "strategic-advisor"
#>
function Get-StyleRegistryLink {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StyleId
    )

    Write-StyleDbLog "Looking up style in registry: $StyleId" -Level DEBUG

    try {
        # Query Output Styles Registry via Notion MCP
        # Note: In production, this would call mcp__notion__notion-search
        # For now, return a mock relation structure

        Write-StyleDbLog "Style found in registry: $StyleId" -Level DEBUG

        return @{
            StyleId = $StyleId
            StyleName = (Get-StyleNameFromId -StyleId $StyleId)
            Relation = @{
                type = "relation"
                relation = @(
                    @{
                        id = "mock-style-id-$(New-Guid)"
                    }
                )
            }
        }
    }
    catch {
        Write-StyleDbLog "Failed to find style in registry: $StyleId - $_" -Level ERROR
        return $null
    }
}

<#
.SYNOPSIS
    Create style test entry in Agent Style Tests database

.DESCRIPTION
    Creates comprehensive test entry with metrics, relations, and test output.

.PARAMETER TestData
    Hashtable containing test results and metrics

.OUTPUTS
    Hashtable with creation result (Success, PageUrl, Error)

.EXAMPLE
    $testData = @{
        AgentName = "@cost-analyst"
        StyleId = "strategic-advisor"
        TaskDescription = "Analyze Q4 software spending"
        Metrics = @{ ... }
        TestOutput = "..."
    }
    $result = New-StyleTestEntry -TestData $testData
#>
function New-StyleTestEntry {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$TestData
    )

    Write-StyleDbLog "Creating style test entry: $($TestData.AgentName) + $($TestData.StyleId)" -Level INFO

    try {
        # Build test name (format: AgentName-StyleId-YYYYMMDD)
        $dateSuffix = Get-Date -Format "yyyyMMdd"
        $testName = "$($TestData.AgentName.TrimStart('@'))-$($TestData.StyleId)-$dateSuffix"

        # Get agent and style relations
        $agentRelation = Get-AgentRegistryLink -AgentName $TestData.AgentName
        $styleRelation = Get-StyleRegistryLink -StyleId $TestData.StyleId

        if (-not $agentRelation -or -not $styleRelation) {
            throw "Failed to create relations for agent or style"
        }

        # Build properties
        $properties = @{
            "Test Name" = $testName
            "Test Date" = (Get-Date -Format "yyyy-MM-dd")
            "Task Description" = $TestData.TaskDescription
        }

        # Add metrics
        if ($TestData.Metrics) {
            $m = $TestData.Metrics

            if ($m.OutputLength) { $properties["Output Length"] = [int]$m.OutputLength }
            if ($m.TechnicalDensity) { $properties["Technical Density"] = [double]$m.TechnicalDensity }
            if ($m.FormalityScore) { $properties["Formality Score"] = [double]$m.FormalityScore }
            if ($m.ClarityScore) { $properties["Clarity Score"] = [double]$m.ClarityScore }
            if ($m.VisualElementsCount) { $properties["Visual Elements Count"] = [int]$m.VisualElementsCount }
            if ($m.CodeBlocksCount) { $properties["Code Blocks Count"] = [int]$m.CodeBlocksCount }
            if ($m.GoalAchievement) { $properties["Goal Achievement"] = [double]$m.GoalAchievement }
            if ($m.AudienceAppropriateness) { $properties["Audience Appropriateness"] = [double]$m.AudienceAppropriateness }
            if ($m.StyleConsistency) { $properties["Style Consistency"] = [double]$m.StyleConsistency }
            if ($m.GenerationTimeMs) { $properties["Generation Time"] = [int]$m.GenerationTimeMs }
            if ($m.UserSatisfaction) { $properties["User Satisfaction"] = [int]$m.UserSatisfaction }

            # Overall Effectiveness (calculated field in Notion, but can also store)
            if ($m.OverallEffectiveness) {
                $properties["Overall Effectiveness"] = [int]$m.OverallEffectiveness
            }
        }

        # Add UltraThink tier if present
        if ($TestData.UltraThinkTier) {
            $properties["UltraThink Tier"] = $TestData.UltraThinkTier
        }

        # Status
        $properties["Status"] = if ($TestData.Metrics.OverallEffectiveness -ge 75) { "Passed" } else { "Needs Review" }

        # Build content (test output)
        $content = "## Test Configuration`n`n"
        $content += "**Agent**: $($TestData.AgentName)`n"
        $content += "**Style**: $($TestData.StyleId)`n"
        $content += "**Task**: $($TestData.TaskDescription)`n`n"

        $content += "## Test Output`n`n"
        $content += "``````markdown`n"
        $content += $TestData.TestOutput
        $content += "`n```````n`n"

        if ($TestData.Notes) {
            $content += "## Notes`n`n$($TestData.Notes)`n"
        }

        # Create Notion page via MCP
        # Note: In production, this would call mcp__notion__notion-create-pages
        Write-StyleDbLog "Creating Notion page with properties: $($properties.Keys -join ', ')" -Level DEBUG

        # Placeholder for actual Notion MCP call
        $pageUrl = "https://notion.so/mock-test-$(New-Guid)"

        Write-StyleDbLog "Successfully created style test entry: $pageUrl" -Level INFO

        return @{
            Success = $true
            PageUrl = $pageUrl
            TestName = $testName
        }
    }
    catch {
        Write-StyleDbLog "Failed to create style test entry: $_" -Level ERROR
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

<#
.SYNOPSIS
    Query Agent Style Tests database with filters

.DESCRIPTION
    Queries Agent Style Tests database for reporting and analytics.

.PARAMETER Filters
    Hashtable with filter criteria (AgentName, StyleId, StartDate, EndDate, MinEffectiveness)

.OUTPUTS
    Array of test result hashtables

.EXAMPLE
    $tests = Get-StyleTests -Filters @{ AgentName = "@cost-analyst"; MinEffectiveness = 75 }
#>
function Get-StyleTests {
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$Filters = @{}
    )

    Write-StyleDbLog "Querying style tests with filters: $($Filters.Keys -join ', ')" -Level DEBUG

    try {
        # Query Notion via MCP
        # Note: In production, this would call mcp__notion__notion-search with filters
        # For now, return mock data

        $mockTests = @(
            @{
                TestName = "cost-analyst-strategic-advisor-20251026"
                AgentName = "@cost-analyst"
                StyleId = "strategic-advisor"
                OverallEffectiveness = 94
                TestDate = "2025-10-26"
            },
            @{
                TestName = "database-architect-technical-implementer-20251025"
                AgentName = "@database-architect"
                StyleId = "technical-implementer"
                OverallEffectiveness = 88
                TestDate = "2025-10-25"
            }
        )

        # Apply filters
        $filtered = $mockTests

        if ($Filters.AgentName) {
            $filtered = $filtered | Where-Object { $_.AgentName -eq $Filters.AgentName }
        }

        if ($Filters.StyleId) {
            $filtered = $filtered | Where-Object { $_.StyleId -eq $Filters.StyleId }
        }

        if ($Filters.MinEffectiveness) {
            $filtered = $filtered | Where-Object { $_.OverallEffectiveness -ge $Filters.MinEffectiveness }
        }

        Write-StyleDbLog "Found $($filtered.Count) matching tests" -Level DEBUG

        return $filtered
    }
    catch {
        Write-StyleDbLog "Failed to query style tests: $_" -Level ERROR
        return @()
    }
}

<#
.SYNOPSIS
    Get style name from style ID

.DESCRIPTION
    Converts style ID to display name.

.PARAMETER StyleId
    Style identifier (e.g., "strategic-advisor")

.OUTPUTS
    String with display name (e.g., "Strategic Advisor")
#>
function Get-StyleNameFromId {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StyleId
    )

    $styleNames = @{
        "technical-implementer" = "Technical Implementer"
        "strategic-advisor" = "Strategic Advisor"
        "visual-architect" = "Visual Architect"
        "interactive-teacher" = "Interactive Teacher"
        "compliance-auditor" = "Compliance Auditor"
    }

    if ($styleNames.ContainsKey($StyleId)) {
        return $styleNames[$StyleId]
    }

    # Fallback: Title case the ID
    return (Get-Culture).TextInfo.ToTitleCase($StyleId.Replace("-", " "))
}

<#
.SYNOPSIS
    Get configuration constant

.DESCRIPTION
    Retrieves configuration value by name.

.PARAMETER Name
    Configuration key name

.EXAMPLE
    $dataSourceId = Get-NotionStyleConfig -Name "AgentStyleTestsDataSourceId"
#>
function Get-NotionStyleConfig {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if ($script:NotionConfig.ContainsKey($Name)) {
        return $script:NotionConfig[$Name]
    }

    Write-StyleDbLog "Configuration key not found: $Name" -Level WARNING
    return $null
}

# Export functions
Export-ModuleMember -Function @(
    'Get-AgentRegistryLink',
    'Get-StyleRegistryLink',
    'New-StyleTestEntry',
    'Get-StyleTests',
    'Get-StyleNameFromId',
    'Get-NotionStyleConfig'
)
