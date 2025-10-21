/**
 * Saga Pattern
 *
 * Implements distributed transaction management with compensating transactions,
 * supporting both choreography and orchestration modes.
 *
 * @module orchestration/patterns/saga-pattern
 */

import { EventEmitter } from 'events';

/**
 * @typedef {Object} SagaStep
 * @property {string} id - Step identifier
 * @property {string} name - Step name
 * @property {Function} transaction - Forward transaction function
 * @property {Function} compensation - Compensating transaction function
 * @property {number} timeout - Step timeout in milliseconds
 * @property {number} maxRetries - Maximum retry attempts
 * @property {boolean} critical - Whether this step is critical (cannot be compensated)
 */

/**
 * @typedef {Object} SagaDefinition
 * @property {string} id - Saga identifier
 * @property {string} name - Saga name
 * @property {string} mode - Execution mode ('orchestration' or 'choreography')
 * @property {SagaStep[]} steps - Saga steps
 * @property {Object} context - Execution context
 * @property {boolean} forwardRecovery - Enable forward recovery on failures
 */

/**
 * @typedef {Object} SagaExecution
 * @property {string} sagaId - Saga ID
 * @property {string} executionId - Unique execution ID
 * @property {string} status - Execution status
 * @property {Map<string, any>} stepResults - Results of completed steps
 * @property {Map<string, string>} stepStatus - Status of each step
 * @property {Date} startedAt - Execution start time
 * @property {Date} completedAt - Execution completion time
 * @property {Error|null} error - Error if failed
 */

export class SagaPattern extends EventEmitter {
  /**
   * Creates a new Saga Pattern orchestrator
   *
   * @param {Object} options - Configuration options
   * @param {string} [options.defaultMode='orchestration'] - Default execution mode
   * @param {number} [options.defaultTimeout=30000] - Default step timeout
   * @param {number} [options.defaultMaxRetries=3] - Default max retries
   * @param {boolean} [options.enableForwardRecovery=true] - Enable forward recovery
   * @param {Function} [options.logger] - Logger function
   */
  constructor(options = {}) {
    super();

    this.defaultMode = options.defaultMode || 'orchestration';
    this.defaultTimeout = options.defaultTimeout || 30000;
    this.defaultMaxRetries = options.defaultMaxRetries || 3;
    this.enableForwardRecovery = options.enableForwardRecovery !== false;
    this.logger = options.logger || console.log;

    /** @type {Map<string, SagaDefinition>} */
    this.sagas = new Map();

    /** @type {Map<string, SagaExecution>} */
    this.executions = new Map();
  }

  /**
   * Registers a saga definition
   *
   * @param {SagaDefinition} saga - Saga to register
   */
  registerSaga(saga) {
    this._validateSaga(saga);

    // Set defaults for steps
    for (const step of saga.steps) {
      step.timeout = step.timeout || this.defaultTimeout;
      step.maxRetries = step.maxRetries !== undefined ? step.maxRetries : this.defaultMaxRetries;
      step.critical = step.critical || false;
    }

    this.sagas.set(saga.id, saga);

    this.logger(`[SagaPattern] Registered saga: ${saga.name} (${saga.mode})`);
    this.emit('saga:registered', { saga });
  }

  /**
   * Executes a saga
   *
   * @param {string} sagaId - Saga ID to execute
   * @param {Object} [context={}] - Execution context
   * @returns {Promise<SagaExecution>} Execution result
   */
  async execute(sagaId, context = {}) {
    const saga = this.sagas.get(sagaId);

    if (!saga) {
      throw new Error(`Saga not found: ${sagaId}`);
    }

    const executionId = this._generateId();

    this.logger(`[SagaPattern] Starting saga execution: ${saga.name} (${executionId})`);

    const execution = {
      sagaId,
      executionId,
      status: 'running',
      stepResults: new Map(),
      stepStatus: new Map(),
      startedAt: new Date(),
      completedAt: null,
      error: null
    };

    this.executions.set(executionId, execution);

    // Initialize step statuses
    for (const step of saga.steps) {
      execution.stepStatus.set(step.id, 'pending');
    }

    this.emit('saga:started', { saga, execution });

    try {
      // Execute based on mode
      if (saga.mode === 'orchestration') {
        await this._executeOrchestration(saga, execution, context);
      } else if (saga.mode === 'choreography') {
        await this._executeChoreography(saga, execution, context);
      } else {
        throw new Error(`Unknown saga mode: ${saga.mode}`);
      }

      execution.status = 'completed';
      execution.completedAt = new Date();

      this.logger(`[SagaPattern] Saga completed: ${saga.name}`);
      this.emit('saga:completed', { saga, execution });

      return execution;

    } catch (error) {
      this.logger(`[SagaPattern] Saga failed: ${saga.name} - ${error.message}`);

      execution.status = 'failed';
      execution.error = error;
      execution.completedAt = new Date();

      this.emit('saga:failed', { saga, execution, error });

      // Attempt compensation
      await this._compensate(saga, execution, context);

      throw error;
    }
  }

  /**
   * Executes saga in orchestration mode
   *
   * @private
   * @param {SagaDefinition} saga - Saga definition
   * @param {SagaExecution} execution - Execution state
   * @param {Object} context - Execution context
   */
  async _executeOrchestration(saga, execution, context) {
    this.logger(`[SagaPattern] Executing saga in orchestration mode`);

    const executionContext = { ...saga.context, ...context };

    for (let i = 0; i < saga.steps.length; i++) {
      const step = saga.steps[i];

      try {
        const result = await this._executeStep(step, executionContext, execution);

        execution.stepResults.set(step.id, result);
        execution.stepStatus.set(step.id, 'completed');

        // Update context with result
        executionContext[step.id] = result;

      } catch (error) {
        execution.stepStatus.set(step.id, 'failed');

        // Try forward recovery if enabled
        if (saga.forwardRecovery && this.enableForwardRecovery) {
          this.logger(`[SagaPattern] Attempting forward recovery for step: ${step.name}`);

          const recovered = await this._attemptForwardRecovery(step, executionContext, execution, error);

          if (recovered) {
            execution.stepResults.set(step.id, recovered);
            execution.stepStatus.set(step.id, 'completed');
            executionContext[step.id] = recovered;
            continue;
          }
        }

        // Forward recovery failed or not enabled, compensate
        throw error;
      }
    }
  }

  /**
   * Executes saga in choreography mode
   *
   * @private
   * @param {SagaDefinition} saga - Saga definition
   * @param {SagaExecution} execution - Execution state
   * @param {Object} context - Execution context
   */
  async _executeChoreography(saga, execution, context) {
    this.logger(`[SagaPattern] Executing saga in choreography mode`);

    const executionContext = { ...saga.context, ...context };

    // In choreography mode, steps are executed based on events
    // Each step publishes events that trigger the next step

    for (const step of saga.steps) {
      try {
        const result = await this._executeStep(step, executionContext, execution);

        execution.stepResults.set(step.id, result);
        execution.stepStatus.set(step.id, 'completed');

        executionContext[step.id] = result;

        // Emit event for next step
        this.emit('step:completed', {
          sagaId: saga.id,
          executionId: execution.executionId,
          stepId: step.id,
          result
        });

      } catch (error) {
        execution.stepStatus.set(step.id, 'failed');

        // Emit failure event
        this.emit('step:failed', {
          sagaId: saga.id,
          executionId: execution.executionId,
          stepId: step.id,
          error
        });

        throw error;
      }
    }
  }

  /**
   * Executes a single step with retries and timeout
   *
   * @private
   * @param {SagaStep} step - Step to execute
   * @param {Object} context - Execution context
   * @param {SagaExecution} execution - Execution state
   * @returns {Promise<any>} Step result
   */
  async _executeStep(step, context, execution) {
    this.logger(`[SagaPattern] Executing step: ${step.name}`);

    execution.stepStatus.set(step.id, 'running');
    this.emit('step:started', { step, context });

    let lastError;

    for (let attempt = 1; attempt <= step.maxRetries; attempt++) {
      try {
        // Execute with timeout
        const result = await this._executeWithTimeout(
          step.transaction(context),
          step.timeout
        );

        this.emit('step:succeeded', { step, result });

        return result;

      } catch (error) {
        lastError = error;

        this.logger(`[SagaPattern] Step ${step.name} failed (attempt ${attempt}/${step.maxRetries}): ${error.message}`);

        if (attempt < step.maxRetries) {
          // Exponential backoff
          const backoff = Math.pow(2, attempt) * 1000;
          await this._sleep(backoff);
        }
      }
    }

    throw lastError;
  }

  /**
   * Attempts forward recovery for a failed step
   *
   * @private
   * @param {SagaStep} step - Failed step
   * @param {Object} context - Execution context
   * @param {SagaExecution} execution - Execution state
   * @param {Error} error - Original error
   * @returns {Promise<any|null>} Recovery result or null if failed
   */
  async _attemptForwardRecovery(step, context, execution, error) {
    try {
      // If step has a recovery function, use it
      if (typeof step.recovery === 'function') {
        const result = await step.recovery(context, error);
        this.logger(`[SagaPattern] Forward recovery succeeded for step: ${step.name}`);
        this.emit('step:recovered', { step, result });
        return result;
      }

      // Otherwise, try re-executing with modified context
      const recoveryContext = {
        ...context,
        _recovery: true,
        _originalError: error
      };

      const result = await this._executeWithTimeout(
        step.transaction(recoveryContext),
        step.timeout
      );

      this.logger(`[SagaPattern] Forward recovery succeeded for step: ${step.name}`);
      this.emit('step:recovered', { step, result });

      return result;

    } catch (recoveryError) {
      this.logger(`[SagaPattern] Forward recovery failed for step: ${step.name}`);
      return null;
    }
  }

  /**
   * Compensates completed steps in reverse order
   *
   * @private
   * @param {SagaDefinition} saga - Saga definition
   * @param {SagaExecution} execution - Execution state
   * @param {Object} context - Execution context
   */
  async _compensate(saga, execution, context) {
    this.logger(`[SagaPattern] Starting compensation for saga: ${saga.name}`);

    execution.status = 'compensating';
    this.emit('saga:compensating', { saga, execution });

    const executionContext = { ...saga.context, ...context };

    // Get completed steps in reverse order
    const completedSteps = saga.steps.filter(step =>
      execution.stepStatus.get(step.id) === 'completed'
    ).reverse();

    for (const step of completedSteps) {
      // Skip critical steps (cannot be compensated)
      if (step.critical) {
        this.logger(`[SagaPattern] Skipping critical step compensation: ${step.name}`);
        continue;
      }

      if (typeof step.compensation !== 'function') {
        this.logger(`[SagaPattern] No compensation function for step: ${step.name}`);
        continue;
      }

      try {
        this.logger(`[SagaPattern] Compensating step: ${step.name}`);

        execution.stepStatus.set(step.id, 'compensating');

        const stepResult = execution.stepResults.get(step.id);
        const compensationContext = {
          ...executionContext,
          _stepResult: stepResult
        };

        await this._executeWithTimeout(
          step.compensation(compensationContext),
          step.timeout
        );

        execution.stepStatus.set(step.id, 'compensated');

        this.emit('step:compensated', { step });

      } catch (error) {
        this.logger(`[SagaPattern] Compensation failed for step ${step.name}: ${error.message}`);

        execution.stepStatus.set(step.id, 'compensation_failed');

        this.emit('step:compensation_failed', { step, error });

        // Continue compensating other steps even if one fails
      }
    }

    execution.status = 'compensated';
    this.emit('saga:compensated', { saga, execution });
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
        setTimeout(() => reject(new Error('Step timeout exceeded')), timeout)
      )
    ]);
  }

  /**
   * Gets execution status
   *
   * @param {string} executionId - Execution ID
   * @returns {SagaExecution|null} Execution state
   */
  getExecution(executionId) {
    return this.executions.get(executionId);
  }

  /**
   * Gets all executions for a saga
   *
   * @param {string} sagaId - Saga ID
   * @returns {SagaExecution[]} Executions
   */
  getSagaExecutions(sagaId) {
    return Array.from(this.executions.values()).filter(e => e.sagaId === sagaId);
  }

  /**
   * Cancels a running saga execution
   *
   * @param {string} executionId - Execution ID
   * @returns {Promise<boolean>} Success status
   */
  async cancel(executionId) {
    const execution = this.executions.get(executionId);

    if (!execution || execution.status !== 'running') {
      return false;
    }

    this.logger(`[SagaPattern] Cancelling execution: ${executionId}`);

    const saga = this.sagas.get(execution.sagaId);

    execution.status = 'cancelled';
    execution.completedAt = new Date();

    this.emit('saga:cancelled', { saga, execution });

    // Compensate completed steps
    await this._compensate(saga, execution, {});

    return true;
  }

  /**
   * Validates a saga definition
   *
   * @private
   * @param {SagaDefinition} saga - Saga to validate
   * @throws {Error} If validation fails
   */
  _validateSaga(saga) {
    if (!saga.id || !saga.name || !saga.steps) {
      throw new Error('Saga must have id, name, and steps');
    }

    if (!Array.isArray(saga.steps) || saga.steps.length === 0) {
      throw new Error('Saga must have at least one step');
    }

    for (const step of saga.steps) {
      if (!step.id || !step.name) {
        throw new Error('Step must have id and name');
      }

      if (typeof step.transaction !== 'function') {
        throw new Error(`Step ${step.id} must have transaction function`);
      }

      if (!step.critical && typeof step.compensation !== 'function') {
        this.logger(`[SagaPattern] Warning: Step ${step.id} has no compensation function and is not critical`);
      }
    }

    if (!['orchestration', 'choreography'].includes(saga.mode)) {
      throw new Error('Saga mode must be "orchestration" or "choreography"');
    }
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
   * Generates a unique ID
   *
   * @private
   * @returns {string} Unique ID
   */
  _generateId() {
    return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * Gets saga statistics
   *
   * @returns {Object} Statistics
   */
  getStats() {
    const executions = Array.from(this.executions.values());

    return {
      sagas: this.sagas.size,
      totalExecutions: executions.length,
      runningExecutions: executions.filter(e => e.status === 'running').length,
      completedExecutions: executions.filter(e => e.status === 'completed').length,
      failedExecutions: executions.filter(e => e.status === 'failed').length,
      compensatedExecutions: executions.filter(e => e.status === 'compensated').length
    };
  }
}

export default SagaPattern;
