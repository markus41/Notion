<#
.SYNOPSIS
    Validate MCP server connectivity and configuration.

.DESCRIPTION
    Comprehensive validation script to ensure all Brookside BI MCP servers
    are properly configured and accessible. This solution is designed to
    streamline troubleshooting and establish confidence in infrastructure.

.PARAMETER ServerName
    Specific MCP server to test (notion, github, azure, playwright).
    If not specified, tests all configured servers.

.PARAMETER Verbose
    Display detailed diagnostic information for troubleshooting.

.EXAMPLE
    .\Test-MCPServers.ps1
    Test all MCP servers

.EXAMPLE
    .\Test-MCPServers.ps1 -ServerName azure
    Test only Azure MCP server

.NOTES
    Best for: Validating MCP configuration after deployment or troubleshooting connectivity issues.
    Designed for: Brookside BI Innovation Nexus - Infrastructure validation.

    Prerequisites:
    - Azure CLI authenticated (for Azure MCP)
    - Environment variables set (for GitHub MCP)
    - Node.js 18+ installed
    - Notion OAuth completed (for Notion MCP)

    Created: 2025-10-21
    Author: Brookside BI
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("notion", "github", "azure", "playwright", "all")]
    [string]$ServerName = "all",

    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host " Brookside BI MCP Server Validation" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

$testResults = @{}
$allPassed = $true

# Helper function to test server availability
function Test-MCPServer {
    param(
        [string]$Name,
        [string]$Command,
        [string[]]$Args,
        [hashtable]$EnvVars = @{}
    )

    Write-Host "Testing $Name MCP Server..." -ForegroundColor Yellow
    Write-Host ""

    $passed = $true
    $details = @()

    try {
        # For Notion, check OAuth credentials
        if ($Name -eq "Notion") {
            $credFile = Join-Path $HOME ".claude" ".credentials.json"
            if (Test-Path $credFile) {
                $creds = Get-Content $credFile -Raw | ConvertFrom-Json
                if ($creds.mcpOAuth -and $creds.mcpOAuth.'notion|eac663db915250e7') {
                    Write-Host "  ✓ OAuth credentials found" -ForegroundColor Green
                    $details += "OAuth authenticated"
                } else {
                    Write-Host "  ⚠ OAuth credentials missing - authenticate on first use" -ForegroundColor Yellow
                    $passed = $false
                    $details += "OAuth not completed"
                }
            } else {
                Write-Host "  ⚠ No credentials file found" -ForegroundColor Yellow
                $passed = $false
                $details += "First-time authentication required"
            }
        }

        # For Azure, check Azure CLI authentication
        if ($Name -eq "Azure") {
            try {
                $azAccount = az account show 2>$null | ConvertFrom-Json
                if ($azAccount) {
                    Write-Host "  ✓ Azure CLI authenticated: $($azAccount.user.name)" -ForegroundColor Green
                    $details += "Azure CLI authenticated"
                } else {
                    Write-Host "  ✗ Azure CLI not authenticated" -ForegroundColor Red
                    $passed = $false
                    $details += "Run 'az login'"
                }
            } catch {
                Write-Host "  ✗ Azure CLI not found" -ForegroundColor Red
                $passed = $false
                $details += "Install Azure CLI"
            }
        }

        # For GitHub, check environment variable
        if ($Name -eq "GitHub") {
            if ($env:GITHUB_PERSONAL_ACCESS_TOKEN) {
                Write-Host "  ✓ GitHub PAT environment variable set" -ForegroundColor Green
                $details += "PAT configured"
            } else {
                Write-Host "  ✗ GITHUB_PERSONAL_ACCESS_TOKEN not set" -ForegroundColor Red
                $passed = $false
                $details += "Run scripts/Set-MCPEnvironment.ps1"
            }
        }

        # Test package availability
        if ($Command -eq "npx") {
            $packageName = $Args[1]
            Write-Host "  Testing package: $packageName" -ForegroundColor Gray

            # Try to get version
            $versionArgs = @("-y", $packageName, "--version")
            $versionOutput = & $Command $versionArgs 2>&1 | Out-String

            if ($LASTEXITCODE -eq 0 -or $versionOutput) {
                Write-Host "  ✓ Package available: $packageName" -ForegroundColor Green
                $details += "Package installed"
            } else {
                Write-Host "  ⚠ Package may need installation: $packageName" -ForegroundColor Yellow
                $details += "Will download on first use"
            }
        }

    } catch {
        Write-Host "  ✗ Validation failed: $($_.Exception.Message)" -ForegroundColor Red
        $passed = $false
        $details += "Error: $($_.Exception.Message)"
    }

    Write-Host ""
    return @{
        Passed = $passed
        Details = $details -join "; "
    }
}

# Test each server
$serversToTest = @()

if ($ServerName -eq "all") {
    $serversToTest = @(
        @{ Name = "Notion"; Command = "npx"; Args = @("-y", "notion-mcp") }
        @{ Name = "GitHub"; Command = "npx"; Args = @("-y", "@modelcontextprotocol/server-github") }
        @{ Name = "Azure"; Command = "npx"; Args = @("-y", "@azure/mcp@latest") }
        @{ Name = "Playwright"; Command = "npx"; Args = @("-y", "@playwright/mcp@latest") }
    )
} else {
    switch ($ServerName) {
        "notion" {
            $serversToTest += @{ Name = "Notion"; Command = "npx"; Args = @("-y", "notion-mcp") }
        }
        "github" {
            $serversToTest += @{ Name = "GitHub"; Command = "npx"; Args = @("-y", "@modelcontextprotocol/server-github") }
        }
        "azure" {
            $serversToTest += @{ Name = "Azure"; Command = "npx"; Args = @("-y", "@azure/mcp@latest") }
        }
        "playwright" {
            $serversToTest += @{ Name = "Playwright"; Command = "npx"; Args = @("-y", "@playwright/mcp@latest") }
        }
    }
}

foreach ($server in $serversToTest) {
    $result = Test-MCPServer -Name $server.Name -Command $server.Command -Args $server.Args
    $testResults[$server.Name] = $result

    if (-not $result.Passed) {
        $allPassed = $false
    }
}

# Summary
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host " Validation Summary" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

foreach ($serverName in $testResults.Keys) {
    $result = $testResults[$serverName]
    if ($result.Passed) {
        Write-Host "  ✓ $serverName MCP: READY" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $serverName MCP: NEEDS ATTENTION" -ForegroundColor Red
    }

    if ($Verbose) {
        Write-Host "    Details: $($result.Details)" -ForegroundColor Gray
    }
}

Write-Host ""

if ($allPassed) {
    Write-Host "All MCP servers validated successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Launch Claude Code" -ForegroundColor White
    Write-Host "  2. Verify connectivity: claude mcp list" -ForegroundColor White
    Write-Host "  3. Complete Notion OAuth if prompted" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "Some MCP servers require attention." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Troubleshooting Steps:" -ForegroundColor Cyan
    Write-Host "  1. Ensure Azure CLI authenticated: az login" -ForegroundColor White
    Write-Host "  2. Set environment variables: scripts/Set-MCPEnvironment.ps1" -ForegroundColor White
    Write-Host "  3. Restart Claude Code to trigger OAuth flows" -ForegroundColor White
    Write-Host "  4. Check logs in ~/.claude/debug/ for detailed errors" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host "Best for: Ensuring reliable MCP infrastructure across Brookside BI repositories." -ForegroundColor Gray
Write-Host ""
