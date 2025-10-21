<#
.SYNOPSIS
    Retrieve secrets from Azure Key Vault for secure credential management.

.DESCRIPTION
    Establishes secure connection to Azure Key Vault to retrieve secrets for MCP and integration usage.
    This solution is designed to streamline secret management across all Brookside BI innovation projects.

.PARAMETER SecretName
    The name of the secret to retrieve from Key Vault.

.PARAMETER VaultName
    The name of the Azure Key Vault. Defaults to kv-brookside-secrets.

.EXAMPLE
    .\Get-KeyVaultSecret.ps1 -SecretName "github-personal-access-token"

.NOTES
    Best for: Organizations requiring centralized secret management with Azure Key Vault integration.
    Designed for: Brookside BI Innovation Nexus - Secure credential retrieval for MCP servers.

    Authentication: Uses Azure CLI authentication (az login)
    Vault URI: https://kv-brookside-secrets.vault.azure.net/

    Created: 2025-10-21
    Author: Brookside BI
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$SecretName,

    [Parameter(Mandatory = $false)]
    [string]$VaultName = "kv-brookside-secrets"
)

# Establish error handling to provide clear resolution guidance
$ErrorActionPreference = "Stop"

try {
    # Verify Azure CLI is installed and authenticated
    $azAccount = az account show 2>$null | ConvertFrom-Json

    if (-not $azAccount) {
        Write-Error "Azure CLI authentication required. Run 'az login' to establish secure connection."
        exit 1
    }

    # Retrieve secret from Azure Key Vault
    $secret = az keyvault secret show --vault-name $VaultName --name $SecretName --query "value" --output tsv 2>$null

    if (-not $secret) {
        Write-Error "Secret '$SecretName' not found in Key Vault '$VaultName'. Verify secret exists and you have appropriate permissions."
        exit 1
    }

    # Output secret value for MCP consumption
    Write-Output $secret

} catch {
    Write-Error "Failed to retrieve secret from Key Vault: $($_.Exception.Message)"
    exit 1
}
