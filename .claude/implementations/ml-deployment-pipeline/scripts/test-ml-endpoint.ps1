# Test ML Endpoint
# Establishes automated smoke testing for Azure ML managed endpoints with latency and
# success rate validation to ensure reliable model inference before production traffic.
#
# Purpose: Validate deployed ML endpoints through comprehensive smoke testing
# Best for: Organizations requiring automated health checks before production rollout
# Version: 1.0.0
# Last Updated: 2025-10-26
#
# Usage:
#   .\test-ml-endpoint.ps1 -EndpointName viability-scoring-dev -Environment dev
#   .\test-ml-endpoint.ps1 -EndpointName viability-scoring-prod -Environment prod -MaxLatency 1500

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$EndpointName,

    [Parameter(Mandatory = $true)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment,

    [Parameter(Mandatory = $false)]
    [int]$MaxLatency = 2000,  # Maximum acceptable latency in milliseconds

    [Parameter(Mandatory = $false)]
    [double]$MinSuccessRate = 0.95,  # Minimum 95% success rate

    [Parameter(Mandatory = $false)]
    [int]$NumTestRequests = 20,

    [Parameter(Mandatory = $false)]
    [string]$TestDataPath = $null,

    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Establish logging
$logFile = "smoke-test-$EndpointName-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$logPath = Join-Path $PSScriptRoot "../logs" $logFile

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"

    if ($Verbose -or $Level -eq 'ERROR' -or $Level -eq 'WARNING') {
        Write-Host $logMessage
    }

    Add-Content -Path $logPath -Value $logMessage
}

# Sample test data for viability scoring model
$sampleTestData = @{
    idea_title             = "AI-Powered Cost Optimization Platform"
    idea_description       = "Machine learning system for automated Azure cost optimization"
    research_score         = 85
    market_size            = "Large"
    technical_complexity   = "Medium"
    estimated_cost         = 15000
    team_capacity          = "High"
    strategic_alignment    = "High"
    competitive_advantage  = "Medium"
    time_to_market_months  = 6
}

try {
    Write-Log "Starting smoke tests for endpoint: $EndpointName" -Level 'INFO'

    # Get endpoint scoring URI
    Write-Log "Retrieving endpoint details..." -Level 'INFO'
    $endpointJson = az ml online-endpoint show --name $EndpointName --output json 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to retrieve endpoint details: $endpointJson"
    }

    $endpoint = $endpointJson | ConvertFrom-Json
    $scoringUri = $endpoint.scoring_uri

    if (-not $scoringUri) {
        throw "Scoring URI not found for endpoint $EndpointName"
    }

    Write-Log "Scoring URI: $scoringUri" -Level 'INFO'

    # Get endpoint authentication key
    Write-Log "Retrieving endpoint credentials..." -Level 'INFO'
    $credJson = az ml online-endpoint get-credentials --name $EndpointName --output json 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to retrieve endpoint credentials: $credJson"
    }

    $credentials = $credJson | ConvertFrom-Json
    $apiKey = $credentials.primaryKey

    if (-not $apiKey) {
        throw "API key not found for endpoint $EndpointName"
    }

    Write-Log "Authentication key retrieved successfully" -Level 'INFO'

    # Load test data
    if ($TestDataPath -and (Test-Path $TestDataPath)) {
        Write-Log "Loading test data from: $TestDataPath" -Level 'INFO'
        $testData = Get-Content $TestDataPath | ConvertFrom-Json
    }
    else {
        Write-Log "Using sample test data" -Level 'INFO'
        $testData = $sampleTestData
    }

    # Initialize test results tracking
    $testResults = @{
        TotalRequests      = $NumTestRequests
        SuccessfulRequests = 0
        FailedRequests     = 0
        TotalLatency       = 0
        MinLatency         = [double]::MaxValue
        MaxLatency         = 0
        LatencyP50         = 0
        LatencyP95         = 0
        LatencyP99         = 0
        SuccessRate        = 0
        MeetsLatencySLA    = $false
        MeetsSuccessRateSLA = $false
        Errors             = @()
        StartTime          = Get-Date
    }

    $latencies = @()

    Write-Log "Executing $NumTestRequests test requests..." -Level 'INFO'

    # Execute test requests
    for ($i = 1; $i -le $NumTestRequests; $i++) {
        try {
            $requestData = @{ data = @($testData) } | ConvertTo-Json -Depth 10

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            $response = Invoke-RestMethod `
                -Uri $scoringUri `
                -Method Post `
                -Headers @{ "Authorization" = "Bearer $apiKey"; "Content-Type" = "application/json" } `
                -Body $requestData `
                -TimeoutSec 30

            $stopwatch.Stop()
            $latency = $stopwatch.ElapsedMilliseconds

            # Validate response structure
            if ($response -and $response[0] -and $response[0].viability_score -ge 0 -and $response[0].viability_score -le 100) {
                $testResults.SuccessfulRequests++
                $latencies += $latency

                $testResults.TotalLatency += $latency
                $testResults.MinLatency = [Math]::Min($testResults.MinLatency, $latency)
                $testResults.MaxLatency = [Math]::Max($testResults.MaxLatency, $latency)

                Write-Log "Request $i succeeded (${latency}ms, score: $($response[0].viability_score))" -Level 'INFO'
            }
            else {
                throw "Invalid response format or score out of range"
            }
        }
        catch {
            $testResults.FailedRequests++
            $error = @{
                RequestNumber = $i
                Error         = $_.Exception.Message
                Timestamp     = Get-Date -Format 'o'
            }
            $testResults.Errors += $error

            Write-Log "Request $i failed: $($_.Exception.Message)" -Level 'ERROR'
        }
    }

    $testResults.EndTime = Get-Date
    $testResults.Duration = ($testResults.EndTime - $testResults.StartTime).TotalSeconds

    # Calculate percentile latencies
    if ($latencies.Count -gt 0) {
        $sortedLatencies = $latencies | Sort-Object

        $p50Index = [Math]::Floor($sortedLatencies.Count * 0.50)
        $p95Index = [Math]::Floor($sortedLatencies.Count * 0.95)
        $p99Index = [Math]::Floor($sortedLatencies.Count * 0.99)

        $testResults.LatencyP50 = $sortedLatencies[$p50Index]
        $testResults.LatencyP95 = $sortedLatencies[$p95Index]
        $testResults.LatencyP99 = $sortedLatencies[$p99Index]
        $testResults.AverageLatency = $testResults.TotalLatency / $testResults.SuccessfulRequests
    }

    # Calculate success rate
    $testResults.SuccessRate = $testResults.SuccessfulRequests / $testResults.TotalRequests

    # Evaluate SLA compliance
    $testResults.MeetsLatencySLA = $testResults.LatencyP95 -le $MaxLatency
    $testResults.MeetsSuccessRateSLA = $testResults.SuccessRate -ge $MinSuccessRate

    # Generate test summary
    Write-Log "`n========== SMOKE TEST RESULTS ==========" -Level 'INFO'
    Write-Log "Endpoint: $EndpointName ($Environment)" -Level 'INFO'
    Write-Log "Total Requests: $($testResults.TotalRequests)" -Level 'INFO'
    Write-Log "Successful Requests: $($testResults.SuccessfulRequests)" -Level 'INFO'
    Write-Log "Failed Requests: $($testResults.FailedRequests)" -Level 'INFO'
    Write-Log "Success Rate: $([Math]::Round($testResults.SuccessRate * 100, 2))%" -Level 'INFO'
    Write-Log "Average Latency: $([Math]::Round($testResults.AverageLatency, 2))ms" -Level 'INFO'
    Write-Log "Min Latency: $($testResults.MinLatency)ms" -Level 'INFO'
    Write-Log "Max Latency: $($testResults.MaxLatency)ms" -Level 'INFO'
    Write-Log "P50 Latency: $($testResults.LatencyP50)ms" -Level 'INFO'
    Write-Log "P95 Latency: $($testResults.LatencyP95)ms" -Level 'INFO'
    Write-Log "P99 Latency: $($testResults.LatencyP99)ms" -Level 'INFO'
    Write-Log "Duration: $([Math]::Round($testResults.Duration, 2))s" -Level 'INFO'

    Write-Log "`n========== SLA VALIDATION ==========" -Level 'INFO'
    Write-Log "Latency SLA (P95 <= ${MaxLatency}ms): $(if ($testResults.MeetsLatencySLA) { 'PASSED' } else { 'FAILED' })" `
        -Level $(if ($testResults.MeetsLatencySLA) { 'INFO' } else { 'ERROR' })
    Write-Log "Success Rate SLA (>= $([Math]::Round($MinSuccessRate * 100, 2))%): $(if ($testResults.MeetsSuccessRateSLA) { 'PASSED' } else { 'FAILED' })" `
        -Level $(if ($testResults.MeetsSuccessRateSLA) { 'INFO' } else { 'ERROR' })

    # Save results to JSON
    $resultsFile = "smoke_test_results_$EndpointName.json"
    $testResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsFile

    Write-Log "`nResults saved to: $resultsFile" -Level 'INFO'

    # Exit with error if SLA not met
    if (-not $testResults.MeetsLatencySLA -or -not $testResults.MeetsSuccessRateSLA) {
        Write-Log "Smoke tests FAILED: SLA requirements not met" -Level 'ERROR'
        exit 1
    }

    Write-Log "Smoke tests PASSED: All SLA requirements met" -Level 'INFO'
    exit 0
}
catch {
    Write-Log "Smoke test execution failed: $_" -Level 'ERROR'
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level 'ERROR'
    exit 1
}
