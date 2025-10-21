---
title: Build Your First Custom Agent - Tutorial
description: Create a production-ready custom agent from scratch. Step-by-step guide covering implementation, testing, deployment, and monitoring best practices.
tags:
  - tutorial
  - custom-agents
  - getting-started
  - python
  - typescript
  - deployment
  - testing
lastUpdated: 2025-10-09
author: Agent Studio Team
audience: developers
---

# Building Your First Custom Agent

## Overview

Welcome to the comprehensive guide for building custom agents in Agent Studio. This tutorial will walk you through creating a fully functional agent from scratch, including definition, implementation, testing, and deployment.

### What You'll Build

In this tutorial, you will create a **Code Review Agent** that:
- Analyzes code quality and identifies potential issues
- Suggests improvements based on best practices
- Integrates with the meta-agent platform
- Communicates with other agents via the dual-layer architecture
- Deploys to Azure Container Apps

### Prerequisites

Before you begin, ensure you have:

- **Development Environment**: Node.js 18+ or Python 3.12+
- **Azure Access**: Active Azure subscription with permissions to create resources
- **Tools Installed**:
  - Git
  - Docker Desktop
  - Azure CLI (`az`)
  - VS Code (recommended) with relevant language extensions
- **Knowledge**: Basic understanding of:
  - TypeScript or Python
  - REST APIs
  - Docker containers
  - Azure services

### Estimated Time

- **Basic Implementation**: 45 minutes
- **Testing**: 30 minutes
- **Deployment**: 30 minutes
- **Total**: 90-120 minutes

### Architecture Overview

Agents in the platform operate using a dual-layer architecture:

- **Strategic Layer**: High-level planning, coordination, and decision-making
- **Operational Layer**: Task execution, tool usage, and specific implementations

Your custom agent will participate in this ecosystem, communicating with other agents through the platform's messaging system.

---

## Step 1: Define Your Agent

### Agent Configuration

Every agent begins with a JSON definition file that specifies its capabilities, expertise, and behavior. Create your agent definition at `.claude/agents/code-reviewer.json`:

```json
{
  "name": "code-reviewer",
  "description": "Automated code review agent specializing in code quality analysis, security vulnerability detection, and best practice enforcement",
  "role": "Code Quality Specialist",
  "layer": "operational",
  "model": "claude-sonnet-4",
  "expertise": [
    "Static code analysis",
    "Security vulnerability detection",
    "Code style and formatting",
    "Performance optimization patterns",
    "Unit testing best practices",
    "SOLID principles",
    "Design pattern recognition",
    "Technical debt identification"
  ],
  "capabilities": [
    "Analyze code for bugs and anti-patterns",
    "Detect security vulnerabilities (OWASP Top 10)",
    "Enforce coding standards and style guides",
    "Suggest performance improvements",
    "Identify code smells and refactoring opportunities",
    "Review test coverage and quality",
    "Generate code quality reports",
    "Recommend best practices"
  ],
  "analysisAreas": {
    "security": {
      "sqlInjection": "Detect SQL injection vulnerabilities",
      "xss": "Identify cross-site scripting risks",
      "authentication": "Review authentication and authorization",
      "dataValidation": "Verify input validation",
      "cryptography": "Check cryptographic implementations",
      "dependencies": "Scan for vulnerable dependencies"
    },
    "quality": {
      "complexity": "Measure cyclomatic complexity",
      "duplication": "Identify code duplication",
      "naming": "Review naming conventions",
      "comments": "Assess documentation quality",
      "errorHandling": "Verify error handling patterns",
      "testability": "Evaluate testability"
    },
    "performance": {
      "algorithms": "Analyze algorithm efficiency",
      "database": "Review database query patterns",
      "caching": "Identify caching opportunities",
      "async": "Check asynchronous patterns",
      "memory": "Detect memory leaks and inefficiencies"
    }
  },
  "reviewLevels": {
    "quick": {
      "description": "Fast, surface-level review",
      "checks": ["syntax", "basic security", "obvious bugs"],
      "timeEstimate": "1-2 minutes"
    },
    "standard": {
      "description": "Comprehensive code review",
      "checks": ["all quick checks", "code quality", "test coverage", "documentation"],
      "timeEstimate": "5-10 minutes"
    },
    "deep": {
      "description": "In-depth analysis including architecture",
      "checks": ["all standard checks", "architecture patterns", "performance analysis", "security audit"],
      "timeEstimate": "15-30 minutes"
    }
  },
  "outputFormat": {
    "summary": {
      "overallScore": "Code quality score (0-100)",
      "severityCounts": "Count of issues by severity (critical, high, medium, low)",
      "recommendation": "Overall recommendation (approve, approve with changes, reject)"
    },
    "issues": {
      "location": "File path, line number, column",
      "severity": "Issue severity level",
      "category": "Issue category (security, quality, performance)",
      "description": "Detailed issue description",
      "suggestion": "Recommended fix or improvement",
      "codeSnippet": "Relevant code snippet"
    },
    "metrics": {
      "linesOfCode": "Total lines analyzed",
      "testCoverage": "Test coverage percentage",
      "complexity": "Average cyclomatic complexity",
      "maintainabilityIndex": "Maintainability score"
    }
  },
  "integrations": {
    "tools": [
      "eslint",
      "pylint",
      "sonarqube",
      "snyk",
      "codeql"
    ],
    "vcs": [
      "github",
      "gitlab",
      "azure-devops"
    ]
  },
  "personality": "Thorough, constructive, educational, focused on improvement rather than criticism",
  "communicationStyle": "Provide specific, actionable feedback with examples and explanations of why issues matter"
}
```

### Understanding the Configuration

Let's break down the key sections:

1. **Basic Metadata**: `name`, `description`, `role` - Identifies the agent
2. **Layer**: `operational` - Indicates this agent performs specific tasks
3. **Model**: `claude-sonnet-4` - Specifies which AI model to use
4. **Expertise**: Array of domain knowledge areas
5. **Capabilities**: What the agent can actually do
6. **Domain-Specific Configuration**: `analysisAreas`, `reviewLevels` - Agent-specific settings
7. **Output Format**: Structure of agent responses
8. **Integrations**: External tools and services the agent can use

### Configuration Best Practices

- **Be Specific**: Clearly define what your agent can and cannot do
- **Use Hierarchical Structure**: Organize complex configurations into nested objects
- **Include Examples**: When possible, show example outputs or formats
- **Document Everything**: Use descriptive keys and include comments (via description fields)
- **Version Compatibility**: Ensure your configuration aligns with platform schemas

---

## Step 2: Implement Agent Logic

You can implement your agent in either TypeScript (Node.js) or Python. We'll show both approaches.

### TypeScript Implementation

Create `src/agents/code-reviewer/agent.ts`:

```typescript
import { BaseAgent, AgentMessage, AgentResponse, AgentConfig } from '@/types/agents';
import { ToolRegistry } from '@/services/tool-registry';
import { Logger } from '@/utils/logger';

/**
 * Code Review Agent
 *
 * Analyzes code for quality, security, and performance issues.
 * Provides detailed, actionable feedback for developers.
 */
export class CodeReviewAgent implements BaseAgent {
  private readonly config: AgentConfig;
  private readonly tools: ToolRegistry;
  private readonly logger: Logger;
  private conversationHistory: AgentMessage[] = [];

  constructor(config: AgentConfig, tools: ToolRegistry) {
    this.config = config;
    this.tools = tools;
    this.logger = new Logger('CodeReviewAgent');
  }

  /**
   * Get the system prompt for the agent
   */
  getSystemPrompt(): string {
    return `You are a ${this.config.role}, specialized in code quality analysis.

Your expertise includes:
${this.config.expertise.map(e => `- ${e}`).join('\n')}

Your capabilities:
${this.config.capabilities.map(c => `- ${c}`).join('\n')}

When reviewing code:
1. Be thorough but constructive
2. Explain WHY issues matter, not just WHAT is wrong
3. Provide specific, actionable suggestions
4. Include code examples when helpful
5. Prioritize critical security and reliability issues
6. Acknowledge good practices when you see them

Communication style: ${this.config.communicationStyle}`;
  }

  /**
   * Process an incoming message and generate a response
   */
  async process(message: AgentMessage): Promise<AgentResponse> {
    this.logger.info('Processing code review request', {
      sender: message.sender,
      hasCode: message.context?.code !== undefined,
    });

    try {
      // Add message to conversation history
      this.conversationHistory.push(message);

      // Extract code and review level from message
      const code = message.context?.code as string;
      const reviewLevel = (message.context?.reviewLevel as string) || 'standard';
      const language = message.context?.language as string;

      if (!code) {
        throw new Error('No code provided for review');
      }

      // Perform code review
      const reviewResult = await this.reviewCode(code, language, reviewLevel);

      // Format response
      const response: AgentResponse = {
        content: this.formatReviewResponse(reviewResult),
        success: true,
        agentName: this.config.name,
        agentRole: this.config.role,
        metadata: {
          reviewLevel,
          language,
          issueCount: reviewResult.issues.length,
          overallScore: reviewResult.summary.overallScore,
        },
        timestamp: new Date(),
      };

      // Add response to history
      this.conversationHistory.push({
        content: response.content,
        sender: this.config.name,
        timestamp: response.timestamp,
      });

      return response;
    } catch (error) {
      this.logger.error('Code review failed', { error });

      return {
        content: `Code review failed: ${error.message}`,
        success: false,
        agentName: this.config.name,
        agentRole: this.config.role,
        metadata: { error: error.message },
        timestamp: new Date(),
      };
    }
  }

  /**
   * Perform code review analysis
   */
  private async reviewCode(
    code: string,
    language: string,
    reviewLevel: string
  ): Promise<CodeReviewResult> {
    this.logger.info('Analyzing code', { language, reviewLevel });

    // Use static analysis tools
    const staticAnalysis = await this.runStaticAnalysis(code, language);

    // Use AI for deeper analysis
    const aiAnalysis = await this.runAIAnalysis(code, language, reviewLevel);

    // Combine results
    const issues = [...staticAnalysis.issues, ...aiAnalysis.issues];

    // Calculate metrics
    const metrics = this.calculateMetrics(code, issues);

    // Generate summary
    const summary = this.generateSummary(issues, metrics);

    return {
      summary,
      issues: this.prioritizeIssues(issues),
      metrics,
    };
  }

  /**
   * Run static analysis using configured tools
   */
  private async runStaticAnalysis(
    code: string,
    language: string
  ): Promise<{ issues: CodeIssue[] }> {
    const tool = this.getToolForLanguage(language);

    if (!tool) {
      this.logger.warn('No static analysis tool available for language', { language });
      return { issues: [] };
    }

    try {
      const result = await this.tools.execute(tool, {
        code,
        language,
        rules: this.getReviewRules(language),
      });

      return { issues: result.issues || [] };
    } catch (error) {
      this.logger.error('Static analysis failed', { error, language });
      return { issues: [] };
    }
  }

  /**
   * Run AI-powered analysis for deeper insights
   */
  private async runAIAnalysis(
    code: string,
    language: string,
    reviewLevel: string
  ): Promise<{ issues: CodeIssue[] }> {
    const reviewConfig = this.config.reviewLevels[reviewLevel];

    const prompt = `Analyze this ${language} code for:
${reviewConfig.checks.map(c => `- ${c}`).join('\n')}

Code to review:
\`\`\`${language}
${code}
\`\`\`

Identify issues and provide detailed, actionable feedback.
Focus on: ${reviewConfig.checks.join(', ')}`;

    try {
      const response = await this.callLLM(prompt);
      return this.parseAIResponse(response);
    } catch (error) {
      this.logger.error('AI analysis failed', { error });
      return { issues: [] };
    }
  }

  /**
   * Call the language model for analysis
   */
  private async callLLM(prompt: string): Promise<string> {
    // Implementation would use Azure OpenAI or Claude API
    // This is a placeholder for the actual implementation
    const response = await fetch('/api/llm/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: this.config.model,
        messages: [
          { role: 'system', content: this.getSystemPrompt() },
          ...this.conversationHistory.map(h => ({
            role: h.sender === this.config.name ? 'assistant' : 'user',
            content: h.content,
          })),
          { role: 'user', content: prompt },
        ],
      }),
    });

    const data = await response.json();
    return data.content;
  }

  /**
   * Parse AI response into structured issues
   */
  private parseAIResponse(response: string): { issues: CodeIssue[] } {
    // Implementation would parse the LLM response into structured issues
    // This is simplified for demonstration
    const issues: CodeIssue[] = [];

    // Parse response and extract issues
    // In production, you'd use a more robust parsing strategy

    return { issues };
  }

  /**
   * Calculate code metrics
   */
  private calculateMetrics(code: string, issues: CodeIssue[]): CodeMetrics {
    const lines = code.split('\n');
    const linesOfCode = lines.filter(l => l.trim() && !l.trim().startsWith('//')).length;

    return {
      linesOfCode,
      testCoverage: 0, // Would be calculated if tests are provided
      complexity: this.calculateComplexity(code),
      maintainabilityIndex: this.calculateMaintainability(linesOfCode, issues.length),
    };
  }

  /**
   * Calculate cyclomatic complexity
   */
  private calculateComplexity(code: string): number {
    // Simplified complexity calculation
    // Count decision points: if, while, for, case, &&, ||, ?
    const decisionPoints = (code.match(/\b(if|while|for|case)\b|\&\&|\|\||\?/g) || []).length;
    return Math.max(1, decisionPoints);
  }

  /**
   * Calculate maintainability index
   */
  private calculateMaintainability(linesOfCode: number, issueCount: number): number {
    // Simplified maintainability calculation
    // Real implementation would use proper formula
    const baseScore = 100;
    const locPenalty = Math.min(30, linesOfCode / 100);
    const issuePenalty = issueCount * 2;

    return Math.max(0, Math.min(100, baseScore - locPenalty - issuePenalty));
  }

  /**
   * Generate review summary
   */
  private generateSummary(issues: CodeIssue[], metrics: CodeMetrics): ReviewSummary {
    const severityCounts = {
      critical: issues.filter(i => i.severity === 'critical').length,
      high: issues.filter(i => i.severity === 'high').length,
      medium: issues.filter(i => i.severity === 'medium').length,
      low: issues.filter(i => i.severity === 'low').length,
    };

    // Calculate overall score
    const overallScore = Math.max(0, 100 - (
      severityCounts.critical * 20 +
      severityCounts.high * 10 +
      severityCounts.medium * 5 +
      severityCounts.low * 2
    ));

    // Determine recommendation
    let recommendation: 'approve' | 'approve-with-changes' | 'reject';
    if (severityCounts.critical > 0 || severityCounts.high > 3) {
      recommendation = 'reject';
    } else if (severityCounts.high > 0 || severityCounts.medium > 5) {
      recommendation = 'approve-with-changes';
    } else {
      recommendation = 'approve';
    }

    return {
      overallScore,
      severityCounts,
      recommendation,
    };
  }

  /**
   * Prioritize issues by severity and impact
   */
  private prioritizeIssues(issues: CodeIssue[]): CodeIssue[] {
    const severityOrder = { critical: 0, high: 1, medium: 2, low: 3 };

    return issues.sort((a, b) => {
      const severityDiff = severityOrder[a.severity] - severityOrder[b.severity];
      if (severityDiff !== 0) return severityDiff;

      // If same severity, sort by line number
      return a.location.line - b.location.line;
    });
  }

  /**
   * Format the review result as a readable response
   */
  private formatReviewResponse(result: CodeReviewResult): string {
    const { summary, issues, metrics } = result;

    let response = `# Code Review Report\n\n`;

    // Summary
    response += `## Summary\n\n`;
    response += `- **Overall Score**: ${summary.overallScore}/100\n`;
    response += `- **Recommendation**: ${summary.recommendation.toUpperCase()}\n`;
    response += `- **Issues Found**: ${issues.length}\n`;
    response += `  - Critical: ${summary.severityCounts.critical}\n`;
    response += `  - High: ${summary.severityCounts.high}\n`;
    response += `  - Medium: ${summary.severityCounts.medium}\n`;
    response += `  - Low: ${summary.severityCounts.low}\n\n`;

    // Metrics
    response += `## Code Metrics\n\n`;
    response += `- **Lines of Code**: ${metrics.linesOfCode}\n`;
    response += `- **Cyclomatic Complexity**: ${metrics.complexity}\n`;
    response += `- **Maintainability Index**: ${metrics.maintainabilityIndex}/100\n\n`;

    // Issues
    if (issues.length > 0) {
      response += `## Issues\n\n`;

      for (const issue of issues) {
        response += `### ${issue.severity.toUpperCase()}: ${issue.description}\n\n`;
        response += `**Location**: ${issue.location.file}:${issue.location.line}:${issue.location.column}\n`;
        response += `**Category**: ${issue.category}\n\n`;

        if (issue.codeSnippet) {
          response += `\`\`\`\n${issue.codeSnippet}\n\`\`\`\n\n`;
        }

        response += `**Suggestion**: ${issue.suggestion}\n\n`;
        response += `---\n\n`;
      }
    } else {
      response += `## No Issues Found\n\nGreat job! The code looks clean.\n\n`;
    }

    return response;
  }

  /**
   * Get the appropriate static analysis tool for a language
   */
  private getToolForLanguage(language: string): string | null {
    const toolMap: Record<string, string> = {
      typescript: 'eslint',
      javascript: 'eslint',
      python: 'pylint',
      csharp: 'roslyn',
    };

    return toolMap[language.toLowerCase()] || null;
  }

  /**
   * Get review rules for a specific language
   */
  private getReviewRules(language: string): string[] {
    // Return language-specific linting rules
    // This would be configured based on your organization's standards
    return [];
  }

  /**
   * Clear conversation history
   */
  clearHistory(): void {
    this.conversationHistory = [];
  }

  /**
   * Get conversation history length
   */
  getHistoryLength(): number {
    return this.conversationHistory.length;
  }

  /**
   * Shutdown the agent and cleanup resources
   */
  async shutdown(): Promise<void> {
    this.logger.info('Shutting down Code Review Agent');
    this.clearHistory();
  }
}

// Type definitions
interface CodeReviewResult {
  summary: ReviewSummary;
  issues: CodeIssue[];
  metrics: CodeMetrics;
}

interface ReviewSummary {
  overallScore: number;
  severityCounts: {
    critical: number;
    high: number;
    medium: number;
    low: number;
  };
  recommendation: 'approve' | 'approve-with-changes' | 'reject';
}

interface CodeIssue {
  location: {
    file: string;
    line: number;
    column: number;
  };
  severity: 'critical' | 'high' | 'medium' | 'low';
  category: string;
  description: string;
  suggestion: string;
  codeSnippet?: string;
}

interface CodeMetrics {
  linesOfCode: number;
  testCoverage: number;
  complexity: number;
  maintainabilityIndex: number;
}
```

### Python Implementation

Create `src/agents/code_reviewer/agent.py`:

```python
"""
Code Review Agent

Analyzes code for quality, security, and performance issues.
Provides detailed, actionable feedback for developers.
"""

import asyncio
import logging
import re
from datetime import datetime
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field

from meta_agents.agent_config import AgentConfig, AgentRole, ToolType
from meta_agents.agent_tools import ToolRegistry, ToolResult
from meta_agents.base_agent import BaseMetaAgent, MetaAgentMessage, MetaAgentResponse


class CodeLocation(BaseModel):
    """Location of code issue."""

    file: str = Field(..., description="File path")
    line: int = Field(..., ge=1, description="Line number")
    column: int = Field(..., ge=1, description="Column number")


class CodeIssue(BaseModel):
    """Represents a code quality issue."""

    location: CodeLocation = Field(..., description="Issue location")
    severity: str = Field(..., description="Issue severity")
    category: str = Field(..., description="Issue category")
    description: str = Field(..., description="Issue description")
    suggestion: str = Field(..., description="Suggested fix")
    code_snippet: Optional[str] = Field(None, description="Code snippet")


class CodeMetrics(BaseModel):
    """Code quality metrics."""

    lines_of_code: int = Field(..., ge=0, description="Total lines of code")
    test_coverage: float = Field(0.0, ge=0.0, le=100.0, description="Test coverage %")
    complexity: float = Field(..., ge=0.0, description="Cyclomatic complexity")
    maintainability_index: float = Field(..., ge=0.0, le=100.0, description="Maintainability score")


class ReviewSummary(BaseModel):
    """Summary of code review."""

    overall_score: float = Field(..., ge=0.0, le=100.0, description="Overall quality score")
    severity_counts: Dict[str, int] = Field(..., description="Issue counts by severity")
    recommendation: str = Field(..., description="Review recommendation")


class CodeReviewResult(BaseModel):
    """Complete code review result."""

    summary: ReviewSummary = Field(..., description="Review summary")
    issues: List[CodeIssue] = Field(default_factory=list, description="Found issues")
    metrics: CodeMetrics = Field(..., description="Code metrics")


class CodeReviewAgent(BaseMetaAgent):
    """
    Code Review Agent

    Specializes in analyzing code for quality, security, and performance issues.
    Provides constructive, actionable feedback to developers.
    """

    def __init__(self, config: AgentConfig, tool_registry: ToolRegistry) -> None:
        """Initialize the code review agent.

        Args:
            config: Agent configuration
            tool_registry: Registry of available tools
        """
        super().__init__(config, tool_registry)
        self.logger = logging.getLogger(__name__)

    def get_system_prompt(self) -> str:
        """Get the system prompt for the agent."""
        expertise_list = "\n".join(f"- {exp}" for exp in self.config.metadata.get("expertise", []))
        capabilities_list = "\n".join(f"- {cap}" for cap in self.config.metadata.get("capabilities", []))

        return f"""You are a {self.config.role.value}, specialized in code quality analysis.

Your expertise includes:
{expertise_list}

Your capabilities:
{capabilities_list}

When reviewing code:
1. Be thorough but constructive
2. Explain WHY issues matter, not just WHAT is wrong
3. Provide specific, actionable suggestions
4. Include code examples when helpful
5. Prioritize critical security and reliability issues
6. Acknowledge good practices when you see them

Communication style: Provide specific, actionable feedback with examples and explanations of why issues matter."""

    async def process(self, message: MetaAgentMessage) -> MetaAgentResponse:
        """Process a code review request.

        Args:
            message: Incoming message with code to review

        Returns:
            MetaAgentResponse with review results
        """
        self.logger.info(
            "Processing code review request",
            extra={
                "sender": message.sender,
                "has_code": "code" in message.context,
            },
        )

        try:
            # Extract code and parameters
            code = message.context.get("code")
            if not code:
                raise ValueError("No code provided for review")

            language = message.context.get("language", "unknown")
            review_level = message.context.get("review_level", "standard")

            # Perform code review
            review_result = await self.review_code(code, language, review_level)

            # Format response
            response_content = self.format_review_response(review_result)

            return MetaAgentResponse(
                content=response_content,
                success=True,
                agent_name=self.config.name,
                agent_role=self.config.role,
                metadata={
                    "review_level": review_level,
                    "language": language,
                    "issue_count": len(review_result.issues),
                    "overall_score": review_result.summary.overall_score,
                },
            )

        except Exception as e:
            self.logger.error("Code review failed", exc_info=True)

            return MetaAgentResponse(
                content=f"Code review failed: {str(e)}",
                success=False,
                agent_name=self.config.name,
                agent_role=self.config.role,
                metadata={"error": str(e)},
            )

    async def review_code(
        self,
        code: str,
        language: str,
        review_level: str,
    ) -> CodeReviewResult:
        """Perform comprehensive code review.

        Args:
            code: Code to review
            language: Programming language
            review_level: Review depth (quick, standard, deep)

        Returns:
            CodeReviewResult with findings
        """
        self.logger.info(
            "Analyzing code",
            extra={"language": language, "review_level": review_level},
        )

        # Run static analysis and AI analysis in parallel
        static_task = self.run_static_analysis(code, language)
        ai_task = self.run_ai_analysis(code, language, review_level)

        static_result, ai_result = await asyncio.gather(static_task, ai_task)

        # Combine results
        all_issues = static_result + ai_result

        # Calculate metrics
        metrics = self.calculate_metrics(code, all_issues)

        # Generate summary
        summary = self.generate_summary(all_issues, metrics)

        # Prioritize issues
        prioritized_issues = self.prioritize_issues(all_issues)

        return CodeReviewResult(
            summary=summary,
            issues=prioritized_issues,
            metrics=metrics,
        )

    async def run_static_analysis(
        self,
        code: str,
        language: str,
    ) -> List[CodeIssue]:
        """Run static analysis tools.

        Args:
            code: Code to analyze
            language: Programming language

        Returns:
            List of issues found
        """
        tool_name = self.get_tool_for_language(language)

        if not tool_name:
            self.logger.warning(
                "No static analysis tool for language",
                extra={"language": language},
            )
            return []

        try:
            # Check if we have the tool configured
            tool_type = ToolType.STATIC_ANALYSIS
            if not self.config.has_tool(tool_type):
                return []

            result = await self.use_tool(
                tool_type,
                code=code,
                language=language,
                rules=self.get_review_rules(language),
            )

            if result.success and result.output:
                return self.parse_tool_issues(result.output)

            return []

        except Exception as e:
            self.logger.error(
                "Static analysis failed",
                exc_info=True,
                extra={"language": language},
            )
            return []

    async def run_ai_analysis(
        self,
        code: str,
        language: str,
        review_level: str,
    ) -> List[CodeIssue]:
        """Run AI-powered code analysis.

        Args:
            code: Code to analyze
            language: Programming language
            review_level: Depth of review

        Returns:
            List of issues found
        """
        review_config = self.config.metadata.get("reviewLevels", {}).get(review_level, {})
        checks = review_config.get("checks", [])

        prompt = f"""Analyze this {language} code for:
{chr(10).join(f"- {check}" for check in checks)}

Code to review:
```{language}
{code}
```

Identify issues and provide detailed, actionable feedback.
Format each issue as:
SEVERITY: [critical|high|medium|low]
LOCATION: [line:column]
CATEGORY: [category]
DESCRIPTION: [description]
SUGGESTION: [suggestion]
---
"""

        try:
            response = await self.call_llm(prompt)
            return self.parse_ai_response(response)

        except Exception as e:
            self.logger.error("AI analysis failed", exc_info=True)
            return []

    def parse_ai_response(self, response: str) -> List[CodeIssue]:
        """Parse AI response into structured issues.

        Args:
            response: Raw AI response text

        Returns:
            List of parsed issues
        """
        issues = []

        # Split response into issue blocks
        issue_blocks = response.split("---")

        for block in issue_blocks:
            if not block.strip():
                continue

            try:
                # Extract issue details using regex
                severity_match = re.search(r"SEVERITY:\s*(\w+)", block, re.IGNORECASE)
                location_match = re.search(r"LOCATION:\s*(\d+):(\d+)", block, re.IGNORECASE)
                category_match = re.search(r"CATEGORY:\s*(.+?)$", block, re.IGNORECASE | re.MULTILINE)
                description_match = re.search(r"DESCRIPTION:\s*(.+?)$", block, re.IGNORECASE | re.MULTILINE)
                suggestion_match = re.search(r"SUGGESTION:\s*(.+?)$", block, re.IGNORECASE | re.MULTILINE)

                if all([severity_match, location_match, category_match, description_match, suggestion_match]):
                    issue = CodeIssue(
                        location=CodeLocation(
                            file="<input>",
                            line=int(location_match.group(1)),
                            column=int(location_match.group(2)),
                        ),
                        severity=severity_match.group(1).lower(),
                        category=category_match.group(1).strip(),
                        description=description_match.group(1).strip(),
                        suggestion=suggestion_match.group(1).strip(),
                    )
                    issues.append(issue)

            except Exception as e:
                self.logger.warning(
                    "Failed to parse issue block",
                    exc_info=True,
                    extra={"block": block[:100]},
                )
                continue

        return issues

    def parse_tool_issues(self, tool_output: Any) -> List[CodeIssue]:
        """Parse static analysis tool output.

        Args:
            tool_output: Raw tool output

        Returns:
            List of parsed issues
        """
        # Implementation depends on tool format
        # This is a simplified placeholder
        return []

    def calculate_metrics(self, code: str, issues: List[CodeIssue]) -> CodeMetrics:
        """Calculate code quality metrics.

        Args:
            code: Source code
            issues: Found issues

        Returns:
            CodeMetrics object
        """
        lines = code.split("\n")
        lines_of_code = len([l for l in lines if l.strip() and not l.strip().startswith("#")])

        complexity = self.calculate_complexity(code)
        maintainability = self.calculate_maintainability(lines_of_code, len(issues))

        return CodeMetrics(
            lines_of_code=lines_of_code,
            test_coverage=0.0,  # Would require test files
            complexity=complexity,
            maintainability_index=maintainability,
        )

    def calculate_complexity(self, code: str) -> float:
        """Calculate cyclomatic complexity.

        Args:
            code: Source code

        Returns:
            Complexity score
        """
        # Count decision points
        decision_keywords = r"\b(if|while|for|case|and|or)\b|\?|&&|\|\|"
        matches = re.findall(decision_keywords, code, re.IGNORECASE)
        return max(1.0, float(len(matches)))

    def calculate_maintainability(self, lines_of_code: int, issue_count: int) -> float:
        """Calculate maintainability index.

        Args:
            lines_of_code: Total lines of code
            issue_count: Number of issues found

        Returns:
            Maintainability score (0-100)
        """
        base_score = 100.0
        loc_penalty = min(30.0, lines_of_code / 100.0)
        issue_penalty = issue_count * 2.0

        score = base_score - loc_penalty - issue_penalty
        return max(0.0, min(100.0, score))

    def generate_summary(
        self,
        issues: List[CodeIssue],
        metrics: CodeMetrics,
    ) -> ReviewSummary:
        """Generate review summary.

        Args:
            issues: All found issues
            metrics: Code metrics

        Returns:
            ReviewSummary object
        """
        severity_counts = {
            "critical": len([i for i in issues if i.severity == "critical"]),
            "high": len([i for i in issues if i.severity == "high"]),
            "medium": len([i for i in issues if i.severity == "medium"]),
            "low": len([i for i in issues if i.severity == "low"]),
        }

        # Calculate overall score
        overall_score = max(0.0, 100.0 - (
            severity_counts["critical"] * 20 +
            severity_counts["high"] * 10 +
            severity_counts["medium"] * 5 +
            severity_counts["low"] * 2
        ))

        # Determine recommendation
        if severity_counts["critical"] > 0 or severity_counts["high"] > 3:
            recommendation = "reject"
        elif severity_counts["high"] > 0 or severity_counts["medium"] > 5:
            recommendation = "approve-with-changes"
        else:
            recommendation = "approve"

        return ReviewSummary(
            overall_score=overall_score,
            severity_counts=severity_counts,
            recommendation=recommendation,
        )

    def prioritize_issues(self, issues: List[CodeIssue]) -> List[CodeIssue]:
        """Sort issues by severity and location.

        Args:
            issues: Unsorted issues

        Returns:
            Sorted issues
        """
        severity_order = {"critical": 0, "high": 1, "medium": 2, "low": 3}

        return sorted(
            issues,
            key=lambda i: (
                severity_order.get(i.severity, 999),
                i.location.line,
                i.location.column,
            ),
        )

    def format_review_response(self, result: CodeReviewResult) -> str:
        """Format review result as markdown.

        Args:
            result: Code review result

        Returns:
            Formatted markdown string
        """
        summary = result.summary
        issues = result.issues
        metrics = result.metrics

        lines = [
            "# Code Review Report\n",
            "## Summary\n",
            f"- **Overall Score**: {summary.overall_score:.1f}/100",
            f"- **Recommendation**: {summary.recommendation.upper()}",
            f"- **Issues Found**: {len(issues)}",
            f"  - Critical: {summary.severity_counts['critical']}",
            f"  - High: {summary.severity_counts['high']}",
            f"  - Medium: {summary.severity_counts['medium']}",
            f"  - Low: {summary.severity_counts['low']}\n",
            "## Code Metrics\n",
            f"- **Lines of Code**: {metrics.lines_of_code}",
            f"- **Cyclomatic Complexity**: {metrics.complexity:.1f}",
            f"- **Maintainability Index**: {metrics.maintainability_index:.1f}/100\n",
        ]

        if issues:
            lines.append("## Issues\n")

            for issue in issues:
                lines.extend([
                    f"### {issue.severity.upper()}: {issue.description}\n",
                    f"**Location**: {issue.location.file}:{issue.location.line}:{issue.location.column}",
                    f"**Category**: {issue.category}\n",
                ])

                if issue.code_snippet:
                    lines.append(f"```\n{issue.code_snippet}\n```\n")

                lines.append(f"**Suggestion**: {issue.suggestion}\n")
                lines.append("---\n")
        else:
            lines.extend([
                "## No Issues Found\n",
                "Great job! The code looks clean.\n",
            ])

        return "\n".join(lines)

    def get_tool_for_language(self, language: str) -> Optional[str]:
        """Get static analysis tool for language.

        Args:
            language: Programming language

        Returns:
            Tool name or None
        """
        tool_map = {
            "python": "pylint",
            "typescript": "eslint",
            "javascript": "eslint",
            "csharp": "roslyn",
        }

        return tool_map.get(language.lower())

    def get_review_rules(self, language: str) -> List[str]:
        """Get linting rules for language.

        Args:
            language: Programming language

        Returns:
            List of rule IDs
        """
        # Return language-specific rules
        # This would be configured per organization
        return []
```

### Implementation Best Practices

1. **Error Handling**: Always wrap operations in try-catch/try-except blocks
2. **Logging**: Log important events, errors, and metrics
3. **Async Operations**: Use async/await for I/O-bound operations
4. **Type Safety**: Use TypeScript interfaces or Pydantic models for data structures
5. **Configuration**: Make behavior configurable rather than hardcoded
6. **Testing**: Write testable code with clear responsibilities
7. **Documentation**: Document public methods and complex logic

---

## Step 3: Register the Agent

### Registration API

Once your agent is implemented, register it with the platform via the API:

```typescript
// register-agent.ts
import { AgentConfig } from '@/types/agents';
import fs from 'fs/promises';
import path from 'path';

async function registerAgent() {
  // Load agent configuration
  const configPath = path.join(process.cwd(), '.claude/agents/code-reviewer.json');
  const configContent = await fs.readFile(configPath, 'utf-8');
  const config: AgentConfig = JSON.parse(configContent);

  // Register with platform
  const response = await fetch('http://localhost:8000/api/agents/register', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${process.env.API_KEY}`,
    },
    body: JSON.stringify({
      name: config.name,
      description: config.description,
      role: config.role,
      layer: config.layer,
      model: config.model,
      config: config,
      endpoint: 'http://localhost:3001/api/code-reviewer',
    }),
  });

  if (!response.ok) {
    throw new Error(`Registration failed: ${await response.text()}`);
  }

  const result = await response.json();
  console.log('Agent registered successfully:', result);
}

registerAgent().catch(console.error);
```

```python
# register_agent.py
import asyncio
import json
import os
from pathlib import Path

import aiohttp


async def register_agent() -> None:
    """Register the code review agent with the platform."""
    # Load agent configuration
    config_path = Path(".claude/agents/code-reviewer.json")
    with config_path.open() as f:
        config = json.load(f)

    # Prepare registration payload
    payload = {
        "name": config["name"],
        "description": config["description"],
        "role": config["role"],
        "layer": config["layer"],
        "model": config["model"],
        "config": config,
        "endpoint": "http://localhost:8000/api/code-reviewer",
    }

    # Register with platform
    api_url = "http://localhost:8000/api/agents/register"
    api_key = os.getenv("API_KEY")

    async with aiohttp.ClientSession() as session:
        async with session.post(
            api_url,
            json=payload,
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {api_key}",
            },
        ) as response:
            if response.status != 200:
                text = await response.text()
                raise Exception(f"Registration failed: {text}")

            result = await response.json()
            print(f"Agent registered successfully: {result}")


if __name__ == "__main__":
    asyncio.run(register_agent())
```

### Environment Configuration

Create a `.env` file for your agent:

```bash
# Azure OpenAI Configuration
AZURE_OPENAI_API_KEY=your_api_key_here
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com
AZURE_OPENAI_DEPLOYMENT=gpt-4
AZURE_OPENAI_API_VERSION=2024-02-01

# Agent Configuration
AGENT_NAME=code-reviewer
AGENT_PORT=3001
LOG_LEVEL=info

# Platform Configuration
PLATFORM_API_URL=http://localhost:8000
API_KEY=your_platform_api_key

# Tool Integrations
ESLINT_ENABLED=true
PYLINT_ENABLED=true
SONAR_API_KEY=your_sonar_key
SNYK_API_KEY=your_snyk_key

# Azure Resources
APPINSIGHTS_CONNECTION_STRING=your_connection_string
REDIS_CONNECTION_STRING=your_redis_connection
```

### Configuration Best Practices

- **Never Commit Secrets**: Use `.env` files and add them to `.gitignore`
- **Use Azure Key Vault**: For production, store secrets in Key Vault
- **Environment-Specific**: Maintain separate configs for dev/staging/prod
- **Validation**: Validate all environment variables on startup

---

## Step 4: Test Your Agent

### Unit Testing (TypeScript)

Create `src/agents/code-reviewer/__tests__/agent.test.ts`:

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { CodeReviewAgent } from '../agent';
import { AgentConfig } from '@/types/agents';
import { ToolRegistry } from '@/services/tool-registry';

describe('CodeReviewAgent', () => {
  let agent: CodeReviewAgent;
  let mockConfig: AgentConfig;
  let mockToolRegistry: ToolRegistry;

  beforeEach(() => {
    mockConfig = {
      name: 'code-reviewer',
      role: 'Code Quality Specialist',
      model: 'claude-sonnet-4',
      expertise: ['Static analysis', 'Security'],
      capabilities: ['Analyze code', 'Detect vulnerabilities'],
      reviewLevels: {
        standard: {
          checks: ['syntax', 'security', 'quality'],
        },
      },
    };

    mockToolRegistry = {
      execute: vi.fn().mockResolvedValue({
        success: true,
        issues: [],
      }),
    } as any;

    agent = new CodeReviewAgent(mockConfig, mockToolRegistry);
  });

  describe('initialization', () => {
    it('should initialize with correct configuration', () => {
      expect(agent).toBeDefined();
      expect(agent.config).toEqual(mockConfig);
    });

    it('should generate correct system prompt', () => {
      const prompt = agent.getSystemPrompt();

      expect(prompt).toContain('Code Quality Specialist');
      expect(prompt).toContain('Static analysis');
      expect(prompt).toContain('Security');
    });
  });

  describe('code review', () => {
    it('should successfully review clean code', async () => {
      const message = {
        content: 'Please review this code',
        sender: 'user',
        context: {
          code: 'function add(a, b) { return a + b; }',
          language: 'javascript',
          reviewLevel: 'standard',
        },
        timestamp: new Date(),
      };

      const response = await agent.process(message);

      expect(response.success).toBe(true);
      expect(response.content).toContain('Code Review Report');
      expect(response.metadata.language).toBe('javascript');
    });

    it('should detect issues in problematic code', async () => {
      const message = {
        content: 'Review this code',
        sender: 'user',
        context: {
          code: 'eval(userInput)', // Dangerous code
          language: 'javascript',
        },
        timestamp: new Date(),
      };

      const response = await agent.process(message);

      expect(response.success).toBe(true);
      expect(response.metadata.issueCount).toBeGreaterThan(0);
    });

    it('should handle missing code gracefully', async () => {
      const message = {
        content: 'Review code',
        sender: 'user',
        context: {},
        timestamp: new Date(),
      };

      const response = await agent.process(message);

      expect(response.success).toBe(false);
      expect(response.content).toContain('No code provided');
    });
  });

  describe('metrics calculation', () => {
    it('should calculate correct lines of code', () => {
      const code = `
        function test() {
          return 42;
        }
      `;

      const metrics = agent['calculateMetrics'](code, []);

      expect(metrics.linesOfCode).toBeGreaterThan(0);
    });

    it('should calculate complexity for complex code', () => {
      const code = `
        function complex(x) {
          if (x > 0) {
            while (x > 10) {
              for (let i = 0; i < x; i++) {
                if (i % 2) {
                  return i;
                }
              }
            }
          }
          return x;
        }
      `;

      const complexity = agent['calculateComplexity'](code);

      expect(complexity).toBeGreaterThan(5);
    });
  });

  describe('issue prioritization', () => {
    it('should prioritize critical issues first', () => {
      const issues = [
        { severity: 'low', location: { line: 1 } },
        { severity: 'critical', location: { line: 10 } },
        { severity: 'medium', location: { line: 5 } },
      ] as any;

      const prioritized = agent['prioritizeIssues'](issues);

      expect(prioritized[0].severity).toBe('critical');
      expect(prioritized[prioritized.length - 1].severity).toBe('low');
    });
  });

  describe('cleanup', () => {
    it('should cleanup resources on shutdown', async () => {
      await agent.shutdown();

      expect(agent.getHistoryLength()).toBe(0);
    });
  });
});
```

### Unit Testing (Python)

Create `src/agents/code_reviewer/tests/test_agent.py`:

```python
"""Unit tests for CodeReviewAgent."""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch

from meta_agents.agent_config import AgentConfig, AgentRole, ToolType, ToolConfig
from agents.code_reviewer.agent import CodeReviewAgent, CodeIssue, CodeLocation
from meta_agents.agent_tools import DefaultToolRegistry, ToolResult
from meta_agents.base_agent import MetaAgentMessage


@pytest.fixture
def agent_config():
    """Create test agent configuration."""
    from pydantic import SecretStr
    from meta_agents.agent_config import AzureOpenAIConfig

    return AgentConfig(
        name="code-reviewer",
        role=AgentRole.VALIDATOR,
        description="Test code reviewer",
        azure_openai=AzureOpenAIConfig(
            api_key=SecretStr("test-key"),
            azure_endpoint="https://test.openai.azure.com",
            deployment_name="gpt-4",
        ),
        tools=[
            ToolConfig(tool_type=ToolType.STATIC_ANALYSIS, enabled=True),
        ],
        metadata={
            "expertise": ["Static analysis", "Security"],
            "capabilities": ["Analyze code", "Detect vulnerabilities"],
            "reviewLevels": {
                "standard": {
                    "checks": ["syntax", "security", "quality"],
                },
            },
        },
    )


@pytest.fixture
def tool_registry():
    """Create mock tool registry."""
    registry = DefaultToolRegistry()

    # Mock static analysis tool
    mock_tool = AsyncMock()
    mock_tool.execute = AsyncMock(return_value=ToolResult(
        success=True,
        output=[],
    ))

    registry.register_tool(ToolType.STATIC_ANALYSIS, mock_tool)

    return registry


@pytest.mark.unit
@pytest.mark.asyncio
class TestCodeReviewAgent:
    """Test suite for CodeReviewAgent."""

    async def test_initialization(self, agent_config, tool_registry):
        """Should initialize agent correctly."""
        agent = CodeReviewAgent(agent_config, tool_registry)

        assert agent.config == agent_config
        assert agent.tool_registry == tool_registry

    async def test_system_prompt_generation(self, agent_config, tool_registry):
        """Should generate correct system prompt."""
        agent = CodeReviewAgent(agent_config, tool_registry)
        prompt = agent.get_system_prompt()

        assert "Code Quality Specialist" in prompt or "VALIDATOR" in prompt
        assert "Static analysis" in prompt
        assert "Security" in prompt

    async def test_review_clean_code(self, agent_config, tool_registry):
        """Should successfully review clean code."""
        agent = CodeReviewAgent(agent_config, tool_registry)

        with patch.object(agent, 'call_llm', new_callable=AsyncMock) as mock_llm:
            mock_llm.return_value = "No issues found"

            message = MetaAgentMessage(
                content="Review this code",
                context={
                    "code": "def add(a, b):\n    return a + b",
                    "language": "python",
                    "review_level": "standard",
                },
            )

            response = await agent.process(message)

            assert response.success
            assert "Code Review Report" in response.content
            assert response.metadata["language"] == "python"

    async def test_review_without_code(self, agent_config, tool_registry):
        """Should handle missing code gracefully."""
        agent = CodeReviewAgent(agent_config, tool_registry)

        message = MetaAgentMessage(
            content="Review code",
            context={},
        )

        response = await agent.process(message)

        assert not response.success
        assert "No code provided" in response.content

    async def test_calculate_metrics(self, agent_config, tool_registry):
        """Should calculate code metrics correctly."""
        agent = CodeReviewAgent(agent_config, tool_registry)

        code = """
def test():
    return 42
"""

        metrics = agent.calculate_metrics(code, [])

        assert metrics.lines_of_code > 0
        assert 0 <= metrics.maintainability_index <= 100
        assert metrics.complexity >= 1

    async def test_calculate_complexity(self, agent_config, tool_registry):
        """Should calculate cyclomatic complexity."""
        agent = CodeReviewAgent(agent_config, tool_registry)

        complex_code = """
def complex(x):
    if x > 0:
        while x > 10:
            for i in range(x):
                if i % 2:
                    return i
    return x
"""

        complexity = agent.calculate_complexity(complex_code)

        assert complexity > 3

    async def test_prioritize_issues(self, agent_config, tool_registry):
        """Should prioritize critical issues first."""
        agent = CodeReviewAgent(agent_config, tool_registry)

        issues = [
            CodeIssue(
                location=CodeLocation(file="test.py", line=1, column=1),
                severity="low",
                category="style",
                description="Minor issue",
                suggestion="Fix it",
            ),
            CodeIssue(
                location=CodeLocation(file="test.py", line=10, column=1),
                severity="critical",
                category="security",
                description="Critical issue",
                suggestion="Fix immediately",
            ),
            CodeIssue(
                location=CodeLocation(file="test.py", line=5, column=1),
                severity="medium",
                category="quality",
                description="Medium issue",
                suggestion="Fix soon",
            ),
        ]

        prioritized = agent.prioritize_issues(issues)

        assert prioritized[0].severity == "critical"
        assert prioritized[-1].severity == "low"

    async def test_generate_summary(self, agent_config, tool_registry):
        """Should generate accurate review summary."""
        agent = CodeReviewAgent(agent_config, tool_registry)

        issues = [
            CodeIssue(
                location=CodeLocation(file="test.py", line=1, column=1),
                severity="critical",
                category="security",
                description="SQL injection",
                suggestion="Use parameterized queries",
            ),
            CodeIssue(
                location=CodeLocation(file="test.py", line=5, column=1),
                severity="high",
                category="security",
                description="XSS vulnerability",
                suggestion="Sanitize input",
            ),
        ]

        metrics = agent.calculate_metrics("def test():\n    pass", issues)
        summary = agent.generate_summary(issues, metrics)

        assert summary.severity_counts["critical"] == 1
        assert summary.severity_counts["high"] == 1
        assert summary.recommendation == "reject"
        assert summary.overall_score < 100

    async def test_parse_ai_response(self, agent_config, tool_registry):
        """Should parse AI response into issues."""
        agent = CodeReviewAgent(agent_config, tool_registry)

        ai_response = """
SEVERITY: critical
LOCATION: 10:5
CATEGORY: security
DESCRIPTION: SQL injection vulnerability detected
SUGGESTION: Use parameterized queries instead of string concatenation
---
SEVERITY: medium
LOCATION: 15:10
CATEGORY: quality
DESCRIPTION: Function is too complex
SUGGESTION: Break down into smaller functions
---
"""

        issues = agent.parse_ai_response(ai_response)

        assert len(issues) == 2
        assert issues[0].severity == "critical"
        assert issues[1].severity == "medium"
        assert issues[0].location.line == 10

    async def test_cleanup_on_shutdown(self, agent_config, tool_registry):
        """Should cleanup resources on shutdown."""
        agent = CodeReviewAgent(agent_config, tool_registry)

        # Add some history
        message = MetaAgentMessage(content="Test", context={"code": "test"})
        with patch.object(agent, 'call_llm', new_callable=AsyncMock):
            await agent.process(message)

        # Shutdown
        await agent.shutdown()

        # History should be cleared
        assert agent.get_history_length() == 0


@pytest.mark.integration
@pytest.mark.asyncio
class TestCodeReviewAgentIntegration:
    """Integration tests for CodeReviewAgent."""

    async def test_end_to_end_review(self, agent_config, tool_registry):
        """Should perform end-to-end code review."""
        agent = CodeReviewAgent(agent_config, tool_registry)

        # Mock LLM call
        with patch.object(agent, 'call_llm', new_callable=AsyncMock) as mock_llm:
            mock_llm.return_value = """
SEVERITY: high
LOCATION: 1:1
CATEGORY: security
DESCRIPTION: Using eval() is dangerous
SUGGESTION: Use a safer alternative like ast.literal_eval()
---
"""

            message = MetaAgentMessage(
                content="Review this code for security issues",
                context={
                    "code": "result = eval(user_input)",
                    "language": "python",
                    "review_level": "standard",
                },
            )

            response = await agent.process(message)

            assert response.success
            assert "Code Review Report" in response.content
            assert response.metadata["issue_count"] > 0
            assert "eval()" in response.content or "security" in response.content.lower()
```

### Integration Testing

Create `tests/integration/test_agent_workflow.ts`:

```typescript
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { CodeReviewAgent } from '@/agents/code-reviewer/agent';
import { AgentOrchestrator } from '@/services/orchestrator';

describe('Agent Integration Tests', () => {
  let orchestrator: AgentOrchestrator;
  let agentId: string;

  beforeAll(async () => {
    // Initialize orchestrator with test configuration
    orchestrator = new AgentOrchestrator({
      apiUrl: 'http://localhost:8000',
      apiKey: process.env.TEST_API_KEY,
    });

    // Register test agent
    const response = await orchestrator.registerAgent({
      name: 'test-code-reviewer',
      type: 'code-reviewer',
      config: {
        /* ... */
      },
    });

    agentId = response.agentId;
  });

  afterAll(async () => {
    // Cleanup: unregister agent
    await orchestrator.unregisterAgent(agentId);
  });

  it('should communicate with other agents', async () => {
    // Send task to agent
    const response = await orchestrator.sendMessage(agentId, {
      content: 'Review this code and coordinate with security-specialist if vulnerabilities found',
      context: {
        code: 'eval(userInput)',
        language: 'javascript',
      },
    });

    expect(response.success).toBe(true);

    // Check if agent coordinated with security specialist
    const interactions = await orchestrator.getAgentInteractions(agentId);
    expect(interactions.some(i => i.targetAgent === 'security-specialist')).toBe(true);
  });

  it('should handle workflow orchestration', async () => {
    // Create workflow with multiple agents
    const workflowId = await orchestrator.createWorkflow({
      steps: [
        { agent: 'code-reviewer', action: 'review' },
        { agent: 'test-engineer', action: 'generate-tests' },
        { agent: 'devops-automator', action: 'deploy' },
      ],
    });

    // Execute workflow
    const result = await orchestrator.executeWorkflow(workflowId, {
      code: 'function add(a, b) { return a + b; }',
    });

    expect(result.success).toBe(true);
    expect(result.completedSteps).toBe(3);
  });
});
```

### Running Tests

```bash
# TypeScript tests
npm test

# Python tests
pytest tests/ -v

# With coverage
npm run test:coverage
pytest tests/ --cov=agents --cov-report=html

# Integration tests only
npm run test:integration
pytest tests/integration/ -v
```

---

## Step 5: Deploy to Production

### Docker Configuration

Create `Dockerfile` for your agent:

```dockerfile
# Multi-stage build for TypeScript agent
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY tsconfig.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY src/ ./src/

# Build application
RUN npm run build

# Production stage
FROM node:20-alpine

WORKDIR /app

# Install production dependencies only
COPY package*.json ./
RUN npm ci --production && npm cache clean --force

# Copy built application
COPY --from=builder /app/dist ./dist

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

USER nodejs

# Expose port
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3001/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start application
CMD ["node", "dist/index.js"]
```

For Python agents:

```dockerfile
FROM python:3.12-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt ./

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY src/ ./src/
COPY .claude/ ./.claude/

# Create non-root user
RUN useradd -m -u 1001 appuser && chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 8001

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import requests; requests.get('http://localhost:8001/health')"

# Run application
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8001"]
```

### Azure Container Apps Deployment

Create `deploy/azure/container-app.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: code-reviewer-agent
  namespace: agent-studio
spec:
  replicas: 2
  selector:
    matchLabels:
      app: code-reviewer
  template:
    metadata:
      labels:
        app: code-reviewer
        version: v1
    spec:
      containers:
        - name: agent
          image: youracr.azurecr.io/code-reviewer:latest
          ports:
            - containerPort: 3001
              protocol: TCP
          env:
            - name: AZURE_OPENAI_API_KEY
              valueFrom:
                secretKeyRef:
                  name: azure-openai-secrets
                  key: api-key
            - name: AZURE_OPENAI_ENDPOINT
              valueFrom:
                configMapKeyRef:
                  name: agent-config
                  key: openai-endpoint
            - name: APPINSIGHTS_CONNECTION_STRING
              valueFrom:
                secretKeyRef:
                  name: monitoring-secrets
                  key: appinsights-connection-string
            - name: LOG_LEVEL
              value: "info"
          resources:
            requests:
              memory: "512Mi"
              cpu: "250m"
            limits:
              memory: "1Gi"
              cpu: "500m"
          livenessProbe:
            httpGet:
              path: /health
              port: 3001
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /ready
              port: 3001
            initialDelaySeconds: 10
            periodSeconds: 5
      imagePullSecrets:
        - name: acr-credentials
---
apiVersion: v1
kind: Service
metadata:
  name: code-reviewer-service
  namespace: agent-studio
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 3001
      protocol: TCP
  selector:
    app: code-reviewer
```

### Deployment Script

Create `scripts/deploy.sh`:

```bash
#!/bin/bash
set -e

# Configuration
RESOURCE_GROUP="agent-studio-rg"
ACR_NAME="agentstudioacr"
IMAGE_NAME="code-reviewer"
VERSION="${1:-latest}"
CONTAINER_APP="code-reviewer-app"
ENVIRONMENT="prod"

echo "Building Docker image..."
docker build -t ${IMAGE_NAME}:${VERSION} .

echo "Tagging image for ACR..."
docker tag ${IMAGE_NAME}:${VERSION} ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${VERSION}

echo "Logging into ACR..."
az acr login --name ${ACR_NAME}

echo "Pushing image to ACR..."
docker push ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${VERSION}

echo "Deploying to Azure Container Apps..."
az containerapp update \
  --name ${CONTAINER_APP} \
  --resource-group ${RESOURCE_GROUP} \
  --image ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${VERSION} \
  --set-env-vars \
    "ENVIRONMENT=${ENVIRONMENT}" \
    "VERSION=${VERSION}"

echo "Deployment complete!"
echo "Checking deployment status..."
az containerapp show \
  --name ${CONTAINER_APP} \
  --resource-group ${RESOURCE_GROUP} \
  --query "properties.latestRevisionName" \
  --output tsv
```

### CI/CD Pipeline (GitHub Actions)

Create `.github/workflows/deploy-agent.yml`:

```yaml
name: Deploy Code Reviewer Agent

on:
  push:
    branches:
      - main
    paths:
      - 'src/agents/code-reviewer/**'
      - '.github/workflows/deploy-agent.yml'
  workflow_dispatch:

env:
  ACR_NAME: agentstudioacr
  IMAGE_NAME: code-reviewer
  RESOURCE_GROUP: agent-studio-rg
  CONTAINER_APP: code-reviewer-app

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to Azure
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Log in to ACR
        run: az acr login --name ${{ env.ACR_NAME }}

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: |
            ${{ env.ACR_NAME }}.azurecr.io/${{ env.IMAGE_NAME }}:${{ github.sha }}
            ${{ env.ACR_NAME }}.azurecr.io/${{ env.IMAGE_NAME }}:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: Deploy to Container Apps
        run: |
          az containerapp update \
            --name ${{ env.CONTAINER_APP }} \
            --resource-group ${{ env.RESOURCE_GROUP }} \
            --image ${{ env.ACR_NAME }}.azurecr.io/${{ env.IMAGE_NAME }}:${{ github.sha }}

      - name: Run smoke tests
        run: |
          ENDPOINT=$(az containerapp show \
            --name ${{ env.CONTAINER_APP }} \
            --resource-group ${{ env.RESOURCE_GROUP }} \
            --query properties.configuration.ingress.fqdn \
            --output tsv)

          curl -f https://${ENDPOINT}/health || exit 1

      - name: Notify deployment
        if: success()
        run: echo "Deployment successful!"
```

### Monitoring Setup

Create Application Insights monitoring:

```typescript
// monitoring.ts
import { ApplicationInsights } from '@azure/monitor-opentelemetry';

export function setupMonitoring() {
  const insights = new ApplicationInsights({
    connectionString: process.env.APPINSIGHTS_CONNECTION_STRING,
  });

  insights.start();

  // Custom metrics
  insights.trackMetric({
    name: 'code-reviews-completed',
    value: 1,
  });

  insights.trackEvent({
    name: 'agent-started',
    properties: {
      agentName: 'code-reviewer',
      version: process.env.VERSION,
    },
  });
}
```

---

## Advanced Topics

### Multi-Agent Coordination

Agents can communicate with each other through the platform's messaging system:

```typescript
// In your agent implementation
async coordinateWithAgent(
  targetAgent: string,
  message: string,
  context: Record<string, any>
): Promise<void> {
  const response = await fetch(`${this.platformUrl}/api/agents/${targetAgent}/message`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${this.apiKey}`,
    },
    body: JSON.stringify({
      fromAgent: this.config.name,
      message,
      context,
    }),
  });

  const result = await response.json();
  this.logger.info('Coordinated with agent', { targetAgent, result });
}
```

Example coordination scenario:

```typescript
// Code reviewer coordinates with security specialist
if (hasCriticalSecurityIssues) {
  await this.coordinateWithAgent(
    'security-specialist',
    'Critical security vulnerabilities detected in code review',
    {
      vulnerabilities: criticalIssues,
      code: originalCode,
      language: language,
    }
  );
}
```

### Error Handling and Retry Logic

Implement robust error handling with exponential backoff:

```typescript
async executeWithRetry<T>(
  operation: () => Promise<T>,
  maxRetries: number = 3
): Promise<T> {
  let lastError: Error;

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await operation();
    } catch (error) {
      lastError = error as Error;
      this.logger.warn('Operation failed, retrying', {
        attempt,
        maxRetries,
        error: error.message,
      });

      if (attempt < maxRetries) {
        const delay = Math.min(1000 * Math.pow(2, attempt), 10000);
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
  }

  throw lastError!;
}
```

### Performance Optimization

#### Caching

Implement caching for expensive operations:

```typescript
import { createClient } from 'redis';

class CachedAgent extends CodeReviewAgent {
  private redis: ReturnType<typeof createClient>;

  async reviewCodeCached(code: string, language: string): Promise<CodeReviewResult> {
    const cacheKey = `review:${this.hashCode(code)}:${language}`;

    // Check cache
    const cached = await this.redis.get(cacheKey);
    if (cached) {
      this.logger.info('Cache hit for code review');
      return JSON.parse(cached);
    }

    // Perform review
    const result = await this.reviewCode(code, language, 'standard');

    // Cache result (24 hours)
    await this.redis.setEx(cacheKey, 86400, JSON.stringify(result));

    return result;
  }

  private hashCode(str: string): string {
    return crypto.createHash('sha256').update(str).digest('hex');
  }
}
```

#### Batching

Process multiple requests in batches:

```typescript
class BatchProcessor {
  private queue: Array<{ code: string; resolve: Function; reject: Function }> = [];
  private processing = false;

  async addToQueue(code: string): Promise<CodeReviewResult> {
    return new Promise((resolve, reject) => {
      this.queue.push({ code, resolve, reject });
      this.processBatch();
    });
  }

  private async processBatch() {
    if (this.processing || this.queue.length === 0) return;

    this.processing = true;
    const batch = this.queue.splice(0, 10); // Process 10 at a time

    try {
      const results = await Promise.all(
        batch.map(item => this.reviewCode(item.code))
      );

      batch.forEach((item, index) => {
        item.resolve(results[index]);
      });
    } catch (error) {
      batch.forEach(item => item.reject(error));
    } finally {
      this.processing = false;
      if (this.queue.length > 0) {
        this.processBatch();
      }
    }
  }
}
```

#### Async Processing

Handle long-running operations asynchronously:

```typescript
async reviewCodeAsync(code: string): Promise<{ jobId: string }> {
  const jobId = crypto.randomUUID();

  // Store job in database with status "pending"
  await this.db.jobs.create({
    id: jobId,
    status: 'pending',
    input: { code },
  });

  // Process in background
  this.processInBackground(jobId, code);

  return { jobId };
}

private async processInBackground(jobId: string, code: string) {
  try {
    const result = await this.reviewCode(code, 'unknown', 'standard');

    await this.db.jobs.update(jobId, {
      status: 'completed',
      result,
    });
  } catch (error) {
    await this.db.jobs.update(jobId, {
      status: 'failed',
      error: error.message,
    });
  }
}
```

---

## Troubleshooting

### Common Issues and Solutions

#### Issue: Agent Not Receiving Messages

**Symptoms**: Agent is registered but doesn't receive any messages

**Solutions**:
1. Check agent registration status:
   ```bash
   curl http://localhost:8000/api/agents/code-reviewer
   ```
2. Verify endpoint is accessible:
   ```bash
   curl http://localhost:3001/health
   ```
3. Check platform logs for routing errors
4. Ensure agent is in "active" status

#### Issue: High Memory Usage

**Symptoms**: Agent container uses excessive memory

**Solutions**:
1. Clear conversation history periodically:
   ```typescript
   if (this.conversationHistory.length > 100) {
     this.conversationHistory = this.conversationHistory.slice(-50);
   }
   ```
2. Implement streaming for large responses
3. Use pagination for large result sets
4. Increase container memory limits

#### Issue: Slow Response Times

**Symptoms**: Agent takes too long to respond

**Solutions**:
1. Implement caching (see Performance Optimization)
2. Use async processing for long operations
3. Optimize LLM prompts (reduce token count)
4. Add response time monitoring:
   ```typescript
   const start = Date.now();
   const result = await this.operation();
   const duration = Date.now() - start;
   this.logger.info('Operation completed', { duration });
   ```

#### Issue: Authentication Failures

**Symptoms**: "401 Unauthorized" or "403 Forbidden" errors

**Solutions**:
1. Verify API key is correct:
   ```bash
   echo $API_KEY
   ```
2. Check Key Vault permissions
3. Ensure managed identity is properly configured
4. Verify token expiration settings

#### Issue: Agent Crashes on Startup

**Symptoms**: Container restarts repeatedly

**Solutions**:
1. Check environment variables:
   ```bash
   kubectl get pod <pod-name> -o yaml
   ```
2. Review startup logs:
   ```bash
   kubectl logs <pod-name>
   ```
3. Verify required secrets exist
4. Check resource limits (CPU/memory)

---

## Next Steps

Congratulations! You've built and deployed your first custom agent. Here are some next steps:

### Expand Agent Capabilities

1. **Add More Tools**: Integrate additional static analysis tools (SonarQube, CodeQL)
2. **Multi-Language Support**: Add support for more programming languages
3. **Custom Rules**: Create organization-specific linting rules
4. **AI Enhancements**: Fine-tune prompts for better accuracy

### Advanced Tutorials

- [Building Multi-Agent Workflows](./multi-agent-workflows.md)
- [Agent Memory and Context Management](./agent-memory.md)
- [Custom Tool Development](./custom-tools.md)
- [Agent Performance Tuning](./performance-tuning.md)
- [Security Best Practices for Agents](./agent-security.md)

### Community Resources

- [Agent Studio Documentation](../README.md)
- [API Reference](../api/README.md)
- [Example Agents](../../examples/agents/)
- [Community Forum](https://community.agentstudio.dev)
- [GitHub Discussions](https://github.com/your-org/agent-studio/discussions)

### Get Help

- **Documentation**: Check the [full documentation](../README.md)
- **Examples**: Review [example implementations](../../examples/)
- **Support**: Open an issue on [GitHub](https://github.com/your-org/agent-studio/issues)
- **Community**: Join our [Discord server](https://discord.gg/agentstudio)

---

## Summary

You've learned how to:

- Define agent capabilities and configuration
- Implement agent logic in TypeScript or Python
- Register agents with the platform
- Write comprehensive tests (unit and integration)
- Deploy agents to Azure Container Apps
- Monitor and optimize agent performance
- Handle errors and implement retry logic
- Coordinate with other agents

Your Code Review Agent is now part of the meta-agent ecosystem, capable of analyzing code quality, detecting security issues, and collaborating with other specialized agents to deliver comprehensive software development automation.

Happy building!
