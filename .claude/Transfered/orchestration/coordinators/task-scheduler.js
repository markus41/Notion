/**
 * Task Scheduler
 *
 * Priority-based task scheduling with critical path scheduling,
 * resource-aware execution, and deadlock detection.
 *
 * @module orchestration/coordinators/task-scheduler
 */

import { EventEmitter } from 'events';

/**
 * @typedef {Object} ScheduledTask
 * @property {string} id - Task identifier
 * @property {string} name - Task name
 * @property {Function} executor - Task executor function
 * @property {number} priority - Task priority (higher = more important)
 * @property {string[]} dependencies - Dependent task IDs
 * @property {string[]} resourceRequirements - Required resources
 * @property {number} estimatedDuration - Estimated duration in ms
 * @property {Date} deadline - Task deadline
 * @property {string} status - Task status
 * @property {Date} scheduledAt - When task was scheduled
 * @property {Date} startedAt - When task started
 * @property {Date} completedAt - When task completed
 */

export class TaskScheduler extends EventEmitter {
  constructor(options = {}) {
    super();

    this.maxConcurrent = options.maxConcurrent || 10;
    this.enableCriticalPath = options.enableCriticalPath !== false;
    this.enableDeadlockDetection = options.enableDeadlockDetection !== false;
    this.deadlockCheckInterval = options.deadlockCheckInterval || 5000;
    this.logger = options.logger || console.log;

    /** @type {Map<string, ScheduledTask>} */
    this.tasks = new Map();

    /** @type {Map<string, Set<string>>} Available resources */
    this.resources = new Map();

    /** @type {Set<string>} Currently executing tasks */
    this.executing = new Set();

    /** @type {number[]} Priority queue (task IDs) */
    this.queue = [];

    this.isRunning = false;
    this.deadlockCheckTimer = null;
  }

  /**
   * Schedules a task for execution
   *
   * @param {ScheduledTask} task - Task to schedule
   * @returns {string} Task ID
   */
  schedule(task) {
    if (!task.id) {
      task.id = this._generateId();
    }

    task.status = 'pending';
    task.scheduledAt = new Date();
    task.startedAt = null;
    task.completedAt = null;

    this.tasks.set(task.id, task);

    // Add to priority queue
    this._enqueue(task.id);

    this.logger(`[TaskScheduler] Scheduled task: ${task.name} (priority: ${task.priority})`);
    this.emit('task:scheduled', { task });

    // Try to execute immediately
    this._tryExecute();

    return task.id;
  }

  /**
   * Cancels a scheduled task
   *
   * @param {string} taskId - Task ID
   * @returns {boolean} Success status
   */
  cancel(taskId) {
    const task = this.tasks.get(taskId);

    if (!task || task.status === 'completed') {
      return false;
    }

    if (task.status === 'running') {
      this.logger(`[TaskScheduler] Warning: Cannot cancel running task ${taskId}`);
      return false;
    }

    task.status = 'cancelled';

    // Remove from queue
    const index = this.queue.indexOf(taskId);
    if (index > -1) {
      this.queue.splice(index, 1);
    }

    this.emit('task:cancelled', { taskId });

    return true;
  }

  /**
   * Starts the scheduler
   */
  start() {
    if (this.isRunning) {
      return;
    }

    this.logger('[TaskScheduler] Starting...');

    this.isRunning = true;

    // Start deadlock detection
    if (this.enableDeadlockDetection) {
      this._startDeadlockDetection();
    }

    this.emit('scheduler:started');
  }

  /**
   * Stops the scheduler
   */
  stop() {
    if (!this.isRunning) {
      return;
    }

    this.logger('[TaskScheduler] Stopping...');

    this.isRunning = false;

    // Stop deadlock detection
    if (this.deadlockCheckTimer) {
      clearInterval(this.deadlockCheckTimer);
      this.deadlockCheckTimer = null;
    }

    this.emit('scheduler:stopped');
  }

  /**
   * Adds a task to priority queue
   *
   * @private
   * @param {string} taskId - Task ID
   */
  _enqueue(taskId) {
    this.queue.push(taskId);

    // Sort by priority (higher first), then by deadline
    this.queue.sort((a, b) => {
      const taskA = this.tasks.get(a);
      const taskB = this.tasks.get(b);

      // Priority first
      if (taskA.priority !== taskB.priority) {
        return taskB.priority - taskA.priority;
      }

      // Then deadline
      if (taskA.deadline && taskB.deadline) {
        return taskA.deadline.getTime() - taskB.deadline.getTime();
      }

      return 0;
    });

    // If critical path scheduling is enabled, reorder
    if (this.enableCriticalPath) {
      this._applyCriticalPathScheduling();
    }
  }

  /**
   * Applies critical path scheduling
   *
   * @private
   */
  _applyCriticalPathScheduling() {
    // Calculate critical path for each task
    const criticalPaths = new Map();

    for (const taskId of this.queue) {
      const path = this._calculateCriticalPath(taskId);
      criticalPaths.set(taskId, path);
    }

    // Sort by critical path length (longer paths first)
    this.queue.sort((a, b) => {
      const pathA = criticalPaths.get(a);
      const pathB = criticalPaths.get(b);

      return pathB - pathA;
    });
  }

  /**
   * Calculates critical path length for a task
   *
   * @private
   * @param {string} taskId - Task ID
   * @returns {number} Critical path length
   */
  _calculateCriticalPath(taskId) {
    const task = this.tasks.get(taskId);

    if (!task || !task.dependencies || task.dependencies.length === 0) {
      return task.estimatedDuration || 0;
    }

    let maxDependencyPath = 0;

    for (const depId of task.dependencies) {
      const depPath = this._calculateCriticalPath(depId);
      maxDependencyPath = Math.max(maxDependencyPath, depPath);
    }

    return (task.estimatedDuration || 0) + maxDependencyPath;
  }

  /**
   * Tries to execute pending tasks
   *
   * @private
   */
  async _tryExecute() {
    if (!this.isRunning) {
      return;
    }

    // Check if we can execute more tasks
    while (this.executing.size < this.maxConcurrent && this.queue.length > 0) {
      const taskId = this._findReadyTask();

      if (!taskId) {
        break;
      }

      await this._executeTask(taskId);
    }
  }

  /**
   * Finds next ready task from queue
   *
   * @private
   * @returns {string|null} Task ID or null
   */
  _findReadyTask() {
    for (let i = 0; i < this.queue.length; i++) {
      const taskId = this.queue[i];
      const task = this.tasks.get(taskId);

      if (!task || task.status !== 'pending') {
        continue;
      }

      // Check dependencies
      if (!this._areDependenciesSatisfied(task)) {
        continue;
      }

      // Check resources
      if (!this._areResourcesAvailable(task)) {
        continue;
      }

      // Found ready task
      this.queue.splice(i, 1);
      return taskId;
    }

    return null;
  }

  /**
   * Checks if task dependencies are satisfied
   *
   * @private
   * @param {ScheduledTask} task - Task to check
   * @returns {boolean} True if satisfied
   */
  _areDependenciesSatisfied(task) {
    if (!task.dependencies || task.dependencies.length === 0) {
      return true;
    }

    return task.dependencies.every(depId => {
      const dep = this.tasks.get(depId);
      return dep && dep.status === 'completed';
    });
  }

  /**
   * Checks if resources are available
   *
   * @private
   * @param {ScheduledTask} task - Task to check
   * @returns {boolean} True if available
   */
  _areResourcesAvailable(task) {
    if (!task.resourceRequirements || task.resourceRequirements.length === 0) {
      return true;
    }

    return task.resourceRequirements.every(resourceId => {
      const resource = this.resources.get(resourceId);
      return resource && resource.size > 0;
    });
  }

  /**
   * Executes a task
   *
   * @private
   * @param {string} taskId - Task ID
   */
  async _executeTask(taskId) {
    const task = this.tasks.get(taskId);

    if (!task) {
      return;
    }

    this.logger(`[TaskScheduler] Executing task: ${task.name}`);

    task.status = 'running';
    task.startedAt = new Date();

    this.executing.add(taskId);

    // Acquire resources
    this._acquireResources(task);

    this.emit('task:started', { task });

    try {
      const result = await task.executor();

      task.status = 'completed';
      task.completedAt = new Date();
      task.result = result;

      const duration = task.completedAt.getTime() - task.startedAt.getTime();

      this.emit('task:completed', { task, result, duration });

    } catch (error) {
      task.status = 'failed';
      task.completedAt = new Date();
      task.error = error;

      this.emit('task:failed', { task, error });

    } finally {
      // Release resources
      this._releaseResources(task);

      this.executing.delete(taskId);

      // Try to execute more tasks
      this._tryExecute();
    }
  }

  /**
   * Acquires resources for a task
   *
   * @private
   * @param {ScheduledTask} task - Task
   */
  _acquireResources(task) {
    if (!task.resourceRequirements) {
      return;
    }

    for (const resourceId of task.resourceRequirements) {
      const resource = this.resources.get(resourceId);
      if (resource) {
        resource.delete(task.id);
      }
    }
  }

  /**
   * Releases resources from a task
   *
   * @private
   * @param {ScheduledTask} task - Task
   */
  _releaseResources(task) {
    if (!task.resourceRequirements) {
      return;
    }

    for (const resourceId of task.resourceRequirements) {
      let resource = this.resources.get(resourceId);
      if (!resource) {
        resource = new Set();
        this.resources.set(resourceId, resource);
      }
      resource.add(task.id);
    }
  }

  /**
   * Starts deadlock detection
   *
   * @private
   */
  _startDeadlockDetection() {
    this.deadlockCheckTimer = setInterval(() => {
      this._checkForDeadlocks();
    }, this.deadlockCheckInterval);
  }

  /**
   * Checks for deadlocks in task dependencies
   *
   * @private
   */
  _checkForDeadlocks() {
    const pendingTasks = Array.from(this.tasks.values())
      .filter(t => t.status === 'pending');

    for (const task of pendingTasks) {
      if (this._hasCircularDependency(task.id, new Set())) {
        this.logger(`[TaskScheduler] Deadlock detected for task: ${task.id}`);

        this.emit('deadlock:detected', { taskId: task.id });

        // Resolve deadlock by cancelling task
        this.cancel(task.id);
      }
    }
  }

  /**
   * Checks for circular dependencies
   *
   * @private
   * @param {string} taskId - Task ID
   * @param {Set<string>} visited - Visited tasks
   * @returns {boolean} True if circular dependency exists
   */
  _hasCircularDependency(taskId, visited) {
    if (visited.has(taskId)) {
      return true;
    }

    const task = this.tasks.get(taskId);

    if (!task || !task.dependencies) {
      return false;
    }

    visited.add(taskId);

    for (const depId of task.dependencies) {
      if (this._hasCircularDependency(depId, new Set(visited))) {
        return true;
      }
    }

    return false;
  }

  /**
   * Gets scheduler statistics
   *
   * @returns {Object} Statistics
   */
  getStats() {
    const tasks = Array.from(this.tasks.values());

    return {
      totalTasks: tasks.length,
      pending: tasks.filter(t => t.status === 'pending').length,
      running: tasks.filter(t => t.status === 'running').length,
      completed: tasks.filter(t => t.status === 'completed').length,
      failed: tasks.filter(t => t.status === 'failed').length,
      cancelled: tasks.filter(t => t.status === 'cancelled').length,
      queueSize: this.queue.length,
      executing: this.executing.size,
      maxConcurrent: this.maxConcurrent
    };
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

export default TaskScheduler;
