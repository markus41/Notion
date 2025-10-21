#!/usr/bin/env node

/**
 * Validation Script for /orchestrate-complex v2.0 Migration
 *
 * Validates the command definition against v2.0 schema and performs
 * comprehensive checks for dynamic DAG generation, conditional execution,
 * event sourcing, saga compensation, and resource locking.
 *
 * Usage: node validate-orchestrate-complex.js
 */

const fs = require('fs');
const path = require('path');

// ANSI color codes for terminal output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function logSection(title) {
  console.log('');
  log('='.repeat(80), 'blue');
  log(title, 'bright');
  log('='.repeat(80), 'blue');
  console.log('');
}

function logCheck(description, passed, details = '') {
  const icon = passed ? '✅' : '❌';
  const color = passed ? 'green' : 'red';
  log(`${icon} ${description}`, color);
  if (details) {
    log(`   ${details}`, 'cyan');
  }
}

// Load command definition
const commandPath = path.join(__dirname, 'orchestrate-complex.json');
let command;

try {
  const fileContent = fs.readFileSync(commandPath, 'utf8');
  command = JSON.parse(fileContent);
  log('✅ Successfully loaded orchestrate-complex.json', 'green');
} catch (error) {
  log(`❌ Failed to load command file: ${error.message}`, 'red');
  process.exit(1);
}

// Validation counters
let totalChecks = 0;
let passedChecks = 0;
let warnings = 0;

function check(description, condition, details = '') {
  totalChecks++;
  const passed = Boolean(condition);
  if (passed) passedChecks++;
  logCheck(description, passed, details);
  return passed;
}

function warn(message) {
  warnings++;
  log(`⚠️  ${message}`, 'yellow');
}

// ============================================================================
// Basic Structure Validation
// ============================================================================

logSection('Basic Structure Validation');

check(
  'Command has version 2.0.0',
  command.version === '2.0.0',
  `Version: ${command.version}`
);

check(
  'Command name is /orchestrate-complex',
  command.name === '/orchestrate-complex',
  `Name: ${command.name}`
);

check(
  'Command has description',
  command.description && command.description.length > 0,
  `Length: ${command.description?.length || 0} chars`
);

check(
  'Command has metadata section',
  command.metadata && typeof command.metadata === 'object'
);

check(
  'Command has configuration section',
  command.configuration && typeof command.configuration === 'object'
);

check(
  'Command has inputs section',
  command.inputs && typeof command.inputs === 'object'
);

check(
  'Command has phases array',
  Array.isArray(command.phases) && command.phases.length > 0,
  `Phases: ${command.phases?.length || 0}`
);

// ============================================================================
// Metadata Validation
// ============================================================================

logSection('Metadata Validation');

check(
  'Metadata has complexity: advanced',
  command.metadata.complexity === 'advanced'
);

check(
  'Metadata lists required agents',
  Array.isArray(command.metadata.requiredAgents) && command.metadata.requiredAgents.length >= 3,
  `Required agents: ${command.metadata.requiredAgents?.length || 0}`
);

check(
  'Metadata has minAgents >= 3',
  command.metadata.minAgents >= 3,
  `Min agents: ${command.metadata.minAgents}`
);

check(
  'Metadata has maxAgents <= 25',
  command.metadata.maxAgents <= 25,
  `Max agents: ${command.metadata.maxAgents}`
);

check(
  'Metadata lists 4 supported patterns',
  Array.isArray(command.metadata.supportedPatterns) && command.metadata.supportedPatterns.length === 4,
  `Patterns: ${command.metadata.supportedPatterns?.join(', ') || 'none'}`
);

const expectedPatterns = ['plan-then-execute', 'hierarchical-decomposition', 'blackboard', 'event-sourcing'];
check(
  'All required patterns are supported',
  expectedPatterns.every(p => command.metadata.supportedPatterns.includes(p))
);

// ============================================================================
// Configuration Validation
// ============================================================================

logSection('Configuration Validation');

check(
  'Dynamic DAG is enabled',
  command.configuration.enableDynamicDAG === true
);

check(
  'Conditional execution is enabled',
  command.configuration.enableConditionalExecution === true
);

check(
  'Event sourcing is enabled',
  command.configuration.enableEventSourcing === true
);

check(
  'Max hierarchy depth is 5',
  command.configuration.maxHierarchyDepth === 5
);

check(
  'Blackboard is enabled',
  command.configuration.blackboardEnabled === true
);

check(
  'Dynamic replanning is enabled',
  command.configuration.dynamicReplanning === true
);

// ============================================================================
// Input Validation
// ============================================================================

logSection('Input Validation');

check(
  'Required inputs defined',
  command.inputs.required && typeof command.inputs.required === 'object'
);

check(
  'Objective input is required',
  command.inputs.required.objective && command.inputs.required.objective.type === 'string'
);

check(
  'Requirements input is required',
  command.inputs.required.requirements && command.inputs.required.requirements.type === 'array'
);

check(
  'Optional inputs defined',
  command.inputs.optional && typeof command.inputs.optional === 'object'
);

check(
  'Pattern input has 5 valid options',
  command.inputs.optional.pattern &&
  Array.isArray(command.inputs.optional.pattern.enum) &&
  command.inputs.optional.pattern.enum.length === 5,
  `Options: ${command.inputs.optional.pattern?.enum?.join(', ') || 'none'}`
);

check(
  'Pattern default is "auto"',
  command.inputs.optional.pattern.default === 'auto'
);

check(
  'Compliance frameworks input is array',
  command.inputs.optional.complianceFrameworks &&
  command.inputs.optional.complianceFrameworks.type === 'array'
);

// ============================================================================
// Phase Structure Validation
// ============================================================================

logSection('Phase Structure Validation');

const expectedPhases = [
  'Pattern Selection & Analysis',
  'Dynamic DAG Construction',
  'Compliance & Security Validation',
  'Architecture Design',
  'Implementation Planning',
  'Execution Coordination',
  'Quality Assurance',
  'Documentation & Deployment',
  'Final Validation & Sign-off'
];

check(
  'Command has 9 phases',
  command.phases.length === 9,
  `Actual: ${command.phases.length} phases`
);

expectedPhases.forEach((expectedName, index) => {
  const phase = command.phases[index];
  check(
    `Phase ${index + 1}: "${expectedName}"`,
    phase && phase.name === expectedName
  );
});

// ============================================================================
// Agent Validation
// ============================================================================

logSection('Agent Validation');

const allAgents = command.phases.flatMap(phase => phase.agents || []);
const totalAgents = allAgents.length;

check(
  'Total agent definitions',
  totalAgents >= 20,
  `Total agents: ${totalAgents}`
);

// Count conditional agents
const conditionalAgents = allAgents.filter(agent =>
  agent.conditional && agent.conditional.enabled === true
);

check(
  'Command has 8 conditional agents',
  conditionalAgents.length === 8,
  `Conditional agents: ${conditionalAgents.length}`
);

// Validate each agent has required fields
allAgents.forEach((agent, index) => {
  const agentNum = index + 1;

  check(
    `Agent ${agentNum} has id`,
    agent.id && typeof agent.id === 'string'
  );

  check(
    `Agent ${agentNum} has name (agent type)`,
    agent.name && typeof agent.name === 'string'
  );

  check(
    `Agent ${agentNum} has task description`,
    agent.task && typeof agent.task === 'string'
  );

  check(
    `Agent ${agentNum} has dependencies array`,
    Array.isArray(agent.dependencies)
  );
});

// ============================================================================
// Conditional Execution Validation
// ============================================================================

logSection('Conditional Execution Validation');

// Phase 2: DAG Construction (conditional phase)
const phase2 = command.phases[1];
check(
  'Phase 2 has conditional execution',
  phase2.conditional && phase2.conditional.enabled === true
);

check(
  'Phase 2 condition checks pattern',
  phase2.conditional.condition && phase2.conditional.condition.includes('patternSelector')
);

// Phase 3: Compliance & Security Validation (3 conditional agents)
const phase3 = command.phases[2];
const complianceValidator = phase3.agents.find(a => a.id === 'compliance-validator');
const securityValidator = phase3.agents.find(a => a.id === 'security-validator');
const cryptoValidator = phase3.agents.find(a => a.id === 'crypto-validator');

check(
  'compliance-validator has conditional execution',
  complianceValidator?.conditional?.enabled === true
);

check(
  'compliance-validator condition checks complianceFrameworks',
  complianceValidator?.conditional?.condition?.includes('complianceFrameworks')
);

check(
  'security-validator has conditional execution',
  securityValidator?.conditional?.enabled === true
);

check(
  'security-validator condition checks risk score',
  securityValidator?.conditional?.condition?.includes('riskAssessment')
);

check(
  'crypto-validator has conditional execution',
  cryptoValidator?.conditional?.enabled === true
);

check(
  'crypto-validator condition checks requirements',
  cryptoValidator?.conditional?.condition?.includes('encryption') ||
  cryptoValidator?.conditional?.condition?.includes('authentication')
);

// Phase 4: API and Database Design (2 conditional agents)
const phase4 = command.phases[3];
const apiDesign = phase4.agents.find(a => a.id === 'api-design');
const databaseDesign = phase4.agents.find(a => a.id === 'database-design');

check(
  'api-design has conditional execution',
  apiDesign?.conditional?.enabled === true
);

check(
  'api-design condition checks architecture',
  apiDesign?.conditional?.condition?.includes('api') ||
  apiDesign?.conditional?.condition?.includes('service')
);

check(
  'database-design has conditional execution',
  databaseDesign?.conditional?.enabled === true
);

check(
  'database-design condition checks architecture',
  databaseDesign?.conditional?.condition?.includes('database') ||
  databaseDesign?.conditional?.condition?.includes('storage')
);

// Phase 7: Chaos Testing (1 conditional agent)
const phase7 = command.phases[6];
const chaosTesting = phase7.agents.find(a => a.id === 'chaos-testing');

check(
  'chaos-testing has conditional execution',
  chaosTesting?.conditional?.enabled === true
);

check(
  'chaos-testing condition checks enableChaosEngineering',
  chaosTesting?.conditional?.condition?.includes('enableChaosEngineering')
);

// ============================================================================
// Dynamic DAG Validation (Phase 6)
// ============================================================================

logSection('Dynamic DAG Validation (Phase 6)');

const phase6 = command.phases[5];

check(
  'Phase 6 name is "Execution Coordination"',
  phase6.name === 'Execution Coordination'
);

check(
  'Phase 6 is marked as dynamic',
  phase6.dynamic === true
);

check(
  'Phase 6 has dynamicAgents configuration',
  phase6.dynamicAgents && typeof phase6.dynamicAgents === 'object'
);

check(
  'dynamicAgents.source points to implementation plan',
  phase6.dynamicAgents?.source?.includes('implementationPlanner')
);

check(
  'dynamicAgents.mapping defines agent structure',
  phase6.dynamicAgents?.mapping &&
  typeof phase6.dynamicAgents.mapping === 'object'
);

const mapping = phase6.dynamicAgents?.mapping;
check(
  'Agent mapping includes id, name, task, dependencies',
  mapping?.id && mapping?.name && mapping?.task && mapping?.dependencies
);

// ============================================================================
// Parallel Execution Validation
// ============================================================================

logSection('Parallel Execution Validation');

const parallelPhases = command.phases.filter(phase => phase.parallel === true);

check(
  'Command has 3 parallel phases',
  parallelPhases.length === 3,
  `Parallel phases: ${parallelPhases.map(p => p.name).join(', ')}`
);

check(
  'Phase 3 (Compliance & Security) is parallel',
  phase3.parallel === true,
  `Agents: ${phase3.agents.length}`
);

check(
  'Phase 7 (Quality Assurance) is parallel',
  phase7.parallel === true,
  `Agents: ${phase7.agents.length}`
);

const phase8 = command.phases[7];
check(
  'Phase 8 (Documentation & Deployment) is parallel',
  phase8.parallel === true,
  `Agents: ${phase8.agents.length}`
);

// Calculate theoretical speedup
const phase3Sequential = phase3.agents.reduce((sum, a) => sum + (a.estimatedTime || 0), 0);
const phase3Parallel = Math.max(...phase3.agents.map(a => a.estimatedTime || 0));
const phase3Speedup = phase3Sequential / phase3Parallel;

check(
  'Phase 3 achieves >2x speedup with parallelism',
  phase3Speedup > 2.0,
  `Speedup: ${phase3Speedup.toFixed(1)}x (${(phase3Sequential/1000).toFixed(0)}s → ${(phase3Parallel/1000).toFixed(0)}s)`
);

const phase7Sequential = phase7.agents.reduce((sum, a) => sum + (a.estimatedTime || 0), 0);
const phase7Parallel = Math.max(...phase7.agents.map(a => a.estimatedTime || 0));
const phase7Speedup = phase7Sequential / phase7Parallel;

check(
  'Phase 7 achieves >3x speedup with parallelism',
  phase7Speedup > 3.0,
  `Speedup: ${phase7Speedup.toFixed(1)}x (${(phase7Sequential/1000).toFixed(0)}s → ${(phase7Parallel/1000).toFixed(0)}s)`
);

// ============================================================================
// Context Sharing Validation
// ============================================================================

logSection('Context Sharing Validation');

check(
  'Context sharing is enabled',
  command.contextSharing && command.contextSharing.enabled === true
);

check(
  'Context sharing strategy is incremental',
  command.contextSharing.strategy === 'incremental'
);

check(
  'Cache policy is defined',
  command.contextSharing.cachePolicy && typeof command.contextSharing.cachePolicy === 'object'
);

check(
  'Cache max size is 100MB',
  command.contextSharing.cachePolicy.maxSize === 104857600
);

check(
  'Cache eviction is LFU',
  command.contextSharing.cachePolicy.eviction === 'LFU'
);

check(
  'Cache TTL is 60 minutes',
  command.contextSharing.cachePolicy.ttl === 3600000
);

check(
  'Shared context includes 6 keys',
  Array.isArray(command.contextSharing.sharedContext) &&
  command.contextSharing.sharedContext.length === 6,
  `Keys: ${command.contextSharing.sharedContext?.join(', ') || 'none'}`
);

const expectedContextKeys = ['objective', 'requirements', 'selectedPattern', 'architecture', 'implementationPlan', 'testStrategy'];
check(
  'All expected context keys are shared',
  expectedContextKeys.every(key => command.contextSharing.sharedContext?.includes(key))
);

// ============================================================================
// Saga Compensation Validation
// ============================================================================

logSection('Saga Compensation Validation');

check(
  'Saga compensation is enabled',
  command.sagaCompensation && command.sagaCompensation.enabled === true
);

check(
  'Compensation phases include Execution and QA',
  Array.isArray(command.sagaCompensation.compensationPhases) &&
  command.sagaCompensation.compensationPhases.includes('Execution Coordination') &&
  command.sagaCompensation.compensationPhases.includes('Quality Assurance'),
  `Phases: ${command.sagaCompensation.compensationPhases?.join(', ') || 'none'}`
);

check(
  'Rollback strategy is reverse-order',
  command.sagaCompensation.rollbackStrategy === 'reverse-order'
);

check(
  'Checkpoint frequency is per-phase',
  command.sagaCompensation.checkpointFrequency === 'per-phase'
);

// Validate chaos-testing has compensation
check(
  'chaos-testing agent has compensation',
  chaosTesting?.compensation && chaosTesting.compensation.enabled === true
);

check(
  'chaos-testing compensation has action',
  chaosTesting?.compensation?.action && chaosTesting.compensation.action.length > 0
);

check(
  'chaos-testing compensation has rollback steps',
  Array.isArray(chaosTesting?.compensation?.rollbackSteps) &&
  chaosTesting.compensation.rollbackSteps.length === 3
);

// ============================================================================
// Resource Locking Validation
// ============================================================================

logSection('Resource Locking Validation');

check(
  'Resource locking is enabled',
  command.resourceLocking && command.resourceLocking.enabled === true
);

check(
  'Resource locking defines 4 resources',
  Array.isArray(command.resourceLocking.resources) &&
  command.resourceLocking.resources.length === 4,
  `Resources: ${command.resourceLocking.resources?.map(r => r.id).join(', ') || 'none'}`
);

const expectedResources = ['dag-engine', 'context-cache', 'state-manager', 'event-log'];
check(
  'All expected resources are defined',
  expectedResources.every(id => command.resourceLocking.resources?.some(r => r.id === id))
);

// Validate each resource
command.resourceLocking.resources?.forEach(resource => {
  check(
    `Resource ${resource.id} has type`,
    resource.type && typeof resource.type === 'string'
  );

  check(
    `Resource ${resource.id} has maxConcurrent`,
    typeof resource.maxConcurrent === 'number' && resource.maxConcurrent > 0
  );

  check(
    `Resource ${resource.id} has priority`,
    resource.priority && ['high', 'medium', 'low'].includes(resource.priority)
  );
});

check(
  'Deadlock detection is enabled',
  command.resourceLocking.deadlockDetection === true
);

check(
  'Deadlock resolution is priority-preemption',
  command.resourceLocking.deadlockResolution === 'priority-preemption'
);

// ============================================================================
// Event Sourcing Validation
// ============================================================================

logSection('Event Sourcing Validation');

check(
  'Event sourcing is enabled',
  command.eventSourcing && command.eventSourcing.enabled === true
);

check(
  'Event log is configured',
  command.eventSourcing.eventLog && typeof command.eventSourcing.eventLog === 'object'
);

check(
  'Event log is enabled',
  command.eventSourcing.eventLog.enabled === true
);

check(
  'Event log persistence is durable',
  command.eventSourcing.eventLog.persistence === 'durable'
);

check(
  'Event log retention is 30 days',
  command.eventSourcing.eventLog.retention === 2592000000,
  `Retention: ${(command.eventSourcing.eventLog.retention / 86400000).toFixed(0)} days`
);

check(
  'State reconstruction is enabled',
  command.eventSourcing.stateReconstruction === true
);

check(
  'Time travel is enabled',
  command.eventSourcing.timeTravel === true
);

check(
  'Replay capability is enabled',
  command.eventSourcing.replayCapability === true
);

// ============================================================================
// Output Validation
// ============================================================================

logSection('Output Validation');

check(
  'Outputs section is defined',
  command.outputs && typeof command.outputs === 'object'
);

const expectedOutputs = [
  'strategicPlan',
  'architecture',
  'implementation',
  'testResults',
  'securityAudit',
  'documentation',
  'deploymentPlan',
  'validationReport',
  'eventLog'
];

check(
  'All 9 expected outputs are defined',
  expectedOutputs.every(output => command.outputs[output]),
  `Outputs: ${Object.keys(command.outputs || {}).length}`
);

// Validate each output has type and description
expectedOutputs.forEach(outputKey => {
  const output = command.outputs[outputKey];
  check(
    `Output ${outputKey} has type`,
    output?.type && typeof output.type === 'string'
  );

  check(
    `Output ${outputKey} has description`,
    output?.description && output.description.length > 0
  );
});

// ============================================================================
// Validation Checks
// ============================================================================

logSection('Validation Checks');

check(
  'Validation section is defined',
  command.validation && typeof command.validation === 'object'
);

check(
  'Pre-execution validation checks defined',
  Array.isArray(command.validation.preExecution) &&
  command.validation.preExecution.length >= 4
);

check(
  'During-execution validation checks defined',
  Array.isArray(command.validation.duringExecution) &&
  command.validation.duringExecution.length >= 4
);

check(
  'Post-execution validation checks defined',
  Array.isArray(command.validation.postExecution) &&
  command.validation.postExecution.length >= 5
);

const totalValidationChecks =
  command.validation.preExecution.length +
  command.validation.duringExecution.length +
  command.validation.postExecution.length;

check(
  'Total validation checks >= 13',
  totalValidationChecks >= 13,
  `Total: ${totalValidationChecks} checks`
);

// ============================================================================
// Performance Targets
// ============================================================================

logSection('Performance Targets');

check(
  'Performance section is defined',
  command.performance && typeof command.performance === 'object'
);

check(
  'Baseline v1.0 metrics defined',
  command.performance.baseline &&
  command.performance.baseline.v1Sequential
);

check(
  'Performance targets defined',
  command.performance.targets && typeof command.performance.targets === 'object'
);

check(
  'DAG construction target < 5 minutes',
  command.performance.targets.dagConstruction &&
  command.performance.targets.dagConstruction <= 300000,
  `Target: ${(command.performance.targets.dagConstruction / 1000).toFixed(0)}s`
);

check(
  'Parallel speedup target >= 40%',
  command.performance.targets.parallelSpeedup &&
  command.performance.targets.parallelSpeedup >= 0.4,
  `Target: ${(command.performance.targets.parallelSpeedup * 100).toFixed(0)}%`
);

check(
  'Cache hit rate target >= 75%',
  command.performance.targets.cacheHitRate &&
  command.performance.targets.cacheHitRate >= 0.75,
  `Target: ${(command.performance.targets.cacheHitRate * 100).toFixed(0)}%`
);

check(
  'Resource utilization target >= 85%',
  command.performance.targets.resourceUtilization &&
  command.performance.targets.resourceUtilization >= 0.85,
  `Target: ${(command.performance.targets.resourceUtilization * 100).toFixed(0)}%`
);

// ============================================================================
// Dependency Graph Validation
// ============================================================================

logSection('Dependency Graph Validation');

// Build dependency graph
const agentMap = new Map();
allAgents.forEach(agent => {
  agentMap.set(agent.id, agent);
});

// Validate all dependencies exist
let missingDeps = 0;
allAgents.forEach(agent => {
  agent.dependencies.forEach(depId => {
    const exists = agentMap.has(depId);
    if (!exists) {
      missingDeps++;
      warn(`Agent ${agent.id} has missing dependency: ${depId}`);
    }
  });
});

check(
  'All agent dependencies exist',
  missingDeps === 0,
  missingDeps > 0 ? `Found ${missingDeps} missing dependencies` : 'All dependencies valid'
);

// Check for circular dependencies (simplified check)
function hasCircularDependency(agentId, visited = new Set(), stack = new Set()) {
  if (stack.has(agentId)) return true; // Circular dependency found
  if (visited.has(agentId)) return false;

  visited.add(agentId);
  stack.add(agentId);

  const agent = agentMap.get(agentId);
  if (agent && agent.dependencies) {
    for (const depId of agent.dependencies) {
      if (hasCircularDependency(depId, visited, stack)) {
        return true;
      }
    }
  }

  stack.delete(agentId);
  return false;
}

let circularDeps = 0;
allAgents.forEach(agent => {
  if (hasCircularDependency(agent.id)) {
    circularDeps++;
    warn(`Circular dependency detected involving agent: ${agent.id}`);
  }
});

check(
  'No circular dependencies detected',
  circularDeps === 0,
  circularDeps > 0 ? `Found ${circularDeps} circular dependencies` : 'Dependency graph is acyclic'
);

// ============================================================================
// Advanced Features Validation
// ============================================================================

logSection('Advanced Features Validation');

check(
  'Command supports pattern auto-selection',
  command.inputs.optional.pattern.enum.includes('auto')
);

check(
  'Command supports Plan-then-Execute pattern',
  command.metadata.supportedPatterns.includes('plan-then-execute')
);

check(
  'Command supports Hierarchical Decomposition pattern',
  command.metadata.supportedPatterns.includes('hierarchical-decomposition')
);

check(
  'Command supports Blackboard pattern',
  command.metadata.supportedPatterns.includes('blackboard')
);

check(
  'Command supports Event Sourcing pattern',
  command.metadata.supportedPatterns.includes('event-sourcing')
);

check(
  'Configuration enables all advanced features',
  command.configuration.enableDynamicDAG &&
  command.configuration.enableConditionalExecution &&
  command.configuration.enableEventSourcing &&
  command.configuration.dynamicReplanning
);

// ============================================================================
// File Size and Complexity
// ============================================================================

logSection('File Metrics');

const fileSize = Buffer.byteLength(JSON.stringify(command, null, 2), 'utf8');
log(`📊 File size: ${(fileSize / 1024).toFixed(2)} KB`, 'cyan');
log(`📊 Total agents: ${totalAgents}`, 'cyan');
log(`📊 Total phases: ${command.phases.length}`, 'cyan');
log(`📊 Conditional agents: ${conditionalAgents.length}`, 'cyan');
log(`📊 Parallel phases: ${parallelPhases.length}`, 'cyan');
log(`📊 Shared context keys: ${command.contextSharing.sharedContext?.length || 0}`, 'cyan');
log(`📊 Resource locks: ${command.resourceLocking.resources?.length || 0}`, 'cyan');
log(`📊 Compensation phases: ${command.sagaCompensation.compensationPhases?.length || 0}`, 'cyan');

// ============================================================================
// Summary
// ============================================================================

logSection('Validation Summary');

const passRate = (passedChecks / totalChecks * 100).toFixed(1);
const failedChecks = totalChecks - passedChecks;

log(`Total checks: ${totalChecks}`, 'cyan');
log(`Passed: ${passedChecks} (${passRate}%)`, passedChecks === totalChecks ? 'green' : 'yellow');
if (failedChecks > 0) {
  log(`Failed: ${failedChecks}`, 'red');
}
if (warnings > 0) {
  log(`Warnings: ${warnings}`, 'yellow');
}

console.log('');

if (passedChecks === totalChecks && warnings === 0) {
  log('🎉 All validation checks passed! Command is ready for v2.0 orchestration.', 'green');
  process.exit(0);
} else if (passedChecks === totalChecks && warnings > 0) {
  log('✅ All critical checks passed, but there are warnings to review.', 'yellow');
  process.exit(0);
} else {
  log(`❌ ${failedChecks} validation check(s) failed. Please review and fix before deployment.`, 'red');
  process.exit(1);
}
