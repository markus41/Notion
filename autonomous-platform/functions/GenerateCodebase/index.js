/**
 * Generate Codebase Activity Function
 *
 * Establishes AI-powered code generation from architecture specifications,
 * producing production-ready application code with comprehensive project structure.
 *
 * This solution is designed to support autonomous development workflows where
 * architecture designs translate directly into executable applications with
 * tests, documentation, and deployment configurations.
 *
 * Best for: Organizations requiring rapid prototyping capabilities that maintain
 * code quality standards while accelerating time-to-deployment through structured
 * AI-assisted development.
 */

const axios = require('axios');
const path = require('path');

/**
 * Technology Stack Templates
 *
 * Establishes project structure patterns for different technology stacks.
 */
const TECH_STACK_TEMPLATES = {
  'node-express-api': {
    language: 'javascript',
    framework: 'express',
    structure: [
      'src/server.js',
      'src/routes/index.js',
      'src/controllers/.gitkeep',
      'src/models/.gitkeep',
      'src/middleware/.gitkeep',
      'src/services/.gitkeep',
      'src/utils/.gitkeep',
      'tests/unit/.gitkeep',
      'tests/integration/.gitkeep',
      'package.json',
      'README.md',
      '.env.example',
      '.gitignore',
      'Dockerfile',
      '.github/workflows/ci-cd.yml'
    ]
  },
  'python-flask-api': {
    language: 'python',
    framework: 'flask',
    structure: [
      'app/__init__.py',
      'app/routes.py',
      'app/models.py',
      'app/services.py',
      'app/utils.py',
      'tests/__init__.py',
      'tests/test_routes.py',
      'requirements.txt',
      'setup.py',
      'README.md',
      '.env.example',
      '.gitignore',
      'Dockerfile',
      '.github/workflows/ci-cd.yml'
    ]
  },
  'dotnet-webapi': {
    language: 'csharp',
    framework: 'aspnetcore',
    structure: [
      'Controllers/HealthController.cs',
      'Models/.gitkeep',
      'Services/.gitkeep',
      'Program.cs',
      'appsettings.json',
      'appsettings.Development.json',
      'README.md',
      '.gitignore',
      'Dockerfile',
      '.github/workflows/ci-cd.yml'
    ]
  },
  'react-webapp': {
    language: 'javascript',
    framework: 'react',
    structure: [
      'src/App.jsx',
      'src/index.jsx',
      'src/components/.gitkeep',
      'src/pages/.gitkeep',
      'src/services/.gitkeep',
      'src/utils/.gitkeep',
      'public/index.html',
      'package.json',
      'README.md',
      '.env.example',
      '.gitignore',
      'Dockerfile'
    ]
  }
};

/**
 * Main Activity Function
 *
 * @param {object} context - Durable Functions activity context
 * @returns {object} Generated codebase with file paths and contents
 */
module.exports = async function (context) {
  const input = context.bindings.context;
  const { architecture, buildName, techStack } = input;

  context.log('Generating codebase from architecture', {
    buildName,
    techStack,
    architectureLength: JSON.stringify(architecture).length
  });

  try {
    // Determine technology stack from architecture or use provided
    const selectedStack = techStack || detectTechStack(architecture);
    const template = TECH_STACK_TEMPLATES[selectedStack];

    if (!template) {
      throw new Error(`Unsupported technology stack: ${selectedStack}. Available: ${Object.keys(TECH_STACK_TEMPLATES).join(', ')}`);
    }

    context.log('Using technology stack template', {
      stack: selectedStack,
      language: template.language,
      framework: template.framework
    });

    // Generate project structure files
    const generatedFiles = [];

    // Generate core application files using Claude
    const coreFiles = await generateCoreFiles(architecture, buildName, template, context);
    generatedFiles.push(...coreFiles);

    // Generate tests
    const testFiles = await generateTestFiles(architecture, buildName, template, context);
    generatedFiles.push(...testFiles);

    // Generate configuration files
    const configFiles = generateConfigurationFiles(buildName, template, architecture);
    generatedFiles.push(...configFiles);

    // Generate documentation
    const docFiles = generateDocumentationFiles(buildName, architecture, template);
    generatedFiles.push(...docFiles);

    // Generate deployment files
    const deploymentFiles = generateDeploymentFiles(architecture, template);
    generatedFiles.push(...deploymentFiles);

    context.log('Codebase generation complete', {
      totalFiles: generatedFiles.length,
      fileTypes: countFileTypes(generatedFiles)
    });

    return {
      success: true,
      buildName,
      techStack: selectedStack,
      files: generatedFiles,
      summary: {
        totalFiles: generatedFiles.length,
        coreFiles: coreFiles.length,
        testFiles: testFiles.length,
        configFiles: configFiles.length,
        docFiles: docFiles.length,
        deploymentFiles: deploymentFiles.length
      }
    };

  } catch (error) {
    context.log.error('Codebase generation failed', {
      error: error.message,
      buildName
    });

    return {
      success: false,
      error: error.message,
      buildName
    };
  }
};

/**
 * Detect Technology Stack
 *
 * Analyzes architecture design to determine appropriate technology stack.
 *
 * @param {object} architecture - Architecture specification
 * @returns {string} Technology stack identifier
 */
function detectTechStack(architecture) {
  const archText = JSON.stringify(architecture).toLowerCase();

  // Priority detection: Look for explicit framework mentions
  if (archText.includes('.net') || archText.includes('aspnetcore') || archText.includes('c#')) {
    return 'dotnet-webapi';
  }
  if (archText.includes('react') || archText.includes('frontend') || archText.includes('webapp')) {
    return 'react-webapp';
  }
  if (archText.includes('python') || archText.includes('flask')) {
    return 'python-flask-api';
  }
  if (archText.includes('node') || archText.includes('express') || archText.includes('javascript')) {
    return 'node-express-api';
  }

  // Default to Node.js API (most common for Azure Functions integration)
  return 'node-express-api';
}

/**
 * Generate Core Application Files
 *
 * Uses Claude AI to generate production-ready application code from architecture.
 *
 * @param {object} architecture - Architecture specification
 * @param {string} buildName - Build name
 * @param {object} template - Technology stack template
 * @param {object} context - Function context for logging
 * @returns {Array} Generated core files
 */
async function generateCoreFiles(architecture, buildName, template, context) {
  const endpoint = process.env.AZURE_OPENAI_ENDPOINT || process.env.ANTHROPIC_API_ENDPOINT;
  const apiKey = process.env.AZURE_OPENAI_API_KEY || process.env.ANTHROPIC_API_KEY;

  if (!endpoint || !apiKey) {
    context.log.warn('Claude API not configured - using template-based generation');
    return generateTemplateBasedFiles(buildName, template);
  }

  // Construct code generation prompt
  const prompt = buildCodeGenerationPrompt(architecture, buildName, template);

  try {
    const isAzureOpenAI = endpoint.includes('openai.azure.com');
    const requestConfig = {
      url: isAzureOpenAI
        ? `${endpoint}/openai/deployments/claude-sonnet-4-5/chat/completions?api-version=2024-10-01`
        : `${endpoint}/v1/messages`,
      method: 'POST',
      headers: isAzureOpenAI
        ? { 'Content-Type': 'application/json', 'api-key': apiKey }
        : { 'Content-Type': 'application/json', 'x-api-key': apiKey, 'anthropic-version': '2023-06-01' },
      data: isAzureOpenAI
        ? { messages: [{ role: 'user', content: prompt }], temperature: 0.3, max_tokens: 8000 }
        : { model: 'claude-sonnet-4-20250514', messages: [{ role: 'user', content: prompt }], temperature: 0.3, max_tokens: 8000 },
      timeout: 120000 // 2 minutes for code generation
    };

    const response = await axios(requestConfig);
    const content = isAzureOpenAI
      ? response.data.choices[0].message.content
      : response.data.content[0].text;

    // Parse generated code into file objects
    return parseGeneratedCode(content, template);

  } catch (error) {
    context.log.warn('Claude code generation failed, falling back to templates', {
      error: error.message
    });
    return generateTemplateBasedFiles(buildName, template);
  }
}

/**
 * Build Code Generation Prompt
 *
 * Constructs comprehensive prompt for AI code generation.
 *
 * @param {object} architecture - Architecture specification
 * @param {string} buildName - Build name
 * @param {object} template - Technology stack template
 * @returns {string} Complete code generation prompt
 */
function buildCodeGenerationPrompt(architecture, buildName, template) {
  return `You are a senior software engineer generating production-ready code for: ${buildName}

ARCHITECTURE SPECIFICATION:
${JSON.stringify(architecture, null, 2)}

TECHNOLOGY STACK:
- Language: ${template.language}
- Framework: ${template.framework}

REQUIREMENTS:
1. Generate complete, production-ready code
2. Follow Microsoft/Azure best practices
3. Include error handling and logging
4. Use environment variables for configuration
5. Implement health check endpoint
6. Follow ${template.language} naming conventions and style guides
7. Include inline documentation with business value comments

RESPONSE FORMAT:
Provide code files in the following format:

\`\`\`filename: src/server.js
// Code here
\`\`\`

\`\`\`filename: src/routes/api.js
// Code here
\`\`\`

Generate the following core files:
${template.structure.filter(f => f.startsWith('src/') || f.startsWith('app/')).join('\n')}

Focus on quality over quantity. Each file should be complete and functional.`;
}

/**
 * Parse Generated Code
 *
 * Extracts individual files from Claude's code generation response.
 *
 * @param {string} content - Claude's response
 * @param {object} template - Technology stack template
 * @returns {Array} Parsed file objects
 */
function parseGeneratedCode(content, template) {
  const files = [];
  const fileRegex = /```filename:\s*(.+?)\n([\s\S]*?)```/g;
  let match;

  while ((match = fileRegex.exec(content)) !== null) {
    const filePath = match[1].trim();
    const fileContent = match[2].trim();

    files.push({
      path: filePath,
      content: fileContent,
      type: 'source'
    });
  }

  return files;
}

/**
 * Generate Template-Based Files
 *
 * Fallback file generation using predefined templates when AI generation fails.
 *
 * @param {string} buildName - Build name
 * @param {object} template - Technology stack template
 * @returns {Array} Template-based files
 */
function generateTemplateBasedFiles(buildName, template) {
  const files = [];

  if (template.language === 'javascript' && template.framework === 'express') {
    // Node.js Express API template
    files.push({
      path: 'src/server.js',
      content: generateNodeExpressServer(buildName),
      type: 'source'
    });

    files.push({
      path: 'src/routes/index.js',
      content: generateExpressRoutes(buildName),
      type: 'source'
    });
  } else if (template.language === 'python' && template.framework === 'flask') {
    // Python Flask API template
    files.push({
      path: 'app/__init__.py',
      content: generateFlaskApp(buildName),
      type: 'source'
    });

    files.push({
      path: 'app/routes.py',
      content: generateFlaskRoutes(buildName),
      type: 'source'
    });
  } else if (template.language === 'csharp') {
    // .NET Web API template
    files.push({
      path: 'Program.cs',
      content: generateDotNetProgram(buildName),
      type: 'source'
    });

    files.push({
      path: 'Controllers/HealthController.cs',
      content: generateDotNetHealthController(buildName),
      type: 'source'
    });
  }

  return files;
}

/**
 * Generate Test Files
 *
 * Creates unit and integration test files for generated code.
 *
 * @param {object} architecture - Architecture specification
 * @param {string} buildName - Build name
 * @param {object} template - Technology stack template
 * @param {object} context - Function context
 * @returns {Array} Test files
 */
async function generateTestFiles(architecture, buildName, template, context) {
  const files = [];

  if (template.language === 'javascript') {
    files.push({
      path: 'tests/unit/health.test.js',
      content: generateJestHealthTest(buildName),
      type: 'test'
    });
  } else if (template.language === 'python') {
    files.push({
      path: 'tests/test_routes.py',
      content: generatePytestHealthTest(buildName),
      type: 'test'
    });
  } else if (template.language === 'csharp') {
    files.push({
      path: 'Tests/HealthControllerTests.cs',
      content: generateXUnitHealthTest(buildName),
      type: 'test'
    });
  }

  return files;
}

/**
 * Generate Configuration Files
 *
 * Creates package.json, requirements.txt, .csproj, and other config files.
 */
function generateConfigurationFiles(buildName, template, architecture) {
  const files = [];

  if (template.language === 'javascript') {
    files.push({
      path: 'package.json',
      content: generatePackageJson(buildName, architecture),
      type: 'config'
    });

    files.push({
      path: '.env.example',
      content: generateEnvExample(architecture),
      type: 'config'
    });
  } else if (template.language === 'python') {
    files.push({
      path: 'requirements.txt',
      content: generateRequirementsTxt(architecture),
      type: 'config'
    });

    files.push({
      path: '.env.example',
      content: generateEnvExample(architecture),
      type: 'config'
    });
  } else if (template.language === 'csharp') {
    files.push({
      path: `${buildName}.csproj`,
      content: generateCsproj(buildName),
      type: 'config'
    });

    files.push({
      path: 'appsettings.json',
      content: generateAppSettingsJson(buildName),
      type: 'config'
    });
  }

  files.push({
    path: '.gitignore',
    content: generateGitignore(template.language),
    type: 'config'
  });

  return files;
}

/**
 * Generate Documentation Files
 *
 * Creates README and API documentation.
 */
function generateDocumentationFiles(buildName, architecture, template) {
  return [
    {
      path: 'README.md',
      content: generateReadme(buildName, architecture, template),
      type: 'docs'
    },
    {
      path: 'ARCHITECTURE.md',
      content: generateArchitectureDoc(architecture),
      type: 'docs'
    }
  ];
}

/**
 * Generate Deployment Files
 *
 * Creates Dockerfile, GitHub Actions workflows, and Azure deployment configs.
 */
function generateDeploymentFiles(architecture, template) {
  return [
    {
      path: 'Dockerfile',
      content: generateDockerfile(template),
      type: 'deployment'
    },
    {
      path: '.github/workflows/ci-cd.yml',
      content: generateGitHubActions(template),
      type: 'deployment'
    }
  ];
}

// Template generation functions (simplified for brevity - would be expanded in production)

function generateNodeExpressServer(buildName) {
  return `/**
 * ${buildName} - Express Server
 *
 * Establishes scalable REST API server with health checks and structured logging.
 * Best for: Production APIs requiring standardized endpoints and monitoring integration.
 */

const express = require('express');
const routes = require('./routes');

const app = express();
const PORT = process.env.PORT || 3000;

// Establish structured request logging for operational visibility
app.use(express.json());
app.use('/api', routes);

// Health check endpoint for Azure App Service monitoring
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(\`Server running on port \${PORT}\`);
});

module.exports = app;
`;
}

function generateExpressRoutes(buildName) {
  return `const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  res.json({ message: '${buildName} API', version: '1.0.0' });
});

module.exports = router;
`;
}

function generatePackageJson(buildName, architecture) {
  return JSON.stringify({
    name: buildName.toLowerCase().replace(/\s+/g, '-'),
    version: '1.0.0',
    description: architecture.summary || `${buildName} API`,
    main: 'src/server.js',
    scripts: {
      start: 'node src/server.js',
      dev: 'nodemon src/server.js',
      test: 'jest',
      'test:coverage': 'jest --coverage'
    },
    dependencies: {
      express: '^4.18.2',
      dotenv: '^16.0.3'
    },
    devDependencies: {
      jest: '^29.5.0',
      nodemon: '^2.0.22',
      supertest: '^6.3.3'
    }
  }, null, 2);
}

function generateReadme(buildName, architecture, template) {
  return `# ${buildName}

${architecture.summary || 'Production-ready application built with autonomous platform'}

## Technology Stack

- **Language**: ${template.language}
- **Framework**: ${template.framework}

## Quick Start

\`\`\`bash
# Install dependencies
${template.language === 'javascript' ? 'npm install' : template.language === 'python' ? 'pip install -r requirements.txt' : 'dotnet restore'}

# Run locally
${template.language === 'javascript' ? 'npm start' : template.language === 'python' ? 'python -m flask run' : 'dotnet run'}
\`\`\`

## Health Check

\`\`\`bash
curl http://localhost:3000/health
\`\`\`

🤖 Generated with Claude Code by Brookside BI Innovation Platform
`;
}

function generateGitignore(language) {
  if (language === 'javascript') {
    return 'node_modules/\n.env\ndist/\ncoverage/\n*.log\n';
  } else if (language === 'python') {
    return '__pycache__/\n*.pyc\n.env\nvenv/\n.pytest_cache/\n';
  } else {
    return 'bin/\nobj/\n*.user\n.vs/\n';
  }
}

function generateDockerfile(template) {
  if (template.language === 'javascript') {
    return `FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
`;
  } else if (template.language === 'python') {
    return `FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "-m", "flask", "run", "--host=0.0.0.0"]
`;
  } else {
    return `FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY *.csproj .
RUN dotnet restore
COPY . .
RUN dotnet publish -c Release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .
EXPOSE 80
ENTRYPOINT ["dotnet", "app.dll"]
`;
  }
}

function generateGitHubActions(template) {
  return `name: CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup
        uses: ${template.language === 'javascript' ? 'actions/setup-node@v3' : template.language === 'python' ? 'actions/setup-python@v4' : 'actions/setup-dotnet@v3'}
      - name: Install
        run: ${template.language === 'javascript' ? 'npm ci' : template.language === 'python' ? 'pip install -r requirements.txt' : 'dotnet restore'}
      - name: Test
        run: ${template.language === 'javascript' ? 'npm test' : template.language === 'python' ? 'pytest' : 'dotnet test'}
`;
}

function generateEnvExample(architecture) {
  return `# ${architecture.details?.title || 'Application'} Configuration
PORT=3000
NODE_ENV=development

# Azure Configuration
AZURE_TENANT_ID=
AZURE_SUBSCRIPTION_ID=

# Add your environment variables here
`;
}

function generateArchitectureDoc(architecture) {
  return `# Architecture Documentation

## System Overview

${architecture.details || 'See architecture specification'}

## Components

${architecture.components ? architecture.components.map(c => `- ${c}`).join('\n') : 'Component details not specified'}

🤖 Generated automatically by Brookside BI Innovation Platform
`;
}

function generateJestHealthTest(buildName) {
  return `const request = require('supertest');
const app = require('../src/server');

describe('Health Check', () => {
  it('should return healthy status', async () => {
    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
    expect(response.body.status).toBe('healthy');
  });
});
`;
}

function countFileTypes(files) {
  return files.reduce((acc, file) => {
    acc[file.type] = (acc[file.type] || 0) + 1;
    return acc;
  }, {});
}

// Additional template functions would be implemented here
function generateFlaskApp(buildName) { return '# Flask app template'; }
function generateFlaskRoutes(buildName) { return '# Flask routes template'; }
function generateDotNetProgram(buildName) { return '// .NET Program.cs template'; }
function generateDotNetHealthController(buildName) { return '// .NET Health controller template'; }
function generatePytestHealthTest(buildName) { return '# Pytest template'; }
function generateXUnitHealthTest(buildName) { return '// XUnit test template'; }
function generateRequirementsTxt(architecture) { return 'flask\npython-dotenv\n'; }
function generateCsproj(buildName) { return '<Project Sdk="Microsoft.NET.Sdk.Web"></Project>'; }
function generateAppSettingsJson(buildName) { return '{}'; }
