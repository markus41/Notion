# Team Structure & Specializations

**Purpose**: Establish clear understanding of team member expertise areas for optimal work routing and collaboration.

**Best for**: Agents performing team assignments, delegating work, or coordinating multi-member initiatives.

---

## Team Members

### Markus Ahling
**Title**: Technical Lead & AI Specialist

**Primary Focus Areas**:
- Engineering & Software Development
- Operations & Infrastructure
- AI & Machine Learning
- Cloud Architecture (Azure)
- Innovation Pipeline Management

**Assign When**:
- Technical architecture design required
- AI/ML projects or research
- Complex infrastructure decisions
- Engineering standards and best practices
- Azure integration and deployment
- Automation and tooling development

**Specializations**:
- Python, TypeScript, C# development
- Azure services (Functions, App Services, AI)
- DevOps and CI/CD pipelines
- Data engineering and ETL
- Claude Code agent development

**Contact**: markus@brooksidebi.com

---

### Brad Wright
**Title**: Sales & Business Strategy Lead

**Primary Focus Areas**:
- Sales & Business Development
- Financial Planning & Analysis
- Marketing Strategy
- Client Relationship Management
- Business Case Development

**Assign When**:
- Sales enablement tools needed
- Business strategy formulation
- Financial modeling and ROI analysis
- Marketing campaign planning
- Client-facing documentation
- Revenue optimization initiatives

**Specializations**:
- CRM systems (Dynamics 365, Salesforce)
- Financial modeling and forecasting
- Sales process optimization
- Go-to-market strategy
- Stakeholder communication

**Contact**: brad@brooksidebi.com

---

### Stephan Densby
**Title**: Operations & Research Lead

**Primary Focus Areas**:
- Operations Management
- Continuous Improvement
- Research Coordination
- Process Optimization
- Workflow Analysis

**Assign When**:
- Process improvement initiatives
- Research coordination and methodology
- Operational efficiency analysis
- Workflow documentation needed
- Cross-functional coordination
- Quality assurance processes

**Specializations**:
- Lean Six Sigma methodologies
- Research methodology design
- Process mapping and optimization
- Data analysis and reporting
- Project management

**Contact**: stephan@brooksidebi.com

---

### Alec Fielding
**Title**: DevOps & Security Specialist

**Primary Focus Areas**:
- DevOps & Infrastructure
- Engineering & Development
- Security & Compliance
- System Integrations
- R&D and Innovation

**Assign When**:
- Cloud infrastructure setup (Azure, AWS)
- Security reviews and compliance
- CI/CD pipeline development
- System integration architecture
- Container orchestration (Kubernetes)
- Infrastructure as Code (Bicep, Terraform)
- Security vulnerability assessment

**Specializations**:
- Azure/AWS cloud platforms
- Kubernetes and container technologies
- Security best practices and compliance
- GitHub Actions and Azure DevOps
- Infrastructure automation
- API integration patterns

**Contact**: alec@brooksidebi.com

---

### Mitch Bisbee
**Title**: Data Engineering & ML Lead

**Primary Focus Areas**:
- DevOps & Infrastructure
- Engineering & Development
- Machine Learning & AI
- Master Data Management
- Quality Assurance

**Assign When**:
- Data engineering pipelines
- ML model development and deployment
- Master data management strategies
- Data quality frameworks
- ETL/ELT process design
- Data warehouse architecture
- Quality assurance automation

**Specializations**:
- Python, SQL, PySpark
- ML frameworks (scikit-learn, TensorFlow)
- Data warehousing (Synapse, Databricks)
- Data quality and governance
- Test automation frameworks
- Azure Data services

**Contact**: mitch@brooksidebi.com

---

## Assignment Routing Logic

### Auto-Assignment via `/team:assign`

**Command**: `/team:assign [work-description] [database: idea|research|build]`

**Routing Algorithm**:
```
1. Parse work description for keywords
2. Match keywords to specialization areas
3. Check current workload (from Agent Activity Hub)
4. Assign to member with:
   - Highest specialization match (60%)
   - Lowest current workload (30%)
   - Recent activity in related area (10%)
5. Update Notion database with assigned person
```

**Keyword Mapping**:
```yaml
Markus Ahling:
  - AI, machine learning, ML, artificial intelligence
  - Python, TypeScript, C#, code generation
  - Azure Functions, App Services, deployment
  - Engineering, technical architecture
  - Claude Code, agents, automation

Brad Wright:
  - Sales, revenue, business development
  - Finance, financial, ROI, budget
  - Marketing, campaign, branding
  - CRM, Dynamics, Salesforce
  - Client, customer, stakeholder

Stephan Densby:
  - Process, workflow, operations
  - Research, investigation, analysis
  - Continuous improvement, optimization
  - Quality, efficiency, lean
  - Coordination, documentation

Alec Fielding:
  - DevOps, infrastructure, cloud
  - Security, compliance, vulnerability
  - Kubernetes, containers, Docker
  - CI/CD, GitHub Actions, pipelines
  - Integration, API, webhooks
  - Terraform, Bicep, IaC

Mitch Bisbee:
  - Data engineering, ETL, pipelines
  - Machine learning, model, training
  - Data quality, governance, master data
  - SQL, databases, warehousing
  - Testing, QA, test automation
  - Databricks, Synapse, Spark
```

---

## Collaboration Patterns

### Multi-Disciplinary Projects

**Architecture**: Markus + Alec
- Markus: Application design and business logic
- Alec: Infrastructure and security architecture

**Data + ML**: Mitch + Markus
- Mitch: Data pipelines and model training
- Markus: Model deployment and integration

**Business + Technical**: Brad + Markus/Alec
- Brad: Business requirements and ROI
- Markus/Alec: Technical feasibility and implementation

**Operations + Research**: Stephan + Any
- Stephan: Research coordination and process design
- Other: Domain-specific execution

---

## Handoff Procedures

### When Handing Off Work

**Required Information**:
1. **Context**: What was the original request?
2. **Progress**: What's been completed so far?
3. **Blockers**: Any issues or dependencies?
4. **Next Steps**: What needs to happen next?
5. **Files**: Links to all relevant documentation/code
6. **Decisions**: Key decisions made and rationale

**Documentation**:
- Update Agent Activity Hub with handoff status
- Add comment in related Notion item (Idea/Research/Build)
- Send direct message with handoff details
- Update todo list or project tracking

**Example Handoff**:
```markdown
## Handoff: AI Cost Optimizer Research

**To**: Mitch Bisbee
**From**: Markus Ahling (via @research-coordinator)
**Date**: 2025-10-26

**Context**: Research thread on AI-powered Azure cost optimization platform.
Market research and technical feasibility completed. Need data engineering
expertise for cost data pipeline design.

**Progress Completed**:
- ✅ Market research (85/100 viability)
- ✅ Technical architecture designed
- ✅ Azure services identified (Functions, OpenAI, Cosmos DB)

**Next Steps** (assigned to Mitch):
1. Design data ingestion pipeline for Azure cost data
2. Determine optimal storage pattern (Cosmos vs SQL)
3. Create data quality framework for cost metrics
4. Estimate pipeline costs and throughput

**Relevant Files**:
- Research Hub: [Link]
- Origin Idea: [Link]
- Architecture diagram: [Link]

**Blockers**: None currently

**Decisions Made**:
- Azure Functions for serverless compute (cost efficiency)
- Cosmos DB for flexible schema (cost data varies by resource type)
- Python for data processing (team expertise)
```

---

## Workload Management

### Current Workload Tracking

**Source**: Agent Activity Hub database
- Filter by team member (Person field)
- Status = "In Progress" or "Blocked"
- Count active work items per person

**Balanced Assignment**:
- If member has >3 active items, consider redistribution
- Urgent items take priority regardless of workload
- Specialized work goes to expert even if busy

### Capacity Planning

**Standard Capacity** (per week):
- Innovation projects: 2-3 concurrent
- Research threads: 1-2 concurrent
- Builds (active development): 1-2 concurrent
- Maintenance/support: Ongoing (10-20% time)

**Overload Indicators**:
- >3 items in "In Progress" status
- Items blocked >3 days
- Declining completion rates
- Extended session durations

---

## Specialization Matrix

| Area | Primary | Secondary | Support |
|------|---------|-----------|---------|
| **AI/ML** | Markus, Mitch | Alec | - |
| **Azure Infrastructure** | Alec, Markus | Mitch | - |
| **Data Engineering** | Mitch | Markus | Alec |
| **Security & Compliance** | Alec | Markus | - |
| **Business Strategy** | Brad | Stephan | - |
| **Research Coordination** | Stephan | All | - |
| **DevOps & CI/CD** | Alec | Markus | Mitch |
| **Process Optimization** | Stephan | Brad | All |
| **Sales Enablement** | Brad | Stephan | Markus |
| **Quality Assurance** | Mitch | Alec | Stephan |

**Key**:
- **Primary**: First choice for assignment
- **Secondary**: Can handle if primary unavailable
- **Support**: Can provide input but not lead

---

## Communication Channels

### Slack Channels
- `#innovation-nexus`: General innovation discussion
- `#technical`: Engineering and architecture
- `#research`: Research coordination
- `#cost-analysis`: Cost optimization initiatives
- `#deployments`: Deployment notifications

### Email
- Use for formal approvals and external communication
- CC relevant team members on decisions
- Subject line format: `[Category] Brief Description`

### Notion Comments
- Use for specific item discussions (Ideas, Research, Builds)
- @mention relevant team members
- Keeps context attached to work items

### Direct Messages
- Use for urgent matters requiring immediate attention
- Quick questions or clarifications
- Handoffs requiring detailed explanation

---

## Escalation Path

### Technical Issues
1. Team member attempts resolution (30 min)
2. Consult with peer specialist (1 hour)
3. Escalate to Markus or Alec (lead decision)

### Business Decisions
1. Gather requirements and context
2. Propose options with pros/cons
3. Escalate to Brad for final decision

### Resource Conflicts
1. Document competing priorities
2. Estimate impact of delay for each
3. Escalate to Markus (operations lead)

### Customer/External Issues
1. Acknowledge and document issue
2. Inform Brad immediately
3. Coordinate response with Brad

---

## Related Resources

**Commands**:
- `/team:assign [work] [database]` - Auto-assign work to team member
- `/agent:activity-summary [timeframe] [member]` - View member workload

**Documentation**:
- [Agent Activity Center](./agent-activity-center.md)
- [Common Workflows](./common-workflows.md)
- [Innovation Workflow](./innovation-workflow.md)

---

**Last Updated**: 2025-10-26
