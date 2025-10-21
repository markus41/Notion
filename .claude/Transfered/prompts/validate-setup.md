# Claude Code Setup Validation

This prompt validates that the AI Orchestrator repository is correctly configured for Claude Code.

## Validation Checklist

Please validate the Claude Code setup by performing the following checks:

### 1. List All Available Slash Commands

Check that the following slash commands are available:
- `/review-all` - Comprehensive code review
- `/secure-audit` - Security vulnerability scan
- `/generate-tests` - Test suite generation
- `/optimize-code` - Performance optimization
- `/document-api` - API documentation generation

**Action**: List all available commands and confirm they are accessible.

### 2. Show Configured Subagents

Verify that the following specialized agents are configured:
- `senior-reviewer` - Code quality and best practices expert
- `security-specialist` - Security and compliance auditing
- `test-engineer` - Test coverage and quality assurance
- `performance-optimizer` - Performance and scalability expert
- `documentation-expert` - Technical documentation specialist

**Action**: Display all configured subagents with their descriptions and capabilities.

### 3. Verify MCP Servers are Accessible

Confirm that the following MCP servers are configured in `.mcp.json`:
- `github` - GitHub integration for repository management
- `sentry` - Sentry integration for error tracking
- `filesystem` - Enhanced filesystem operations
- `postgres` - PostgreSQL database integration

**Action**: Check MCP server configuration and verify accessibility.

### 4. Check that CLAUDE.md is Being Loaded

Verify that the project memory file is accessible:
- Confirm `CLAUDE.md` exists at the repository root
- Verify it contains comprehensive project context:
  - Architecture overview
  - Coding standards
  - API endpoints
  - Testing requirements
  - Deployment instructions

**Action**: Read and summarize key sections from `CLAUDE.md`.

### 5. Confirm Hooks are Registered

Verify that lifecycle hooks are configured in `.claude/hooks.mjs`:
- `PreToolUse` - Audit logging before tool execution
- `PostToolUse` - Auto-formatting and cleanup
- `SessionStart` - Initialize development environment
- `PreCompact` - Preserve critical context before compaction

**Action**: Confirm hook registration and functionality.

## Additional Validation Steps

### 6. Verify Directory Structure

Confirm the following directories exist:
- `.claude/` - Claude Code configuration
- `.claude/commands/` - Slash command definitions
- `.claude/agents/` - Specialized agent configurations
- `.github/` - GitHub workflows and instructions
- `docs/` - Documentation
- `prompts/` - Reusable prompt templates
- `src/` - Source code
- `tests/` - Test suites
- `scripts/` - Automation scripts
- `state/` - State management

### 7. Configuration Files

Verify the following configuration files exist and are valid:
- `.claude/settings.json` - Claude Code settings
- `.mcp.json` - MCP server configurations
- `package.json` - Node.js package configuration
- `.env.example` - Environment variable template
- `.github/workflows/ci.yml` - CI/CD pipeline
- `.github/CODEOWNERS` - Code ownership
- `.github/AGENT_INSTRUCTIONS.md` - AI agent guidelines

### 8. Documentation Completeness

Check that the following documentation files exist:
- `README.md` - Project overview and setup guide
- `docs/ARCHITECTURE.md` - System architecture documentation
- `CLAUDE.md` - Project memory and context

### 9. Security Setup Review

Run a basic security review:
- Check for any exposed secrets in `.env.example`
- Verify `.gitignore` includes sensitive files
- Confirm authentication and authorization patterns are documented
- Review security guidelines in `CLAUDE.md`

### 10. Testing Infrastructure

Verify testing setup:
- Test directories exist (`tests/unit`, `tests/integration`, `tests/e2e`)
- Test scripts configured in `package.json`
- Testing framework and tools documented

## Expected Output

After running all validation steps, provide a summary report:

```
✅ Slash Commands: All 5 commands available
✅ Specialized Agents: All 5 agents configured
✅ MCP Servers: All 4 servers configured
✅ CLAUDE.md: Loaded successfully with complete context
✅ Lifecycle Hooks: All 4 hooks registered
✅ Directory Structure: All directories present
✅ Configuration Files: All files valid
✅ Documentation: Complete and comprehensive
✅ Security: No exposed secrets, proper configurations
✅ Testing: Infrastructure ready

Status: READY FOR DEVELOPMENT
```

## Troubleshooting

If any validation fails:

1. **Missing Commands**: Check `.claude/commands/` directory
2. **Missing Agents**: Check `.claude/agents/` directory
3. **MCP Issues**: Verify `.mcp.json` syntax and environment variables
4. **CLAUDE.md Not Loading**: Check file location and formatting
5. **Hooks Not Working**: Verify `.claude/hooks.mjs` syntax

## Usage

To run this validation:

```bash
# Using Claude Code
claude "Run the validation prompt from prompts/validate-setup.md"

# Or manually
# Copy this prompt and paste it into Claude Code
```

## Next Steps After Validation

Once validation passes:

1. **Initialize Git Repository** (if not already done):
   ```bash
   git init
   git add .
   git commit -m "feat: initial AI Orchestrator setup with Claude Code integration"
   ```

2. **Install Dependencies**:
   ```bash
   npm install
   ```

3. **Set Up Environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Run Initial Tests**:
   ```bash
   npm run lint
   npm run test
   ```

5. **Start Development**:
   ```bash
   npm run dev
   ```

6. **Use Claude Code Features**:
   ```bash
   claude /review-all
   claude /secure-audit
   ```

## Success Criteria

The setup is complete when:
- ✅ All validation checks pass
- ✅ Claude Code can access all commands and agents
- ✅ Project context from CLAUDE.md is loaded
- ✅ MCP integrations are functional
- ✅ Development environment is ready
- ✅ Documentation is comprehensive and accessible

---

**Note**: This validation prompt should be run periodically to ensure the Claude Code setup remains optimal as the project evolves.
