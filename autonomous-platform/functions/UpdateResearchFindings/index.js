/**
 * Update Research Findings Activity Function
 *
 * Establishes comprehensive documentation of research outcomes with structured
 * findings, viability assessments, and actionable next steps.
 *
 * This solution is designed to support knowledge capture from parallel research
 * agent execution, synthesizing multi-dimensional analysis into clear business decisions.
 *
 * Best for: Organizations requiring systematic research documentation that drives
 * measurable outcomes through evidence-based decision making.
 */

const NotionClient = require('../Shared/notionClient');

/**
 * Main Activity Function
 *
 * @param {object} context - Durable Functions activity context
 * @returns {object} Updated Research Hub page
 */
module.exports = async function (context) {
  const input = context.bindings.context;
  const {
    researchPageId,
    marketAnalysis,
    technicalFeasibility,
    costAnalysis,
    riskAssessment,
    viabilityScore,
    viabilityAssessment,
    nextSteps
  } = input;

  context.log('Updating Research Hub with findings', {
    researchPageId,
    viabilityScore,
    viabilityAssessment,
    nextSteps
  });

  try {
    const notionClient = new NotionClient(process.env.NOTION_API_KEY);

    // Construct comprehensive findings document
    const keyFindings = buildKeyFindings(
      marketAnalysis,
      technicalFeasibility,
      costAnalysis,
      riskAssessment
    );

    const recommendations = buildRecommendations(
      viabilityAssessment,
      nextSteps,
      marketAnalysis,
      technicalFeasibility,
      costAnalysis
    );

    // Update Research Hub entry with complete findings
    await notionClient.updatePage(researchPageId, {
      // Key Findings (rich text)
      'Key Findings': {
        rich_text: [
          {
            text: { content: keyFindings }
          }
        ]
      },

      // Viability Assessment
      'Viability Assessment': {
        select: { name: viabilityAssessment }
      },

      // Viability Score (if property exists)
      'Viability Score': {
        number: viabilityScore
      },

      // Next Steps
      'Next Steps': {
        select: { name: nextSteps }
      },

      // Recommendations (rich text)
      'Recommendations': {
        rich_text: [
          {
            text: { content: recommendations }
          }
        ]
      },

      // Individual scores (if properties exist)
      'Market Score': {
        number: marketAnalysis.score
      },

      'Technical Score': {
        number: technicalFeasibility.score
      },

      'Cost Score': {
        number: costAnalysis.score
      },

      'Risk Score': {
        number: riskAssessment.score
      },

      // Status
      'Status': {
        select: { name: 'Completed' }
      },

      // Completed Date
      'Completed Date': {
        date: { start: new Date().toISOString().split('T')[0] }
      }
    });

    // Add detailed findings as page comment for full context
    const detailedComment = buildDetailedComment(
      marketAnalysis,
      technicalFeasibility,
      costAnalysis,
      riskAssessment,
      viabilityScore
    );

    await notionClient.addComment(researchPageId, detailedComment);

    context.log('Research findings updated successfully', {
      researchPageId,
      viabilityScore,
      nextSteps
    });

    return { success: true, researchPageId, viabilityScore, nextSteps };

  } catch (error) {
    context.log.error('Failed to update research findings', {
      error: error.message,
      researchPageId
    });
    throw error;
  }
};

/**
 * Build Key Findings Summary
 *
 * Synthesizes multi-dimensional research results into executive summary.
 *
 * @param {object} marketAnalysis - Market research results
 * @param {object} technicalFeasibility - Technical analysis results
 * @param {object} costAnalysis - Cost analysis results
 * @param {object} riskAssessment - Risk assessment results
 * @returns {string} Structured key findings text
 */
function buildKeyFindings(marketAnalysis, technicalFeasibility, costAnalysis, riskAssessment) {
  const findings = [];

  // Market findings
  if (marketAnalysis.score >= 70) {
    findings.push(`✅ MARKET OPPORTUNITY: ${marketAnalysis.summary || 'Strong market potential identified'}`);
  } else if (marketAnalysis.score >= 50) {
    findings.push(`⚡ MARKET OPPORTUNITY: ${marketAnalysis.summary || 'Moderate market potential with conditions'}`);
  } else {
    findings.push(`⚠️ MARKET OPPORTUNITY: ${marketAnalysis.summary || 'Limited market opportunity identified'}`);
  }

  // Technical findings
  if (technicalFeasibility.score >= 70) {
    findings.push(`✅ TECHNICAL FEASIBILITY: ${technicalFeasibility.summary || 'Technically viable with Microsoft ecosystem'}`);
  } else if (technicalFeasibility.score >= 50) {
    findings.push(`⚡ TECHNICAL FEASIBILITY: ${technicalFeasibility.summary || 'Technically feasible with some complexity'}`);
  } else {
    findings.push(`⚠️ TECHNICAL FEASIBILITY: ${technicalFeasibility.summary || 'Significant technical challenges identified'}`);
  }

  // Cost findings
  const estimatedCost = costAnalysis.monthlyCost || costAnalysis.estimatedCost || 0;
  findings.push(`💰 COST: $${estimatedCost}/month estimated operational cost (Score: ${costAnalysis.score}/100)`);

  // Risk findings
  if (riskAssessment.score >= 70) {
    findings.push(`✅ RISK: ${riskAssessment.summary || 'Low risk with manageable mitigation strategies'}`);
  } else if (riskAssessment.score >= 50) {
    findings.push(`⚡ RISK: ${riskAssessment.summary || 'Moderate risk requiring active mitigation'}`);
  } else {
    findings.push(`⚠️ RISK: ${riskAssessment.summary || 'High risk requiring comprehensive mitigation plan'}`);
  }

  return findings.join('\n\n');
}

/**
 * Build Recommendations
 *
 * Establishes actionable next steps based on viability assessment and analysis results.
 *
 * @param {string} viabilityAssessment - Overall viability category
 * @param {string} nextSteps - Next step recommendation
 * @param {object} marketAnalysis - Market research results
 * @param {object} technicalFeasibility - Technical analysis results
 * @param {object} costAnalysis - Cost analysis results
 * @returns {string} Structured recommendations text
 */
function buildRecommendations(viabilityAssessment, nextSteps, marketAnalysis, technicalFeasibility, costAnalysis) {
  const recommendations = [];

  // Primary recommendation based on next steps
  if (nextSteps === 'Build Example') {
    recommendations.push('🚀 PRIMARY RECOMMENDATION: Proceed to prototype development');
    recommendations.push('');
    recommendations.push('RATIONALE:');
    recommendations.push(`- Viability Assessment: ${viabilityAssessment}`);
    recommendations.push(`- Market opportunity validated (Score: ${marketAnalysis.score}/100)`);
    recommendations.push(`- Technical approach confirmed (Score: ${technicalFeasibility.score}/100)`);
    recommendations.push(`- Cost within acceptable range ($${costAnalysis.monthlyCost || costAnalysis.estimatedCost || 0}/month)`);
    recommendations.push('');
    recommendations.push('NEXT ACTIONS:');
    recommendations.push('1. Create Example Build entry in Notion');
    recommendations.push('2. Initialize GitHub repository with architecture documentation');
    recommendations.push('3. Assign lead builder and core team');
    recommendations.push('4. Link required software/tools to build');
    recommendations.push('5. Deploy to Azure development environment');
  } else if (nextSteps === 'More Research') {
    recommendations.push('🔬 PRIMARY RECOMMENDATION: Continue investigation');
    recommendations.push('');
    recommendations.push('KNOWLEDGE GAPS IDENTIFIED:');
    if (marketAnalysis.score < 60) {
      recommendations.push('- Market opportunity requires deeper validation');
    }
    if (technicalFeasibility.score < 60) {
      recommendations.push('- Technical approach needs proof-of-concept validation');
    }
    if (costAnalysis.score < 60) {
      recommendations.push('- Cost-benefit analysis requires more detailed modeling');
    }
    recommendations.push('');
    recommendations.push('NEXT ACTIONS:');
    recommendations.push('1. Extend research timeline (2-4 weeks)');
    recommendations.push('2. Address specific knowledge gaps listed above');
    recommendations.push('3. Schedule follow-up decision point');
  } else if (nextSteps === 'Archive') {
    recommendations.push('📚 PRIMARY RECOMMENDATION: Archive with learnings');
    recommendations.push('');
    recommendations.push('ARCHIVE RATIONALE:');
    recommendations.push(`- Viability Assessment: ${viabilityAssessment}`);
    if (marketAnalysis.score < 50) {
      recommendations.push('- Insufficient market opportunity identified');
    }
    if (technicalFeasibility.score < 50) {
      recommendations.push('- Technical complexity exceeds expected benefits');
    }
    if (costAnalysis.monthlyCost > 1000) {
      recommendations.push('- Operational cost exceeds acceptable thresholds');
    }
    recommendations.push('');
    recommendations.push('NEXT ACTIONS:');
    recommendations.push('1. Update Idea status to Archived');
    recommendations.push('2. Create Knowledge Vault entry with learnings');
    recommendations.push('3. Document why idea was not pursued');
    recommendations.push('4. Identify any reusable insights for future work');
  }

  // Add agent-specific recommendations
  if (marketAnalysis.recommendations && marketAnalysis.recommendations.length > 0) {
    recommendations.push('');
    recommendations.push('MARKET INSIGHTS:');
    marketAnalysis.recommendations.forEach(rec => {
      recommendations.push(`- ${rec}`);
    });
  }

  if (technicalFeasibility.recommendations && technicalFeasibility.recommendations.length > 0) {
    recommendations.push('');
    recommendations.push('TECHNICAL CONSIDERATIONS:');
    technicalFeasibility.recommendations.forEach(rec => {
      recommendations.push(`- ${rec}`);
    });
  }

  return recommendations.join('\n');
}

/**
 * Build Detailed Comment
 *
 * Constructs comprehensive findings document for page comments with full agent results.
 *
 * @param {object} marketAnalysis - Market research results
 * @param {object} technicalFeasibility - Technical analysis results
 * @param {object} costAnalysis - Cost analysis results
 * @param {object} riskAssessment - Risk assessment results
 * @param {number} viabilityScore - Composite viability score
 * @returns {string} Detailed comment text
 */
function buildDetailedComment(marketAnalysis, technicalFeasibility, costAnalysis, riskAssessment, viabilityScore) {
  const sections = [];

  sections.push('=== RESEARCH SWARM COMPLETE ===');
  sections.push(`Composite Viability Score: ${viabilityScore}/100`);
  sections.push('');

  // Market Analysis
  sections.push('📊 MARKET RESEARCH (Weight: 30%)');
  sections.push(`Score: ${marketAnalysis.score}/100`);
  sections.push(`Summary: ${marketAnalysis.summary || 'See details'}`);
  if (marketAnalysis.details) {
    sections.push(`Details: ${marketAnalysis.details}`);
  }
  sections.push('');

  // Technical Feasibility
  sections.push('⚙️ TECHNICAL ANALYSIS (Weight: 25%)');
  sections.push(`Score: ${technicalFeasibility.score}/100`);
  sections.push(`Summary: ${technicalFeasibility.summary || 'See details'}`);
  if (technicalFeasibility.details) {
    sections.push(`Details: ${technicalFeasibility.details}`);
  }
  sections.push('');

  // Cost Analysis
  sections.push('💰 COST ANALYSIS (Weight: 25%)');
  sections.push(`Score: ${costAnalysis.score}/100`);
  sections.push(`Estimated Monthly Cost: $${costAnalysis.monthlyCost || costAnalysis.estimatedCost || 0}`);
  sections.push(`Summary: ${costAnalysis.summary || 'See details'}`);
  if (costAnalysis.details) {
    sections.push(`Details: ${costAnalysis.details}`);
  }
  sections.push('');

  // Risk Assessment
  sections.push('⚠️ RISK ASSESSMENT (Weight: 20%)');
  sections.push(`Score: ${riskAssessment.score}/100`);
  sections.push(`Summary: ${riskAssessment.summary || 'See details'}`);
  if (riskAssessment.risks && riskAssessment.risks.length > 0) {
    sections.push('Identified Risks:');
    riskAssessment.risks.forEach(risk => {
      sections.push(`  - ${risk}`);
    });
  }
  sections.push('');

  sections.push('🤖 Generated by Research Swarm (Parallel Agent Execution)');
  sections.push(`Timestamp: ${new Date().toISOString()}`);

  return sections.join('\n');
}
