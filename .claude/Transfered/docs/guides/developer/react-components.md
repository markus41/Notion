---
title: React Component Development Guide
description: Build production-ready React components with TypeScript, hooks, and real-time capabilities. Streamline frontend development with modern patterns.
tags:
  - react
  - typescript
  - components
  - frontend
  - hooks
  - best-practices
lastUpdated: 2025-10-09
author: Agent Studio Team
audience: developers
---

# React Component Development Guide

## Overview

Agent Studio's frontend is built with modern React 19, TypeScript, and a carefully selected stack designed for performance, developer experience, and real-time capabilities. This guide provides comprehensive best practices and patterns for building components in the Agent Studio ecosystem.

### Technology Stack

- **React 19**: Latest React with enhanced concurrent features and improved hooks
- **TypeScript 5.9.3**: Full type safety with strict mode enabled
- **Vite 7.1.9**: Lightning-fast development with native ESM and optimized builds
- **Tailwind CSS 3.4.1**: Utility-first styling for rapid UI development
- **TanStack Query 5.17.9**: Powerful server state management and caching
- **React Router 7.9.4**: Type-safe routing with modern patterns
- **Vitest 3.2.4**: Fast unit testing with React Testing Library
- **SignalR**: Real-time bidirectional communication for live updates

### Architecture Philosophy

Our component architecture follows these core principles:

1. **Type Safety First**: Every component is strongly typed with TypeScript interfaces
2. **Composition Over Inheritance**: Build complex UIs from small, focused components
3. **Real-Time by Default**: Leverage SignalR for live data updates
4. **Performance Conscious**: Code splitting, lazy loading, and memoization are standard
5. **Accessible by Design**: ARIA labels, keyboard navigation, and semantic HTML
6. **Test-Driven Development**: Write tests alongside components

## Component Architecture

### Folder Structure

Agent Studio uses a feature-based folder structure that scales well with growth:

```
webapp/src/
├── components/           # Shared, reusable components
│   ├── meta-agents/     # Feature-specific components
│   │   ├── AgentMetrics.tsx
│   │   ├── AgentThoughtStream.tsx
│   │   ├── AgentConversation.tsx
│   │   ├── WorkflowGraph.tsx
│   │   └── AgentControls.tsx
│   ├── Layout.tsx       # App-level layout
│   └── CommandPalette.tsx
├── pages/               # Route-level page components
│   ├── MetaAgents.tsx
│   ├── AgentWorkspace.tsx
│   ├── AgentsPage.tsx
│   └── SettingsPage.tsx
├── hooks/               # Custom React hooks
│   ├── useSignalR.ts
│   ├── useMetaAgents.ts
│   ├── useAgentStream.ts
│   └── __tests__/       # Hook tests
├── services/            # API and external service integrations
│   ├── signalrService.ts
│   ├── metaAgentService.ts
│   └── __tests__/       # Service tests
├── types/               # TypeScript type definitions
│   └── meta-agents.ts
└── test/                # Test utilities and setup
    └── setup.ts
```

**Organization Principles:**

- **Components**: Place shared components in `/components`, feature-specific in subdirectories
- **Pages**: Top-level route components that compose smaller components
- **Hooks**: Extract reusable logic into custom hooks, always prefix with `use`
- **Services**: API clients and external integrations, keep separate from UI logic
- **Types**: Centralized type definitions shared across the app

### Naming Conventions

**Components:**
- Use PascalCase: `AgentMetrics.tsx`, `WorkflowGraph.tsx`
- File name matches component name
- One component per file (except small internal sub-components)

**Hooks:**
- Use camelCase with `use` prefix: `useSignalR.ts`, `useMetaAgents.ts`
- Custom hooks must follow React's rules of hooks

**Types:**
- Use PascalCase for interfaces and types: `Agent`, `AgentMetrics`
- Use kebab-case for type definition files: `meta-agents.ts`

**Services:**
- Use camelCase with descriptive suffix: `signalrService.ts`, `metaAgentService.ts`

## Building Components

### Functional Components with TypeScript

All components in Agent Studio are functional components with full TypeScript typing. Here's a complete example:

```typescript
/**
 * AgentCard Component
 * Displays agent information with real-time status updates
 */

import { memo } from 'react';
import { clsx } from 'clsx';
import type { Agent } from '../types/meta-agents';

/**
 * Component props interface
 */
interface AgentCardProps {
  /** The agent to display */
  agent: Agent;
  /** Whether the card is selected */
  isSelected?: boolean;
  /** Handler called when card is clicked */
  onSelect?: (agentId: string) => void;
  /** Handler called when start button is clicked */
  onStart?: (agentId: string) => void;
  /** Additional CSS classes */
  className?: string;
}

/**
 * AgentCard Component
 *
 * @example
 * ```tsx
 * <AgentCard
 *   agent={agent}
 *   isSelected={selectedId === agent.id}
 *   onSelect={handleSelect}
 *   onStart={handleStart}
 * />
 * ```
 */
function AgentCard({
  agent,
  isSelected = false,
  onSelect,
  onStart,
  className,
}: AgentCardProps) {
  const handleClick = () => {
    onSelect?.(agent.id);
  };

  const handleStartClick = (e: React.MouseEvent) => {
    e.stopPropagation(); // Prevent card selection
    onStart?.(agent.id);
  };

  const statusColor = {
    idle: 'bg-gray-500',
    thinking: 'bg-yellow-500',
    executing: 'bg-blue-500',
    completed: 'bg-green-500',
    error: 'bg-red-500',
    paused: 'bg-orange-500',
  }[agent.status];

  return (
    <div
      role="button"
      tabIndex={0}
      onClick={handleClick}
      onKeyDown={(e) => e.key === 'Enter' && handleClick()}
      className={clsx(
        'p-4 rounded-lg border-2 transition-all cursor-pointer',
        'hover:shadow-lg focus:outline-none focus:ring-2 focus:ring-blue-500',
        isSelected ? 'border-blue-500 bg-blue-50' : 'border-gray-200 bg-white',
        className
      )}
      aria-label={`Agent ${agent.name}`}
      aria-pressed={isSelected}
    >
      {/* Status indicator */}
      <div className="flex items-center gap-2 mb-2">
        <div
          className={clsx('w-3 h-3 rounded-full', statusColor)}
          aria-label={`Status: ${agent.status}`}
        />
        <span className="text-xs text-gray-500 uppercase tracking-wider">
          {agent.status}
        </span>
      </div>

      {/* Agent info */}
      <h3 className="text-lg font-semibold text-gray-900 mb-1">
        {agent.name}
      </h3>
      <p className="text-sm text-gray-600 mb-3">
        {agent.description}
      </p>

      {/* Capabilities */}
      <div className="flex flex-wrap gap-1 mb-3">
        {agent.capabilities.map((capability) => (
          <span
            key={capability}
            className="px-2 py-1 text-xs bg-gray-100 text-gray-700 rounded"
          >
            {capability.replace(/_/g, ' ')}
          </span>
        ))}
      </div>

      {/* Metrics */}
      <div className="grid grid-cols-2 gap-2 mb-3 text-xs text-gray-600">
        <div>
          <span className="font-medium">Requests:</span> {agent.metrics.totalRequests}
        </div>
        <div>
          <span className="font-medium">Success:</span> {(agent.metrics.successRate * 100).toFixed(1)}%
        </div>
      </div>

      {/* Actions */}
      {onStart && agent.status === 'idle' && (
        <button
          onClick={handleStartClick}
          className={clsx(
            'w-full px-4 py-2 rounded-md font-medium transition-colors',
            'bg-blue-500 text-white hover:bg-blue-600',
            'focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2'
          )}
          aria-label={`Start ${agent.name}`}
        >
          Start Agent
        </button>
      )}
    </div>
  );
}

// Export memoized component to prevent unnecessary re-renders
export default memo(AgentCard);
```

**Key Patterns:**

1. **TypeScript Interface**: Define props interface with JSDoc comments for IDE support
2. **Default Props**: Use default parameter values for optional props
3. **Event Handlers**: Type event handlers correctly (`React.MouseEvent`, `React.KeyboardEvent`)
4. **Accessibility**: Include ARIA labels, keyboard handlers, and semantic HTML
5. **Performance**: Use `memo()` for components that receive stable props
6. **Styling**: Use `clsx` for conditional class names with Tailwind

### Custom Hooks

Custom hooks are the heart of Agent Studio's state management. They encapsulate complex logic and make it reusable across components.

#### Example 1: useSignalR Hook (Real-Time Connection)

```typescript
/**
 * useSignalR Hook
 * Manages SignalR real-time WebSocket connection
 */

import { useEffect, useState, useCallback, useRef } from 'react';
import { signalRService } from '../services/signalrService';
import type { StreamEvent, ConnectionState } from '../types/meta-agents';

interface UseSignalROptions {
  autoConnect?: boolean;
  onEvent?: (event: StreamEvent) => void;
  onConnectionStateChange?: (state: ConnectionState) => void;
}

interface UseSignalRReturn {
  connectionState: ConnectionState;
  connectionId: string | null;
  isConnected: boolean;
  connect: () => Promise<void>;
  disconnect: () => Promise<void>;
  invoke: <T = unknown>(methodName: string, ...args: unknown[]) => Promise<T>;
  send: (methodName: string, ...args: unknown[]) => Promise<void>;
  subscribe: (callback: (event: StreamEvent) => void) => () => void;
}

export function useSignalR(options: UseSignalROptions = {}): UseSignalRReturn {
  const { autoConnect = true, onEvent, onConnectionStateChange } = options;

  const [connectionState, setConnectionState] = useState<ConnectionState>(
    signalRService.getConnectionState()
  );
  const [connectionId, setConnectionId] = useState<string | null>(
    signalRService.getConnectionId()
  );

  const isConnected = connectionState === 'connected';
  const mountedRef = useRef(true);

  // Connect to SignalR hub
  const connect = useCallback(async () => {
    try {
      await signalRService.connect();
      if (mountedRef.current) {
        setConnectionState(signalRService.getConnectionState());
        setConnectionId(signalRService.getConnectionId());
      }
    } catch (error) {
      console.error('useSignalR: Connection failed', error);
    }
  }, []);

  // Disconnect from SignalR hub
  const disconnect = useCallback(async () => {
    try {
      await signalRService.disconnect();
      if (mountedRef.current) {
        setConnectionState('disconnected');
        setConnectionId(null);
      }
    } catch (error) {
      console.error('useSignalR: Disconnect failed', error);
    }
  }, []);

  // Invoke server method with return value
  const invoke = useCallback(
    async <T = unknown>(methodName: string, ...args: unknown[]): Promise<T> => {
      return signalRService.invoke<T>(methodName, ...args);
    },
    []
  );

  // Send message to server without return value
  const send = useCallback(
    async (methodName: string, ...args: unknown[]): Promise<void> => {
      return signalRService.send(methodName, ...args);
    },
    []
  );

  // Subscribe to events
  const subscribe = useCallback(
    (callback: (event: StreamEvent) => void): (() => void) => {
      return signalRService.subscribe(callback);
    },
    []
  );

  // Setup connection state listener
  useEffect(() => {
    const unsubscribe = signalRService.onConnectionStateChange((state) => {
      if (mountedRef.current) {
        setConnectionState(state);
        setConnectionId(signalRService.getConnectionId());
        onConnectionStateChange?.(state);
      }
    });

    return unsubscribe;
  }, [onConnectionStateChange]);

  // Setup event listener
  useEffect(() => {
    if (!onEvent) return;

    const unsubscribe = signalRService.subscribe(onEvent);
    return unsubscribe;
  }, [onEvent]);

  // Auto-connect on mount
  useEffect(() => {
    mountedRef.current = true;

    if (autoConnect && !signalRService.isConnected()) {
      connect();
    }

    return () => {
      mountedRef.current = false;
      // Don't auto-disconnect on unmount as other components may use the connection
    };
  }, [autoConnect, connect]);

  return {
    connectionState,
    connectionId,
    isConnected,
    connect,
    disconnect,
    invoke,
    send,
    subscribe,
  };
}
```

**Usage:**

```typescript
function MetaAgentsPage() {
  const { isConnected, connectionState, subscribe } = useSignalR({
    autoConnect: true,
    onEvent: (event) => {
      console.log('Received event:', event);
    },
  });

  return (
    <div>
      <span>Connection: {connectionState}</span>
      {isConnected && <p>Real-time updates active</p>}
    </div>
  );
}
```

#### Example 2: useMetaAgents Hook (Agent Management)

```typescript
/**
 * useMetaAgents Hook
 * Comprehensive agent state management with real-time updates
 */

import { useEffect, useState, useCallback, useMemo } from 'react';
import { useSignalR } from './useSignalR';
import { metaAgentService } from '../services/metaAgentService';
import type {
  Agent,
  AgentConfig,
  AgentFilter,
  AgentTask,
  StreamEvent,
  PaginationParams,
} from '../types/meta-agents';

interface UseMetaAgentsOptions {
  autoFetch?: boolean;
  filter?: AgentFilter;
  pagination?: PaginationParams;
  enableRealtime?: boolean;
}

interface UseMetaAgentsReturn {
  agents: Agent[];
  loading: boolean;
  error: string | null;
  selectedAgent: Agent | null;
  selectAgent: (id: string | null) => void;
  fetchAgents: () => Promise<void>;
  createAgent: (config: AgentConfig) => Promise<Agent | null>;
  updateAgent: (id: string, updates: Partial<Agent>) => Promise<Agent | null>;
  deleteAgent: (id: string) => Promise<boolean>;
  startAgent: (id: string) => Promise<Agent | null>;
  stopAgent: (id: string) => Promise<Agent | null>;
  pauseAgent: (id: string) => Promise<Agent | null>;
  executeTask: (agentId: string, task: Partial<AgentTask>) => Promise<AgentTask | null>;
  refresh: () => Promise<void>;
}

export function useMetaAgents(options: UseMetaAgentsOptions = {}): UseMetaAgentsReturn {
  const { autoFetch = true, filter, pagination, enableRealtime = true } = options;

  const [agents, setAgents] = useState<Agent[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [selectedAgentId, setSelectedAgentId] = useState<string | null>(null);

  // Get selected agent from agents list (memoized)
  const selectedAgent = useMemo(
    () => agents.find((a) => a.id === selectedAgentId) ?? null,
    [agents, selectedAgentId]
  );

  // Fetch agents from API
  const fetchAgents = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const response = await metaAgentService.getAgents(filter, pagination);

      if (response.success && response.data) {
        setAgents(response.data);
      } else {
        setError(response.error || 'Failed to fetch agents');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  }, [filter, pagination]);

  // Create a new agent
  const createAgent = useCallback(
    async (config: AgentConfig): Promise<Agent | null> => {
      setError(null);

      try {
        const response = await metaAgentService.createAgent(config);

        if (response.success && response.data) {
          setAgents((prev) => [...prev, response.data!]);
          return response.data;
        } else {
          setError(response.error || 'Failed to create agent');
          return null;
        }
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error');
        return null;
      }
    },
    []
  );

  // Update an existing agent
  const updateAgent = useCallback(
    async (id: string, updates: Partial<Agent>): Promise<Agent | null> => {
      setError(null);

      try {
        const response = await metaAgentService.updateAgent(id, updates);

        if (response.success && response.data) {
          setAgents((prev) =>
            prev.map((agent) => (agent.id === id ? response.data! : agent))
          );
          return response.data;
        } else {
          setError(response.error || 'Failed to update agent');
          return null;
        }
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error');
        return null;
      }
    },
    []
  );

  // Handle real-time updates
  const handleRealtimeEvent = useCallback((event: StreamEvent) => {
    switch (event.type) {
      case 'agent.created':
        setAgents((prev) => [...prev, event.data]);
        break;

      case 'agent.updated':
        setAgents((prev) =>
          prev.map((agent) =>
            agent.id === event.data.id ? { ...agent, ...event.data } : agent
          )
        );
        break;

      case 'agent.deleted':
        setAgents((prev) => prev.filter((agent) => agent.id !== event.data.id));
        if (selectedAgentId === event.data.id) {
          setSelectedAgentId(null);
        }
        break;

      case 'agent.status_changed':
        setAgents((prev) =>
          prev.map((agent) =>
            agent.id === event.data.id
              ? { ...agent, status: event.data.status, updatedAt: new Date() }
              : agent
          )
        );
        break;

      case 'metrics.updated':
        setAgents((prev) =>
          prev.map((agent) =>
            agent.id === event.data.agentId
              ? { ...agent, metrics: event.data.metrics, updatedAt: new Date() }
              : agent
          )
        );
        break;
    }
  }, [selectedAgentId]);

  // Setup real-time updates
  useSignalR({
    autoConnect: enableRealtime,
    onEvent: enableRealtime ? handleRealtimeEvent : undefined,
  });

  // Initial fetch on mount
  useEffect(() => {
    if (autoFetch) {
      fetchAgents();
    }
  }, [autoFetch, fetchAgents]);

  return {
    agents,
    loading,
    error,
    selectedAgent,
    selectAgent: setSelectedAgentId,
    fetchAgents,
    createAgent,
    updateAgent,
    deleteAgent: async (id) => { /* implementation */ },
    startAgent: async (id) => { /* implementation */ },
    stopAgent: async (id) => { /* implementation */ },
    pauseAgent: async (id) => { /* implementation */ },
    executeTask: async (agentId, task) => { /* implementation */ },
    refresh: fetchAgents,
  };
}
```

**Usage:**

```typescript
function AgentsList() {
  const {
    agents,
    loading,
    error,
    selectedAgent,
    selectAgent,
    startAgent,
    createAgent,
  } = useMetaAgents({
    autoFetch: true,
    enableRealtime: true,
  });

  const handleCreateAgent = async () => {
    const newAgent = await createAgent({
      name: 'New Agent',
      type: 'architect',
      capabilities: ['planning', 'reasoning'],
    });

    if (newAgent) {
      selectAgent(newAgent.id);
    }
  };

  if (loading) return <LoadingSpinner />;
  if (error) return <ErrorMessage message={error} />;

  return (
    <div>
      <button onClick={handleCreateAgent}>Create Agent</button>
      {agents.map((agent) => (
        <AgentCard
          key={agent.id}
          agent={agent}
          isSelected={selectedAgent?.id === agent.id}
          onSelect={selectAgent}
          onStart={startAgent}
        />
      ))}
    </div>
  );
}
```

#### Example 3: useForm Hook (Form Management)

```typescript
/**
 * useForm Hook
 * Simple form state management with validation
 */

import { useState, useCallback, ChangeEvent } from 'react';

interface UseFormOptions<T> {
  initialValues: T;
  validate?: (values: T) => Partial<Record<keyof T, string>>;
  onSubmit: (values: T) => Promise<void> | void;
}

interface UseFormReturn<T> {
  values: T;
  errors: Partial<Record<keyof T, string>>;
  touched: Partial<Record<keyof T, boolean>>;
  isSubmitting: boolean;
  handleChange: (e: ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => void;
  handleBlur: (e: ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => void;
  handleSubmit: (e: React.FormEvent) => Promise<void>;
  setFieldValue: (field: keyof T, value: any) => void;
  setFieldError: (field: keyof T, error: string) => void;
  reset: () => void;
}

export function useForm<T extends Record<string, any>>({
  initialValues,
  validate,
  onSubmit,
}: UseFormOptions<T>): UseFormReturn<T> {
  const [values, setValues] = useState<T>(initialValues);
  const [errors, setErrors] = useState<Partial<Record<keyof T, string>>>({});
  const [touched, setTouched] = useState<Partial<Record<keyof T, boolean>>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleChange = useCallback((e: ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value, type } = e.target;
    const fieldValue = type === 'checkbox' ? (e.target as HTMLInputElement).checked : value;

    setValues((prev) => ({
      ...prev,
      [name]: fieldValue,
    }));
  }, []);

  const handleBlur = useCallback((e: ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name } = e.target;

    setTouched((prev) => ({
      ...prev,
      [name]: true,
    }));

    if (validate) {
      const validationErrors = validate(values);
      setErrors(validationErrors);
    }
  }, [values, validate]);

  const handleSubmit = useCallback(
    async (e: React.FormEvent) => {
      e.preventDefault();

      // Mark all fields as touched
      const allTouched = Object.keys(values).reduce(
        (acc, key) => ({ ...acc, [key]: true }),
        {}
      );
      setTouched(allTouched);

      // Validate
      if (validate) {
        const validationErrors = validate(values);
        setErrors(validationErrors);

        if (Object.keys(validationErrors).length > 0) {
          return;
        }
      }

      // Submit
      setIsSubmitting(true);
      try {
        await onSubmit(values);
      } finally {
        setIsSubmitting(false);
      }
    },
    [values, validate, onSubmit]
  );

  const setFieldValue = useCallback((field: keyof T, value: any) => {
    setValues((prev) => ({
      ...prev,
      [field]: value,
    }));
  }, []);

  const setFieldError = useCallback((field: keyof T, error: string) => {
    setErrors((prev) => ({
      ...prev,
      [field]: error,
    }));
  }, []);

  const reset = useCallback(() => {
    setValues(initialValues);
    setErrors({});
    setTouched({});
    setIsSubmitting(false);
  }, [initialValues]);

  return {
    values,
    errors,
    touched,
    isSubmitting,
    handleChange,
    handleBlur,
    handleSubmit,
    setFieldValue,
    setFieldError,
    reset,
  };
}
```

**Usage:**

```typescript
interface AgentFormValues {
  name: string;
  description: string;
  type: string;
}

function CreateAgentForm() {
  const { createAgent } = useMetaAgents();

  const form = useForm<AgentFormValues>({
    initialValues: {
      name: '',
      description: '',
      type: 'architect',
    },
    validate: (values) => {
      const errors: Partial<Record<keyof AgentFormValues, string>> = {};

      if (!values.name) errors.name = 'Name is required';
      if (values.name.length < 3) errors.name = 'Name must be at least 3 characters';
      if (!values.description) errors.description = 'Description is required';

      return errors;
    },
    onSubmit: async (values) => {
      await createAgent(values);
      form.reset();
    },
  });

  return (
    <form onSubmit={form.handleSubmit} className="space-y-4">
      <div>
        <label htmlFor="name" className="block text-sm font-medium text-gray-700">
          Agent Name
        </label>
        <input
          id="name"
          name="name"
          type="text"
          value={form.values.name}
          onChange={form.handleChange}
          onBlur={form.handleBlur}
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
          aria-invalid={!!form.errors.name}
          aria-describedby={form.errors.name ? 'name-error' : undefined}
        />
        {form.errors.name && form.touched.name && (
          <p id="name-error" className="mt-1 text-sm text-red-600">
            {form.errors.name}
          </p>
        )}
      </div>

      <div>
        <label htmlFor="description" className="block text-sm font-medium text-gray-700">
          Description
        </label>
        <textarea
          id="description"
          name="description"
          value={form.values.description}
          onChange={form.handleChange}
          onBlur={form.handleBlur}
          rows={3}
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
        />
        {form.errors.description && form.touched.description && (
          <p className="mt-1 text-sm text-red-600">{form.errors.description}</p>
        )}
      </div>

      <button
        type="submit"
        disabled={form.isSubmitting}
        className="px-4 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600 disabled:opacity-50"
      >
        {form.isSubmitting ? 'Creating...' : 'Create Agent'}
      </button>
    </form>
  );
}
```

### Context Providers

Context providers are used for app-wide state that many components need to access. Agent Studio uses context for theme, authentication, and WebSocket connections.

```typescript
/**
 * Theme Context Provider
 * Manages light/dark theme with persistence
 */

import { createContext, useContext, useState, useEffect, ReactNode } from 'react';

type Theme = 'light' | 'dark' | 'system';

interface ThemeContextValue {
  theme: Theme;
  setTheme: (theme: Theme) => void;
  resolvedTheme: 'light' | 'dark';
}

const ThemeContext = createContext<ThemeContextValue | undefined>(undefined);

interface ThemeProviderProps {
  children: ReactNode;
  defaultTheme?: Theme;
}

export function ThemeProvider({ children, defaultTheme = 'system' }: ThemeProviderProps) {
  const [theme, setTheme] = useState<Theme>(() => {
    // Load from localStorage
    const stored = localStorage.getItem('theme') as Theme;
    return stored || defaultTheme;
  });

  const resolvedTheme = theme === 'system'
    ? window.matchMedia('(prefers-color-scheme: dark)').matches
      ? 'dark'
      : 'light'
    : theme;

  useEffect(() => {
    // Save to localStorage
    localStorage.setItem('theme', theme);

    // Apply theme class to document
    const root = document.documentElement;
    root.classList.remove('light', 'dark');
    root.classList.add(resolvedTheme);
  }, [theme, resolvedTheme]);

  // Listen for system theme changes
  useEffect(() => {
    if (theme !== 'system') return;

    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    const handleChange = () => {
      const root = document.documentElement;
      root.classList.remove('light', 'dark');
      root.classList.add(mediaQuery.matches ? 'dark' : 'light');
    };

    mediaQuery.addEventListener('change', handleChange);
    return () => mediaQuery.removeEventListener('change', handleChange);
  }, [theme]);

  return (
    <ThemeContext.Provider value={{ theme, setTheme, resolvedTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}

export function useTheme() {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within ThemeProvider');
  }
  return context;
}
```

**Usage:**

```typescript
// In main.tsx or App.tsx
import { ThemeProvider } from './contexts/ThemeContext';

function App() {
  return (
    <ThemeProvider defaultTheme="system">
      <RouterProvider router={router} />
    </ThemeProvider>
  );
}

// In any component
function Header() {
  const { theme, setTheme, resolvedTheme } = useTheme();

  return (
    <header>
      <button onClick={() => setTheme(resolvedTheme === 'dark' ? 'light' : 'dark')}>
        {resolvedTheme === 'dark' ? '☀️ Light' : '🌙 Dark'}
      </button>
    </header>
  );
}
```

## State Management

### Local State (useState)

Use `useState` for component-local state that doesn't need to be shared.

```typescript
function Counter() {
  const [count, setCount] = useState(0);

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => setCount(count + 1)}>Increment</button>
    </div>
  );
}
```

**When to use:**
- UI state (modals, dropdowns, form inputs)
- Temporary data (search queries, filters)
- Component-specific state not needed elsewhere

### Server State (TanStack Query)

TanStack Query is the preferred solution for server state management, providing caching, background updates, and optimistic updates.

```typescript
/**
 * TanStack Query Setup
 */

import { QueryClient, QueryClientProvider, useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { metaAgentService } from './services/metaAgentService';

// Create query client
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 60 * 1000, // Data fresh for 1 minute
      cacheTime: 5 * 60 * 1000, // Cache for 5 minutes
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
});

// Setup in App
function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <YourApp />
    </QueryClientProvider>
  );
}

// Query hook
function useAgents(filter?: AgentFilter) {
  return useQuery({
    queryKey: ['agents', filter],
    queryFn: () => metaAgentService.getAgents(filter),
    select: (response) => response.data,
  });
}

// Mutation hook with optimistic updates
function useCreateAgent() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (config: AgentConfig) => metaAgentService.createAgent(config),
    onMutate: async (newAgent) => {
      // Cancel outgoing refetches
      await queryClient.cancelQueries({ queryKey: ['agents'] });

      // Snapshot previous value
      const previousAgents = queryClient.getQueryData(['agents']);

      // Optimistically update
      queryClient.setQueryData(['agents'], (old: Agent[]) => [
        ...old,
        { id: 'temp', ...newAgent },
      ]);

      return { previousAgents };
    },
    onError: (err, newAgent, context) => {
      // Rollback on error
      queryClient.setQueryData(['agents'], context.previousAgents);
    },
    onSettled: () => {
      // Refetch after error or success
      queryClient.invalidateQueries({ queryKey: ['agents'] });
    },
  });
}

// Usage in component
function AgentsList() {
  const { data: agents, isLoading, error } = useAgents();
  const createAgent = useCreateAgent();

  const handleCreate = async () => {
    try {
      await createAgent.mutateAsync({
        name: 'New Agent',
        type: 'architect',
      });
    } catch (error) {
      console.error('Failed to create agent:', error);
    }
  };

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;

  return (
    <div>
      <button onClick={handleCreate} disabled={createAgent.isPending}>
        Create Agent
      </button>
      {agents?.map((agent) => <AgentCard key={agent.id} agent={agent} />)}
    </div>
  );
}
```

### Global State (Zustand)

For client-side global state (UI preferences, app-wide settings), use Zustand for its simplicity and TypeScript support.

```typescript
/**
 * Zustand Store Example
 */

import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface AppState {
  sidebarOpen: boolean;
  selectedView: 'grid' | 'list';
  filters: AgentFilter;

  toggleSidebar: () => void;
  setView: (view: 'grid' | 'list') => void;
  setFilters: (filters: AgentFilter) => void;
  reset: () => void;
}

const useAppStore = create<AppState>()(
  persist(
    (set) => ({
      sidebarOpen: true,
      selectedView: 'grid',
      filters: {},

      toggleSidebar: () => set((state) => ({ sidebarOpen: !state.sidebarOpen })),
      setView: (view) => set({ selectedView: view }),
      setFilters: (filters) => set({ filters }),
      reset: () => set({ sidebarOpen: true, selectedView: 'grid', filters: {} }),
    }),
    {
      name: 'app-storage', // localStorage key
      partialize: (state) => ({
        selectedView: state.selectedView,
        filters: state.filters,
      }), // Only persist these fields
    }
  )
);

// Usage in components
function Sidebar() {
  const { sidebarOpen, toggleSidebar } = useAppStore();

  return (
    <aside className={sidebarOpen ? 'open' : 'closed'}>
      <button onClick={toggleSidebar}>Toggle</button>
    </aside>
  );
}

function AgentsView() {
  const { selectedView, setView, filters, setFilters } = useAppStore();

  return (
    <div>
      <button onClick={() => setView('grid')}>Grid</button>
      <button onClick={() => setView('list')}>List</button>
      {selectedView === 'grid' ? <GridView /> : <ListView />}
    </div>
  );
}
```

## Styling

### Tailwind CSS

Agent Studio uses Tailwind CSS for utility-first styling with a custom configuration.

```typescript
// tailwind.config.js
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  darkMode: 'class', // Enable dark mode with class strategy
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#eff6ff',
          500: '#3b82f6',
          600: '#2563eb',
        },
        'neon-blue': '#00f0ff',
        'neon-green': '#00ff9f',
        'neon-orange': '#ff6b35',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },
      spacing: {
        18: '4.5rem',
        112: '28rem',
      },
      animation: {
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
      },
    },
  },
  plugins: [],
};
```

**Usage in Components:**

```typescript
function Button({ variant = 'primary', children, ...props }) {
  return (
    <button
      className={clsx(
        'px-4 py-2 rounded-md font-medium transition-colors',
        'focus:outline-none focus:ring-2 focus:ring-offset-2',
        {
          'bg-blue-500 text-white hover:bg-blue-600 focus:ring-blue-500': variant === 'primary',
          'bg-gray-200 text-gray-900 hover:bg-gray-300 focus:ring-gray-500': variant === 'secondary',
          'bg-red-500 text-white hover:bg-red-600 focus:ring-red-500': variant === 'danger',
        }
      )}
      {...props}
    >
      {children}
    </button>
  );
}
```

### Component Variants

For complex components with many variants, create a variant configuration:

```typescript
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

// Utility to merge Tailwind classes
function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// Button variants configuration
const buttonVariants = {
  variant: {
    primary: 'bg-blue-500 text-white hover:bg-blue-600',
    secondary: 'bg-gray-200 text-gray-900 hover:bg-gray-300',
    danger: 'bg-red-500 text-white hover:bg-red-600',
    ghost: 'bg-transparent hover:bg-gray-100',
  },
  size: {
    sm: 'px-3 py-1.5 text-sm',
    md: 'px-4 py-2 text-base',
    lg: 'px-6 py-3 text-lg',
  },
};

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: keyof typeof buttonVariants.variant;
  size?: keyof typeof buttonVariants.size;
}

function Button({
  variant = 'primary',
  size = 'md',
  className,
  children,
  ...props
}: ButtonProps) {
  return (
    <button
      className={cn(
        'rounded-md font-medium transition-colors',
        'focus:outline-none focus:ring-2 focus:ring-offset-2',
        buttonVariants.variant[variant],
        buttonVariants.size[size],
        className
      )}
      {...props}
    >
      {children}
    </button>
  );
}
```

### Responsive Design

Tailwind makes responsive design straightforward with breakpoint prefixes:

```typescript
function ResponsiveGrid() {
  return (
    <div className={cn(
      'grid gap-4',
      'grid-cols-1',           // Mobile: 1 column
      'sm:grid-cols-2',        // Small screens: 2 columns
      'md:grid-cols-3',        // Medium screens: 3 columns
      'lg:grid-cols-4',        // Large screens: 4 columns
      'xl:grid-cols-5'         // Extra large: 5 columns
    )}>
      {items.map((item) => (
        <div key={item.id} className="p-4 bg-white rounded-lg shadow">
          {item.content}
        </div>
      ))}
    </div>
  );
}
```

## Real-Time Updates

### SignalR Integration

Agent Studio uses SignalR for real-time bidirectional communication between the frontend and backend.

```typescript
/**
 * Real-time Agent Dashboard with Live Updates
 */

function AgentDashboard() {
  const [agents, setAgents] = useState<Agent[]>([]);
  const { isConnected, subscribe } = useSignalR({ autoConnect: true });

  useEffect(() => {
    // Subscribe to real-time events
    const unsubscribe = subscribe((event: StreamEvent) => {
      switch (event.type) {
        case 'agent.status_changed':
          setAgents((prev) =>
            prev.map((agent) =>
              agent.id === event.data.id
                ? { ...agent, status: event.data.status }
                : agent
            )
          );
          break;

        case 'metrics.updated':
          setAgents((prev) =>
            prev.map((agent) =>
              agent.id === event.data.agentId
                ? { ...agent, metrics: event.data.metrics }
                : agent
            )
          );
          break;
      }
    });

    return unsubscribe;
  }, [subscribe]);

  return (
    <div>
      <div className="flex items-center gap-2 mb-4">
        <div className={clsx(
          'w-3 h-3 rounded-full',
          isConnected ? 'bg-green-500 animate-pulse' : 'bg-red-500'
        )} />
        <span className="text-sm text-gray-600">
          {isConnected ? 'Connected' : 'Disconnected'}
        </span>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {agents.map((agent) => (
          <AgentCard key={agent.id} agent={agent} />
        ))}
      </div>
    </div>
  );
}
```

### Optimistic Updates

Provide immediate feedback to users by updating UI before server confirmation:

```typescript
function AgentControls({ agent }: { agent: Agent }) {
  const queryClient = useQueryClient();
  const [isStarting, setIsStarting] = useState(false);

  const handleStart = async () => {
    setIsStarting(true);

    // Optimistic update
    queryClient.setQueryData(['agents'], (old: Agent[]) =>
      old.map((a) => a.id === agent.id ? { ...a, status: 'thinking' } : a)
    );

    try {
      await metaAgentService.startAgent(agent.id);
      // Success! Real-time event will update the actual status
    } catch (error) {
      // Rollback optimistic update
      queryClient.setQueryData(['agents'], (old: Agent[]) =>
        old.map((a) => a.id === agent.id ? { ...a, status: 'idle' } : a)
      );
      console.error('Failed to start agent:', error);
    } finally {
      setIsStarting(false);
    }
  };

  return (
    <button
      onClick={handleStart}
      disabled={isStarting || agent.status !== 'idle'}
      className="px-4 py-2 bg-blue-500 text-white rounded-md disabled:opacity-50"
    >
      {isStarting ? 'Starting...' : 'Start Agent'}
    </button>
  );
}
```

## Data Visualization

### Charts (Recharts)

Agent Studio uses Recharts for responsive, animated charts.

```typescript
import {
  LineChart,
  Line,
  AreaChart,
  Area,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from 'recharts';

function MetricsChart({ data }: { data: MetricDataPoint[] }) {
  const chartData = data.map((point) => ({
    time: new Date(point.timestamp).toLocaleTimeString([], {
      hour: '2-digit',
      minute: '2-digit',
    }),
    value: point.value,
  }));

  return (
    <ResponsiveContainer width="100%" height={300}>
      <AreaChart data={chartData}>
        <defs>
          <linearGradient id="colorValue" x1="0" y1="0" x2="0" y2="1">
            <stop offset="5%" stopColor="#00f0ff" stopOpacity={0.3} />
            <stop offset="95%" stopColor="#00f0ff" stopOpacity={0} />
          </linearGradient>
        </defs>
        <CartesianGrid strokeDasharray="3 3" stroke="#1a1a24" />
        <XAxis
          dataKey="time"
          stroke="#6b7280"
          style={{ fontSize: '12px' }}
        />
        <YAxis
          stroke="#6b7280"
          style={{ fontSize: '12px' }}
        />
        <Tooltip content={<CustomTooltip />} />
        <Area
          type="monotone"
          dataKey="value"
          stroke="#00f0ff"
          strokeWidth={2}
          fill="url(#colorValue)"
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}

// Custom tooltip for better UX
function CustomTooltip({ active, payload, label }: any) {
  if (!active || !payload || !payload.length) return null;

  return (
    <div className="bg-gray-800/95 backdrop-blur-sm border border-blue-500/30 rounded-lg p-3 shadow-lg">
      <div className="text-xs text-gray-400 mb-1">{label}</div>
      {payload.map((entry: any, index: number) => (
        <div key={index} className="text-sm font-medium" style={{ color: entry.color }}>
          {entry.name}: {entry.value}
        </div>
      ))}
    </div>
  );
}
```

## Testing

### Unit Tests (Vitest)

Agent Studio uses Vitest for fast unit testing with React Testing Library.

```typescript
/**
 * Component Test Example
 */

import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { AgentCard } from './AgentCard';
import type { Agent } from '../types/meta-agents';

describe('AgentCard', () => {
  const mockAgent: Agent = {
    id: 'agent-1',
    name: 'Test Agent',
    description: 'A test agent',
    type: 'architect',
    status: 'idle',
    capabilities: ['planning', 'reasoning'],
    metrics: {
      totalRequests: 100,
      successRate: 0.95,
      averageResponseTime: 250,
      tokensUsed: 5000,
      errorCount: 5,
      activeTime: 3600,
      lastActivity: new Date(),
    },
    theme: {
      primary: '#00f0ff',
      secondary: '#00ff9f',
      accent: '#a855f7',
      glow: '#00f0ff',
    },
    config: {
      id: 'agent-1',
      name: 'Test Agent',
      description: 'A test agent',
      type: 'architect',
      capabilities: ['planning', 'reasoning'],
    },
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  it('renders agent information correctly', () => {
    render(<AgentCard agent={mockAgent} />);

    expect(screen.getByText('Test Agent')).toBeInTheDocument();
    expect(screen.getByText('A test agent')).toBeInTheDocument();
    expect(screen.getByText(/idle/i)).toBeInTheDocument();
  });

  it('displays capabilities as badges', () => {
    render(<AgentCard agent={mockAgent} />);

    expect(screen.getByText('planning')).toBeInTheDocument();
    expect(screen.getByText('reasoning')).toBeInTheDocument();
  });

  it('shows metrics correctly', () => {
    render(<AgentCard agent={mockAgent} />);

    expect(screen.getByText(/100/)).toBeInTheDocument(); // Total requests
    expect(screen.getByText(/95.0%/)).toBeInTheDocument(); // Success rate
  });

  it('calls onSelect when clicked', () => {
    const onSelect = vi.fn();
    render(<AgentCard agent={mockAgent} onSelect={onSelect} />);

    fireEvent.click(screen.getByRole('button', { name: /Agent Test Agent/i }));

    expect(onSelect).toHaveBeenCalledWith('agent-1');
  });

  it('calls onStart when start button clicked', () => {
    const onStart = vi.fn();
    render(<AgentCard agent={mockAgent} onStart={onStart} />);

    fireEvent.click(screen.getByRole('button', { name: /Start Test Agent/i }));

    expect(onStart).toHaveBeenCalledWith('agent-1');
  });

  it('applies selected styles when isSelected is true', () => {
    const { container } = render(<AgentCard agent={mockAgent} isSelected={true} />);

    const card = container.firstChild;
    expect(card).toHaveClass('border-blue-500');
  });

  it('supports keyboard navigation', () => {
    const onSelect = vi.fn();
    render(<AgentCard agent={mockAgent} onSelect={onSelect} />);

    const card = screen.getByRole('button', { name: /Agent Test Agent/i });
    fireEvent.keyDown(card, { key: 'Enter' });

    expect(onSelect).toHaveBeenCalledWith('agent-1');
  });
});
```

### Hook Tests

```typescript
import { renderHook, waitFor } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { useMetaAgents } from '../useMetaAgents';
import { metaAgentService } from '../../services/metaAgentService';

vi.mock('../../services/metaAgentService');
vi.mock('../useSignalR', () => ({
  useSignalR: vi.fn(() => ({
    connectionState: 'connected',
    isConnected: true,
    subscribe: vi.fn(),
  })),
}));

describe('useMetaAgents', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('fetches agents on mount when autoFetch is true', async () => {
    const mockAgents = [
      { id: 'agent-1', name: 'Agent 1', status: 'idle' },
      { id: 'agent-2', name: 'Agent 2', status: 'thinking' },
    ];

    vi.mocked(metaAgentService.getAgents).mockResolvedValue({
      success: true,
      data: mockAgents,
    });

    const { result } = renderHook(() => useMetaAgents({ autoFetch: true }));

    expect(result.current.loading).toBe(true);

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
      expect(result.current.agents).toEqual(mockAgents);
      expect(result.current.error).toBeNull();
    });
  });

  it('creates agent successfully', async () => {
    const newAgent = { id: 'agent-3', name: 'New Agent', status: 'idle' };

    vi.mocked(metaAgentService.getAgents).mockResolvedValue({
      success: true,
      data: [],
    });

    vi.mocked(metaAgentService.createAgent).mockResolvedValue({
      success: true,
      data: newAgent,
    });

    const { result } = renderHook(() => useMetaAgents());

    await waitFor(() => expect(result.current.loading).toBe(false));

    const created = await result.current.createAgent({
      id: 'agent-3',
      name: 'New Agent',
      type: 'architect',
      capabilities: [],
    });

    expect(created).toEqual(newAgent);
    expect(result.current.agents).toContainEqual(newAgent);
  });

  it('handles errors gracefully', async () => {
    vi.mocked(metaAgentService.getAgents).mockResolvedValue({
      success: false,
      error: 'Network error',
    });

    const { result } = renderHook(() => useMetaAgents());

    await waitFor(() => {
      expect(result.current.error).toBe('Network error');
      expect(result.current.agents).toEqual([]);
    });
  });
});
```

## Performance

### Code Splitting

Use React lazy and Suspense for route-based code splitting:

```typescript
import { lazy, Suspense } from 'react';
import { Routes, Route } from 'react-router-dom';

// Lazy load page components
const MetaAgents = lazy(() => import('./pages/MetaAgents'));
const AgentWorkspace = lazy(() => import('./pages/AgentWorkspace'));
const SettingsPage = lazy(() => import('./pages/SettingsPage'));

function App() {
  return (
    <Suspense fallback={<LoadingScreen />}>
      <Routes>
        <Route path="/" element={<HomePage />} />
        <Route path="/meta-agents" element={<MetaAgents />} />
        <Route path="/workspace" element={<AgentWorkspace />} />
        <Route path="/settings" element={<SettingsPage />} />
      </Routes>
    </Suspense>
  );
}

function LoadingScreen() {
  return (
    <div className="flex items-center justify-center h-screen">
      <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-500" />
    </div>
  );
}
```

### Memoization

Use React's memoization hooks to prevent unnecessary re-renders:

```typescript
import { memo, useMemo, useCallback } from 'react';

// Memoize expensive computations
function AgentStats({ agents }: { agents: Agent[] }) {
  const stats = useMemo(() => {
    return {
      total: agents.length,
      active: agents.filter((a) => a.status === 'executing').length,
      idle: agents.filter((a) => a.status === 'idle').length,
      avgResponseTime: agents.reduce((sum, a) => sum + a.metrics.averageResponseTime, 0) / agents.length,
    };
  }, [agents]);

  return (
    <div className="grid grid-cols-4 gap-4">
      <StatCard label="Total" value={stats.total} />
      <StatCard label="Active" value={stats.active} />
      <StatCard label="Idle" value={stats.idle} />
      <StatCard label="Avg Response" value={`${stats.avgResponseTime.toFixed(0)}ms`} />
    </div>
  );
}

// Memoize callback functions
function AgentsList({ onSelectAgent }: { onSelectAgent: (id: string) => void }) {
  const { agents } = useMetaAgents();

  // Prevent re-creating handler on every render
  const handleSelect = useCallback((id: string) => {
    console.log('Selected agent:', id);
    onSelectAgent(id);
  }, [onSelectAgent]);

  return (
    <div>
      {agents.map((agent) => (
        <AgentCard
          key={agent.id}
          agent={agent}
          onSelect={handleSelect}
        />
      ))}
    </div>
  );
}

// Memoize entire component
const StatCard = memo(function StatCard({
  label,
  value
}: {
  label: string;
  value: string | number;
}) {
  return (
    <div className="p-4 bg-white rounded-lg shadow">
      <div className="text-sm text-gray-500">{label}</div>
      <div className="text-2xl font-bold text-gray-900">{value}</div>
    </div>
  );
});
```

### Virtual Scrolling

For large lists, use virtual scrolling to render only visible items:

```typescript
import { useVirtualizer } from '@tanstack/react-virtual';
import { useRef } from 'react';

function AgentList({ agents }: { agents: Agent[] }) {
  const parentRef = useRef<HTMLDivElement>(null);

  const virtualizer = useVirtualizer({
    count: agents.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 100, // Estimated height of each item
    overscan: 5, // Render 5 items above/below viewport
  });

  return (
    <div ref={parentRef} className="h-screen overflow-auto">
      <div
        style={{
          height: `${virtualizer.getTotalSize()}px`,
          width: '100%',
          position: 'relative',
        }}
      >
        {virtualizer.getVirtualItems().map((virtualItem) => {
          const agent = agents[virtualItem.index];
          return (
            <div
              key={virtualItem.key}
              style={{
                position: 'absolute',
                top: 0,
                left: 0,
                width: '100%',
                height: `${virtualItem.size}px`,
                transform: `translateY(${virtualItem.start}px)`,
              }}
            >
              <AgentCard agent={agent} />
            </div>
          );
        })}
      </div>
    </div>
  );
}
```

## Accessibility

### ARIA Labels

Provide descriptive labels for screen readers:

```typescript
function AgentControls({ agent }: { agent: Agent }) {
  return (
    <div role="group" aria-label={`Controls for ${agent.name}`}>
      <button
        onClick={() => handleStart(agent.id)}
        aria-label={`Start ${agent.name}`}
        aria-disabled={agent.status !== 'idle'}
      >
        <PlayIcon aria-hidden="true" />
        Start
      </button>

      <button
        onClick={() => handleStop(agent.id)}
        aria-label={`Stop ${agent.name}`}
        aria-disabled={agent.status === 'idle'}
      >
        <StopIcon aria-hidden="true" />
        Stop
      </button>
    </div>
  );
}
```

### Keyboard Navigation

Ensure full keyboard accessibility:

```typescript
function Modal({ isOpen, onClose, children }: ModalProps) {
  const modalRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!isOpen) return;

    // Focus trap
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        onClose();
      }

      if (e.key === 'Tab') {
        const focusableElements = modalRef.current?.querySelectorAll(
          'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
        );

        if (!focusableElements || focusableElements.length === 0) return;

        const first = focusableElements[0] as HTMLElement;
        const last = focusableElements[focusableElements.length - 1] as HTMLElement;

        if (e.shiftKey && document.activeElement === first) {
          e.preventDefault();
          last.focus();
        } else if (!e.shiftKey && document.activeElement === last) {
          e.preventDefault();
          first.focus();
        }
      }
    };

    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="modal-title"
      ref={modalRef}
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/50"
    >
      <div className="bg-white rounded-lg p-6 max-w-lg w-full">
        {children}
      </div>
    </div>
  );
}
```

### Color Contrast

Ensure WCAG AA compliance (4.5:1 for normal text, 3:1 for large text):

```typescript
// Good contrast examples
const textColors = {
  // White text on dark backgrounds
  primary: 'bg-blue-600 text-white',          // 4.54:1
  success: 'bg-green-600 text-white',         // 4.55:1
  danger: 'bg-red-600 text-white',            // 5.14:1

  // Dark text on light backgrounds
  light: 'bg-gray-100 text-gray-900',         // 16.23:1
  subtle: 'bg-blue-50 text-blue-900',         // 12.63:1
};

// Bad contrast - avoid these
const badContrast = {
  poor: 'bg-yellow-300 text-white',           // 1.37:1 - Too low!
  insufficient: 'bg-gray-400 text-gray-100',  // 2.91:1 - Below AA
};
```

## Best Practices

### Component Composition

Build complex UIs from simple, composable components:

```typescript
// Bad: Monolithic component
function AgentDashboard() {
  return (
    <div>
      <header>...</header>
      <nav>...</nav>
      <main>
        <aside>...</aside>
        <section>...</section>
      </main>
      <footer>...</footer>
    </div>
  );
}

// Good: Composed from smaller components
function AgentDashboard() {
  return (
    <DashboardLayout>
      <DashboardHeader />
      <DashboardContent>
        <Sidebar />
        <MainContent>
          <AgentsList />
          <AgentDetails />
        </MainContent>
      </DashboardContent>
      <DashboardFooter />
    </DashboardLayout>
  );
}
```

### Error Boundaries

Gracefully handle errors in component trees:

```typescript
import { Component, ErrorInfo, ReactNode } from 'react';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error?: Error;
}

class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('ErrorBoundary caught an error:', error, errorInfo);
    // Log to error reporting service
  }

  render() {
    if (this.state.hasError) {
      return (
        this.props.fallback || (
          <div className="p-8 text-center">
            <h2 className="text-2xl font-bold text-red-600 mb-2">
              Something went wrong
            </h2>
            <p className="text-gray-600 mb-4">
              {this.state.error?.message || 'An unexpected error occurred'}
            </p>
            <button
              onClick={() => this.setState({ hasError: false })}
              className="px-4 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600"
            >
              Try again
            </button>
          </div>
        )
      );
    }

    return this.props.children;
  }
}

// Usage
function App() {
  return (
    <ErrorBoundary>
      <AgentDashboard />
    </ErrorBoundary>
  );
}
```

### Loading States

Provide clear feedback during asynchronous operations:

```typescript
function AgentsList() {
  const { agents, loading, error } = useMetaAgents();

  // Loading state with skeleton
  if (loading) {
    return (
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {Array.from({ length: 6 }).map((_, i) => (
          <div key={i} className="p-4 bg-white rounded-lg shadow animate-pulse">
            <div className="h-4 bg-gray-200 rounded mb-2" />
            <div className="h-3 bg-gray-200 rounded mb-2 w-2/3" />
            <div className="h-3 bg-gray-200 rounded w-1/2" />
          </div>
        ))}
      </div>
    );
  }

  // Error state
  if (error) {
    return (
      <div className="p-8 text-center bg-red-50 rounded-lg">
        <div className="text-red-600 text-4xl mb-2">⚠️</div>
        <h3 className="text-lg font-semibold text-red-900 mb-1">
          Failed to load agents
        </h3>
        <p className="text-red-700 mb-4">{error}</p>
        <button
          onClick={() => window.location.reload()}
          className="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700"
        >
          Retry
        </button>
      </div>
    );
  }

  // Empty state
  if (agents.length === 0) {
    return (
      <div className="p-8 text-center bg-gray-50 rounded-lg">
        <div className="text-gray-400 text-6xl mb-4">🤖</div>
        <h3 className="text-lg font-semibold text-gray-900 mb-1">
          No agents yet
        </h3>
        <p className="text-gray-600 mb-4">
          Get started by creating your first agent
        </p>
        <button className="px-4 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600">
          Create Agent
        </button>
      </div>
    );
  }

  // Success state
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      {agents.map((agent) => (
        <AgentCard key={agent.id} agent={agent} />
      ))}
    </div>
  );
}
```

## Troubleshooting

### Common Issues

**Issue: Component re-renders too often**

Solution: Use React DevTools Profiler to identify the cause. Common fixes:
- Memoize callbacks with `useCallback`
- Memoize computed values with `useMemo`
- Memoize components with `memo()`
- Move state closer to where it's used

**Issue: SignalR connection drops**

Solution: Check the SignalR service configuration and implement reconnection logic with exponential backoff.

**Issue: Type errors in event handlers**

Solution: Use proper React event types:
```typescript
// Correct
const handleClick = (e: React.MouseEvent<HTMLButtonElement>) => {};
const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {};
const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {};

// Incorrect
const handleClick = (e: any) => {}; // Avoid 'any'
```

**Issue: Tailwind classes not applying**

Solution:
- Ensure file is in `content` array in `tailwind.config.js`
- Check for typos in class names
- Use `clsx` or `cn()` for conditional classes
- Don't use string interpolation for dynamic classes

**Issue: Tests failing with async state updates**

Solution: Use `waitFor` from React Testing Library:
```typescript
await waitFor(() => {
  expect(screen.getByText('Success')).toBeInTheDocument();
});
```

## Conclusion

Agent Studio's frontend architecture combines React 19's latest features with TypeScript's type safety, Tailwind's utility-first styling, and SignalR's real-time capabilities to create a robust, performant, and accessible user experience.

Key takeaways:
- Always start with TypeScript interfaces for components and hooks
- Leverage custom hooks to encapsulate and reuse logic
- Use TanStack Query for server state, Zustand for client state
- Build accessible components with ARIA labels and keyboard navigation
- Optimize performance with code splitting, memoization, and virtual scrolling
- Test components thoroughly with Vitest and React Testing Library
- Provide clear loading, error, and empty states for better UX

For more information, see:
- [Workflow Creation Guide](./workflow-creation.md)
- [CI/CD Quickstart](./ci-cd-quickstart.md)
- [TypeScript Best Practices](https://www.typescriptlang.org/docs/)
- [React 19 Documentation](https://react.dev/)
- [Tailwind CSS Documentation](https://tailwindcss.com/)
