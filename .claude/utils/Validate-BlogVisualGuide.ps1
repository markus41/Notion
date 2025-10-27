# Blog Visual Enhancements Guide - Quality Validation
# Counts Mermaid diagrams and brand voice keywords

$content = Get-Content '.claude/docs/blog-visual-enhancements-guide.md' -Raw

$mermaid = ([regex]::Matches($content, '```mermaid')).Count
$bestFor = ([regex]::Matches($content, 'Best for')).Count
$establish = ([regex]::Matches($content, 'Establish', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
$streamline = ([regex]::Matches($content, 'Streamline', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
$sustainable = ([regex]::Matches($content, 'sustainable', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
$drive = ([regex]::Matches($content, 'drive measurable', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count

Write-Host ""
Write-Host "Blog Visual Enhancements Guide - Quality Validation" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Mermaid Diagrams: " -NoNewline -ForegroundColor White
Write-Host $mermaid -ForegroundColor Green
Write-Host "'Best for:' qualifiers: " -NoNewline -ForegroundColor White
Write-Host $bestFor -ForegroundColor Green
Write-Host ""
Write-Host "Brand Voice Keywords:" -ForegroundColor Yellow
Write-Host "  Establish: " -NoNewline -ForegroundColor Gray
Write-Host $establish -ForegroundColor White
Write-Host "  Streamline: " -NoNewline -ForegroundColor Gray
Write-Host $streamline -ForegroundColor White
Write-Host "  Sustainable: " -NoNewline -ForegroundColor Gray
Write-Host $sustainable -ForegroundColor White
Write-Host "  'Drive measurable': " -NoNewline -ForegroundColor Gray
Write-Host $drive -ForegroundColor White
Write-Host ""

if ($mermaid -ge 5 -and $bestFor -ge 1) {
    Write-Host "✅ All quality targets achieved!" -ForegroundColor Green
    Write-Host "   - Target: 5 diagrams, Actual: $mermaid" -ForegroundColor Gray
    Write-Host "   - Target: 1 'Best for:', Actual: $bestFor" -ForegroundColor Gray
} else {
    Write-Host "⚠️ Quality targets not met" -ForegroundColor Yellow
    Write-Host "   - Mermaid diagrams: $mermaid (target: 5+)" -ForegroundColor Gray
    Write-Host "   - 'Best for:' qualifiers: $bestFor (target: 1+)" -ForegroundColor Gray
}
