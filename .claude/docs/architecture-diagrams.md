# Architecture Diagrams - Brookside BI Innovation Nexus

**Author**: Claude Code Agent (Mermaid Diagram Expert)
**Date**: October 21, 2025
**Version**: 1.0.0

This document establishes visual system architecture through Mermaid diagrams to streamline understanding of Innovation Nexus structure, workflows, and integrations.

**Best for**: Teams requiring visual documentation of system architecture, database relationships, and operational workflows.

## Table of Contents

- [System Overview](#system-overview)
- [Notion Database Relationships](#notion-database-relationships)
- [Innovation Lifecycle](#innovation-lifecycle)
- [MCP Server Integration](#mcp-server-integration)
- [Agent Coordination](#agent-coordination)
- [Authentication Flow](#authentication-flow)

---

## System Overview

High-level architecture showing major components and integrations:

```mermaid
graph TB
    subgraph "Claude Code Environment"
        CC[Claude Code Agent]
        AS[Agent System]
        CM[Command Router]
    end

    subgraph "MCP Servers"
        NM[Notion MCP]
        GM[GitHub MCP]
        AM[Azure MCP]
        PM[Playwright MCP]
    end

    subgraph "External Services"
        N[(Notion Workspace)]
        GH[GitHub Organization]
        AZ[Azure Subscription]
        KV[(Azure Key Vault)]
    end

    CC --> AS
    CC --> CM
    AS --> NM
    AS --> GM
    AS --> AM
    AS --> PM

    NM --> N
    GM --> GH
    AM --> AZ
    AM --> KV
    PM --> Browser[Web Browser]

    style CC fill:#4A90E2
    style AS fill:#7ED321
    style NM fill:#F5A623
    style GM fill:#BD10E0
    style AM fill:#50E3C2
    style PM fill:#B8E986
```

---

## Notion Database Relationships

Entity relationship diagram showing Innovation Nexus database structure:

```mermaid
erDiagram
    IDEAS_REGISTRY ||--o{ RESEARCH_HUB : "triggers research"
    IDEAS_REGISTRY ||--o{ EXAMPLE_BUILDS : "leads to"
    IDEAS_REGISTRY ||--o{ SOFTWARE_TRACKER : "requires"
    IDEAS_REGISTRY ||--o{ OKRS : "aligns with"

    RESEARCH_HUB ||--o{ EXAMPLE_BUILDS : "recommends build"
    RESEARCH_HUB ||--o{ SOFTWARE_TRACKER : "uses tools"
    RESEARCH_HUB ||--o{ KNOWLEDGE_VAULT : "generates learnings"

    EXAMPLE_BUILDS ||--o{ SOFTWARE_TRACKER : "consumes services"
    EXAMPLE_BUILDS ||--o{ KNOWLEDGE_VAULT : "documents lessons"
    EXAMPLE_BUILDS ||--o{ INTEGRATION_REGISTRY : "registers integrations"

    SOFTWARE_TRACKER ||--o{ INTEGRATION_REGISTRY : "authenticated via"

    IDEAS_REGISTRY {
        string idea_title PK
        string status
        string viability
        string champion
        string innovation_type
        int impact_score
        string effort
    }

    RESEARCH_HUB {
        string research_title PK
        string status
        string viability_assessment
        string next_steps
        string hypothesis
        string methodology
    }

    EXAMPLE_BUILDS {
        string build_name PK
        string status
        string build_type
        string viability
        string reusability
        string github_url
        string lead_builder
    }

    SOFTWARE_TRACKER {
        string software_name PK
        decimal cost
        int license_count
        string status
        string category
        string microsoft_service
    }

    KNOWLEDGE_VAULT {
        string title PK
        string content_type
        string status
        string evergreen_dated
    }

    INTEGRATION_REGISTRY {
        string integration_name PK
        string integration_type
        string authentication_method
        string security_review_status
    }

    OKRS {
        string objective PK
        string status
        int progress_percentage
    }
```

---

## Innovation Lifecycle

Complete workflow from idea to knowledge capture:

```mermaid
stateDiagram-v2
    [*] --> Concept: New Idea
    Concept --> NeedsResearch: Viability = Needs Research
    Concept --> Active: Viability = High/Medium
    Concept --> Archived: Not Viable

    NeedsResearch --> ResearchActive: Start Research
    ResearchActive --> ViabilityAssessment: Complete Research

    ViabilityAssessment --> HighlyViable: Highly Viable
    ViabilityAssessment --> ModeratelyViable: Moderately Viable
    ViabilityAssessment --> NotViable: Not Viable
    ViabilityAssessment --> Inconclusive: Needs More Research

    HighlyViable --> BuildExample: Decision: Build
    ModeratelyViable --> BuildExample: Decision: Build
    Inconclusive --> ResearchActive: More Investigation

    BuildExample --> DevelopmentActive: Create Build Entry
    DevelopmentActive --> BuildCompleted: Implementation Finished
    BuildCompleted --> KnowledgeCapture: Archive with Learnings

    KnowledgeCapture --> KnowledgeVault: Document Reusability
    KnowledgeVault --> [*]: Archived for Reference

    NotViable --> Archived: Document Why
    Archived --> [*]

    note right of Concept
        Status: Concept
        Owner: Champion Assigned
        Cost: Estimated
    end note

    note right of ResearchActive
        Status: Active
        Hypothesis: Defined
        Methodology: Documented
    end note

    note right of DevelopmentActive
        Status: Active
        GitHub: Repository Created
        Azure: Resources Provisioned
    end note

    note right of KnowledgeVault
        Status: Archived
        Lessons: Captured
        Reusability: Assessed
    end note
```

---

## MCP Server Integration

Authentication and communication flow:

```mermaid
sequenceDiagram
    participant User
    participant Claude as Claude Code
    participant Notion as Notion MCP
    participant GitHub as GitHub MCP
    participant Azure as Azure MCP
    participant KV as Azure Key Vault

    Note over User,KV: Authentication Setup Phase

    User->>Azure: az login
    Azure-->>User: ✓ Authenticated

    User->>Claude: Launch Claude Code
    Claude->>Notion: Check connection
    Notion-->>Claude: Requires OAuth

    Notion->>User: Open browser for OAuth
    User->>Notion: Grant workspace access
    Notion-->>Claude: ✓ Connected

    Claude->>KV: Retrieve GitHub PAT
    KV-->>Claude: ghp_token
    Claude->>GitHub: Configure with PAT
    GitHub-->>Claude: ✓ Connected

    Claude->>Azure: Use Azure CLI credentials
    Azure-->>Claude: ✓ Connected

    Note over User,KV: Operational Phase

    User->>Claude: Create new idea
    Claude->>Notion: Search for duplicates
    Notion-->>Claude: No duplicates found
    Claude->>Notion: Create Ideas Registry entry
    Notion-->>Claude: Entry created

    Claude->>GitHub: Create repository
    GitHub-->>Claude: Repository URL
    Claude->>Notion: Link GitHub URL to idea
    Notion-->>Claude: ✓ Updated

    Claude->>Azure: Provision resources
    Azure-->>Claude: Resource IDs
    Claude->>Notion: Link Azure resources
    Notion-->>Claude: ✓ Complete
```

---

## Agent Coordination

Multi-agent workflow for complex operations:

```mermaid
graph TB
    User[User Request]
    Router{Command Router}

    subgraph "Innovation Agents"
        Ideas[@ideas-capture]
        Research[@research-coordinator]
        Build[@build-architect]
        Archive[@archive-manager]
    end

    subgraph "Analysis Agents"
        Cost[@cost-analyst]
        Viability[@viability-assessor]
        Workflow[@workflow-router]
    end

    subgraph "Technical Agents"
        Integration[@integration-specialist]
        Schema[@schema-manager]
        NotionMCP[@notion-mcp-specialist]
        Repo[@repo-analyzer]
    end

    subgraph "Documentation Agents"
        Knowledge[@knowledge-curator]
        Markdown[@markdown-expert]
        Mermaid[@mermaid-diagram-expert]
    end

    User --> Router

    Router -->|/innovation:new-idea| Ideas
    Router -->|/innovation:start-research| Research
    Router -->|Create build| Build
    Router -->|/knowledge:archive| Archive

    Ideas --> Cost
    Ideas --> Workflow
    Ideas --> Viability

    Research --> Cost
    Research --> Integration
    Research --> Viability

    Build --> Integration
    Build --> Cost
    Build --> Repo
    Build --> Workflow

    Archive --> Knowledge
    Knowledge --> Markdown

    Integration --> Schema
    Integration --> NotionMCP

    Build -.->|GitHub ops| Repo
    Build -.->|Azure ops| Integration
    Knowledge -.->|Diagrams| Mermaid

    style User fill:#4A90E2
    style Router fill:#F5A623
    style Ideas fill:#7ED321
    style Cost fill:#BD10E0
    style Integration fill:#50E3C2
```

---

## Authentication Flow

Secure credential management through Azure Key Vault:

```mermaid
flowchart TD
    Start([Start Setup])
    AzLogin[Azure CLI Login]
    VerifyKV{Key Vault<br/>Access?}
    SetEnv[Set Environment Variables]
    LaunchClaude[Launch Claude Code]
    NotionOAuth[Notion OAuth Flow]
    Verify{All MCP<br/>Connected?}
    Ready([Ready to Use])
    Error([Troubleshooting<br/>Required])

    Start --> AzLogin
    AzLogin --> VerifyKV

    VerifyKV -->|Yes| SetEnv
    VerifyKV -->|No| RequestAccess[Request Key Vault<br/>Permissions]
    RequestAccess --> VerifyKV

    SetEnv --> LaunchClaude
    LaunchClaude --> NotionOAuth
    NotionOAuth --> Verify

    Verify -->|Yes| Ready
    Verify -->|No| Error

    subgraph "Environment Configuration"
        SetEnv
        KV[(Key Vault)]
        PAT[GitHub PAT]
        NotionKey[Notion API Key]

        SetEnv --> KV
        KV --> PAT
        KV --> NotionKey
        PAT --> ENV1[GITHUB_PERSONAL_ACCESS_TOKEN]
        NotionKey --> ENV2[NOTION_API_KEY]
    end

    subgraph "MCP Server Connection"
        LaunchClaude
        Notion[Notion MCP]
        GitHub[GitHub MCP]
        Azure[Azure MCP]
        Playwright[Playwright MCP]

        LaunchClaude --> Notion
        LaunchClaude --> GitHub
        LaunchClaude --> Azure
        LaunchClaude --> Playwright
    end

    style Start fill:#4A90E2
    style Ready fill:#7ED321
    style Error fill:#D0021B
    style VerifyKV fill:#F5A623
    style Verify fill:#F5A623
```

---

## Autonomous Pipeline Flow

Self-managing innovation workflow:

```mermaid
sequenceDiagram
    participant I as Ideas Registry
    participant AP as Autonomous Platform
    participant R as Research Hub
    participant V as Viability Assessor
    participant B as Example Builds
    participant K as Knowledge Vault

    Note over I,K: Autonomous Workflow Activation

    I->>AP: Idea Status = "Needs Research"
    AP->>R: Auto-create Research Entry
    R-->>AP: Research Created

    Note over AP,R: Autonomous Research Phase

    AP->>R: Monitor Research Status
    R->>AP: Status = "Completed"
    AP->>V: Assess Viability
    V-->>AP: Viability = "Highly Viable"

    alt Highly Viable or Moderately Viable
        AP->>B: Auto-create Build Entry
        B-->>AP: Build Created
        AP->>I: Update Next Steps
        Note over B: Developer implements build
    else Not Viable or Inconclusive
        AP->>I: Update with Assessment
        AP->>K: Archive Decision Rationale
    end

    Note over B,K: Autonomous Completion

    B->>AP: Build Status = "Completed"
    AP->>K: Auto-create Knowledge Entry
    K-->>AP: Knowledge Captured
    AP->>B: Update Status = "Archived"
    AP->>I: Mark Complete

    Note over I,K: Human Decision Points (Minimal)

    rect rgb(255, 240, 200)
        Note over I: Human reviews viability<br/>before build creation
        Note over B: Human completes<br/>implementation work
        Note over K: Human reviews<br/>knowledge documentation
    end
```

---

## Related Documentation

- [CLAUDE.md](../CLAUDE.md) - Complete system documentation
- [API References](api/) - MCP server operations
- [Architectural Patterns](.claude/docs/patterns/) - Enterprise patterns
- [Agent Directory](.claude/agents/) - Specialized agent specifications

---

**Best for**: Teams requiring visual system documentation to understand architecture, workflows, and integration patterns across Innovation Nexus infrastructure.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
