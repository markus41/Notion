/**
 * Research Swarm Orchestrator (Durable Function)
 *
 * Establishes parallel research execution where multiple specialized agents
 * investigate different aspects of idea viability simultaneously, then synthesize
 * findings into comprehensive viability assessment.
 *
 * Research Agents (Parallel Execution):
 * - Market Researcher: Market opportunity, trends, competitive landscape
 * - Technical Analyst: Technical feasibility, architecture options, complexity
 * - Cost Analyst: Build cost, operational cost, ROI projection
 * - Risk Assessor: Technical risks, business risks, mitigation strategies
 *
 * Best for: High-value ideas requiring thorough feasibility investigation before build
 */

const df = require("durable-functions");

module.exports = df.orchestrator(function* (context) {
  const input = context.df.getInput();
  const { pageId, databaseType, page } = input;

  context.log(`Research Swarm started for page: ${pageId}`);

  try {
    // ========================================================================
    // INITIALIZATION: Fetch idea context
    // ========================================================================
    yield context.df.callActivity('UpdateNotionStatus', {
      pageId,
      databaseType: 'research',
      properties: {
        'Automation Status': 'In Progress',
        'Automation Stage': 'Research Initialization',
        'Research Progress %': 0
      }
    });

    // Create Research Hub entry linked to idea
    const researchEntry = yield context.df.callActivity('CreateResearchEntry', {
      ideaPageId: pageId,
      ideaData: page
    });

    const researchPageId = researchEntry.id;

    context.log('Research Hub entry created', {
      researchPageId,
      linkedTo: pageId
    });

    // ========================================================================
    // PHASE 1: PARALLEL RESEARCH EXECUTION (4 agents)
    // ========================================================================
    yield context.df.callActivity('UpdateNotionStatus', {
      pageId: researchPageId,
      databaseType: 'research',
      properties: {
        'Automation Stage': 'Research Execution (Parallel)',
        'Research Progress %': 10
      }
    });

    // Prepare research context
    const ideaTitle = page.properties.Title?.title?.[0]?.plain_text || 'Untitled Idea';
    const ideaDescription = page.properties.Description?.rich_text?.[0]?.plain_text || '';
    const ideaCategory = page.properties.Category?.select?.name || 'General';

    // Launch all 4 research agents in parallel
    const researchTasks = [
      // Agent 1: Market Researcher
      context.df.callActivity('InvokeClaudeAgent', {
        agent: 'market-researcher',
        task: `Analyze market opportunity for: ${ideaTitle}\n\nDescription: ${ideaDescription}\n\nCategory: ${ideaCategory}\n\nProvide:\n1. Market size and growth trends\n2. Competitive landscape\n3. Market demand indicators\n4. Target audience analysis\n5. Market score (0-100)`,
        outputFormat: 'structured',
        timeout: 900000 // 15 minutes
      }),

      // Agent 2: Technical Analyst
      context.df.callActivity('InvokeClaudeAgent', {
        agent: 'technical-analyst',
        task: `Assess technical feasibility for: ${ideaTitle}\n\nDescription: ${ideaDescription}\n\nProvide:\n1. Recommended technology stack (Microsoft-first)\n2. Architecture approach\n3. Technical complexity (XS/S/M/L/XL)\n4. Implementation risks\n5. Technical score (0-100)`,
        outputFormat: 'structured',
        timeout: 900000
      }),

      // Agent 3: Cost Analyst
      context.df.callActivity('InvokeClaudeAgent', {
        agent: 'cost-analyst',
        task: `Calculate viability and costs for: ${ideaTitle}\n\nDescription: ${ideaDescription}\n\nProvide:\n1. Estimated build cost (hours × $150/hr)\n2. Monthly operational cost (Azure services, software)\n3. Required software/tools and costs\n4. ROI projection (time savings, revenue potential)\n5. Cost score (0-100, lower cost = higher score)`,
        outputFormat: 'structured',
        timeout: 900000
      }),

      // Agent 4: Risk Assessor
      context.df.callActivity('InvokeClaudeAgent', {
        agent: 'risk-assessor',
        task: `Identify risks and challenges for: ${ideaTitle}\n\nDescription: ${ideaDescription}\n\nProvide:\n1. Technical risks and likelihood\n2. Business/market risks\n3. Resource/capacity risks\n4. Mitigation strategies for each risk\n5. Risk score (0-100, lower risk = higher score)`,
        outputFormat: 'structured',
        timeout: 900000
      })
    ];

    // Execute all research agents in parallel
    const researchResults = yield context.df.Task.all(researchTasks);

    const [marketAnalysis, technicalFeasibility, costAnalysis, riskAssessment] = researchResults;

    context.log('Research agents completed', {
      marketScore: marketAnalysis.score,
      technicalScore: technicalFeasibility.score,
      costScore: costAnalysis.score,
      riskScore: riskAssessment.score
    });

    yield context.df.callActivity('UpdateNotionStatus', {
      pageId: researchPageId,
      databaseType: 'research',
      properties: {
        'Research Progress %': 70
      }
    });

    // ========================================================================
    // PHASE 2: VIABILITY SCORE CALCULATION
    // ========================================================================
    yield context.df.callActivity('UpdateNotionStatus', {
      pageId: researchPageId,
      databaseType: 'research',
      properties: {
        'Automation Stage': 'Viability Synthesis'
      }
    });

    // Calculate composite viability score (weighted average)
    const weights = {
      market: 0.30,      // Market opportunity weight
      technical: 0.25,   // Technical feasibility weight
      cost: 0.25,        // Cost efficiency weight
      risk: 0.20         // Risk mitigation weight
    };

    const viabilityScore = Math.round(
      marketAnalysis.score * weights.market +
      technicalFeasibility.score * weights.technical +
      costAnalysis.score * weights.cost +
      riskAssessment.score * weights.risk
    );

    context.log('Viability score calculated', { viabilityScore });

    // Determine viability assessment category
    let viabilityAssessment;
    let nextSteps;

    if (viabilityScore >= 85) {
      viabilityAssessment = 'Highly Viable';
      nextSteps = 'Build Example';
    } else if (viabilityScore >= 70) {
      viabilityAssessment = 'Moderately Viable';
      nextSteps = 'Build Example';
    } else if (viabilityScore >= 50) {
      viabilityAssessment = 'Moderately Viable';
      nextSteps = 'More Research'; // Needs deeper investigation
    } else {
      viabilityAssessment = 'Not Viable';
      nextSteps = 'Archive';
    }

    // ========================================================================
    // PHASE 3: UPDATE RESEARCH HUB WITH FINDINGS
    // ========================================================================
    yield context.df.callActivity('UpdateNotionStatus', {
      pageId: researchPageId,
      databaseType: 'research',
      properties: {
        'Automation Stage': 'Documentation',
        'Research Progress %': 90
      }
    });

    // Update Research Hub with comprehensive findings
    yield context.df.callActivity('UpdateResearchFindings', {
      researchPageId,
      marketAnalysis,
      technicalFeasibility,
      costAnalysis,
      riskAssessment,
      viabilityScore,
      viabilityAssessment,
      nextSteps
    });

    // Update original idea with viability score
    yield context.df.callActivity('UpdateNotionStatus', {
      pageId,
      databaseType: 'ideas',
      properties: {
        'Viability Score': viabilityScore,
        'Viability': viabilityScore >= 75 ? 'High' : viabilityScore >= 50 ? 'Medium' : 'Low'
      }
    });

    // ========================================================================
    // PHASE 4: AUTO-TRIGGER BUILD OR ESCALATE
    // ========================================================================
    yield context.df.callActivity('UpdateNotionStatus', {
      pageId: researchPageId,
      databaseType: 'research',
      properties: {
        'Automation Status': 'Complete',
        'Research Progress %': 100,
        'Last Automation Event': new Date().toISOString()
      }
    });

    // Decision: Auto-trigger build or escalate to human
    if (viabilityScore >= 85 && costAnalysis.monthlyCost < 500) {
      context.log('Auto-triggering build pipeline (high viability + low cost)');

      // Start Build Pipeline Orchestrator
      const buildInstanceId = yield context.df.callSubOrchestrator(
        'BuildPipelineOrchestrator',
        {
          pageId,
          databaseType: 'ideas',
          triggerName: 'research_high_viability',
          eventTimestamp: new Date().toISOString(),
          researchPageId
        }
      );

      return {
        status: 'auto_build_triggered',
        viabilityScore,
        buildInstanceId,
        researchPageId
      };
    } else if (viabilityScore >= 60 && viabilityScore < 85) {
      context.log('Viability in gray zone - escalating to human');

      yield context.df.callActivity('EscalateToHuman', {
        pageId,
        reason: 'viability_gray_zone',
        details: {
          viabilityScore,
          viabilityAssessment,
          estimatedCost: costAnalysis.monthlyCost,
          recommendation: nextSteps
        }
      });

      return {
        status: 'requires_review',
        viabilityScore,
        viabilityAssessment,
        researchPageId
      };
    } else if (viabilityScore < 60) {
      context.log('Low viability - archiving with learnings');

      // Archive idea with learnings
      yield context.df.callActivity('ArchiveWithLearnings', {
        pageId,
        reason: 'low_viability',
        viabilityScore,
        researchSummary: {
          marketAnalysis,
          technicalFeasibility,
          costAnalysis,
          riskAssessment
        }
      });

      return {
        status: 'archived_low_viability',
        viabilityScore,
        researchPageId
      };
    } else {
      // viabilityScore >= 85 but cost >= 500
      context.log('High viability but cost exceeds threshold - escalating');

      yield context.df.callActivity('EscalateToHuman', {
        pageId,
        reason: 'cost_threshold_exceeded',
        details: {
          viabilityScore,
          estimatedCost: costAnalysis.monthlyCost,
          threshold: 500
        }
      });

      return {
        status: 'requires_cost_approval',
        viabilityScore,
        estimatedCost: costAnalysis.monthlyCost,
        researchPageId
      };
    }
  } catch (error) {
    context.log.error('Research swarm error', {
      error: error.message,
      stack: error.stack
    });

    // Update Research Hub with failure
    yield context.df.callActivity('UpdateNotionStatus', {
      pageId: researchPageId || pageId,
      databaseType: 'research',
      properties: {
        'Automation Status': 'Failed',
        'Last Automation Event': new Date().toISOString()
      }
    });

    throw error;
  }
});
