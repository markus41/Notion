/**
 * Validate Deployment Activity Function
 *
 * Establishes comprehensive health checks and validation for Azure deployments,
 * ensuring applications are operational before completion.
 *
 * This solution is designed to support sustainable deployment practices with
 * automated testing, health monitoring, and failure detection capabilities.
 *
 * Best for: Organizations requiring deployment verification workflows that
 * catch issues early and enable automatic remediation or rollback.
 */

const axios = require('axios');
const { exec } = require('child_process');
const { promisify } = require('util');
const execAsync = promisify(exec);

/**
 * Health Check Configuration
 *
 * Establishes validation thresholds and retry policies.
 */
const HEALTH_CHECK_CONFIG = {
  maxRetries: 5,
  retryDelay: 10000,      // 10 seconds
  healthTimeout: 30000,   // 30 seconds per check
  requiredSuccesses: 2    // Number of consecutive successes required
};

/**
 * Main Activity Function
 *
 * @param {object} context - Durable Functions activity context
 * @returns {object} Validation result with health status
 */
module.exports = async function (context) {
  const input = context.bindings.context;
  const { deployedResources, resourceGroupName } = input;

  context.log('Validating deployment', {
    resourceGroupName,
    resources: Object.keys(deployedResources)
  });

  try {
    const validationResults = {
      healthChecks: {},
      azureResourceValidation: {},
      performanceMetrics: {},
      overallStatus: 'pending'
    };

    // Step 1: Validate Azure resources are provisioned
    const resourceValidation = await validateAzureResources(
      resourceGroupName,
      deployedResources,
      context
    );
    validationResults.azureResourceValidation = resourceValidation;

    if (!resourceValidation.allResourcesReady) {
      return {
        success: false,
        error: 'Azure resources not fully provisioned',
        validationResults
      };
    }

    // Step 2: Health check endpoint validation
    const appUrl = deployedResources.appServiceUrl ||
                   deployedResources.functionAppUrl ||
                   deployedResources.containerAppUrl;

    if (appUrl) {
      const healthCheckResult = await performHealthChecks(appUrl, context);
      validationResults.healthChecks = healthCheckResult;

      if (!healthCheckResult.healthy) {
        return {
          success: false,
          error: 'Health checks failed',
          validationResults,
          requiresRemediation: true
        };
      }
    } else {
      context.log.warn('No application URL found - skipping health checks');
    }

    // Step 3: Performance baseline measurement
    if (appUrl) {
      const perfMetrics = await measurePerformanceBaseline(appUrl, context);
      validationResults.performanceMetrics = perfMetrics;
    }

    // Step 4: Application Insights validation
    if (deployedResources.appInsightsName) {
      const telemetryCheck = await validateApplicationInsights(
        resourceGroupName,
        deployedResources.appInsightsName,
        context
      );
      validationResults.telemetryValidation = telemetryCheck;
    }

    validationResults.overallStatus = 'healthy';

    context.log('Deployment validation complete - all checks passed', {
      healthStatus: validationResults.healthChecks?.status || 'N/A',
      responseTime: validationResults.performanceMetrics?.averageResponseTime || 'N/A'
    });

    return {
      success: true,
      validationResults,
      timestamp: new Date().toISOString()
    };

  } catch (error) {
    context.log.error('Deployment validation failed', {
      error: error.message,
      stack: error.stack
    });

    return {
      success: false,
      error: error.message,
      requiresRemediation: true
    };
  }
};

/**
 * Validate Azure Resources
 *
 * Verifies all deployed Azure resources are in succeeded provisioning state.
 *
 * @param {string} resourceGroupName - Resource group name
 * @param {object} deployedResources - Deployed resource details
 * @param {object} context - Function context
 * @returns {object} Resource validation results
 */
async function validateAzureResources(resourceGroupName, deployedResources, context) {
  const validation = {
    allResourcesReady: true,
    resourceStatuses: {}
  };

  try {
    // Get all resources in resource group
    const { stdout } = await execAsync(
      `az resource list --resource-group ${resourceGroupName} --query "[].{name:name, type:type, provisioningState:provisioningState}"`
    );

    const resources = JSON.parse(stdout);

    for (const resource of resources) {
      const isReady = resource.provisioningState === 'Succeeded';
      validation.resourceStatuses[resource.name] = {
        type: resource.type,
        state: resource.provisioningState,
        ready: isReady
      };

      if (!isReady) {
        validation.allResourcesReady = false;
        context.log.warn('Resource not ready', {
          name: resource.name,
          state: resource.provisioningState
        });
      }
    }

    context.log('Azure resource validation complete', {
      totalResources: resources.length,
      allReady: validation.allResourcesReady
    });

  } catch (error) {
    context.log.error('Failed to validate Azure resources', {
      error: error.message
    });
    validation.allResourcesReady = false;
    validation.error = error.message;
  }

  return validation;
}

/**
 * Perform Health Checks
 *
 * Executes HTTP health check requests with retry logic.
 *
 * @param {string} appUrl - Application URL
 * @param {object} context - Function context
 * @returns {object} Health check results
 */
async function performHealthChecks(appUrl, context) {
  const healthEndpoint = `${appUrl}/health`;
  const results = {
    healthy: false,
    endpoint: healthEndpoint,
    attempts: [],
    consecutiveSuccesses: 0
  };

  context.log('Starting health checks', {
    endpoint: healthEndpoint,
    maxRetries: HEALTH_CHECK_CONFIG.maxRetries
  });

  for (let attempt = 1; attempt <= HEALTH_CHECK_CONFIG.maxRetries; attempt++) {
    const attemptResult = await performSingleHealthCheck(healthEndpoint, attempt, context);
    results.attempts.push(attemptResult);

    if (attemptResult.success) {
      results.consecutiveSuccesses++;
      if (results.consecutiveSuccesses >= HEALTH_CHECK_CONFIG.requiredSuccesses) {
        results.healthy = true;
        results.status = 'healthy';
        context.log('Health checks passed', {
          successfulAttempts: results.consecutiveSuccesses,
          totalAttempts: attempt
        });
        break;
      }
    } else {
      results.consecutiveSuccesses = 0; // Reset counter on failure
    }

    // Wait before retry (except on last attempt)
    if (attempt < HEALTH_CHECK_CONFIG.maxRetries) {
      await sleep(HEALTH_CHECK_CONFIG.retryDelay);
    }
  }

  if (!results.healthy) {
    results.status = 'unhealthy';
    context.log.error('Health checks failed', {
      totalAttempts: results.attempts.length,
      lastError: results.attempts[results.attempts.length - 1].error
    });
  }

  return results;
}

/**
 * Perform Single Health Check
 *
 * Executes single HTTP health check request.
 *
 * @param {string} healthEndpoint - Health check URL
 * @param {number} attemptNumber - Attempt number
 * @param {object} context - Function context
 * @returns {object} Attempt result
 */
async function performSingleHealthCheck(healthEndpoint, attemptNumber, context) {
  const attemptResult = {
    attemptNumber,
    timestamp: new Date().toISOString(),
    success: false
  };

  try {
    const startTime = Date.now();
    const response = await axios.get(healthEndpoint, {
      timeout: HEALTH_CHECK_CONFIG.healthTimeout,
      validateStatus: (status) => status === 200
    });

    const responseTime = Date.now() - startTime;

    attemptResult.success = true;
    attemptResult.statusCode = response.status;
    attemptResult.responseTime = responseTime;
    attemptResult.responseBody = response.data;

    context.log(`Health check attempt ${attemptNumber} succeeded`, {
      responseTime: `${responseTime}ms`,
      status: response.status
    });

  } catch (error) {
    attemptResult.success = false;
    attemptResult.error = error.message;
    attemptResult.statusCode = error.response?.status;

    context.log.warn(`Health check attempt ${attemptNumber} failed`, {
      error: error.message,
      statusCode: error.response?.status
    });
  }

  return attemptResult;
}

/**
 * Measure Performance Baseline
 *
 * Establishes baseline performance metrics for deployed application.
 *
 * @param {string} appUrl - Application URL
 * @param {object} context - Function context
 * @returns {object} Performance metrics
 */
async function measurePerformanceBaseline(appUrl, context) {
  const metrics = {
    samples: [],
    averageResponseTime: 0,
    minResponseTime: Infinity,
    maxResponseTime: 0,
    successRate: 0
  };

  const sampleCount = 5;

  context.log('Measuring performance baseline', {
    endpoint: appUrl,
    samples: sampleCount
  });

  for (let i = 0; i < sampleCount; i++) {
    try {
      const startTime = Date.now();
      await axios.get(`${appUrl}/health`, { timeout: 10000 });
      const responseTime = Date.now() - startTime;

      metrics.samples.push({
        responseTime,
        success: true,
        timestamp: new Date().toISOString()
      });

      metrics.minResponseTime = Math.min(metrics.minResponseTime, responseTime);
      metrics.maxResponseTime = Math.max(metrics.maxResponseTime, responseTime);

      // Small delay between samples
      await sleep(1000);

    } catch (error) {
      metrics.samples.push({
        success: false,
        error: error.message
      });
    }
  }

  const successfulSamples = metrics.samples.filter(s => s.success);
  metrics.successRate = (successfulSamples.length / sampleCount) * 100;

  if (successfulSamples.length > 0) {
    const totalResponseTime = successfulSamples.reduce((sum, s) => sum + s.responseTime, 0);
    metrics.averageResponseTime = Math.round(totalResponseTime / successfulSamples.length);
  }

  context.log('Performance baseline measured', {
    averageResponseTime: `${metrics.averageResponseTime}ms`,
    successRate: `${metrics.successRate}%`
  });

  return metrics;
}

/**
 * Validate Application Insights
 *
 * Verifies telemetry is being collected by Application Insights.
 *
 * @param {string} resourceGroupName - Resource group name
 * @param {string} appInsightsName - Application Insights resource name
 * @param {object} context - Function context
 * @returns {object} Telemetry validation results
 */
async function validateApplicationInsights(resourceGroupName, appInsightsName, context) {
  const validation = {
    telemetryConfigured: false,
    instrumentationKeyPresent: false
  };

  try {
    const { stdout } = await execAsync(
      `az monitor app-insights component show --resource-group ${resourceGroupName} --app ${appInsightsName}`
    );

    const appInsights = JSON.parse(stdout);

    validation.telemetryConfigured = appInsights.provisioningState === 'Succeeded';
    validation.instrumentationKeyPresent = !!appInsights.instrumentationKey;

    context.log('Application Insights validation complete', {
      configured: validation.telemetryConfigured,
      instrumentationKey: validation.instrumentationKeyPresent ? 'present' : 'missing'
    });

  } catch (error) {
    context.log.warn('Failed to validate Application Insights', {
      error: error.message
    });
    validation.error = error.message;
  }

  return validation;
}

/**
 * Sleep Utility
 *
 * Delays execution for specified milliseconds.
 *
 * @param {number} ms - Milliseconds to sleep
 * @returns {Promise} Promise that resolves after delay
 */
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
