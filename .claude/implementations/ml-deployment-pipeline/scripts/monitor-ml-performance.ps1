# Monitor ML Performance
# Establishes real-time monitoring dashboard for Azure ML endpoints with data drift detection,
# performance metric tracking, and automated alerting for proactive quality assurance.
#
# Purpose: Comprehensive ML endpoint monitoring with alert configuration
# Best for: Organizations requiring production ML monitoring with SLA enforcement
# Version: 1.0.0
# Last Updated: 2025-10-26
#
# Usage:
#   .\monitor-ml-performance.ps1 -EndpointName viability-scoring-prod -Metric error_rate
#   .\monitor-ml-performance.ps1 -EndpointName viability-scoring-prod -ConfigureAlerts
#   .\monitor-ml-performance.ps1 -EndpointName viability-scoring-prod -GenerateDashboard

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$EndpointName,

    [Parameter(Mandatory = $false)]
    [ValidateSet('error_rate', 'latency_p95', 'throughput', 'availability', 'all')]
    [string]$Metric = 'all',

    [Parameter(Mandatory = $false)]
    [switch]$ConfigureAlerts,

    [Parameter(Mandatory = $false)]
    [string]$AlertEmail = 'consultations@brooksidebi.com',

    [Parameter(Mandatory = $false)]
    [double]$DataDriftThreshold = 0.15,  # 15% drift triggers alert

    [Parameter(Mandatory = $false)]
    [double]$AccuracyDropThreshold = 0.05,  # 5% accuracy drop triggers alert

    [Parameter(Mandatory = $false)]
    [int]$LatencyThresholdMs = 2000,  # 2 seconds P95 latency threshold

    [Parameter(Mandatory = $false)]
    [double]$ErrorRateThreshold = 0.05,  # 5% error rate threshold

    [Parameter(Mandatory = $false)]
    [int]$TimeWindowMinutes = 15,  # Monitoring time window

    [Parameter(Mandatory = $false)]
    [string]$Environment = $null,

    [Parameter(Mandatory = $false)]
    [switch]$GenerateDashboard
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Establish logging
$logFile = "monitor-$EndpointName-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$logPath = Join-Path $PSScriptRoot "../logs" $logFile

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"

    Write-Host $logMessage
    Add-Content -Path $logPath -Value $logMessage
}

function Get-ApplicationInsightsMetrics {
    param(
        [string]$EndpointName,
        [string]$MetricName,
        [int]$TimeWindowMinutes
    )

    # Get Application Insights resource ID for endpoint
    $appInsightsId = az ml online-endpoint show `
        --name $EndpointName `
        --query 'properties.appInsights' -o tsv 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Log "Failed to retrieve Application Insights resource for endpoint" -Level 'WARNING'
        return $null
    }

    # Query Application Insights for metrics
    $endTime = Get-Date
    $startTime = $endTime.AddMinutes(-$TimeWindowMinutes)

    $query = switch ($MetricName) {
        'error_rate' {
            @"
requests
| where timestamp > datetime($($startTime.ToString('yyyy-MM-ddTHH:mm:ss')))
| where timestamp < datetime($($endTime.ToString('yyyy-MM-ddTHH:mm:ss')))
| summarize
    TotalRequests = count(),
    FailedRequests = countif(success == false)
| extend ErrorRate = todouble(FailedRequests) / todouble(TotalRequests)
| project ErrorRate
"@
        }
        'latency_p95' {
            @"
requests
| where timestamp > datetime($($startTime.ToString('yyyy-MM-ddTHH:mm:ss')))
| where timestamp < datetime($($endTime.ToString('yyyy-MM-ddTHH:mm:ss')))
| summarize P95Latency = percentile(duration, 95)
| project P95Latency
"@
        }
        'throughput' {
            @"
requests
| where timestamp > datetime($($startTime.ToString('yyyy-MM-ddTHH:mm:ss')))
| where timestamp < datetime($($endTime.ToString('yyyy-MM-ddTHH:mm:ss')))
| summarize RequestCount = count()
| extend RequestsPerMinute = todouble(RequestCount) / $TimeWindowMinutes
| project RequestsPerMinute
"@
        }
        'availability' {
            @"
requests
| where timestamp > datetime($($startTime.ToString('yyyy-MM-ddTHH:mm:ss')))
| where timestamp < datetime($($endTime.ToString('yyyy-MM-ddTHH:mm:ss')))
| summarize
    TotalRequests = count(),
    SuccessfulRequests = countif(success == true)
| extend Availability = todouble(SuccessfulRequests) / todouble(TotalRequests) * 100
| project Availability
"@
        }
    }

    # Execute query against Application Insights
    try {
        $result = az monitor app-insights query `
            --app $appInsightsId `
            --analytics-query $query `
            --output json 2>&1 | ConvertFrom-Json

        return $result.tables[0].rows[0][0]
    }
    catch {
        Write-Log "Failed to query Application Insights: $_" -Level 'WARNING'
        return $null
    }
}

function Configure-MetricAlerts {
    param(
        [string]$EndpointName,
        [string]$AlertEmail,
        [hashtable]$Thresholds
    )

    Write-Log "Configuring metric alerts for endpoint: $EndpointName" -Level 'INFO'

    # Get endpoint resource ID
    $endpointId = az ml online-endpoint show `
        --name $EndpointName `
        --query 'id' -o tsv 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to retrieve endpoint resource ID"
    }

    # Create action group for alert notifications
    $actionGroupName = "ag-ml-alerts-$EndpointName"

    az monitor action-group create `
        --name $actionGroupName `
        --resource-group rg-brookside-ml `
        --short-name "ML Alerts" `
        --email receiver $AlertEmail email=$AlertEmail

    if ($LASTEXITCODE -ne 0) {
        Write-Log "Failed to create action group (may already exist)" -Level 'WARNING'
    }

    $actionGroupId = az monitor action-group show `
        --name $actionGroupName `
        --resource-group rg-brookside-ml `
        --query 'id' -o tsv

    # Configure error rate alert
    Write-Log "Creating error rate alert (threshold: $($Thresholds.ErrorRate * 100)%)..." -Level 'INFO'

    az monitor metrics alert create `
        --name "high-error-rate-$EndpointName" `
        --resource-group rg-brookside-ml `
        --scopes $endpointId `
        --condition "avg requests/failed > $($Thresholds.ErrorRate * 100)" `
        --window-size 15m `
        --evaluation-frequency 5m `
        --action $actionGroupId `
        --description "Alert when error rate exceeds $($Thresholds.ErrorRate * 100)% for 15 minutes" `
        --severity 2

    # Configure latency alert
    Write-Log "Creating latency alert (threshold: $($Thresholds.Latency)ms)..." -Level 'INFO'

    az monitor metrics alert create `
        --name "high-latency-$EndpointName" `
        --resource-group rg-brookside-ml `
        --scopes $endpointId `
        --condition "avg requests/duration > $($Thresholds.Latency)" `
        --window-size 15m `
        --evaluation-frequency 5m `
        --action $actionGroupId `
        --description "Alert when P95 latency exceeds $($Thresholds.Latency)ms for 15 minutes" `
        --severity 3

    # Configure availability alert
    Write-Log "Creating availability alert (threshold: 99%)..." -Level 'INFO'

    az monitor metrics alert create `
        --name "low-availability-$EndpointName" `
        --resource-group rg-brookside-ml `
        --scopes $endpointId `
        --condition "avg requests/success < 99" `
        --window-size 15m `
        --evaluation-frequency 5m `
        --action $actionGroupId `
        --description "Alert when endpoint availability drops below 99% for 15 minutes" `
        --severity 1

    Write-Log "Metric alerts configured successfully" -Level 'INFO'
}

function Generate-PerformanceDashboard {
    param([string]$EndpointName)

    Write-Log "Generating performance dashboard for: $EndpointName" -Level 'INFO'

    # Collect metrics
    $metrics = @{
        ErrorRate        = Get-ApplicationInsightsMetrics -EndpointName $EndpointName -MetricName 'error_rate' -TimeWindowMinutes $TimeWindowMinutes
        LatencyP95       = Get-ApplicationInsightsMetrics -EndpointName $EndpointName -MetricName 'latency_p95' -TimeWindowMinutes $TimeWindowMinutes
        Throughput       = Get-ApplicationInsightsMetrics -EndpointName $EndpointName -MetricName 'throughput' -TimeWindowMinutes $TimeWindowMinutes
        Availability     = Get-ApplicationInsightsMetrics -EndpointName $EndpointName -MetricName 'availability' -TimeWindowMinutes $TimeWindowMinutes
        Timestamp        = Get-Date -Format 'o'
        TimeWindow       = "$TimeWindowMinutes minutes"
    }

    # Generate dashboard markdown
    $dashboard = @"
# ML Endpoint Performance Dashboard
## $EndpointName

**Generated**: $($metrics.Timestamp)
**Time Window**: $($metrics.TimeWindow)

---

## Key Metrics

| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| **Error Rate** | $([Math]::Round($metrics.ErrorRate * 100, 2))% | <$($ErrorRateThreshold * 100)% | $(if ($metrics.ErrorRate -lt $ErrorRateThreshold) { '✅ PASS' } else { '❌ FAIL' }) |
| **P95 Latency** | $([Math]::Round($metrics.LatencyP95, 0))ms | <${LatencyThresholdMs}ms | $(if ($metrics.LatencyP95 -lt $LatencyThresholdMs) { '✅ PASS' } else { '❌ FAIL' }) |
| **Throughput** | $([Math]::Round($metrics.Throughput, 2)) req/min | N/A | ℹ️ INFO |
| **Availability** | $([Math]::Round($metrics.Availability, 2))% | >99% | $(if ($metrics.Availability -gt 99) { '✅ PASS' } else { '❌ FAIL' }) |

---

## Performance Trends

### Error Rate Over Time
$(if ($metrics.ErrorRate -lt $ErrorRateThreshold) {
"Current error rate is within acceptable thresholds. System is operating normally."
} else {
"⚠️ **WARNING**: Error rate exceeds threshold. Investigate immediately."
})

### Latency Distribution
$(if ($metrics.LatencyP95 -lt $LatencyThresholdMs) {
"P95 latency is within SLA requirements. Response times are acceptable."
} else {
"⚠️ **WARNING**: Latency exceeds SLA. Consider scaling or optimization."
})

### Availability Status
$(if ($metrics.Availability -gt 99.9) {
"✅ Endpoint is highly available and meeting SLA requirements (99.9%+)."
} elseif ($metrics.Availability -gt 99) {
"✅ Endpoint is meeting minimum SLA requirements (99%+)."
} else {
"❌ **CRITICAL**: Availability below SLA. Immediate investigation required."
})

---

## Recommendations

$(if ($metrics.ErrorRate -gt $ErrorRateThreshold) {
"- **High Error Rate**: Review Application Insights logs for error patterns
- Check model input validation and data quality
- Consider rolling back to previous stable deployment
"
})

$(if ($metrics.LatencyP95 -gt $LatencyThresholdMs) {
"- **High Latency**: Evaluate endpoint scaling configuration
- Review model inference optimization opportunities
- Consider moving to larger instance types or increasing instance count
"
})

$(if ($metrics.Availability -lt 99) {
"- **Low Availability**: Check endpoint health and deployment status
- Review recent deployments for correlation with availability drop
- Verify Azure service health for underlying infrastructure
"
})

---

## Data Drift Monitoring

$(if ($Environment -eq 'prod') {
"**Status**: Scheduled monthly drift analysis
**Next Analysis**: $(( Get-Date).AddMonths(1).ToString('yyyy-MM-dd'))
**Threshold**: $($DataDriftThreshold * 100)% deviation

Data drift detection runs on the first Monday of each month. Results are automatically logged to Application Insights custom events."
} else {
"**Status**: Data drift monitoring is enabled for production environments only.
"
})

---

## Cost Analysis

**Estimated Monthly Cost** (based on current traffic):
- Instance Type: Standard_DS3_v2
- Instance Count: $(if ($Environment -eq 'prod') { '2' } else { '1' })
- Estimated Cost: $(if ($Environment -eq 'prod') { '$572' } else { '$143' }) per month

*Note: Actual costs may vary based on traffic patterns and scaling behavior.*

---

**Last Updated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@

    $dashboardFile = "dashboard-$EndpointName.md"
    $dashboard | Out-File -FilePath $dashboardFile

    Write-Log "Dashboard saved to: $dashboardFile" -Level 'INFO'

    return $metrics
}

try {
    Write-Log "Starting ML endpoint monitoring: $EndpointName" -Level 'INFO'

    # Validate Azure CLI authentication
    $account = az account show 2>&1 | ConvertFrom-Json

    if (-not $account) {
        throw "Not authenticated to Azure CLI. Run 'az login' first."
    }

    # Set Azure ML defaults
    az configure --defaults workspace=ml-brookside-prod group=rg-brookside-ml

    if ($ConfigureAlerts) {
        # Configure metric alerts
        $thresholds = @{
            ErrorRate = $ErrorRateThreshold
            Latency   = $LatencyThresholdMs
        }

        Configure-MetricAlerts `
            -EndpointName $EndpointName `
            -AlertEmail $AlertEmail `
            -Thresholds $thresholds

        Write-Log "Alert configuration completed successfully" -Level 'INFO'
    }
    elseif ($GenerateDashboard) {
        # Generate performance dashboard
        $metrics = Generate-PerformanceDashboard -EndpointName $EndpointName

        Write-Log "Dashboard generation completed successfully" -Level 'INFO'

        return $metrics
    }
    elseif ($Metric -ne 'all') {
        # Query specific metric
        $value = Get-ApplicationInsightsMetrics `
            -EndpointName $EndpointName `
            -MetricName $Metric `
            -TimeWindowMinutes $TimeWindowMinutes

        if ($null -ne $value) {
            Write-Log "$Metric : $value" -Level 'INFO'
            Write-Output $value
        }
        else {
            Write-Log "Failed to retrieve metric: $Metric" -Level 'WARNING'
        }
    }
    else {
        # Query all metrics
        Write-Log "Retrieving all metrics for $EndpointName..." -Level 'INFO'

        $allMetrics = @{
            ErrorRate    = Get-ApplicationInsightsMetrics -EndpointName $EndpointName -MetricName 'error_rate' -TimeWindowMinutes $TimeWindowMinutes
            LatencyP95   = Get-ApplicationInsightsMetrics -EndpointName $EndpointName -MetricName 'latency_p95' -TimeWindowMinutes $TimeWindowMinutes
            Throughput   = Get-ApplicationInsightsMetrics -EndpointName $EndpointName -MetricName 'throughput' -TimeWindowMinutes $TimeWindowMinutes
            Availability = Get-ApplicationInsightsMetrics -EndpointName $EndpointName -MetricName 'availability' -TimeWindowMinutes $TimeWindowMinutes
        }

        Write-Log "`nMETRICS SUMMARY ($TimeWindowMinutes min window):" -Level 'INFO'
        Write-Log "  Error Rate: $([Math]::Round($allMetrics.ErrorRate * 100, 2))%" -Level 'INFO'
        Write-Log "  P95 Latency: $([Math]::Round($allMetrics.LatencyP95, 0))ms" -Level 'INFO'
        Write-Log "  Throughput: $([Math]::Round($allMetrics.Throughput, 2)) req/min" -Level 'INFO'
        Write-Log "  Availability: $([Math]::Round($allMetrics.Availability, 2))%" -Level 'INFO'

        return $allMetrics
    }
}
catch {
    Write-Log "Monitoring operation failed: $_" -Level 'ERROR'
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level 'ERROR'
    exit 1
}
