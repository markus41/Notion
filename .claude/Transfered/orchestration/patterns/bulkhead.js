/**
 * Bulkhead Pattern
 *
 * Implements resource isolation with partitioned resource pools,
 * concurrent execution limits, and queue management.
 *
 * @module orchestration/patterns/bulkhead
 */

import { EventEmitter } from 'events';

/**
 * @typedef {Object} BulkheadConfig
 * @property {string} name - Bulkhead name
 * @property {number} maxConcurrent - Maximum concurrent executions (default: 10)
 * @property {number} maxQueueSize - Maximum queue size (default: 100)
 * @property {number} timeout - Execution timeout in ms (default: 30000)
 * @property {string} overflowStrategy - Strategy when queue is full (reject, drop-oldest, drop-newest)
 */

/**
 * @typedef {Object} BulkheadState
 * @property {number} activeExecutions - Current active executions
 * @property {number} queuedExecutions - Current queued executions
 * @property {number} totalExecuted - Total executions
 * @property {number} totalRejected - Total rejections
 * @property {number} totalTimeouts - Total timeouts
 */

/**
 * @typedef {Object} QueuedTask
 * @property {string} id - Task ID
 * @property {Function} fn - Function to execute
 * @property {any[]} args - Function arguments
 * @property {Function} resolve - Promise resolve function
 * @property {Function} reject - Promise reject function
 * @property {Date} enqueuedAt - Time task was enqueued
 */

export class Bulkhead extends EventEmitter {
  /**
   * Creates a new Bulkhead for resource isolation
   *
   * @param {BulkheadConfig} config - Bulkhead configuration
   * @param {Function} [logger] - Logger function
   */
  constructor(config, logger = console.log) {
    super();

    this.name = config.name || 'Bulkhead';
    this.maxConcurrent = config.maxConcurrent || 10;
    this.maxQueueSize = config.maxQueueSize || 100;
    this.timeout = config.timeout || 30000;
    this.overflowStrategy = config.overflowStrategy || 'reject';
    this.logger = logger;

    /** @type {BulkheadState} */
    this.state = {
      activeExecutions: 0,
      queuedExecutions: 0,
      totalExecuted: 0,
      totalRejected: 0,
      totalTimeouts: 0
    };

    /** @type {QueuedTask[]} */
    this.queue = [];

    /** @type {Set<string>} */
    this.activeTaskIds = new Set();
  }

  /**
   * Executes a function with bulkhead protection
   *
   * @param {Function} fn - Function to execute
   * @param {...any} args - Function arguments
   * @returns {Promise<any>} Function result
   */
  async execute(fn, ...args) {
    // Check if we can execute immediately
    if (this.state.activeExecutions < this.maxConcurrent) {
      return await this._executeImmediate(fn, args);
    }

    // Need to queue
    return await this._enqueue(fn, args);
  }

  /**
   * Wraps a function with bulkhead protection
   *
   * @param {Function} fn - Function to wrap
   * @returns {Function} Wrapped function
   */
  wrap(fn) {
    return async (...args) => {
      return await this.execute(fn, ...args);
    };
  }

  /**
   * Executes a function immediately
   *
   * @private
   * @param {Function} fn - Function to execute
   * @param {any[]} args - Function arguments
   * @returns {Promise<any>} Function result
   */
  async _executeImmediate(fn, args) {
    const taskId = this._generateId();

    this.state.activeExecutions++;
    this.activeTaskIds.add(taskId);

    this.logger(`[${this.name}] Executing task ${taskId} (active: ${this.state.activeExecutions}/${this.maxConcurrent})`);

    this.emit('task:started', {
      taskId,
      active: this.state.activeExecutions,
      queued: this.state.queuedExecutions
    });

    try {
      // Execute with timeout
      const result = await this._executeWithTimeout(fn(...args), this.timeout);

      this.state.totalExecuted++;

      this.emit('task:completed', {
        taskId,
        active: this.state.activeExecutions,
        queued: this.state.queuedExecutions
      });

      return result;

    } catch (error) {
      if (error.message === 'Execution timeout') {
        this.state.totalTimeouts++;
        this.emit('task:timeout', { taskId });
      }

      this.emit('task:failed', { taskId, error });
      throw error;

    } finally {
      this.state.activeExecutions--;
      this.activeTaskIds.delete(taskId);

      // Process next queued task
      this._processQueue();
    }
  }

  /**
   * Enqueues a task for later execution
   *
   * @private
   * @param {Function} fn - Function to execute
   * @param {any[]} args - Function arguments
   * @returns {Promise<any>} Function result
   */
  async _enqueue(fn, args) {
    // Check if queue is full
    if (this.state.queuedExecutions >= this.maxQueueSize) {
      return await this._handleOverflow(fn, args);
    }

    return new Promise((resolve, reject) => {
      const task = {
        id: this._generateId(),
        fn,
        args,
        resolve,
        reject,
        enqueuedAt: new Date()
      };

      this.queue.push(task);
      this.state.queuedExecutions++;

      this.logger(`[${this.name}] Task ${task.id} enqueued (queue: ${this.state.queuedExecutions}/${this.maxQueueSize})`);

      this.emit('task:enqueued', {
        taskId: task.id,
        queueSize: this.state.queuedExecutions,
        maxQueueSize: this.maxQueueSize
      });
    });
  }

  /**
   * Handles overflow when queue is full
   *
   * @private
   * @param {Function} fn - Function to execute
   * @param {any[]} args - Function arguments
   * @returns {Promise<any>} Function result
   */
  async _handleOverflow(fn, args) {
    this.logger(`[${this.name}] Queue overflow (strategy: ${this.overflowStrategy})`);

    if (this.overflowStrategy === 'reject') {
      this.state.totalRejected++;
      this.emit('task:rejected', { reason: 'queue_full' });
      throw new Error('Bulkhead queue is full');

    } else if (this.overflowStrategy === 'drop-oldest') {
      // Remove oldest task and reject it
      const oldest = this.queue.shift();

      if (oldest) {
        this.state.queuedExecutions--;
        oldest.reject(new Error('Dropped from queue (oldest)'));

        this.emit('task:dropped', { taskId: oldest.id, reason: 'oldest' });
      }

      // Enqueue new task
      return await this._enqueue(fn, args);

    } else if (this.overflowStrategy === 'drop-newest') {
      // Reject the new task
      this.state.totalRejected++;
      this.emit('task:rejected', { reason: 'drop_newest' });
      throw new Error('Task dropped (newest)');

    } else {
      throw new Error(`Unknown overflow strategy: ${this.overflowStrategy}`);
    }
  }

  /**
   * Processes the next task in queue
   *
   * @private
   */
  _processQueue() {
    if (this.queue.length === 0 || this.state.activeExecutions >= this.maxConcurrent) {
      return;
    }

    const task = this.queue.shift();

    if (!task) {
      return;
    }

    this.state.queuedExecutions--;

    this.logger(`[${this.name}] Processing queued task ${task.id} (queue: ${this.state.queuedExecutions})`);

    this.emit('task:dequeued', {
      taskId: task.id,
      waitTime: Date.now() - task.enqueuedAt.getTime(),
      queueSize: this.state.queuedExecutions
    });

    // Execute the task
    this._executeImmediate(task.fn, task.args)
      .then(task.resolve)
      .catch(task.reject);
  }

  /**
   * Executes a promise with timeout
   *
   * @private
   * @param {Promise} promise - Promise to execute
   * @param {number} timeout - Timeout in milliseconds
   * @returns {Promise<any>} Result
   */
  async _executeWithTimeout(promise, timeout) {
    return Promise.race([
      promise,
      new Promise((_, reject) =>
        setTimeout(() => reject(new Error('Execution timeout')), timeout)
      )
    ]);
  }

  /**
   * Gets current state
   *
   * @returns {BulkheadState} Current state
   */
  getState() {
    return { ...this.state };
  }

  /**
   * Gets statistics
   *
   * @returns {Object} Statistics
   */
  getStats() {
    const utilizationRate = (this.state.activeExecutions / this.maxConcurrent) * 100;
    const queueUtilizationRate = (this.state.queuedExecutions / this.maxQueueSize) * 100;

    const totalProcessed = this.state.totalExecuted + this.state.totalRejected + this.state.totalTimeouts;
    const successRate = totalProcessed > 0
      ? (this.state.totalExecuted / totalProcessed) * 100
      : 0;

    return {
      name: this.name,
      activeExecutions: this.state.activeExecutions,
      maxConcurrent: this.maxConcurrent,
      utilizationRate: utilizationRate.toFixed(2) + '%',
      queuedExecutions: this.state.queuedExecutions,
      maxQueueSize: this.maxQueueSize,
      queueUtilizationRate: queueUtilizationRate.toFixed(2) + '%',
      totalExecuted: this.state.totalExecuted,
      totalRejected: this.state.totalRejected,
      totalTimeouts: this.state.totalTimeouts,
      successRate: successRate.toFixed(2) + '%'
    };
  }

  /**
   * Checks if bulkhead is saturated
   *
   * @returns {boolean} True if saturated
   */
  isSaturated() {
    return this.state.activeExecutions >= this.maxConcurrent &&
           this.state.queuedExecutions >= this.maxQueueSize;
  }

  /**
   * Checks if bulkhead is healthy
   *
   * @returns {boolean} True if healthy
   */
  isHealthy() {
    const utilizationRate = (this.state.activeExecutions / this.maxConcurrent);
    const queueUtilizationRate = (this.state.queuedExecutions / this.maxQueueSize);

    // Healthy if under 80% utilization
    return utilizationRate < 0.8 && queueUtilizationRate < 0.8;
  }

  /**
   * Clears the queue
   *
   * @param {string} [reason='manual_clear'] - Reason for clearing
   */
  clearQueue(reason = 'manual_clear') {
    this.logger(`[${this.name}] Clearing queue (${this.queue.length} tasks)`);

    for (const task of this.queue) {
      task.reject(new Error(`Queue cleared: ${reason}`));
    }

    this.queue = [];
    this.state.queuedExecutions = 0;

    this.emit('queue:cleared', { reason });
  }

  /**
   * Resets statistics
   */
  resetStats() {
    this.logger(`[${this.name}] Resetting statistics`);

    this.state.totalExecuted = 0;
    this.state.totalRejected = 0;
    this.state.totalTimeouts = 0;

    this.emit('stats:reset');
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
}

/**
 * Bulkhead Manager
 *
 * Manages multiple bulkhead pools
 */
export class BulkheadManager extends EventEmitter {
  constructor(logger = console.log) {
    super();

    this.logger = logger;

    /** @type {Map<string, Bulkhead>} */
    this.bulkheads = new Map();
  }

  /**
   * Creates or gets a bulkhead
   *
   * @param {string} name - Bulkhead name
   * @param {BulkheadConfig} [config] - Configuration
   * @returns {Bulkhead} Bulkhead instance
   */
  getBulkhead(name, config = {}) {
    if (!this.bulkheads.has(name)) {
      const bulkhead = new Bulkhead({ ...config, name }, this.logger);

      // Forward events
      bulkhead.on('task:rejected', (data) => {
        this.emit('bulkhead:task:rejected', { name, ...data });
      });

      bulkhead.on('task:timeout', (data) => {
        this.emit('bulkhead:task:timeout', { name, ...data });
      });

      this.bulkheads.set(name, bulkhead);

      this.logger(`[BulkheadManager] Created bulkhead: ${name}`);
    }

    return this.bulkheads.get(name);
  }

  /**
   * Removes a bulkhead
   *
   * @param {string} name - Bulkhead name
   * @returns {boolean} Success status
   */
  removeBulkhead(name) {
    const bulkhead = this.bulkheads.get(name);

    if (bulkhead) {
      bulkhead.clearQueue('bulkhead_removed');
    }

    return this.bulkheads.delete(name);
  }

  /**
   * Gets all bulkheads
   *
   * @returns {Map<string, Bulkhead>} All bulkheads
   */
  getAllBulkheads() {
    return new Map(this.bulkheads);
  }

  /**
   * Gets health status of all bulkheads
   *
   * @returns {Object} Health status
   */
  getHealth() {
    const health = {
      healthy: [],
      degraded: [],
      saturated: []
    };

    for (const [name, bulkhead] of this.bulkheads) {
      if (bulkhead.isSaturated()) {
        health.saturated.push(name);
      } else if (bulkhead.isHealthy()) {
        health.healthy.push(name);
      } else {
        health.degraded.push(name);
      }
    }

    return health;
  }

  /**
   * Gets statistics for all bulkheads
   *
   * @returns {Object} Statistics
   */
  getStats() {
    const stats = {};

    for (const [name, bulkhead] of this.bulkheads) {
      stats[name] = bulkhead.getStats();
    }

    return stats;
  }

  /**
   * Clears all queues
   *
   * @param {string} [reason='manual_clear'] - Reason for clearing
   */
  clearAllQueues(reason = 'manual_clear') {
    this.logger(`[BulkheadManager] Clearing all queues`);

    for (const bulkhead of this.bulkheads.values()) {
      bulkhead.clearQueue(reason);
    }
  }

  /**
   * Resets all statistics
   */
  resetAllStats() {
    this.logger(`[BulkheadManager] Resetting all statistics`);

    for (const bulkhead of this.bulkheads.values()) {
      bulkhead.resetStats();
    }
  }
}

export default Bulkhead;
