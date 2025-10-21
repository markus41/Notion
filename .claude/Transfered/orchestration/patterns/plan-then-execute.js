/**
 * Plan-then-Execute Pattern
 *
 * Implements strategic planning followed by parallel execution with dynamic re-planning.
 * Supports state checkpointing, rollback, and real-time monitoring.
 *
 * @module orchestration/patterns/plan-then-execute
 */

import { EventEmitter } from 'events';

/**
 * @typedef {Object} Task
 * @property {string} id - Unique task identifier
 * @property {string} name - Task name
 * @property {string} description - Task description
 * @property {string[]} dependencies - Array of task IDs this task depends on
 * @property {number} priority - Task priority (higher = more important)
 * @property {Function} executor - Async function to execute the task
 * @property {number} estimatedDuration - Estimated duration in milliseconds
 * @property {Object} metadata - Additional task metadata
 */

/**
 * @typedef {Object} Plan
 * @property {string} id - Plan identifier
 * @property {string} goal - Overall goal description
 * @property {Task[]} tasks - Array of tasks in the plan
 * @property {Object} constraints - Execution constraints (time, resources, etc.)
 * @property {number} version - Plan version number
 * @property {Date} createdAt - Plan creation timestamp
 */

/**
 * @typedef {Object} ExecutionState
 * @property {string} planId - Current plan ID
 * @property {Map<string, any>} taskResults - Results of completed tasks
 * @property {Map<string, string>} taskStatus - Status of each task (pending, running, completed, failed)
 * @property {Object[]} checkpoints - State checkpoints for rollback
 * @property {number} completedTasks - Number of completed tasks
 * @property {number} failedTasks - Number of failed tasks
 */

export class PlanThenExecute extends EventEmitter {
  /**
   * Creates a new Plan-then-Execute orchestrator
   *
   * @param {Object} options - Configuration options
   * @param {number} [options.maxRetries=3] - Maximum retry attempts per task
   * @param {number} [options.replanThreshold=0.3] - Failure rate threshold to trigger re-planning
   * @param {number} [options.maxConcurrency=10] - Maximum concurrent task execution
   * @param {number} [options.checkpointInterval=5] - Create checkpoint every N tasks
   * @param {Function} [options.logger] - Logger function
   */
  constructor(options = {}) {
    super();

    this.maxRetries = options.maxRetries || 3;
    this.replanThreshold = options.replanThreshold || 0.3;
    this.maxConcurrency = options.maxConcurrency || 10;
    this.checkpointInterval = options.checkpointInterval || 5;
    this.logger = options.logger || console.log;

    /** @type {Plan|null} */
    this.currentPlan = null;

    /** @type {ExecutionState} */
    this.state = {
      planId: null,
      taskResults: new Map(),
      taskStatus: new Map(),
      checkpoints: [],
      completedTasks: 0,
      failedTasks: 0
    };

    this.isExecuting = false;
    this.executionStartTime = null;
  }

  /**
   * Creates a strategic plan from a goal and available tasks
   *
   * @param {string} goal - The goal to achieve
   * @param {Task[]} tasks - Available tasks
   * @param {Object} [constraints={}] - Execution constraints
   * @returns {Promise<Plan>} The generated plan
   */
  async createPlan(goal, tasks, constraints = {}) {
    this.logger(`[PlanThenExecute] Creating plan for goal: ${goal}`);

    // Validate tasks
    this._validateTasks(tasks);

    // Sort tasks by priority and dependencies
    const sortedTasks = this._topologicalSort(tasks);

    const plan = {
      id: this._generateId(),
      goal,
      tasks: sortedTasks,
      constraints: {
        maxDuration: constraints.maxDuration || Infinity,
        maxCost: constraints.maxCost || Infinity,
        requiredResources: constraints.requiredResources || [],
        ...constraints
      },
      version: 1,
      createdAt: new Date()
    };

    this.logger(`[PlanThenExecute] Plan created with ${sortedTasks.length} tasks`);
    this.emit('plan:created', plan);

    return plan;
  }

  /**
   * Validates the plan for feasibility and correctness
   *
   * @param {Plan} plan - Plan to validate
   * @returns {Promise<{valid: boolean, issues: string[]}>} Validation result
   */
  async validatePlan(plan) {
    this.logger(`[PlanThenExecute] Validating plan ${plan.id}`);

    const issues = [];

    // Check for circular dependencies
    if (this._hasCircularDependencies(plan.tasks)) {
      issues.push('Circular dependencies detected');
    }

    // Validate task executors
    for (const task of plan.tasks) {
      if (typeof task.executor !== 'function') {
        issues.push(`Task ${task.id} has invalid executor`);
      }
    }

    // Check time constraints
    const estimatedDuration = plan.tasks.reduce((sum, task) => sum + task.estimatedDuration, 0);
    if (estimatedDuration > plan.constraints.maxDuration) {
      issues.push(`Estimated duration ${estimatedDuration}ms exceeds max duration ${plan.constraints.maxDuration}ms`);
    }

    const valid = issues.length === 0;

    this.emit('plan:validated', { plan, valid, issues });

    return { valid, issues };
  }

  /**
   * Executes the plan with parallel task execution and monitoring
   *
   * @param {Plan} plan - Plan to execute
   * @param {Object} [options={}] - Execution options
   * @param {boolean} [options.autoReplan=true] - Enable automatic re-planning on failures
   * @returns {Promise<Map<string, any>>} Results of all tasks
   */
  async execute(plan, options = {}) {
    const autoReplan = options.autoReplan !== false;

    this.logger(`[PlanThenExecute] Starting execution of plan ${plan.id}`);

    // Validate plan first
    const validation = await this.validatePlan(plan);
    if (!validation.valid) {
      throw new Error(`Plan validation failed: ${validation.issues.join(', ')}`);
    }

    this.currentPlan = plan;
    this.isExecuting = true;
    this.executionStartTime = Date.now();

    // Initialize state
    this.state = {
      planId: plan.id,
      taskResults: new Map(),
      taskStatus: new Map(),
      checkpoints: [],
      completedTasks: 0,
      failedTasks: 0
    };

    // Mark all tasks as pending
    for (const task of plan.tasks) {
      this.state.taskStatus.set(task.id, 'pending');
    }

    this.emit('execution:started', { plan });

    try {
      await this._executeTasksWithMonitoring(plan, autoReplan);

      this.logger(`[PlanThenExecute] Plan execution completed successfully`);
      this.emit('execution:completed', {
        plan,
        results: this.state.taskResults,
        duration: Date.now() - this.executionStartTime
      });

      return this.state.taskResults;

    } catch (error) {
      this.logger(`[PlanThenExecute] Plan execution failed: ${error.message}`);
      this.emit('execution:failed', { plan, error });
      throw error;

    } finally {
      this.isExecuting = false;
    }
  }

  /**
   * Creates a checkpoint of current execution state
   *
   * @returns {Object} Checkpoint object
   */
  createCheckpoint() {
    const checkpoint = {
      id: this._generateId(),
      timestamp: new Date(),
      taskResults: new Map(this.state.taskResults),
      taskStatus: new Map(this.state.taskStatus),
      completedTasks: this.state.completedTasks,
      failedTasks: this.state.failedTasks
    };

    this.state.checkpoints.push(checkpoint);
    this.logger(`[PlanThenExecute] Checkpoint created: ${checkpoint.id}`);
    this.emit('checkpoint:created', checkpoint);

    return checkpoint;
  }

  /**
   * Rolls back to a previous checkpoint
   *
   * @param {string} checkpointId - Checkpoint ID to rollback to
   * @returns {boolean} Success status
   */
  async rollback(checkpointId) {
    const checkpoint = this.state.checkpoints.find(cp => cp.id === checkpointId);

    if (!checkpoint) {
      this.logger(`[PlanThenExecute] Checkpoint ${checkpointId} not found`);
      return false;
    }

    this.logger(`[PlanThenExecute] Rolling back to checkpoint ${checkpointId}`);

    this.state.taskResults = new Map(checkpoint.taskResults);
    this.state.taskStatus = new Map(checkpoint.taskStatus);
    this.state.completedTasks = checkpoint.completedTasks;
    this.state.failedTasks = checkpoint.failedTasks;

    // Remove checkpoints after this one
    const checkpointIndex = this.state.checkpoints.findIndex(cp => cp.id === checkpointId);
    this.state.checkpoints = this.state.checkpoints.slice(0, checkpointIndex + 1);

    this.emit('rollback:completed', { checkpointId });

    return true;
  }

  /**
   * Executes tasks with monitoring and triggers re-planning if needed
   *
   * @private
   * @param {Plan} plan - Plan to execute
   * @param {boolean} autoReplan - Enable automatic re-planning
   */
  async _executeTasksWithMonitoring(plan, autoReplan) {
    const taskQueue = [...plan.tasks];
    const executing = new Set();

    while (taskQueue.length > 0 || executing.size > 0) {
      // Check if re-planning is needed
      if (autoReplan && this._shouldReplan()) {
        this.logger(`[PlanThenExecute] Failure threshold exceeded, triggering re-planning`);
        await this._replan();
        return this._executeTasksWithMonitoring(this.currentPlan, autoReplan);
      }

      // Find tasks ready to execute
      const readyTasks = taskQueue.filter(task =>
        this._areDepsSatisfied(task) && executing.size < this.maxConcurrency
      );

      // Start executing ready tasks
      for (const task of readyTasks) {
        taskQueue.splice(taskQueue.indexOf(task), 1);
        executing.add(task.id);

        this._executeTask(task)
          .then(result => {
            this.state.taskResults.set(task.id, result);
            this.state.taskStatus.set(task.id, 'completed');
            this.state.completedTasks++;

            executing.delete(task.id);

            // Create checkpoint periodically
            if (this.state.completedTasks % this.checkpointInterval === 0) {
              this.createCheckpoint();
            }

            this.emit('task:completed', { task, result });
          })
          .catch(error => {
            this.state.taskStatus.set(task.id, 'failed');
            this.state.failedTasks++;

            executing.delete(task.id);

            this.emit('task:failed', { task, error });
          });
      }

      // Wait a bit before next iteration
      await this._sleep(100);

      // Check if we're stuck
      if (taskQueue.length > 0 && executing.size === 0 && readyTasks.length === 0) {
        throw new Error('Execution stuck: tasks have unsatisfied dependencies or all tasks failed');
      }
    }

    // Check if we have failures
    if (this.state.failedTasks > 0) {
      throw new Error(`Execution completed with ${this.state.failedTasks} failed tasks`);
    }
  }

  /**
   * Executes a single task with retries
   *
   * @private
   * @param {Task} task - Task to execute
   * @returns {Promise<any>} Task result
   */
  async _executeTask(task) {
    this.logger(`[PlanThenExecute] Executing task: ${task.id} - ${task.name}`);
    this.state.taskStatus.set(task.id, 'running');
    this.emit('task:started', { task });

    let lastError;

    for (let attempt = 1; attempt <= this.maxRetries; attempt++) {
      try {
        const result = await task.executor();
        return result;

      } catch (error) {
        lastError = error;
        this.logger(`[PlanThenExecute] Task ${task.id} failed (attempt ${attempt}/${this.maxRetries}): ${error.message}`);

        if (attempt < this.maxRetries) {
          await this._sleep(Math.pow(2, attempt) * 1000); // Exponential backoff
        }
      }
    }

    throw lastError;
  }

  /**
   * Checks if task dependencies are satisfied
   *
   * @private
   * @param {Task} task - Task to check
   * @returns {boolean} True if dependencies are satisfied
   */
  _areDepsSatisfied(task) {
    if (!task.dependencies || task.dependencies.length === 0) {
      return true;
    }

    return task.dependencies.every(depId =>
      this.state.taskStatus.get(depId) === 'completed'
    );
  }

  /**
   * Determines if re-planning should be triggered
   *
   * @private
   * @returns {boolean} True if re-planning is needed
   */
  _shouldReplan() {
    const totalTasks = this.state.completedTasks + this.state.failedTasks;
    if (totalTasks === 0) return false;

    const failureRate = this.state.failedTasks / totalTasks;
    return failureRate >= this.replanThreshold;
  }

  /**
   * Triggers re-planning with current state
   *
   * @private
   */
  async _replan() {
    this.logger(`[PlanThenExecute] Re-planning triggered`);
    this.emit('replan:started', { state: this.state });

    // Get remaining tasks
    const remainingTasks = this.currentPlan.tasks.filter(task =>
      this.state.taskStatus.get(task.id) !== 'completed'
    );

    // Create new plan with remaining tasks
    const newPlan = await this.createPlan(
      this.currentPlan.goal,
      remainingTasks,
      this.currentPlan.constraints
    );

    newPlan.version = this.currentPlan.version + 1;
    this.currentPlan = newPlan;

    // Reset failed task statuses
    for (const task of remainingTasks) {
      if (this.state.taskStatus.get(task.id) === 'failed') {
        this.state.taskStatus.set(task.id, 'pending');
      }
    }

    this.state.failedTasks = 0;

    this.emit('replan:completed', { plan: newPlan });
  }

  /**
   * Validates tasks for correctness
   *
   * @private
   * @param {Task[]} tasks - Tasks to validate
   * @throws {Error} If validation fails
   */
  _validateTasks(tasks) {
    if (!Array.isArray(tasks) || tasks.length === 0) {
      throw new Error('Tasks must be a non-empty array');
    }

    const taskIds = new Set();

    for (const task of tasks) {
      if (!task.id || !task.name || !task.executor) {
        throw new Error('Task must have id, name, and executor');
      }

      if (taskIds.has(task.id)) {
        throw new Error(`Duplicate task ID: ${task.id}`);
      }

      taskIds.add(task.id);
    }
  }

  /**
   * Performs topological sort on tasks based on dependencies
   *
   * @private
   * @param {Task[]} tasks - Tasks to sort
   * @returns {Task[]} Sorted tasks
   */
  _topologicalSort(tasks) {
    const sorted = [];
    const visited = new Set();
    const visiting = new Set();

    const visit = (task) => {
      if (visited.has(task.id)) return;
      if (visiting.has(task.id)) {
        throw new Error(`Circular dependency detected: ${task.id}`);
      }

      visiting.add(task.id);

      if (task.dependencies) {
        for (const depId of task.dependencies) {
          const depTask = tasks.find(t => t.id === depId);
          if (depTask) {
            visit(depTask);
          }
        }
      }

      visiting.delete(task.id);
      visited.add(task.id);
      sorted.push(task);
    };

    for (const task of tasks) {
      visit(task);
    }

    return sorted;
  }

  /**
   * Checks for circular dependencies in tasks
   *
   * @private
   * @param {Task[]} tasks - Tasks to check
   * @returns {boolean} True if circular dependencies exist
   */
  _hasCircularDependencies(tasks) {
    try {
      this._topologicalSort(tasks);
      return false;
    } catch (error) {
      return true;
    }
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
   * Sleep utility
   *
   * @private
   * @param {number} ms - Milliseconds to sleep
   * @returns {Promise<void>}
   */
  _sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

export default PlanThenExecute;
