/**
 * Hierarchical Decomposition Pattern
 *
 * Implements recursive task breakdown with automatic parallelization
 * and bottom-up result aggregation.
 *
 * @module orchestration/patterns/hierarchical-decomposition
 */

import { EventEmitter } from 'events';

/**
 * @typedef {Object} DecomposableTask
 * @property {string} id - Unique task identifier
 * @property {string} name - Task name
 * @property {string} type - Task type (atomic, composite)
 * @property {Function} [executor] - Executor for atomic tasks
 * @property {Function} [decomposer] - Decomposer function for composite tasks
 * @property {number} complexity - Task complexity score (0-100)
 * @property {Object} context - Task execution context
 * @property {DecomposableTask[]} [subtasks] - Child tasks after decomposition
 * @property {number} depth - Current depth in hierarchy
 */

/**
 * @typedef {Object} TaskNode
 * @property {DecomposableTask} task - The task
 * @property {TaskNode|null} parent - Parent node
 * @property {TaskNode[]} children - Child nodes
 * @property {string} status - Node status (pending, decomposing, executing, completed, failed)
 * @property {any} result - Task result
 * @property {Error|null} error - Task error if failed
 */

/**
 * @typedef {Object} DecompositionResult
 * @property {TaskNode} root - Root task node
 * @property {Map<string, any>} results - All task results
 * @property {number} totalTasks - Total number of tasks executed
 * @property {number} maxDepth - Maximum depth reached
 * @property {number} duration - Total execution duration
 */

export class HierarchicalDecomposition extends EventEmitter {
  /**
   * Creates a new Hierarchical Decomposition orchestrator
   *
   * @param {Object} options - Configuration options
   * @param {number} [options.maxDepth=5] - Maximum decomposition depth
   * @param {number} [options.maxConcurrency=20] - Maximum concurrent task execution
   * @param {number} [options.complexityThreshold=20] - Complexity threshold for decomposition
   * @param {Function} [options.logger] - Logger function
   */
  constructor(options = {}) {
    super();

    this.maxDepth = options.maxDepth || 5;
    this.maxConcurrency = options.maxConcurrency || 20;
    this.complexityThreshold = options.complexityThreshold || 20;
    this.logger = options.logger || console.log;

    /** @type {Map<string, TaskNode>} */
    this.taskNodes = new Map();

    /** @type {Set<string>} */
    this.executingTasks = new Set();

    this.totalTasksExecuted = 0;
    this.maxDepthReached = 0;
  }

  /**
   * Decomposes and executes a complex task hierarchically
   *
   * @param {DecomposableTask} task - Root task to decompose and execute
   * @returns {Promise<DecompositionResult>} Execution result
   */
  async execute(task) {
    this.logger(`[HierarchicalDecomposition] Starting execution of task: ${task.name}`);

    const startTime = Date.now();

    // Initialize root node
    const rootNode = this._createTaskNode(task, null);
    this.taskNodes.set(task.id, rootNode);

    this.emit('execution:started', { task });

    try {
      // Decompose and execute
      await this._decomposeAndExecute(rootNode);

      // Collect results
      const results = this._collectResults(rootNode);

      const result = {
        root: rootNode,
        results,
        totalTasks: this.totalTasksExecuted,
        maxDepth: this.maxDepthReached,
        duration: Date.now() - startTime
      };

      this.logger(`[HierarchicalDecomposition] Execution completed: ${this.totalTasksExecuted} tasks, max depth: ${this.maxDepthReached}`);
      this.emit('execution:completed', result);

      return result;

    } catch (error) {
      this.logger(`[HierarchicalDecomposition] Execution failed: ${error.message}`);
      this.emit('execution:failed', { task, error });
      throw error;
    }
  }

  /**
   * Recursively decomposes and executes a task node
   *
   * @private
   * @param {TaskNode} node - Task node to process
   * @returns {Promise<any>} Task result
   */
  async _decomposeAndExecute(node) {
    const task = node.task;

    // Update max depth
    if (task.depth > this.maxDepthReached) {
      this.maxDepthReached = task.depth;
    }

    // Check if task should be decomposed
    if (this._shouldDecompose(task)) {
      return await this._decompose(node);
    } else {
      return await this._executeAtomic(node);
    }
  }

  /**
   * Determines if a task should be decomposed
   *
   * @private
   * @param {DecomposableTask} task - Task to check
   * @returns {boolean} True if task should be decomposed
   */
  _shouldDecompose(task) {
    // Don't decompose if already at max depth
    if (task.depth >= this.maxDepth) {
      this.logger(`[HierarchicalDecomposition] Max depth reached for task ${task.id}, treating as atomic`);
      return false;
    }

    // Don't decompose if task is atomic
    if (task.type === 'atomic') {
      return false;
    }

    // Don't decompose if complexity is below threshold
    if (task.complexity < this.complexityThreshold) {
      return false;
    }

    // Must have decomposer function
    if (typeof task.decomposer !== 'function') {
      this.logger(`[HierarchicalDecomposition] Task ${task.id} has no decomposer, treating as atomic`);
      return false;
    }

    return true;
  }

  /**
   * Decomposes a task into subtasks and executes them
   *
   * @private
   * @param {TaskNode} node - Task node to decompose
   * @returns {Promise<any>} Aggregated result
   */
  async _decompose(node) {
    const task = node.task;

    this.logger(`[HierarchicalDecomposition] Decomposing task: ${task.id} (depth: ${task.depth})`);
    node.status = 'decomposing';

    this.emit('task:decomposing', { task });

    try {
      // Execute decomposer to get subtasks
      const subtasks = await task.decomposer(task.context);

      if (!Array.isArray(subtasks) || subtasks.length === 0) {
        this.logger(`[HierarchicalDecomposition] Decomposer returned no subtasks for ${task.id}, treating as atomic`);
        return await this._executeAtomic(node);
      }

      this.logger(`[HierarchicalDecomposition] Task ${task.id} decomposed into ${subtasks.length} subtasks`);

      // Create child nodes
      for (const subtask of subtasks) {
        subtask.depth = task.depth + 1;
        const childNode = this._createTaskNode(subtask, node);
        node.children.push(childNode);
        this.taskNodes.set(subtask.id, childNode);
      }

      this.emit('task:decomposed', { task, subtasks });

      // Identify independent subtasks that can be parallelized
      const { parallel, sequential } = this._analyzeParallelization(node.children);

      this.logger(`[HierarchicalDecomposition] Parallelization analysis: ${parallel.length} parallel, ${sequential.length} sequential`);

      // Execute parallel tasks concurrently
      if (parallel.length > 0) {
        await this._executeParallel(parallel);
      }

      // Execute sequential tasks in order
      if (sequential.length > 0) {
        await this._executeSequential(sequential);
      }

      // Aggregate results from children
      const aggregatedResult = await this._aggregateResults(node);

      node.status = 'completed';
      node.result = aggregatedResult;

      this.emit('task:aggregated', { task, result: aggregatedResult });

      return aggregatedResult;

    } catch (error) {
      node.status = 'failed';
      node.error = error;
      throw error;
    }
  }

  /**
   * Executes an atomic task
   *
   * @private
   * @param {TaskNode} node - Task node to execute
   * @returns {Promise<any>} Task result
   */
  async _executeAtomic(node) {
    const task = node.task;

    this.logger(`[HierarchicalDecomposition] Executing atomic task: ${task.id}`);
    node.status = 'executing';

    this.emit('task:executing', { task });

    try {
      // Wait for concurrency slot
      await this._acquireConcurrencySlot(task.id);

      // Execute task
      const executor = task.executor || this._defaultExecutor;
      const result = await executor(task.context);

      this.totalTasksExecuted++;

      node.status = 'completed';
      node.result = result;

      this.emit('task:completed', { task, result });

      return result;

    } catch (error) {
      node.status = 'failed';
      node.error = error;

      this.emit('task:failed', { task, error });
      throw error;

    } finally {
      this._releaseConcurrencySlot(task.id);
    }
  }

  /**
   * Analyzes which tasks can be executed in parallel
   *
   * @private
   * @param {TaskNode[]} nodes - Task nodes to analyze
   * @returns {{parallel: TaskNode[], sequential: TaskNode[]}} Parallel and sequential task groups
   */
  _analyzeParallelization(nodes) {
    const parallel = [];
    const sequential = [];

    // Build dependency graph
    const dependencies = new Map();

    for (const node of nodes) {
      const task = node.task;
      dependencies.set(task.id, task.dependencies || []);
    }

    // Identify tasks with no dependencies (can run in parallel)
    for (const node of nodes) {
      const deps = dependencies.get(node.task.id);

      if (deps.length === 0) {
        parallel.push(node);
      } else {
        sequential.push(node);
      }
    }

    return { parallel, sequential };
  }

  /**
   * Executes tasks in parallel with concurrency control
   *
   * @private
   * @param {TaskNode[]} nodes - Task nodes to execute
   * @returns {Promise<void>}
   */
  async _executeParallel(nodes) {
    this.logger(`[HierarchicalDecomposition] Executing ${nodes.length} tasks in parallel`);

    const promises = nodes.map(node => this._decomposeAndExecute(node));
    await Promise.all(promises);
  }

  /**
   * Executes tasks sequentially
   *
   * @private
   * @param {TaskNode[]} nodes - Task nodes to execute
   * @returns {Promise<void>}
   */
  async _executeSequential(nodes) {
    this.logger(`[HierarchicalDecomposition] Executing ${nodes.length} tasks sequentially`);

    for (const node of nodes) {
      await this._decomposeAndExecute(node);
    }
  }

  /**
   * Aggregates results from child tasks
   *
   * @private
   * @param {TaskNode} node - Parent task node
   * @returns {Promise<any>} Aggregated result
   */
  async _aggregateResults(node) {
    const task = node.task;

    // Collect child results
    const childResults = node.children.map(child => ({
      id: child.task.id,
      name: child.task.name,
      result: child.result
    }));

    // Use custom aggregator if provided
    if (typeof task.aggregator === 'function') {
      return await task.aggregator(childResults, task.context);
    }

    // Default aggregation: return array of results
    return childResults;
  }

  /**
   * Collects all results from the task tree
   *
   * @private
   * @param {TaskNode} node - Root node
   * @returns {Map<string, any>} All task results
   */
  _collectResults(node) {
    const results = new Map();

    const traverse = (n) => {
      if (n.result !== undefined) {
        results.set(n.task.id, n.result);
      }

      for (const child of n.children) {
        traverse(child);
      }
    };

    traverse(node);

    return results;
  }

  /**
   * Acquires a concurrency slot
   *
   * @private
   * @param {string} taskId - Task ID
   * @returns {Promise<void>}
   */
  async _acquireConcurrencySlot(taskId) {
    while (this.executingTasks.size >= this.maxConcurrency) {
      await this._sleep(50);
    }

    this.executingTasks.add(taskId);
  }

  /**
   * Releases a concurrency slot
   *
   * @private
   * @param {string} taskId - Task ID
   */
  _releaseConcurrencySlot(taskId) {
    this.executingTasks.delete(taskId);
  }

  /**
   * Creates a task node
   *
   * @private
   * @param {DecomposableTask} task - Task
   * @param {TaskNode|null} parent - Parent node
   * @returns {TaskNode} Created node
   */
  _createTaskNode(task, parent) {
    return {
      task: { ...task, depth: task.depth || 0 },
      parent,
      children: [],
      status: 'pending',
      result: undefined,
      error: null
    };
  }

  /**
   * Default executor for atomic tasks
   *
   * @private
   * @param {Object} context - Task context
   * @returns {Promise<any>} Task result
   */
  async _defaultExecutor(context) {
    // Default implementation: just return the context
    return context;
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

  /**
   * Visualizes the task hierarchy
   *
   * @param {TaskNode} node - Root node
   * @param {string} [indent=''] - Current indentation
   * @returns {string} Tree visualization
   */
  visualizeTree(node, indent = '') {
    let output = `${indent}${node.task.name} (${node.status})`;

    if (node.children.length > 0) {
      output += `\n${indent}├─ Children (${node.children.length}):`;

      for (let i = 0; i < node.children.length; i++) {
        const child = node.children[i];
        const isLast = i === node.children.length - 1;
        const childIndent = indent + (isLast ? '   ' : '│  ');
        output += '\n' + this.visualizeTree(child, childIndent);
      }
    }

    return output;
  }
}

export default HierarchicalDecomposition;
