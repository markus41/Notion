<#
.SYNOPSIS
    Style Metrics Calculator - Behavioral analysis for output styles testing

.DESCRIPTION
    Establish comprehensive behavioral metrics calculation for agent output analysis.
    Measures technical density, formality, clarity, visual elements, and effectiveness scores.
    Designed for organizations scaling agent communication optimization through empirical data.

.NOTES
    Author: Brookside BI Innovation Nexus
    Purpose: Quantitative assessment of agent communication patterns
    Best for: Data-driven style optimization with measurable effectiveness metrics
#>

# Common technical terms dictionary (for technical density calculation)
$script:TechnicalTerms = @(
    # Programming & Software
    "API", "REST", "GraphQL", "SDK", "CLI", "GUI", "HTTP", "HTTPS", "JSON", "XML", "YAML",
    "database", "query", "schema", "index", "transaction", "SQL", "NoSQL",
    "algorithm", "function", "method", "class", "interface", "module", "component",
    "async", "await", "callback", "promise", "thread", "process", "concurrency",
    "authentication", "authorization", "OAuth", "JWT", "token", "encryption",
    "deployment", "pipeline", "CI/CD", "container", "Docker", "Kubernetes", "orchestration",
    "repository", "commit", "branch", "merge", "pull request", "version control",

    # Cloud & Infrastructure
    "Azure", "AWS", "GCP", "cloud", "serverless", "microservices", "monolith",
    "load balancer", "CDN", "cache", "Redis", "VPC", "subnet", "firewall",
    "scalability", "redundancy", "failover", "high availability", "disaster recovery",

    # Data & Analytics
    "ETL", "data warehouse", "data lake", "OLAP", "OLTP", "BigQuery", "Snowflake",
    "machine learning", "AI", "model", "training", "inference", "neural network",
    "regression", "classification", "clustering", "optimization",

    # Business Intelligence
    "dashboard", "visualization", "KPI", "metric", "dimension", "measure",
    "Power BI", "Tableau", "report", "dataset", "data source", "filter", "slicer"
)

# Formal language indicators
$script:FormalIndicators = @(
    "therefore", "thus", "hence", "consequently", "moreover", "furthermore",
    "however", "nevertheless", "nonetheless", "notwithstanding", "whereas",
    "pursuant to", "in accordance with", "with respect to", "regarding",
    "aforementioned", "herein", "thereof", "whereby", "insofar as"
)

# Casual language indicators
$script:CasualIndicators = @(
    "gonna", "wanna", "gotta", "kinda", "sorta", "yeah", "yep", "nope",
    "cool", "awesome", "great", "nice", "hey", "hi", "thanks", "cheers",
    "btw", "fyi", "asap", "lol", "omg", "tbh", "imo", "imho"
)

<#
.SYNOPSIS
    Calculate technical density score

.DESCRIPTION
    Measures ratio of technical terms, code blocks, acronyms, and implementation details to total content.
    Returns value 0.0-1.0 where higher values indicate more technical content.

.PARAMETER Text
    Text content to analyze

.OUTPUTS
    Double value 0.0-1.0 representing technical density

.EXAMPLE
    $density = Get-TechnicalDensity -Text $agentOutput
    # Returns: 0.72 (highly technical)
#>
function Get-TechnicalDensity {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return 0.0
    }

    $totalWords = ($Text -split '\s+').Count
    if ($totalWords -eq 0) {
        return 0.0
    }

    # Count technical terms
    $technicalTermCount = 0
    foreach ($term in $script:TechnicalTerms) {
        $pattern = "\b$([regex]::Escape($term))\b"
        $matches = [regex]::Matches($Text, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        $technicalTermCount += $matches.Count
    }

    # Count code blocks (both fenced and inline)
    $codeBlockMatches = [regex]::Matches($Text, '```[\s\S]*?```')
    $inlineCodeMatches = [regex]::Matches($Text, '`[^`]+`')
    $codeBlockCount = $codeBlockMatches.Count + ($inlineCodeMatches.Count * 0.5)  # Inline code weighted less

    # Count acronyms (2-5 uppercase letters)
    $acronymMatches = [regex]::Matches($Text, '\b[A-Z]{2,5}\b')
    $acronymCount = $acronymMatches.Count

    # Count file paths and URLs
    $pathMatches = [regex]::Matches($Text, '[\w/\\]+\.\w+|https?://\S+')
    $pathCount = $pathMatches.Count

    # Calculate technical content score
    $technicalScore = ($technicalTermCount + ($codeBlockCount * 10) + ($acronymCount * 2) + $pathCount) / $totalWords

    # Normalize to 0-1 range (cap at 1.0)
    return [Math]::Min(1.0, $technicalScore)
}

<#
.SYNOPSIS
    Calculate formality score

.DESCRIPTION
    Detects formal language patterns vs casual/conversational tone.
    Returns value 0.0-1.0 where higher values indicate more formal language.

.PARAMETER Text
    Text content to analyze

.OUTPUTS
    Double value 0.0-1.0 representing formality

.EXAMPLE
    $formality = Get-FormalityScore -Text $agentOutput
    # Returns: 0.65 (formal business communication)
#>
function Get-FormalityScore {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return 0.5  # Neutral default
    }

    $totalWords = ($Text -split '\s+').Count
    if ($totalWords -eq 0) {
        return 0.5
    }

    # Count formal indicators
    $formalCount = 0
    foreach ($indicator in $script:FormalIndicators) {
        $pattern = "\b$([regex]::Escape($indicator))\b"
        $matches = [regex]::Matches($Text, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        $formalCount += $matches.Count
    }

    # Count casual indicators
    $casualCount = 0
    foreach ($indicator in $script:CasualIndicators) {
        $pattern = "\b$([regex]::Escape($indicator))\b"
        $matches = [regex]::Matches($Text, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        $casualCount += $matches.Count
    }

    # Count contractions (casual indicator)
    $contractionMatches = [regex]::Matches($Text, "\b\w+'\w+\b")
    $casualCount += $contractionMatches.Count

    # Count exclamation marks (casual indicator)
    $exclamationCount = ([regex]::Matches($Text, '!')).Count
    $casualCount += ($exclamationCount * 0.5)

    # Count passive voice constructions (formal indicator)
    $passiveMatches = [regex]::Matches($Text, '\b(is|are|was|were|been|being)\s+\w+ed\b')
    $formalCount += ($passiveMatches.Count * 0.5)

    # Calculate formality ratio
    $totalIndicators = $formalCount + $casualCount
    if ($totalIndicators -eq 0) {
        return 0.5  # Neutral if no indicators
    }

    return [Math]::Min(1.0, $formalCount / $totalIndicators)
}

<#
.SYNOPSIS
    Calculate clarity score

.DESCRIPTION
    Approximates Flesch Reading Ease adjusted for AI-generated content.
    Returns value 0.0-1.0 where higher values indicate clearer, more accessible language.

.PARAMETER Text
    Text content to analyze

.OUTPUTS
    Double value 0.0-1.0 representing clarity

.EXAMPLE
    $clarity = Get-ClarityScore -Text $agentOutput
    # Returns: 0.78 (clear, accessible to general audience)
#>
function Get-ClarityScore {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return 0.5
    }

    # Remove code blocks for readability analysis (they skew metrics)
    $textWithoutCode = $Text -replace '```[\s\S]*?```', ''
    $textWithoutCode = $textWithoutCode -replace '`[^`]+`', ''

    # Count sentences (approximate)
    $sentences = ([regex]::Matches($textWithoutCode, '[.!?]+\s+')).Count + 1

    # Count words
    $words = ($textWithoutCode -split '\s+').Count

    # Count syllables (simplified: vowel groups)
    $syllables = 0
    $textWithoutCode -split '\s+' | ForEach-Object {
        $vowelGroups = ([regex]::Matches($_, '[aeiouy]+', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
        $syllables += [Math]::Max(1, $vowelGroups)
    }

    if ($words -eq 0 -or $sentences -eq 0) {
        return 0.5
    }

    # Flesch Reading Ease approximation
    # Score = 206.835 - 1.015 * (words/sentences) - 84.6 * (syllables/words)
    $avgWordsPerSentence = $words / $sentences
    $avgSyllablesPerWord = $syllables / $words

    $fleschScore = 206.835 - (1.015 * $avgWordsPerSentence) - (84.6 * $avgSyllablesPerWord)

    # Normalize to 0-1 range (Flesch scale is typically 0-100, but can be negative)
    # Higher Flesch = easier to read = higher clarity
    $normalizedScore = ($fleschScore + 50) / 150  # Shift and scale

    return [Math]::Max(0.0, [Math]::Min(1.0, $normalizedScore))
}

<#
.SYNOPSIS
    Count visual elements

.DESCRIPTION
    Counts diagrams, tables, callouts, lists, icons, and other visual structure elements.

.PARAMETER Text
    Text content to analyze

.OUTPUTS
    Integer count of visual elements

.EXAMPLE
    $visuals = Get-VisualElementsCount -Text $agentOutput
    # Returns: 12 (tables, lists, callouts)
#>
function Get-VisualElementsCount {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return 0
    }

    $count = 0

    # Mermaid diagrams
    $mermaidMatches = [regex]::Matches($Text, '```mermaid[\s\S]*?```')
    $count += $mermaidMatches.Count * 3  # Weight diagrams heavily

    # HTML tables
    $tableMatches = [regex]::Matches($Text, '<table[\s\S]*?</table>')
    $count += $tableMatches.Count * 2

    # Markdown tables
    $mdTableMatches = [regex]::Matches($Text, '\|[^\n]+\|[^\n]+\n\|[-:\s|]+\|')
    $count += $mdTableMatches.Count * 2

    # Callouts (blockquotes with emoji or special formatting)
    $calloutMatches = [regex]::Matches($Text, '>\s*[🔔📌💡⚠️✅❌🚀📊💼🎯]')
    $count += $calloutMatches.Count

    # Bulleted lists (significant items only, not single bullets)
    $bulletListMatches = [regex]::Matches($Text, '^\s*[-*]\s+.+\n^\s*[-*]\s+', [System.Text.RegularExpressions.RegexOptions]::Multiline)
    $count += $bulletListMatches.Count

    # Numbered lists
    $numberedListMatches = [regex]::Matches($Text, '^\s*\d+\.\s+.+\n^\s*\d+\.\s+', [System.Text.RegularExpressions.RegexOptions]::Multiline)
    $count += $numberedListMatches.Count

    # Horizontal rules (section dividers)
    $hrMatches = [regex]::Matches($Text, '^[-*_]{3,}$', [System.Text.RegularExpressions.RegexOptions]::Multiline)
    $count += $hrMatches.Count

    # Emojis (visual indicators)
    $emojiMatches = [regex]::Matches($Text, '[\u{1F300}-\u{1F9FF}]')
    $count += [Math]::Min(10, $emojiMatches.Count)  # Cap emoji count at 10

    # Images and diagrams (markdown and HTML)
    $imageMatches = [regex]::Matches($Text, '!\[.*?\]\(.*?\)|<img\s+.*?>')
    $count += $imageMatches.Count * 2

    return $count
}

<#
.SYNOPSIS
    Count code blocks

.DESCRIPTION
    Counts both fenced code blocks and inline code snippets.

.PARAMETER Text
    Text content to analyze

.OUTPUTS
    Integer count of code blocks

.EXAMPLE
    $codeBlocks = Get-CodeBlocksCount -Text $agentOutput
    # Returns: 8 (5 fenced blocks + 3 inline code snippets)
#>
function Get-CodeBlocksCount {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return 0
    }

    # Fenced code blocks (``` ... ```)
    $fencedMatches = [regex]::Matches($Text, '```[\s\S]*?```')
    $fencedCount = $fencedMatches.Count

    # Inline code (`...`)
    $inlineMatches = [regex]::Matches($Text, '`[^`]+`')
    $inlineCount = $inlineMatches.Count

    # Weight: 1 fenced block = 1, 3 inline = 1
    return $fencedCount + [Math]::Floor($inlineCount / 3)
}

<#
.SYNOPSIS
    Calculate overall effectiveness score

.DESCRIPTION
    Weighted average of goal achievement, audience appropriateness, style consistency, and clarity.
    Formula: (35% goal) + (30% audience) + (20% consistency) + (15% clarity)

.PARAMETER Metrics
    Hashtable containing individual metrics (GoalAchievement, AudienceAppropriateness, StyleConsistency, Clarity)

.OUTPUTS
    Integer value 0-100 representing overall effectiveness

.EXAMPLE
    $metrics = @{
        GoalAchievement = 0.9
        AudienceAppropriateness = 0.85
        StyleConsistency = 0.88
        Clarity = 0.75
    }
    $overall = Get-OverallEffectiveness -Metrics $metrics
    # Returns: 85
#>
function Get-OverallEffectiveness {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Metrics
    )

    $goal = if ($Metrics.ContainsKey('GoalAchievement')) { $Metrics.GoalAchievement } else { 0.5 }
    $audience = if ($Metrics.ContainsKey('AudienceAppropriateness')) { $Metrics.AudienceAppropriateness } else { 0.5 }
    $consistency = if ($Metrics.ContainsKey('StyleConsistency')) { $Metrics.StyleConsistency } else { 0.5 }
    $clarity = if ($Metrics.ContainsKey('ClarityScore')) { $Metrics.ClarityScore } else { 0.5 }

    # Weighted average: 35% + 30% + 20% + 15% = 100%
    $weightedScore = (0.35 * $goal) + (0.30 * $audience) + (0.20 * $consistency) + (0.15 * $clarity)

    return [Math]::Round($weightedScore * 100)
}

<#
.SYNOPSIS
    Calculate comprehensive behavioral metrics

.DESCRIPTION
    Analyzes text and returns full metrics profile including all behavioral and effectiveness measures.

.PARAMETER Text
    Text content to analyze

.PARAMETER AdditionalMetrics
    Optional hashtable with manually assessed metrics (GoalAchievement, AudienceAppropriateness, StyleConsistency, UserSatisfaction)

.OUTPUTS
    Hashtable with complete metrics profile

.EXAMPLE
    $metrics = Get-ComprehensiveMetrics -Text $agentOutput -AdditionalMetrics @{
        GoalAchievement = 0.9
        AudienceAppropriateness = 0.85
        StyleConsistency = 0.88
        UserSatisfaction = 5
    }
#>
function Get-ComprehensiveMetrics {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $false)]
        [hashtable]$AdditionalMetrics = @{}
    )

    # Calculate automated metrics
    $metrics = @{
        # Behavioral metrics (automated)
        TechnicalDensity = Get-TechnicalDensity -Text $Text
        FormalityScore = Get-FormalityScore -Text $Text
        ClarityScore = Get-ClarityScore -Text $Text
        VisualElementsCount = Get-VisualElementsCount -Text $Text
        CodeBlocksCount = Get-CodeBlocksCount -Text $Text
        OutputLength = $Text.Length

        # Timestamp
        CalculatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    # Add manual metrics if provided
    if ($AdditionalMetrics.GoalAchievement) {
        $metrics.GoalAchievement = $AdditionalMetrics.GoalAchievement
    }

    if ($AdditionalMetrics.AudienceAppropriateness) {
        $metrics.AudienceAppropriateness = $AdditionalMetrics.AudienceAppropriateness
    }

    if ($AdditionalMetrics.StyleConsistency) {
        $metrics.StyleConsistency = $AdditionalMetrics.StyleConsistency
    }

    if ($AdditionalMetrics.UserSatisfaction) {
        $metrics.UserSatisfaction = $AdditionalMetrics.UserSatisfaction
    }

    if ($AdditionalMetrics.GenerationTimeMs) {
        $metrics.GenerationTimeMs = $AdditionalMetrics.GenerationTimeMs
    }

    # Calculate overall effectiveness if we have the required metrics
    if ($metrics.ContainsKey('GoalAchievement') -and
        $metrics.ContainsKey('AudienceAppropriateness') -and
        $metrics.ContainsKey('StyleConsistency')) {

        $metrics.OverallEffectiveness = Get-OverallEffectiveness -Metrics $metrics
    }

    return $metrics
}

# Export functions
Export-ModuleMember -Function @(
    'Get-TechnicalDensity',
    'Get-FormalityScore',
    'Get-ClarityScore',
    'Get-VisualElementsCount',
    'Get-CodeBlocksCount',
    'Get-OverallEffectiveness',
    'Get-ComprehensiveMetrics'
)
