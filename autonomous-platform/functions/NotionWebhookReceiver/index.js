/**
 * Notion Webhook Receiver
 *
 * Establishes secure webhook endpoint for Notion database property changes.
 * Routes events to appropriate Durable Function orchestrators based on trigger matrix.
 *
 * Best for: Real-time automation triggers with event validation and routing logic
 */

const df = require("durable-functions");
const crypto = require("crypto");

/**
 * Notion Webhook Trigger Matrix
 * Maps database changes to orchestrator workflows
 */
const TRIGGER_MATRIX = {
  // Ideas Registry Triggers
  ideas: {
    statusToActive: {
      condition: (page) => page.properties.Status?.select?.name === 'Active' &&
                          page.properties.Viability?.select?.name === 'Needs Research',
      orchestrator: 'ResearchSwarmOrchestrator',
      description: 'Launch autonomous research swarm'
    },
    fastTrackBuild: {
      condition: (page) => page.properties.Status?.select?.name === 'Active' &&
                          ['High', 'Medium'].includes(page.properties.Viability?.select?.name) &&
                          ['XS', 'S'].includes(page.properties.Effort?.select?.name),
      orchestrator: 'BuildPipelineOrchestrator',
      description: 'Fast-track to build (skip research)'
    },
    highViability: {
      condition: (page) => {
        const score = page.properties['Viability Score']?.number || 0;
        const effort = page.properties.Effort?.select?.name;
        const cost = page.properties['Estimated Cost']?.number || 0;
        return score > 85 && ['XS', 'S'].includes(effort) && cost < 500;
      },
      orchestrator: 'BuildPipelineOrchestrator',
      description: 'Auto-approve and trigger autonomous build'
    }
  },

  // Research Hub Triggers
  research: {
    researchComplete: {
      condition: (page) => {
        const progress = page.properties['Research Progress %']?.number || 0;
        return progress === 100;
      },
      orchestrator: 'ViabilityAssessmentOrchestrator',
      description: 'Synthesize findings and calculate viability'
    },
    highViabilityResearch: {
      condition: (page) => {
        const score = page.properties['Viability Score']?.number || 0;
        const nextSteps = page.properties['Next Steps']?.select?.name;
        return score > 85 && nextSteps === 'Build Example';
      },
      orchestrator: 'BuildPipelineOrchestrator',
      description: 'Auto-trigger build pipeline from research'
    },
    lowViabilityResearch: {
      condition: (page) => {
        const score = page.properties['Viability Score']?.number || 0;
        const nextSteps = page.properties['Next Steps']?.select?.name;
        return score < 60 || nextSteps === 'Abandon';
      },
      orchestrator: 'ArchiveOrchestrator',
      description: 'Auto-archive with learnings'
    }
  },

  // Example Builds Triggers
  builds: {
    buildComplete: {
      condition: (page) => page.properties.Status?.select?.name === 'Completed' &&
                          page.properties['GitHub Repo']?.url &&
                          page.properties['Live URL']?.url,
      orchestrator: 'KnowledgeCaptureOrchestrator',
      description: 'Archive with knowledge capture and pattern learning'
    },
    deploymentFailing: {
      condition: (page) => page.properties['Deployment Health']?.select?.name === 'Failing',
      orchestrator: 'HealthRemediationOrchestrator',
      description: 'Attempt auto-remediation'
    }
  }
};

/**
 * Verify Notion webhook signature
 */
function verifyNotionSignature(req) {
  const notionSignature = req.headers['notion-signature'];
  if (!notionSignature) {
    return false;
  }

  // Notion uses HMAC SHA-256 with webhook secret
  // For now, accept all requests (configure secret in production)
  // TODO: Implement proper signature verification
  return true;
}

/**
 * Determine database type from page ID
 */
async function getDatabaseType(pageId) {
  // Database IDs from configuration
  const DATABASE_IDS = {
    ideas: process.env.NOTION_IDEAS_DATABASE_ID || '984a4038-3e45-4a98-8df4-fd64dd8a1032',
    research: process.env.NOTION_RESEARCH_DATABASE_ID || '91e8beff-af94-4614-90b9-3a6d3d788d4a',
    builds: process.env.NOTION_BUILDS_DATABASE_ID || 'a1cd1528-971d-4873-a176-5e93b93555f6'
  };

  // In production, query Notion API to determine parent database
  // For now, return based on known patterns
  return 'ideas'; // Simplified for initial implementation
}

/**
 * Evaluate trigger conditions and route to orchestrator
 */
function evaluateTriggers(databaseType, page) {
  const triggers = TRIGGER_MATRIX[databaseType];
  if (!triggers) {
    return null;
  }

  // Find first matching trigger
  for (const [triggerName, trigger] of Object.entries(triggers)) {
    if (trigger.condition(page)) {
      return {
        orchestrator: trigger.orchestrator,
        description: trigger.description,
        triggerName,
        databaseType
      };
    }
  }

  return null;
}

/**
 * Main webhook handler
 */
module.exports = async function (context, req) {
  context.log('Notion webhook received', {
    headers: req.headers,
    bodySize: req.body ? JSON.stringify(req.body).length : 0
  });

  // Verify signature
  if (!verifyNotionSignature(req)) {
    context.log.warn('Invalid Notion signature');
    context.res = {
      status: 401,
      body: { error: 'Unauthorized: Invalid signature' }
    };
    return;
  }

  // Parse webhook payload
  const event = req.body;

  // Notion webhook verification (challenge response)
  if (event.type === 'url_verification') {
    context.log('Webhook verification request');
    context.res = {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
      body: { challenge: event.challenge }
    };
    return;
  }

  // Handle page update events
  if (event.type === 'page.property_values.updated') {
    const pageId = event.data.id;
    const page = event.data;

    context.log('Page property updated', {
      pageId,
      properties: Object.keys(page.properties || {})
    });

    // Determine database type
    const databaseType = await getDatabaseType(pageId);

    // Evaluate trigger conditions
    const triggerResult = evaluateTriggers(databaseType, page);

    if (triggerResult) {
      context.log('Trigger matched', triggerResult);

      // Start Durable Function orchestration
      const client = df.getClient(context);
      const instanceId = await client.startNew(
        triggerResult.orchestrator,
        undefined,
        {
          pageId,
          databaseType: triggerResult.databaseType,
          triggerName: triggerResult.triggerName,
          eventTimestamp: new Date().toISOString(),
          page: page // Include full page data for orchestrator
        }
      );

      context.log(`Started orchestration: ${triggerResult.orchestrator}`, {
        instanceId,
        pageId,
        trigger: triggerResult.triggerName
      });

      context.res = {
        status: 202,
        headers: {
          'Content-Type': 'application/json',
          'Location': client.createCheckStatusResponse(context.bindingData, instanceId).headers.Location
        },
        body: {
          message: 'Automation workflow started',
          orchestrator: triggerResult.orchestrator,
          instanceId,
          trigger: triggerResult.description
        }
      };
    } else {
      context.log('No trigger matched for this event');
      context.res = {
        status: 200,
        body: { message: 'Event received, no automation triggered' }
      };
    }
  } else {
    context.log.warn('Unhandled event type', { type: event.type });
    context.res = {
      status: 200,
      body: { message: 'Event received but not processed' }
    };
  }
};
