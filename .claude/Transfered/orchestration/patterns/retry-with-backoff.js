/**
 * Retry with Backoff Pattern
 *
 * Implements intelligent retry logic with exponential backoff, jitter,
 * idempotency validation, and circuit breaker integration.
 *
 * @module orchestration/patterns/retry-with-backoff
 */

import { EventEmitter } from 'events';

/**
 * @typedef {Object} RetryConfig
 * @property {string} name - Retry policy name
 * @property {number} maxRetries - Maximum retry attempts (default: 3)
 * @property {number} initialDelay - Initial delay in ms (default: 1000)
 * @property {number} maxDelay - Maximum delay in ms (default: 30000)
 * @property {number} backoffMultiplier - Backoff multiplier (default: 2)
 * @property {boolean} useJitter - Use jitter to prevent thundering herd (default: true)
 * @property {number} jitterFactor - Jitter factor 0-1 (default: 0.1)
 * @property {Function} [retryableErrors] - Function to determine if error is retryable
 * @property {Function} [onRetry] - Callback before each retry
 * @property {Function} [validateIdempotency] - Function to validate idempotency
 * @property {Object} [circuitBreaker] - Circuit breaker integration
 */

/**
 * @typedef {Object} RetryState
 * @property {number} attempt - Current attempt number
 * @property {number} totalAttempts - Total attempts made
 * @property {number} successfulRetries - Successful retries
 * @property {number} failedRetries - Failed retries
 * @property {number} totalDelay - Total delay time accumulated
 * @property {Date|null} lastAttemptTime - Time of last attempt
 * @property {Error|null} lastError - Last error encountered
 */

export class RetryWithBackoff extends EventEmitter {
  /**
   * Creates a new Retry with Backoff policy
   *
   * @param {RetryConfig} config - Retry configuration
   * @param {Function} [logger] - Logger function
   */
  constructor(config = {}, logger = console.log) {
    super();

    this.name = config.name || 'RetryPolicy';
    this.maxRetries = config.maxRetries !== undefined ? config.maxRetries : 3;
    this.initialDelay = config.initialDelay || 1000;
    this.maxDelay = config.maxDelay || 30000;
    this.backoffMultiplier = config.backoffMultiplier || 2;
    this.useJitter = config.useJitter !== false;
    this.jitterFactor = config.jitterFactor || 0.1;
    this.retryableErrors = config.retryableErrors || this._defaultRetryableErrors.bind(this);
    this.onRetry = config.onRetry || null;
    this.validateIdempotency = config.validateIdempotency || null;
    this.circuitBreaker = config.circuitBreaker || null;
    this.logger = logger;

    /** @type {RetryState} */
    this.state = {
      attempt: 0,
      totalAttempts: 0,
      successfulRetries: 0,
      failedRetries: 0,
      totalDelay: 0,
      lastAttemptTime: null,
      lastError: null
    };
  }

  /**
   * Executes a function with retry logic
   *
   * @param {Function} fn - Function to execute
   * @param {...any} args - Function arguments
   * @returns {Promise<any>} Function result
   */
  async execute(fn, ...args) {
    this.state.attempt = 0;

    let lastError;

    while (this.state.attempt <= this.maxRetries) {
      this.state.attempt++;
      this.state.totalAttempts++;
      this.state.lastAttemptTime = new Date();

      try {
        // Validate idempotency before retry
        if (this.state.attempt > 1 && this.validateIdempotency) {
          const isIdempotent = await this.validateIdempotency(fn, args);

          if (!isIdempotent) {
            this.logger(`[${this.name}] Idempotency check failed, aborting retry`);
            throw new Error('Operation is not idempotent, cannot retry safely');
          }
        }

        // Check circuit breaker if integrated
        if (this.circuitBreaker && this.circuitBreaker.isOpen()) {
          throw new Error('Circuit breaker is open');
        }

        this.logger(`[${this.name}] Attempt ${this.state.attempt}/${this.maxRetries + 1}`);

        this.emit('attempt:started', {
          attempt: this.state.attempt,
          maxRetries: this.maxRetries
        });

        const result = await fn(...args);

        // Success
        if (this.state.attempt > 1) {
          this.state.successfulRetries++;
          this.emit('retry:succeeded', {
            attempt: this.state.attempt,
            totalDelay: this.state.totalDelay
          });
        }

        this.emit('attempt:succeeded', { attempt: this.state.attempt, result });

        return result;

      } catch (error) {
        lastError = error;
        this.state.lastError = error;

        this.logger(`[${this.name}] Attempt ${this.state.attempt} failed: ${error.message}`);

        this.emit('attempt:failed', {
          attempt: this.state.attempt,
          error,
          willRetry: this.state.attempt <= this.maxRetries
        });

        // Check if error is retryable
        const isRetryable = await this.retryableErrors(error);

        if (!isRetryable) {
          this.logger(`[${this.name}] Error is not retryable, aborting`);
          this.state.failedRetries++;
          throw error;
        }

        // No more retries left
        if (this.state.attempt > this.maxRetries) {
          this.state.failedRetries++;
          this.emit('retry:exhausted', {
            attempts: this.state.attempt,
            error
          });
          break;
        }

        // Calculate delay for next attempt
        const delay = this._calculateDelay(this.state.attempt);
        this.state.totalDelay += delay;

        this.logger(`[${this.name}] Retrying in ${delay}ms...`);

        this.emit('retry:scheduled', {
          attempt: this.state.attempt + 1,
          delay,
          error
        });

        // Execute onRetry callback if provided
        if (this.onRetry) {
          try {
            await this.onRetry(this.state.attempt, error, delay);
          } catch (callbackError) {
            this.logger(`[${this.name}] onRetry callback failed: ${callbackError.message}`);
          }
        }

        // Wait before retry
        await this._sleep(delay);
      }
    }

    // All retries exhausted
    throw lastError;
  }

  /**
   * Wraps a function with retry logic
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
   * Calculates delay for next retry attempt
   *
   * @private
   * @param {number} attempt - Current attempt number
   * @returns {number} Delay in milliseconds
   */
  _calculateDelay(attempt) {
    // Exponential backoff: initialDelay * (backoffMultiplier ^ (attempt - 1))
    let delay = this.initialDelay * Math.pow(this.backoffMultiplier, attempt - 1);

    // Cap at max delay
    delay = Math.min(delay, this.maxDelay);

    // Add jitter if enabled
    if (this.useJitter) {
      delay = this._addJitter(delay);
    }

    return Math.floor(delay);
  }

  /**
   * Adds jitter to delay to prevent thundering herd
   *
   * @private
   * @param {number} delay - Base delay
   * @returns {number} Delay with jitter
   */
  _addJitter(delay) {
    // Random jitter: delay * (1 ± jitterFactor * random())
    const jitter = delay * this.jitterFactor * (Math.random() * 2 - 1);
    return delay + jitter;
  }

  /**
   * Default retryable errors check
   *
   * @private
   * @param {Error} error - Error to check
   * @returns {boolean} True if error is retryable
   */
  _defaultRetryableErrors(error) {
    // Retry on network errors, timeouts, and 5xx server errors
    const retryableMessages = [
      'timeout',
      'ETIMEDOUT',
      'ECONNREFUSED',
      'ECONNRESET',
      'ENOTFOUND',
      'Network',
      '5'  // 5xx errors
    ];

    const errorString = error.toString().toLowerCase();

    return retryableMessages.some(msg =>
      errorString.includes(msg.toLowerCase())
    );
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
   * Gets current state
   *
   * @returns {RetryState} Current state
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
    const successRate = this.state.totalAttempts > 0
      ? ((this.state.totalAttempts - this.state.failedRetries) / this.state.totalAttempts) * 100
      : 0;

    const retryRate = this.state.totalAttempts > 0
      ? ((this.state.successfulRetries + this.state.failedRetries) / this.state.totalAttempts) * 100
      : 0;

    return {
      name: this.name,
      totalAttempts: this.state.totalAttempts,
      successfulRetries: this.state.successfulRetries,
      failedRetries: this.state.failedRetries,
      successRate: successRate.toFixed(2) + '%',
      retryRate: retryRate.toFixed(2) + '%',
      totalDelay: this.state.totalDelay,
      averageDelay: this.state.successfulRetries > 0
        ? Math.floor(this.state.totalDelay / this.state.successfulRetries)
        : 0,
      lastAttemptTime: this.state.lastAttemptTime,
      lastError: this.state.lastError?.message || null
    };
  }

  /**
   * Resets statistics
   */
  resetStats() {
    this.logger(`[${this.name}] Resetting statistics`);

    this.state = {
      attempt: 0,
      totalAttempts: 0,
      successfulRetries: 0,
      failedRetries: 0,
      totalDelay: 0,
      lastAttemptTime: null,
      lastError: null
    };

    this.emit('stats:reset');
  }
}

/**
 * Retry Policy Manager
 *
 * Manages multiple retry policies
 */
export class RetryPolicyManager extends EventEmitter {
  constructor(logger = console.log) {
    super();

    this.logger = logger;

    /** @type {Map<string, RetryWithBackoff>} */
    this.policies = new Map();
  }

  /**
   * Creates or gets a retry policy
   *
   * @param {string} name - Policy name
   * @param {RetryConfig} [config] - Configuration
   * @returns {RetryWithBackoff} Retry policy instance
   */
  getPolicy(name, config = {}) {
    if (!this.policies.has(name)) {
      const policy = new RetryWithBackoff({ ...config, name }, this.logger);

      // Forward events
      policy.on('retry:exhausted', (data) => {
        this.emit('policy:retry:exhausted', { name, ...data });
      });

      policy.on('retry:succeeded', (data) => {
        this.emit('policy:retry:succeeded', { name, ...data });
      });

      this.policies.set(name, policy);

      this.logger(`[RetryPolicyManager] Created retry policy: ${name}`);
    }

    return this.policies.get(name);
  }

  /**
   * Removes a retry policy
   *
   * @param {string} name - Policy name
   * @returns {boolean} Success status
   */
  removePolicy(name) {
    return this.policies.delete(name);
  }

  /**
   * Gets all retry policies
   *
   * @returns {Map<string, RetryWithBackoff>} All policies
   */
  getAllPolicies() {
    return new Map(this.policies);
  }

  /**
   * Gets statistics for all policies
   *
   * @returns {Object} Statistics
   */
  getStats() {
    const stats = {};

    for (const [name, policy] of this.policies) {
      stats[name] = policy.getStats();
    }

    return stats;
  }

  /**
   * Resets all statistics
   */
  resetAllStats() {
    this.logger(`[RetryPolicyManager] Resetting all statistics`);

    for (const policy of this.policies.values()) {
      policy.resetStats();
    }
  }
}

/**
 * Retry utilities
 */
export const RetryUtils = {
  /**
   * Creates a retry policy with common presets
   *
   * @param {string} preset - Preset name (aggressive, moderate, conservative, minimal)
   * @returns {RetryConfig} Configuration
   */
  createPreset(preset) {
    const presets = {
      aggressive: {
        maxRetries: 5,
        initialDelay: 500,
        maxDelay: 10000,
        backoffMultiplier: 1.5,
        useJitter: true
      },
      moderate: {
        maxRetries: 3,
        initialDelay: 1000,
        maxDelay: 30000,
        backoffMultiplier: 2,
        useJitter: true
      },
      conservative: {
        maxRetries: 2,
        initialDelay: 2000,
        maxDelay: 60000,
        backoffMultiplier: 3,
        useJitter: true
      },
      minimal: {
        maxRetries: 1,
        initialDelay: 1000,
        maxDelay: 5000,
        backoffMultiplier: 2,
        useJitter: false
      }
    };

    return presets[preset] || presets.moderate;
  },

  /**
   * Creates an HTTP-specific retry policy
   *
   * @param {Object} options - Options
   * @returns {RetryConfig} Configuration
   */
  createHttpRetryPolicy(options = {}) {
    return {
      maxRetries: options.maxRetries || 3,
      initialDelay: options.initialDelay || 1000,
      maxDelay: options.maxDelay || 30000,
      backoffMultiplier: 2,
      useJitter: true,
      retryableErrors: (error) => {
        // Retry on network errors and 5xx, 408, 429, 503
        if (error.code) {
          const retryableCodes = ['ETIMEDOUT', 'ECONNREFUSED', 'ECONNRESET', 'ENOTFOUND'];
          if (retryableCodes.includes(error.code)) return true;
        }

        if (error.response) {
          const retryableStatuses = [408, 429, 500, 502, 503, 504];
          if (retryableStatuses.includes(error.response.status)) return true;
        }

        return false;
      }
    };
  },

  /**
   * Creates a database-specific retry policy
   *
   * @param {Object} options - Options
   * @returns {RetryConfig} Configuration
   */
  createDbRetryPolicy(options = {}) {
    return {
      maxRetries: options.maxRetries || 5,
      initialDelay: options.initialDelay || 500,
      maxDelay: options.maxDelay || 10000,
      backoffMultiplier: 2,
      useJitter: true,
      retryableErrors: (error) => {
        // Retry on connection errors, deadlocks, timeouts
        const retryableMessages = [
          'connection',
          'deadlock',
          'timeout',
          'ECONNREFUSED',
          'lock wait'
        ];

        const errorString = error.toString().toLowerCase();

        return retryableMessages.some(msg =>
          errorString.includes(msg.toLowerCase())
        );
      }
    };
  }
};

export default RetryWithBackoff;
