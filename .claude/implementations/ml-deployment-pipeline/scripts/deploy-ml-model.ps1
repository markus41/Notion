# Deploy ML Model to Azure ML Managed Endpoint
# Establishes automated model deployment orchestration with canary and blue-green strategies
# for zero-downtime production releases across Brookside BI Innovation Nexus environments.
#
# Purpose: Orchestrate ML model deployment to Azure ML managed online endpoints
# Best for: Organizations requiring automated, safe ML model deployments with rollback capabilities
# Version: 1.0.0
# Last Updated: 2025-10-26
#
# Usage:
#   .\deploy-ml-model.ps1 -Environment dev -EndpointName viability-scoring-dev
#   .\deploy-ml-model.ps1 -Environment prod -EndpointName viability-scoring-prod -DeploymentStrategy blue-green

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment,

    [Parameter(Mandatory = $true)]
    [string]$EndpointName,

    [Parameter(Mandatory = $false)]
    [ValidateSet('canary', 'blue-green')]
    [string]$DeploymentStrategy = 'canary',

    [Parameter(Mandatory = $false)]
    [int]$InitialTrafficPercentage = 10,

    [Parameter(Mandatory = $false)]
    [string]$ModelName = 'viability_scoring_model',

    [Parameter(Mandatory = $false)]
    [string]$InstanceType = 'Standard_DS3_v2',

    [Parameter(Mandatory = $false)]
    [int]$InstanceCount = 1,

    [Parameter(Mandatory = $false)]
    [switch]$EnableAppInsights,

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# Establish error handling for reliable deployment orchestration
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Import required modules
Import-Module Az.Accounts -ErrorAction SilentlyContinue
Import-Module Az.Monitor -ErrorAction SilentlyContinue

# Environment-specific configuration establishing scalability and cost optimization
$instanceConfig = @{
    'dev'     = @{ Type = 'Standard_DS2_v2'; Count = 1; Priority = 'LowPriority' }
    'staging' = @{ Type = 'Standard_DS3_v2'; Count = 1; Priority = 'LowPriority' }
    'prod'    = @{ Type = 'Standard_DS3_v2'; Count = 2; Priority = 'Standard' }
}

# Override with parameters if provided
if ($InstanceType) {
    $instanceConfig[$Environment].Type = $InstanceType
}
if ($InstanceCount) {
    $instanceConfig[$Environment].Count = $InstanceCount
}

# Establish logging configuration
$logFile = "deployment-$Environment-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$logPath = Join-Path $PSScriptRoot "../logs" $logFile

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"

    Write-Host $logMessage
    Add-Content -Path $logPath -Value $logMessage
}

try {
    Write-Log "Starting ML model deployment to $EndpointName ($Environment)" -Level 'INFO'

    # Validate Azure CLI authentication
    Write-Log "Validating Azure CLI authentication..." -Level 'INFO'
    $account = az account show 2>&1 | ConvertFrom-Json

    if (-not $account) {
        throw "Not authenticated to Azure CLI. Run 'az login' first."
    }

    Write-Log "Authenticated as: $($account.user.name)" -Level 'INFO'

    # Set Azure ML defaults
    Write-Log "Configuring Azure ML workspace defaults..." -Level 'INFO'
    az configure --defaults workspace=ml-brookside-prod group=rg-brookside-ml

    # Check if endpoint exists
    Write-Log "Checking if endpoint '$EndpointName' exists..." -Level 'INFO'
    $endpointExists = az ml online-endpoint show --name $EndpointName 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Log "Endpoint does not exist, creating new endpoint..." -Level 'INFO'

        if (-not $WhatIf) {
            az ml online-endpoint create `
                --name $EndpointName `
                --auth-mode key `
                --tags environment=$Environment managed_by=BrooksideBI

            if ($LASTEXITCODE -ne 0) {
                throw "Failed to create endpoint $EndpointName"
            }

            Write-Log "Endpoint '$EndpointName' created successfully" -Level 'INFO'
        }
        else {
            Write-Log "[WhatIf] Would create endpoint: $EndpointName" -Level 'INFO'
        }
    }
    else {
        Write-Log "Endpoint '$EndpointName' already exists" -Level 'INFO'
    }

    # Generate deployment name with timestamp
    $deploymentName = if ($DeploymentStrategy -eq 'blue-green') {
        "blue-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    }
    else {
        "deploy-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    }

    Write-Log "Creating deployment: $deploymentName" -Level 'INFO'

    # Build deployment command
    $deploymentArgs = @(
        'ml', 'online-deployment', 'create',
        '--name', $deploymentName,
        '--endpoint', $EndpointName,
        '--model', "azureml:${ModelName}@latest",
        '--instance-type', $instanceConfig[$Environment].Type,
        '--instance-count', $instanceConfig[$Environment].Count,
        '--environment-variable', "ENVIRONMENT=$Environment",
        '--environment-variable', "DEPLOYMENT_TIMESTAMP=$(Get-Date -Format 'o')"
    )

    # Add Application Insights if enabled
    if ($EnableAppInsights) {
        $deploymentArgs += '--app-insights-enabled'
        Write-Log "Application Insights enabled for deployment" -Level 'INFO'
    }

    # Add production-specific configurations
    if ($Environment -eq 'prod') {
        $deploymentArgs += '--environment-variable'
        $deploymentArgs += 'LOG_LEVEL=WARNING'
        Write-Log "Production logging configured" -Level 'INFO'
    }

    # Execute deployment
    if (-not $WhatIf) {
        Write-Log "Executing deployment command..." -Level 'INFO'
        & az @deploymentArgs

        if ($LASTEXITCODE -ne 0) {
            throw "Deployment creation failed for $deploymentName"
        }

        Write-Log "Deployment '$deploymentName' created successfully" -Level 'INFO'
    }
    else {
        Write-Log "[WhatIf] Would execute: az $($deploymentArgs -join ' ')" -Level 'INFO'
    }

    # Configure traffic routing based on strategy
    if (-not $WhatIf) {
        Write-Log "Configuring traffic routing ($DeploymentStrategy strategy)..." -Level 'INFO'

        if ($DeploymentStrategy -eq 'canary') {
            # Canary deployment: Start with specified percentage
            az ml online-endpoint update `
                --name $EndpointName `
                --traffic "$deploymentName=$InitialTrafficPercentage"

            if ($LASTEXITCODE -ne 0) {
                throw "Failed to configure canary traffic"
            }

            Write-Log "Canary traffic configured: $InitialTrafficPercentage% to $deploymentName" -Level 'INFO'
        }
        else {
            # Blue-green deployment: Keep at 0% until manual switch
            Write-Log "Blue-green deployment ready. Traffic remains at 0% until manual approval." -Level 'INFO'
        }

        # Wait for deployment to become ready
        Write-Log "Waiting for deployment to become ready..." -Level 'INFO'
        $maxAttempts = 60
        $attempt = 0

        while ($attempt -lt $maxAttempts) {
            $deploymentStatus = az ml online-deployment show `
                --name $deploymentName `
                --endpoint $EndpointName `
                --query 'provisioningState' -o tsv 2>&1

            if ($deploymentStatus -eq 'Succeeded') {
                Write-Log "Deployment is ready and healthy" -Level 'INFO'
                break
            }

            $attempt++
            Write-Log "Deployment status: $deploymentStatus (attempt $attempt/$maxAttempts)" -Level 'INFO'
            Start-Sleep -Seconds 10
        }

        if ($attempt -ge $maxAttempts) {
            throw "Deployment did not become ready within expected timeframe"
        }
    }

    # Get endpoint details for output
    if (-not $WhatIf) {
        $endpointDetails = az ml online-endpoint show `
            --name $EndpointName `
            --query '{scoringUri:scoring_uri, swaggerUri:swagger_uri}' -o json | ConvertFrom-Json

        Write-Log "Deployment completed successfully" -Level 'INFO'
        Write-Log "Endpoint Scoring URI: $($endpointDetails.scoringUri)" -Level 'INFO'
        Write-Log "Swagger URI: $($endpointDetails.swaggerUri)" -Level 'INFO'

        # Output deployment summary
        $summary = @{
            EndpointName          = $EndpointName
            DeploymentName        = $deploymentName
            Environment           = $Environment
            Strategy              = $DeploymentStrategy
            TrafficPercentage     = $InitialTrafficPercentage
            InstanceType          = $instanceConfig[$Environment].Type
            InstanceCount         = $instanceConfig[$Environment].Count
            ScoringUri            = $endpointDetails.scoringUri
            SwaggerUri            = $endpointDetails.swaggerUri
            DeploymentTimestamp   = Get-Date -Format 'o'
            Status                = 'Success'
        }

        $summary | ConvertTo-Json -Depth 10 | Out-File -FilePath "deployment-summary-$Environment.json"
        Write-Log "Deployment summary saved to deployment-summary-$Environment.json" -Level 'INFO'

        return $summary
    }
    else {
        Write-Log "[WhatIf] Deployment simulation completed successfully" -Level 'INFO'
    }
}
catch {
    Write-Log "Deployment failed: $_" -Level 'ERROR'
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level 'ERROR'

    # Attempt rollback if deployment was partially created
    if ($deploymentName -and -not $WhatIf) {
        Write-Log "Attempting to clean up failed deployment..." -Level 'WARNING'

        try {
            az ml online-deployment delete `
                --name $deploymentName `
                --endpoint $EndpointName `
                --yes --no-wait

            Write-Log "Cleanup initiated for deployment: $deploymentName" -Level 'INFO'
        }
        catch {
            Write-Log "Cleanup failed: $_" -Level 'ERROR'
        }
    }

    throw
}
finally {
    Write-Log "Deployment script execution completed" -Level 'INFO'
}

# Cost tracking integration (update Notion Software Tracker)
# Calculate monthly endpoint costs:
# - Standard_DS2_v2: ~$0.196/hour × 730 hours = ~$143/month
# - Standard_DS3_v2: ~$0.392/hour × 730 hours = ~$286/month
# - LowPriority discount: 60-80% cost reduction for dev/staging
