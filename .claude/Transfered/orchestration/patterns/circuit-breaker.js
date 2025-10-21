/**
 * Circuit Breaker Pattern
 *
 * Implements failure isolation with Closed/Open/Half-Open states,
 * automatic recovery attempts, and fallback mechanisms.
 *
 * @module orchestration/patterns/circuit-breaker
 */

import { EventEmitter } from 'events';

/**
 * @typedef {Object} CircuitBreakerConfig
 * @property {string} name - Circuit breaker name
 * @property {number} failureThreshold - Number of failures before opening (default: 5)
 * @property {number} successThreshold - Successes needed in half-open to close (default: 2)
 * @property {number} timeout - Time in ms before attempting reset (default: 60000)
 * @property {Function} [fallback] - Fallback function when circuit is open
 * @property {Function} [isFailure] - Custom function to determine if response is a failure
 */

/**
 * @typedef {Object} CircuitState
 * @property {string} state - Current state (CLOSED, OPEN, HALF_OPEN)
 * @property {number} failures - Consecutive failure count
 * @property {number} successes - Success count in half-open state
 * @property {Date|null} lastFailureTime - Time of last failure
 * @property {Date|null} nextAttemptTime - Time when next attempt is allowed
 * @property {number} totalCalls - Total number of calls
 * @property {number} totalFailures - Total failures
 * @property {number} totalSuccesses - Total successes
 */

const STATES = {
  CLOSED: 'CLOSED',
  OPEN: 'OPEN',
  HALF_OPEN: 'HALF_OPEN'
};

export class CircuitBreaker extends EventEmitter {
  /**
   * Creates a new Circuit Breaker
   *
   * @param {CircuitBreakerConfig} config - Circuit breaker configuration
   * @param {Function} [logger] - Logger function
   */
  constructor(config, logger = console.log) {
    super();

    this.name = config.name || 'CircuitBreaker';
    this.failureThreshold = config.failureThreshold || 5;
    this.successThreshold = config.successThreshold || 2;
    this.timeout = config.timeout || 60000;
    this.fallback = config.fallback || null;
    this.isFailure = config.isFailure || this._defaultIsFailure.bind(this);
    this.logger = logger;

    /** @type {CircuitState} */
    this.state = {
      state: STATES.CLOSED,
      failures: 0,
      successes: 0,
      lastFailureTime: null,
      nextAttemptTime: null,
      totalCalls: 0,
      totalFailures: 0,
      totalSuccesses: 0
    };
  }

  /**
   * Executes a function protected by the circuit breaker
   *
   * @param {Function} fn - Function to execute
   * @param {...any} args - Arguments to pass to the function
   * @returns {Promise<any>} Function result
   */
  async execute(fn, ...args) {
    this.state.totalCalls++;

    // Check if circuit is open
    if (this.state.state === STATES.OPEN) {
      // Check if timeout has elapsed
      if (Date.now() < this.state.nextAttemptTime) {
        this.logger(`[${this.name}] Circuit is OPEN, rejecting call`);
        this.emit('call:rejected', { state: this.state });

        // Try fallback if available
        if (this.fallback) {
          this.logger(`[${this.name}] Executing fallback`);
          return await this.fallback(...args);
        }

        throw new Error('Circuit breaker is OPEN');
      }

      // Timeout elapsed, transition to half-open
      this._transitionTo(STATES.HALF_OPEN);
    }

    try {
      this.logger(`[${this.name}] Executing call (state: ${this.state.state})`);

      const result = await fn(...args);

      // Check if result indicates failure
      if (await this.isFailure(result)) {
        await this._onFailure();
        throw new Error('Call failed (isFailure check)');
      }

      await this._onSuccess();

      return result;

    } catch (error) {
      await this._onFailure(error);
      throw error;
    }
  }

  /**
   * Wraps a function with circuit breaker protection
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
   * Handles successful execution
   *
   * @private
   */
  async _onSuccess() {
    this.state.totalSuccesses++;

    if (this.state.state === STATES.HALF_OPEN) {
      this.state.successes++;

      this.logger(`[${this.name}] Success in HALF_OPEN (${this.state.successes}/${this.successThreshold})`);

      // Check if we've reached success threshold
      if (this.state.successes >= this.successThreshold) {
        this._transitionTo(STATES.CLOSED);
      }

    } else if (this.state.state === STATES.CLOSED) {
      // Reset failure count on success
      this.state.failures = 0;
    }

    this.emit('call:success', { state: this.state });
  }

  /**
   * Handles failed execution
   *
   * @private
   * @param {Error} [error] - Error that occurred
   */
  async _onFailure(error = null) {
    this.state.totalFailures++;
    this.state.failures++;
    this.state.lastFailureTime = new Date();

    this.logger(`[${this.name}] Failure detected (${this.state.failures}/${this.failureThreshold})`);

    this.emit('call:failure', { state: this.state, error });

    if (this.state.state === STATES.HALF_OPEN) {
      // Failure in half-open immediately opens circuit
      this._transitionTo(STATES.OPEN);

    } else if (this.state.state === STATES.CLOSED) {
      // Check if we've reached failure threshold
      if (this.state.failures >= this.failureThreshold) {
        this._transitionTo(STATES.OPEN);
      }
    }
  }

  /**
   * Transitions to a new state
   *
   * @private
   * @param {string} newState - New state to transition to
   */
  _transitionTo(newState) {
    const oldState = this.state.state;

    if (oldState === newState) {
      return;
    }

    this.logger(`[${this.name}] State transition: ${oldState} -> ${newState}`);

    this.state.state = newState;

    if (newState === STATES.OPEN) {
      this.state.nextAttemptTime = Date.now() + this.timeout;
      this.state.successes = 0;

      this.emit('state:open', { state: this.state });

    } else if (newState === STATES.HALF_OPEN) {
      this.state.successes = 0;
      this.state.failures = 0;

      this.emit('state:half_open', { state: this.state });

    } else if (newState === STATES.CLOSED) {
      this.state.failures = 0;
      this.state.successes = 0;
      this.state.nextAttemptTime = null;

      this.emit('state:closed', { state: this.state });
    }

    this.emit('state:changed', {
      from: oldState,
      to: newState,
      state: this.state
    });
  }

  /**
   * Default failure detection
   *
   * @private
   * @param {any} result - Function result
   * @returns {boolean} True if result indicates failure
   */
  _defaultIsFailure(result) {
    // By default, only exceptions are failures
    return false;
  }

  /**
   * Manually opens the circuit
   */
  open() {
    this.logger(`[${this.name}] Manually opening circuit`);
    this._transitionTo(STATES.OPEN);
  }

  /**
   * Manually closes the circuit
   */
  close() {
    this.logger(`[${this.name}] Manually closing circuit`);
    this._transitionTo(STATES.CLOSED);
  }

  /**
   * Manually transitions to half-open
   */
  halfOpen() {
    this.logger(`[${this.name}] Manually transitioning to half-open`);
    this._transitionTo(STATES.HALF_OPEN);
  }

  /**
   * Resets the circuit breaker state
   */
  reset() {
    this.logger(`[${this.name}] Resetting circuit breaker`);

    this.state = {
      state: STATES.CLOSED,
      failures: 0,
      successes: 0,
      lastFailureTime: null,
      nextAttemptTime: null,
      totalCalls: this.state.totalCalls,
      totalFailures: this.state.totalFailures,
      totalSuccesses: this.state.totalSuccesses
    };

    this.emit('circuit:reset', { state: this.state });
  }

  /**
   * Gets current state
   *
   * @returns {CircuitState} Current state
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
    const successRate = this.state.totalCalls > 0
      ? (this.state.totalSuccesses / this.state.totalCalls) * 100
      : 0;

    const failureRate = this.state.totalCalls > 0
      ? (this.state.totalFailures / this.state.totalCalls) * 100
      : 0;

    return {
      name: this.name,
      state: this.state.state,
      totalCalls: this.state.totalCalls,
      totalSuccesses: this.state.totalSuccesses,
      totalFailures: this.state.totalFailures,
      successRate: successRate.toFixed(2) + '%',
      failureRate: failureRate.toFixed(2) + '%',
      consecutiveFailures: this.state.failures,
      lastFailureTime: this.state.lastFailureTime
    };
  }

  /**
   * Checks if circuit is healthy
   *
   * @returns {boolean} True if circuit is closed
   */
  isHealthy() {
    return this.state.state === STATES.CLOSED;
  }

  /**
   * Checks if circuit is open
   *
   * @returns {boolean} True if circuit is open
   */
  isOpen() {
    return this.state.state === STATES.OPEN;
  }

  /**
   * Checks if circuit is half-open
   *
   * @returns {boolean} True if circuit is half-open
   */
  isHalfOpen() {
    return this.state.state === STATES.HALF_OPEN;
  }
}

/**
 * Circuit Breaker Manager
 *
 * Manages multiple circuit breakers
 */
export class CircuitBreakerManager extends EventEmitter {
  constructor(logger = console.log) {
    super();

    this.logger = logger;

    /** @type {Map<string, CircuitBreaker>} */
    this.breakers = new Map();
  }

  /**
   * Creates or gets a circuit breaker
   *
   * @param {string} name - Circuit breaker name
   * @param {CircuitBreakerConfig} [config] - Configuration
   * @returns {CircuitBreaker} Circuit breaker instance
   */
  getBreaker(name, config = {}) {
    if (!this.breakers.has(name)) {
      const breaker = new CircuitBreaker({ ...config, name }, this.logger);

      // Forward events
      breaker.on('state:changed', (data) => {
        this.emit('breaker:state:changed', { name, ...data });
      });

      breaker.on('call:failure', (data) => {
        this.emit('breaker:call:failure', { name, ...data });
      });

      this.breakers.set(name, breaker);

      this.logger(`[CircuitBreakerManager] Created circuit breaker: ${name}`);
    }

    return this.breakers.get(name);
  }

  /**
   * Removes a circuit breaker
   *
   * @param {string} name - Circuit breaker name
   * @returns {boolean} Success status
   */
  removeBreaker(name) {
    return this.breakers.delete(name);
  }

  /**
   * Gets all circuit breakers
   *
   * @returns {Map<string, CircuitBreaker>} All breakers
   */
  getAllBreakers() {
    return new Map(this.breakers);
  }

  /**
   * Gets health status of all breakers
   *
   * @returns {Object} Health status
   */
  getHealth() {
    const health = {
      healthy: [],
      degraded: [],
      unhealthy: []
    };

    for (const [name, breaker] of this.breakers) {
      const state = breaker.getState();

      if (state.state === STATES.CLOSED) {
        health.healthy.push(name);
      } else if (state.state === STATES.HALF_OPEN) {
        health.degraded.push(name);
      } else {
        health.unhealthy.push(name);
      }
    }

    return health;
  }

  /**
   * Gets statistics for all breakers
   *
   * @returns {Object} Statistics
   */
  getStats() {
    const stats = {};

    for (const [name, breaker] of this.breakers) {
      stats[name] = breaker.getStats();
    }

    return stats;
  }

  /**
   * Resets all circuit breakers
   */
  resetAll() {
    this.logger(`[CircuitBreakerManager] Resetting all circuit breakers`);

    for (const breaker of this.breakers.values()) {
      breaker.reset();
    }
  }
}

export default CircuitBreaker;
