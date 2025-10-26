---
description: Test agent+style combinations with comprehensive behavioral and effectiveness metrics. Supports UltraThink mode for deep analysis with tier classification. Compare all styles for an agent or run targeted tests with custom tasks.
allowed-tools: Task(@style-orchestrator:*), mcp__notion__*
argument-hint: <agent-name> <style-name|?> [--task="description"] [--interactive] [--ultrathink]
model: claude-sonnet-4-5-20250929
---

## Context

Establish data-driven output style optimization by systematically testing agent+style combinations with quantitative behavioral metrics, qualitative effectiveness assessments, and deep analysis scoring. This solution streamlines style selection decisions from subjective guesswork (30-45 minute deliberation) to objective evidence-based recommendations (<30 second retrieval).

**Best for**: Organizations requiring systematic communication optimization with empirical validation, performance tracking, and continuous improvement based on measurable effectiveness data.

---

## Command Syntax

```bash
/test-agent-style <agent-name> <style-name> [options]

# Arguments:
<agent-name>    - Agent to test (e.g., @cost-analyst, @build-architect)
<style-name>    - Style to apply, or "?" to compare all styles
                  Options: technical-implementer, strategic-advisor,
                          visual-architect, interactive-teacher, compliance-auditor

# Options:
--task="[description]"  - Custom task to test (default: agent-appropriate task)
--interactive           - Interactive mode with user feedback collection
--ultrathink            - Enable deep analysis mode (extended reasoning, tier classification)
--sync                  - Sync results to Notion Agent Style Tests database immediately
--report                - Generate detailed analysis report after test
```

---

## Usage Examples

### Basic Test (Single Combination)
```bash
/test-agent-style @cost-analyst strategic-advisor
```
**Output**: Executes cost analysis task with strategic-advisor style, reports metrics

---

### Custom Task
```bash
/test-agent-style @markdown-expert technical-implementer --task="Document API authentication endpoints"
```
**Output**: Tests markdown-expert agent creating API docs with technical-implementer style

---

### Compare All Styles
```bash
/test-agent-style @viability-assessor ?
```
**Output**: Runs same task with all 5 styles, generates comparative analysis

---

### UltraThink Mode (Deep Analysis)
```bash
/test-agent-style @build-architect visual-architect --task="Design microservices architecture" --ultrathink
```
**Output**: Extended reasoning analysis with tier classification (Gold/Silver/Bronze)

---

### Interactive Mode
```bash
/test-agent-style @knowledge-curator interactive-teacher --interactive
```
**Output**: Presents test output, collects user satisfaction rating, asks follow-up questions

---

### Full Testing Suite
```bash
/test-agent-style @compliance-orchestrator ? --ultrathink --sync --report
```
**Output**: Comprehensive test of all 5 styles with deep analysis, Notion sync, and detailed report

---

## Workflow

### Phase 1: Input Validation & Context Preparation

**1.1 Parse Arguments**
```javascript
const agentName = ARGUMENTS[0];  // e.g., "@cost-analyst"
const styleName = ARGUMENTS[1];  // e.g., "strategic-advisor" or "?"
const options = parseOptions(ARGUMENTS.slice(2));
```

**1.2 Validate Agent**
```bash
# Check agent exists in .claude/agents/
if (!exists(`.claude/agents/${agentName.replace('@','')}.md`)) {
  error(`Agent ${agentName} not found. Available agents: [list]`);
  exit(1);
}
```

**1.3 Validate Style**
```bash
const validStyles = [
  'technical-implementer',
  'strategic-advisor',
  'visual-architect',
  'interactive-teacher',
  'compliance-auditor'
];

if (styleName !== '?' && !validStyles.includes(styleName)) {
  error(`Style ${styleName} not found. Valid options: ${validStyles.join(', ')}`);
  exit(1);
}
```

**1.4 Determine Test Task**
```javascript
let testTask;

if (options.task) {
  // User provided custom task
  testTask = options.task;
} else {
  // Generate agent-appropriate default task
  testTask = generateDefaultTask(agentName);
}
```

---

### Phase 2: Style Selection (If Needed)

**2.1 Single Style Mode**
```javascript
if (styleName !== '?') {
  // Test single specified style
  const stylesToTest = [styleName];
  runTests(agentName, stylesToTest, testTask, options);
}
```

**2.2 Compare All Styles Mode**
```javascript
if (styleName === '?') {
  console.log(`Comparing all 5 styles for ${agentName}...\n`);

  // Recommend optimal style first
  if (!options.noRecommendation) {
    const recommendation = await invoke('Task', {
      subagent_type: 'style-orchestrator',
      prompt: `Recommend optimal style for ${agentName} task: "${testTask}"`,
      description: 'Style recommendation for comparison baseline'
    });

    console.log('📊 Recommendation (baseline):');
    console.log(recommendation);
    console.log('\n---\n');
  }

  // Test all 5 styles
  const stylesToTest = [
    'technical-implementer',
    'strategic-advisor',
    'visual-architect',
    'interactive-teacher',
    'compliance-auditor'
  ];

  runTests(agentName, stylesToTest, testTask, options);
}
```

---

### Phase 3: Test Execution

**For Each Style in stylesToTest**:

**3.1 Load Agent + Style Configuration**
```javascript
async function runSingleTest(agentName, styleName, testTask, options) {
  console.log(`\n🧪 Testing: ${agentName} + ${styleName}`);
  console.log(`Task: ${testTask}\n`);

  // Load agent specification
  const agentSpec = await readFile(`.claude/agents/${agentName.replace('@','')}.md`);

  // Load style definition
  const styleSpec = await readFile(`.claude/styles/${styleName}.md`);

  // Combine into enhanced prompt
  const enhancedPrompt = composeStylePrompt(agentSpec, styleSpec, testTask);

  // Record start time
  const startTime = Date.now();

  // ...continue to execution
}
```

**3.2 Execute Agent Task with Style Applied**
```javascript
  // Execute with style-modified behavior
  const testOutput = await invoke('Task', {
    subagent_type: agentName.replace('@', ''),
    prompt: enhancedPrompt,
    description: `Style test: ${styleName} (${options.ultrathink ? 'UltraThink' : 'Standard'})`
  });

  // Record end time
  const endTime = Date.now();
  const generationTime = endTime - startTime;
```

**3.3 Calculate Behavioral Metrics**
```javascript
  const metrics = {
    // Output characteristics
    outputLength: countTokens(testOutput),
    technicalDensity: calculateTechnicalDensity(testOutput),  // 0-1
    formalityScore: calculateFormality(testOutput),           // 0-1
    clarityScore: calculateClarity(testOutput),               // 0-1
    visualElementsCount: countVisualElements(testOutput),
    codeBlocksCount: countCodeBlocks(testOutput),

    // Time performance
    generationTimeMs: generationTime,
    tokensPerSecond: (countTokens(testOutput) / (generationTime / 1000)).toFixed(2),

    // Placeholder for user feedback (collected later if interactive)
    goalAchievement: null,      // 0-1, set in interactive mode
    audienceAppropriate: null,  // 0-1, set in interactive mode
    styleConsistency: null,     // 0-1, calculated automatically
    userSatisfaction: null      // 1-5, set in interactive mode
  };
```

**Metric Calculation Methods:**

```javascript
function calculateTechnicalDensity(text) {
  // Ratio of technical terms, code blocks, and jargon
  const technicalPatterns = [
    /\b(function|class|const|let|var|import|export)\b/g,
    /```[\s\S]*?```/g,
    /\b(API|SDK|CLI|SQL|HTTP|JSON|XML)\b/g,
    /\b[A-Z]{2,}\b/g  // Acronyms
  ];

  let technicalMatches = 0;
  technicalPatterns.forEach(pattern => {
    const matches = text.match(pattern);
    if (matches) technicalMatches += matches.length;
  });

  const totalWords = text.split(/\s+/).length;
  return Math.min(technicalMatches / (totalWords * 0.1), 1.0);  // Cap at 1.0
}

function calculateFormality(text) {
  // Formal language indicators
  const formalIndicators = [
    /\b(hereby|attest|pursuant|aforementioned|notwithstanding)\b/gi,
    /\b(The organization|The entity)\b/g,
    /\b(established|implemented|documented|validated)\b/gi,
  ];

  // Informal language indicators
  const informalIndicators = [
    /\b(gonna|wanna|yeah|ok|cool)\b/gi,
    /\b(we'll|we're|you'll|you're)\b/g,
    /[!]{2,}/g,  // Multiple exclamation marks
  ];

  let formalScore = 0;
  formalIndicators.forEach(pattern => {
    const matches = text.match(pattern);
    if (matches) formalScore += matches.length;
  });

  let informalScore = 0;
  informalIndicators.forEach(pattern => {
    const matches = text.match(pattern);
    if (matches) informalScore += matches.length;
  });

  const totalIndicators = formalScore + informalScore;
  if (totalIndicators === 0) return 0.5;  // Neutral baseline

  return formalScore / totalIndicators;
}

function calculateClarity(text) {
  // Readability metrics (Flesch Reading Ease approximation)
  const sentences = text.split(/[.!?]+/).length;
  const words = text.split(/\s+/).length;
  const syllables = estimateSyllables(text);

  // Flesch Reading Ease: 206.835 - 1.015(words/sentences) - 84.6(syllables/words)
  const wordsPerSentence = words / sentences;
  const syllablesPerWord = syllables / words;

  const fleschScore = 206.835 - (1.015 * wordsPerSentence) - (84.6 * syllablesPerWord);

  // Normalize to 0-1 (Flesch scores typically 0-100)
  return Math.max(0, Math.min(1, fleschScore / 100));
}

function countVisualElements(text) {
  // Mermaid diagrams, tables, callout boxes
  const visualPatterns = [
    /```mermaid[\s\S]*?```/g,
    /\|[^|]+\|/g,  // Table rows
    /^[-*+]\s/gm,  // Lists
    /^#+\s/gm,     // Headers
  ];

  let count = 0;
  visualPatterns.forEach(pattern => {
    const matches = text.match(pattern);
    if (matches) count += matches.length;
  });

  return count;
}

function countCodeBlocks(text) {
  const codeBlocks = text.match(/```[\s\S]*?```/g);
  return codeBlocks ? codeBlocks.length : 0;
}
```

**3.4 UltraThink Deep Analysis (If Enabled)**
```javascript
  if (options.ultrathink) {
    console.log('\n🧠 Running UltraThink Deep Analysis...\n');

    const deepAnalysis = await invoke('Task', {
      subagent_type: 'ultrathink-analyzer',
      prompt: `Analyze agent+style combination with deep reasoning:

      Agent: ${agentName}
      Style: ${styleName}
      Task: ${testTask}
      Output: ${testOutput}
      Metrics: ${JSON.stringify(metrics, null, 2)}

      Provide:
      1. Semantic Appropriateness (0-100)
      2. Audience Alignment (0-100)
      3. Brand Consistency (0-100)
      4. Practical Effectiveness (0-100)
      5. Innovation Potential (0-100)
      6. Overall Tier Classification (Gold/Silver/Bronze/Needs Improvement)
      7. Detailed reasoning for scores
      8. Recommendations for optimization`,
      description: 'UltraThink deep analysis'
    });

    metrics.ultrathinkAnalysis = deepAnalysis;

    // Extract tier classification
    const tierMatch = deepAnalysis.match(/Tier:\s*(Gold|Silver|Bronze|Needs Improvement)/i);
    metrics.ultrathinkTier = tierMatch ? tierMatch[1] : 'Unknown';
  }
```

---

### Phase 4: Interactive Feedback Collection (If Enabled)

**4.1 Present Output to User**
```javascript
  if (options.interactive) {
    console.log('\n📄 Test Output:\n');
    console.log('='.repeat(80));
    console.log(testOutput);
    console.log('='.repeat(80));
  }
```

**4.2 Collect User Ratings**
```javascript
    // Goal Achievement
    const goalRating = await askUser(
      'Did the output achieve the task goal? (0-10, 0=missed completely, 10=exceeded expectations): '
    );
    metrics.goalAchievement = parseInt(goalRating) / 10;

    // Audience Appropriateness
    const audienceRating = await askUser(
      'Is the output appropriate for the target audience? (0-10, 0=wrong audience, 10=perfect match): '
    );
    metrics.audienceAppropriate = parseInt(audienceRating) / 10;

    // Style Consistency
    const consistencyRating = await askUser(
      'Did the output maintain consistent style throughout? (0-10, 0=inconsistent, 10=perfectly consistent): '
    );
    metrics.styleConsistency = parseInt(consistencyRating) / 10;

    // Overall Satisfaction
    const satisfactionRating = await askUser(
      'Overall satisfaction with this output? (1-5 stars, 1=poor, 5=excellent): '
    );
    metrics.userSatisfaction = parseInt(satisfactionRating);
  }
```

**4.3 Calculate Overall Effectiveness Score**
```javascript
  // Weighted effectiveness formula
  const effectivenessScore = (
    (metrics.goalAchievement || 0.7) * 0.35 +      // 35% weight
    (metrics.audienceAppropriate || 0.7) * 0.25 +  // 25% weight
    (metrics.clarityScore || 0.7) * 0.20 +         // 20% weight
    (metrics.styleConsistency || 0.8) * 0.20       // 20% weight
  ) * 100;

  metrics.overallEffectiveness = Math.round(effectivenessScore);
```

---

### Phase 5: Results Presentation

**5.1 Display Individual Test Results**
```javascript
  console.log(`\n📊 Test Results: ${agentName} + ${styleName}\n`);
  console.log('Behavioral Metrics:');
  console.log(`  • Output Length: ${metrics.outputLength} tokens`);
  console.log(`  • Technical Density: ${(metrics.technicalDensity * 100).toFixed(1)}%`);
  console.log(`  • Formality Score: ${(metrics.formalityScore * 100).toFixed(1)}%`);
  console.log(`  • Clarity Score: ${(metrics.clarityScore * 100).toFixed(1)}%`);
  console.log(`  • Visual Elements: ${metrics.visualElementsCount}`);
  console.log(`  • Code Blocks: ${metrics.codeBlocksCount}`);

  console.log('\nPerformance Metrics:');
  console.log(`  • Generation Time: ${(metrics.generationTimeMs / 1000).toFixed(2)}s`);
  console.log(`  • Tokens/Second: ${metrics.tokensPerSecond}`);

  if (metrics.goalAchievement !== null) {
    console.log('\nEffectiveness Metrics:');
    console.log(`  • Goal Achievement: ${(metrics.goalAchievement * 100).toFixed(1)}%`);
    console.log(`  • Audience Appropriateness: ${(metrics.audienceAppropriate * 100).toFixed(1)}%`);
    console.log(`  • Style Consistency: ${(metrics.styleConsistency * 100).toFixed(1)}%`);
    console.log(`  • User Satisfaction: ${'⭐'.repeat(metrics.userSatisfaction)} (${metrics.userSatisfaction}/5)`);
    console.log(`\n  🎯 Overall Effectiveness: ${metrics.overallEffectiveness}/100`);
  }

  if (options.ultrathink && metrics.ultrathinkTier) {
    console.log(`\n🏆 UltraThink Tier: ${getTierEmoji(metrics.ultrathinkTier)} ${metrics.ultrathinkTier}`);
  }
```

**5.2 Comparative Analysis (If Multiple Styles Tested)**
```javascript
if (stylesToTest.length > 1) {
  console.log('\n📊 Comparative Analysis\n');

  // Sort by overall effectiveness
  const sortedResults = testResults.sort((a, b) =>
    b.metrics.overallEffectiveness - a.metrics.overallEffectiveness
  );

  // Display comparison table
  console.table(sortedResults.map(r => ({
    'Style': r.styleName,
    'Effectiveness': `${r.metrics.overallEffectiveness}/100`,
    'Clarity': `${(r.metrics.clarityScore * 100).toFixed(0)}%`,
    'Technical': `${(r.metrics.technicalDensity * 100).toFixed(0)}%`,
    'Formality': `${(r.metrics.formalityScore * 100).toFixed(0)}%`,
    'Time': `${(r.metrics.generationTimeMs / 1000).toFixed(1)}s`,
    'Tier': r.metrics.ultrathinkTier || 'N/A'
  })));

  // Recommendations
  console.log('\n🎯 Recommendations:\n');
  console.log(`**Top Choice**: ${sortedResults[0].styleName} (${sortedResults[0].metrics.overallEffectiveness}/100 effectiveness)`);
  console.log(`  → ${getStyleRecommendationReason(sortedResults[0])}\n`);

  if (sortedResults[1]) {
    console.log(`**Alternative**: ${sortedResults[1].styleName} (${sortedResults[1].metrics.overallEffectiveness}/100 effectiveness)`);
    console.log(`  → Use when: ${getAlternativeUseCase(sortedResults[0], sortedResults[1])}\n`);
  }
}
```

---

### Phase 6: Notion Database Synchronization

**6.1 Sync to Agent Style Tests Database**
```javascript
if (options.sync || options.interactive) {
  console.log('\n💾 Syncing results to Notion Agent Style Tests database...\n');

  for (const result of testResults) {
    const testEntry = {
      'Test Name': `${agentName}-${result.styleName}-${formatDate(new Date(), 'YYYYMMDD')}`,
      'Agent': linkToAgentRegistry(agentName),
      'Style': linkToStyleRegistry(result.styleName),
      'Test Date': new Date().toISOString(),
      'Task Description': testTask,
      'Output Length': result.metrics.outputLength,
      'Technical Density': result.metrics.technicalDensity,
      'Formality Score': result.metrics.formalityScore,
      'Clarity Score': result.metrics.clarityScore,
      'Visual Elements Count': result.metrics.visualElementsCount,
      'Code Blocks Count': result.metrics.codeBlocksCount,
      'Goal Achievement': result.metrics.goalAchievement || 0.7,
      'Audience Appropriateness': result.metrics.audienceAppropriate || 0.7,
      'Style Consistency': result.metrics.styleConsistency || 0.8,
      'Generation Time': result.metrics.generationTimeMs,
      'User Satisfaction': result.metrics.userSatisfaction || 4,
      'Overall Effectiveness': result.metrics.overallEffectiveness / 100,
      'Test Output': truncate(result.output, 5000),  // Long text field
      'Notes': options.ultrathink ? `UltraThink Tier: ${result.metrics.ultrathinkTier}` : '',
      'Status': result.metrics.overallEffectiveness >= 75 ? 'Passed' : 'Needs Review'
    };

    await invoke('mcp__notion__notion-create-pages', {
      parent: { data_source_id: AGENT_STYLE_TESTS_DB_ID },
      pages: [{ properties: testEntry }]
    });

    console.log(`✓ Synced: ${testEntry['Test Name']}`);
  }

  console.log('\n✅ All results synced to Notion\n');
}
```

---

### Phase 7: Report Generation (If Requested)

**7.1 Generate Comprehensive Test Report**
```javascript
if (options.report) {
  console.log('\n📄 Generating detailed test report...\n');

  const reportContent = generateDetailedReport({
    agentName,
    testTask,
    testResults,
    options,
    timestamp: new Date().toISOString()
  });

  const reportFilename = `.claude/reports/style-test-${agentName.replace('@','')}-${Date.now()}.md`;
  await writeFile(reportFilename, reportContent);

  console.log(`✅ Report generated: ${reportFilename}\n`);
  console.log('View report for:');
  console.log('  • Complete test output samples');
  console.log('  • Detailed metric breakdowns');
  console.log('  • UltraThink analysis (if enabled)');
  console.log('  • Historical performance comparison');
  console.log('  • Optimization recommendations\n');
}
```

---

## Default Task Generation

**Agent-Appropriate Default Tasks:**

```javascript
function generateDefaultTask(agentName) {
  const defaultTasks = {
    '@cost-analyst': 'Analyze Q4 2025 software spending and identify optimization opportunities',
    '@viability-assessor': 'Assess viability of AI-powered cost optimization platform idea',
    '@build-architect': 'Design microservices architecture for customer data platform',
    '@code-generator': 'Generate Azure Functions HTTP trigger with Cosmos DB integration',
    '@markdown-expert': 'Create comprehensive API documentation for authentication endpoints',
    '@compliance-orchestrator': 'Document SOC2 Type II logical access control (CC6.1)',
    '@knowledge-curator': 'Archive learnings from completed cloud migration research project',
    '@research-coordinator': 'Structure feasibility study for real-time collaboration features',
    '@deployment-orchestrator': 'Plan blue-green deployment strategy for production release',
    '@integration-specialist': 'Configure Azure AD B2C authentication for customer portal',
    '@database-architect': 'Design normalized database schema for CRM system',
    '@architect-supreme': 'Evaluate architectural patterns for event-driven microservices',
    // ... 37 total agents with contextual tasks
  };

  return defaultTasks[agentName] ||
    `Perform typical ${agentName} task demonstrating core capabilities`;
}
```

---

## Helper Functions

```javascript
function getTierEmoji(tier) {
  const emojis = {
    'Gold': '🥇',
    'Silver': '🥈',
    'Bronze': '🥉',
    'Needs Improvement': '⚪'
  };
  return emojis[tier] || '❓';
}

function getStyleRecommendationReason(result) {
  const reasons = {
    'technical-implementer': 'Provides precise technical guidance with executable code examples',
    'strategic-advisor': 'Delivers executive-ready business insights with clear ROI analysis',
    'visual-architect': 'Offers intuitive visual communication with balanced technical depth',
    'interactive-teacher': 'Enables progressive learning with accessible explanations',
    'compliance-auditor': 'Ensures audit-ready documentation with formal evidence structure'
  };
  return reasons[result.styleName] || 'Optimal combination for this task type';
}

function getAlternativeUseCase(primary, alternative) {
  // Context-aware alternative recommendations
  if (primary.metrics.technicalDensity > 0.7 && alternative.metrics.technicalDensity < 0.4) {
    return 'Target audience is less technical or needs high-level overview first';
  }
  if (primary.metrics.formalityScore < 0.5 && alternative.metrics.formalityScore > 0.8) {
    return 'Output will be reviewed by auditors, compliance officers, or regulatory bodies';
  }
  if (primary.metrics.visualElementsCount > 5 && alternative.metrics.visualElementsCount < 2) {
    return 'Diagrams not essential or text-based format required';
  }
  return 'Different audience or context requires alternative communication approach';
}

function linkToAgentRegistry(agentName) {
  // Create Notion relation to Agent Registry
  // Returns page ID from Agent Registry that matches agentName
  // Implementation depends on Notion MCP relation creation
}

function linkToStyleRegistry(styleName) {
  // Create Notion relation to Output Styles Registry
  // Returns page ID from Output Styles Registry that matches styleName
}
```

---

## Error Handling

**Common Errors and Remediation:**

**1. Agent Not Found**
```
Error: Agent @cost-analyzer not found
Available agents: @cost-analyst, @cost-feasibility-analyst, @cost-optimizer-ai
Did you mean: @cost-analyst?
```

**2. Invalid Style Name**
```
Error: Style "strategic" not recognized
Valid styles: technical-implementer, strategic-advisor, visual-architect,
              interactive-teacher, compliance-auditor
```

**3. Task Too Vague**
```
Warning: Default task may not demonstrate style effectiveness optimally
Recommendation: Provide specific task with --task="..." for better results
```

**4. Notion Sync Failure**
```
Error: Failed to sync results to Notion (Rate limit exceeded)
Results saved locally to: .claude/cache/test-results-[timestamp].json
Retry sync with: /style:sync-results [filename]
```

---

## Performance Benchmarks

**Expected Execution Times:**

| Mode | Single Style | All Styles (5) |
|------|-------------|----------------|
| **Standard** | 30-60 seconds | 3-5 minutes |
| **UltraThink** | 60-120 seconds | 6-10 minutes |
| **Interactive** | 90-180 seconds | 10-15 minutes |
| **Full Suite (UltraThink + Interactive + Report)** | 120-180 seconds | 12-18 minutes |

**Optimization Tips:**
- Use standard mode for quick validation
- Reserve UltraThink for critical combination testing
- Batch multiple tests in single session to amortize startup costs
- Enable --sync only when immediate Notion tracking needed

---

## Success Criteria

**Test Considered Successful If:**

✅ **Execution Completes**: No errors, all metrics calculated
✅ **Output Quality**: Metrics within expected ranges for style
✅ **Style Consistency**: Output matches style characteristics (verified by metrics)
✅ **Performance**: Generation time within acceptable range (<120s standard mode)
✅ **Notion Sync**: Results successfully written to Agent Style Tests database (if enabled)

**Red Flags Requiring Investigation:**

🚨 **Effectiveness <50%**: Agent+style combination fundamentally incompatible
🚨 **Technical Density Mismatch**: technical-implementer showing <0.5 density
🚨 **Formality Mismatch**: compliance-auditor showing <0.7 formality
🚨 **Generation Time >180s**: Performance issue requiring optimization
🚨 **Clarity Score <0.3**: Output difficult to understand, style refinement needed

---

## Integration with Other Commands

**Typical Workflow:**

```bash
# 1. Get recommendation
/style:recommend @cost-analyst "Analyze Q4 spending"

# 2. Test recommended style
/test-agent-style @cost-analyst strategic-advisor --task="Analyze Q4 spending"

# 3. Compare with alternatives
/test-agent-style @cost-analyst ? --task="Analyze Q4 spending"

# 4. Run deep analysis on winner
/test-agent-style @cost-analyst strategic-advisor --task="Analyze Q4 spending" --ultrathink --sync

# 5. Generate performance report
/style:report --agent=@cost-analyst --timeframe=30d
```

---

## Continuous Improvement

**After Each Test:**

1. **Review Metrics**: Identify unexpected scores or patterns
2. **Collect Feedback**: Interactive mode captures user satisfaction
3. **Update Baselines**: Historical data improves future recommendations
4. **Refine Styles**: Low-performing combinations inform style adjustments
5. **Document Insights**: Capture learnings in test notes field

**Quarterly Review Process:**

1. Run `/style:report --timeframe=90d` for portfolio-wide analysis
2. Identify top 10 and bottom 10 combinations
3. Investigate underperformers (technical issues or style mismatch?)
4. Document best practices from top performers
5. Update style definitions based on empirical evidence
6. Sunset or refine consistently low-performing combinations

---

**Best for**: Organizations requiring systematic, data-driven communication optimization that improves output effectiveness by 25% or more through empirical validation, continuous learning from test results, and evidence-based style selection that drives measurable improvements in audience satisfaction and task achievement rates.
