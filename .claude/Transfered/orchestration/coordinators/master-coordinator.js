/**
 * Master Coordinator
 *
 * Top-level orchestration system that manages multiple patterns,
 * agent lifecycles, global state, and execution monitoring.
 *
 * @module orchestration/coordinators/master-coordinator
 */

import { EventEmitter } from 'events';

/**
 * @typedef {Object} Agent
 * @property {string} id - Agent identifier
 * @property {string} name - Agent name
 * @property {string} type - Agent type
 * @property {string} status - Agent status (idle, busy, paused, stopped)
 * @property {Object} capabilities - Agent capabilities
 * @property {Function} execute - Agent execution function
 * @property {Date} createdAt - Creation timestamp
 * @property {Date} lastActiveAt - Last activity timestamp
 */

/**
 * @typedef {Object} ExecutionPlan
 * @property {string} id - Plan identifier
 * @property {string} strategy - Execution strategy
 * @property {Agent[]} assignedAgents - Agents assigned to this plan
 * @property {Object} state - Plan state
 * @property {Date} startedAt - Start timestamp
 * @property {Date} completedAt - Completion timestamp
 */

export class MasterCoordinator extends EventEmitter {
  /**
   * Creates a new Master Coordinator
   *
   * @param {Object} options - Configuration options
   * @param {number} [options.maxConcurrentPlans=5] - Maximum concurrent execution plans
   * @param {number} [options.agentTimeout=300000] - Agent timeout in ms
   * @param {boolean} [options.enableMetrics=true] - Enable metrics collection
   * @param {Function} [options.logger] - Logger function
   */
  constructor(options = {}) {
    super();

    this.maxConcurrentPlans = options.maxConcurrentPlans || 5;
    this.agentTimeout = options.agentTimeout || 300000;
    this.enableMetrics = options.enableMetrics !== false;
    this.logger = options.logger || console.log;

    /** @type {Map<string, Agent>} */
    this.agents = new Map();

    /** @type {Map<string, ExecutionPlan>} */
    this.executionPlans = new Map();

    /** @type {Map<string, any>} Global state store */
    this.globalState = new Map();

    /** @type {Object} Pattern orchestrators */
    this.patterns = {};

    /** @type {Object} Metrics */
    this.metrics = {
      totalExecutions: 0,
      successfulExecutions: 0,
      failedExecutions: 0,
      totalAgents: 0,
      activeAgents: 0,
      averageExecutionTime: 0
    };

    this.isRunning = false;
  }

  /**
   * Registers an orchestration pattern
   *
   * @param {string} name - Pattern name
   * @param {Object} pattern - Pattern orchestrator instance
   */
  registerPattern(name, pattern) {
    this.patterns[name] = pattern;

    // Forward pattern events
    if (pattern.on) {
      pattern.on('execution:started', (data) => {
        this.emit('pattern:execution:started', { pattern: name, ...data });
      });

      pattern.on('execution:completed', (data) => {
        this.emit('pattern:execution:completed', { pattern: name, ...data });
      });

      pattern.on('execution:failed', (data) => {
        this.emit('pattern:execution:failed', { pattern: name, ...data });
      });
    }

    this.logger(`[MasterCoordinator] Registered pattern: ${name}`);
  }

  /**
   * Registers an agent
   *
   * @param {Agent} agent - Agent to register
   * @returns {string} Agent ID
   */
  registerAgent(agent) {
    if (!agent.id) {
      agent.id = this._generateId();
    }

    agent.status = 'idle';
    agent.createdAt = new Date();
    agent.lastActiveAt = new Date();

    this.agents.set(agent.id, agent);
    this.metrics.totalAgents++;

    this.logger(`[MasterCoordinator] Registered agent: ${agent.name} (${agent.id})`);
    this.emit('agent:registered', { agent });

    return agent.id;
  }

  /**
   * Unregisters an agent
   *
   * @param {string} agentId - Agent ID
   * @returns {boolean} Success status
   */
  unregisterAgent(agentId) {
    const agent = this.agents.get(agentId);

    if (!agent) {
      return false;
    }

    // Stop agent if running
    if (agent.status === 'busy') {
      this.logger(`[MasterCoordinator] Warning: Unregistering busy agent ${agentId}`);
    }

    this.agents.delete(agentId);

    this.logger(`[MasterCoordinator] Unregistered agent: ${agentId}`);
    this.emit('agent:unregistered', { agentId });

    return true;
  }

  /**
   * Executes a task using specified pattern and agents
   *
   * @param {Object} options - Execution options
   * @param {string} options.pattern - Pattern to use
   * @param {Object} options.task - Task to execute
   * @param {string[]} [options.agentIds] - Specific agents to use
   * @param {Object} [options.config] - Pattern-specific configuration
   * @returns {Promise<any>} Execution result
   */
  async execute(options) {
    const { pattern, task, agentIds, config = {} } = options;

    if (!this.patterns[pattern]) {
      throw new Error(`Pattern not found: ${pattern}`);
    }

    // Check concurrent plan limit
    const activePlans = Array.from(this.executionPlans.values())
      .filter(p => p.state === 'running');

    if (activePlans.length >= this.maxConcurrentPlans) {
      throw new Error(`Maximum concurrent plans (${this.maxConcurrentPlans}) reached`);
    }

    // Create execution plan
    const plan = {
      id: this._generateId(),
      strategy: pattern,
      assignedAgents: [],
      state: 'running',
      startedAt: new Date(),
      completedAt: null,
      result: null,
      error: null
    };

    this.executionPlans.set(plan.id, plan);

    // Assign agents
    const agents = await this._assignAgents(task, agentIds);
    plan.assignedAgents = agents;

    this.logger(`[MasterCoordinator] Starting execution: ${plan.id} using ${pattern}`);
    this.emit('execution:started', { plan, task });

    this.metrics.totalExecutions++;

    const startTime = Date.now();

    try {
      // Mark agents as busy
      for (const agent of agents) {
        agent.status = 'busy';
        agent.lastActiveAt = new Date();
      }

      // Execute using pattern
      const patternExecutor = this.patterns[pattern];
      const result = await patternExecutor.execute(task, config);

      plan.state = 'completed';
      plan.completedAt = new Date();
      plan.result = result;

      const duration = Date.now() - startTime;

      // Update metrics
      this.metrics.successfulExecutions++;
      this._updateAverageExecutionTime(duration);

      this.logger(`[MasterCoordinator] Execution completed: ${plan.id} (${duration}ms)`);
      this.emit('execution:completed', { plan, result, duration });

      return result;

    } catch (error) {
      plan.state = 'failed';
      plan.completedAt = new Date();
      plan.error = error;

      this.metrics.failedExecutions++;

      this.logger(`[MasterCoordinator] Execution failed: ${plan.id} - ${error.message}`);
      this.emit('execution:failed', { plan, error });

      throw error;

    } finally {
      // Mark agents as idle
      for (const agent of agents) {
        agent.status = 'idle';
        agent.lastActiveAt = new Date();
      }
    }
  }

  /**
   * Assigns agents to a task
   *
   * @private
   * @param {Object} task - Task to execute
   * @param {string[]} [specificAgentIds] - Specific agent IDs to use
   * @returns {Promise<Agent[]>} Assigned agents
   */
  async _assignAgents(task, specificAgentIds = null) {
    let agents = [];

    if (specificAgentIds && specificAgentIds.length > 0) {
      // Use specific agents
      for (const agentId of specificAgentIds) {
        const agent = this.agents.get(agentId);

        if (!agent) {
          throw new Error(`Agent not found: ${agentId}`);
        }

        if (agent.status !== 'idle') {
          throw new Error(`Agent is not idle: ${agentId}`);
        }

        agents.push(agent);
      }

    } else {
      // Auto-assign based on capabilities
      const idleAgents = Array.from(this.agents.values())
        .filter(a => a.status === 'idle');

      if (idleAgents.length === 0) {
        throw new Error('No idle agents available');
      }

      // Simple assignment: pick first idle agent
      // In production, use more sophisticated matching
      agents = [idleAgents[0]];
    }

    this.metrics.activeAgents = agents.length;

    return agents;
  }

  /**
   * Gets or sets global state
   *
   * @param {string} key - State key
   * @param {any} [value] - State value (if setting)
   * @returns {any} State value
   */
  state(key, value = undefined) {
    if (value !== undefined) {
      this.globalState.set(key, value);
      this.emit('state:updated', { key, value });
      return value;
    }

    return this.globalState.get(key);
  }

  /**
   * Gets agent by ID
   *
   * @param {string} agentId - Agent ID
   * @returns {Agent|null} Agent
   */
  getAgent(agentId) {
    return this.agents.get(agentId) || null;
  }

  /**
   * Gets agents by criteria
   *
   * @param {Object} criteria - Search criteria
   * @param {string} [criteria.status] - Agent status
   * @param {string} [criteria.type] - Agent type
   * @returns {Agent[]} Matching agents
   */
  getAgents(criteria = {}) {
    let agents = Array.from(this.agents.values());

    if (criteria.status) {
      agents = agents.filter(a => a.status === criteria.status);
    }

    if (criteria.type) {
      agents = agents.filter(a => a.type === criteria.type);
    }

    return agents;
  }

  /**
   * Gets execution plan
   *
   * @param {string} planId - Plan ID
   * @returns {ExecutionPlan|null} Execution plan
   */
  getExecutionPlan(planId) {
    return this.executionPlans.get(planId) || null;
  }

  /**
   * Gets all execution plans
   *
   * @param {Object} [filter={}] - Filter criteria
   * @returns {ExecutionPlan[]} Execution plans
   */
  getExecutionPlans(filter = {}) {
    let plans = Array.from(this.executionPlans.values());

    if (filter.state) {
      plans = plans.filter(p => p.state === filter.state);
    }

    if (filter.strategy) {
      plans = plans.filter(p => p.strategy === filter.strategy);
    }

    return plans;
  }

  /**
   * Pauses an agent
   *
   * @param {string} agentId - Agent ID
   * @returns {boolean} Success status
   */
  pauseAgent(agentId) {
    const agent = this.agents.get(agentId);

    if (!agent) {
      return false;
    }

    if (agent.status === 'busy') {
      this.logger(`[MasterCoordinator] Warning: Cannot pause busy agent ${agentId}`);
      return false;
    }

    agent.status = 'paused';

    this.emit('agent:paused', { agentId });

    return true;
  }

  /**
   * Resumes an agent
   *
   * @param {string} agentId - Agent ID
   * @returns {boolean} Success status
   */
  resumeAgent(agentId) {
    const agent = this.agents.get(agentId);

    if (!agent || agent.status !== 'paused') {
      return false;
    }

    agent.status = 'idle';

    this.emit('agent:resumed', { agentId });

    return true;
  }

  /**
   * Gets system metrics
   *
   * @returns {Object} Metrics
   */
  getMetrics() {
    const idleAgents = this.getAgents({ status: 'idle' }).length;
    const busyAgents = this.getAgents({ status: 'busy' }).length;

    const successRate = this.metrics.totalExecutions > 0
      ? (this.metrics.successfulExecutions / this.metrics.totalExecutions) * 100
      : 0;

    return {
      ...this.metrics,
      idleAgents,
      busyAgents,
      successRate: successRate.toFixed(2) + '%',
      patterns: Object.keys(this.patterns).length,
      activePlans: this.getExecutionPlans({ state: 'running' }).length
    };
  }

  /**
   * Updates average execution time
   *
   * @private
   * @param {number} duration - Execution duration
   */
  _updateAverageExecutionTime(duration) {
    const total = this.metrics.successfulExecutions;

    this.metrics.averageExecutionTime =
      ((this.metrics.averageExecutionTime * (total - 1)) + duration) / total;
  }

  /**
   * Starts the coordinator
   */
  async start() {
    if (this.isRunning) {
      return;
    }

    this.logger('[MasterCoordinator] Starting...');

    this.isRunning = true;

    this.emit('coordinator:started');
  }

  /**
   * Stops the coordinator
   */
  async stop() {
    if (!this.isRunning) {
      return;
    }

    this.logger('[MasterCoordinator] Stopping...');

    // Wait for active plans to complete
    const activePlans = this.getExecutionPlans({ state: 'running' });

    if (activePlans.length > 0) {
      this.logger(`[MasterCoordinator] Waiting for ${activePlans.length} active plans...`);

      // In production, implement graceful shutdown with timeout
    }

    this.isRunning = false;

    this.emit('coordinator:stopped');
  }

  /**
   * Generates a unique ID
   *
   * @private
   * @returns {string} Unique ID
   */
  _generateId() {
    return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * Gets system health status
   *
   * @returns {Object} Health status
   */
  getHealth() {
    const agents = Array.from(this.agents.values());
    const healthyAgents = agents.filter(a => a.status !== 'stopped').length;

    const activePlans = this.getExecutionPlans({ state: 'running' });
    const failedPlans = this.getExecutionPlans({ state: 'failed' });

    const recentFailureRate = activePlans.length + failedPlans.length > 0
      ? failedPlans.length / (activePlans.length + failedPlans.length)
      : 0;

    const isHealthy = healthyAgents > 0 && recentFailureRate < 0.5;

    return {
      status: isHealthy ? 'healthy' : 'degraded',
      isRunning: this.isRunning,
      totalAgents: agents.length,
      healthyAgents,
      activePlans: activePlans.length,
      recentFailureRate: (recentFailureRate * 100).toFixed(2) + '%'
    };
  }
}

export default MasterCoordinator;
