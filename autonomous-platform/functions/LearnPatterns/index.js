/**
 * Learn Patterns Activity Function
 *
 * Establishes pattern extraction and learning from successful builds, continuously
 * improving the platform's ability to generate architecture through pattern recognition.
 *
 * This solution is designed to support machine learning-style pattern evolution where
 * successful architectures inform future recommendations through similarity matching
 * and usage tracking.
 *
 * Best for: Organizations seeking to accelerate development through accumulated
 * architectural knowledge that improves recommendation quality over time.
 */

const { CosmosClient } = require('@azure/cosmos');

/**
 * Cosmos DB Configuration
 */
const COSMOS_ENDPOINT = process.env.COSMOS_ENDPOINT || '';
const COSMOS_KEY = process.env.COSMOS_KEY || '';
const DATABASE_ID = 'InnovationPlatform';
const CONTAINER_ID = 'Patterns';

/**
 * Main Activity Function
 *
 * @param {object} context - Durable Functions activity context
 * @returns {object} Pattern learning results
 */
module.exports = async function (context) {
  const input = context.bindings.context;
  const {
    buildName,
    architecture,
    deployedResources,
    validationResults,
    capturedPatterns
  } = input;

  context.log('Learning patterns from successful build', {
    buildName,
    capturedPatterns: capturedPatterns?.length || 0
  });

  try {
    // Initialize Cosmos DB client
    if (!COSMOS_ENDPOINT || !COSMOS_KEY) {
      context.log.warn('Cosmos DB not configured - skipping pattern learning');
      return {
        success: true,
        message: 'Cosmos DB not configured - patterns not persisted',
        patternsIdentified: capturedPatterns || []
      };
    }

    const cosmosClient = new CosmosClient({
      endpoint: COSMOS_ENDPOINT,
      key: COSMOS_KEY
    });

    const database = cosmosClient.database(DATABASE_ID);
    const container = database.container(CONTAINER_ID);

    const learningResults = {
      patternsCreated: 0,
      patternsUpdated: 0,
      patterns: []
    };

    // Process each captured pattern
    for (const patternName of (capturedPatterns || [])) {
      const patternResult = await processPattern(
        container,
        patternName,
        buildName,
        architecture,
        deployedResources,
        validationResults,
        context
      );

      learningResults.patterns.push(patternResult);

      if (patternResult.created) {
        learningResults.patternsCreated++;
      } else if (patternResult.updated) {
        learningResults.patternsUpdated++;
      }
    }

    // Extract and learn composite patterns (combinations)
    const compositePatterns = identifyCompositePatterns(capturedPatterns, architecture);
    for (const compositePattern of compositePatterns) {
      const patternResult = await processPattern(
        container,
        compositePattern.name,
        buildName,
        architecture,
        deployedResources,
        validationResults,
        context,
        compositePattern.components
      );

      learningResults.patterns.push(patternResult);

      if (patternResult.created) {
        learningResults.patternsCreated++;
      } else if (patternResult.updated) {
        learningResults.patternsUpdated++;
      }
    }

    context.log('Pattern learning complete', {
      patternsCreated: learningResults.patternsCreated,
      patternsUpdated: learningResults.patternsUpdated,
      totalPatterns: learningResults.patterns.length
    });

    return {
      success: true,
      ...learningResults
    };

  } catch (error) {
    context.log.error('Pattern learning failed', {
      error: error.message,
      stack: error.stack
    });

    return {
      success: false,
      error: error.message
    };
  }
};

/**
 * Process Pattern
 *
 * Creates or updates pattern entry in Cosmos DB with usage tracking.
 *
 * @param {Container} container - Cosmos DB container
 * @param {string} patternName - Pattern identifier
 * @param {string} buildName - Build name
 * @param {object} architecture - Architecture specification
 * @param {object} deployedResources - Deployment details
 * @param {object} validationResults - Validation results
 * @param {object} context - Function context
 * @param {Array} components - Sub-pattern components (for composite patterns)
 * @returns {object} Pattern processing result
 */
async function processPattern(container, patternName, buildName, architecture, deployedResources, validationResults, context, components = null) {
  try {
    // Check if pattern exists
    const patternId = patternName.toLowerCase().replace(/[^a-z0-9-]/g, '-');
    const { resource: existingPattern } = await container.item(patternId, patternId).read();

    if (existingPattern) {
      // Update existing pattern
      const updatedPattern = await updateExistingPattern(
        container,
        existingPattern,
        buildName,
        validationResults,
        context
      );

      return {
        patternName,
        patternId,
        updated: true,
        created: false,
        usageCount: updatedPattern.usageCount,
        successRate: updatedPattern.successRate
      };

    } else {
      // Create new pattern
      const newPattern = await createNewPattern(
        container,
        patternId,
        patternName,
        buildName,
        architecture,
        deployedResources,
        validationResults,
        components,
        context
      );

      return {
        patternName,
        patternId,
        created: true,
        updated: false,
        usageCount: newPattern.usageCount,
        successRate: newPattern.successRate
      };
    }

  } catch (error) {
    if (error.code === 404) {
      // Pattern doesn't exist - create it
      const newPattern = await createNewPattern(
        container,
        patternId,
        patternName,
        buildName,
        architecture,
        deployedResources,
        validationResults,
        components,
        context
      );

      return {
        patternName,
        patternId,
        created: true,
        updated: false,
        usageCount: newPattern.usageCount,
        successRate: newPattern.successRate
      };
    }

    throw error;
  }
}

/**
 * Create New Pattern
 *
 * Establishes new pattern entry in Cosmos DB with initial metadata.
 *
 * @param {Container} container - Cosmos DB container
 * @param {string} patternId - Pattern unique identifier
 * @param {string} patternName - Human-readable pattern name
 * @param {string} buildName - Build name
 * @param {object} architecture - Architecture specification
 * @param {object} deployedResources - Deployment details
 * @param {object} validationResults - Validation results
 * @param {Array} components - Sub-pattern components
 * @param {object} context - Function context
 * @returns {object} Created pattern document
 */
async function createNewPattern(container, patternId, patternName, buildName, architecture, deployedResources, validationResults, components, context) {
  const pattern = {
    id: patternId,
    patternName,
    type: components ? 'composite' : 'atomic',
    components: components || [],
    usageCount: 1,
    successCount: validationResults?.overallStatus === 'healthy' ? 1 : 0,
    successRate: validationResults?.overallStatus === 'healthy' ? 100 : 0,
    tags: extractPatternTags(patternName, architecture),
    implementations: [
      {
        buildName,
        timestamp: new Date().toISOString(),
        successful: validationResults?.overallStatus === 'healthy',
        performanceMetrics: validationResults?.performanceMetrics || {},
        deploymentType: deployedResources?.appServiceName ? 'app-service' :
                       deployedResources?.functionAppName ? 'function-app' :
                       deployedResources?.containerAppName ? 'container-app' : 'unknown'
      }
    ],
    specification: extractPatternSpecification(patternName, architecture),
    created: new Date().toISOString(),
    lastUpdated: new Date().toISOString()
  };

  const { resource: createdPattern } = await container.items.create(pattern);

  context.log('New pattern created', {
    patternId,
    patternName,
    type: pattern.type
  });

  return createdPattern;
}

/**
 * Update Existing Pattern
 *
 * Increments usage counters and adds new implementation example.
 *
 * @param {Container} container - Cosmos DB container
 * @param {object} existingPattern - Existing pattern document
 * @param {string} buildName - Build name
 * @param {object} validationResults - Validation results
 * @param {object} context - Function context
 * @returns {object} Updated pattern document
 */
async function updateExistingPattern(container, existingPattern, buildName, validationResults, context) {
  const successful = validationResults?.overallStatus === 'healthy';

  // Update counters
  existingPattern.usageCount++;
  if (successful) {
    existingPattern.successCount = (existingPattern.successCount || 0) + 1;
  }
  existingPattern.successRate = Math.round(
    ((existingPattern.successCount || 0) / existingPattern.usageCount) * 100
  );

  // Add implementation example
  existingPattern.implementations = existingPattern.implementations || [];
  existingPattern.implementations.push({
    buildName,
    timestamp: new Date().toISOString(),
    successful,
    performanceMetrics: validationResults?.performanceMetrics || {}
  });

  // Keep only last 10 implementations
  if (existingPattern.implementations.length > 10) {
    existingPattern.implementations = existingPattern.implementations.slice(-10);
  }

  existingPattern.lastUpdated = new Date().toISOString();

  const { resource: updatedPattern } = await container
    .item(existingPattern.id, existingPattern.id)
    .replace(existingPattern);

  context.log('Pattern updated', {
    patternId: existingPattern.id,
    usageCount: updatedPattern.usageCount,
    successRate: `${updatedPattern.successRate}%`
  });

  return updatedPattern;
}

/**
 * Identify Composite Patterns
 *
 * Detects meaningful combinations of atomic patterns.
 *
 * @param {Array} atomicPatterns - List of atomic patterns
 * @param {object} architecture - Architecture specification
 * @returns {Array} Composite pattern definitions
 */
function identifyCompositePatterns(atomicPatterns, architecture) {
  const compositePatterns = [];

  if (!atomicPatterns || atomicPatterns.length < 2) {
    return compositePatterns;
  }

  // Common composite pattern: Azure AD + Storage
  if (atomicPatterns.includes('azure-ad-authentication') &&
      (atomicPatterns.includes('cosmos-db-storage') || atomicPatterns.includes('sql-database-storage') || atomicPatterns.includes('blob-storage'))) {
    const storagePattern = atomicPatterns.find(p => p.includes('storage'));
    compositePatterns.push({
      name: `secure-${storagePattern}`,
      components: ['azure-ad-authentication', storagePattern]
    });
  }

  // Common composite pattern: REST API + Authentication
  if (atomicPatterns.includes('rest-api') &&
      (atomicPatterns.includes('azure-ad-authentication') || atomicPatterns.includes('api-key-authentication'))) {
    const authPattern = atomicPatterns.find(p => p.includes('authentication'));
    compositePatterns.push({
      name: `authenticated-rest-api`,
      components: ['rest-api', authPattern]
    });
  }

  // Common composite pattern: Serverless + Storage
  if (atomicPatterns.includes('serverless-function') &&
      (atomicPatterns.includes('cosmos-db-storage') || atomicPatterns.includes('blob-storage'))) {
    const storagePattern = atomicPatterns.find(p => p.includes('storage'));
    compositePatterns.push({
      name: `serverless-data-processing`,
      components: ['serverless-function', storagePattern]
    });
  }

  // Common composite pattern: Container + Database
  if (atomicPatterns.includes('containerized-deployment') &&
      (atomicPatterns.includes('cosmos-db-storage') || atomicPatterns.includes('sql-database-storage'))) {
    const dbPattern = atomicPatterns.find(p => p.includes('storage') || p.includes('database'));
    compositePatterns.push({
      name: `containerized-data-app`,
      components: ['containerized-deployment', dbPattern]
    });
  }

  return compositePatterns;
}

/**
 * Extract Pattern Tags
 *
 * Generates searchable tags for pattern categorization.
 *
 * @param {string} patternName - Pattern name
 * @param {object} architecture - Architecture specification
 * @returns {Array} Pattern tags
 */
function extractPatternTags(patternName, architecture) {
  const tags = [];

  // Category tags
  if (patternName.includes('authentication') || patternName.includes('auth')) {
    tags.push('security', 'authentication');
  }
  if (patternName.includes('storage') || patternName.includes('database')) {
    tags.push('data', 'storage');
  }
  if (patternName.includes('api')) {
    tags.push('integration', 'api');
  }
  if (patternName.includes('serverless') || patternName.includes('function')) {
    tags.push('compute', 'serverless');
  }
  if (patternName.includes('container')) {
    tags.push('compute', 'container');
  }

  // Technology tags
  if (patternName.includes('azure')) {
    tags.push('azure', 'microsoft');
  }
  if (patternName.includes('cosmos')) {
    tags.push('cosmosdb', 'nosql');
  }
  if (patternName.includes('sql')) {
    tags.push('sql', 'relational');
  }

  // Architecture tags from specification
  const archText = JSON.stringify(architecture).toLowerCase();
  if (archText.includes('microservice')) {
    tags.push('microservices');
  }
  if (archText.includes('event')) {
    tags.push('event-driven');
  }

  return [...new Set(tags)]; // Remove duplicates
}

/**
 * Extract Pattern Specification
 *
 * Generates reusable specification template for pattern.
 *
 * @param {string} patternName - Pattern name
 * @param {object} architecture - Architecture specification
 * @returns {object} Pattern specification
 */
function extractPatternSpecification(patternName, architecture) {
  const specification = {
    name: patternName,
    description: `Pattern extracted from successful build architecture`,
    recommendedFor: [],
    configuration: {},
    benefits: [],
    considerations: []
  };

  // Pattern-specific recommendations
  if (patternName.includes('azure-ad')) {
    specification.recommendedFor.push('Enterprise applications requiring SSO');
    specification.benefits.push('Centralized identity management');
    specification.benefits.push('Integrated with Microsoft 365');
    specification.considerations.push('Requires Azure AD tenant');
  }

  if (patternName.includes('cosmos-db')) {
    specification.recommendedFor.push('Globally distributed applications');
    specification.recommendedFor.push('High-throughput workloads');
    specification.benefits.push('Multi-region replication');
    specification.benefits.push('Serverless option available');
    specification.considerations.push('Cost scales with throughput');
  }

  if (patternName.includes('serverless')) {
    specification.recommendedFor.push('Variable workload patterns');
    specification.recommendedFor.push('Event-driven architectures');
    specification.benefits.push('Pay-per-execution pricing');
    specification.benefits.push('Auto-scaling included');
    specification.considerations.push('Cold start latency');
  }

  return specification;
}
