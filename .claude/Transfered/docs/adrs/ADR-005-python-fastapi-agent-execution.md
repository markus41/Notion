# ADR-005: Python with FastAPI for Agent Execution Layer

## Status
Accepted

## Context

Agent Studio requires an execution runtime for AI agents that can:

- Integrate with Azure OpenAI and multiple LLM providers
- Execute specialized agent types (Architect, Builder, Validator, Scribe)
- Support asynchronous task processing with high concurrency
- Stream responses for long-running agent executions
- Integrate with AI/ML libraries and frameworks (LangChain, Semantic Kernel)
- Handle dynamic prompt templates with variable substitution
- Manage token limits and context window constraints
- Provide rich error handling and retry logic

### Requirements

1. **LLM Integration:** First-class support for Azure OpenAI, OpenAI, and future providers
2. **Async Operations:** Handle 100+ concurrent agent executions without blocking
3. **Streaming Support:** Server-sent events for real-time agent output
4. **Type Safety:** Strong typing for request/response validation
5. **Performance:** Sub-second cold start, 10K+ requests/hour throughput
6. **Developer Experience:** Simple API design, comprehensive documentation
7. **Testing:** High test coverage (85%+) with mocked LLM responses
8. **Observability:** Distributed tracing, structured logging, metrics
9. **Azure Integration:** Seamless deployment to Azure Container Apps

### Constraints

- Must integrate with existing .NET orchestration layer via HTTP/JSON
- Must support Python 3.12+ for latest async features
- Must run in containerized environment (Docker)
- Must handle variable memory footprint (model weights, context)
- Must implement secure secret management (Key Vault)
- Must support horizontal scaling (stateless design)

## Decision

We will implement the **Agent Execution Layer using Python 3.12 with FastAPI framework**, leveraging:

- **Python 3.12:** Latest async/await features, performance improvements
- **FastAPI 0.110+:** Modern async web framework with automatic API docs
- **Pydantic v2:** Data validation and serialization with type hints
- **Uvicorn:** ASGI server with high-performance async I/O
- **Azure OpenAI SDK:** Official Python SDK for Azure OpenAI integration
- **LangChain/Semantic Kernel:** AI agent frameworks for orchestration
- **OpenTelemetry:** Distributed tracing and metrics collection

### Architecture Overview

**Service Structure:**
```
src/python/
├── meta_agents/
│   ├── api.py              # FastAPI app and routes
│   ├── agents/
│   │   ├── base.py         # BaseAgent abstract class
│   │   ├── architect.py    # System architecture agent
│   │   ├── builder.py      # Code generation agent
│   │   ├── validator.py    # Quality validation agent
│   │   └── scribe.py       # Documentation agent
│   ├── llm/
│   │   ├── client.py       # Azure OpenAI client
│   │   ├── prompts.py      # Prompt templates (Jinja2)
│   │   └── streaming.py    # SSE streaming handler
│   ├── models/
│   │   ├── requests.py     # Pydantic request models
│   │   └── responses.py    # Pydantic response models
│   ├── services/
│   │   ├── context.py      # Context management
│   │   ├── memory.py       # Conversation memory
│   │   └── tools.py        # MCP tool integration
│   └── utils/
│       ├── telemetry.py    # OpenTelemetry setup
│       ├── auth.py         # Azure AD authentication
│       └── config.py       # Configuration management
└── tests/
    ├── unit/
    ├── integration/
    └── fixtures/           # Mocked LLM responses
```

### FastAPI Application

**Main Application (api.py):**
```python
from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from azure.identity import DefaultAzureCredential
from azure.monitor.opentelemetry import configure_azure_monitor

from meta_agents.models import AgentTaskRequest, AgentResult
from meta_agents.agents import get_agent
from meta_agents.llm import AzureOpenAIClient
from meta_agents.utils import get_config

# Initialize FastAPI app
app = FastAPI(
    title="Agent Studio - Meta Agents API",
    description="AI agent execution service for Agent Studio platform",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configure Azure Monitor
configure_azure_monitor(
    connection_string=get_config().app_insights_connection_string,
    logger_name="meta_agents"
)

# Instrument FastAPI
FastAPIInstrumentor.instrument_app(app)

# Dependency injection
def get_llm_client() -> AzureOpenAIClient:
    credential = DefaultAzureCredential()
    return AzureOpenAIClient(
        endpoint=get_config().azure_openai_endpoint,
        credential=credential
    )

@app.post("/api/agents/execute", response_model=AgentResult)
async def execute_agent_task(
    request: AgentTaskRequest,
    llm_client: AzureOpenAIClient = Depends(get_llm_client)
) -> AgentResult:
    """
    Execute an agent task synchronously.

    Args:
        request: Agent task request with type, prompt, and context
        llm_client: Azure OpenAI client instance

    Returns:
        AgentResult with output, metadata, and metrics

    Raises:
        HTTPException: If agent execution fails
    """
    try:
        agent = get_agent(request.agent_type, llm_client)
        result = await agent.execute(
            prompt=request.prompt,
            context=request.context,
            max_tokens=request.max_tokens,
            temperature=request.temperature
        )
        return result
    except Exception as e:
        logger.error(f"Agent execution failed: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/agents/stream")
async def stream_agent_execution(
    request: AgentTaskRequest,
    llm_client: AzureOpenAIClient = Depends(get_llm_client)
):
    """
    Stream agent execution results via Server-Sent Events.

    Returns:
        StreamingResponse with real-time agent output
    """
    from fastapi.responses import StreamingResponse

    agent = get_agent(request.agent_type, llm_client)

    async def generate():
        async for chunk in agent.stream(request.prompt, request.context):
            yield f"data: {chunk.json()}\n\n"

    return StreamingResponse(generate(), media_type="text/event-stream")

@app.get("/api/agents/capabilities")
async def get_agent_capabilities():
    """List available agent types and their capabilities."""
    return {
        "agents": [
            {
                "type": "Architect",
                "description": "Designs system architecture and technical specifications",
                "capabilities": ["system-design", "architecture-review", "technology-selection"]
            },
            {
                "type": "Builder",
                "description": "Generates code and implementation artifacts",
                "capabilities": ["code-generation", "scaffolding", "refactoring"]
            },
            {
                "type": "Validator",
                "description": "Validates outputs against quality gates",
                "capabilities": ["quality-checks", "validation", "feedback"]
            },
            {
                "type": "Scribe",
                "description": "Generates comprehensive documentation",
                "capabilities": ["documentation", "technical-writing", "api-specs"]
            }
        ]
    }

@app.get("/health")
async def health_check():
    """Health check endpoint for container orchestrator."""
    return {"status": "healthy", "service": "meta-agents"}
```

### Base Agent Implementation

**BaseAgent (agents/base.py):**
```python
from abc import ABC, abstractmethod
from typing import Dict, Any, AsyncIterator
from opentelemetry import trace

from meta_agents.llm import AzureOpenAIClient
from meta_agents.models import AgentResult

tracer = trace.get_tracer(__name__)

class BaseAgent(ABC):
    """Base class for all AI agents."""

    def __init__(self, llm_client: AzureOpenAIClient):
        self.llm_client = llm_client
        self.agent_type = self.__class__.__name__

    @abstractmethod
    async def process(
        self,
        prompt: str,
        context: Dict[str, Any],
        **kwargs
    ) -> AgentResult:
        """
        Process agent task and return result.

        Args:
            prompt: User prompt or task description
            context: Shared context from previous tasks
            **kwargs: Additional agent-specific parameters

        Returns:
            AgentResult with output and metadata
        """
        pass

    @trace_span("agent_execution")
    async def execute(
        self,
        prompt: str,
        context: Dict[str, Any] = None,
        max_tokens: int = 4000,
        temperature: float = 0.7
    ) -> AgentResult:
        """
        Execute agent with telemetry and error handling.

        This method wraps the process() method with:
        - Distributed tracing
        - Error handling and retry logic
        - Metrics collection
        - Logging
        """
        with tracer.start_as_current_span("agent.execute") as span:
            span.set_attribute("agent.type", self.agent_type)
            span.set_attribute("prompt.length", len(prompt))

            try:
                result = await self.process(
                    prompt=prompt,
                    context=context or {},
                    max_tokens=max_tokens,
                    temperature=temperature
                )

                span.set_attribute("result.token_count", result.token_usage.total)
                span.set_attribute("result.duration_ms", result.duration_ms)

                return result
            except Exception as e:
                span.record_exception(e)
                span.set_status(trace.Status(trace.StatusCode.ERROR))
                raise

    async def stream(
        self,
        prompt: str,
        context: Dict[str, Any] = None
    ) -> AsyncIterator[str]:
        """
        Stream agent output in real-time.

        Yields:
            Partial results as they become available
        """
        # Override in subclass for streaming support
        raise NotImplementedError("Streaming not supported for this agent")
```

**Architect Agent Example (agents/architect.py):**
```python
from meta_agents.agents.base import BaseAgent
from meta_agents.models import AgentResult, TokenUsage
from meta_agents.llm import AzureOpenAIClient

class ArchitectAgent(BaseAgent):
    """
    Agent specialized in system architecture and design.

    Capabilities:
    - Design scalable system architectures
    - Review existing architectures for improvements
    - Select appropriate technologies and patterns
    - Generate architecture decision records (ADRs)
    """

    SYSTEM_PROMPT = """You are a senior software architect with 15 years of experience
    designing cloud-native, scalable systems. Your expertise includes:
    - Microservices and distributed systems architecture
    - Azure cloud infrastructure and services
    - Event-driven and CQRS patterns
    - Performance optimization and scalability
    - Security and compliance best practices

    Provide detailed, actionable architectural recommendations with clear rationale.
    Include diagrams where helpful (Mermaid format).
    """

    async def process(
        self,
        prompt: str,
        context: Dict[str, Any],
        **kwargs
    ) -> AgentResult:
        """
        Generate system architecture design based on requirements.

        Args:
            prompt: Architecture requirements or design question
            context: Project context, constraints, existing systems

        Returns:
            AgentResult with architecture design and recommendations
        """
        # Build messages with system prompt and context
        messages = [
            {"role": "system", "content": self.SYSTEM_PROMPT}
        ]

        # Add context if available
        if context:
            context_str = self._format_context(context)
            messages.append({
                "role": "system",
                "content": f"Project Context:\n{context_str}"
            })

        messages.append({"role": "user", "content": prompt})

        # Call LLM
        response = await self.llm_client.chat_completion(
            messages=messages,
            temperature=kwargs.get("temperature", 0.7),
            max_tokens=kwargs.get("max_tokens", 4000),
            model="gpt-4"
        )

        return AgentResult(
            agent_type="Architect",
            output=response.choices[0].message.content,
            token_usage=TokenUsage(
                prompt=response.usage.prompt_tokens,
                completion=response.usage.completion_tokens,
                total=response.usage.total_tokens
            ),
            model=response.model,
            metadata={
                "finish_reason": response.choices[0].finish_reason,
                "context_used": bool(context)
            }
        )

    def _format_context(self, context: Dict[str, Any]) -> str:
        """Format context dictionary into readable text."""
        lines = []
        for key, value in context.items():
            lines.append(f"- {key}: {value}")
        return "\n".join(lines)
```

### Pydantic Models for Type Safety

**Request Models (models/requests.py):**
```python
from pydantic import BaseModel, Field, validator
from typing import Dict, Any, Optional, Literal

class AgentTaskRequest(BaseModel):
    """Request model for agent task execution."""

    agent_type: Literal["Architect", "Builder", "Validator", "Scribe"] = Field(
        description="Type of agent to execute"
    )
    prompt: str = Field(
        min_length=10,
        max_length=10000,
        description="Task prompt or requirements"
    )
    context: Optional[Dict[str, Any]] = Field(
        default=None,
        description="Shared context from previous tasks"
    )
    max_tokens: int = Field(
        default=4000,
        ge=100,
        le=32000,
        description="Maximum tokens in response"
    )
    temperature: float = Field(
        default=0.7,
        ge=0.0,
        le=2.0,
        description="LLM temperature (creativity)"
    )

    @validator("prompt")
    def validate_prompt(cls, v):
        if not v.strip():
            raise ValueError("Prompt cannot be empty or whitespace")
        return v.strip()

    class Config:
        schema_extra = {
            "example": {
                "agent_type": "Architect",
                "prompt": "Design a microservices architecture for an e-commerce platform",
                "context": {
                    "scale": "100K daily active users",
                    "cloud": "Azure"
                },
                "max_tokens": 4000,
                "temperature": 0.7
            }
        }
```

**Response Models (models/responses.py):**
```python
from pydantic import BaseModel, Field
from typing import Dict, Any, Optional
from datetime import datetime

class TokenUsage(BaseModel):
    """Token usage statistics."""
    prompt: int = Field(description="Tokens in prompt")
    completion: int = Field(description="Tokens in completion")
    total: int = Field(description="Total tokens used")

class AgentResult(BaseModel):
    """Agent execution result."""

    agent_type: str = Field(description="Type of agent that executed")
    output: str = Field(description="Agent output/result")
    token_usage: TokenUsage = Field(description="Token consumption")
    model: str = Field(description="LLM model used")
    duration_ms: int = Field(description="Execution duration in milliseconds")
    metadata: Optional[Dict[str, Any]] = Field(
        default=None,
        description="Additional metadata"
    )
    timestamp: datetime = Field(
        default_factory=datetime.utcnow,
        description="Result timestamp"
    )

    class Config:
        schema_extra = {
            "example": {
                "agent_type": "Architect",
                "output": "# Microservices Architecture\\n\\n## Overview\\n...",
                "token_usage": {
                    "prompt": 1200,
                    "completion": 2800,
                    "total": 4000
                },
                "model": "gpt-4",
                "duration_ms": 8500,
                "metadata": {
                    "finish_reason": "stop",
                    "context_used": True
                },
                "timestamp": "2025-10-14T10:00:00Z"
            }
        }
```

### Azure OpenAI Integration

**LLM Client (llm/client.py):**
```python
from azure.identity import DefaultAzureCredential
from openai import AsyncAzureOpenAI
from typing import List, Dict, Any
import asyncio

class AzureOpenAIClient:
    """Async client for Azure OpenAI with retry and error handling."""

    def __init__(self, endpoint: str, credential: DefaultAzureCredential):
        self.client = AsyncAzureOpenAI(
            azure_endpoint=endpoint,
            azure_ad_token_provider=credential.get_token,
            api_version="2024-02-15-preview"
        )

    async def chat_completion(
        self,
        messages: List[Dict[str, str]],
        model: str = "gpt-4",
        temperature: float = 0.7,
        max_tokens: int = 4000,
        **kwargs
    ):
        """
        Generate chat completion with retry logic.

        Args:
            messages: Conversation messages
            model: Deployment name (gpt-4, gpt-35-turbo)
            temperature: Sampling temperature
            max_tokens: Maximum response tokens

        Returns:
            OpenAI ChatCompletion response
        """
        retry_count = 0
        max_retries = 3

        while retry_count < max_retries:
            try:
                response = await self.client.chat.completions.create(
                    model=model,
                    messages=messages,
                    temperature=temperature,
                    max_tokens=max_tokens,
                    **kwargs
                )
                return response
            except Exception as e:
                retry_count += 1
                if retry_count >= max_retries:
                    raise

                # Exponential backoff
                wait_time = 2 ** retry_count
                logger.warning(
                    f"LLM call failed, retrying in {wait_time}s... (attempt {retry_count}/{max_retries})"
                )
                await asyncio.sleep(wait_time)
```

### Testing Strategy

**Unit Tests with Mocked LLM (tests/unit/test_architect_agent.py):**
```python
import pytest
from unittest.mock import AsyncMock, MagicMock
from meta_agents.agents import ArchitectAgent
from meta_agents.models import AgentResult

@pytest.fixture
def mock_llm_client():
    client = AsyncMock()
    client.chat_completion.return_value = MagicMock(
        choices=[
            MagicMock(
                message=MagicMock(content="# Architecture Design\n\n..."),
                finish_reason="stop"
            )
        ],
        usage=MagicMock(prompt_tokens=1200, completion_tokens=2800, total_tokens=4000),
        model="gpt-4"
    )
    return client

@pytest.mark.asyncio
async def test_architect_agent_execute(mock_llm_client):
    """Test architect agent executes successfully."""
    agent = ArchitectAgent(mock_llm_client)

    result = await agent.execute(
        prompt="Design a scalable API",
        context={"scale": "10K RPS"}
    )

    assert isinstance(result, AgentResult)
    assert result.agent_type == "Architect"
    assert result.token_usage.total == 4000
    assert "Architecture Design" in result.output

    # Verify LLM was called with correct parameters
    mock_llm_client.chat_completion.assert_called_once()
```

**Integration Tests (tests/integration/test_api.py):**
```python
import pytest
from fastapi.testclient import TestClient
from meta_agents.api import app

client = TestClient(app)

def test_execute_agent_endpoint():
    """Test agent execution endpoint."""
    response = client.post(
        "/api/agents/execute",
        json={
            "agent_type": "Architect",
            "prompt": "Design a microservices architecture",
            "max_tokens": 2000,
            "temperature": 0.7
        }
    )

    assert response.status_code == 200
    data = response.json()
    assert data["agent_type"] == "Architect"
    assert "output" in data
    assert "token_usage" in data
```

### Performance Considerations

**Async I/O Throughout:**
```python
# All LLM calls are async
async def process(self, prompt: str, context: Dict[str, Any]) -> AgentResult:
    response = await self.llm_client.chat_completion(...)  # No blocking
    return AgentResult(...)
```

**Connection Pooling:**
```python
# AsyncAzureOpenAI uses connection pooling by default
client = AsyncAzureOpenAI(
    max_retries=3,
    timeout=60.0,
    http_client=httpx.AsyncClient(
        limits=httpx.Limits(max_connections=100, max_keepalive_connections=20)
    )
)
```

**Concurrency Limits:**
```python
# Limit concurrent LLM calls to avoid rate limiting
semaphore = asyncio.Semaphore(10)  # Max 10 concurrent calls

async def execute_with_limit(self, prompt, context):
    async with semaphore:
        return await self.execute(prompt, context)
```

## Consequences

### Positive

1. **Excellent AI/ML Ecosystem**
   - Rich library support (LangChain, Semantic Kernel, Hugging Face)
   - Native async/await support in Python 3.12
   - Strong community and documentation
   - Easy integration with Azure OpenAI SDK

2. **Developer Productivity**
   - FastAPI auto-generates OpenAPI/Swagger docs
   - Pydantic provides runtime type validation
   - Simple, intuitive API design
   - Excellent IDE support with type hints

3. **Performance**
   - Async I/O handles 100+ concurrent requests efficiently
   - Uvicorn ASGI server with high throughput
   - Minimal memory overhead for stateless operations
   - Fast cold start (< 1 second)

4. **Type Safety**
   - Pydantic validates all request/response data
   - Type hints enable static analysis (mypy)
   - Automatic API documentation from types
   - Reduces runtime errors

5. **Testing**
   - Easy to mock LLM responses for unit tests
   - pytest-asyncio for async test support
   - High test coverage achievable (85%+)
   - Fast test execution (mocked LLM calls)

6. **Observability**
   - OpenTelemetry auto-instrumentation
   - Distributed tracing across services
   - Structured logging with context
   - Custom metrics integration

### Negative

1. **Runtime Performance**
   - Python slower than compiled languages (.NET, Go)
   - GIL limits true parallelism for CPU-bound tasks
   - Higher memory usage than .NET/Go
   - **Mitigation:** Use async I/O (most operations are I/O-bound), horizontal scaling

2. **Dependency Management**
   - Python package ecosystem can have conflicts
   - Virtual environments required for isolation
   - Docker images larger than .NET (400MB+ vs 200MB)
   - **Mitigation:** Use pipenv/poetry, multi-stage Docker builds

3. **Type Safety Limitations**
   - Runtime type checking (not compile-time)
   - Type hints optional (can be ignored)
   - mypy not enforced by default
   - **Mitigation:** Strict mypy config, Pydantic validation, CI/CD type checks

4. **Cold Start Latency**
   - Python import overhead (0.5-1s cold start)
   - Larger memory footprint during startup
   - **Mitigation:** Keep containers warm, use smaller base images

## Alternatives Considered

### .NET (C#) for Everything

**Pros:**
- Unified codebase (same as orchestration layer)
- Better performance for CPU-bound tasks
- Compile-time type safety
- Smaller memory footprint

**Cons:**
- Weaker AI/ML ecosystem than Python
- Fewer LLM libraries and frameworks
- Steeper learning curve for AI developers
- Less community support for AI use cases

**Decision:** Rejected; Python's AI/ML ecosystem is superior and critical for agent development.

### Node.js with TypeScript

**Pros:**
- Single language across frontend and backend
- Excellent async I/O performance
- Strong type safety with TypeScript
- Good LLM SDK support

**Cons:**
- Weaker AI/ML ecosystem than Python
- Less mature LLM agent frameworks
- Callback complexity for advanced patterns
- Smaller community for AI use cases

**Decision:** Rejected; Python more suitable for AI/ML workloads.

### Go

**Pros:**
- Excellent performance and concurrency
- Small binary size and fast startup
- Strong standard library
- Low memory footprint

**Cons:**
- Very limited AI/ML ecosystem
- Minimal LLM integration libraries
- Verbose error handling
- Smaller community for AI development

**Decision:** Rejected; insufficient AI/ML library support.

## Implementation Notes

### Phase 1: Core Agents (Completed)
- FastAPI service with 4 agent types
- Azure OpenAI integration
- Pydantic request/response validation
- Unit tests with mocked LLMs (85% coverage)
- OpenTelemetry instrumentation

### Phase 2: Advanced Features (Next 2 months)
- Streaming responses via SSE
- LangChain integration for complex workflows
- Vector database for agent memory (Azure AI Search)
- Custom tool integration (MCP protocol)
- Enhanced error handling and retry logic

### Phase 3: Optimization (3-6 months)
- Local model support (Llama, Mistral)
- Prompt caching to reduce costs
- Response caching for common queries
- Multi-model support (GPT-4, Claude, Gemini)
- Performance tuning (connection pooling, batching)

## References

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Pydantic Documentation](https://docs.pydantic.dev/)
- [Azure OpenAI Python SDK](https://github.com/Azure/azure-sdk-for-python/tree/main/sdk/ai/azure-ai-openai)
- [C4 Container Diagram](../architecture/c4-container.mmd)
- [Data Flow Documentation](../architecture/data-flows.md)

---

**Date:** 2025-10-14
**Authors:** Architecture Team, AI/ML Team
**Reviewers:** Engineering Leadership
**Status:** Accepted and Implemented

This decision establishes Python with FastAPI as the foundation for AI agent execution designed to streamline LLM integration with enterprise-grade performance and developer productivity.
