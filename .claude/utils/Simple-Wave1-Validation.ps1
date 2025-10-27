# Simplified Phase 1 Wave 1 Quality Validation
# Quick metrics for GitHub PR

$files = @("README.md", "CLAUDE.md", "QUICKSTART.md", "TROUBLESHOOTING.md", "GIT-STRUCTURE.md")

Write-Host ""
Write-Host "Phase 1 Wave 1 Quality Validation" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

$totalMermaid = 0
$totalBestFor = 0
$totalEstablish = 0
$totalStreamline = 0

foreach ($file in $files) {
    $content = Get-Content $file -Raw

    $mermaid = ([regex]::Matches($content, "mermaid")).Count
    $bestFor = ([regex]::Matches($content, "Best for")).Count
    $establish = ([regex]::Matches($content, "Establish")).Count
    $streamline = ([regex]::Matches($content, "Streamline")).Count

    Write-Host "$file :" -ForegroundColor White
    Write-Host "  Mermaid diagrams: $mermaid" -ForegroundColor Gray
    Write-Host "  Best for: $bestFor" -ForegroundColor Gray
    Write-Host "  Establish: $establish | Streamline: $streamline" -ForegroundColor Gray
    Write-Host ""

    $totalMermaid += $mermaid
    $totalBestFor += $bestFor
    $totalEstablish += $establish
    $totalStreamline += $streamline
}

Write-Host "Summary Metrics" -ForegroundColor Cyan
Write-Host "---------------" -ForegroundColor Cyan
Write-Host "Total Mermaid Diagrams: $totalMermaid" -ForegroundColor Green
Write-Host "Total Best for Qualifiers: $totalBestFor" -ForegroundColor Green
Write-Host "Total Establish Keywords: $totalEstablish" -ForegroundColor Green
Write-Host "Total Streamline Keywords: $totalStreamline" -ForegroundColor Green
Write-Host ""
Write-Host "Validation complete" -ForegroundColor Green
