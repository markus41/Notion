# Update-NotionRelations.ps1
# Establish scalable approach for bulk Notion relation property updates via direct API
# Designed for: Bypassing MCP limitations when linking multiple items to relation properties

<#
.SYNOPSIS
    Updates a Notion page's relation property with multiple linked page IDs.

.DESCRIPTION
    This script directly invokes the Notion REST API to update relation properties
    with arrays of page IDs, circumventing the Notion MCP limitation that prevents
    array-based relation updates. Designed for bulk software dependency linking
    and other multi-relation scenarios.

.PARAMETER PageId
    The Notion page ID to update (36-character UUID with or without hyphens).

.PARAMETER PropertyName
    The exact name of the relation property (e.g., "Software/Tools Used").

.PARAMETER RelationIds
    Array of Notion page IDs to link. These will be ADDED to existing relations
    (append behavior) or REPLACE all relations depending on -ReplaceAll switch.

.PARAMETER ReplaceAll
    If specified, replaces all existing relations. Default is to append.

.PARAMETER NotionApiKey
    Optional. If not provided, retrieves from Azure Key Vault (kv-brookside-secrets).

.EXAMPLE
    .\Update-NotionRelations.ps1 `
        -PageId "29886779-099a-8175-8e1c-f09c7ad4788b" `
        -PropertyName "Software/Tools Used" `
        -RelationIds @(
            "29586779-099a-818b-a39c-f2a010682014",  # GitHub Enterprise
            "29586779-099a-81c2-b981-eb92a51a5898",  # Azure Cosmos DB
            "29586779-099a-81fc-9ebe-e0a9783c05c0"   # Azure Storage
        )

    Adds three software dependencies to Repository Analyzer build, preserving existing links.

.EXAMPLE
    .\Update-NotionRelations.ps1 `
        -PageId "abc123" `
        -PropertyName "Team Members" `
        -RelationIds @("user-id-1", "user-id-2") `
        -ReplaceAll

    Replaces all team member assignments with two specific users.

.NOTES
    Best for: Bulk operations (>10 relations), repeated patterns, CI/CD integration
    Use manual UI: For <10 relations, one-time updates
    Requires: Azure CLI authentication for Key Vault access (unless -NotionApiKey provided)
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9a-f]{8}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{12}$')]
    [string]$PageId,

    [Parameter(Mandatory = $true)]
    [string]$PropertyName,

    [Parameter(Mandatory = $true)]
    [string[]]$RelationIds,

    [Parameter(Mandatory = $false)]
    [switch]$ReplaceAll,

    [Parameter(Mandatory = $false)]
    [string]$NotionApiKey
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ===== Functions =====

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Level = "Info"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "Info"    { "Cyan" }
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error"   { "Red" }
    }

    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Get-NotionApiKey {
    if ($NotionApiKey) {
        Write-Log "Using provided API key" -Level Info
        return $NotionApiKey
    }

    Write-Log "Retrieving Notion API key from Azure Key Vault..." -Level Info

    # Check if Get-KeyVaultSecret.ps1 exists
    $kvScriptPath = Join-Path $PSScriptRoot "Get-KeyVaultSecret.ps1"
    if (-not (Test-Path $kvScriptPath)) {
        throw "Get-KeyVaultSecret.ps1 not found at $kvScriptPath. Please provide -NotionApiKey parameter."
    }

    try {
        $apiKey = & $kvScriptPath -SecretName "notion-api-key" -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($apiKey)) {
            throw "Retrieved API key is empty"
        }
        Write-Log "API key retrieved successfully" -Level Success
        return $apiKey
    }
    catch {
        throw "Failed to retrieve Notion API key from Key Vault: $_"
    }
}

function Get-ExistingRelations {
    param(
        [string]$PageId,
        [string]$ApiKey
    )

    Write-Log "Fetching current page state to preserve existing relations..." -Level Info

    $headers = @{
        "Authorization"  = "Bearer $ApiKey"
        "Notion-Version" = "2022-06-28"
        "Content-Type"   = "application/json"
    }

    try {
        $response = Invoke-RestMethod `
            -Uri "https://api.notion.com/v1/pages/$PageId" `
            -Method GET `
            -Headers $headers

        $property = $response.properties.$PropertyName
        if (-not $property) {
            throw "Property '$PropertyName' not found on page"
        }

        if ($property.type -ne "relation") {
            throw "Property '$PropertyName' is not a relation property (type: $($property.type))"
        }

        $existingIds = $property.relation | ForEach-Object { $_.id }
        Write-Log "Found $($existingIds.Count) existing relations" -Level Info
        return $existingIds
    }
    catch {
        throw "Failed to fetch existing relations: $_"
    }
}

function Update-PageRelations {
    param(
        [string]$PageId,
        [string]$ApiKey,
        [string]$PropertyName,
        [string[]]$AllRelationIds
    )

    Write-Log "Updating page with $($AllRelationIds.Count) total relations..." -Level Info

    # Build Notion API request body
    $relationObjects = $AllRelationIds | ForEach-Object {
        @{ id = $_ }
    }

    $body = @{
        properties = @{
            $PropertyName = @{
                relation = $relationObjects
            }
        }
    } | ConvertTo-Json -Depth 10

    $headers = @{
        "Authorization"  = "Bearer $ApiKey"
        "Notion-Version" = "2022-06-28"
        "Content-Type"   = "application/json"
    }

    if ($PSCmdlet.ShouldProcess("Page $PageId", "Update $PropertyName with $($AllRelationIds.Count) relations")) {
        try {
            $response = Invoke-RestMethod `
                -Uri "https://api.notion.com/v1/pages/$PageId" `
                -Method PATCH `
                -Headers $headers `
                -Body $body

            Write-Log "Successfully updated relations" -Level Success
            return $response
        }
        catch {
            $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($errorDetails) {
                throw "Notion API error: $($errorDetails.message)"
            }
            throw "Failed to update relations: $_"
        }
    }
}

# ===== Main Execution =====

try {
    Write-Log "=== Notion Relation Update ===" -Level Info
    Write-Log "Page ID: $PageId" -Level Info
    Write-Log "Property: $PropertyName" -Level Info
    Write-Log "New Relations: $($RelationIds.Count)" -Level Info
    Write-Log "Mode: $(if ($ReplaceAll) { 'REPLACE ALL' } else { 'APPEND' })" -Level Info

    # Step 1: Get API key
    $apiKey = Get-NotionApiKey

    # Step 2: Determine final relation list
    $finalRelations = if ($ReplaceAll) {
        Write-Log "Replacing all existing relations" -Level Warning
        $RelationIds
    }
    else {
        $existing = Get-ExistingRelations -PageId $PageId -ApiKey $apiKey
        $combined = @($existing) + @($RelationIds) | Select-Object -Unique
        Write-Log "Combining $($existing.Count) existing + $($RelationIds.Count) new = $($combined.Count) total" -Level Info
        $combined
    }

    # Step 3: Update page
    $result = Update-PageRelations `
        -PageId $PageId `
        -ApiKey $apiKey `
        -PropertyName $PropertyName `
        -AllRelationIds $finalRelations

    # Step 4: Verification
    Write-Log "=== Update Complete ===" -Level Success
    Write-Log "Page URL: https://www.notion.so/$($PageId -replace '-', '')" -Level Info
    Write-Log "Total relations now: $($finalRelations.Count)" -Level Success

    # Return summary object
    return [PSCustomObject]@{
        PageId           = $PageId
        PropertyName     = $PropertyName
        PreviousCount    = if ($ReplaceAll) { 0 } else { $existing.Count }
        NewCount         = $RelationIds.Count
        TotalCount       = $finalRelations.Count
        Mode             = if ($ReplaceAll) { "Replace" } else { "Append" }
        Success          = $true
    }
}
catch {
    Write-Log "Operation failed: $_" -Level Error
    throw
}
