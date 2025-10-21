/**
 * Build Pipeline Orchestrator (Durable Function)
 *
 * Establishes end-to-end autonomous build workflow from idea to production deployment.
 * Coordinates 5 sequential stages with pattern-based architecture generation.
 *
 * Workflow Stages:
 * 1. Architecture Generation (pattern-based)
 * 2. Code Generation & GitHub Setup
 * 3. Azure Infrastructure Deployment
 * 4. Health Validation & Testing
 * 5. Knowledge Capture & Pattern Learning
 *
 * Best for: Fully autonomous builds with high risk tolerance, not customer-facing
 */

const df = require("durable-functions");

module.exports = df.orchestrator(function* (context) {
  const input = context.df.getInput();
  const { pageId, databaseType, triggerName } = input;

  context.log(`Build Pipeline started for page: ${pageId}`);

  try {
    // ========================================================================
    // STAGE 1: ARCHITECTURE GENERATION (5-15 minutes)
    // ========================================================================
    yield context.df.callActivity('UpdateNotionStatus', {
      pageId,
      databaseType: 'builds',
      properties: {
        'Automation Status': 'In Progress',
        'Automation Stage': 'Architecture Generation',
        'Build Stage': 'Planning'
      }
    });

    const architectureInput = {
      pageId,
      task: 'Generate system architecture using learned patterns',
      agent: 'build-architect',
      includePatternMatching: true
    };

    const architecture = yield context.df.callActivity(
      'InvokeClaudeAgent',
      architectureInput
    );

    context.log('Architecture generated', {
      techStack: architecture.techStack,
      estimatedCost: architecture.estimatedCost
    });

    // Check cost threshold
    if (architecture.estimatedCost > 500) {
      yield context.df.callActivity('EscalateToHuman', {
        pageId,
        reason: 'cost_threshold_exceeded',
        details: {
          estimatedCost: architecture.estimatedCost,
          threshold: 500
        }
      });
      return { status: 'requires_review', reason: 'Cost exceeds $500/month' };
    }

    // ========================================================================
    // STAGE 2: CODE GENERATION & GITHUB SETUP (10-30 minutes)
    // ========================================================================
    yield context.df.callActivity('UpdateNotionStatus', {
      pageId,
      databaseType: 'builds',
      properties: {
        'Automation Stage': 'Code Generation',
        'Build Stage': 'Development'
      }
    });

    const codeGenInput = {
      architecture,
      task: 'Generate complete codebase with tests and CI/CD',
      agent: 'build-architect'
    };

    const codebase = yield context.df.callActivity(
      'GenerateCodebase',
      codeGenInput
    );

    context.log('Codebase generated', {
      fileCount: codebase.files.length,
      hasTests: codebase.hasTests
    });

    // Create GitHub repository
    const repoInput = {
      name: codebase.projectName,
      description: codebase.description,
      files: codebase.files,
      isPrivate: false // Internal learning builds are public
    };

    const githubRepo = yield context.df.callActivity(
      'CreateGitHubRepository',
      repoInput
    );

    yield context.df.callActivity('UpdateNotionStatus', {
      pageId,
      databaseType: 'builds',
      properties: {
        'GitHub Repo': githubRepo.url,
        'Repository Name': githubRepo.name
      }
    });

    context.log('GitHub repository created', {
      url: githubRepo.url,
      name: githubRepo.name
    });

    // ========================================================================
    // STAGE 3: AZURE DEPLOYMENT (15-45 minutes)
    // ========================================================================
    yield context.df.callActivity('UpdateNotionStatus', {
      pageId,
      databaseType: 'builds',
      properties: {
        'Automation Stage': 'Azure Deployment',
        'Build Stage': 'Deployment'
      }
    });

    const deploymentInput = {
      architecture,
      githubRepo,
      resourcePrefix: `build-${pageId.slice(0, 8)}`,
      environment: 'dev'
    };

    const deployment = yield context.df.callActivity(
      'DeployToAzure',
      deploymentInput
    );

    yield context.df.callActivity('UpdateNotionStatus', {
      pageId,
      databaseType: 'builds',
      properties: {
        'Live URL': deployment.appUrl,
        'Azure Resource Group': deployment.resourceGroupName,
        'Monthly Cost': deployment.actualMonthlyCost
      }
    });

    context.log('Azure deployment complete', {
      appUrl: deployment.appUrl,
      resourceGroup: deployment.resourceGroupName
    });

    // ========================================================================
    // STAGE 4: HEALTH VALIDATION (5-10 minutes)
    // ========================================================================
    yield context.df.callActivity('UpdateNotionStatus', {
      pageId,
      databaseType: 'builds',
      properties: {
        'Automation Stage': 'Health Validation',
        'Build Stage': 'Testing'
      }
    });

    const healthCheckInput = {
      appUrl: deployment.appUrl,
      githubRepo: githubRepo.url,
      runTests: codebase.hasTests
    };

    const healthCheck = yield context.df.callActivity(
      'ValidateDeployment',
      healthCheckInput
    );

    context.log('Health check complete', {
      status: healthCheck.status,
      testsPassed: healthCheck.testsPassed,
      failureCount: healthCheck.failures.length
    });

    if (healthCheck.status !== 'healthy') {
      // Attempt auto-remediation
      const remediationResult = yield context.df.callActivity(
        'AttemptRemediation',
        {
          deployment,
          healthCheck,
          maxRetries: 2
        }
      );

      if (!remediationResult.success) {
        yield context.df.callActivity('EscalateToHuman', {
          pageId,
          reason: 'deployment_health_check_failed',
          details: {
            failures: healthCheck.failures,
            remediationAttempts: remediationResult.attempts
          }
        });

        yield context.df.callActivity('UpdateNotionStatus', {
          pageId,
          databaseType: 'builds',
          properties: {
            'Automation Status': 'Requires Review',
            'Build Stage': 'Failed',
            'Deployment Health': 'Failing'
          }
        });

        return {
          status: 'failed',
          reason: 'Health check failed after remediation attempts'
        };
      }
    }

    // Mark build as Live
    yield context.df.callActivity('UpdateNotionStatus', {
      pageId,
      databaseType: 'builds',
      properties: {
        'Automation Stage': 'Knowledge Capture',
        'Build Stage': 'Live',
        'Deployment Health': 'Healthy',
        'Status': 'Completed'
      }
    });

    // ========================================================================
    // STAGE 5: KNOWLEDGE CAPTURE & PATTERN LEARNING (10-20 minutes)
    // ========================================================================
    const knowledgeInput = {
      pageId,
      architecture,
      deployment,
      healthCheck,
      task: 'Extract learnings and create Knowledge Vault entry'
    };

    const knowledgeVaultEntry = yield context.df.callActivity(
      'CaptureKnowledge',
      knowledgeInput
    );

    context.log('Knowledge captured', {
      knowledgeVaultId: knowledgeVaultEntry.id,
      reusabilityScore: knowledgeVaultEntry.reusabilityScore
    });

    // Learn architectural patterns
    const patternInput = {
      buildId: pageId,
      architecture,
      deployment,
      successMetrics: {
        deployTime: healthCheck.deploymentDuration,
        testsPassed: healthCheck.testsPassed,
        cost: deployment.actualMonthlyCost
      }
    };

    const patternLearning = yield context.df.callActivity(
      'LearnPatterns',
      patternInput
    );

    context.log('Pattern learning complete', {
      patternsUpdated: patternLearning.patternsUpdated,
      newPatternsCreated: patternLearning.newPatternsCreated
    });

    // ========================================================================
    // FINAL STATUS UPDATE
    // ========================================================================
    yield context.df.callActivity('UpdateNotionStatus', {
      pageId,
      databaseType: 'builds',
      properties: {
        'Automation Status': 'Complete',
        'Automation Stage': 'Completed',
        'Last Automation Event': new Date().toISOString()
      }
    });

    context.log('Build pipeline completed successfully');

    return {
      status: 'success',
      buildId: pageId,
      githubRepo: githubRepo.url,
      liveUrl: deployment.appUrl,
      knowledgeVaultId: knowledgeVaultEntry.id,
      patternsLearned: patternLearning.patternsUpdated + patternLearning.newPatternsCreated,
      totalDuration: context.df.currentUtcDateTime - new Date(input.eventTimestamp)
    };
  } catch (error) {
    context.log.error('Build pipeline error', {
      error: error.message,
      stack: error.stack
    });

    // Update Notion with failure
    yield context.df.callActivity('UpdateNotionStatus', {
      pageId,
      databaseType: 'builds',
      properties: {
        'Automation Status': 'Failed',
        'Build Stage': 'Failed',
        'Last Automation Event': new Date().toISOString()
      }
    });

    // Escalate to human
    yield context.df.callActivity('EscalateToHuman', {
      pageId,
      reason: 'orchestration_error',
      details: {
        error: error.message,
        stage: 'unknown'
      }
    });

    throw error;
  }
});
