# Meta-Agent Platform Test Strategy

**Version:** 1.0
**Last Updated:** 2025-10-08
**Status:** Active

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Testing Philosophy and Principles](#testing-philosophy-and-principles)
3. [Test Pyramid Architecture](#test-pyramid-architecture)
4. [Coverage Targets and Quality Metrics](#coverage-targets-and-quality-metrics)
5. [Testing Frameworks and Tools](#testing-frameworks-and-tools)
6. [Layer-Specific Test Strategies](#layer-specific-test-strategies)
7. [Test Data Management](#test-data-management)
8. [CI/CD Integration](#cicd-integration)
9. [Performance Testing Strategy](#performance-testing-strategy)
10. [Security Testing Strategy](#security-testing-strategy)
11. [Test Environment Management](#test-environment-management)
12. [Quality Gates and Release Criteria](#quality-gates-and-release-criteria)
13. [Monitoring and Continuous Improvement](#monitoring-and-continuous-improvement)

---

## Executive Summary

This document defines the comprehensive testing strategy for the Meta-Agent Platform, a multi-layered system consisting of:
- **Python Layer:** Meta-agents (Architect, Builder, Validator, Scribe), memory systems, and FastAPI endpoints
- **.NET Layer:** Orchestration services, workflow execution, Cosmos DB repositories, and SignalR hubs
- **React Layer:** Web UI components, hooks, state management, and real-time visualization
- **Integration Layer:** Cross-service communication, event streaming, and workflow coordination

**Primary Objectives:**
1. Achieve 85%+ code coverage across all layers
2. Maintain test pyramid distribution (70% unit, 20% integration, 10% E2E)
3. Enable fast feedback loops (<5 minutes for unit tests, <15 minutes for full suite)
4. Ensure zero critical defects in production
5. Support continuous deployment with confidence

---

## Testing Philosophy and Principles

### Core Principles

1. **Shift-Left Testing**
   - Write tests before or alongside code (TDD/BDD where applicable)
   - Catch defects early in the development cycle
   - Use static analysis and linting to prevent common errors

2. **Risk-Based Testing**
   - Allocate testing effort based on business criticality and technical risk
   - Critical paths (agent orchestration, workflow execution): 100% coverage
   - High-risk areas (payment processing, data persistence): 90%+ coverage
   - Medium-risk areas (UI components, utilities): 70%+ coverage

3. **Test Pyramid Adherence**
   - Majority of tests at unit level (fast, isolated, deterministic)
   - Selective integration testing for component interactions
   - Minimal but comprehensive E2E testing for critical workflows

4. **Quality Over Quantity**
   - Focus on meaningful assertions and property-based testing
   - Use mutation testing to validate test effectiveness (75%+ mutation score target)
   - Eliminate flaky tests systematically

5. **Automation with Purpose**
   - Automate repetitive, regression-prone scenarios
   - Reserve manual testing for exploratory testing and usability validation
   - Design maintainable, readable test automation

6. **Production Testing (Shift-Right)**
   - Canary deployments with comprehensive monitoring
   - Feature flags for controlled rollout
   - Synthetic monitoring and chaos engineering

### Test Design Principles

- **Arrange-Act-Assert (AAA)** pattern for unit tests
- **Given-When-Then** pattern for BDD scenarios
- **Test isolation:** Each test should be independent and repeatable
- **Clear naming:** Test names should describe the scenario and expected outcome
- **Single responsibility:** Each test should verify one behavior
- **Fast execution:** Unit tests <1s, integration tests <5s

---

## Test Pyramid Architecture

```
                    E2E Tests (10%)
                 ┌──────────────────┐
                 │  Full Workflows  │
                 │  User Journeys   │
                 │  Cross-System    │
                 └──────────────────┘
                         ▲
                         │
            Integration Tests (20%)
         ┌───────────────────────────────┐
         │  Service Communication        │
         │  Database Integration         │
         │  SignalR Hubs                 │
         │  API Endpoints                │
         └───────────────────────────────┘
                         ▲
                         │
                 Unit Tests (70%)
    ┌────────────────────────────────────────┐
    │  Agent Logic        │  Orchestrators   │
    │  Memory Systems     │  Repositories    │
    │  API Routes         │  Components      │
    │  Business Logic     │  Utilities       │
    └────────────────────────────────────────┘
```

### Distribution by Layer

| Layer | Unit | Integration | E2E | Total Tests |
|-------|------|-------------|-----|-------------|
| Python | 250 | 50 | 15 | 315 |
| .NET | 180 | 40 | 10 | 230 |
| React | 200 | 30 | 25 | 255 |
| Total | 630 (70%) | 120 (20%) | 50 (10%) | 800 |

---

## Coverage Targets and Quality Metrics

### Code Coverage Targets

| Layer | Overall | Critical Paths | High Risk | Medium Risk | Low Risk |
|-------|---------|----------------|-----------|-------------|----------|
| Python | 85% | 100% | 90% | 75% | 60% |
| .NET | 85% | 100% | 90% | 75% | 60% |
| React | 80% | 95% | 85% | 70% | 55% |

**Critical Paths:**
- Agent workflow execution (Architect → Builder → Validator → Scribe)
- Workflow orchestration and state management
- Memory persistence and retrieval
- Real-time SignalR communication

**High Risk:**
- LLM API integration
- Cosmos DB operations
- Error handling and recovery
- Checkpoint/resume functionality

### Quality Metrics

**Testing Metrics:**
- Test pass rate: 100% (no failing tests in main branch)
- Test flakiness: <1% (max 1 flaky test per 100 runs)
- Test execution time:
  - Unit tests: <5 minutes
  - Integration tests: <10 minutes
  - E2E tests: <20 minutes
  - Full suite: <30 minutes
- Mutation score: 75%+ (validates test effectiveness)
- Code coverage trend: No decrease between releases

**Quality Metrics:**
- Defect density: <5 defects per 1000 LOC
- Escaped defects (production): <2 per release
- Mean time to detection (MTTD): <24 hours
- Mean time to resolution (MTTR): <48 hours for critical, <1 week for non-critical
- System uptime: 99.9% for production
- Customer satisfaction (CSAT): >4.5/5

**Process Metrics:**
- Test automation coverage: >95% of regression tests
- Test maintenance effort: <10% of development time
- Test execution frequency: Every commit (unit), every PR (integration), daily (E2E)
- Build break rate: <5%

---

## Testing Frameworks and Tools

### Python Testing Stack

```python
# Core Testing
pytest==8.0.0                    # Test framework
pytest-asyncio==0.23.0           # Async test support
pytest-cov==4.1.0                # Coverage reporting
pytest-xdist==3.5.0              # Parallel execution
pytest-timeout==2.2.0            # Test timeout enforcement

# Mocking and Test Doubles
pytest-mock==3.12.0              # Mocking utilities
responses==0.24.0                # HTTP mocking
freezegun==1.4.0                 # Time mocking

# Property-Based Testing
hypothesis==6.96.0               # Property-based testing

# API Testing
httpx==0.26.0                    # Async HTTP client
fastapi[test]==0.109.0           # FastAPI test client

# Database Testing
pytest-postgresql==5.0.0         # PostgreSQL fixtures
fakeredis==2.20.0                # Redis mocking

# Mutation Testing
mutmut==2.4.4                    # Mutation testing

# Code Quality
ruff==0.1.14                     # Fast linter
black==24.1.1                    # Code formatter
mypy==1.8.0                      # Type checking
```

**Configuration:** `src/python/pyproject.toml`, `src/python/pytest.ini`

### .NET Testing Stack

```xml
<!-- Core Testing -->
<PackageReference Include="xUnit" Version="2.6.6" />
<PackageReference Include="xUnit.runner.visualstudio" Version="2.5.6" />
<PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.9.0" />

<!-- Mocking and Assertions -->
<PackageReference Include="Moq" Version="4.20.70" />
<PackageReference Include="FluentAssertions" Version="6.12.0" />

<!-- Integration Testing -->
<PackageReference Include="Microsoft.AspNetCore.Mvc.Testing" Version="8.0.1" />
<PackageReference Include="Testcontainers" Version="3.7.0" />
<PackageReference Include="Testcontainers.CosmosDb" Version="3.7.0" />
<PackageReference Include="Testcontainers.Redis" Version="3.7.0" />

<!-- SignalR Testing -->
<PackageReference Include="Microsoft.AspNetCore.SignalR.Client" Version="8.0.1" />

<!-- Coverage -->
<PackageReference Include="coverlet.collector" Version="6.0.0" />
<PackageReference Include="coverlet.msbuild" Version="6.0.0" />

<!-- Mutation Testing -->
<PackageReference Include="Stryker.Core" Version="4.0.0" />
```

**Configuration:** `services/dotnet/AgentStudio.Api.Tests/xunit.runner.json`

### React Testing Stack

```json
{
  "devDependencies": {
    // Core Testing
    "vitest": "^1.2.0",
    "@vitest/ui": "^1.2.0",
    "@vitest/coverage-v8": "^1.2.0",

    // React Testing
    "@testing-library/react": "^14.1.2",
    "@testing-library/jest-dom": "^6.2.0",
    "@testing-library/user-event": "^14.5.2",

    // API Mocking
    "msw": "^2.0.13",

    // E2E Testing
    "@playwright/test": "^1.41.0",

    // Component Testing
    "@storybook/react": "^7.6.10",
    "@storybook/test-runner": "^0.16.0"
  }
}
```

**Configuration:** `src/webapp/vitest.config.ts`, `src/webapp/playwright.config.ts`

### Additional Tools

- **Performance Testing:** k6, Apache JMeter
- **Load Testing:** Locust (Python), Artillery (Node.js)
- **Security Testing:** OWASP ZAP, Trivy, Bandit (Python), Security Code Scan (.NET)
- **Contract Testing:** Pact
- **Accessibility Testing:** axe-core, Pa11y
- **Visual Regression:** Percy, Chromatic

---

## Layer-Specific Test Strategies

### Python Layer Testing

#### Meta-Agent Testing

**Scope:** Architect, Builder, Validator, Scribe agents

**Unit Tests (85% coverage target):**
```python
# Test Structure: src/python/tests/agents/
tests/
├── agents/
│   ├── test_architect_agent.py
│   ├── test_builder_agent.py
│   ├── test_validator_agent.py
│   ├── test_scribe_agent.py
│   └── test_base_agent.py
```

**Test Categories:**
1. **Agent Initialization**
   - Configuration validation
   - LLM client setup
   - Tool registry initialization

2. **Message Processing**
   - Valid message handling
   - Context processing
   - Error scenarios

3. **LLM Integration**
   - Mock LLM responses
   - Prompt construction
   - Response parsing

4. **Tool Usage**
   - Tool execution
   - Tool failure handling
   - Retry logic

5. **Agent Handoff**
   - Handoff request creation
   - Context propagation
   - Role transitions

**Example Test:**
```python
@pytest.mark.asyncio
async def test_architect_agent_requirements_analysis():
    """Test Architect agent analyzes requirements correctly."""
    # Arrange
    config = create_test_agent_config(AgentRole.ARCHITECT)
    agent = ArchitectAgent(config)
    message = MetaAgentMessage(
        content="Build a REST API for user management",
        context={"task_type": "analyze_requirements"}
    )

    # Mock LLM response
    mock_llm_response = """
    Requirements Analysis:
    1. Functional: CRUD operations for users
    2. Non-functional: Security, scalability
    3. Questions: Authentication method?
    """

    with patch.object(agent, 'call_llm', return_value=mock_llm_response):
        # Act
        response = await agent.process(message)

        # Assert
        assert response.success is True
        assert "Requirements Analysis" in response.content
        assert response.agent_role == AgentRole.ARCHITECT
```

#### Memory System Testing

**Scope:** Vector store, agent memory, context manager

**Unit Tests (90% coverage target):**
```python
# Test Structure:
tests/
├── memory/
│   ├── test_vector_store.py
│   ├── test_agent_memory.py
│   └── test_context_manager.py
```

**Test Categories:**
1. **Vector Store Operations**
   - Document insertion
   - Semantic search
   - Document deletion
   - Collection management

2. **Memory Persistence**
   - Memory storage
   - Memory retrieval
   - Memory updates
   - Memory expiration

3. **Context Management**
   - Context building
   - Context windowing
   - Relevance filtering

**Property-Based Testing:**
```python
from hypothesis import given, strategies as st

@given(
    embeddings=st.lists(
        st.lists(st.floats(min_value=-1.0, max_value=1.0), min_size=1536, max_size=1536),
        min_size=1,
        max_size=100
    )
)
@pytest.mark.asyncio
async def test_vector_search_returns_sorted_results(embeddings):
    """Property: Search results are always sorted by similarity."""
    vector_store = create_test_vector_store()

    # Add documents
    docs = [
        VectorDocument(id=f"doc_{i}", content=f"Content {i}", embedding=emb)
        for i, emb in enumerate(embeddings)
    ]
    await vector_store.add_documents(docs)

    # Search with random query
    query_embedding = [random.uniform(-1, 1) for _ in range(1536)]
    results = await vector_store.search(query_embedding, top_k=10)

    # Assert: Results are sorted by score (descending)
    scores = [r.score for r in results]
    assert scores == sorted(scores, reverse=True)
```

#### API Testing

**Scope:** FastAPI routes and endpoints

**Integration Tests (20%):**
```python
# Test Structure:
tests/
├── api/
│   ├── test_health_endpoints.py
│   ├── test_architect_endpoints.py
│   ├── test_builder_endpoints.py
│   ├── test_validator_endpoints.py
│   ├── test_scribe_endpoints.py
│   └── test_workflow_endpoints.py
```

**Test Categories:**
1. **Endpoint Functionality**
   - Request validation
   - Response formatting
   - Error handling

2. **Authentication & Authorization**
   - Token validation
   - Permission checks

3. **Workflow Execution**
   - Multi-agent workflows
   - Handoff coordination
   - State tracking

**Example Integration Test:**
```python
@pytest.mark.asyncio
async def test_workflow_execution_sequential():
    """Test sequential workflow: Architect -> Builder -> Validator -> Scribe."""
    async with AsyncClient(app=app, base_url="http://test") as client:
        # Execute workflow
        response = await client.post(
            "/api/workflow/execute",
            json={
                "initial_task": "Create a simple calculator API",
                "starting_agent": "architect",
                "max_iterations": 10,
                "context": {}
            }
        )

        assert response.status_code == 200
        data = response.json()

        # Verify workflow execution
        assert data["success"] is True
        assert len(data["steps"]) >= 4  # All 4 agents involved

        # Verify agent sequence
        agent_roles = [step["agent_role"] for step in data["steps"]]
        assert "architect" in agent_roles
        assert "builder" in agent_roles
        assert "validator" in agent_roles
        assert "scribe" in agent_roles
```

### .NET Layer Testing

#### Orchestration Testing

**Scope:** Workflow orchestrator, state machine, execution engine

**Unit Tests (85% coverage target):**
```csharp
// Test Structure: services/dotnet/AgentStudio.Orchestration.Tests/
Tests/
├── Orchestrators/
│   ├── MetaAgentOrchestratorTests.cs
│   ├── WorkflowExecutorTests.cs
│   └── StateManagerTests.cs
```

**Test Categories:**
1. **Workflow Execution**
   - Sequential workflows
   - Parallel workflows
   - Iterative workflows

2. **State Management**
   - State persistence
   - State transitions
   - Checkpoint creation

3. **Error Handling**
   - Agent failures
   - Retry logic
   - Compensation actions

**Example Test:**
```csharp
[Fact]
public async Task ExecuteWorkflow_SequentialPattern_ExecutesInOrder()
{
    // Arrange
    var mockPythonClient = new Mock<IPythonAgentClient>();
    var mockStateRepo = new Mock<IWorkflowRepository>();
    var orchestrator = new MetaAgentOrchestrator(
        mockPythonClient.Object,
        mockStateRepo.Object,
        Mock.Of<ILogger<MetaAgentOrchestrator>>()
    );

    var workflowRequest = new WorkflowRequest
    {
        Type = WorkflowType.Sequential,
        InitialTask = "Analyze requirements",
        AgentSequence = new[] { "architect", "builder", "validator", "scribe" }
    };

    // Mock agent responses
    mockPythonClient
        .Setup(x => x.ExecuteAgentTaskAsync(It.IsAny<string>(), It.IsAny<AgentTaskRequest>(), It.IsAny<CancellationToken>()))
        .ReturnsAsync(new AgentTaskResponse
        {
            Success = true,
            Content = "Task completed"
        });

    // Act
    var result = await orchestrator.ExecuteWorkflowAsync(workflowRequest);

    // Assert
    result.Should().NotBeNull();
    result.Success.Should().BeTrue();
    result.Steps.Should().HaveCount(4);
    result.Steps.Select(s => s.AgentRole).Should().ContainInOrder("architect", "builder", "validator", "scribe");
}
```

#### Repository Testing

**Scope:** Cosmos DB repositories

**Integration Tests (Using Testcontainers):**
```csharp
[Collection("CosmosDB")]
public class CosmosDbWorkflowRepositoryTests : IAsyncLifetime
{
    private readonly CosmosDbFixture _fixture;
    private IWorkflowRepository _repository;

    public CosmosDbWorkflowRepositoryTests(CosmosDbFixture fixture)
    {
        _fixture = fixture;
    }

    public async Task InitializeAsync()
    {
        _repository = new CosmosDbWorkflowRepository(
            _fixture.CosmosClient,
            _fixture.DatabaseName,
            Mock.Of<ILogger<CosmosDbWorkflowRepository>>()
        );
    }

    [Fact]
    public async Task SaveWorkflowState_NewWorkflow_ReturnsWithETag()
    {
        // Arrange
        var workflowState = new WorkflowState
        {
            Id = Guid.NewGuid().ToString(),
            Type = "sequential",
            Status = "pending",
            WorkspaceId = "test-workspace"
        };

        // Act
        var saved = await _repository.SaveWorkflowStateAsync(workflowState);

        // Assert
        saved.Should().NotBeNull();
        saved.ETag.Should().NotBeNullOrEmpty();
        saved.Id.Should().Be(workflowState.Id);
    }

    [Fact]
    public async Task SaveWorkflowState_OptimisticConcurrency_ThrowsOnConflict()
    {
        // Arrange
        var workflowState = new WorkflowState
        {
            Id = Guid.NewGuid().ToString(),
            Type = "sequential",
            Status = "pending",
            WorkspaceId = "test-workspace"
        };

        var saved1 = await _repository.SaveWorkflowStateAsync(workflowState);

        // Simulate concurrent update
        saved1.Status = "in_progress";
        var saved2 = await _repository.SaveWorkflowStateAsync(saved1);

        // Act & Assert
        saved1.Status = "completed";
        await Assert.ThrowsAsync<CosmosException>(
            async () => await _repository.SaveWorkflowStateAsync(saved1)
        );
    }

    public Task DisposeAsync() => Task.CompletedTask;
}
```

#### SignalR Hub Testing

**Scope:** Real-time communication hubs

**Integration Tests:**
```csharp
public class MetaAgentHubTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    [Fact]
    public async Task Hub_WorkflowProgress_BroadcastsToClients()
    {
        // Arrange
        var connection = new HubConnectionBuilder()
            .WithUrl($"{_factory.Server.BaseAddress}hubs/meta-agents")
            .Build();

        var progressReceived = new TaskCompletionSource<WorkflowProgress>();
        connection.On<WorkflowProgress>("WorkflowProgress", progress =>
        {
            progressReceived.SetResult(progress);
        });

        await connection.StartAsync();

        // Act
        await connection.InvokeAsync("SubscribeToWorkflow", "workflow-123");

        // Trigger workflow update (simulated)
        var hubContext = _factory.Services.GetRequiredService<IHubContext<MetaAgentHub>>();
        await hubContext.Clients.Group("workflow-123").SendAsync("WorkflowProgress", new WorkflowProgress
        {
            WorkflowId = "workflow-123",
            CurrentStep = 2,
            Status = "in_progress"
        });

        // Assert
        var result = await progressReceived.Task.WaitAsync(TimeSpan.FromSeconds(5));
        result.WorkflowId.Should().Be("workflow-123");
        result.CurrentStep.Should().Be(2);
    }
}
```

### React Layer Testing

#### Component Testing

**Scope:** UI components, meta-agent visualizations

**Unit Tests (80% coverage target):**
```typescript
// Test Structure: src/webapp/src/components/meta-agents/__tests__/
__tests__/
├── Agent3DVisualization.test.tsx
├── AgentThoughtStream.test.tsx
├── AgentConversation.test.tsx
├── WorkflowGraph.test.tsx
├── AgentMetrics.test.tsx
└── AgentControls.test.tsx
```

**Example Component Test:**
```typescript
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi } from 'vitest';
import { AgentControls } from '../AgentControls';

describe('AgentControls', () => {
  it('should start workflow when start button clicked', async () => {
    // Arrange
    const onStartWorkflow = vi.fn();
    const user = userEvent.setup();

    render(
      <AgentControls
        workflowStatus="idle"
        onStartWorkflow={onStartWorkflow}
        onStopWorkflow={vi.fn()}
        onPauseWorkflow={vi.fn()}
      />
    );

    // Act
    const startButton = screen.getByRole('button', { name: /start workflow/i });
    await user.click(startButton);

    // Assert
    expect(onStartWorkflow).toHaveBeenCalledTimes(1);
  });

  it('should disable start button when workflow is running', () => {
    // Arrange
    render(
      <AgentControls
        workflowStatus="running"
        onStartWorkflow={vi.fn()}
        onStopWorkflow={vi.fn()}
        onPauseWorkflow={vi.fn()}
      />
    );

    // Assert
    const startButton = screen.getByRole('button', { name: /start workflow/i });
    expect(startButton).toBeDisabled();
  });

  it('should display correct workflow status', () => {
    // Arrange
    render(
      <AgentControls
        workflowStatus="running"
        onStartWorkflow={vi.fn()}
        onStopWorkflow={vi.fn()}
        onPauseWorkflow={vi.fn()}
      />
    );

    // Assert
    expect(screen.getByText(/status: running/i)).toBeInTheDocument();
  });
});
```

#### Hook Testing

**Scope:** Custom React hooks

**Test Structure:**
```typescript
// src/webapp/src/hooks/__tests__/
__tests__/
├── useMetaAgents.test.ts
├── useWorkflowExecution.test.ts
├── useSignalR.test.ts
└── useAgentMemory.test.ts
```

**Example Hook Test:**
```typescript
import { renderHook, waitFor } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { useWorkflowExecution } from '../useWorkflowExecution';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  return ({ children }) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  );
};

describe('useWorkflowExecution', () => {
  it('should execute workflow successfully', async () => {
    // Arrange
    const { result } = renderHook(() => useWorkflowExecution(), {
      wrapper: createWrapper(),
    });

    // Act
    result.current.startWorkflow({
      initialTask: 'Create REST API',
      startingAgent: 'architect',
    });

    // Assert
    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
      expect(result.current.workflow).toBeDefined();
      expect(result.current.workflow?.success).toBe(true);
    });
  });
});
```

#### Integration Testing with MSW

**API Mocking:**
```typescript
// src/webapp/src/mocks/handlers.ts
import { http, HttpResponse } from 'msw';

export const handlers = [
  http.post('/api/workflow/execute', async ({ request }) => {
    const body = await request.json();

    return HttpResponse.json({
      workflowId: 'test-workflow-123',
      steps: [
        {
          stepNumber: 1,
          agentRole: 'architect',
          agentName: 'Architect-1',
          content: 'Requirements analyzed',
          success: true,
        },
      ],
      finalOutput: 'Workflow completed',
      success: true,
      totalIterations: 4,
    });
  }),

  http.get('/api/health', () => {
    return HttpResponse.json({
      status: 'healthy',
      version: '0.1.0',
      agents: ['architect', 'builder', 'validator', 'scribe'],
    });
  }),
];
```

---

## Test Data Management

### Test Data Strategy

1. **Fixtures and Factories**
   - Use factories for creating test data objects
   - Maintain fixtures for common scenarios
   - Version control all test data

2. **Database Seeding**
   - Automated seed data for integration tests
   - Consistent data across test runs
   - Cleanup after each test

3. **Mocked External Dependencies**
   - Mock LLM responses (Azure OpenAI)
   - Mock external APIs
   - Controlled, deterministic responses

### Python Test Fixtures

```python
# src/python/tests/conftest.py
import pytest
from meta_agents.agent_config import AgentConfig, AgentRole, AzureOpenAIConfig
from meta_agents.architect_agent import ArchitectAgent

@pytest.fixture
def azure_openai_config():
    """Azure OpenAI configuration for testing."""
    return AzureOpenAIConfig(
        api_key="test-api-key",
        azure_endpoint="https://test.openai.azure.com/",
        deployment_name="gpt-4",
        api_version="2024-02-01",
    )

@pytest.fixture
def architect_agent_config(azure_openai_config):
    """Architect agent configuration."""
    return AgentConfig(
        name="test-architect",
        role=AgentRole.ARCHITECT,
        description="Test architect agent",
        azure_openai=azure_openai_config,
    )

@pytest.fixture
async def architect_agent(architect_agent_config):
    """Initialized Architect agent for testing."""
    agent = ArchitectAgent(architect_agent_config)
    yield agent
    await agent.shutdown()

@pytest.fixture
def mock_llm_responses():
    """Common LLM responses for testing."""
    return {
        "requirements_analysis": """
        Requirements Analysis:
        1. Functional: User authentication, data CRUD
        2. Non-functional: Scalability, security
        3. Questions: Deployment target?
        """,
        "system_design": """
        System Design:
        Architecture: Microservices
        Components: API Gateway, Auth Service, Data Service
        Technology: Python, FastAPI, PostgreSQL
        """,
    }
```

### .NET Test Fixtures

```csharp
// services/dotnet/AgentStudio.Api.Tests/Fixtures/CosmosDbFixture.cs
public class CosmosDbFixture : IAsyncLifetime
{
    private CosmosDbContainer? _container;

    public CosmosClient CosmosClient { get; private set; } = null!;
    public string DatabaseName { get; } = "test-db";

    public async Task InitializeAsync()
    {
        // Start Cosmos DB emulator container
        _container = new CosmosDbBuilder()
            .WithImage("mcr.microsoft.com/cosmosdb/linux/azure-cosmos-emulator:latest")
            .Build();

        await _container.StartAsync();

        // Create client
        CosmosClient = new CosmosClient(
            _container.GetConnectionString(),
            new CosmosClientOptions
            {
                HttpClientFactory = () => _container.HttpClient,
                ConnectionMode = ConnectionMode.Gateway
            }
        );

        // Create database
        await CosmosClient.CreateDatabaseIfNotExistsAsync(DatabaseName);

        // Create containers
        var database = CosmosClient.GetDatabase(DatabaseName);
        await database.CreateContainerIfNotExistsAsync("workflow-states", "/workflow_id");
    }

    public async Task DisposeAsync()
    {
        if (_container != null)
        {
            await _container.DisposeAsync();
        }
    }
}
```

### React Test Setup

```typescript
// src/webapp/src/test-utils/setup.ts
import { afterEach } from 'vitest';
import { cleanup } from '@testing-library/react';
import '@testing-library/jest-dom';
import { server } from '../mocks/server';

// Start MSW server
beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterAll(() => server.close());
afterEach(() => {
  server.resetHandlers();
  cleanup();
});
```

---

## CI/CD Integration

### Test Execution Strategy

**Per Commit (Fast Feedback):**
- Unit tests only (Python, .NET, React)
- Linting and type checking
- Target: <5 minutes

**Per Pull Request:**
- Unit tests
- Integration tests
- Security scanning
- Target: <15 minutes

**Daily/Nightly:**
- Full test suite (unit + integration + E2E)
- Performance tests
- Mutation testing
- Target: <2 hours

**Pre-Release:**
- Full regression suite
- Security audit
- Performance benchmarking
- Load testing

### Updated CI Pipeline

See the complete CI/CD configuration in the next section.

---

## Performance Testing Strategy

### Performance Targets

| Component | Metric | Target | Critical |
|-----------|--------|--------|----------|
| Agent Response | Latency (p95) | <2s | <5s |
| API Endpoints | Latency (p95) | <500ms | <1s |
| Vector Search | Latency (p95) | <100ms | <300ms |
| Cosmos DB Read | Latency (p95) | <10ms | <50ms |
| Cosmos DB Write | Latency (p95) | <50ms | <150ms |
| SignalR Message | Latency (p95) | <100ms | <500ms |
| Workflow Execution | Duration | <30s | <60s |
| Concurrent Users | Throughput | 100 users | 50 users |

### Load Testing Scenarios

**Scenario 1: Agent Request Load**
```python
# tests/performance/load_test_agents.py
from locust import HttpUser, task, between

class MetaAgentUser(HttpUser):
    wait_time = between(1, 3)

    @task(3)
    def architect_task(self):
        self.client.post(
            "/api/architect/task",
            json={
                "content": "Design a microservices architecture",
                "context": {},
                "auto_handoff": False,
            },
        )

    @task(2)
    def builder_task(self):
        self.client.post(
            "/api/builder/task",
            json={
                "content": "Implement user authentication",
                "context": {},
                "auto_handoff": False,
            },
        )

    @task(1)
    def workflow_execution(self):
        self.client.post(
            "/api/workflow/execute",
            json={
                "initial_task": "Create a REST API",
                "starting_agent": "architect",
                "max_iterations": 10,
            },
        )
```

**Scenario 2: Vector Search Performance**
```python
# tests/performance/benchmark_vector_search.py
import asyncio
import time
from statistics import mean, stdev

async def benchmark_vector_search(vector_store, num_queries=1000):
    """Benchmark vector search performance."""
    latencies = []

    for _ in range(num_queries):
        query_embedding = [random.uniform(-1, 1) for _ in range(1536)]

        start = time.perf_counter()
        results = await vector_store.search(query_embedding, top_k=10)
        end = time.perf_counter()

        latencies.append((end - start) * 1000)  # Convert to ms

    return {
        "mean_latency_ms": mean(latencies),
        "p95_latency_ms": sorted(latencies)[int(0.95 * len(latencies))],
        "p99_latency_ms": sorted(latencies)[int(0.99 * len(latencies))],
        "stdev_ms": stdev(latencies),
    }
```

---

## Security Testing Strategy

### Security Testing Scope

1. **Static Application Security Testing (SAST)**
   - Code vulnerability scanning
   - Dependency vulnerability analysis
   - Secret detection

2. **Dynamic Application Security Testing (DAST)**
   - API security testing
   - Injection attack testing
   - Authentication bypass testing

3. **Dependency Scanning**
   - Known vulnerability detection
   - License compliance
   - Outdated package detection

### Security Test Suite

**Python Security Tests:**
```python
# tests/security/test_input_validation.py
import pytest
from fastapi.testclient import TestClient

def test_api_rejects_sql_injection_attempts():
    """Test API properly sanitizes SQL injection attempts."""
    client = TestClient(app)

    malicious_inputs = [
        "'; DROP TABLE users; --",
        "1' OR '1'='1",
        "admin'--",
    ]

    for input_str in malicious_inputs:
        response = client.post(
            "/api/architect/task",
            json={"content": input_str, "context": {}},
        )
        # Should either sanitize or reject
        assert response.status_code in [200, 400]

def test_api_rejects_oversized_payloads():
    """Test API rejects excessively large payloads."""
    client = TestClient(app)

    huge_content = "A" * (10 * 1024 * 1024)  # 10MB
    response = client.post(
        "/api/architect/task",
        json={"content": huge_content, "context": {}},
    )

    assert response.status_code == 413  # Payload Too Large
```

**.NET Security Tests:**
```csharp
[Fact]
public async Task Api_RejectsUnauthorizedRequests()
{
    // Arrange
    var client = _factory.CreateClient();

    // Act
    var response = await client.PostAsync(
        "/api/workflows",
        new StringContent("{}", Encoding.UTF8, "application/json")
    );

    // Assert
    response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
}

[Fact]
public async Task Api_ValidatesJwtToken()
{
    // Arrange
    var client = _factory.CreateClient();
    client.DefaultRequestHeaders.Authorization =
        new AuthenticationHeaderValue("Bearer", "invalid-token");

    // Act
    var response = await client.GetAsync("/api/workflows");

    // Assert
    response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
}
```

---

## Test Environment Management

### Environment Types

1. **Local Development**
   - Docker Compose for dependencies
   - Local test databases
   - Mocked external services

2. **CI/CD (GitHub Actions)**
   - Ephemeral test databases
   - Testcontainers for integration tests
   - Isolated parallel execution

3. **Staging**
   - Production-like environment
   - Real Azure services
   - E2E test execution

### Test Data Cleanup

**Python:**
```python
@pytest.fixture(autouse=True)
async def cleanup_test_data(vector_store, cosmos_client):
    """Cleanup test data after each test."""
    yield

    # Cleanup vector store
    await vector_store.clear()

    # Cleanup Cosmos DB test data
    # (handled by Testcontainers in integration tests)
```

**.NET:**
```csharp
public class DatabaseCleanupAttribute : BeforeAfterTestAttribute
{
    public override async Task After(MethodInfo methodUnderTest)
    {
        // Cleanup database after each test
        var fixture = /* get fixture */;
        await fixture.CleanupAsync();
    }
}
```

---

## Quality Gates and Release Criteria

### Definition of Done (Testing)

A feature is considered "done" when:

1. **Unit Tests**
   - Coverage >= target for the layer (80-85%)
   - All tests passing
   - No flaky tests

2. **Integration Tests**
   - Critical paths tested
   - All integration points verified
   - Database operations tested

3. **Code Quality**
   - Linting passes (ruff, ESLint, Roslyn)
   - Type checking passes (mypy, TypeScript)
   - No critical security vulnerabilities

4. **Performance**
   - No performance regressions
   - Latency targets met
   - Load tests pass

5. **Documentation**
   - Test coverage documented
   - Known limitations documented
   - Test data requirements documented

### Release Gates

**Automated Gates (Must Pass):**
- All unit tests pass (100%)
- All integration tests pass (100%)
- Code coverage >= 85% (Python, .NET) / 80% (React)
- No critical security vulnerabilities
- No performance regressions (>10% degradation)
- Mutation score >= 75%

**Manual Gates (Required):**
- E2E test results reviewed
- Performance test results reviewed
- Security scan results reviewed
- Accessibility audit passed (WCAG 2.1 AA)

---

## Monitoring and Continuous Improvement

### Test Metrics Dashboard

Track and visualize:
- Test execution time trends
- Test pass rate over time
- Code coverage trends
- Flaky test detection
- Defect escape rate
- MTTR for test failures

### Continuous Improvement Process

**Monthly Reviews:**
1. Analyze flaky tests and eliminate root causes
2. Review slow tests and optimize
3. Update test data and fixtures
4. Refactor duplicate test code
5. Review escaped defects and add regression tests

**Quarterly Reviews:**
1. Evaluate testing tools and frameworks
2. Review test pyramid distribution
3. Assess test coverage gaps
4. Update testing strategy based on learnings
5. Performance testing benchmarks review

### Feedback Loops

**Fast Feedback (<5 min):**
- Unit test failures
- Linting and formatting errors
- Type checking errors

**Medium Feedback (<15 min):**
- Integration test failures
- Security scan results
- Code coverage reports

**Slow Feedback (<2 hours):**
- E2E test results
- Performance test results
- Mutation testing results

---

## Appendix

### Test Naming Conventions

**Python:**
```python
def test_<method>_<scenario>_<expected_outcome>():
    pass

# Examples:
def test_architect_agent_analyze_requirements_returns_analysis():
    pass

def test_vector_store_search_with_invalid_embedding_raises_error():
    pass
```

**.NET:**
```csharp
[Fact]
public void Method_Scenario_ExpectedOutcome()
{
}

// Examples:
[Fact]
public void ExecuteWorkflow_ValidRequest_ReturnsSuccess()
{
}

[Fact]
public void SaveWorkflowState_ConflictingETag_ThrowsException()
{
}
```

**TypeScript:**
```typescript
it('should <expected outcome> when <scenario>', () => {});

// Examples:
it('should render agent list when agents are loaded', () => {});
it('should disable start button when workflow is running', () => {});
```

### Test Organization

**By Feature:**
```
tests/
├── features/
│   ├── agent_workflow/
│   │   ├── test_sequential_workflow.py
│   │   ├── test_parallel_workflow.py
│   │   └── test_iterative_workflow.py
│   ├── memory_system/
│   │   ├── test_vector_search.py
│   │   └── test_context_management.py
```

**By Layer:**
```
tests/
├── unit/
├── integration/
├── e2e/
├── performance/
└── security/
```

---

**Document Status:** Active
**Next Review Date:** 2025-11-08
**Owned By:** Engineering Team
**Approved By:** Tech Lead, QA Lead
