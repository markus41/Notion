<#
.SYNOPSIS
    Initialize MCP server configuration for Brookside BI repositories.

.DESCRIPTION
    Establishes standardized MCP configuration to streamline secure credential management
    and drive measurable outcomes through consistent tooling across innovation workflows.

    This solution is designed for organizations scaling technology across teams.

.PARAMETER TargetRepository
    The target repository path where MCP configuration will be deployed.
    Defaults to current directory.

.PARAMETER NotionWorkspaceId
    The Notion Workspace ID for this repository's integration.
    If not provided, will use existing value or prompt user.

.PARAMETER SkipValidation
    Skip MCP server connectivity validation after configuration.

.EXAMPLE
    .\Initialize-MCPConfig.ps1
    Initialize MCP config in current directory

.EXAMPLE
    .\Initialize-MCPConfig.ps1 -TargetRepository "C:\Repos\Project-Ascension"
    Deploy MCP config to specific repository

.EXAMPLE
    .\Initialize-MCPConfig.ps1 -NotionWorkspaceId "12345678-90ab-cdef-1234-567890abcdef"
    Initialize with specific Notion workspace

.NOTES
    Best for: Organizations requiring consistent MCP deployment across multiple repositories.
    Designed for: Brookside BI Innovation Nexus - Standardized infrastructure for AI agents.

    Prerequisites:
    - Azure CLI installed and authenticated
    - Access to kv-brookside-secrets Key Vault
    - Node.js 18+ for MCP servers
    - Template file at .claude/templates/mcp-config-template.json

    Created: 2025-10-21
    Author: Brookside BI
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$TargetRepository = (Get-Location).Path,

    [Parameter(Mandatory = $false)]
    [string]$NotionWorkspaceId,

    [Parameter(Mandatory = $false)]
    [switch]$SkipValidation
)

$ErrorActionPreference = "Stop"

# Define paths
$TemplateDir = Join-Path $PSScriptRoot ".." ".claude" "templates"
$TemplateFile = Join-Path $TemplateDir "mcp-config-template.json"
$TargetClaudeDir = Join-Path $TargetRepository ".claude"
$TargetConfigFile = Join-Path $TargetClaudeDir "settings.local.json"

Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host " Brookside BI MCP Configuration Setup" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Verify prerequisites
Write-Host "Step 1: Verifying prerequisites..." -ForegroundColor Yellow
Write-Host ""

# Check Azure CLI authentication
try {
    $azAccount = az account show 2>$null | ConvertFrom-Json
    if (-not $azAccount) {
        Write-Error "Azure CLI authentication required. Run 'az login' to establish secure connection."
        exit 1
    }
    Write-Host "  ✓ Azure CLI authenticated as: $($azAccount.user.name)" -ForegroundColor Green
} catch {
    Write-Error "Azure CLI not found or not authenticated. Install Azure CLI and run 'az login'."
    exit 1
}

# Check Node.js
try {
    $nodeVersion = node --version 2>$null
    if ($nodeVersion) {
        Write-Host "  ✓ Node.js installed: $nodeVersion" -ForegroundColor Green
    } else {
        Write-Warning "Node.js not found. MCP servers require Node.js 18+."
        $continue = Read-Host "Continue anyway? (y/N)"
        if ($continue -ne 'y') { exit 1 }
    }
} catch {
    Write-Warning "Could not verify Node.js installation."
}

# Check template file exists
if (-not (Test-Path $TemplateFile)) {
    Write-Error "Template file not found: $TemplateFile"
    Write-Host "Run this script from the Innovation Nexus repository with templates." -ForegroundColor Yellow
    exit 1
}
Write-Host "  ✓ Template file found: $TemplateFile" -ForegroundColor Green

Write-Host ""

# Step 2: Create .claude directory if needed
Write-Host "Step 2: Setting up target repository structure..." -ForegroundColor Yellow
Write-Host ""

if (-not (Test-Path $TargetClaudeDir)) {
    New-Item -ItemType Directory -Path $TargetClaudeDir -Force | Out-Null
    Write-Host "  ✓ Created .claude directory: $TargetClaudeDir" -ForegroundColor Green
} else {
    Write-Host "  ✓ .claude directory exists: $TargetClaudeDir" -ForegroundColor Green
}

# Step 3: Load template and configure
Write-Host ""
Write-Host "Step 3: Configuring MCP servers..." -ForegroundColor Yellow
Write-Host ""

$templateContent = Get-Content $TemplateFile -Raw | ConvertFrom-Json

# Remove documentation comments (keys starting with //)
$cleanConfig = @{
    mcpServers = @{
        notion = $templateContent.mcpServers.notion
        github = $templateContent.mcpServers.github
        azure = $templateContent.mcpServers.azure
        playwright = $templateContent.mcpServers.playwright
    }
    globalSettings = @{}
}

# Handle Notion Workspace ID
if ($NotionWorkspaceId) {
    $cleanConfig.globalSettings.NOTION_WORKSPACE_ID = $NotionWorkspaceId
    Write-Host "  ✓ Using provided Notion Workspace ID: $NotionWorkspaceId" -ForegroundColor Green
} else {
    # Check if config already exists
    if (Test-Path $TargetConfigFile) {
        $existingConfig = Get-Content $TargetConfigFile -Raw | ConvertFrom-Json
        if ($existingConfig.globalSettings.NOTION_WORKSPACE_ID) {
            $cleanConfig.globalSettings.NOTION_WORKSPACE_ID = $existingConfig.globalSettings.NOTION_WORKSPACE_ID
            Write-Host "  ✓ Preserved existing Notion Workspace ID" -ForegroundColor Green
        }
    }

    # If still not set, prompt user
    if (-not $cleanConfig.globalSettings.NOTION_WORKSPACE_ID) {
        Write-Host ""
        Write-Host "  Notion Workspace ID required for Notion MCP integration." -ForegroundColor Yellow
        Write-Host "  Find this in Notion: Settings > Workspace > Workspace ID" -ForegroundColor Gray
        Write-Host ""
        $inputWorkspaceId = Read-Host "  Enter Notion Workspace ID (or press Enter to skip)"

        if ($inputWorkspaceId) {
            $cleanConfig.globalSettings.NOTION_WORKSPACE_ID = $inputWorkspaceId
            Write-Host "  ✓ Notion Workspace ID configured" -ForegroundColor Green
        } else {
            $cleanConfig.globalSettings.NOTION_WORKSPACE_ID = "REPLACE_WITH_YOUR_WORKSPACE_ID"
            Write-Host "  ⚠ Notion Workspace ID not set - update manually in config file" -ForegroundColor Yellow
        }
    }
}

# Step 4: Write configuration
Write-Host ""
Write-Host "Step 4: Writing configuration file..." -ForegroundColor Yellow
Write-Host ""

$cleanConfig | ConvertTo-Json -Depth 10 | Set-Content $TargetConfigFile -Encoding UTF8
Write-Host "  ✓ Configuration written to: $TargetConfigFile" -ForegroundColor Green

# Step 5: Set environment variables
Write-Host ""
Write-Host "Step 5: Configuring environment variables..." -ForegroundColor Yellow
Write-Host ""

$envScriptPath = Join-Path $PSScriptRoot "Set-MCPEnvironment.ps1"
if (Test-Path $envScriptPath) {
    try {
        & $envScriptPath
        Write-Host "  ✓ Environment variables configured from Azure Key Vault" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to set environment variables: $($_.Exception.Message)"
        Write-Host "  Run scripts/Set-MCPEnvironment.ps1 manually before using MCP servers" -ForegroundColor Yellow
    }
} else {
    Write-Warning "Set-MCPEnvironment.ps1 not found. Environment variables not configured."
}

# Step 6: Validate MCP servers
if (-not $SkipValidation) {
    Write-Host ""
    Write-Host "Step 6: Validating MCP server connectivity..." -ForegroundColor Yellow
    Write-Host ""

    $testScriptPath = Join-Path $PSScriptRoot "Test-MCPServers.ps1"
    if (Test-Path $testScriptPath) {
        try {
            & $testScriptPath
        } catch {
            Write-Warning "MCP validation failed: $($_.Exception.Message)"
        }
    } else {
        Write-Host "  Test-MCPServers.ps1 not found - skipping validation" -ForegroundColor Yellow
        Write-Host "  Verify connectivity manually: claude mcp list" -ForegroundColor Gray
    }
} else {
    Write-Host ""
    Write-Host "Step 6: Skipping validation (--SkipValidation)" -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host " MCP Configuration Complete!" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Review configuration: $TargetConfigFile" -ForegroundColor White
Write-Host "  2. Restart Claude Code to activate MCP servers" -ForegroundColor White
Write-Host "  3. Verify connectivity: claude mcp list" -ForegroundColor White
Write-Host "  4. Authenticate Notion MCP (OAuth flow on first use)" -ForegroundColor White
Write-Host ""
Write-Host "Configuration Details:" -ForegroundColor Cyan
Write-Host "  • Repository: $TargetRepository" -ForegroundColor Gray
Write-Host "  • MCP Servers: Notion, GitHub, Azure, Playwright" -ForegroundColor Gray
Write-Host "  • Authentication: Azure Key Vault (kv-brookside-secrets)" -ForegroundColor Gray
Write-Host "  • Workspace ID: $($cleanConfig.globalSettings.NOTION_WORKSPACE_ID)" -ForegroundColor Gray
Write-Host ""
Write-Host "Best for: Organizations requiring standardized, secure MCP deployment" -ForegroundColor Gray
Write-Host "across multiple innovation repositories." -ForegroundColor Gray
Write-Host ""
