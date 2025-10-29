<#
.SYNOPSIS
    One-click repository optimization for maximum performance

.DESCRIPTION
    Establish comprehensive repository optimization to drive measurable performance improvements
    across all Innovation Nexus operations. Streamlines git operations, log management, and
    artifact cleanup in a single automated workflow.

    Designed for organizations scaling innovation workflows with 50+ agents, 70+ commands, and
    extensive automation requiring lean, high-performance repositories.

.PARAMETER Aggressive
    Enable aggressive git garbage collection (slower but maximum compression)

.PARAMETER SkipGC
    Skip git garbage collection (useful if recently run)

.PARAMETER SkipLogs
    Skip log compression (useful if logs recently compressed)

.EXAMPLE
    .\Optimize-Repository.ps1
    Standard optimization: git gc, log compression, artifact cleanup

.EXAMPLE
    .\Optimize-Repository.ps1 -Aggressive
    Maximum compression with aggressive git garbage collection

.EXAMPLE
    .\Optimize-Repository.ps1 -SkipGC
    Optimize logs and artifacts without git operations

.NOTES
    Best for: Monthly maintenance or after major cleanups
    Expected runtime: 2-5 minutes (10-15 minutes with -Aggressive)
    Author: Brookside BI Innovation Nexus
    Last Modified: 2025-10-28
#>

param(
    [switch]$Aggressive,
    [switch]$SkipGC,
    [switch]$SkipLogs
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Repository Optimization Starting..." -ForegroundColor Cyan
Write-Host "Configuration: $(if ($Aggressive) { 'Aggressive GC' } else { 'Standard' })" -ForegroundColor Gray
Write-Host ""

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

# Navigate to repository root
Push-Location $repoRoot

try {
    # 1. Git optimization
    if (-not $SkipGC) {
        Write-Host "1. Optimizing Git repository..." -ForegroundColor Yellow
        Write-Host "   Expiring reflog..." -ForegroundColor Gray
        git reflog expire --expire=now --all 2>&1 | Out-Null

        if ($Aggressive) {
            Write-Host "   Running aggressive garbage collection (this may take 10-15 minutes)..." -ForegroundColor Gray
            git gc --aggressive --prune=now 2>&1 | Out-Null
        } else {
            Write-Host "   Running standard garbage collection..." -ForegroundColor Gray
            git gc --prune=now 2>&1 | Out-Null
        }
        Write-Host "   ✓ Git optimized" -ForegroundColor Green
    } else {
        Write-Host "1. Skipping Git optimization (--SkipGC specified)" -ForegroundColor Gray
    }

    # 2. Compress logs
    if (-not $SkipLogs) {
        Write-Host "`n2. Compressing large logs..." -ForegroundColor Yellow
        & "$scriptDir\Compress-Logs.ps1" 2>&1 | Where-Object { $_ -match '✓|ℹ️|No log' } | ForEach-Object {
            Write-Host "   $_"
        }
        Write-Host "   ✓ Logs processed" -ForegroundColor Green
    } else {
        Write-Host "`n2. Skipping log compression (--SkipLogs specified)" -ForegroundColor Gray
    }

    # 3. Archive old migration artifacts (if any remain and migration complete)
    Write-Host "`n3. Checking migration artifacts..." -ForegroundColor Yellow
    if (Test-Path ".claude/data/MIGRATION_COMPLETE.md") {
        $migrationFiles = Get-ChildItem ".claude/data" -Filter "migration-*" -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -eq ".json" -or $_.Name -like "migration-batches" }

        if ($migrationFiles) {
            $date = Get-Date -Format 'yyyyMMdd'
            $archivePath = ".claude/data/migration-archive-$date.zip"
            Compress-Archive -Path $migrationFiles.FullName -DestinationPath $archivePath -CompressionLevel Optimal
            $migrationFiles | Remove-Item -Recurse -Force
            Write-Host "   ✓ Migration artifacts archived" -ForegroundColor Green
        } else {
            Write-Host "   ✓ No migration artifacts to clean" -ForegroundColor Green
        }
    } else {
        Write-Host "   ⏭️  Migration not complete, skipping cleanup" -ForegroundColor Gray
    }

    # 4. Report final size
    Write-Host "`n4. Calculating repository metrics..." -ForegroundColor Yellow

    $repoFiles = Get-ChildItem . -Recurse -File | Measure-Object -Property Length -Sum
    $repoSize = $repoFiles.Sum / 1MB
    $fileCount = $repoFiles.Count

    $gitFiles = Get-ChildItem .git -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum
    $gitSize = $gitFiles.Sum / 1MB

    $workingSize = $repoSize - $gitSize

    Write-Host ""
    Write-Host "📊 Optimization Complete!" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "   Total Size:     $([math]::Round($repoSize, 2)) MB" -ForegroundColor White
    Write-Host "   Git History:    $([math]::Round($gitSize, 2)) MB" -ForegroundColor White
    Write-Host "   Working Files:  $([math]::Round($workingSize, 2)) MB" -ForegroundColor White
    Write-Host "   File Count:     $fileCount files" -ForegroundColor White
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

    # Performance recommendations
    Write-Host "`n💡 Recommendations:" -ForegroundColor Cyan
    if ($workingSize -gt 50) {
        Write-Host "   • Working files >50MB - consider additional cleanup" -ForegroundColor Yellow
    }
    if ($gitSize -gt 500) {
        Write-Host "   • Git history >500MB - consider using --Aggressive monthly" -ForegroundColor Yellow
    }
    if (-not $Aggressive -and $gitSize -gt 200) {
        Write-Host "   • Run with -Aggressive flag for maximum compression" -ForegroundColor Yellow
    }

    Write-Host "`n✅ Repository optimized for large-scale operations" -ForegroundColor Green

} catch {
    Write-Host "`n❌ Optimization failed: $_" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}
