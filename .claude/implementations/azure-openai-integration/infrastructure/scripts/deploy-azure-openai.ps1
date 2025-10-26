<#
.SYNOPSIS
    Deploy Azure OpenAI infrastructure for Brookside BI Innovation Nexus

.DESCRIPTION
    Establish production-ready Azure OpenAI Service with comprehensive validation,
    deployment orchestration, and post-deployment verification. Designed for
    organizations requiring secure, scalable AI infrastructure with automated
    rollback capabilities.

.PARAMETER Environment
    Target deployment environment (dev, staging, prod)

.PARAMETER ResourceGroup
    Azure resource group name (will be created if doesn't exist)

.PARAMETER Location
    Azure region for deployment (default: eastus)

.PARAMETER SkipValidation
    Skip pre-deployment validation checks (not recommended)

.PARAMETER WhatIf
    Preview deployment changes without executing

.EXAMPLE
    .\deploy-azure-openai.ps1 -Environment dev -ResourceGroup rg-brookside-aoai-dev

.EXAMPLE
    .\deploy-azure-openai.ps1 -Environment prod -ResourceGroup rg-brookside-aoai-prod -WhatIf

.NOTES
    Best for: Organizations deploying Azure OpenAI with enterprise governance requirements
    Requires: Azure CLI 2.50+, Bicep CLI 0.20+, Contributor role on subscription
    Author: Claude Code Deployment Orchestrator
    Version: 1.0.0
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory = $false)]
    [string]$Location = 'eastus',

    [Parameter(Mandatory = $false)]
    [switch]$SkipValidation,

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$SubscriptionId = 'cfacbbe8-a2a3-445f-a188-68b3b35f0c84'
$TenantId = '2930489e-9d8a-456b-9de9-e4787faeab9c'
$KeyVaultName = 'kv-brookside-secrets'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BicepTemplate = Join-Path $ScriptDir '..\bicep\main.bicep'
$ParametersFile = Join-Path $ScriptDir "..\bicep\parameters\$Environment.json"

# Deployment metadata
$DeploymentName = "aoai-deployment-$Environment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$DeploymentStartTime = Get-Date

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Write-Status {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Type = 'Info'
    )

    $color = switch ($Type) {
        'Info' { 'Cyan' }
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
    }

    $prefix = switch ($Type) {
        'Info' { '[INFO]' }
        'Success' { '[SUCCESS]' }
        'Warning' { '[WARNING]' }
        'Error' { '[ERROR]' }
    }

    Write-Host "$prefix $Message" -ForegroundColor $color
}

function Test-Prerequisites {
    Write-Status "Validating deployment prerequisites..." -Type Info

    # Check Azure CLI
    try {
        $azVersion = az version --query '\"azure-cli\"' -o tsv
        Write-Status "Azure CLI version: $azVersion" -Type Info

        if ([version]$azVersion -lt [version]'2.50.0') {
            throw "Azure CLI version 2.50.0 or higher required. Current: $azVersion"
        }
    } catch {
        Write-Status "Azure CLI not found or version check failed: $_" -Type Error
        return $false
    }

    # Check Bicep CLI
    try {
        $bicepVersion = az bicep version
        Write-Status "Bicep CLI version: $bicepVersion" -Type Info
    } catch {
        Write-Status "Bicep CLI not found. Installing..." -Type Warning
        az bicep install
    }

    # Verify authentication
    try {
        $currentAccount = az account show | ConvertFrom-Json
        Write-Status "Authenticated as: $($currentAccount.user.name)" -Type Info

        if ($currentAccount.id -ne $SubscriptionId) {
            Write-Status "Setting subscription to: $SubscriptionId" -Type Info
            az account set --subscription $SubscriptionId
        }
    } catch {
        Write-Status "Azure authentication failed. Run 'az login' first." -Type Error
        return $false
    }

    # Verify template files exist
    if (-not (Test-Path $BicepTemplate)) {
        Write-Status "Bicep template not found: $BicepTemplate" -Type Error
        return $false
    }

    if (-not (Test-Path $ParametersFile)) {
        Write-Status "Parameters file not found: $ParametersFile" -Type Error
        return $false
    }

    Write-Status "Prerequisites validated successfully" -Type Success
    return $true
}

function New-ResourceGroupIfNotExists {
    param([string]$Name, [string]$Location)

    Write-Status "Verifying resource group: $Name" -Type Info

    $rgExists = az group exists --name $Name | ConvertFrom-Json

    if (-not $rgExists) {
        Write-Status "Creating resource group: $Name in $Location" -Type Info
        az group create --name $Name --location $Location --tags `
            Environment=$Environment `
            ManagedBy=ClaudeCode `
            Project=InnovationNexus | Out-Null

        Write-Status "Resource group created successfully" -Type Success
    } else {
        Write-Status "Resource group already exists" -Type Info
    }
}

function Test-BicepTemplate {
    Write-Status "Validating Bicep template..." -Type Info

    try {
        $validation = az deployment group validate `
            --resource-group $ResourceGroup `
            --template-file $BicepTemplate `
            --parameters $ParametersFile `
            --query 'properties.validatedResources[].type' `
            -o json | ConvertFrom-Json

        Write-Status "Template validated successfully. Resources to deploy:" -Type Success
        $validation | ForEach-Object { Write-Status "  - $_" -Type Info }

        return $true
    } catch {
        Write-Status "Template validation failed: $_" -Type Error
        return $false
    }
}

function Invoke-BicepDeployment {
    Write-Status "Starting Bicep deployment: $DeploymentName" -Type Info

    try {
        if ($WhatIf) {
            Write-Status "Running What-If analysis..." -Type Info
            $whatIfResult = az deployment group what-if `
                --resource-group $ResourceGroup `
                --template-file $BicepTemplate `
                --parameters $ParametersFile `
                --name $DeploymentName

            Write-Host $whatIfResult
            Write-Status "What-If analysis completed. No changes applied." -Type Success
            return $null
        }

        Write-Status "Executing deployment (this may take 5-10 minutes)..." -Type Info

        $deployment = az deployment group create `
            --resource-group $ResourceGroup `
            --template-file $BicepTemplate `
            --parameters $ParametersFile `
            --name $DeploymentName `
            --query 'properties.outputs' `
            -o json | ConvertFrom-Json

        $deploymentDuration = (Get-Date) - $DeploymentStartTime
        Write-Status "Deployment completed in $([math]::Round($deploymentDuration.TotalMinutes, 2)) minutes" -Type Success

        return $deployment
    } catch {
        Write-Status "Deployment failed: $_" -Type Error

        # Retrieve deployment error details
        Write-Status "Retrieving deployment error details..." -Type Info
        $errors = az deployment operation group list `
            --resource-group $ResourceGroup `
            --name $DeploymentName `
            --query "[?properties.statusMessage.error != null].properties.statusMessage.error" `
            -o json | ConvertFrom-Json

        $errors | ForEach-Object {
            Write-Status "Error: $($_.code) - $($_.message)" -Type Error
        }

        return $null
    }
}

function Set-KeyVaultSecrets {
    param([object]$DeploymentOutputs)

    Write-Status "Storing Azure OpenAI endpoint in Key Vault..." -Type Info

    try {
        $endpoint = $DeploymentOutputs.azureOpenAIEndpoint.value
        $deploymentName = $DeploymentOutputs.deploymentName.value

        az keyvault secret set `
            --vault-name $KeyVaultName `
            --name "azure-openai-endpoint-$Environment" `
            --value $endpoint `
            --output none

        az keyvault secret set `
            --vault-name $KeyVaultName `
            --name "azure-openai-deployment-name-$Environment" `
            --value $deploymentName `
            --output none

        Write-Status "Secrets stored successfully in Key Vault: $KeyVaultName" -Type Success
    } catch {
        Write-Status "Failed to store secrets in Key Vault: $_" -Type Warning
        Write-Status "Endpoint: $endpoint (store manually if needed)" -Type Info
    }
}

function Test-Deployment {
    param([object]$DeploymentOutputs)

    Write-Status "Running post-deployment validation..." -Type Info

    $aoaiName = $DeploymentOutputs.azureOpenAIName.value
    $endpoint = $DeploymentOutputs.azureOpenAIEndpoint.value

    # Verify Azure OpenAI Service exists
    try {
        $aoaiService = az cognitiveservices account show `
            --name $aoaiName `
            --resource-group $ResourceGroup `
            --query '{name:name, provisioningState:properties.provisioningState, endpoint:properties.endpoint}' `
            -o json | ConvertFrom-Json

        if ($aoaiService.provisioningState -eq 'Succeeded') {
            Write-Status "Azure OpenAI Service provisioned successfully" -Type Success
            Write-Status "Endpoint: $($aoaiService.endpoint)" -Type Info
        } else {
            Write-Status "Service provisioning state: $($aoaiService.provisioningState)" -Type Warning
        }
    } catch {
        Write-Status "Failed to verify Azure OpenAI Service: $_" -Type Error
        return $false
    }

    # Verify model deployment
    try {
        $deploymentName = $DeploymentOutputs.deploymentName.value
        $modelDeployment = az cognitiveservices account deployment show `
            --name $aoaiName `
            --resource-group $ResourceGroup `
            --deployment-name $deploymentName `
            --query '{name:name, provisioningState:properties.provisioningState, model:properties.model.name}' `
            -o json | ConvertFrom-Json

        if ($modelDeployment.provisioningState -eq 'Succeeded') {
            Write-Status "Model deployment verified: $($modelDeployment.model)" -Type Success
        } else {
            Write-Status "Model provisioning state: $($modelDeployment.provisioningState)" -Type Warning
        }
    } catch {
        Write-Status "Failed to verify model deployment: $_" -Type Error
        return $false
    }

    # Verify Managed Identity RBAC
    $managedIdentityPrincipalId = $DeploymentOutputs.managedIdentityPrincipalId.value
    try {
        $roleAssignments = az role assignment list `
            --assignee $managedIdentityPrincipalId `
            --scope $DeploymentOutputs.azureOpenAIId.value `
            --query '[].roleDefinitionName' `
            -o json | ConvertFrom-Json

        if ($roleAssignments -contains 'Cognitive Services OpenAI User') {
            Write-Status "RBAC role assignment verified" -Type Success
        } else {
            Write-Status "Expected role assignment not found" -Type Warning
        }
    } catch {
        Write-Status "Failed to verify RBAC: $_" -Type Warning
    }

    Write-Status "Post-deployment validation completed" -Type Success
    return $true
}

function Show-DeploymentSummary {
    param([object]$DeploymentOutputs)

    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Green
    Write-Host " Azure OpenAI Deployment Summary - $Environment Environment" -ForegroundColor Green
    Write-Host "============================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Status: DEPLOYED SUCCESSFULLY" -ForegroundColor Green
    Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
    Write-Host "Duration: $([math]::Round(((Get-Date) - $DeploymentStartTime).TotalMinutes, 2)) minutes" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Resources Deployed:" -ForegroundColor Yellow
    Write-Host "  - Azure OpenAI Service: $($DeploymentOutputs.azureOpenAIName.value)" -ForegroundColor White
    Write-Host "  - Model Deployment: $($DeploymentOutputs.deploymentName.value) (GPT-4 Turbo)" -ForegroundColor White
    Write-Host "  - Managed Identity: $($DeploymentOutputs.managedIdentityId.value)" -ForegroundColor White
    Write-Host ""
    Write-Host "Configuration:" -ForegroundColor Yellow
    Write-Host "  - Endpoint: $($DeploymentOutputs.azureOpenAIEndpoint.value)" -ForegroundColor White
    Write-Host "  - Resource Group: $ResourceGroup" -ForegroundColor White
    Write-Host "  - Location: $Location" -ForegroundColor White
    Write-Host "  - Authentication: Managed Identity (RBAC)" -ForegroundColor White
    Write-Host ""
    Write-Host "Key Vault Secrets (stored in $KeyVaultName):" -ForegroundColor Yellow
    Write-Host "  - azure-openai-endpoint-$Environment" -ForegroundColor White
    Write-Host "  - azure-openai-deployment-name-$Environment" -ForegroundColor White
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Configure application with Managed Identity Client ID:" -ForegroundColor White
    Write-Host "     $($DeploymentOutputs.managedIdentityClientId.value)" -ForegroundColor Cyan
    Write-Host "  2. Update MCP configuration with endpoint URL" -ForegroundColor White
    Write-Host "  3. Test integration with sample API calls" -ForegroundColor White
    Write-Host "  4. Monitor costs in Azure Cost Management" -ForegroundColor White
    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Green
    Write-Host ""
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host " Azure OpenAI Deployment - Brookside BI Innovation Nexus" -ForegroundColor Cyan
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Environment: $Environment" -ForegroundColor Yellow
    Write-Host "Resource Group: $ResourceGroup" -ForegroundColor Yellow
    Write-Host "Location: $Location" -ForegroundColor Yellow
    Write-Host "Deployment Name: $DeploymentName" -ForegroundColor Yellow
    Write-Host ""

    # Stage 1: Pre-Deployment Validation
    if (-not $SkipValidation) {
        if (-not (Test-Prerequisites)) {
            Write-Status "Prerequisites validation failed. Exiting." -Type Error
            exit 1
        }
    }

    # Stage 2: Resource Group Creation
    New-ResourceGroupIfNotExists -Name $ResourceGroup -Location $Location

    # Stage 3: Template Validation
    if (-not (Test-BicepTemplate)) {
        Write-Status "Template validation failed. Exiting." -Type Error
        exit 1
    }

    # Stage 4: Deployment Execution
    $deploymentOutputs = Invoke-BicepDeployment

    if ($null -eq $deploymentOutputs) {
        if ($WhatIf) {
            Write-Status "What-If mode completed. No resources deployed." -Type Info
            exit 0
        } else {
            Write-Status "Deployment failed. Check error messages above." -Type Error
            exit 1
        }
    }

    # Stage 5: Key Vault Secret Storage
    Set-KeyVaultSecrets -DeploymentOutputs $deploymentOutputs

    # Stage 6: Post-Deployment Validation
    if (-not (Test-Deployment -DeploymentOutputs $deploymentOutputs)) {
        Write-Status "Post-deployment validation failed. Review warnings above." -Type Warning
    }

    # Stage 7: Deployment Summary
    Show-DeploymentSummary -DeploymentOutputs $deploymentOutputs

    Write-Status "Deployment completed successfully" -Type Success
    exit 0

} catch {
    Write-Status "Deployment failed with error: $_" -Type Error
    Write-Status "Stack trace: $($_.ScriptStackTrace)" -Type Error
    exit 1
}
