/**
 * Archive with Learnings Activity Function
 *
 * Establishes structured archival workflow that preserves valuable insights
 * from low-viability ideas, preventing knowledge loss while maintaining
 * clean active workspace.
 *
 * This solution is designed to support organizational learning where even
 * unsuccessful ideas contribute to institutional knowledge through systematic
 * documentation of failure reasons and context.
 *
 * Best for: Organizations valuing continuous improvement where learnings
 * from declined ideas inform future decision-making and prevent duplicate investigation.
 */

const NotionClient = require('../Shared/notionClient');

const KNOWLEDGE_VAULT_DATABASE_ID = process.env.NOTION_DATABASE_ID_KNOWLEDGE || '13b5e9de-2dd1-45ec-839a-4f3d50cd8d06';

/**
 * Main Activity Function
 *
 * @param {object} context - Durable Functions activity context
 * @returns {object} Archive result with Knowledge Vault entry ID
 */
module.exports = async function (context) {
  const input = context.bindings.context;
  const { pageId, reason, viabilityScore, researchSummary } = input;

  context.log('Archiving idea with learnings preservation', {
    pageId,
    reason,
    viabilityScore
  });

  try {
    const notionClient = new NotionClient(process.env.NOTION_API_KEY);

    // Fetch original idea page for context
    const ideaPage = await notionClient.getPage(pageId);
    const ideaTitle = notionClient.extractPropertyValue(ideaPage.properties.Title);
    const ideaDescription = notionClient.extractPropertyValue(ideaPage.properties.Description);
    const ideaCategory = notionClient.extractPropertyValue(ideaPage.properties.Category);

    // Update idea page to Archived status
    await notionClient.updatePage(pageId, {
      'Status': {
        select: { name: 'Archived' }
      },
      'Viability': {
        select: { name: 'Not Viable' }
      },
      'Archive Reason': {
        rich_text: [
          {
            text: { content: formatArchiveReason(reason, viabilityScore) }
          }
        ]
      },
      'Archived Date': {
        date: { start: new Date().toISOString().split('T')[0] }
      },
      'Last Automation Event': {
        rich_text: [
          {
            text: { content: new Date().toISOString() }
          }
        ]
      }
    });

    // Create Knowledge Vault entry with learnings
    const knowledgeVaultEntry = await createKnowledgeVaultEntry(
      notionClient,
      ideaTitle,
      ideaDescription,
      ideaCategory,
      reason,
      viabilityScore,
      researchSummary,
      pageId
    );

    // Add archival comment to idea page
    const archivalComment = buildArchivalComment(reason, viabilityScore, researchSummary, knowledgeVaultEntry.id);
    await notionClient.addComment(pageId, archivalComment);

    context.log('Idea archived successfully with learnings', {
      pageId,
      knowledgeVaultId: knowledgeVaultEntry.id,
      viabilityScore
    });

    return {
      success: true,
      pageId,
      knowledgeVaultId: knowledgeVaultEntry.id,
      status: 'archived_with_learnings'
    };

  } catch (error) {
    context.log.error('Failed to archive idea with learnings', {
      error: error.message,
      pageId
    });
    throw error;
  }
};

/**
 * Format Archive Reason
 *
 * Converts reason code to human-readable explanation.
 *
 * @param {string} reason - Archive reason code
 * @param {number} viabilityScore - Composite viability score
 * @returns {string} Formatted reason text
 */
function formatArchiveReason(reason, viabilityScore) {
  const reasonDescriptions = {
    'low_viability': `Low Viability (Score: ${viabilityScore}/100) - Research indicated insufficient value proposition`,
    'high_cost_low_benefit': `Cost-Benefit Analysis Unfavorable - Operational costs exceed expected benefits`,
    'market_opportunity_insufficient': `Limited Market Opportunity - Competitive landscape or demand validation failed`,
    'technical_complexity_high': `Technical Complexity Excessive - Implementation effort exceeds strategic value`,
    'regulatory_constraints': `Regulatory or Compliance Barriers - Legal/compliance requirements prohibitive`,
    'resource_constraints': `Resource Capacity Insufficient - Team capacity or skill gaps prevent execution`,
    'strategic_misalignment': `Strategic Misalignment - Does not align with current organizational priorities`
  };

  return reasonDescriptions[reason] || `Archived: ${reason} (Viability: ${viabilityScore}/100)`;
}

/**
 * Create Knowledge Vault Entry
 *
 * Establishes comprehensive documentation of why idea was not pursued,
 * preserving context for future reference and preventing duplicate investigation.
 *
 * @param {NotionClient} notionClient - Initialized Notion client
 * @param {string} ideaTitle - Original idea title
 * @param {string} ideaDescription - Original idea description
 * @param {string} ideaCategory - Idea category
 * @param {string} reason - Archive reason
 * @param {number} viabilityScore - Composite viability score
 * @param {object} researchSummary - Research findings summary
 * @param {string} ideaPageId - Original idea page ID
 * @returns {object} Created Knowledge Vault page
 */
async function createKnowledgeVaultEntry(
  notionClient,
  ideaTitle,
  ideaDescription,
  ideaCategory,
  reason,
  viabilityScore,
  researchSummary,
  ideaPageId
) {
  const knowledgeTitle = `[Archived] ${ideaTitle}`;
  const knowledgeContent = buildKnowledgeContent(
    ideaTitle,
    ideaDescription,
    ideaCategory,
    reason,
    viabilityScore,
    researchSummary
  );

  const knowledgeVaultEntry = await notionClient.createPage({
    parent: { database_id: KNOWLEDGE_VAULT_DATABASE_ID },
    properties: {
      // Title
      'Title': {
        title: [
          {
            text: { content: knowledgeTitle }
          }
        ]
      },

      // Content Type
      'Content Type': {
        select: { name: 'Post-Mortem' }
      },

      // Status
      'Status': {
        select: { name: 'Published' }
      },

      // Evergreen/Dated
      'Evergreen/Dated': {
        select: { name: 'Dated' } // Archive reasons are time-sensitive
      },

      // Category (if property exists)
      'Category': {
        select: { name: ideaCategory }
      },

      // Tags (using multi-select if property exists)
      'Tags': {
        multi_select: [
          { name: 'Archived Idea' },
          { name: 'Low Viability' },
          { name: ideaCategory }
        ]
      },

      // Created Date
      'Created Date': {
        date: { start: new Date().toISOString().split('T')[0] }
      }
    },
    children: [
      {
        object: 'block',
        type: 'heading_1',
        heading_1: {
          rich_text: [
            {
              type: 'text',
              text: { content: 'Why This Idea Was Not Pursued' }
            }
          ]
        }
      },
      {
        object: 'block',
        type: 'paragraph',
        paragraph: {
          rich_text: [
            {
              type: 'text',
              text: { content: knowledgeContent }
            }
          ]
        }
      }
    ]
  });

  // Create relation back to original idea (if property exists)
  try {
    await notionClient.updatePage(knowledgeVaultEntry.id, {
      'Ideas': {
        relation: [{ id: ideaPageId }]
      }
    });
  } catch (error) {
    // Relation property may not exist - continue without it
    console.log('Could not create relation to idea:', error.message);
  }

  return knowledgeVaultEntry;
}

/**
 * Build Knowledge Content
 *
 * Constructs comprehensive documentation of archive rationale and learnings.
 *
 * @param {string} ideaTitle - Original idea title
 * @param {string} ideaDescription - Original idea description
 * @param {string} ideaCategory - Idea category
 * @param {string} reason - Archive reason
 * @param {number} viabilityScore - Composite viability score
 * @param {object} researchSummary - Research findings
 * @returns {string} Formatted knowledge content
 */
function buildKnowledgeContent(ideaTitle, ideaDescription, ideaCategory, reason, viabilityScore, researchSummary) {
  const sections = [];

  sections.push(`ORIGINAL IDEA: ${ideaTitle}`);
  sections.push('');

  if (ideaDescription) {
    sections.push('DESCRIPTION:');
    sections.push(ideaDescription);
    sections.push('');
  }

  sections.push('ARCHIVE DECISION:');
  sections.push(formatArchiveReason(reason, viabilityScore));
  sections.push('');

  if (researchSummary) {
    sections.push('RESEARCH FINDINGS:');
    sections.push('');

    if (researchSummary.marketAnalysis) {
      sections.push(`Market Opportunity (Score: ${researchSummary.marketAnalysis.score}/100):`);
      sections.push(`  ${researchSummary.marketAnalysis.summary || 'See research details'}`);
      sections.push('');
    }

    if (researchSummary.technicalFeasibility) {
      sections.push(`Technical Feasibility (Score: ${researchSummary.technicalFeasibility.score}/100):`);
      sections.push(`  ${researchSummary.technicalFeasibility.summary || 'See research details'}`);
      sections.push('');
    }

    if (researchSummary.costAnalysis) {
      sections.push(`Cost Analysis (Score: ${researchSummary.costAnalysis.score}/100):`);
      sections.push(`  Estimated Monthly Cost: $${researchSummary.costAnalysis.monthlyCost || 'N/A'}`);
      sections.push(`  ${researchSummary.costAnalysis.summary || 'See research details'}`);
      sections.push('');
    }

    if (researchSummary.riskAssessment) {
      sections.push(`Risk Assessment (Score: ${researchSummary.riskAssessment.score}/100):`);
      sections.push(`  ${researchSummary.riskAssessment.summary || 'See research details'}`);
      if (researchSummary.riskAssessment.risks && researchSummary.riskAssessment.risks.length > 0) {
        sections.push('  Key Risks:');
        researchSummary.riskAssessment.risks.forEach(risk => {
          sections.push(`    - ${risk}`);
        });
      }
      sections.push('');
    }
  }

  sections.push('KEY LEARNINGS:');
  sections.push('');

  // Extract key learnings based on reason
  if (reason === 'low_viability') {
    sections.push('- Multi-dimensional viability assessment completed with quantitative scoring');
    sections.push('- Low composite score indicates insufficient strategic value to pursue');
    sections.push('- Research methodology validated; findings documented for future reference');
  } else if (reason === 'high_cost_low_benefit') {
    sections.push('- Comprehensive cost analysis identified operational expenses exceeding acceptable thresholds');
    sections.push('- ROI modeling suggests extended break-even timeline incompatible with priorities');
    sections.push('- Consider revisiting if market conditions change or costs decrease');
  } else if (reason === 'market_opportunity_insufficient') {
    sections.push('- Market research indicated limited demand or saturated competitive landscape');
    sections.push('- Customer validation did not support expected adoption rates');
    sections.push('- Monitor market trends; opportunity may emerge in future');
  } else if (reason === 'technical_complexity_high') {
    sections.push('- Technical feasibility assessment identified implementation challenges');
    sections.push('- Complexity-to-value ratio unfavorable given current team capacity');
    sections.push('- Consider alternative approaches or revisit with increased technical capability');
  } else {
    sections.push('- Systematic research and viability assessment completed');
    sections.push('- Decision documented with clear rationale for future reference');
    sections.push('- Prevents duplicate investigation of similar concepts');
  }

  sections.push('');
  sections.push('FUTURE CONSIDERATIONS:');
  sections.push('- Preserve this archive entry for reference during similar idea evaluations');
  sections.push('- Monitor for changed conditions that might alter viability assessment');
  sections.push('- Share learnings with team to inform future innovation prioritization');
  sections.push('');

  sections.push(`Category: ${ideaCategory}`);
  sections.push(`Viability Score: ${viabilityScore}/100`);
  sections.push(`Archived: ${new Date().toISOString().split('T')[0]}`);
  sections.push('');
  sections.push('🤖 Archived automatically by Innovation Platform with learnings preservation');

  return sections.join('\n');
}

/**
 * Build Archival Comment
 *
 * Constructs comment for original idea page documenting archival decision.
 *
 * @param {string} reason - Archive reason
 * @param {number} viabilityScore - Composite viability score
 * @param {object} researchSummary - Research findings
 * @param {string} knowledgeVaultId - Created Knowledge Vault entry ID
 * @returns {string} Formatted comment text
 */
function buildArchivalComment(reason, viabilityScore, researchSummary, knowledgeVaultId) {
  const sections = [];

  sections.push('📚 IDEA ARCHIVED WITH LEARNINGS');
  sections.push('');
  sections.push(`Viability Score: ${viabilityScore}/100`);
  sections.push(`Archive Reason: ${formatArchiveReason(reason, viabilityScore)}`);
  sections.push('');

  if (researchSummary) {
    sections.push('Research completed with findings:');
    sections.push(`  - Market: ${researchSummary.marketAnalysis?.score || 'N/A'}/100`);
    sections.push(`  - Technical: ${researchSummary.technicalFeasibility?.score || 'N/A'}/100`);
    sections.push(`  - Cost: ${researchSummary.costAnalysis?.score || 'N/A'}/100`);
    sections.push(`  - Risk: ${researchSummary.riskAssessment?.score || 'N/A'}/100`);
    sections.push('');
  }

  sections.push('Learnings documented in Knowledge Vault for future reference.');
  sections.push(`Knowledge Vault Entry: https://notion.so/${knowledgeVaultId}`);
  sections.push('');
  sections.push('This archive entry prevents duplicate investigation while preserving context.');
  sections.push('');
  sections.push(`🤖 Archived by Autonomous Platform at ${new Date().toISOString()}`);

  return sections.join('\n');
}
