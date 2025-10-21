/**
 * Create Research Entry Activity Function
 *
 * Establishes Research Hub entries linked to originating ideas with proper
 * structure for hypothesis, methodology, and findings documentation.
 *
 * This solution is designed to support structured feasibility investigations
 * where research threads maintain clear traceability to business objectives.
 *
 * Best for: Organizations requiring systematic research approaches with
 * documented hypotheses and methodologies that drive measurable outcomes.
 */

const NotionClient = require('../Shared/notionClient');

const RESEARCH_HUB_DATABASE_ID = process.env.NOTION_DATABASE_ID_RESEARCH || '91e8beff-af94-4614-90b9-3a6d3d788d4a';

/**
 * Main Activity Function
 *
 * @param {object} context - Durable Functions activity context
 * @returns {object} Created Research Hub page object
 */
module.exports = async function (context) {
  const input = context.bindings.context;
  const { ideaPageId, ideaData } = input;

  context.log('Creating Research Hub entry', {
    ideaPageId,
    ideaTitle: ideaData.properties.Title?.title?.[0]?.plain_text
  });

  try {
    const notionClient = new NotionClient(process.env.NOTION_API_KEY);

    // Extract idea details
    const ideaTitle = ideaData.properties.Title?.title?.[0]?.plain_text || 'Untitled Idea';
    const ideaDescription = ideaData.properties.Description?.rich_text?.[0]?.plain_text || '';
    const ideaCategory = ideaData.properties.Category?.select?.name || 'General';
    const ideaEffort = ideaData.properties.Effort?.select?.name || 'M';

    // Generate research title and hypothesis
    const researchTitle = `Research: ${ideaTitle}`;
    const hypothesis = generateHypothesis(ideaTitle, ideaDescription, ideaCategory);
    const methodology = generateMethodology(ideaCategory, ideaEffort);

    // Create Research Hub entry
    const researchPage = await notionClient.createPage({
      parent: { database_id: RESEARCH_HUB_DATABASE_ID },
      properties: {
        // Title (required)
        'Title': {
          title: [
            {
              text: { content: researchTitle }
            }
          ]
        },

        // Status
        'Status': {
          select: { name: 'Active' }
        },

        // Link to originating idea (relation)
        'Ideas': {
          relation: [
            { id: ideaPageId }
          ]
        },

        // Hypothesis
        'Hypothesis': {
          rich_text: [
            {
              text: { content: hypothesis }
            }
          ]
        },

        // Methodology
        'Methodology': {
          rich_text: [
            {
              text: { content: methodology }
            }
          ]
        },

        // Research Type
        'Research Type': {
          select: { name: determineResearchType(ideaCategory) }
        },

        // Automation Status
        'Automation Status': {
          select: { name: 'In Progress' }
        },

        // Automation Stage
        'Automation Stage': {
          rich_text: [
            {
              text: { content: 'Research Initialization' }
            }
          ]
        },

        // Research Progress %
        'Research Progress %': {
          number: 0
        },

        // Started Date
        'Started Date': {
          date: { start: new Date().toISOString().split('T')[0] }
        }
      }
    });

    context.log('Research Hub entry created successfully', {
      researchPageId: researchPage.id,
      linkedIdeaId: ideaPageId
    });

    return researchPage;

  } catch (error) {
    context.log.error('Failed to create Research Hub entry', {
      error: error.message,
      ideaPageId
    });
    throw error;
  }
};

/**
 * Generate Research Hypothesis
 *
 * Establishes clear success criteria and expected outcomes for investigation.
 *
 * @param {string} title - Idea title
 * @param {string} description - Idea description
 * @param {string} category - Idea category
 * @returns {string} Structured hypothesis statement
 */
function generateHypothesis(title, description, category) {
  const hypothesisTemplates = {
    'Internal Tool': `We hypothesize that ${title} will streamline key workflows and improve operational efficiency by addressing current manual processes or tooling gaps.`,
    'Customer Feature': `We hypothesize that ${title} will drive measurable customer value through enhanced functionality that addresses identified user needs.`,
    'Infrastructure': `We hypothesize that ${title} will establish scalable infrastructure that supports sustainable growth and reduces operational overhead.`,
    'Integration': `We hypothesize that ${title} will enable seamless data flow and process automation across systems, reducing manual intervention.`,
    'AI/ML': `We hypothesize that ${title} will leverage AI/ML capabilities to provide intelligent insights or automation that improves decision-making or efficiency.`,
    'Data & Analytics': `We hypothesize that ${title} will improve data visibility and analytical capabilities, enabling better business decisions.`
  };

  const baseHypothesis = hypothesisTemplates[category] || hypothesisTemplates['Internal Tool'];

  // Add description context if available
  if (description && description.length > 10) {
    return `${baseHypothesis}\n\nContext: ${description.substring(0, 200)}${description.length > 200 ? '...' : ''}`;
  }

  return baseHypothesis;
}

/**
 * Generate Research Methodology
 *
 * Establishes investigation approach based on category and effort level.
 *
 * @param {string} category - Idea category
 * @param {string} effort - Estimated effort (XS, S, M, L, XL)
 * @returns {string} Structured methodology description
 */
function generateMethodology(category, effort) {
  const effortLevel = ['XS', 'S'].includes(effort) ? 'rapid' : ['M'].includes(effort) ? 'standard' : 'comprehensive';

  const methodologyTemplates = {
    rapid: [
      '1. Literature Review: Review Microsoft documentation and existing solutions (1-2 hours)',
      '2. Technical Spike: Proof-of-concept code to validate approach (2-4 hours)',
      '3. Cost Estimation: Calculate Azure service costs and licensing requirements (1 hour)',
      '4. Risk Assessment: Identify technical and business risks (1 hour)',
      '5. Viability Determination: Go/No-Go decision with justification (1 hour)'
    ],
    standard: [
      '1. Market Research: Analyze competitive landscape and industry trends (4-8 hours)',
      '2. Technical Investigation: Evaluate technology stack options and architecture patterns (8-12 hours)',
      '3. Prototype Development: Build minimal proof-of-concept (8-16 hours)',
      '4. Cost-Benefit Analysis: Detailed financial modeling (4-6 hours)',
      '5. Risk & Security Review: Comprehensive risk assessment with mitigation strategies (4-6 hours)',
      '6. Stakeholder Validation: Present findings to decision makers (2-4 hours)'
    ],
    comprehensive: [
      '1. Discovery Phase: Stakeholder interviews and requirements gathering (1-2 weeks)',
      '2. Market Analysis: Competitive landscape, trends, and strategic positioning (1 week)',
      '3. Technical Deep Dive: Architecture design, technology evaluation, scalability assessment (2-3 weeks)',
      '4. Proof-of-Concept Build: Working prototype with core functionality (3-4 weeks)',
      '5. Financial Modeling: ROI analysis, total cost of ownership, break-even timeline (1 week)',
      '6. Risk Management: Comprehensive risk register with detailed mitigation plans (1 week)',
      '7. Security & Compliance Review: Security assessment, regulatory compliance check (1 week)',
      '8. Recommendation Report: Executive summary with go/no-go recommendation (3-5 days)'
    ]
  };

  return methodologyTemplates[effortLevel].join('\n');
}

/**
 * Determine Research Type
 *
 * Categorizes research based on idea category for appropriate investigation approach.
 *
 * @param {string} category - Idea category
 * @returns {string} Research type
 */
function determineResearchType(category) {
  const researchTypeMap = {
    'Internal Tool': 'Technical Spike',
    'Customer Feature': 'Market Research',
    'Infrastructure': 'Architecture Study',
    'Integration': 'Feasibility Study',
    'AI/ML': 'Technical Spike',
    'Data & Analytics': 'Architecture Study',
    'Process Improvement': 'Process Analysis',
    'Cost Optimization': 'Financial Analysis'
  };

  return researchTypeMap[category] || 'Feasibility Study';
}
