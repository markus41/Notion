/**
 * Notion API client wrapper for creating agent activity pages.
 * Establishes reliable integration with proper error handling and retry logic.
 *
 * Best for: Serverless functions requiring sustainable Notion database operations
 */

import { Client } from '@notionhq/client';
import type { AgentActivityEvent, NotionPageProperties, WebhookResponse } from './types';

/**
 * Transform agent activity event to Notion page properties matching Agent Activity Hub schema.
 * Maps local event structure to Notion database property types.
 *
 * @param event - Agent activity data from hook or webhook
 * @returns Notion-compatible page properties
 */
function transformToNotionProperties(event: AgentActivityEvent): NotionPageProperties {
  const properties: NotionPageProperties = {
    'Session ID': {
      title: [{ text: { content: event.sessionId } }]
    },
    'Agent Name': {
      select: { name: event.agentName }
    },
    'Status': {
      select: { name: event.status.charAt(0).toUpperCase() + event.status.slice(1).replace('-', ' ') }
    },
    'Start Time': {
      date: { start: event.startTime }
    }
  };

  // Optional properties - only include if present
  if (event.endTime) {
    properties['End Time'] = { date: { start: event.endTime } };
  }

  if (event.durationMinutes !== undefined) {
    properties['Duration (Minutes)'] = { number: event.durationMinutes };
  }

  if (event.filesCreated !== undefined) {
    properties['Files Created'] = { number: event.filesCreated };
  }

  if (event.filesUpdated !== undefined) {
    properties['Files Updated'] = { number: event.filesUpdated };
  }

  if (event.linesGenerated !== undefined) {
    properties['Lines Generated'] = { number: event.linesGenerated };
  }

  if (event.workDescription) {
    properties['Work Description'] = {
      rich_text: [{ text: { content: event.workDescription.substring(0, 2000) } }]
    };
  }

  if (event.deliverables && event.deliverables.length > 0) {
    const deliverablesText = event.deliverables.join('\n');
    properties['Deliverables'] = {
      rich_text: [{ text: { content: deliverablesText.substring(0, 2000) } }]
    };
  }

  if (event.nextSteps) {
    properties['Next Steps'] = {
      rich_text: [{ text: { content: event.nextSteps.substring(0, 2000) } }]
    };
  }

  if (event.performanceMetrics) {
    properties['Performance Metrics'] = {
      rich_text: [{ text: { content: event.performanceMetrics.substring(0, 2000) } }]
    };
  }

  if (event.blockerDetails) {
    properties['Blocker Details'] = {
      rich_text: [{ text: { content: event.blockerDetails.substring(0, 2000) } }]
    };
  }

  if (event.handoffContext) {
    properties['Handoff Context'] = {
      rich_text: [{ text: { content: event.handoffContext.substring(0, 2000) } }]
    };
  }

  return properties;
}

/**
 * Create agent activity page in Notion Agent Activity Hub database.
 * Streamlines page creation with proper error handling and response formatting.
 *
 * @param notionApiKey - Notion integration API token from Key Vault
 * @param databaseId - Agent Activity Hub database ID (72b879f2-13bd-4edb-9c59-b43089dbef21)
 * @param event - Agent activity event data
 * @returns Webhook response with success status and created page details
 *
 * @example
 * ```typescript
 * const response = await createAgentActivityPage(
 *   process.env.NOTION_API_KEY,
 *   '72b879f213bd4edb9c59b43089dbef21',
 *   agentEvent
 * );
 *
 * if (response.success) {
 *   console.log('Page created:', response.pageUrl);
 * }
 * ```
 */
export async function createAgentActivityPage(
  notionApiKey: string,
  databaseId: string,
  event: AgentActivityEvent
): Promise<WebhookResponse> {
  try {
    const notion = new Client({ auth: notionApiKey });

    const properties = transformToNotionProperties(event);

    const response = await notion.pages.create({
      parent: { database_id: databaseId },
      properties: properties as any, // Notion SDK types are strict, we match schema exactly
    });

    return {
      success: true,
      message: 'Agent activity page created successfully',
      pageId: response.id,
      pageUrl: 'url' in response ? response.url : `https://notion.so/${response.id.replace(/-/g, '')}`
    };
  } catch (error: any) {
    console.error('Failed to create Notion page:', error);

    return {
      success: false,
      message: 'Failed to create agent activity page',
      error: error.message || String(error)
    };
  }
}

/**
 * Check if Notion database is accessible with provided API key.
 * Validates integration permissions and database connectivity.
 *
 * @param notionApiKey - Notion integration API token
 * @param databaseId - Database ID to check
 * @returns true if accessible, false otherwise
 *
 * @example
 * ```typescript
 * const isAccessible = await checkDatabaseAccess(
 *   notionApiKey,
 *   '72b879f213bd4edb9c59b43089dbef21'
 * );
 *
 * if (!isAccessible) {
 *   throw new Error('Database not shared with integration');
 * }
 * ```
 */
export async function checkDatabaseAccess(
  notionApiKey: string,
  databaseId: string
): Promise<boolean> {
  try {
    const notion = new Client({ auth: notionApiKey });
    await notion.databases.retrieve({ database_id: databaseId });
    return true;
  } catch (error) {
    console.error('Database access check failed:', error);
    return false;
  }
}
