# Getting Started with Agent Framework

Welcome to the Agent Framework project! This guide will help you get up and running quickly.

## Prerequisites

- **Node.js** 18+ (for webapp)
- **.NET 8.0+** (for .NET samples)
- **Python 3.10+** (for Python samples)
- **Docker** (optional, for local infrastructure)

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/Brookside-Proving-Grounds/Project-Ascension.git
cd Project-Ascension
```

### 2. Run .NET Samples

```bash
cd src/dotnet
dotnet build
dotnet run --project AgentFramework.Samples
dotnet test
```

### 3. Run Python Samples

```bash
cd src/python
pip install -e ".[dev]"
python examples.py
pytest
```

### 4. Run Webapp

```bash
cd src/webapp
npm install
npm run dev
```

The webapp will be available at `http://localhost:3000`.

### 5. Start Local Infrastructure (Optional)

```bash
docker-compose up -d
```

This starts:
- PostgreSQL database
- Redis cache
- Azurite (Azure Storage emulator)
- OpenTelemetry Collector
- Jaeger UI (traces)

## Project Structure

```
Project-Ascension/
├── src/
│   ├── dotnet/              # .NET agent framework samples
│   ├── python/              # Python agent framework samples
│   └── webapp/              # React webapp
├── agents/                  # Agent configuration files
├── workflows/               # Workflow configuration files
├── tools/                   # Tool implementations
│   ├── mcp-server/         # MCP server stub
│   ├── openapi/            # OpenAPI tool
│   ├── code-exec/          # Code execution sandbox
│   ├── web-search/         # Web search tool
│   └── file-io/            # File I/O tool with guards
├── docs/                    # Documentation
└── tests/                   # E2E tests

```

## Key Features

### Agent Framework
- **Sequential Workflows**: Agents process tasks one after another
- **Concurrent Workflows**: Parallel agent execution
- **Group Chat**: Multi-agent collaboration
- **Handoff**: Dynamic agent routing
- **Checkpointing**: Resume workflows from saved states
- **Type-Safe Messaging**: Strongly-typed message passing

### Webapp Features
- **React Flow Canvas**: Visual workflow design
- **Trace Waterfall**: Execution visualization with VisX/D3
- **Monaco Editor**: Code editing in-browser
- **Command Palette**: Quick navigation (Cmd+K)
- **Tailwind CSS**: Modern, responsive design

### Tools
- **MCP Server**: Model Context Protocol server
- **OpenAPI Integration**: REST API tool
- **Code Execution**: Sandboxed code runner
- **Web Search**: Search integration stub
- **File I/O**: Secure file operations

## Next Steps

1. Explore the [Workflow Examples](./workflows/)
2. Read the [Architecture Decision Records](./adrs/)
3. Review the [Threat Model](./THREAT_MODEL.md)
4. Check the [Onboarding Checklist](./ONBOARDING.md)
5. Contribute! See [CONTRIBUTING.md](../CONTRIBUTING.md)

## Troubleshooting

### Port Already in Use
If port 3000 is already in use, modify `vite.config.ts`:
```ts
server: {
  port: 3001, // Change to available port
}
```

### .NET Build Errors
Ensure you have .NET 8.0+ installed:
```bash
dotnet --version
```

### Python Import Errors
Make sure you installed the package in editable mode:
```bash
pip install -e ".[dev]"
```

## Support

- **Issues**: [GitHub Issues](https://github.com/Brookside-Proving-Grounds/Project-Ascension/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Brookside-Proving-Grounds/Project-Ascension/discussions)
- **Documentation**: [/docs](./docs/)

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.
