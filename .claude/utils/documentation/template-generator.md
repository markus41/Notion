# Documentation Template Generator

**Purpose**: Automated generation of standardized documentation scaffolding for Innovation Nexus repositories, builds, and knowledge artifacts.

**Best for**: Organizations requiring consistent documentation structure across projects with Brookside BI brand compliance and AI-agent readability.

## Available Templates

### 1. README Template

**Use Case**: Project overview and quick start guide for repositories

```markdown
# [Project Name]

[One-sentence description that leads with business value]

**Best for**: [Target audience and primary use case]

## Overview

[2-3 paragraphs explaining what this project does, why it exists, and key outcomes it delivers. Lead with benefits before technical details.]

### Key Features

- **[Feature 1]**: [Outcome-focused description]
- **[Feature 2]**: [Outcome-focused description]
- **[Feature 3]**: [Outcome-focused description]

### Technology Stack

- **Language/Framework**: [Name] [Version]
- **Database**: [Type and version]
- **Hosting**: [Azure service, region, SKU]
- **Key Dependencies**: [List with versions]

**Designed for**: Organizations scaling [technology] across teams who require [specific capability].

## Quick Start

### Prerequisites

```bash
# Required software with minimum versions
node >= 18.0.0
azure-cli >= 2.50.0
git >= 2.30.0
```

### Installation

```bash
# Clone repository
git clone [repo-url]
cd [project-name]

# Install dependencies
npm install  # or: pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with actual values (see Configuration section)

# Verify installation
npm run verify  # Expected: All checks pass ✓
```

### Configuration

Required environment variables:

```bash
# Azure Configuration
AZURE_TENANT_ID=your-tenant-id
AZURE_SUBSCRIPTION_ID=your-subscription-id

# Application Configuration
API_KEY=your-api-key  # Retrieve from Key Vault: kv-brookside-secrets
DATABASE_URL=connection-string

# Optional Configuration
LOG_LEVEL=info  # Options: debug, info, warn, error
CACHE_TTL=3600  # Cache time-to-live in seconds
```

### Run Locally

```bash
# Start development server
npm run dev  # or: python main.py

# Application starts on http://localhost:3000
# Verify: curl http://localhost:3000/health
# Expected response: {"status": "healthy"}
```

## Documentation

- [Architecture Overview](docs/architecture/overview.md) - System design and patterns
- [API Reference](docs/api/endpoints.md) - Endpoint specifications
- [Deployment Guide](docs/guides/deployment.md) - Azure deployment procedures
- [Troubleshooting](docs/guides/troubleshooting.md) - Common issues and solutions

## Cost Breakdown

**Estimated Monthly Operating Costs:**

| Service | SKU | Monthly Cost |
|---------|-----|--------------|
| [Azure Service 1] | [SKU] | $X.XX |
| [Azure Service 2] | [SKU] | $X.XX |
| **Total** | | **$XX.XX** |

**Cost Optimization**: [Microsoft alternatives or optimization opportunities]

## Related Resources

- **Origin Idea**: [Link to Notion Ideas Registry entry]
- **Research**: [Link to Notion Research Hub entry]
- **GitHub**: [Repository URL]
- **Azure Resources**: [Resource Group link]
- **Teams Channel**: [Link]
- **Knowledge Vault**: [Link to related documentation]

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development standards and workflows.

## Support

For questions or issues:
- **Email**: Consultations@BrooksideBI.com
- **Phone**: +1 209 487 2047

---

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>

**Designed for**: [Reiterate target audience and value proposition]
```

### 2. API Documentation Template

**Use Case**: REST API endpoint specifications

```markdown
# API Reference

Establish secure, scalable API access to [service description] that supports sustainable integration patterns across your environment.

**Best for**: Developers building integrations with [service name]

## Authentication

All API requests require authentication using [method]:

```bash
# Example authenticated request
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://api.example.com/v1/endpoint
```

**Authentication Methods:**
- **Bearer Token**: [How to obtain]
- **API Key**: [How to configure]
- **Azure AD**: [OAuth flow description]

## Base URL

```
Production: https://api.example.com/v1
Staging: https://api-staging.example.com/v1
Development: http://localhost:3000/api/v1
```

## Endpoints

### List Resources

```http
GET /api/resources
```

**Purpose**: Retrieve paginated list of resources with filtering support

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `page` | integer | No | Page number (default: 1) |
| `limit` | integer | No | Results per page (default: 20, max: 100) |
| `filter` | string | No | Filter expression |
| `sort` | string | No | Sort field and direction (e.g., "created_at:desc") |

**Request Example:**

```bash
curl -X GET "https://api.example.com/v1/resources?page=1&limit=20&sort=created_at:desc" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Response (200 OK):**

```json
{
  "data": [
    {
      "id": "res_1234567890",
      "name": "Resource Name",
      "status": "active",
      "created_at": "2025-10-22T10:30:00Z",
      "metadata": {}
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 42,
    "pages": 3
  }
}
```

**Error Responses:**

| Status | Description |
|--------|-------------|
| 401 | Unauthorized - Invalid or missing authentication |
| 403 | Forbidden - Insufficient permissions |
| 429 | Too Many Requests - Rate limit exceeded |
| 500 | Internal Server Error - Server-side issue |

### Create Resource

```http
POST /api/resources
```

**Purpose**: Create new resource with validation and cost tracking

**Request Body:**

```json
{
  "name": "Resource Name",
  "description": "Resource description",
  "status": "active",
  "metadata": {
    "custom_field": "value"
  }
}
```

**Request Example:**

```bash
curl -X POST "https://api.example.com/v1/resources" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Resource Name",
    "description": "Resource description",
    "status": "active"
  }'
```

**Response (201 Created):**

```json
{
  "id": "res_1234567890",
  "name": "Resource Name",
  "description": "Resource description",
  "status": "active",
  "created_at": "2025-10-22T10:30:00Z",
  "url": "https://api.example.com/v1/resources/res_1234567890"
}
```

**Validation Rules:**
- `name`: Required, 1-100 characters
- `description`: Optional, max 500 characters
- `status`: Required, must be one of: "active", "inactive", "archived"

## Rate Limiting

**Limits:**
- 100 requests per minute per API key
- 1000 requests per hour per API key

**Response Headers:**
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1634567890
```

## Webhooks

Subscribe to events using webhooks:

```json
{
  "url": "https://your-app.com/webhooks",
  "events": ["resource.created", "resource.updated"],
  "secret": "whsec_your_webhook_secret"
}
```

## SDKs and Libraries

**Official SDKs:**
- **Node.js**: `npm install @example/api-client`
- **Python**: `pip install example-api-client`
- **C#**: `dotnet add package Example.ApiClient`

**Example Usage (Node.js):**

```typescript
import { ExampleClient } from '@example/api-client';

const client = new ExampleClient({
  apiKey: process.env.API_KEY
});

const resources = await client.resources.list({
  page: 1,
  limit: 20
});
```

## Support

For API questions or issues:
- **Email**: Consultations@BrooksideBI.com
- **Phone**: +1 209 487 2047

---

**Designed for**: Organizations requiring structured API integration patterns that support scalable, sustainable development practices.
```

### 3. CLAUDE.md Template

**Use Case**: AI agent instructions for repositories

```markdown
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**[Project Name]** - [One-sentence description that establishes value proposition]

**Repository Purpose**: Streamline key workflows for [domain] through:
- [Key capability 1]
- [Key capability 2]
- [Key capability 3]

**Best for**: [Target audience and primary use case]

## Core Architecture

### System Design

[High-level architecture description with key components]

```
[ASCII diagram or description of system architecture]
Component A → Component B → Component C
  ↓
Database
```

### Technology Stack

- **Language**: [Language] [Version]
- **Framework**: [Framework] [Version]
- **Database**: [Type] [Version]
- **Cloud**: [Azure services used]
- **Key Libraries**: [List with versions]

## Development Guidelines

### Code Standards

**Brookside BI Brand Voice in Code:**
- Comments explain business value first, then implementation
- Variable/function names are descriptive and domain-focused
- Error messages are solution-oriented

**Example:**
```typescript
/**
 * Establish scalable data access layer to support multi-team operations.
 * Implements connection pooling and retry logic for Azure SQL Database.
 *
 * Best for: High-throughput applications requiring reliable database access
 */
export class DatabaseClient {
  // Implementation
}
```

### Project Structure

```
src/
├── api/                 # API endpoint handlers
├── services/            # Business logic layer
├── models/              # Data models and schemas
├── utils/               # Shared utilities
└── config/              # Configuration management

tests/
├── unit/               # Unit tests
├── integration/        # Integration tests
└── e2e/                # End-to-end tests

docs/
├── architecture/       # System design
├── api/               # API documentation
└── guides/            # Setup and deployment guides
```

### Testing Requirements

```bash
# Run all tests
npm test

# Expected: All tests pass, coverage >80%
# Coverage report: coverage/lcov-report/index.html
```

**Test Categories:**
- Unit tests: Test individual functions/classes
- Integration tests: Test component interactions
- E2E tests: Test complete workflows

### Commit Message Format

Follow Conventional Commits with Brookside BI brand voice:

```
feat: Streamline data retrieval with distributed caching for improved performance
fix: Resolve authentication timeout issues to ensure reliable access
docs: Enhance API documentation with real-world usage examples
refactor: Establish modular architecture to support sustainable growth
```

## Azure Infrastructure

### Resource Configuration

**Resource Group**: [Name]
**Region**: [Azure region]

**Resources:**
- App Service: [Name] ([SKU])
- Database: [Name] ([Tier])
- Storage: [Name] ([SKU])
- Key Vault: [Name]

### Secrets Management

All secrets stored in Azure Key Vault: `[vault-name]`

```bash
# Retrieve secret
az keyvault secret show --vault-name [vault-name] --name [secret-name]
```

**Required Secrets:**
- `[secret-1]`: [Description]
- `[secret-2]`: [Description]

### Deployment

```bash
# Deploy to Azure
az login
az account set --subscription [subscription-id]
./deploy.sh [environment]  # dev | staging | prod
```

## Cost Tracking

**Estimated Monthly Costs:**
- [Service 1]: $X.XX/month
- [Service 2]: $X.XX/month
- **Total**: $XX.XX/month

**Linked in Notion**:
- Example Build: [Link]
- Software Tracker: [Link]

## Related Resources

- **Ideas Registry**: [Notion link]
- **Research Hub**: [Notion link]
- **Knowledge Vault**: [Notion link]
- **GitHub**: [Repository URL]
- **Azure DevOps**: [Project link]
- **Teams Channel**: [Link]

## AI Agent Guidelines

### For Claude Code Agents

**When working with this repository:**
- Always reference Azure Key Vault for secrets (never hardcode)
- Apply Brookside BI brand voice to all code comments and documentation
- Ensure all setup steps are idempotent
- Include verification commands after each setup step
- Structure documentation for AI-agent consumption (no ambiguity)

**Sub-Agents Available:**
- `@build-architect`: Technical architecture and documentation
- `@integration-specialist`: Azure resource configuration
- `@cost-analyst`: Cost tracking and optimization
- `@markdown-expert`: Documentation formatting

### Common Operations

**Start Development:**
```bash
# 1. Configure environment
cp .env.example .env
# Edit .env with values from Key Vault

# 2. Install dependencies
npm install

# 3. Run tests
npm test

# 4. Start dev server
npm run dev
```

**Deploy to Azure:**
```bash
# 1. Authenticate
az login

# 2. Deploy
./deploy.sh staging

# 3. Verify
curl https://[app-url]/health
```

## Support

For development questions:
- **Email**: Consultations@BrooksideBI.com
- **Phone**: +1 209 487 2047

---

**Designed for**: Organizations requiring AI-agent-friendly repository guidelines that establish structured development practices and support sustainable, scalable innovation.
```

## Template Generator Usage

### Command Line

```bash
# Generate README
node .claude/utils/documentation/template-generator.js readme \
  --project-name "Cost Dashboard MVP" \
  --description "Real-time cost tracking dashboard for Azure resources" \
  --output README.md

# Generate API docs
node .claude/utils/documentation/template-generator.js api \
  --service-name "Cost Tracking API" \
  --output docs/api/endpoints.md

# Generate CLAUDE.md
node .claude/utils/documentation/template-generator.js claude \
  --project-name "Cost Dashboard MVP" \
  --output CLAUDE.md

# Generate all templates
node .claude/utils/documentation/template-generator.js all \
  --project-name "Cost Dashboard MVP" \
  --output-dir ./
```

### Programmatic Usage

```javascript
const { generateTemplate } = require('.claude/utils/documentation/template-generator');

const readme = generateTemplate('readme', {
  projectName: 'Cost Dashboard MVP',
  description: 'Real-time cost tracking dashboard for Azure resources',
  bestFor: 'Finance teams requiring transparent Azure cost visibility',
  techStack: {
    language: 'TypeScript 5.0',
    framework: 'Next.js 14',
    database: 'Azure SQL Database',
    hosting: 'Azure App Service (B1)'
  }
});

fs.writeFileSync('README.md', readme);
```

## Customization Options

All templates support these customization parameters:

| Parameter | Type | Description |
|-----------|------|-------------|
| `projectName` | string | Project display name |
| `description` | string | One-sentence description |
| `bestFor` | string | Target audience qualifier |
| `techStack` | object | Technology stack details |
| `azureResources` | array | Azure services used |
| `estimatedCost` | number | Monthly cost estimate |
| `notionLinks` | object | Links to Notion databases |

## Related Tools

- [Quality Checker](.claude/utils/documentation/quality-checker.md) - Validate generated templates
- [Brand Transformer](.claude/utils/documentation/brand-transformer.md) - Apply brand voice
- [Link Validator](.claude/utils/documentation/link-validator.md) - Verify cross-references

---

**Documentation Template Generator** - Establish consistent documentation structure across projects that streamlines creation workflows and ensures Brookside BI brand compliance from the start.

**Designed for**: Organizations scaling documentation practices who require standardized templates with built-in brand voice, technical rigor, and AI-agent readability that supports sustainable growth.
