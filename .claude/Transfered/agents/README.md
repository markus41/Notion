# Agents

This directory contains AI agent configuration files for Agent Studio.

## What are Agents?

Agents are autonomous AI entities that can perform specific tasks. Each agent is configured with:

- **Capabilities** - What the agent can do
- **Configuration** - Model settings, parameters
- **Triggers** - Events that activate the agent
- **Tools** - MCP tools the agent can use
- **Observability** - Telemetry and logging settings
- **Security** - Authentication and authorization rules

## Agent Types

### Autonomous Agents

Execute independently based on triggers and events.

**Example:** `code-review-agent.json`
- Automatically reviews pull requests
- Provides code quality feedback
- Checks for security issues

### Reactive Agents

Respond to specific requests or events.

**Example:** `documentation-agent.json`
- Generates documentation from code
- Updates documentation on code changes
- Creates API documentation

## Agent Configuration Schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "id": "agent-id",
  "name": "Agent Name",
  "version": "1.0.0",
  "description": "Agent description",
  "type": "autonomous|reactive",
  "capabilities": ["capability1", "capability2"],
  "configuration": {
    "model": "gpt-4",
    "temperature": 0.3,
    "max_tokens": 2000
  },
  "triggers": [
    {
      "type": "webhook|schedule|event",
      "event": "event.name",
      "conditions": {}
    }
  ],
  "tools": [
    {
      "name": "tool-name",
      "type": "mcp",
      "config": {}
    }
  ],
  "observability": {
    "telemetry_enabled": true,
    "log_level": "info",
    "trace_sampling_rate": 0.1
  },
  "security": {
    "authentication_required": true,
    "allowed_origins": [],
    "rate_limit": {
      "requests_per_minute": 60
    }
  }
}
```

## Available Agents

### Code Review Agent (`code-review-agent.json`)

Automatically reviews pull requests and provides intelligent feedback.

**Capabilities:**
- Code analysis
- Security scanning
- Best practices checking
- Automated commenting

**Triggers:**
- Pull request opened
- Pull request synchronized

**Tools:**
- GitHub API
- Code analyzer

### Documentation Agent (`documentation-agent.json`)

Generates and maintains comprehensive technical documentation.

**Capabilities:**
- Code documentation
- API documentation
- README generation
- Changelog management

**Triggers:**
- Daily schedule
- Push to main branch

**Tools:**
- Git repository
- Documentation generator

## Creating a New Agent

1. **Create a JSON file** in this directory
2. **Define agent properties** following the schema
3. **Configure capabilities** and triggers
4. **Add required tools**
5. **Set observability** and security settings
6. **Test the agent** configuration
7. **Deploy** to Agent Studio

Example:

```bash
# Create new agent file
cat > my-agent.json << EOF
{
  "id": "my-agent",
  "name": "My Custom Agent",
  "version": "1.0.0",
  "description": "Does something useful",
  "type": "autonomous",
  "capabilities": ["custom-capability"],
  "configuration": {
    "model": "gpt-4",
    "temperature": 0.5
  },
  "triggers": [{
    "type": "webhook",
    "event": "custom.event"
  }],
  "tools": [{
    "name": "custom-tool",
    "type": "mcp"
  }]
}
EOF
```

## Agent Best Practices

1. **Clear naming** - Use descriptive names
2. **Specific capabilities** - Focus on single responsibility
3. **Appropriate model** - Choose the right model for the task
4. **Error handling** - Configure retry policies
5. **Observability** - Enable telemetry for monitoring
6. **Security** - Require authentication for sensitive operations
7. **Rate limiting** - Prevent abuse
8. **Documentation** - Describe agent purpose and usage

## Testing Agents

Test agents locally before deployment:

```bash
# Using Python service
cd services/python
uvicorn app.main:app --reload

# Create agent
curl -X POST http://localhost:8000/agents \
  -H "Content-Type: application/json" \
  -d @agents/my-agent.json

# Execute agent
curl -X POST http://localhost:8000/agents/my-agent/execute \
  -H "Content-Type: application/json" \
  -d '{"agent_id": "my-agent", "parameters": {}}'
```

## Deployment

Agents are automatically deployed when changes are merged to the main branch.

## Monitoring

Monitor agent execution through:
- Application Insights
- OpenTelemetry traces
- Agent execution logs
- Custom metrics

## Troubleshooting

### Agent Not Triggering

- Check trigger configuration
- Verify event source
- Review agent logs
- Check security settings

### Agent Execution Fails

- Review execution logs
- Check tool availability
- Verify model configuration
- Test with sample data

### Performance Issues

- Adjust model parameters
- Enable caching
- Optimize tool calls
- Review rate limits

## Resources

- [Agent Architecture](../docs/architecture.md)
- [MCP Tools](../tools/README.md)
- [Workflows](../workflows/README.md)
- [API Documentation](../docs/api.md)
