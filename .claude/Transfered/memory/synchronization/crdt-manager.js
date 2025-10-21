/**
 * CRDT Manager
 *
 * Conflict-free Replicated Data Types implementation for distributed memory synchronization.
 * Ensures eventual consistency across distributed memory replicas without coordination.
 *
 * Supported CRDTs:
 * - G-Counter: Grow-only counter
 * - PN-Counter: Positive-Negative counter
 * - LWW-Element-Set: Last-Write-Wins element set
 * - OR-Set: Observed-Remove set
 * - LWW-Register: Last-Write-Wins register
 *
 * @module memory/synchronization/crdt-manager
 */

import { createLogger } from '../../utils/logger.js';
import { EventEmitter } from 'events';

const logger = createLogger('CRDTManager');

/**
 * CRDT types
 * @enum {string}
 */
export const CRDTType = {
  G_COUNTER: 'g_counter',
  PN_COUNTER: 'pn_counter',
  LWW_ELEMENT_SET: 'lww_element_set',
  OR_SET: 'or_set',
  LWW_REGISTER: 'lww_register'
};

/**
 * G-Counter: Grow-only counter
 *
 * State-based CRDT that can only increment.
 * Conflict resolution: merge by taking max per replica.
 */
export class GCounter {
  /**
   * @param {string} replicaId - Unique replica identifier
   */
  constructor(replicaId) {
    this.replicaId = replicaId;
    this.counters = new Map();
    this.counters.set(replicaId, 0);
  }

  /**
   * Increment counter
   *
   * @param {number} [amount=1] - Amount to increment
   */
  increment(amount = 1) {
    const current = this.counters.get(this.replicaId) || 0;
    this.counters.set(this.replicaId, current + amount);
  }

  /**
   * Get current value
   *
   * @returns {number} Sum of all replica counters
   */
  value() {
    let sum = 0;
    for (const count of this.counters.values()) {
      sum += count;
    }
    return sum;
  }

  /**
   * Merge with another G-Counter
   *
   * @param {GCounter} other - Other G-Counter
   */
  merge(other) {
    for (const [replicaId, count] of other.counters.entries()) {
      const current = this.counters.get(replicaId) || 0;
      this.counters.set(replicaId, Math.max(current, count));
    }
  }

  /**
   * Serialize to JSON
   *
   * @returns {Object} Serialized state
   */
  toJSON() {
    return {
      type: CRDTType.G_COUNTER,
      replicaId: this.replicaId,
      counters: Object.fromEntries(this.counters)
    };
  }

  /**
   * Deserialize from JSON
   *
   * @param {Object} json - Serialized state
   * @returns {GCounter} Restored G-Counter
   */
  static fromJSON(json) {
    const counter = new GCounter(json.replicaId);
    counter.counters = new Map(Object.entries(json.counters).map(([k, v]) => [k, Number(v)]));
    return counter;
  }
}

/**
 * PN-Counter: Positive-Negative counter
 *
 * State-based CRDT that can increment and decrement.
 * Uses two G-Counters internally.
 */
export class PNCounter {
  /**
   * @param {string} replicaId - Unique replica identifier
   */
  constructor(replicaId) {
    this.replicaId = replicaId;
    this.positive = new GCounter(replicaId);
    this.negative = new GCounter(replicaId);
  }

  /**
   * Increment counter
   *
   * @param {number} [amount=1] - Amount to increment
   */
  increment(amount = 1) {
    this.positive.increment(amount);
  }

  /**
   * Decrement counter
   *
   * @param {number} [amount=1] - Amount to decrement
   */
  decrement(amount = 1) {
    this.negative.increment(amount);
  }

  /**
   * Get current value
   *
   * @returns {number} Positive minus negative
   */
  value() {
    return this.positive.value() - this.negative.value();
  }

  /**
   * Merge with another PN-Counter
   *
   * @param {PNCounter} other - Other PN-Counter
   */
  merge(other) {
    this.positive.merge(other.positive);
    this.negative.merge(other.negative);
  }

  /**
   * Serialize to JSON
   *
   * @returns {Object} Serialized state
   */
  toJSON() {
    return {
      type: CRDTType.PN_COUNTER,
      replicaId: this.replicaId,
      positive: this.positive.toJSON(),
      negative: this.negative.toJSON()
    };
  }

  /**
   * Deserialize from JSON
   *
   * @param {Object} json - Serialized state
   * @returns {PNCounter} Restored PN-Counter
   */
  static fromJSON(json) {
    const counter = new PNCounter(json.replicaId);
    counter.positive = GCounter.fromJSON(json.positive);
    counter.negative = GCounter.fromJSON(json.negative);
    return counter;
  }
}

/**
 * LWW-Element-Set: Last-Write-Wins element set
 *
 * Set CRDT that resolves conflicts using timestamps (last write wins).
 */
export class LWWElementSet {
  /**
   * @param {string} replicaId - Unique replica identifier
   */
  constructor(replicaId) {
    this.replicaId = replicaId;
    this.addSet = new Map(); // element -> timestamp
    this.removeSet = new Map(); // element -> timestamp
  }

  /**
   * Add element to set
   *
   * @param {*} element - Element to add
   * @param {number} [timestamp=Date.now()] - Timestamp
   */
  add(element, timestamp = Date.now()) {
    const key = JSON.stringify(element);
    const currentTimestamp = this.addSet.get(key) || 0;

    if (timestamp > currentTimestamp) {
      this.addSet.set(key, timestamp);
    }
  }

  /**
   * Remove element from set
   *
   * @param {*} element - Element to remove
   * @param {number} [timestamp=Date.now()] - Timestamp
   */
  remove(element, timestamp = Date.now()) {
    const key = JSON.stringify(element);
    const currentTimestamp = this.removeSet.get(key) || 0;

    if (timestamp > currentTimestamp) {
      this.removeSet.set(key, timestamp);
    }
  }

  /**
   * Check if element exists in set
   *
   * @param {*} element - Element to check
   * @returns {boolean} True if element exists
   */
  has(element) {
    const key = JSON.stringify(element);
    const addTimestamp = this.addSet.get(key) || 0;
    const removeTimestamp = this.removeSet.get(key) || 0;

    // Element exists if it was added after it was removed (or never removed)
    return addTimestamp > removeTimestamp;
  }

  /**
   * Get all elements in set
   *
   * @returns {Array<*>} Array of elements
   */
  values() {
    const elements = [];

    for (const [key, addTimestamp] of this.addSet.entries()) {
      const removeTimestamp = this.removeSet.get(key) || 0;

      if (addTimestamp > removeTimestamp) {
        elements.push(JSON.parse(key));
      }
    }

    return elements;
  }

  /**
   * Get set size
   *
   * @returns {number} Number of elements
   */
  size() {
    return this.values().length;
  }

  /**
   * Merge with another LWW-Element-Set
   *
   * @param {LWWElementSet} other - Other LWW-Element-Set
   */
  merge(other) {
    // Merge add sets (take max timestamp)
    for (const [element, timestamp] of other.addSet.entries()) {
      const currentTimestamp = this.addSet.get(element) || 0;
      this.addSet.set(element, Math.max(currentTimestamp, timestamp));
    }

    // Merge remove sets (take max timestamp)
    for (const [element, timestamp] of other.removeSet.entries()) {
      const currentTimestamp = this.removeSet.get(element) || 0;
      this.removeSet.set(element, Math.max(currentTimestamp, timestamp));
    }
  }

  /**
   * Serialize to JSON
   *
   * @returns {Object} Serialized state
   */
  toJSON() {
    return {
      type: CRDTType.LWW_ELEMENT_SET,
      replicaId: this.replicaId,
      addSet: Object.fromEntries(this.addSet),
      removeSet: Object.fromEntries(this.removeSet)
    };
  }

  /**
   * Deserialize from JSON
   *
   * @param {Object} json - Serialized state
   * @returns {LWWElementSet} Restored LWW-Element-Set
   */
  static fromJSON(json) {
    const set = new LWWElementSet(json.replicaId);
    set.addSet = new Map(Object.entries(json.addSet));
    set.removeSet = new Map(Object.entries(json.removeSet));
    return set;
  }
}

/**
 * OR-Set: Observed-Remove set
 *
 * Set CRDT that allows concurrent additions and removals.
 * Each element has unique tags to track observations.
 */
export class ORSet {
  /**
   * @param {string} replicaId - Unique replica identifier
   */
  constructor(replicaId) {
    this.replicaId = replicaId;
    this.elements = new Map(); // element -> Set<tag>
  }

  /**
   * Add element to set
   *
   * @param {*} element - Element to add
   * @returns {string} Unique tag for this addition
   */
  add(element) {
    const key = JSON.stringify(element);
    const tag = `${this.replicaId}:${Date.now()}:${Math.random().toString(36).substr(2, 9)}`;

    if (!this.elements.has(key)) {
      this.elements.set(key, new Set());
    }

    this.elements.get(key).add(tag);
    return tag;
  }

  /**
   * Remove element from set
   *
   * @param {*} element - Element to remove
   */
  remove(element) {
    const key = JSON.stringify(element);
    this.elements.delete(key);
  }

  /**
   * Check if element exists in set
   *
   * @param {*} element - Element to check
   * @returns {boolean} True if element exists
   */
  has(element) {
    const key = JSON.stringify(element);
    const tags = this.elements.get(key);
    return tags && tags.size > 0;
  }

  /**
   * Get all elements in set
   *
   * @returns {Array<*>} Array of elements
   */
  values() {
    const elements = [];

    for (const [key, tags] of this.elements.entries()) {
      if (tags.size > 0) {
        elements.push(JSON.parse(key));
      }
    }

    return elements;
  }

  /**
   * Get set size
   *
   * @returns {number} Number of elements
   */
  size() {
    let count = 0;

    for (const tags of this.elements.values()) {
      if (tags.size > 0) {
        count++;
      }
    }

    return count;
  }

  /**
   * Merge with another OR-Set
   *
   * @param {ORSet} other - Other OR-Set
   */
  merge(other) {
    for (const [element, otherTags] of other.elements.entries()) {
      if (!this.elements.has(element)) {
        this.elements.set(element, new Set());
      }

      const tags = this.elements.get(element);

      // Union of tags
      for (const tag of otherTags) {
        tags.add(tag);
      }
    }
  }

  /**
   * Serialize to JSON
   *
   * @returns {Object} Serialized state
   */
  toJSON() {
    const elements = {};

    for (const [key, tags] of this.elements.entries()) {
      elements[key] = Array.from(tags);
    }

    return {
      type: CRDTType.OR_SET,
      replicaId: this.replicaId,
      elements
    };
  }

  /**
   * Deserialize from JSON
   *
   * @param {Object} json - Serialized state
   * @returns {ORSet} Restored OR-Set
   */
  static fromJSON(json) {
    const set = new ORSet(json.replicaId);

    for (const [key, tags] of Object.entries(json.elements)) {
      set.elements.set(key, new Set(tags));
    }

    return set;
  }
}

/**
 * LWW-Register: Last-Write-Wins register
 *
 * Register CRDT that holds a single value, resolved by timestamp.
 */
export class LWWRegister {
  /**
   * @param {string} replicaId - Unique replica identifier
   * @param {*} [initialValue=null] - Initial value
   */
  constructor(replicaId, initialValue = null) {
    this.replicaId = replicaId;
    this.value_ = initialValue;
    this.timestamp = 0;
  }

  /**
   * Set register value
   *
   * @param {*} value - New value
   * @param {number} [timestamp=Date.now()] - Timestamp
   */
  set(value, timestamp = Date.now()) {
    if (timestamp > this.timestamp) {
      this.value_ = value;
      this.timestamp = timestamp;
    }
  }

  /**
   * Get register value
   *
   * @returns {*} Current value
   */
  get() {
    return this.value_;
  }

  /**
   * Merge with another LWW-Register
   *
   * @param {LWWRegister} other - Other LWW-Register
   */
  merge(other) {
    if (other.timestamp > this.timestamp) {
      this.value_ = other.value_;
      this.timestamp = other.timestamp;
    }
  }

  /**
   * Serialize to JSON
   *
   * @returns {Object} Serialized state
   */
  toJSON() {
    return {
      type: CRDTType.LWW_REGISTER,
      replicaId: this.replicaId,
      value: this.value_,
      timestamp: this.timestamp
    };
  }

  /**
   * Deserialize from JSON
   *
   * @param {Object} json - Serialized state
   * @returns {LWWRegister} Restored LWW-Register
   */
  static fromJSON(json) {
    const register = new LWWRegister(json.replicaId, json.value);
    register.timestamp = json.timestamp;
    return register;
  }
}

/**
 * CRDT Manager
 *
 * Manages multiple CRDT instances with automatic merging and synchronization.
 */
export class CRDTManager extends EventEmitter {
  /**
   * @param {Object} config - Configuration object
   * @param {string} config.replicaId - Unique replica identifier
   * @param {Object} [config.redisClient] - Redis client for persistence
   * @param {string} [config.namespace='crdt'] - Redis namespace
   */
  constructor(config) {
    super();

    this.replicaId = config.replicaId;
    this.redis = config.redisClient;
    this.namespace = config.namespace || 'crdt';

    // CRDT registry
    this.crdts = new Map();

    logger.info('CRDT Manager initialized', {
      replicaId: this.replicaId,
      namespace: this.namespace
    });
  }

  /**
   * Create or get CRDT instance
   *
   * @param {string} id - CRDT identifier
   * @param {CRDTType} type - CRDT type
   * @param {*} [initialValue] - Initial value (for registers)
   * @returns {Object} CRDT instance
   */
  create(id, type, initialValue = null) {
    if (this.crdts.has(id)) {
      return this.crdts.get(id);
    }

    let crdt;

    switch (type) {
      case CRDTType.G_COUNTER:
        crdt = new GCounter(this.replicaId);
        break;
      case CRDTType.PN_COUNTER:
        crdt = new PNCounter(this.replicaId);
        break;
      case CRDTType.LWW_ELEMENT_SET:
        crdt = new LWWElementSet(this.replicaId);
        break;
      case CRDTType.OR_SET:
        crdt = new ORSet(this.replicaId);
        break;
      case CRDTType.LWW_REGISTER:
        crdt = new LWWRegister(this.replicaId, initialValue);
        break;
      default:
        throw new Error(`Unknown CRDT type: ${type}`);
    }

    this.crdts.set(id, crdt);

    logger.debug('CRDT created', { id, type });
    this.emit('crdt:created', { id, type });

    return crdt;
  }

  /**
   * Get CRDT instance
   *
   * @param {string} id - CRDT identifier
   * @returns {Object|null} CRDT instance or null
   */
  get(id) {
    return this.crdts.get(id) || null;
  }

  /**
   * Merge remote CRDT state
   *
   * @param {string} id - CRDT identifier
   * @param {Object} remoteState - Remote CRDT state (JSON)
   * @returns {boolean} True if merged successfully
   */
  merge(id, remoteState) {
    try {
      const local = this.crdts.get(id);

      if (!local) {
        // Create new CRDT from remote state
        const remote = this._deserialize(remoteState);
        this.crdts.set(id, remote);
        logger.debug('CRDT created from remote state', { id });
        this.emit('crdt:created', { id, type: remoteState.type });
        return true;
      }

      // Deserialize remote state
      const remote = this._deserialize(remoteState);

      // Merge
      local.merge(remote);

      logger.debug('CRDT merged', { id });
      this.emit('crdt:merged', { id });

      return true;
    } catch (error) {
      logger.error('Failed to merge CRDT', { error: error.message, id });
      return false;
    }
  }

  /**
   * Get CRDT state for synchronization
   *
   * @param {string} id - CRDT identifier
   * @returns {Object|null} Serialized CRDT state
   */
  getState(id) {
    const crdt = this.crdts.get(id);

    if (!crdt) {
      return null;
    }

    return crdt.toJSON();
  }

  /**
   * Get all CRDT states
   *
   * @returns {Object} Map of id -> state
   */
  getAllStates() {
    const states = {};

    for (const [id, crdt] of this.crdts.entries()) {
      states[id] = crdt.toJSON();
    }

    return states;
  }

  /**
   * Persist CRDT to Redis
   *
   * @param {string} id - CRDT identifier
   * @returns {Promise<boolean>} True if persisted
   */
  async persist(id) {
    if (!this.redis) {
      return false;
    }

    try {
      const state = this.getState(id);

      if (!state) {
        return false;
      }

      const key = `${this.namespace}:${id}`;
      await this.redis.set(key, JSON.stringify(state));

      logger.debug('CRDT persisted', { id });
      return true;
    } catch (error) {
      logger.error('Failed to persist CRDT', { error: error.message, id });
      return false;
    }
  }

  /**
   * Load CRDT from Redis
   *
   * @param {string} id - CRDT identifier
   * @returns {Promise<boolean>} True if loaded
   */
  async load(id) {
    if (!this.redis) {
      return false;
    }

    try {
      const key = `${this.namespace}:${id}`;
      const stateJson = await this.redis.get(key);

      if (!stateJson) {
        return false;
      }

      const state = JSON.parse(stateJson);
      const crdt = this._deserialize(state);

      this.crdts.set(id, crdt);

      logger.debug('CRDT loaded', { id });
      return true;
    } catch (error) {
      logger.error('Failed to load CRDT', { error: error.message, id });
      return false;
    }
  }

  /**
   * Deserialize CRDT from JSON
   *
   * @private
   * @param {Object} state - Serialized state
   * @returns {Object} CRDT instance
   */
  _deserialize(state) {
    switch (state.type) {
      case CRDTType.G_COUNTER:
        return GCounter.fromJSON(state);
      case CRDTType.PN_COUNTER:
        return PNCounter.fromJSON(state);
      case CRDTType.LWW_ELEMENT_SET:
        return LWWElementSet.fromJSON(state);
      case CRDTType.OR_SET:
        return ORSet.fromJSON(state);
      case CRDTType.LWW_REGISTER:
        return LWWRegister.fromJSON(state);
      default:
        throw new Error(`Unknown CRDT type: ${state.type}`);
    }
  }

  /**
   * Destroy CRDT manager
   */
  async destroy() {
    this.crdts.clear();
    this.removeAllListeners();
    logger.info('CRDT Manager destroyed');
  }
}

export default CRDTManager;
