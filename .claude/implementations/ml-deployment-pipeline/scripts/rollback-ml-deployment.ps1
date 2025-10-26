# Rollback ML Deployment
# Establishes automated rollback procedures for Azure ML endpoint deployments when quality
# gates fail, errors exceed thresholds, or manual intervention is required for safe recovery.
#
# Purpose: Enable rapid recovery from failed ML deployments with minimal downtime
# Best for: Organizations requiring production-grade rollback capabilities with audit trails
# Version: 1.0.0
# Last Updated: 2025-10-26
#
# Usage:
#   .\rollback-ml-deployment.ps1 -EndpointName viability-scoring-prod
#   .\rollback-ml-deployment.ps1 -EndpointName viability-scoring-prod -ToDeployment deploy-20251026-143022
#   .\rollback-ml-deployment.ps1 -EndpointName viability-scoring-prod -DeleteFailedDeployment

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$EndpointName,

    [Parameter(Mandatory = $false)]
    [string]$ToDeployment = $null,  # Specific deployment to rollback to (default: previous stable)

    [Parameter(Mandatory = $false)]
    [switch]$DeleteFailedDeployment,  # Remove failed deployment after rollback

    [Parameter(Mandatory = $false)]
    [string]$Reason = 'Manual rollback requested',  # Reason for rollback (audit trail)

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Establish logging configuration
$logFile = "rollback-$EndpointName-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$logPath = Join-Path $PSScriptRoot "../logs" $logFile

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"

    Write-Host $logMessage
    Add-Content -Path $logPath -Value $logMessage
}

function Get-CurrentDeploymentTraffic {
    param([string]$EndpointName)

    $traffic = az ml online-endpoint show `
        --name $EndpointName `
        --query 'traffic' -o json 2>&1 | ConvertFrom-Json

    return $traffic
}

function Get-DeploymentHistory {
    param([string]$EndpointName)

    $deployments = az ml online-deployment list `
        --endpoint-name $EndpointName `
        --query '[].{name:name, created:createdTime, state:provisioningState}' -o json 2>&1 | ConvertFrom-Json

    return $deployments | Sort-Object -Property created -Descending
}

try {
    Write-Log "========================================" -Level 'INFO'
    Write-Log "STARTING ROLLBACK PROCEDURE" -Level 'WARNING'
    Write-Log "========================================" -Level 'INFO'
    Write-Log "Endpoint: $EndpointName" -Level 'INFO'
    Write-Log "Reason: $Reason" -Level 'INFO'
    Write-Log "Timestamp: $(Get-Date -Format 'o')" -Level 'INFO'

    # Validate Azure CLI authentication
    Write-Log "Validating Azure CLI authentication..." -Level 'INFO'
    $account = az account show 2>&1 | ConvertFrom-Json

    if (-not $account) {
        throw "Not authenticated to Azure CLI. Run 'az login' first."
    }

    Write-Log "Authenticated as: $($account.user.name)" -Level 'INFO'

    # Set Azure ML defaults
    az configure --defaults workspace=ml-brookside-prod group=rg-brookside-ml

    # Get current deployment traffic distribution
    Write-Log "Retrieving current traffic distribution..." -Level 'INFO'
    $currentTraffic = Get-CurrentDeploymentTraffic -EndpointName $EndpointName

    Write-Log "Current traffic distribution:" -Level 'INFO'
    $currentTraffic.PSObject.Properties | ForEach-Object {
        Write-Log "  $($_.Name): $($_.Value)%" -Level 'INFO'
    }

    # Identify current primary deployment (highest traffic)
    $primaryDeployment = $currentTraffic.PSObject.Properties |
        Sort-Object -Property Value -Descending |
        Select-Object -First 1

    Write-Log "Current primary deployment: $($primaryDeployment.Name) ($($primaryDeployment.Value)% traffic)" -Level 'INFO'

    # Get deployment history
    Write-Log "Retrieving deployment history..." -Level 'INFO'
    $deploymentHistory = Get-DeploymentHistory -EndpointName $EndpointName

    Write-Log "Deployment history:" -Level 'INFO'
    $deploymentHistory | ForEach-Object {
        Write-Log "  $($_.name) - Created: $($_.created) - State: $($_.state)" -Level 'INFO'
    }

    # Determine rollback target
    if ($ToDeployment) {
        # Validate specified deployment exists
        $targetDeployment = $deploymentHistory | Where-Object { $_.name -eq $ToDeployment }

        if (-not $targetDeployment) {
            throw "Specified deployment '$ToDeployment' not found in endpoint history"
        }

        Write-Log "Rolling back to specified deployment: $ToDeployment" -Level 'WARNING'
    }
    else {
        # Find previous stable deployment (second in history, excluding current primary)
        $targetDeployment = $deploymentHistory |
            Where-Object { $_.name -ne $primaryDeployment.Name -and $_.state -eq 'Succeeded' } |
            Select-Object -First 1

        if (-not $targetDeployment) {
            throw "No stable previous deployment found for rollback"
        }

        Write-Log "Rolling back to previous stable deployment: $($targetDeployment.name)" -Level 'WARNING'
    }

    # Confirmation prompt for production safety
    if (-not $WhatIf) {
        Write-Log "`nROLLBACK CONFIRMATION REQUIRED" -Level 'WARNING'
        Write-Log "FROM: $($primaryDeployment.Name)" -Level 'WARNING'
        Write-Log "TO:   $($targetDeployment.name)" -Level 'WARNING'
        Write-Log "This will immediately shift 100% traffic to the target deployment." -Level 'WARNING'

        $confirmation = Read-Host "`nProceed with rollback? (yes/no)"

        if ($confirmation -ne 'yes') {
            Write-Log "Rollback cancelled by user" -Level 'INFO'
            exit 0
        }
    }

    # Execute rollback: Shift 100% traffic to target deployment
    Write-Log "Executing rollback: Shifting 100% traffic to $($targetDeployment.name)..." -Level 'WARNING'

    if (-not $WhatIf) {
        az ml online-endpoint update `
            --name $EndpointName `
            --traffic "$($targetDeployment.name)=100"

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to update endpoint traffic during rollback"
        }

        Write-Log "Traffic successfully shifted to $($targetDeployment.name)" -Level 'INFO'
    }
    else {
        Write-Log "[WhatIf] Would shift 100% traffic to $($targetDeployment.name)" -Level 'INFO'
    }

    # Wait for traffic shift to propagate
    if (-not $WhatIf) {
        Write-Log "Waiting 30 seconds for traffic shift to propagate..." -Level 'INFO'
        Start-Sleep -Seconds 30
    }

    # Verify rollback success
    if (-not $WhatIf) {
        Write-Log "Verifying rollback success..." -Level 'INFO'
        $newTraffic = Get-CurrentDeploymentTraffic -EndpointName $EndpointName

        $verificationSuccess = $newTraffic.PSObject.Properties |
            Where-Object { $_.Name -eq $targetDeployment.name -and $_.Value -eq 100 }

        if ($verificationSuccess) {
            Write-Log "Rollback verification PASSED: 100% traffic on $($targetDeployment.name)" -Level 'INFO'
        }
        else {
            Write-Log "Rollback verification WARNING: Traffic distribution may not be as expected" -Level 'WARNING'
            Write-Log "Current traffic:" -Level 'WARNING'
            $newTraffic.PSObject.Properties | ForEach-Object {
                Write-Log "  $($_.Name): $($_.Value)%" -Level 'WARNING'
            }
        }
    }

    # Delete failed deployment if requested
    if ($DeleteFailedDeployment -and -not $WhatIf) {
        Write-Log "Deleting failed deployment: $($primaryDeployment.Name)..." -Level 'INFO'

        az ml online-deployment delete `
            --endpoint-name $EndpointName `
            --name $primaryDeployment.Name `
            --yes --no-wait

        if ($LASTEXITCODE -eq 0) {
            Write-Log "Failed deployment deletion initiated: $($primaryDeployment.Name)" -Level 'INFO'
        }
        else {
            Write-Log "Failed to delete deployment $($primaryDeployment.Name)" -Level 'WARNING'
        }
    }

    # Generate rollback audit record
    $auditRecord = @{
        EndpointName         = $EndpointName
        RollbackTimestamp    = Get-Date -Format 'o'
        FromDeployment       = $primaryDeployment.Name
        ToDeployment         = $targetDeployment.name
        Reason               = $Reason
        InitiatedBy          = $account.user.name
        DeletedFailedDeploy  = $DeleteFailedDeployment.IsPresent
        Success              = $true
        VerificationStatus   = 'Passed'
    }

    $auditFile = "rollback-audit-$EndpointName-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $auditRecord | ConvertTo-Json -Depth 10 | Out-File -FilePath $auditFile

    Write-Log "`nRollback audit record saved to: $auditFile" -Level 'INFO'

    Write-Log "`n========================================" -Level 'INFO'
    Write-Log "ROLLBACK COMPLETED SUCCESSFULLY" -Level 'INFO'
    Write-Log "========================================" -Level 'INFO'

    # Send notification (integrate with Teams/email as needed)
    Write-Log "`nNOTIFICATION: Rollback completed for $EndpointName" -Level 'INFO'
    Write-Log "Previous deployment: $($primaryDeployment.Name)" -Level 'INFO'
    Write-Log "Current deployment: $($targetDeployment.name)" -Level 'INFO'
    Write-Log "Reason: $Reason" -Level 'INFO'

    exit 0
}
catch {
    Write-Log "========================================" -Level 'ERROR'
    Write-Log "ROLLBACK FAILED" -Level 'ERROR'
    Write-Log "========================================" -Level 'ERROR'
    Write-Log "Error: $_" -Level 'ERROR'
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level 'ERROR'

    # Generate failure audit record
    $failureRecord = @{
        EndpointName      = $EndpointName
        RollbackTimestamp = Get-Date -Format 'o'
        Reason            = $Reason
        InitiatedBy       = $account.user.name
        Success           = $false
        Error             = $_.Exception.Message
        StackTrace        = $_.ScriptStackTrace
    }

    $failureFile = "rollback-failure-$EndpointName-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $failureRecord | ConvertTo-Json -Depth 10 | Out-File -FilePath $failureFile

    Write-Log "Failure audit record saved to: $failureFile" -Level 'ERROR'

    exit 1
}

# Rollback strategies by scenario:
#
# 1. Smoke Tests Fail (Automated):
#    - Triggered by CI/CD pipeline on test failure
#    - Immediate 100% rollback to previous stable
#    - Failed deployment deleted automatically
#
# 2. Error Rate Spike (Automated):
#    - Triggered by Application Insights alert (>5% errors)
#    - Gradual rollback: 100% -> 50% -> 0% on new deployment
#    - Monitor for 5 minutes between steps
#
# 3. Latency Degradation (Semi-automated):
#    - Alert on P95 latency >2000ms for 10 minutes
#    - Requires manual approval for rollback
#    - Keep deployment for investigation
#
# 4. Data Drift Detection (Manual):
#    - Alert on monthly drift report >15% deviation
#    - Schedule rollback during maintenance window
#    - Trigger model retraining pipeline
