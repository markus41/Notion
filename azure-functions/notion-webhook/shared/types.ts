/**
 * Type definitions for Notion webhook integration and agent activity logging.
 * Establishes structured data contracts for sustainable multi-tier tracking system.
 *
 * Best for: Organizations scaling agent activity monitoring with type-safe implementations
 */

export interface AgentActivityEvent {
  sessionId: string;
  agentName: string;
  status: 'in-progress' | 'completed' | 'blocked' | 'handed-off';
  workDescription: string;
  startTime: string; // ISO-8601 datetime
  endTime?: string; // ISO-8601 datetime
  durationMinutes?: number;
  filesCreated?: number;
  filesUpdated?: number;
  linesGenerated?: number;
  deliverablesCount?: number;
  deliverables?: string[];
  nextSteps?: string;
  performanceMetrics?: string;
  relatedNotionItems?: string;
  blockerDetails?: string;
  handoffContext?: string;
  webhookSynced?: boolean;
  webhookAttemptedAt?: string;
  queuedAt: string;
  syncStatus: 'pending' | 'synced' | 'failed';
  retryCount: number;
}

export interface NotionWebhookEvent {
  object: 'event';
  id: string;
  created_time: string;
  last_edited_time: string;
  parent: {
    type: 'database_id';
    database_id: string;
  };
  properties: Record<string, unknown>;
  type: 'page';
}

export interface NotionWebhookPayload {
  type: 'page.created' | 'page.updated' | 'page.deleted';
  page: NotionWebhookEvent;
  webhook_id: string;
}

export interface NotionPageProperties {
  'Session ID': { title: [{ text: { content: string } }] };
  'Agent Name': { select: { name: string } };
  'Status': { select: { name: string } };
  'Start Time': { date: { start: string } };
  'End Time'?: { date: { start: string } };
  'Duration (Minutes)'?: { number: number };
  'Files Created'?: { number: number };
  'Files Updated'?: { number: number };
  'Lines Generated'?: { number: number };
  'Work Description'?: { rich_text: [{ text: { content: string } }] };
  'Deliverables'?: { rich_text: [{ text: { content: string } }] };
  'Next Steps'?: { rich_text: [{ text: { content: string } }] };
  'Performance Metrics'?: { rich_text: [{ text: { content: string } }] };
  'Blocker Details'?: { rich_text: [{ text: { content: string } }] };
  'Handoff Context'?: { rich_text: [{ text: { content: string } }] };
}

export interface WebhookResponse {
  success: boolean;
  message: string;
  pageId?: string;
  pageUrl?: string;
  error?: string;
}

export interface QueueEntry extends AgentActivityEvent {
  LineNumber?: number;
}

export interface KeyVaultSecrets {
  notionApiKey: string;
  notionWebhookSecret: string;
}

export interface WebhookConfig {
  databaseId: string;
  webhookEndpoint: string;
  maxRetries: number;
  timeoutSeconds: number;
}
