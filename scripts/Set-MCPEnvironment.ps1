<#
.SYNOPSIS
    Establish secure environment variables from Azure Key Vault for MCP server usage.

.DESCRIPTION
    Retrieves secrets from Azure Key Vault and sets them as environment variables for the current session.
    This solution is designed to streamline secure credential management for Claude Code MCP servers.

    Run this script before launching Claude Code to ensure MCP servers have access to required credentials.

.PARAMETER Persistent
    If specified, sets environment variables at the User level (persists across sessions).
    Default behavior sets variables only for the current PowerShell session.

.EXAMPLE
    .\Set-MCPEnvironment.ps1
    Sets environment variables for current session only

.EXAMPLE
    .\Set-MCPEnvironment.ps1 -Persistent
    Sets persistent user-level environment variables

.NOTES
    Best for: Organizations requiring automated secret management from Azure Key Vault.
    Designed for: Brookside BI Innovation Nexus - Secure MCP credential configuration.

    Prerequisites:
    - Azure CLI installed and authenticated (az login)
    - Access to kv-brookside-secrets Key Vault
    - Read permissions on required secrets

    Secrets Retrieved:
    - github-personal-access-token → GITHUB_PERSONAL_ACCESS_TOKEN
    - notion-api-key → NOTION_API_KEY

    Created: 2025-10-21
    Author: Brookside BI
#>

param(
    [Parameter(Mandatory = $false)]
    [switch]$Persistent
)

$ErrorActionPreference = "Stop"

$VaultName = "kv-brookside-secrets"
$SecretsToRetrieve = @{
    "github-personal-access-token" = "GITHUB_PERSONAL_ACCESS_TOKEN"
    "notion-api-key" = "NOTION_API_KEY"
}

Write-Host "Establishing secure connection to Azure Key Vault..." -ForegroundColor Cyan

try {
    $azAccount = az account show 2>$null | ConvertFrom-Json

    if (-not $azAccount) {
        Write-Error "Azure CLI authentication required. Run az login to establish secure connection."
        exit 1
    }

    Write-Host "Azure authentication verified: $($azAccount.user.name)" -ForegroundColor Green

    foreach ($secretEntry in $SecretsToRetrieve.GetEnumerator()) {
        $secretName = $secretEntry.Key
        $envVarName = $secretEntry.Value

        Write-Host "Retrieving secret: $secretName..." -ForegroundColor Yellow

        $secretValue = az keyvault secret show --vault-name $VaultName --name $secretName --query "value" --output tsv 2>$null

        if (-not $secretValue) {
            Write-Warning "Secret $secretName not found or inaccessible. Skipping..."
            continue
        }

        if ($Persistent) {
            [System.Environment]::SetEnvironmentVariable($envVarName, $secretValue, [System.EnvironmentVariableTarget]::User)
            Write-Host "Set persistent environment variable: $envVarName" -ForegroundColor Green
        } else {
            Set-Item -Path "env:$envVarName" -Value $secretValue
            Write-Host "Set session environment variable: $envVarName" -ForegroundColor Green
        }
    }

    Write-Host ""
    Write-Host "Environment configuration complete!" -ForegroundColor Cyan
    Write-Host "MCP servers can now access required credentials securely." -ForegroundColor Green
    Write-Host ""

    if (-not $Persistent) {
        Write-Host "NOTE: Variables set for current session only." -ForegroundColor Yellow
        Write-Host "To set persistent variables, run with -Persistent parameter" -ForegroundColor Yellow
        Write-Host ""
    }

} catch {
    Write-Error "Failed to establish secure environment: $($_.Exception.Message)"
    exit 1
}
