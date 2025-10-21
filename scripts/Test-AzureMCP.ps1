# Test Azure MCP Server Startup
# This script tests if the Azure MCP server can start and respond to the MCP protocol

Write-Host "Testing Azure MCP Server..." -ForegroundColor Cyan

# Test 1: Check if Azure CLI is authenticated
Write-Host ""
Write-Host "Test 1: Azure CLI Authentication" -ForegroundColor Yellow
try {
    $account = az account show 2>&1 | ConvertFrom-Json
    Write-Host "OK Authenticated as: $($account.user.name)" -ForegroundColor Green
    Write-Host "  Subscription: $($account.name)" -ForegroundColor Gray
    Write-Host "  Tenant: $($account.tenantDisplayName)" -ForegroundColor Gray
}
catch {
    Write-Host "FAIL Azure CLI not authenticated" -ForegroundColor Red
    Write-Host "  Please run: az login" -ForegroundColor Yellow
    exit 1
}

# Test 2: Check if @azure/mcp package is available
Write-Host ""
Write-Host "Test 2: Azure MCP Package" -ForegroundColor Yellow
try {
    $version = npx -y @azure/mcp@latest --version 2>&1
    Write-Host "OK Azure MCP version: $version" -ForegroundColor Green
}
catch {
    Write-Host "FAIL Failed to run Azure MCP package" -ForegroundColor Red
    exit 1
}

# Test 3: Try to start the MCP server
Write-Host ""
Write-Host "Test 3: MCP Server Startup" -ForegroundColor Yellow
try {
    Write-Host "  Starting MCP server..." -ForegroundColor Gray

    # Start the process and capture output
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "cmd.exe"
    $pinfo.Arguments = "/c npx -y @azure/mcp@latest server start --debug"
    $pinfo.UseShellExecute = $false
    $pinfo.RedirectStandardOutput = $true
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardInput = $true

    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null

    # Send a simple JSON-RPC initialize message
    $initMsg = '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'
    $p.StandardInput.WriteLine($initMsg)
    $p.StandardInput.Close()

    # Wait for output with timeout
    $timeout = 5
    $i = 0
    $output = ""
    $errorOutput = ""

    while ($i -lt $timeout -and -not $p.HasExited) {
        Start-Sleep -Seconds 1
        $i++
    }

    # Try to read output
    if (-not $p.StandardOutput.EndOfStream) {
        $output = $p.StandardOutput.ReadToEnd()
    }

    if (-not $p.StandardError.EndOfStream) {
        $errorOutput = $p.StandardError.ReadToEnd()
    }

    # Kill the process if still running
    if (-not $p.HasExited) {
        $p.Kill()
    }

    $p.WaitForExit()
    $p.Dispose()

    if ($output) {
        Write-Host "OK MCP Server produced output" -ForegroundColor Green
        Write-Host "  First 300 chars:" -ForegroundColor Gray
        $truncated = $output.Substring(0, [Math]::Min(300, $output.Length))
        Write-Host "  $truncated" -ForegroundColor Gray
    }
    elseif ($errorOutput) {
        Write-Host "FAIL MCP Server produced errors" -ForegroundColor Red
        Write-Host "  Error output:" -ForegroundColor Gray
        Write-Host "  $errorOutput" -ForegroundColor Gray
    }
    else {
        Write-Host "FAIL No output from MCP server" -ForegroundColor Red
    }
}
catch {
    Write-Host "FAIL Exception occurred: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Test Complete" -ForegroundColor Cyan
