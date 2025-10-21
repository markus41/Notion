/**
 * Escalate to Human Activity Function
 *
 * Establishes structured human escalation workflow when autonomous decisions
 * require manual review, approval, or expertise beyond automation thresholds.
 *
 * This solution is designed to support sustainable governance practices where
 * complex decisions escalate to appropriate stakeholders with complete context.
 *
 * Best for: Organizations requiring human oversight for high-stakes decisions
 * while maintaining autonomous execution for routine operations.
 */

const NotionClient = require('../Shared/notionClient');
const axios = require('axios');

/**
 * Escalation Notification Channels
 *
 * Configure multiple notification methods to ensure stakeholder awareness.
 */
const ESCALATION_CHANNELS = {
  notion: true,           // Update Notion page with escalation flag
  email: true,            // Send email notification (via Logic App/Power Automate)
  teams: true,            // Post to Teams channel
  appInsights: true       // Log to Application Insights for tracking
};

/**
 * Main Activity Function
 *
 * @param {object} context - Durable Functions activity context
 * @returns {object} Escalation record
 */
module.exports = async function (context) {
  const input = context.bindings.context;
  const { pageId, reason, details } = input;

  context.log('Escalating to human decision', {
    pageId,
    reason,
    viabilityScore: details.viabilityScore,
    estimatedCost: details.estimatedCost
  });

  try {
    const notionClient = new NotionClient(process.env.NOTION_API_KEY);
    const escalationId = generateEscalationId();

    // Create escalation record
    const escalationRecord = {
      id: escalationId,
      pageId,
      reason,
      details,
      timestamp: new Date().toISOString(),
      status: 'pending_review',
      assignedTo: assignReviewer(reason, details)
    };

    // Update Notion page with escalation status
    if (ESCALATION_CHANNELS.notion) {
      await updateNotionWithEscalation(notionClient, pageId, reason, escalationRecord);
    }

    // Send email notification
    if (ESCALATION_CHANNELS.email) {
      await sendEmailNotification(escalationRecord, context);
    }

    // Post to Teams channel
    if (ESCALATION_CHANNELS.teams) {
      await postToTeamsChannel(escalationRecord, context);
    }

    // Log to Application Insights
    if (ESCALATION_CHANNELS.appInsights) {
      context.log.metric('HumanEscalation', 1, {
        reason,
        pageId,
        viabilityScore: details.viabilityScore,
        estimatedCost: details.estimatedCost
      });
    }

    context.log('Escalation created successfully', {
      escalationId,
      assignedTo: escalationRecord.assignedTo
    });

    return escalationRecord;

  } catch (error) {
    context.log.error('Failed to create escalation', {
      error: error.message,
      pageId,
      reason
    });
    throw error;
  }
};

/**
 * Generate Escalation ID
 *
 * Creates unique identifier for tracking escalation lifecycle.
 *
 * @returns {string} Escalation ID
 */
function generateEscalationId() {
  const timestamp = Date.now().toString(36);
  const random = Math.random().toString(36).substring(2, 7);
  return `ESC-${timestamp}-${random}`.toUpperCase();
}

/**
 * Assign Reviewer
 *
 * Determines appropriate stakeholder for escalation review based on reason and context.
 *
 * @param {string} reason - Escalation reason code
 * @param {object} details - Escalation context details
 * @returns {string} Assigned reviewer name or role
 */
function assignReviewer(reason, details) {
  const assignmentRules = {
    'viability_gray_zone': 'Markus Ahling',          // Engineering lead for technical decisions
    'cost_threshold_exceeded': 'Brad Wright',         // Finance/business lead for budget decisions
    'high_cost_low_viability': 'Brad Wright',
    'deployment_failed': 'Alec Fielding',            // DevOps lead for infrastructure issues
    'security_review_required': 'Alec Fielding',     // Security specialist
    'complex_architecture': 'Markus Ahling',
    'integration_complexity': 'Alec Fielding'
  };

  // Default to engineering lead if no specific rule
  return assignmentRules[reason] || 'Markus Ahling';
}

/**
 * Update Notion with Escalation
 *
 * Flags Notion page for human review with escalation context.
 *
 * @param {NotionClient} notionClient - Initialized Notion client
 * @param {string} pageId - Notion page ID
 * @param {string} reason - Escalation reason
 * @param {object} escalationRecord - Complete escalation record
 */
async function updateNotionWithEscalation(notionClient, pageId, reason, escalationRecord) {
  // Update page properties
  await notionClient.updatePage(pageId, {
    'Automation Status': {
      select: { name: 'Requires Review' }
    },
    'Escalation Reason': {
      rich_text: [
        {
          text: { content: formatEscalationReason(reason) }
        }
      ]
    },
    'Assigned To': {
      select: { name: escalationRecord.assignedTo }
    },
    'Last Automation Event': {
      rich_text: [
        {
          text: { content: new Date().toISOString() }
        }
      ]
    }
  });

  // Add detailed comment with escalation context
  const commentText = buildEscalationComment(reason, escalationRecord.details, escalationRecord.id);
  await notionClient.addComment(pageId, commentText);
}

/**
 * Format Escalation Reason
 *
 * Converts reason code to human-readable description.
 *
 * @param {string} reason - Escalation reason code
 * @returns {string} Formatted reason text
 */
function formatEscalationReason(reason) {
  const reasonDescriptions = {
    'viability_gray_zone': '⚡ Viability Score in Gray Zone (60-85) - Manual Review Required',
    'cost_threshold_exceeded': '💰 Estimated Cost Exceeds $500/month Threshold - Budget Approval Needed',
    'high_cost_low_viability': '⚠️ High Cost + Low Viability - Strategic Decision Required',
    'deployment_failed': '🔧 Automated Deployment Failed - DevOps Intervention Required',
    'security_review_required': '🔒 Security Review Required - Compliance Approval Needed',
    'complex_architecture': '🏗️ Architecture Complexity High - Expert Review Required',
    'integration_complexity': '🔗 Integration Complexity High - Specialist Review Required'
  };

  return reasonDescriptions[reason] || `❓ Manual Review Required: ${reason}`;
}

/**
 * Build Escalation Comment
 *
 * Constructs comprehensive comment with escalation context and decision guidance.
 *
 * @param {string} reason - Escalation reason
 * @param {object} details - Escalation details
 * @param {string} escalationId - Escalation identifier
 * @returns {string} Formatted comment text
 */
function buildEscalationComment(reason, details, escalationId) {
  const sections = [];

  sections.push('🚨 HUMAN ESCALATION REQUIRED');
  sections.push(`Escalation ID: ${escalationId}`);
  sections.push(`Reason: ${formatEscalationReason(reason)}`);
  sections.push('');

  sections.push('CONTEXT:');
  if (details.viabilityScore !== undefined) {
    sections.push(`  Viability Score: ${details.viabilityScore}/100`);
    sections.push(`  Viability Assessment: ${details.viabilityAssessment || 'N/A'}`);
  }
  if (details.estimatedCost !== undefined) {
    sections.push(`  Estimated Monthly Cost: $${details.estimatedCost}`);
    if (details.threshold) {
      sections.push(`  Cost Threshold: $${details.threshold}`);
    }
  }
  if (details.recommendation) {
    sections.push(`  AI Recommendation: ${details.recommendation}`);
  }
  sections.push('');

  sections.push('REQUIRED ACTION:');
  if (reason === 'viability_gray_zone') {
    sections.push('  Review viability assessment and research findings');
    sections.push('  Decision: Proceed to Build OR Request More Research OR Archive');
  } else if (reason === 'cost_threshold_exceeded') {
    sections.push('  Review estimated costs and budget implications');
    sections.push('  Decision: Approve Budget OR Optimize Costs OR Decline');
  } else if (reason === 'deployment_failed') {
    sections.push('  Review deployment logs and error messages');
    sections.push('  Decision: Manual Fix OR Retry Deployment OR Escalate to DevOps');
  } else {
    sections.push('  Review details above and make decision');
    sections.push('  Update Automation Status to resume workflow');
  }
  sections.push('');

  sections.push(`🤖 Escalated by Autonomous Platform at ${new Date().toISOString()}`);

  return sections.join('\n');
}

/**
 * Send Email Notification
 *
 * Triggers email notification via Azure Logic App or Power Automate flow.
 *
 * @param {object} escalationRecord - Escalation record
 * @param {object} context - Function context for logging
 */
async function sendEmailNotification(escalationRecord, context) {
  try {
    const logicAppUrl = process.env.LOGIC_APP_EMAIL_WEBHOOK_URL;

    if (!logicAppUrl) {
      context.log.warn('Logic App webhook URL not configured - skipping email notification');
      return;
    }

    await axios.post(logicAppUrl, {
      to: getEmailForReviewer(escalationRecord.assignedTo),
      subject: `[Innovation Platform] Escalation Required: ${escalationRecord.reason}`,
      body: buildEmailBody(escalationRecord),
      priority: 'high'
    });

    context.log('Email notification sent', {
      escalationId: escalationRecord.id,
      assignedTo: escalationRecord.assignedTo
    });

  } catch (error) {
    context.log.error('Failed to send email notification', {
      error: error.message,
      escalationId: escalationRecord.id
    });
    // Don't throw - email failure shouldn't block escalation
  }
}

/**
 * Get Email for Reviewer
 *
 * Maps reviewer name to email address.
 *
 * @param {string} reviewerName - Assigned reviewer name
 * @returns {string} Email address
 */
function getEmailForReviewer(reviewerName) {
  const emailMap = {
    'Markus Ahling': 'markus@brooksidebi.com',
    'Brad Wright': 'brad@brooksidebi.com',
    'Stephan Densby': 'stephan@brooksidebi.com',
    'Alec Fielding': 'alec@brooksidebi.com',
    'Mitch Bisbee': 'mitch@brooksidebi.com'
  };

  return emailMap[reviewerName] || 'consultations@brooksidebi.com';
}

/**
 * Build Email Body
 *
 * Constructs HTML email body with escalation details.
 *
 * @param {object} escalationRecord - Escalation record
 * @returns {string} HTML email body
 */
function buildEmailBody(escalationRecord) {
  return `
    <h2>Escalation Required: ${formatEscalationReason(escalationRecord.reason)}</h2>
    <p><strong>Escalation ID:</strong> ${escalationRecord.id}</p>
    <p><strong>Timestamp:</strong> ${new Date(escalationRecord.timestamp).toLocaleString()}</p>

    <h3>Context:</h3>
    <ul>
      ${escalationRecord.details.viabilityScore !== undefined ? `<li>Viability Score: ${escalationRecord.details.viabilityScore}/100</li>` : ''}
      ${escalationRecord.details.estimatedCost !== undefined ? `<li>Estimated Monthly Cost: $${escalationRecord.details.estimatedCost}</li>` : ''}
      ${escalationRecord.details.recommendation ? `<li>AI Recommendation: ${escalationRecord.details.recommendation}</li>` : ''}
    </ul>

    <h3>Action Required:</h3>
    <p>Please review the escalation in Notion and update the Automation Status to resume the workflow.</p>

    <p><a href="https://notion.so/${escalationRecord.pageId}">View in Notion →</a></p>

    <hr>
    <p style="color: #666; font-size: 12px;">
      🤖 This escalation was automatically generated by the Brookside BI Innovation Platform.
    </p>
  `;
}

/**
 * Post to Teams Channel
 *
 * Posts escalation notification to Microsoft Teams channel via webhook.
 *
 * @param {object} escalationRecord - Escalation record
 * @param {object} context - Function context for logging
 */
async function postToTeamsChannel(escalationRecord, context) {
  try {
    const teamsWebhookUrl = process.env.TEAMS_WEBHOOK_URL;

    if (!teamsWebhookUrl) {
      context.log.warn('Teams webhook URL not configured - skipping Teams notification');
      return;
    }

    const card = {
      "@type": "MessageCard",
      "@context": "https://schema.org/extensions",
      "summary": `Escalation Required: ${escalationRecord.reason}`,
      "themeColor": "FF6B35",
      "title": "🚨 Human Escalation Required",
      "sections": [
        {
          "activityTitle": formatEscalationReason(escalationRecord.reason),
          "activitySubtitle": `Assigned to: ${escalationRecord.assignedTo}`,
          "facts": [
            {
              "name": "Escalation ID",
              "value": escalationRecord.id
            },
            {
              "name": "Viability Score",
              "value": escalationRecord.details.viabilityScore !== undefined ?
                `${escalationRecord.details.viabilityScore}/100` : 'N/A'
            },
            {
              "name": "Estimated Cost",
              "value": escalationRecord.details.estimatedCost !== undefined ?
                `$${escalationRecord.details.estimatedCost}/month` : 'N/A'
            }
          ]
        }
      ],
      "potentialAction": [
        {
          "@type": "OpenUri",
          "name": "View in Notion",
          "targets": [
            {
              "os": "default",
              "uri": `https://notion.so/${escalationRecord.pageId}`
            }
          ]
        }
      ]
    };

    await axios.post(teamsWebhookUrl, card);

    context.log('Teams notification sent', {
      escalationId: escalationRecord.id
    });

  } catch (error) {
    context.log.error('Failed to send Teams notification', {
      error: error.message,
      escalationId: escalationRecord.id
    });
    // Don't throw - Teams failure shouldn't block escalation
  }
}
