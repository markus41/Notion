# Phase 1 Wave 1 Quality Validation Script
# Validates documentation quality metrics for GitHub PR

$wave1Files = @(
    "README.md",
    "CLAUDE.md",
    "QUICKSTART.md",
    "TROUBLESHOOTING.md",
    "GIT-STRUCTURE.md"
)

$results = @()

foreach ($file in $wave1Files) {
    $content = Get-Content $file -Raw

    # Count code blocks
    $codeBlockMatches = [regex]::Matches($content, '```\w*')
    $codeBlockCount = $codeBlockMatches.Count

    # Check code blocks have language tags
    $untaggedBlocks = [regex]::Matches($content, '```\s*\n')
    $untaggedCount = $untaggedBlocks.Count

    # Count Mermaid diagrams
    $mermaidCount = ([regex]::Matches($content, '```mermaid')).Count

    # Count "Best for:" qualifiers
    $bestForCount = ([regex]::Matches($content, 'Best for:', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count

    # Count brand voice keywords
    $establishCount = ([regex]::Matches($content, 'Establish\w*', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
    $streamlineCount = ([regex]::Matches($content, 'Streamline\w*', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
    $measurableCount = ([regex]::Matches($content, 'measurable outcome', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
    $sustainableCount = ([regex]::Matches($content, 'sustainable\w*', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count

    # Count internal links
    $internalLinkMatches = [regex]::Matches($content, '\[.*?\]\((\.claude/|scripts/|docs/|\.\/|\.\./)[^\)]+\)')
    $internalLinkCount = $internalLinkMatches.Count

    # Count external links
    $externalLinkMatches = [regex]::Matches($content, '\[.*?\]\((https?://[^\)]+)\)')
    $externalLinkCount = $externalLinkMatches.Count

    # Count images
    $imageMatches = [regex]::Matches($content, '!\[.*?\]\([^\)]+\)')
    $imageCount = $imageMatches.Count

    # Calculate brand compliance score (simple keyword density)
    $totalWords = ($content -split '\s+').Count
    $brandKeywords = $establishCount + $streamlineCount + $measurableCount + $sustainableCount
    $brandDensity = [math]::Round(($brandKeywords / $totalWords) * 1000, 2) # per 1000 words

    $results += [PSCustomObject]@{
        File = $file
        CodeBlocks = $codeBlockCount
        UntaggedBlocks = $untaggedCount
        MermaidDiagrams = $mermaidCount
        BestForQualifiers = $bestForCount
        InternalLinks = $internalLinkCount
        ExternalLinks = $externalLinkCount
        Images = $imageCount
        BrandKeywordDensity = $brandDensity
        EstablishCount = $establishCount
        StreamlineCount = $streamlineCount
        MeasurableOutcomes = $measurableCount
        SustainableCount = $sustainableCount
    }
}

Write-Host ""
Write-Host "=== Phase 1 Wave 1 Quality Validation ===" -ForegroundColor Cyan
Write-Host "Files Analyzed: $($wave1Files.Count)" -ForegroundColor White
Write-Host ""

$results | Format-Table -AutoSize

# Summary metrics
$totalMermaid = ($results | Measure-Object -Property MermaidDiagrams -Sum).Sum
$totalBestFor = ($results | Measure-Object -Property BestForQualifiers -Sum).Sum
$totalUntagged = ($results | Measure-Object -Property UntaggedBlocks -Sum).Sum
$avgBrandDensity = [math]::Round(($results | Measure-Object -Property BrandKeywordDensity -Average).Average, 2)

Write-Host ""
Write-Host "=== Summary Metrics ===" -ForegroundColor Cyan
Write-Host "Total Mermaid Diagrams: $totalMermaid" -ForegroundColor Green
Write-Host "Total 'Best for:' Qualifiers: $totalBestFor" -ForegroundColor Green
Write-Host "Untagged Code Blocks: $totalUntagged" -ForegroundColor $(if ($totalUntagged -eq 0) { "Green" } else { "Yellow" })
Write-Host "Avg Brand Keyword Density: $avgBrandDensity per 1000 words" -ForegroundColor Green

# Quality assessment
Write-Host ""
Write-Host "=== Quality Assessment ===" -ForegroundColor Cyan
$filesWithBestFor = ($results | Where-Object { $_.BestForQualifiers -gt 0 }).Count
$filesWithMermaid = ($results | Where-Object { $_.MermaidDiagrams -gt 0 }).Count

Write-Host "Files with 'Best for:' qualifier: $filesWithBestFor / $($wave1Files.Count) ($(($filesWithBestFor/$wave1Files.Count*100).ToString('0'))%)" -ForegroundColor Green
Write-Host "Files with Mermaid diagrams: $filesWithMermaid / $($wave1Files.Count) ($(($filesWithMermaid/$wave1Files.Count*100).ToString('0'))%)" -ForegroundColor Green

if ($totalUntagged -eq 0) {
    Write-Host "Code block language tags: 100% ✓" -ForegroundColor Green
} else {
    Write-Host "Code block language tags: $([math]::Round((1 - ($totalUntagged/($results | Measure-Object -Property CodeBlocks -Sum).Sum)) * 100, 1))%" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Validation complete. Ready for GitHub PR creation." -ForegroundColor Cyan
