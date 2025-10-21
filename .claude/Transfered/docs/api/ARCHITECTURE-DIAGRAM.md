# API Architecture Diagrams

## Overview Architecture

```mermaid
graph TB
    subgraph "Frontend Layer"
        React[React Application<br/>TypeScript + Vite]
    end

    subgraph ".NET Orchestrator"
        API[REST API<br/>ASP.NET Core]
        Hub[SignalR Hub<br/>WebSocket]
        ControlPlane[Control Plane Service<br/>gRPC/REST]
        CallbackHandler[Callback Handler<br/>gRPC/REST]
    end

    subgraph "Python Agents"
        Agent1[Agent 1<br/>FastAPI/gRPC]
        Agent2[Agent 2<br/>FastAPI/gRPC]
        Agent3[Agent N<br/>FastAPI/gRPC]
    end

    subgraph "Data Layer"
        DB[(PostgreSQL<br/>Workflows, Tasks)]
        Cache[(Redis<br/>Cache, Sessions)]
        Storage[(Blob Storage<br/>Artifacts)]
    end

    subgraph "Observability"
        OTEL[OpenTelemetry<br/>Collector]
        Jaeger[Jaeger<br/>Traces]
        Prom[Prometheus<br/>Metrics]
    end

    React -->|REST API<br/>CRUD Operations| API
    React <-->|SignalR<br/>Real-time Events| Hub

    API --> DB
    API --> Cache
    Hub --> Cache

    ControlPlane -->|Execute Task<br/>Get Status<br/>Cancel| Agent1
    ControlPlane -->|Execute Task<br/>Get Status<br/>Cancel| Agent2
    ControlPlane -->|Execute Task<br/>Get Status<br/>Cancel| Agent3

    Agent1 -->|Progress<br/>Completion<br/>Errors<br/>Handoffs| CallbackHandler
    Agent2 -->|Progress<br/>Completion<br/>Errors<br/>Handoffs| CallbackHandler
    Agent3 -->|Progress<br/>Completion<br/>Errors<br/>Handoffs| CallbackHandler

    CallbackHandler --> Hub
    CallbackHandler --> DB

    Agent1 --> Storage
    Agent2 --> Storage
    Agent3 --> Storage

    API --> OTEL
    ControlPlane --> OTEL
    Agent1 --> OTEL
    OTEL --> Jaeger
    OTEL --> Prom

    style React fill:#61dafb,stroke:#000,color:#000
    style API fill:#512bd4,stroke:#000,color:#fff
    style Hub fill:#512bd4,stroke:#000,color:#fff
    style ControlPlane fill:#512bd4,stroke:#000,color:#fff
    style CallbackHandler fill:#512bd4,stroke:#000,color:#fff
    style Agent1 fill:#3776ab,stroke:#000,color:#fff
    style Agent2 fill:#3776ab,stroke:#000,color:#fff
    style Agent3 fill:#3776ab,stroke:#000,color:#fff
```

---

## API Communication Flow

```mermaid
sequenceDiagram
    participant U as User (React)
    participant API as .NET API
    participant Hub as SignalR Hub
    participant CP as Control Plane
    participant Agent as Python Agent
    participant DB as Database

    Note over U,DB: Workflow Execution Flow

    U->>API: POST /v1/workflows/{id}/execute
    activate API
    API->>DB: Create Execution Record
    API->>CP: ExecuteTask(request)
    activate CP
    CP->>Agent: gRPC ExecuteTask
    activate Agent
    Agent-->>CP: TaskResponse (queued)
    deactivate Agent
    CP-->>API: TaskResponse
    deactivate CP
    API-->>U: 202 Accepted + task_id
    deactivate API

    Note over Hub,U: Real-time Updates via SignalR
    Hub->>U: WorkflowStarted event
    Hub->>U: TaskStatusChanged (pending→running)

    Note over Agent,Hub: Agent Callbacks

    loop Progress Updates
        Agent->>CP: POST /callbacks/progress
        activate CP
        CP->>DB: Update Task Progress
        CP->>Hub: Broadcast Progress
        deactivate CP
        Hub->>U: TaskProgressUpdated event
    end

    Agent->>Agent: Execute Task

    alt Success
        Agent->>CP: POST /callbacks/completion
        activate CP
        CP->>DB: Update Task (completed)
        CP->>Hub: Broadcast Completion
        deactivate CP
        Hub->>U: TaskStatusChanged (completed)
        Hub->>U: WorkflowCompleted event
    else Error
        Agent->>CP: POST /callbacks/error
        activate CP
        CP->>DB: Update Task (failed)
        CP->>Hub: Broadcast Error
        deactivate CP
        Hub->>U: ErrorOccurred event
        Hub->>U: TaskStatusChanged (failed)
    end

    U->>API: GET /v1/tasks/{id}/results
    activate API
    API->>DB: Fetch Results
    API-->>U: TaskResult + artifacts
    deactivate API
```

---

## SignalR Event Flow

```mermaid
graph LR
    subgraph "React Client"
        Client[SignalR Client]
    end

    subgraph ".NET SignalR Hub"
        Hub[AgentStudioHub]
        Groups[Groups Manager]
    end

    subgraph "Event Sources"
        Orchestrator[Orchestrator]
        Callbacks[Callback Handler]
        Agents[Agent Monitor]
    end

    subgraph "Client Groups"
        G1[workflow:wf_123]
        G2[task:task_456]
        G3[agent:agent_01]
        G4[user:user_789]
    end

    Client -->|Subscribe| Hub
    Hub --> Groups
    Groups --> G1
    Groups --> G2
    Groups --> G3
    Groups --> G4

    Orchestrator -->|WorkflowStarted<br/>WorkflowCompleted| Hub
    Callbacks -->|TaskProgressUpdated<br/>TaskStatusChanged| Hub
    Agents -->|AgentStatusChanged<br/>HeartbeatReceived| Hub

    Hub -->|Filter by Group| Groups
    Groups -->|WorkflowStarted| Client
    Groups -->|TaskProgressUpdated| Client
    Groups -->|AgentStatusChanged| Client
    Groups -->|LogMessageReceived| Client

    style Client fill:#61dafb,stroke:#000,color:#000
    style Hub fill:#512bd4,stroke:#000,color:#fff
    style Groups fill:#512bd4,stroke:#000,color:#fff
```

---

## Authentication Flow (OAuth 2.0 + PKCE)

```mermaid
sequenceDiagram
    participant User as User (Browser)
    participant App as React App
    participant Auth as Auth Server
    participant API as .NET API

    Note over User,API: Authorization Code Flow with PKCE

    User->>App: Click "Login"
    App->>App: Generate code_verifier<br/>Generate code_challenge
    App->>Auth: GET /oauth/authorize?<br/>client_id=...&<br/>code_challenge=...&<br/>code_challenge_method=S256

    Auth->>User: Show Login Page
    User->>Auth: Enter Credentials
    Auth->>User: Show Consent Page
    User->>Auth: Grant Consent

    Auth->>App: Redirect with code
    App->>Auth: POST /oauth/token<br/>code + code_verifier

    Auth->>Auth: Verify PKCE
    Auth-->>App: access_token + refresh_token

    App->>App: Store tokens securely

    Note over App,API: API Calls

    App->>API: POST /v1/tasks<br/>Authorization: Bearer {access_token}
    activate API
    API->>API: Verify JWT Signature<br/>Check Expiration<br/>Validate Scopes
    API-->>App: 202 Accepted
    deactivate API

    Note over App,Auth: Token Refresh

    App->>App: Access token expired
    App->>Auth: POST /oauth/token<br/>grant_type=refresh_token<br/>refresh_token=...
    Auth-->>App: New access_token + refresh_token
    App->>API: Retry with new token
    API-->>App: 200 OK
```

---

## Rate Limiting Architecture

```mermaid
graph TB
    subgraph "API Gateway"
        Request[Incoming Request]
        RateLimit[Rate Limiter<br/>Middleware]
        Handler[API Handler]
    end

    subgraph "Rate Limit Storage"
        Redis[(Redis<br/>Token Buckets)]
    end

    subgraph "Rate Limit Rules"
        UserTier{User Tier?}
        Endpoint{Endpoint Type?}
    end

    Request --> RateLimit
    RateLimit --> Redis
    RateLimit --> UserTier
    RateLimit --> Endpoint

    UserTier -->|Free| L1[60 req/min]
    UserTier -->|Pro| L2[600 req/min]
    UserTier -->|Enterprise| L3[3000 req/min]

    Endpoint -->|Read| E1[100 req/min]
    Endpoint -->|Write| E2[30 req/min]
    Endpoint -->|Execute| E3[20 req/min]

    RateLimit -->|Within Limit| Handler
    RateLimit -->|Exceeded| Reject[429 Too Many Requests<br/>+ Retry-After header]

    Handler --> Response[200 OK<br/>+ Rate Limit Headers]

    style Request fill:#fff,stroke:#000
    style RateLimit fill:#ff9800,stroke:#000,color:#000
    style Handler fill:#4caf50,stroke:#000,color:#fff
    style Reject fill:#f44336,stroke:#000,color:#fff
    style Redis fill:#dc382d,stroke:#000,color:#fff
```

---

## Error Handling Flow

```mermaid
graph TB
    Request[API Request] --> Validation{Validation<br/>Passed?}

    Validation -->|No| ValError[400/422<br/>Validation Error]
    Validation -->|Yes| Auth{Authenticated?}

    Auth -->|No| AuthError[401<br/>Unauthorized]
    Auth -->|Yes| Authz{Authorized?}

    Authz -->|No| AuthzError[403<br/>Forbidden]
    Authz -->|Yes| RateLimit{Rate Limit<br/>OK?}

    RateLimit -->|No| RateLimitError[429<br/>Rate Limit Exceeded]
    RateLimit -->|Yes| Business{Business<br/>Logic}

    Business -->|Not Found| NotFound[404<br/>Not Found]
    Business -->|Conflict| Conflict[409<br/>Conflict]
    Business -->|Error| ServerError{Error Type?}
    Business -->|Success| Success[200/201/202<br/>Success]

    ServerError -->|Transient| Transient[503<br/>Service Unavailable<br/>+ Retry-After]
    ServerError -->|Permanent| Internal[500<br/>Internal Server Error]

    ValError --> RFC7807[RFC 7807<br/>Problem Details]
    AuthError --> RFC7807
    AuthzError --> RFC7807
    RateLimitError --> RFC7807
    NotFound --> RFC7807
    Conflict --> RFC7807
    Transient --> RFC7807
    Internal --> RFC7807

    RFC7807 --> Response[Error Response<br/>+ Trace ID<br/>+ Error Details]

    style Success fill:#4caf50,stroke:#000,color:#fff
    style ValError fill:#ff9800,stroke:#000,color:#000
    style AuthError fill:#f44336,stroke:#000,color:#fff
    style AuthzError fill:#f44336,stroke:#000,color:#fff
    style RateLimitError fill:#ff9800,stroke:#000,color:#000
    style NotFound fill:#ff9800,stroke:#000,color:#000
    style Conflict fill:#ff9800,stroke:#000,color:#000
    style Transient fill:#ff9800,stroke:#000,color:#000
    style Internal fill:#f44336,stroke:#000,color:#fff
    style RFC7807 fill:#2196f3,stroke:#000,color:#fff
```

---

## gRPC vs REST Decision Tree

```mermaid
graph TB
    Start{API Consumer?}

    Start -->|Browser/Frontend| UseBrowser{Need Real-time?}
    Start -->|Backend Service| UseBackend{Traffic Pattern?}

    UseBrowser -->|Yes| UseSignalR[Use SignalR<br/>WebSocket]
    UseBrowser -->|No| UseREST[Use REST API<br/>JSON over HTTP]

    UseBackend -->|High Frequency| UseGRPC[Use gRPC<br/>Protobuf over HTTP/2]
    UseBackend -->|Low Frequency| UseRESTBackend{Need Streaming?}

    UseRESTBackend -->|Yes| UseGRPC
    UseRESTBackend -->|No| UseRESTService[Use REST API<br/>JSON over HTTP]

    UseSignalR --> Implement1[Implement:<br/>SignalR Hub Contract]
    UseREST --> Implement2[Implement:<br/>Frontend API<br/>OpenAPI Spec]
    UseGRPC --> Implement3[Implement:<br/>gRPC Services<br/>.proto schemas]
    UseRESTService --> Implement4[Implement:<br/>Control Plane API<br/>OpenAPI Spec]

    style Start fill:#2196f3,stroke:#000,color:#fff
    style UseSignalR fill:#4caf50,stroke:#000,color:#fff
    style UseREST fill:#4caf50,stroke:#000,color:#fff
    style UseGRPC fill:#4caf50,stroke:#000,color:#fff
    style UseRESTService fill:#4caf50,stroke:#000,color:#fff
```

---

## Deployment Architecture

```mermaid
graph TB
    subgraph "Load Balancer"
        LB[Azure Load Balancer<br/>or AWS ALB]
    end

    subgraph "API Gateway"
        Gateway[API Gateway<br/>Rate Limiting, Auth]
    end

    subgraph "Kubernetes Cluster"
        subgraph "Frontend Pods"
            React1[React App 1]
            React2[React App 2]
            React3[React App N]
        end

        subgraph "API Pods"
            API1[.NET API 1]
            API2[.NET API 2]
            API3[.NET API N]
        end

        subgraph "Agent Pods"
            Agent1[Python Agent 1]
            Agent2[Python Agent 2]
            Agent3[Python Agent N]
        end
    end

    subgraph "Data Layer"
        DB[(PostgreSQL<br/>Primary + Replicas)]
        Cache[(Redis Cluster<br/>3 nodes)]
        Storage[(Blob Storage<br/>Azure/S3)]
    end

    subgraph "Observability"
        OTEL[OTEL Collector]
        Jaeger[Jaeger]
        Prom[Prometheus]
        Grafana[Grafana]
    end

    Internet((Internet)) --> LB
    LB --> Gateway
    Gateway --> React1
    Gateway --> React2
    Gateway --> React3

    React1 --> API1
    React2 --> API2
    React3 --> API3

    API1 <--> Agent1
    API2 <--> Agent2
    API3 <--> Agent3

    API1 --> DB
    API2 --> DB
    API3 --> DB

    API1 --> Cache
    API2 --> Cache
    API3 --> Cache

    Agent1 --> Storage
    Agent2 --> Storage
    Agent3 --> Storage

    API1 --> OTEL
    API2 --> OTEL
    Agent1 --> OTEL
    Agent2 --> OTEL

    OTEL --> Jaeger
    OTEL --> Prom
    Prom --> Grafana

    style Internet fill:#fff,stroke:#000
    style LB fill:#ff9800,stroke:#000,color:#000
    style Gateway fill:#ff9800,stroke:#000,color:#000
```

---

## Monitoring Dashboard Layout

```mermaid
graph TB
    subgraph "Grafana Dashboard"
        subgraph "System Metrics"
            CPU[CPU Usage<br/>Time Series]
            Memory[Memory Usage<br/>Time Series]
            Network[Network I/O<br/>Time Series]
        end

        subgraph "API Metrics"
            ReqRate[Request Rate<br/>Counter Graph]
            Latency[Latency p50/p95/p99<br/>Histogram]
            Errors[Error Rate<br/>Pie Chart]
        end

        subgraph "Business Metrics"
            Tasks[Active Tasks<br/>Gauge]
            Workflows[Workflow Executions<br/>Bar Chart]
            Agents[Agent Status<br/>Status Panel]
        end

        subgraph "Alerts"
            Alert1[High Error Rate<br/>> 1%]
            Alert2[High Latency<br/>p95 > 500ms]
            Alert3[Agent Offline<br/>> 5 min]
        end
    end

    subgraph "Data Sources"
        Prometheus[(Prometheus)]
        Jaeger[(Jaeger)]
        Logs[(Elasticsearch)]
    end

    Prometheus --> CPU
    Prometheus --> Memory
    Prometheus --> Network
    Prometheus --> ReqRate
    Prometheus --> Latency
    Prometheus --> Errors
    Prometheus --> Tasks
    Prometheus --> Workflows
    Prometheus --> Agents

    Prometheus --> Alert1
    Prometheus --> Alert2
    Prometheus --> Alert3

    style CPU fill:#4caf50,stroke:#000,color:#fff
    style Memory fill:#4caf50,stroke:#000,color:#fff
    style Network fill:#4caf50,stroke:#000,color:#fff
    style Alert1 fill:#f44336,stroke:#000,color:#fff
    style Alert2 fill:#f44336,stroke:#000,color:#fff
    style Alert3 fill:#f44336,stroke:#000,color:#fff
```

---

## API Lifecycle Management

```mermaid
graph LR
    Design[1. API Design<br/>OpenAPI/Protobuf] --> Mock[2. Mock Server<br/>Prism/gRPC Mock]
    Mock --> Contract[3. Contract Tests<br/>Pact/Spectral]
    Contract --> Implement[4. Implementation<br/>.NET/Python]
    Implement --> Test[5. Integration Tests<br/>Postman/k6]
    Test --> Deploy[6. Deployment<br/>Kubernetes]
    Deploy --> Monitor[7. Monitoring<br/>Grafana/Jaeger]
    Monitor --> Version[8. Versioning<br/>Deprecation]
    Version --> Design

    style Design fill:#2196f3,stroke:#000,color:#fff
    style Mock fill:#4caf50,stroke:#000,color:#fff
    style Contract fill:#4caf50,stroke:#000,color:#fff
    style Implement fill:#ff9800,stroke:#000,color:#000
    style Test fill:#4caf50,stroke:#000,color:#fff
    style Deploy fill:#9c27b0,stroke:#000,color:#fff
    style Monitor fill:#9c27b0,stroke:#000,color:#fff
    style Version fill:#2196f3,stroke:#000,color:#fff
```

---

## Complete Data Flow Example

```mermaid
sequenceDiagram
    participant User
    participant React
    participant API
    participant Hub
    participant CP as Control Plane
    participant Agent
    participant DB
    participant Storage
    participant OTEL

    Note over User,OTEL: Complete Workflow Execution

    User->>React: Click "Execute Workflow"
    React->>API: POST /v1/workflows/{id}/execute

    activate API
    API->>DB: Create Execution
    API->>OTEL: Trace: CreateExecution
    API->>CP: ExecuteTask(request)

    activate CP
    CP->>OTEL: Trace: ExecuteTask
    CP->>Agent: gRPC ExecuteTask

    activate Agent
    Agent->>DB: Create Task Record
    Agent->>OTEL: Trace: TaskStarted
    Agent-->>CP: TaskResponse (queued)
    deactivate Agent

    CP-->>API: TaskResponse
    deactivate CP
    API-->>React: 202 Accepted
    deactivate API

    API->>Hub: WorkflowStarted event
    Hub->>React: WorkflowStarted
    React->>User: Show "Workflow Running"

    activate Agent
    Agent->>CP: POST /callbacks/progress (20%)
    CP->>Hub: TaskProgressUpdated
    Hub->>React: Progress: 20%
    React->>User: Update Progress Bar

    Agent->>Agent: Process Data
    Agent->>OTEL: Trace: ProcessingData

    Agent->>CP: POST /callbacks/progress (60%)
    CP->>Hub: TaskProgressUpdated
    Hub->>React: Progress: 60%

    Agent->>Storage: Upload Artifacts
    Storage-->>Agent: Upload Complete

    Agent->>CP: POST /callbacks/completion
    activate CP
    CP->>DB: Update Task (completed)
    CP->>Hub: TaskStatusChanged
    CP->>Hub: WorkflowCompleted
    deactivate CP

    Hub->>React: Workflow Complete
    React->>User: Show "Success"
    deactivate Agent

    User->>React: Click "View Results"
    React->>API: GET /v1/tasks/{id}/results
    activate API
    API->>DB: Fetch Results
    API->>Storage: Get Artifact URLs
    API-->>React: Results + Artifacts
    deactivate API
    React->>User: Display Results
```

---

These diagrams provide a comprehensive visual representation of the API architecture, covering all major aspects of the system.
