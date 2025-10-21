# Agent Management - Quick Start Guide

## For Developers

### File Locations (All Absolute Paths)

#### Core Types
```
C:\Users\MarkusAhling\Project-Ascension\webapp\src\types\models\agent.ts
```

#### API Client
```
C:\Users\MarkusAhling\Project-Ascension\webapp\src\api\clients\AgentClient.ts
```

#### React Hooks
```
C:\Users\MarkusAhling\Project-Ascension\webapp\src\hooks\useAgents.ts
```

#### Components
```
C:\Users\MarkusAhling\Project-Ascension\webapp\src\components\domain\AgentCard.tsx
C:\Users\MarkusAhling\Project-Ascension\webapp\src\components\domain\AgentFormModal.tsx
C:\Users\MarkusAhling\Project-Ascension\webapp\src\components\domain\ExecuteTaskModal.tsx
C:\Users\MarkusAhling\Project-Ascension\webapp\src\components\domain\index.ts
```

#### Pages
```
C:\Users\MarkusAhling\Project-Ascension\webapp\src\pages\AgentsPage.tsx
```

## Quick Code Snippets

### Using the Agents Hook
```typescript
import { useAgents } from '../hooks/useAgents';

function MyComponent() {
  const { data, isLoading, error } = useAgents({
    status: AgentStatus.Active,
    role: AgentRole.Architect,
    search: 'code review',
    limit: 20,
    offset: 0,
  });

  const agents = data?.agents || [];
  // Use agents...
}
```

### Creating an Agent
```typescript
import { useCreateAgent } from '../hooks/useAgents';

function MyComponent() {
  const createMutation = useCreateAgent();

  const handleCreate = async () => {
    try {
      const agent = await createMutation.mutateAsync({
        name: 'My Agent',
        role: AgentRole.Builder,
        description: 'Builds components',
        azureOpenAIConfig: {
          endpoint: 'https://my-resource.openai.azure.com',
          deploymentName: 'gpt-4',
          apiVersion: '2024-02-01',
          maxTokens: 4000,
          temperature: 0.7,
        },
        maxRetries: 3,
        retryDelay: 1000,
        timeout: 30000,
      });
      console.log('Created:', agent.id);
    } catch (error) {
      console.error('Failed:', error);
    }
  };
}
```

### Executing a Task
```typescript
import { useExecuteTask } from '../hooks/useAgents';

function MyComponent() {
  const executeMutation = useExecuteTask();

  const handleExecute = async (agentId: string) => {
    try {
      const result = await executeMutation.mutateAsync({
        agentId,
        description: 'Review this code for best practices',
        priority: TaskPriority.High,
        maxIterations: 10,
        timeout: 60000,
      });
      console.log('Task completed:', result.taskId);
    } catch (error) {
      console.error('Task failed:', error);
    }
  };
}
```

### Using AgentCard Component
```typescript
import { AgentCard } from '../components/domain';

function MyComponent() {
  return (
    <div className="grid grid-cols-3 gap-6">
      {agents.map((agent) => (
        <AgentCard
          key={agent.id}
          agent={agent}
          onEdit={(agent) => console.log('Edit', agent.id)}
          onDelete={(id) => console.log('Delete', id)}
          onExecuteTask={(id) => console.log('Execute', id)}
          onViewDetails={(id) => navigate(`/agents/${id}`)}
        />
      ))}
    </div>
  );
}
```

### Using Modals
```typescript
import { AgentFormModal, ExecuteTaskModal } from '../components/domain';

function MyComponent() {
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [isExecuteOpen, setIsExecuteOpen] = useState(false);
  const [selectedAgent, setSelectedAgent] = useState<Agent | undefined>();

  return (
    <>
      <Button onClick={() => setIsFormOpen(true)}>
        Create Agent
      </Button>

      <AgentFormModal
        isOpen={isFormOpen}
        onClose={() => setIsFormOpen(false)}
        agent={selectedAgent} // undefined for create, agent object for edit
      />

      {selectedAgent && (
        <ExecuteTaskModal
          isOpen={isExecuteOpen}
          onClose={() => setIsExecuteOpen(false)}
          agent={selectedAgent}
        />
      )}
    </>
  );
}
```

## Common Patterns

### Filtering Agents
```typescript
const { data } = useAgents({
  status: AgentStatus.Active,
  role: AgentRole.Architect,
  search: searchQuery,
  sortBy: 'createdAt',
  sortOrder: 'desc',
  limit: 20,
  offset: (page - 1) * 20,
});
```

### Optimistic Updates
```typescript
// The hooks handle this automatically!
// On update, the UI updates immediately, then rolls back if the API fails

const updateMutation = useUpdateAgent();
await updateMutation.mutateAsync({
  id: agentId,
  request: { status: AgentStatus.Active }
});
// UI already shows Active status
```

### Cache Invalidation
```typescript
// Automatic on mutations
createAgent() → invalidates agent lists
updateAgent() → invalidates agent detail & lists
deleteAgent() → removes from cache, invalidates lists
executeTask() → invalidates metrics & activity
```

## Type Reference

### Key Enums
```typescript
enum AgentStatus {
  Active = 'Active',
  Inactive = 'Inactive',
  Paused = 'Paused',
  Error = 'Error',
  Deploying = 'Deploying'
}

enum AgentRole {
  Architect = 'Architect',
  Builder = 'Builder',
  Validator = 'Validator',
  Scribe = 'Scribe',
  Custom = 'Custom'
}

enum TaskPriority {
  Low = 'Low',
  Normal = 'Normal',
  High = 'High',
  Critical = 'Critical'
}
```

### Agent Interface
```typescript
interface Agent {
  id: string;
  name: string;
  role: AgentRole;
  description?: string;
  status: AgentStatus;
  azureOpenAIConfig: AzureOpenAIConfig;
  tools: AgentTool[];
  maxRetries: number;
  retryDelay: number;
  timeout?: number;
  metrics: AgentMetrics;
  createdAt: Date;
  updatedAt: Date;
  createdBy: string;
  metadata?: Record<string, unknown>;
  etag?: string;
}
```

## Environment Setup

### 1. Install Dependencies
```bash
cd C:\Users\MarkusAhling\Project-Ascension\webapp
npm install
```

### 2. Start Dev Server
```bash
npm run dev
```

### 3. Access Application
```
http://localhost:5173/agents
```

## Troubleshooting

### "Module not found" errors
```bash
# Make sure you're in the webapp directory
cd C:\Users\MarkusAhling\Project-Ascension\webapp
npm install
```

### Type errors with imports
```typescript
// Use absolute imports from src
import { Agent } from '../types/models/agent';
import { useAgents } from '../hooks/useAgents';
import { AgentCard } from '../components/domain';
```

### API connection issues
```typescript
// Check BaseApiClient configuration
// Default base URL: /api/agents
// Update in AgentClient constructor if needed
```

### Modal not opening
```typescript
// Ensure state is managed correctly
const [isOpen, setIsOpen] = useState(false);

<Button onClick={() => setIsOpen(true)}>Open</Button>
<Modal isOpen={isOpen} onClose={() => setIsOpen(false)} />
```

## Next Steps

1. **Start the dev server:** `npm run dev`
2. **Navigate to agents page:** http://localhost:5173/agents
3. **Try creating an agent** using the "Create Agent" button
4. **Explore the codebase** starting with `AgentsPage.tsx`
5. **Add your backend API endpoint** in `AgentClient.ts` if needed

## Need Help?

See the comprehensive summary:
```
C:\Users\MarkusAhling\Project-Ascension\AGENT_MANAGEMENT_SUMMARY.md
```

Contact:
- **Email:** Consultations@BrooksideBI.com
- **Phone:** +1 209 487 2047
