# Parse Agent Metadata Script
# Establishes comprehensive metadata extraction from agent definition files
# to streamline Agent Registry population with accurate tool assignments and capabilities

param(
    [string]$AgentDirectory = ".claude/agents",
    [string]$OutputFile = ".claude/data/agent-metadata.json"
)

Write-Host "🔍 Parsing Agent Metadata from $AgentDirectory..." -ForegroundColor Cyan

$agents = @()
$agentFiles = Get-ChildItem -Path $AgentDirectory -Filter "*.md" | Sort-Object Name

foreach ($file in $agentFiles) {
    Write-Host "  Processing: $($file.BaseName)..." -ForegroundColor Gray

    $content = Get-Content $file.FullName -Raw

    # Extract YAML frontmatter
    if ($content -match '(?s)^---\r?\n(.*?)\r?\n---\r?\n(.*)$') {
        $frontmatter = $matches[1]
        $body = $matches[2]

        # Parse name from frontmatter
        $name = if ($frontmatter -match 'name:\s*(.+)') { $matches[1].Trim() } else { $file.BaseName }

        # Parse description
        $description = if ($frontmatter -match 'description:\s*(.+?)(?=\n\w+:|$)') {
            $matches[1].Trim() -replace '\s+', ' '
        } else { "" }

        # Parse model
        $model = if ($frontmatter -match 'model:\s*(.+)') { $matches[1].Trim() } else { "sonnet" }

        # Extract first 200 words for System Prompt
        $bodyWords = ($body -replace '<[^>]+>', '' -split '\s+' | Where-Object { $_.Length -gt 0 })
        $systemPrompt = ($bodyWords | Select-Object -First 200) -join ' '
        if ($systemPrompt.Length -gt 500) {
            $systemPrompt = $systemPrompt.Substring(0, 497) + "..."
        }

        # Detect tools from description and content
        $tools = @()
        $toolKeywords = @{
            'Notion MCP' = @('notion', 'database', 'page', 'Ideas Registry', 'Research Hub', 'Example Builds', 'Software Tracker', 'Knowledge Vault')
            'GitHub MCP' = @('github', 'repository', 'repo', 'commit', 'pull request', 'branch')
            'Azure MCP' = @('azure', 'App Service', 'Function', 'SQL', 'deployment', 'infrastructure', 'Bicep')
            'Playwright' = @('playwright', 'browser', 'web', 'automation', 'testing')
            'Bash' = @('bash', 'shell', 'command', 'script', 'execute')
            'Read' = @('read file', 'analyze', 'parse', 'examine')
            'Write' = @('write file', 'create file', 'generate file')
            'Edit' = @('edit file', 'modify', 'update file')
            'Grep' = @('search', 'find', 'grep', 'pattern')
            'Glob' = @('glob', 'file pattern', 'match files')
            'WebFetch' = @('web', 'fetch', 'http', 'URL', 'documentation', 'research online')
        }

        $combinedText = "$description $body".ToLower()
        foreach ($tool in $toolKeywords.Keys) {
            foreach ($keyword in $toolKeywords[$tool]) {
                if ($combinedText -match [regex]::Escape($keyword.ToLower())) {
                    if ($tools -notcontains $tool) {
                        $tools += $tool
                    }
                    break
                }
            }
        }

        # Determine Agent Type
        $agentType = "Specialized"  # Default
        if ($name -match 'orchestrator|coordinator|router') { $agentType = "Orchestrator" }
        if ($name -match 'style|meta') { $agentType = "Meta-Agent" }
        if ($name -match 'expert|specialist' -and $description -notmatch 'specialized') { $agentType = "Utility" }

        # Determine Primary Specialization
        $specialization = "Engineering"  # Default
        if ($name -match 'cost|budget|financial') { $specialization = "Business" }
        if ($name -match 'research|market|viability') { $specialization = "Research" }
        if ($name -match 'architecture|architect|design') { $specialization = "Architecture" }
        if ($name -match 'deploy|infra|ops|monitor') { $specialization = "DevOps" }
        if ($name -match 'security|compliance|risk') { $specialization = "Security" }
        if ($name -match 'data|database|schema') { $specialization = "Data" }
        if ($name -match 'ai|ml|openai') { $specialization = "AI/ML" }

        # Determine Capabilities
        $capabilities = @()
        if ($combinedText -match 'code|generate|develop|build') { $capabilities += "Code Generation" }
        if ($combinedText -match 'architect|design|system|pattern') { $capabilities += "System Design" }
        if ($combinedText -match 'document|markdown|write|content') { $capabilities += "Documentation" }
        if ($combinedText -match 'test|validate|verify|quality') { $capabilities += "Testing" }
        if ($combinedText -match 'troubleshoot|debug|diagnose|fix') { $capabilities += "Troubleshooting" }
        if ($combinedText -match 'analy|assess|evaluat|review') { $capabilities += "Analysis" }
        if ($combinedText -match 'plan|strategy|organize|coordinate') { $capabilities += "Planning" }
        if ($combinedText -match 'orchestrat|coordinate|route|workflow') { $capabilities += "Orchestration" }
        if ($combinedText -match 'style|format|transform') { $capabilities += "Style Transformation" }

        # Determine Best Use Cases
        $bestUseCases = @()
        if ($specialization -in @("Engineering", "AI/ML", "DevOps")) { $bestUseCases += "Code Development" }
        if ($specialization -in @("Architecture", "DevOps")) { $bestUseCases += "System Architecture" }
        if ("Documentation" -in $capabilities) { $bestUseCases += "Documentation" }
        if ($specialization -eq "Research") { $bestUseCases += "Research" }
        if ($name -match 'compliance|audit|security') { $bestUseCases += "Compliance" }
        if ($name -match 'troubleshoot|fix|debug') { $bestUseCases += "Troubleshooting" }
        if ($name -match 'plan|architect|strategy') { $bestUseCases += "Planning" }

        # Determine Status based on activity
        $status = "🟢 Active"  # Default to active for all agents

        # Determine Invocation Pattern
        $invocationPattern = "On-Demand"  # Default
        if ($description -match 'proactive|automatic|autonomous|monitor') { $invocationPattern = "Proactive" }
        if ($description -match 'multi-agent|workflow|swarm|parallel') { $invocationPattern = "Multi-Agent Workflow" }

        $agentMetadata = @{
            'Name' = "@$name"
            'AgentID' = $name
            'FilePath' = $file.FullName
            'Description' = $description
            'Model' = $model
            'SystemPrompt' = $systemPrompt
            'Tools' = $tools
            'AgentType' = $agentType
            'PrimarySpecialization' = $specialization
            'Capabilities' = $capabilities
            'BestUseCases' = $bestUseCases
            'Status' = $status
            'InvocationPattern' = $invocationPattern
        }

        $agents += $agentMetadata
    }
}

# Export to JSON
$agents | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host "`n✅ Parsed $($agents.Count) agents successfully!" -ForegroundColor Green
Write-Host "📄 Output saved to: $OutputFile" -ForegroundColor Cyan

# Display summary
Write-Host "`n📊 Summary by Specialization:" -ForegroundColor Yellow
$agents | Group-Object -Property PrimarySpecialization | Sort-Object Count -Descending | ForEach-Object {
    Write-Host "  $($_.Name): $($_.Count) agents" -ForegroundColor Gray
}

Write-Host "`n🔧 Summary by Tools:" -ForegroundColor Yellow
$allTools = $agents | ForEach-Object { $_.Tools } | Group-Object | Sort-Object Count -Descending
$allTools | ForEach-Object {
    Write-Host "  $($_.Name): $($_.Count) agents" -ForegroundColor Gray
}
