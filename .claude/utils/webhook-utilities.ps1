<#
.SYNOPSIS
    Webhook utilities for Notion agent activity integration testing and management

.DESCRIPTION
    Establish comprehensive webhook testing and configuration utilities supporting:
    - Webhook secret generation for secure HMAC-SHA256 signature verification
    - Test payload creation with valid signatures
    - Endpoint health validation
    - End-to-end webhook flow testing

    Best for: Organizations deploying webhook-based integration requiring pre-deployment validation
    and operational health monitoring of Azure Function endpoints.

.PARAMETER Operation
    Utility operation to perform:
    - GenerateSecret: Create new webhook signing secret
    - TestEndpoint: Validate Azure Function endpoint accessibility
    - SendTestPayload: POST test activity event with signature verification
    - HealthCheck: Comprehensive endpoint health assessment

.PARAMETER WebhookEndpoint
    Azure Function webhook URL (default: production endpoint from hook config)

.PARAMETER WebhookSecret
    Webhook signing secret (default: retrieve from Azure Key Vault)

.EXAMPLE
    # Generate new webhook secret for Key Vault storage
    .\webhook-utilities.ps1 -Operation GenerateSecret

.EXAMPLE
    # Test endpoint accessibility
    .\webhook-utilities.ps1 -Operation TestEndpoint

.EXAMPLE
    # Send test payload with signature verification
    .\webhook-utilities.ps1 -Operation SendTestPayload -WebhookSecret "your-secret-here"

.EXAMPLE
    # Comprehensive health check
    .\webhook-utilities.ps1 -Operation HealthCheck

.NOTES
    Author: Brookside BI Innovation Nexus
    Purpose: Streamline webhook deployment validation and operational monitoring
    Related: azure-functions/notion-webhook/README.md
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("GenerateSecret", "TestEndpoint", "SendTestPayload", "HealthCheck")]
    [string]$Operation,

    [Parameter(Mandatory = $false)]
    [string]$WebhookEndpoint = "https://notion-webhook-brookside-prod.azurewebsites.net/api/NotionWebhook",

    [Parameter(Mandatory = $false)]
    [string]$WebhookSecret = ""
)

$ErrorActionPreference = "Stop"

# Establish logging configuration
function Write-UtilityLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "DEBUG")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "DEBUG" { "Gray" }
        default { "White" }
    }

    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage -ForegroundColor $color
}

# Generate cryptographically secure webhook secret (HMAC-SHA256)
function New-WebhookSecret {
    Write-UtilityLog "Generating cryptographically secure webhook secret..." -Level INFO

    $bytes = New-Object byte[] 32
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($bytes)
    $secret = [System.BitConverter]::ToString($bytes).Replace("-", "").ToLower()

    Write-UtilityLog "Secret generated successfully (64 hex characters)" -Level SUCCESS
    Write-Host "`nWebhook Secret (store in Azure Key Vault 'notion-webhook-secret'):" -ForegroundColor Cyan
    Write-Host $secret -ForegroundColor Yellow
    Write-Host "`nAzure CLI command to store secret:" -ForegroundColor Cyan
    Write-Host "az keyvault secret set --vault-name kv-brookside-secrets --name notion-webhook-secret --value `"$secret`"" -ForegroundColor Gray

    return $secret
}

# Generate HMAC-SHA256 signature for webhook payload
function New-WebhookSignature {
    param(
        [string]$Payload,
        [string]$Secret
    )

    $hmac = [System.Security.Cryptography.HMACSHA256]::new([System.Text.Encoding]::UTF8.GetBytes($Secret))
    $hash = $hmac.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Payload))
    $signature = [System.BitConverter]::ToString($hash).Replace("-", "").ToLower()

    return "v1=$signature"
}

# Test endpoint accessibility and basic health
function Test-WebhookEndpoint {
    param([string]$Endpoint)

    Write-UtilityLog "Testing endpoint accessibility: $Endpoint" -Level INFO

    try {
        # Test basic HTTP connectivity (expect 400/401 for GET request)
        $response = Invoke-WebRequest -Uri $Endpoint -Method Get -ErrorAction SilentlyContinue

        Write-UtilityLog "Endpoint returned status: $($response.StatusCode)" -Level WARNING
        Write-UtilityLog "Note: GET request expected to fail - testing POST endpoint" -Level DEBUG
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 401) {
            Write-UtilityLog "Endpoint accessible - Returned 401 Unauthorized (expected for GET)" -Level SUCCESS
            return $true
        }
        elseif ($_.Exception.Response.StatusCode -eq 400) {
            Write-UtilityLog "Endpoint accessible - Returned 400 Bad Request (expected for GET)" -Level SUCCESS
            return $true
        }
        else {
            Write-UtilityLog "Endpoint test failed: $_" -Level ERROR
            return $false
        }
    }

    return $true
}

# Send test agent activity payload to webhook endpoint
function Send-TestPayload {
    param(
        [string]$Endpoint,
        [string]$Secret
    )

    Write-UtilityLog "Preparing test agent activity payload..." -Level INFO

    # Build test payload matching AgentActivityEvent structure
    $testPayload = @{
        sessionId = "test-webhook-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        agentName = "@webhook-test-agent"
        status = "completed"
        workDescription = "Webhook integration validation test - verifying end-to-end flow from hook to Notion via Azure Function"
        startTime = (Get-Date).AddMinutes(-5).ToString('yyyy-MM-ddTHH:mm:ssZ')
        endTime = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
        durationMinutes = 5
        filesCreated = 2
        filesUpdated = 1
        linesGenerated = 150
        deliverablesCount = 1
        deliverables = @(
            "Validated webhook signature verification",
            "Confirmed Azure Function accessibility",
            "Tested Notion page creation"
        )
        nextSteps = "Monitor Application Insights for test activity entry"
        performanceMetrics = "Latency: <500ms, Success rate: 100%"
        queuedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
        syncStatus = "pending"
        retryCount = 0
        webhookSynced = $false
        webhookAttemptedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
    }

    $payloadJson = $testPayload | ConvertTo-Json -Compress
    Write-UtilityLog "Payload size: $($payloadJson.Length) bytes" -Level DEBUG

    # Generate signature
    $signature = New-WebhookSignature -Payload $payloadJson -Secret $Secret
    Write-UtilityLog "Generated signature: $signature" -Level DEBUG

    # Send POST request
    try {
        Write-UtilityLog "Sending POST request to webhook endpoint..." -Level INFO

        $headers = @{
            "Notion-Signature" = $signature
            "Content-Type" = "application/json"
        }

        $response = Invoke-RestMethod -Uri $Endpoint `
            -Method Post `
            -Headers $headers `
            -Body $payloadJson `
            -TimeoutSec 30 `
            -ErrorAction Stop

        Write-UtilityLog "Webhook request successful!" -Level SUCCESS
        Write-Host "`nResponse Details:" -ForegroundColor Cyan
        Write-Host "  Success: $($response.success)" -ForegroundColor Green
        Write-Host "  Message: $($response.message)" -ForegroundColor White
        Write-Host "  Page ID: $($response.pageId)" -ForegroundColor Gray
        Write-Host "  Page URL: $($response.pageUrl)" -ForegroundColor Blue
        Write-Host "  Duration: $($response.duration)ms" -ForegroundColor Gray

        Write-Host "`nNext Steps:" -ForegroundColor Cyan
        Write-Host "  1. Verify page created in Agent Activity Hub: $($response.pageUrl)" -ForegroundColor White
        Write-Host "  2. Check Application Insights logs for execution details" -ForegroundColor White
        Write-Host "  3. Confirm webhook signature verification succeeded" -ForegroundColor White

        return $true
    }
    catch {
        Write-UtilityLog "Webhook request failed: $_" -Level ERROR

        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            Write-Host "`nError Details:" -ForegroundColor Red
            Write-Host "  Status Code: $statusCode" -ForegroundColor White

            if ($statusCode -eq 401) {
                Write-Host "  Likely Cause: Invalid webhook signature" -ForegroundColor Yellow
                Write-Host "  Solution: Verify webhook secret matches Key Vault value" -ForegroundColor Yellow
            }
            elseif ($statusCode -eq 500) {
                Write-Host "  Likely Cause: Notion API error or database access issue" -ForegroundColor Yellow
                Write-Host "  Solution: Check Application Insights logs and database permissions" -ForegroundColor Yellow
            }
        }

        return $false
    }
}

# Comprehensive health check
function Invoke-HealthCheck {
    param(
        [string]$Endpoint,
        [string]$Secret
    )

    Write-UtilityLog "`n========== Webhook Health Check Started ==========" -Level INFO

    $checks = @{
        EndpointAccessibility = $false
        SignatureGeneration = $false
        PayloadDelivery = $false
    }

    # 1. Endpoint accessibility
    Write-UtilityLog "`n[1/3] Testing endpoint accessibility..." -Level INFO
    $checks.EndpointAccessibility = Test-WebhookEndpoint -Endpoint $Endpoint

    # 2. Signature generation
    Write-UtilityLog "`n[2/3] Testing signature generation..." -Level INFO
    if ([string]::IsNullOrWhiteSpace($Secret)) {
        Write-UtilityLog "No webhook secret provided - skipping signature test" -Level WARNING
        Write-UtilityLog "Provide secret with -WebhookSecret parameter for full validation" -Level INFO
    }
    else {
        $testSig = New-WebhookSignature -Payload "test" -Secret $Secret
        $checks.SignatureGeneration = $testSig.StartsWith("v1=")
        Write-UtilityLog "Signature format valid: $($checks.SignatureGeneration)" -Level $(if ($checks.SignatureGeneration) { "SUCCESS" } else { "ERROR" })
    }

    # 3. Payload delivery (only if secret provided)
    if (-not [string]::IsNullOrWhiteSpace($Secret)) {
        Write-UtilityLog "`n[3/3] Testing payload delivery with signature..." -Level INFO
        $checks.PayloadDelivery = Send-TestPayload -Endpoint $Endpoint -Secret $Secret
    }
    else {
        Write-UtilityLog "`n[3/3] Skipping payload delivery test (no secret provided)" -Level WARNING
    }

    # Summary
    Write-UtilityLog "`n========== Health Check Summary ==========" -Level INFO
    Write-Host "Endpoint Accessibility: $(if ($checks.EndpointAccessibility) { '✓ PASS' } else { '✗ FAIL' })" -ForegroundColor $(if ($checks.EndpointAccessibility) { "Green" } else { "Red" })
    Write-Host "Signature Generation:   $(if ($checks.SignatureGeneration) { '✓ PASS' } else { '⊘ SKIP' })" -ForegroundColor $(if ($checks.SignatureGeneration) { "Green" } elseif ([string]::IsNullOrWhiteSpace($Secret)) { "Yellow" } else { "Red" })
    Write-Host "Payload Delivery:       $(if ($checks.PayloadDelivery) { '✓ PASS' } else { '⊘ SKIP' })" -ForegroundColor $(if ($checks.PayloadDelivery) { "Green" } elseif ([string]::IsNullOrWhiteSpace($Secret)) { "Yellow" } else { "Red" })

    $overallPass = $checks.EndpointAccessibility -and ($checks.SignatureGeneration -or [string]::IsNullOrWhiteSpace($Secret))

    Write-Host "`nOverall Status: $(if ($overallPass) { 'HEALTHY ✓' } else { 'ISSUES DETECTED ✗' })" -ForegroundColor $(if ($overallPass) { "Green" } else { "Red" })
}

# Main execution
try {
    Write-Host "`n=== Webhook Utilities ===" -ForegroundColor Cyan
    Write-Host "Operation: $Operation" -ForegroundColor White
    Write-Host "Endpoint: $WebhookEndpoint`n" -ForegroundColor Gray

    switch ($Operation) {
        "GenerateSecret" {
            New-WebhookSecret
        }

        "TestEndpoint" {
            $result = Test-WebhookEndpoint -Endpoint $WebhookEndpoint
            if (-not $result) {
                exit 1
            }
        }

        "SendTestPayload" {
            if ([string]::IsNullOrWhiteSpace($WebhookSecret)) {
                Write-UtilityLog "ERROR: WebhookSecret parameter required for SendTestPayload operation" -Level ERROR
                Write-UtilityLog "Usage: .\webhook-utilities.ps1 -Operation SendTestPayload -WebhookSecret 'your-secret'" -Level INFO
                exit 1
            }

            $result = Send-TestPayload -Endpoint $WebhookEndpoint -Secret $WebhookSecret
            if (-not $result) {
                exit 1
            }
        }

        "HealthCheck" {
            Invoke-HealthCheck -Endpoint $WebhookEndpoint -Secret $WebhookSecret
        }
    }

    Write-Host "`n[SUCCESS] Operation completed successfully`n" -ForegroundColor Green
    exit 0
}
catch {
    Write-UtilityLog "FATAL ERROR: $_" -Level ERROR
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}
