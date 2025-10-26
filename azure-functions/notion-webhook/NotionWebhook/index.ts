/**
 * Notion Webhook HTTP Trigger - Real-time agent activity logging endpoint.
 * Establishes reliable webhook listener with signature verification and fallback resilience.
 *
 * Flow:
 * 1. Validate Notion-Signature header (HMAC-SHA256)
 * 2. Parse webhook payload (agent activity event)
 * 3. Create Notion page in Agent Activity Hub
 * 4. Return 200 OK to acknowledge receipt
 *
 * Best for: Production webhook endpoints requiring secure, scalable agent activity tracking
 *
 * @see https://developers.notion.com/reference/webhooks
 */

import { app, HttpRequest, HttpResponseInit, InvocationContext } from '@azure/functions';
import { verifyNotionSignature } from '../shared/signatureVerification';
import { createAgentActivityPage } from '../shared/notionClient';
import { getNotionSecrets } from '../shared/keyVaultClient';
import type { AgentActivityEvent } from '../shared/types';

/**
 * Main webhook handler - processes incoming agent activity events from hook script.
 * Validates signature, creates Notion page, returns success/error response.
 */
export async function NotionWebhookHandler(
  request: HttpRequest,
  context: InvocationContext
): Promise<HttpResponseInit> {
  const startTime = Date.now();
  context.log('Notion webhook triggered - processing agent activity event');

  try {
    // 1. Retrieve secrets from Azure Key Vault (cached for warm starts)
    const keyVaultName = process.env.KEY_VAULT_NAME || 'kv-brookside-secrets';
    const databaseId = process.env.AGENT_ACTIVITY_HUB_ID || '72b879f213bd4edb9c59b43089dbef21';

    const secrets = await getNotionSecrets(keyVaultName);

    // 2. Get raw request body for signature verification
    const rawBody = await request.text();
    const notionSignature = request.headers.get('notion-signature');

    // 3. Verify Notion signature (security: prevent unauthorized webhooks)
    const isValid = verifyNotionSignature(rawBody, notionSignature, secrets.notionWebhookSecret);

    if (!isValid) {
      context.log.error('Invalid webhook signature - rejecting request');
      return {
        status: 401,
        jsonBody: {
          success: false,
          message: 'Invalid signature',
          error: 'Webhook signature verification failed'
        }
      };
    }

    context.log('Signature verified successfully');

    // 4. Parse agent activity event from request body
    let event: AgentActivityEvent;
    try {
      event = JSON.parse(rawBody) as AgentActivityEvent;
    } catch (parseError: any) {
      context.log.error('Failed to parse webhook payload:', parseError);
      return {
        status: 400,
        jsonBody: {
          success: false,
          message: 'Invalid JSON payload',
          error: parseError.message
        }
      };
    }

    // 5. Validate required fields
    if (!event.sessionId || !event.agentName || !event.status) {
      context.log.error('Missing required fields in webhook payload');
      return {
        status: 400,
        jsonBody: {
          success: false,
          message: 'Missing required fields',
          error: 'sessionId, agentName, and status are required'
        }
      };
    }

    context.log(`Processing activity: ${event.agentName} - ${event.sessionId}`);

    // 6. Create Notion page in Agent Activity Hub
    const result = await createAgentActivityPage(
      secrets.notionApiKey,
      databaseId,
      event
    );

    const duration = Date.now() - startTime;

    if (result.success) {
      context.log(`Page created successfully in ${duration}ms: ${result.pageUrl}`);

      return {
        status: 200,
        jsonBody: {
          success: true,
          message: 'Agent activity logged successfully',
          pageId: result.pageId,
          pageUrl: result.pageUrl,
          duration: duration
        }
      };
    } else {
      context.log.error(`Failed to create page: ${result.error}`);

      return {
        status: 500,
        jsonBody: {
          success: false,
          message: 'Failed to create Notion page',
          error: result.error,
          duration: duration
        }
      };
    }
  } catch (error: any) {
    const duration = Date.now() - startTime;
    context.log.error('Webhook handler error:', error);

    return {
      status: 500,
      jsonBody: {
        success: false,
        message: 'Internal server error',
        error: error.message || String(error),
        duration: duration
      }
    };
  }
}

// Register HTTP trigger
app.http('NotionWebhook', {
  methods: ['POST'],
  authLevel: 'anonymous',
  route: 'NotionWebhook',
  handler: NotionWebhookHandler
});
