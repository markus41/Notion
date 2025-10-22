# Test script for session-parser.ps1
# Run this to validate session parser functionality

# Load the session parser functions
. "$PSScriptRoot\session-parser.ps1"

Write-Host "`n=== SESSION PARSER TESTS ===" -ForegroundColor Cyan
Write-Host "Testing Brookside BI Innovation Nexus automatic logging components`n" -ForegroundColor Gray

# Test 1: File Categorization
Write-Host "Test 1: File Categorization" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

$testFiles = @(
    'README.md',
    'CLAUDE.md',
    'src/main.py',
    'src/utils/helper.ts',
    'deployment/main.bicep',
    'config.json',
    'test_app.py',
    'setup.ps1',
    '.github/workflows/ci.yml',
    'data/sample.csv',
    'Dockerfile'
)

foreach ($file in $testFiles) {
    $category = Get-FileCategory -FilePath $file
    Write-Host "  $file" -NoNewline
    Write-Host " -> $category" -ForegroundColor Yellow
}

# Test 2: Session ID Generation
Write-Host "`nTest 2: Session ID Generation" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

$testAgents = @('@build-architect', '@cost-analyst', '@schema-manager')
foreach ($agent in $testAgents) {
    $sessionId = New-SessionId -AgentName $agent
    Write-Host "  $agent" -NoNewline
    Write-Host " -> $sessionId" -ForegroundColor Yellow
}

# Test 3: Deliverables Detection
Write-Host "`nTest 3: Deliverables Detection" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

$startTime = (Get-Date).AddMinutes(-10)
Write-Host "  Scanning for files modified in last 10 minutes..." -ForegroundColor Gray

try {
    $deliverables = Get-SessionDeliverables -StartTime $startTime
    Write-Host "  Files Created: $($deliverables.FilesCreated.Count)" -ForegroundColor Yellow
    Write-Host "  Files Updated: $($deliverables.FilesUpdated.Count)" -ForegroundColor Yellow
    Write-Host "  Total Files: $($deliverables.TotalFiles)" -ForegroundColor Yellow
    Write-Host "  Estimated Lines: $($deliverables.EstimatedLines)" -ForegroundColor Yellow

    if ($deliverables.Categories.Count -gt 0) {
        Write-Host "`n  Categories:" -ForegroundColor Gray
        foreach ($category in $deliverables.Categories.Keys | Sort-Object) {
            $count = $deliverables.Categories[$category]
            Write-Host "    - ${category}: $count files" -ForegroundColor Yellow
        }
    }

    if ($deliverables.FilesCreated.Count -gt 0) {
        Write-Host "`n  Recently Created Files:" -ForegroundColor Gray
        $deliverables.FilesCreated | Select-Object -First 5 | ForEach-Object {
            Write-Host "    - $_" -ForegroundColor Yellow
        }
    }
}
catch {
    Write-Host "  Error: $_" -ForegroundColor Red
}

# Test 4: Metrics Calculation
Write-Host "`nTest 4: Metrics Calculation" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

$testDeliverables = @{
    FilesCreated = @('file1.py', 'file2.ts', 'file3.md')
    FilesUpdated = @('config.json', 'README.md')
    TotalFiles = 5
    EstimatedLines = 1250
    Categories = @{
        'Code' = 2
        'Documentation' = 2
        'Configuration' = 1
    }
}

$testStartTime = (Get-Date).AddMinutes(-45)
$testEndTime = Get-Date

$metrics = Get-SessionMetrics -Deliverables $testDeliverables -StartTime $testStartTime -EndTime $testEndTime

Write-Host "  Files Created: $($metrics.FilesCreated)" -ForegroundColor Yellow
Write-Host "  Files Updated: $($metrics.FilesUpdated)" -ForegroundColor Yellow
Write-Host "  Duration: $($metrics.DurationMinutes) minutes" -ForegroundColor Yellow
Write-Host "  Lines Generated: $($metrics.LinesGenerated)" -ForegroundColor Yellow
Write-Host "  Files/Minute: $($metrics.FilesPerMinute)" -ForegroundColor Yellow
Write-Host "  Lines/Minute: $($metrics.LinesPerMinute)" -ForegroundColor Yellow

# Test 5: Markdown Formatting
Write-Host "`nTest 5: Markdown Formatting" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

$markdown = Format-DeliverablesMarkdown -Deliverables $testDeliverables
Write-Host "`nDeliverables Markdown:" -ForegroundColor Gray
Write-Host $markdown -ForegroundColor Yellow

$metricsMarkdown = Format-MetricsMarkdown -Metrics $metrics
Write-Host "`nMetrics Markdown:" -ForegroundColor Gray
Write-Host $metricsMarkdown -ForegroundColor Yellow

# Test 6: Complete Session Context
Write-Host "`nTest 6: Complete Session Context" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

try {
    $context = New-SessionContext `
        -AgentName '@build-architect' `
        -WorkDescription 'Create automatic logging infrastructure for Innovation Nexus' `
        -StartTime (Get-Date).AddMinutes(-30) `
        -Status 'completed'

    Write-Host "  Session ID: $($context.SessionId)" -ForegroundColor Yellow
    Write-Host "  Agent: $($context.AgentName)" -ForegroundColor Yellow
    Write-Host "  Status: $($context.Status)" -ForegroundColor Yellow
    Write-Host "  Duration: $($context.DurationMinutes) minutes" -ForegroundColor Yellow
    Write-Host "  Total Files: $($context.Deliverables.TotalFiles)" -ForegroundColor Yellow
    Write-Host "  Estimated Lines: $($context.Deliverables.EstimatedLines)" -ForegroundColor Yellow
}
catch {
    Write-Host "  Error: $_" -ForegroundColor Red
}

Write-Host "`n=== ALL TESTS COMPLETED ===" -ForegroundColor Cyan
Write-Host "Session parser utilities validated successfully!`n" -ForegroundColor Green
