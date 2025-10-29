<#
.SYNOPSIS
    Compress large log files to optimize repository performance

.DESCRIPTION
    Establish automated log compression to maintain lean .claude/logs directory and drive
    measurable performance improvements through systematic artifact management.

    Identifies logs >100KB, compresses to dated ZIP files, removes originals. Designed for
    organizations scaling innovation workflows across teams with extensive agent activity.

.PARAMETER MinSizeKB
    Minimum file size in KB to trigger compression (default: 100)

.PARAMETER WhatIf
    Preview which files would be compressed without executing

.EXAMPLE
    .\Compress-Logs.ps1
    Compresses all log files larger than 100KB

.EXAMPLE
    .\Compress-Logs.ps1 -MinSizeKB 50
    Compresses all log files larger than 50KB

.EXAMPLE
    .\Compress-Logs.ps1 -WhatIf
    Preview compression without making changes

.NOTES
    Best for: Monthly maintenance to keep .claude/logs lean and optimize repository performance
    Author: Brookside BI Innovation Nexus
    Last Modified: 2025-10-28
#>

param(
    [int]$MinSizeKB = 100,
    [switch]$WhatIf
)

Write-Host "🗜️  Log Compression Utility" -ForegroundColor Cyan
Write-Host "Minimum size: $MinSizeKB KB" -ForegroundColor Gray
Write-Host ""

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logsPath = Join-Path (Split-Path -Parent $scriptDir) ".claude\logs"

if (-not (Test-Path $logsPath)) {
    Write-Host "❌ Logs directory not found: $logsPath" -ForegroundColor Red
    exit 1
}

$compressed = 0
$totalSaved = 0
$date = Get-Date -Format 'yyyyMMdd'

Get-ChildItem $logsPath -Filter "*.log" |
    Where-Object { $_.Length -gt ($MinSizeKB * 1KB) } |
    ForEach-Object {
        $sizeKB = [math]::Round($_.Length / 1KB, 2)
        $zipName = "$($_.BaseName)-$date.zip"
        $zipPath = Join-Path $logsPath $zipName

        if ($WhatIf) {
            Write-Host "  Would compress: $($_.Name) ($sizeKB KB)" -ForegroundColor Yellow
        } else {
            try {
                Compress-Archive -Path $_.FullName -DestinationPath $zipPath -CompressionLevel Optimal -ErrorAction Stop
                $zipSize = [math]::Round((Get-Item $zipPath).Length / 1KB, 2)
                $saved = $sizeKB - $zipSize

                Remove-Item $_.FullName -Force
                Write-Host "  ✓ Compressed: $($_.Name) ($sizeKB KB → $zipSize KB, saved $([math]::Round($saved, 2)) KB)" -ForegroundColor Green

                $compressed++
                $totalSaved += $saved
            } catch {
                Write-Host "  ❌ Failed to compress $($_.Name): $_" -ForegroundColor Red
            }
        }
    }

Write-Host ""
if ($WhatIf) {
    Write-Host "ℹ️  Run without -WhatIf to compress files" -ForegroundColor Cyan
} else {
    if ($compressed -eq 0) {
        Write-Host "ℹ️  No log files found larger than $MinSizeKB KB" -ForegroundColor Gray
    } else {
        Write-Host "✅ Compressed $compressed log files" -ForegroundColor Green
        Write-Host "💾 Total space saved: $([math]::Round($totalSaved, 2)) KB" -ForegroundColor Green
    }
}
