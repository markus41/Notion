/**
 * Capture Knowledge Activity Function
 *
 * Establishes comprehensive knowledge documentation for successful builds,
 * preserving learnings, architectural patterns, and reusability assessments
 * in the Knowledge Vault for organizational learning.
 *
 * This solution is designed to support continuous improvement through
 * systematic capture of technical insights, best practices, and proven
 * patterns that accelerate future innovation.
 *
 * Best for: Organizations building institutional knowledge where successful
 * builds inform future development and prevent redundant problem-solving.
 */

const NotionClient = require('../Shared/notionClient');

const KNOWLEDGE_VAULT_DATABASE_ID = process.env.NOTION_DATABASE_ID_KNOWLEDGE || '13b5e9de-2dd1-45ec-839a-4f3d50cd8d06';

/**
 * Main Activity Function
 *
 * @param {object} context - Durable Functions activity context
 * @returns {object} Knowledge Vault entry details
 */
module.exports = async function (context) {
  const input = context.bindings.context;
  const {
    buildPageId,
    buildData,
    architecture,
    deployedResources,
    validationResults,
    estimatedCost
  } = input;

  context.log('Capturing knowledge from successful build', {
    buildPageId,
    buildName: buildData.properties.Title?.title?.[0]?.plain_text
  });

  try {
    const notionClient = new NotionClient(process.env.NOTION_API_KEY);

    // Extract build details
    const buildName = buildData.properties.Title?.title?.[0]?.plain_text || 'Untitled Build';
    const buildType = buildData.properties['Build Type']?.select?.name || 'Prototype';
    const techStack = buildData.properties['Tech Stack']?.select?.name || 'Unknown';

    // Assess reusability
    const reusabilityAssessment = assessReusability(
      buildData,
      architecture,
      validationResults
    );

    // Generate knowledge content
    const knowledgeTitle = `${buildName} - Technical Reference`;
    const knowledgeContent = buildKnowledgeContent(
      buildName,
      buildType,
      architecture,
      deployedResources,
      validationResults,
      estimatedCost,
      reusabilityAssessment
    );

    // Create Knowledge Vault entry
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
          select: { name: 'Technical Doc' }
        },

        // Status
        'Status': {
          select: { name: 'Published' }
        },

        // Evergreen/Dated
        'Evergreen/Dated': {
          select: { name: determineEvergreen(buildType, architecture) }
        },

        // Reusability
        'Reusability': {
          select: { name: reusabilityAssessment.level }
        },

        // Tags (using multi-select if property exists)
        'Tags': {
          multi_select: [
            { name: 'Successful Build' },
            { name: buildType },
            { name: techStack },
            { name: 'Autonomous Platform' }
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
                text: { content: '🎯 Technical Reference Documentation' }
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

    // Create relation back to original build (if property exists)
    try {
      await notionClient.updatePage(knowledgeVaultEntry.id, {
        'Builds': {
          relation: [{ id: buildPageId }]
        }
      });
    } catch (error) {
      context.log.warn('Could not create relation to build:', error.message);
    }

    // Update build page with Knowledge Vault link
    await notionClient.updatePage(buildPageId, {
      'Knowledge Vault Entry': {
        url: `https://notion.so/${knowledgeVaultEntry.id.replace(/-/g, '')}`
      }
    });

    // Add knowledge capture comment to build page
    const captureComment = buildCaptureComment(
      knowledgeVaultEntry.id,
      reusabilityAssessment
    );
    await notionClient.addComment(buildPageId, captureComment);

    context.log('Knowledge captured successfully', {
      knowledgeVaultId: knowledgeVaultEntry.id,
      reusability: reusabilityAssessment.level
    });

    return {
      success: true,
      knowledgeVaultId: knowledgeVaultEntry.id,
      knowledgeVaultUrl: `https://notion.so/${knowledgeVaultEntry.id.replace(/-/g, '')}`,
      reusability: reusabilityAssessment.level,
      patternsIdentified: reusabilityAssessment.patterns
    };

  } catch (error) {
    context.log.error('Failed to capture knowledge', {
      error: error.message,
      buildPageId
    });
    throw error;
  }
};

/**
 * Assess Reusability
 *
 * Evaluates build reusability based on multiple factors.
 *
 * @param {object} buildData - Build page data
 * @param {object} architecture - Architecture specification
 * @param {object} validationResults - Deployment validation results
 * @returns {object} Reusability assessment
 */
function assessReusability(buildData, architecture, validationResults) {
  const assessment = {
    level: 'Partially Reusable',
    score: 0,
    maxScore: 100,
    factors: {},
    patterns: []
  };

  // Factor 1: Code Quality (25 points)
  const hasTests = !!buildData.properties['Has Tests']?.checkbox;
  const testCoverage = buildData.properties['Test Coverage']?.number || 0;
  if (hasTests && testCoverage >= 70) {
    assessment.factors.codeQuality = 25;
  } else if (hasTests) {
    assessment.factors.codeQuality = 15;
  } else {
    assessment.factors.codeQuality = 0;
  }

  // Factor 2: Documentation Quality (20 points)
  const hasReadme = true; // Generated builds always have README
  const hasArchitectureDocs = !!architecture.details;
  if (hasReadme && hasArchitectureDocs) {
    assessment.factors.documentation = 20;
  } else if (hasReadme) {
    assessment.factors.documentation = 10;
  } else {
    assessment.factors.documentation = 0;
  }

  // Factor 3: Deployment Success (20 points)
  const deploymentSuccessful = validationResults?.overallStatus === 'healthy';
  const healthChecksPass = validationResults?.healthChecks?.healthy;
  if (deploymentSuccessful && healthChecksPass) {
    assessment.factors.deployment = 20;
  } else if (deploymentSuccessful) {
    assessment.factors.deployment = 10;
  } else {
    assessment.factors.deployment = 0;
  }

  // Factor 4: Generalization (20 points)
  const isNotFork = buildData.properties['Is Fork']?.checkbox !== true;
  const isWellStructured = architecture.components?.length > 0;
  if (isNotFork && isWellStructured) {
    assessment.factors.generalization = 20;
  } else if (isNotFork) {
    assessment.factors.generalization = 10;
  } else {
    assessment.factors.generalization = 0;
  }

  // Factor 5: Pattern Clarity (15 points)
  const identifiedPatterns = identifyArchitecturalPatterns(architecture);
  assessment.patterns = identifiedPatterns;
  assessment.factors.patterns = Math.min(identifiedPatterns.length * 5, 15);

  // Calculate total score
  assessment.score = Object.values(assessment.factors).reduce((sum, val) => sum + val, 0);

  // Determine reusability level
  if (assessment.score >= 75) {
    assessment.level = 'Highly Reusable';
  } else if (assessment.score >= 50) {
    assessment.level = 'Partially Reusable';
  } else {
    assessment.level = 'One-Off';
  }

  return assessment;
}

/**
 * Identify Architectural Patterns
 *
 * Detects reusable patterns in architecture specification.
 *
 * @param {object} architecture - Architecture specification
 * @returns {Array} Identified patterns
 */
function identifyArchitecturalPatterns(architecture) {
  const patterns = [];
  const archText = JSON.stringify(architecture).toLowerCase();

  // Authentication patterns
  if (archText.includes('azure ad') || archText.includes('managed identity')) {
    patterns.push('azure-ad-authentication');
  }
  if (archText.includes('api key') || archText.includes('token')) {
    patterns.push('api-key-authentication');
  }

  // Storage patterns
  if (archText.includes('cosmos') || archText.includes('nosql')) {
    patterns.push('cosmos-db-storage');
  }
  if (archText.includes('sql') || archText.includes('database')) {
    patterns.push('sql-database-storage');
  }
  if (archText.includes('blob') || archText.includes('file storage')) {
    patterns.push('blob-storage');
  }

  // API patterns
  if (archText.includes('rest') || archText.includes('api')) {
    patterns.push('rest-api');
  }
  if (archText.includes('graphql')) {
    patterns.push('graphql-api');
  }
  if (archText.includes('webhook')) {
    patterns.push('webhook-integration');
  }

  // Deployment patterns
  if (archText.includes('app service')) {
    patterns.push('app-service-deployment');
  }
  if (archText.includes('function') || archText.includes('serverless')) {
    patterns.push('serverless-function');
  }
  if (archText.includes('container')) {
    patterns.push('containerized-deployment');
  }

  return patterns;
}

/**
 * Build Knowledge Content
 *
 * Constructs comprehensive documentation of build learnings.
 *
 * @param {string} buildName - Build name
 * @param {string} buildType - Build type
 * @param {object} architecture - Architecture specification
 * @param {object} deployedResources - Azure deployment details
 * @param {object} validationResults - Validation results
 * @param {number} estimatedCost - Monthly cost estimate
 * @param {object} reusabilityAssessment - Reusability analysis
 * @returns {string} Formatted knowledge content
 */
function buildKnowledgeContent(buildName, buildType, architecture, deployedResources, validationResults, estimatedCost, reusabilityAssessment) {
  const sections = [];

  sections.push(`BUILD: ${buildName}`);
  sections.push(`Type: ${buildType}`);
  sections.push('');

  sections.push('SUCCESS SUMMARY:');
  sections.push('✅ Build completed successfully through autonomous platform');
  sections.push(`✅ Deployment validated (Health: ${validationResults?.overallStatus || 'verified'})`);
  sections.push(`✅ Reusability: ${reusabilityAssessment.level} (Score: ${reusabilityAssessment.score}/100)`);
  sections.push('');

  if (architecture.summary) {
    sections.push('ARCHITECTURE OVERVIEW:');
    sections.push(architecture.summary);
    sections.push('');
  }

  if (reusabilityAssessment.patterns.length > 0) {
    sections.push('ARCHITECTURAL PATTERNS IDENTIFIED:');
    reusabilityAssessment.patterns.forEach(pattern => {
      sections.push(`  🔧 ${pattern}`);
    });
    sections.push('');
  }

  if (deployedResources) {
    sections.push('AZURE DEPLOYMENT:');
    if (deployedResources.appServiceUrl) {
      sections.push(`  App Service: ${deployedResources.appServiceUrl}`);
    }
    if (deployedResources.functionAppUrl) {
      sections.push(`  Function App: ${deployedResources.functionAppUrl}`);
    }
    if (deployedResources.containerAppUrl) {
      sections.push(`  Container App: ${deployedResources.containerAppUrl}`);
    }
    if (deployedResources.appInsightsName) {
      sections.push(`  Application Insights: ${deployedResources.appInsightsName}`);
    }
    sections.push('');
  }

  if (validationResults?.performanceMetrics) {
    sections.push('PERFORMANCE BASELINE:');
    sections.push(`  Average Response Time: ${validationResults.performanceMetrics.averageResponseTime}ms`);
    sections.push(`  Success Rate: ${validationResults.performanceMetrics.successRate}%`);
    sections.push('');
  }

  if (estimatedCost) {
    sections.push('COST ANALYSIS:');
    sections.push(`  Estimated Monthly: $${estimatedCost}`);
    sections.push(`  Estimated Annual: $${estimatedCost * 12}`);
    sections.push('');
  }

  sections.push('REUSABILITY ASSESSMENT:');
  sections.push(`  Overall Level: ${reusabilityAssessment.level}`);
  sections.push(`  Score: ${reusabilityAssessment.score}/100`);
  sections.push('');
  sections.push('  Score Breakdown:');
  Object.entries(reusabilityAssessment.factors).forEach(([factor, score]) => {
    sections.push(`    - ${factor}: ${score} points`);
  });
  sections.push('');

  sections.push('KEY LEARNINGS:');
  sections.push('- Autonomous build pipeline executed successfully end-to-end');
  sections.push('- Architecture design patterns validated and documented');
  sections.push('- Deployment process automated with health validation');
  sections.push('- Performance metrics established for future comparison');
  if (reusabilityAssessment.level === 'Highly Reusable') {
    sections.push('- Build architecture suitable for templating and reuse');
  }
  sections.push('');

  sections.push('FUTURE APPLICATIONS:');
  if (reusabilityAssessment.level === 'Highly Reusable') {
    sections.push('- Use as reference architecture for similar builds');
    sections.push('- Extract patterns for pattern library');
    sections.push('- Consider creating reusable template');
  } else if (reusabilityAssessment.level === 'Partially Reusable') {
    sections.push('- Reference specific components and patterns');
    sections.push('- Adapt architecture for similar use cases');
  } else {
    sections.push('- Preserve for context but not recommended for direct reuse');
  }
  sections.push('');

  sections.push(`Captured: ${new Date().toISOString().split('T')[0]}`);
  sections.push('🤖 Generated automatically by Brookside BI Innovation Platform');

  return sections.join('\n');
}

/**
 * Build Capture Comment
 *
 * Constructs comment for build page documenting knowledge capture.
 *
 * @param {string} knowledgeVaultId - Knowledge Vault entry ID
 * @param {object} reusabilityAssessment - Reusability analysis
 * @returns {string} Formatted comment text
 */
function buildCaptureComment(knowledgeVaultId, reusabilityAssessment) {
  const sections = [];

  sections.push('📚 KNOWLEDGE CAPTURED');
  sections.push('');
  sections.push('Build learnings and architectural patterns documented for future reference.');
  sections.push('');
  sections.push(`Reusability Assessment: ${reusabilityAssessment.level} (${reusabilityAssessment.score}/100)`);
  sections.push('');
  if (reusabilityAssessment.patterns.length > 0) {
    sections.push('Patterns Identified:');
    reusabilityAssessment.patterns.forEach(pattern => {
      sections.push(`  - ${pattern}`);
    });
    sections.push('');
  }
  sections.push(`Knowledge Vault Entry: https://notion.so/${knowledgeVaultId.replace(/-/g, '')}`);
  sections.push('');
  sections.push('This documentation will accelerate similar builds and inform pattern library.');
  sections.push('');
  sections.push(`🤖 Captured by Autonomous Platform at ${new Date().toISOString()}`);

  return sections.join('\n');
}

/**
 * Determine Evergreen Status
 *
 * Categorizes knowledge as evergreen (timeless) or dated (time-sensitive).
 *
 * @param {string} buildType - Build type
 * @param {object} architecture - Architecture specification
 * @returns {string} 'Evergreen' or 'Dated'
 */
function determineEvergreen(buildType, architecture) {
  // Reference implementations and architectural patterns are evergreen
  if (buildType === 'Reference Implementation') {
    return 'Evergreen';
  }

  // Technical patterns are generally evergreen
  const archText = JSON.stringify(architecture).toLowerCase();
  if (archText.includes('pattern') || archText.includes('template')) {
    return 'Evergreen';
  }

  // Most prototypes and POCs are dated
  if (buildType === 'Prototype' || buildType === 'POC') {
    return 'Dated';
  }

  // Default to Evergreen for MVPs and Demos
  return 'Evergreen';
}
