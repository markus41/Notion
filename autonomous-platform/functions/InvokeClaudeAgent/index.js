/**
 * Invoke Claude Agent Activity Function
 *
 * Establishes scalable AI agent execution for autonomous workflows.
 * Invokes specialized Claude agents (@build-architect, @research-coordinator, etc.)
 * with context and task specifications, then returns structured results.
 *
 * This solution is designed to support multi-agent orchestration patterns where
 * different specialists execute in parallel or sequentially based on workflow needs.
 *
 * Best for: Organizations requiring AI-powered automation with specialized expertise
 * for architecture design, research coordination, viability assessment, and pattern application.
 */

const axios = require('axios');

/**
 * Agent Configuration Registry
 *
 * Establishes agent-specific settings including context requirements,
 * timeout thresholds, and output format specifications.
 */
const AGENT_CONFIG = {
  'build-architect': {
    systemPrompt: 'You are a senior software architect specializing in Azure and Microsoft ecosystem solutions. Design scalable, production-ready architectures with clear technical specifications.',
    timeout: 900000, // 15 minutes
    temperature: 0.7,
    maxTokens: 4000
  },
  'research-coordinator': {
    systemPrompt: 'You are a research coordinator specializing in feasibility studies and viability assessments. Structure investigations with clear hypotheses, methodologies, and actionable findings.',
    timeout: 900000,
    temperature: 0.5,
    maxTokens: 3000
  },
  'market-researcher': {
    systemPrompt: 'You are a market research analyst. Assess market opportunity, competitive landscape, trends, and demand indicators. Provide quantitative scores (0-100).',
    timeout: 900000,
    temperature: 0.5,
    maxTokens: 2500
  },
  'technical-analyst': {
    systemPrompt: 'You are a technical feasibility analyst. Evaluate implementation complexity, technology stack alignment (Microsoft-first), and technical risks. Provide quantitative scores (0-100).',
    timeout: 900000,
    temperature: 0.5,
    maxTokens: 2500
  },
  'cost-analyst': {
    systemPrompt: 'You are a financial analyst specializing in software and infrastructure costs. Calculate build costs, operational costs, ROI projections. Provide quantitative scores (0-100, lower cost = higher score).',
    timeout: 900000,
    temperature: 0.3,
    maxTokens: 2500
  },
  'risk-assessor': {
    systemPrompt: 'You are a risk management specialist. Identify technical, business, and operational risks with likelihood assessments and mitigation strategies. Provide quantitative scores (0-100, lower risk = higher score).',
    timeout: 900000,
    temperature: 0.5,
    maxTokens: 2500
  },
  'viability-assessor': {
    systemPrompt: 'You are a viability assessment expert. Evaluate effort vs. impact, feasibility, and strategic alignment. Provide clear go/no-go recommendations with detailed justification.',
    timeout: 900000,
    temperature: 0.5,
    maxTokens: 3000
  }
};

/**
 * Main Activity Function
 *
 * @param {object} context - Durable Functions activity context
 * @returns {object} Agent response with structured results
 */
module.exports = async function (context) {
  const input = context.bindings.context;
  const { agent, task, includePatternMatching = false, outputFormat = 'json', timeout } = input;

  context.log(`Invoking agent: ${agent}`, {
    taskLength: task?.length || 0,
    includePatternMatching,
    outputFormat
  });

  try {
    // Validate agent exists in registry
    const agentConfig = AGENT_CONFIG[agent];
    if (!agentConfig) {
      throw new Error(`Unknown agent: ${agent}. Available agents: ${Object.keys(AGENT_CONFIG).join(', ')}`);
    }

    // Construct agent invocation payload
    const prompt = buildAgentPrompt(task, includePatternMatching, outputFormat, agentConfig);

    // Invoke Claude API (via Azure OpenAI or Anthropic direct)
    // NOTE: This assumes Azure OpenAI endpoint configured in Key Vault
    const response = await invokeClaudeAPI(prompt, agentConfig, timeout || agentConfig.timeout);

    // Parse response based on output format
    const parsedResponse = parseAgentResponse(response, outputFormat);

    context.log(`Agent ${agent} completed successfully`, {
      responseLength: JSON.stringify(parsedResponse).length,
      score: parsedResponse.score || 'N/A'
    });

    return parsedResponse;

  } catch (error) {
    context.log.error(`Agent ${agent} invocation failed`, {
      error: error.message,
      stack: error.stack
    });

    // Return error response with structured format
    return {
      success: false,
      agent,
      error: error.message,
      timestamp: new Date().toISOString()
    };
  }
};

/**
 * Build Agent Prompt
 *
 * Constructs comprehensive prompt with system context, task specification,
 * pattern matching context (if enabled), and output format requirements.
 *
 * @param {string} task - User task specification
 * @param {boolean} includePatternMatching - Whether to include pattern context
 * @param {string} outputFormat - Expected output format (json, markdown, structured)
 * @param {object} agentConfig - Agent-specific configuration
 * @returns {string} Complete prompt for Claude API
 */
function buildAgentPrompt(task, includePatternMatching, outputFormat, agentConfig) {
  let prompt = `${agentConfig.systemPrompt}\n\n`;

  // Add task specification
  prompt += `TASK:\n${task}\n\n`;

  // Add pattern matching context if enabled
  if (includePatternMatching) {
    prompt += `PATTERN CONTEXT:\n`;
    prompt += `You have access to a pattern library of previously successful builds. When designing architecture, consider:\n`;
    prompt += `- Authentication patterns (Azure AD, Service Principal, API Key)\n`;
    prompt += `- Storage patterns (Cosmos DB, SQL, Blob Storage)\n`;
    prompt += `- API patterns (REST, GraphQL, webhooks)\n`;
    prompt += `- Deployment patterns (App Service, Functions, Container Apps)\n`;
    prompt += `Apply learned patterns where appropriate and suggest new patterns for novel architectures.\n\n`;
  }

  // Add output format requirements
  prompt += `OUTPUT FORMAT:\n`;
  if (outputFormat === 'json' || outputFormat === 'structured') {
    prompt += `Respond with valid JSON containing:\n`;
    prompt += `{\n`;
    prompt += `  "summary": "Brief executive summary (2-3 sentences)",\n`;
    prompt += `  "details": "Detailed analysis or design",\n`;
    prompt += `  "score": 0-100 (if applicable, otherwise omit),\n`;
    prompt += `  "recommendations": ["actionable recommendation 1", "..."],\n`;
    prompt += `  "risks": ["identified risk 1", "..."] (if applicable),\n`;
    prompt += `  "estimatedCost": number (monthly $ if applicable, otherwise omit),\n`;
    prompt += `  "estimatedEffort": "XS|S|M|L|XL" (if applicable),\n`;
    prompt += `  "confidence": "high|medium|low"\n`;
    prompt += `}\n`;
  } else if (outputFormat === 'markdown') {
    prompt += `Respond with well-structured markdown including:\n`;
    prompt += `- Clear headings and sections\n`;
    prompt += `- Bullet points for lists\n`;
    prompt += `- Code blocks for technical specifications\n`;
    prompt += `- Tables for comparisons\n`;
  }

  prompt += `\nProvide your response now:`;

  return prompt;
}

/**
 * Invoke Claude API
 *
 * Establishes connection to Claude API (Azure OpenAI or Anthropic) and
 * executes agent invocation with retry logic and timeout handling.
 *
 * @param {string} prompt - Complete agent prompt
 * @param {object} agentConfig - Agent configuration with timeout and temperature
 * @param {number} timeout - Execution timeout in milliseconds
 * @returns {string} Raw API response
 */
async function invokeClaudeAPI(prompt, agentConfig, timeout) {
  // Retrieve Azure OpenAI endpoint and key from environment (via Key Vault references)
  const endpoint = process.env.AZURE_OPENAI_ENDPOINT || process.env.ANTHROPIC_API_ENDPOINT;
  const apiKey = process.env.AZURE_OPENAI_API_KEY || process.env.ANTHROPIC_API_KEY;

  if (!endpoint || !apiKey) {
    throw new Error('Claude API credentials not configured. Set AZURE_OPENAI_ENDPOINT and AZURE_OPENAI_API_KEY in Key Vault.');
  }

  // Determine API format (Azure OpenAI vs. Anthropic direct)
  const isAzureOpenAI = endpoint.includes('openai.azure.com');

  let requestConfig;
  if (isAzureOpenAI) {
    // Azure OpenAI format
    requestConfig = {
      url: `${endpoint}/openai/deployments/claude-sonnet-4-5/chat/completions?api-version=2024-10-01`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'api-key': apiKey
      },
      data: {
        messages: [
          { role: 'user', content: prompt }
        ],
        temperature: agentConfig.temperature,
        max_tokens: agentConfig.maxTokens
      },
      timeout
    };
  } else {
    // Anthropic direct format
    requestConfig = {
      url: `${endpoint}/v1/messages`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01'
      },
      data: {
        model: 'claude-sonnet-4-20250514',
        messages: [
          { role: 'user', content: prompt }
        ],
        temperature: agentConfig.temperature,
        max_tokens: agentConfig.maxTokens
      },
      timeout
    };
  }

  try {
    const response = await axios(requestConfig);

    // Extract content from response
    if (isAzureOpenAI) {
      return response.data.choices[0].message.content;
    } else {
      return response.data.content[0].text;
    }

  } catch (error) {
    if (error.code === 'ECONNABORTED') {
      throw new Error(`Agent invocation timeout after ${timeout}ms`);
    }
    throw new Error(`Claude API error: ${error.response?.data?.error?.message || error.message}`);
  }
}

/**
 * Parse Agent Response
 *
 * Extracts structured data from agent response based on requested output format.
 * Handles JSON parsing, markdown structure extraction, and error recovery.
 *
 * @param {string} response - Raw agent response
 * @param {string} outputFormat - Expected format (json, markdown, structured)
 * @returns {object} Parsed response object
 */
function parseAgentResponse(response, outputFormat) {
  if (outputFormat === 'json' || outputFormat === 'structured') {
    try {
      // Attempt to parse JSON from response
      // Handle cases where response includes markdown code blocks
      const jsonMatch = response.match(/```json\n([\s\S]*?)\n```/) || response.match(/\{[\s\S]*\}/);

      if (jsonMatch) {
        const jsonString = jsonMatch[1] || jsonMatch[0];
        return JSON.parse(jsonString);
      }

      // If no JSON found, return as text in structured format
      return {
        success: true,
        summary: response.substring(0, 200) + '...',
        details: response,
        confidence: 'medium'
      };

    } catch (error) {
      // JSON parse failed - return as text
      return {
        success: true,
        summary: 'Response could not be parsed as JSON',
        details: response,
        confidence: 'low',
        parseError: error.message
      };
    }
  } else {
    // Markdown or plain text format
    return {
      success: true,
      content: response,
      format: outputFormat
    };
  }
}
