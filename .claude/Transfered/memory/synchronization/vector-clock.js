/**
 * Vector Clock Implementation
 *
 * Provides causal ordering and happens-before relationships for distributed events.
 * Used to track causality and detect concurrent operations in distributed memory systems.
 *
 * Key concepts:
 * - Happens-before relationship (A -> B)
 * - Concurrent events (A || B)
 * - Lamport timestamps for total ordering
 *
 * @module memory/synchronization/vector-clock
 */

import { createLogger } from '../../utils/logger.js';

const logger = createLogger('VectorClock');

/**
 * Clock comparison results
 * @enum {string}
 */
export const ClockComparison = {
  EQUAL: 'equal',           // Clocks are identical
  BEFORE: 'before',         // This clock happened before other
  AFTER: 'after',           // This clock happened after other
  CONCURRENT: 'concurrent'  // Clocks are concurrent (no causal relationship)
};

/**
 * Vector Clock
 *
 * Tracks logical time for distributed events using vector timestamps.
 */
export class VectorClock {
  /**
   * @param {string} nodeId - Unique node identifier
   * @param {Object} [initialClock={}] - Initial clock state
   */
  constructor(nodeId, initialClock = {}) {
    this.nodeId = nodeId;
    this.clock = { ...initialClock };

    // Ensure this node exists in clock
    if (!this.clock[nodeId]) {
      this.clock[nodeId] = 0;
    }

    logger.debug('Vector clock initialized', { nodeId, clock: this.clock });
  }

  /**
   * Increment this node's clock
   *
   * @returns {VectorClock} This clock (for chaining)
   */
  increment() {
    this.clock[this.nodeId] = (this.clock[this.nodeId] || 0) + 1;
    logger.debug('Clock incremented', { nodeId: this.nodeId, value: this.clock[this.nodeId] });
    return this;
  }

  /**
   * Update clock based on received message
   *
   * Implements the vector clock merge rule:
   * For each node i: clock[i] = max(local[i], received[i])
   * Then increment own clock
   *
   * @param {VectorClock|Object} receivedClock - Received clock
   * @returns {VectorClock} This clock (for chaining)
   */
  update(receivedClock) {
    const received = receivedClock instanceof VectorClock
      ? receivedClock.clock
      : receivedClock;

    // Merge: take max for each node
    for (const [nodeId, timestamp] of Object.entries(received)) {
      this.clock[nodeId] = Math.max(this.clock[nodeId] || 0, timestamp);
    }

    // Increment own clock
    this.increment();

    logger.debug('Clock updated', { nodeId: this.nodeId, clock: this.clock });
    return this;
  }

  /**
   * Compare this clock with another
   *
   * @param {VectorClock|Object} other - Other clock
   * @returns {ClockComparison} Comparison result
   */
  compare(other) {
    const otherClock = other instanceof VectorClock ? other.clock : other;

    // Get all node IDs from both clocks
    const allNodes = new Set([
      ...Object.keys(this.clock),
      ...Object.keys(otherClock)
    ]);

    let hasLess = false;
    let hasGreater = false;

    for (const nodeId of allNodes) {
      const thisValue = this.clock[nodeId] || 0;
      const otherValue = otherClock[nodeId] || 0;

      if (thisValue < otherValue) {
        hasLess = true;
      } else if (thisValue > otherValue) {
        hasGreater = true;
      }
    }

    // Determine relationship
    if (!hasLess && !hasGreater) {
      return ClockComparison.EQUAL;
    } else if (hasLess && !hasGreater) {
      return ClockComparison.BEFORE;
    } else if (!hasLess && hasGreater) {
      return ClockComparison.AFTER;
    } else {
      return ClockComparison.CONCURRENT;
    }
  }

  /**
   * Check if this clock happened before another
   *
   * @param {VectorClock|Object} other - Other clock
   * @returns {boolean} True if this happened before other
   */
  happensBefore(other) {
    return this.compare(other) === ClockComparison.BEFORE;
  }

  /**
   * Check if this clock happened after another
   *
   * @param {VectorClock|Object} other - Other clock
   * @returns {boolean} True if this happened after other
   */
  happensAfter(other) {
    return this.compare(other) === ClockComparison.AFTER;
  }

  /**
   * Check if this clock is concurrent with another
   *
   * @param {VectorClock|Object} other - Other clock
   * @returns {boolean} True if concurrent
   */
  isConcurrent(other) {
    return this.compare(other) === ClockComparison.CONCURRENT;
  }

  /**
   * Check if this clock equals another
   *
   * @param {VectorClock|Object} other - Other clock
   * @returns {boolean} True if equal
   */
  equals(other) {
    return this.compare(other) === ClockComparison.EQUAL;
  }

  /**
   * Get clock value for specific node
   *
   * @param {string} nodeId - Node identifier
   * @returns {number} Clock value
   */
  get(nodeId) {
    return this.clock[nodeId] || 0;
  }

  /**
   * Set clock value for specific node
   *
   * @param {string} nodeId - Node identifier
   * @param {number} value - Clock value
   * @returns {VectorClock} This clock (for chaining)
   */
  set(nodeId, value) {
    this.clock[nodeId] = value;
    return this;
  }

  /**
   * Get all node IDs in clock
   *
   * @returns {string[]} Array of node IDs
   */
  getNodeIds() {
    return Object.keys(this.clock);
  }

  /**
   * Clone this clock
   *
   * @returns {VectorClock} Cloned clock
   */
  clone() {
    return new VectorClock(this.nodeId, { ...this.clock });
  }

  /**
   * Merge with another clock (without incrementing)
   *
   * @param {VectorClock|Object} other - Other clock
   * @returns {VectorClock} New merged clock
   */
  merge(other) {
    const otherClock = other instanceof VectorClock ? other.clock : other;

    const merged = new VectorClock(this.nodeId);

    // Merge all nodes
    const allNodes = new Set([
      ...Object.keys(this.clock),
      ...Object.keys(otherClock)
    ]);

    for (const nodeId of allNodes) {
      merged.clock[nodeId] = Math.max(
        this.clock[nodeId] || 0,
        otherClock[nodeId] || 0
      );
    }

    return merged;
  }

  /**
   * Get Lamport timestamp (sum of all clock values)
   *
   * Provides a total order for events (though not causally accurate).
   * Useful for tie-breaking.
   *
   * @returns {number} Lamport timestamp
   */
  getLamportTimestamp() {
    return Object.values(this.clock).reduce((sum, value) => sum + value, 0);
  }

  /**
   * Serialize to JSON
   *
   * @returns {Object} Serialized clock
   */
  toJSON() {
    return {
      nodeId: this.nodeId,
      clock: { ...this.clock }
    };
  }

  /**
   * Serialize to string representation
   *
   * @returns {string} String representation
   */
  toString() {
    const entries = Object.entries(this.clock)
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([node, value]) => `${node}:${value}`)
      .join(',');

    return `{${entries}}`;
  }

  /**
   * Deserialize from JSON
   *
   * @param {Object} json - Serialized clock
   * @returns {VectorClock} Restored clock
   */
  static fromJSON(json) {
    return new VectorClock(json.nodeId, json.clock);
  }

  /**
   * Parse from string representation
   *
   * @param {string} str - String representation
   * @param {string} nodeId - Node ID for the clock
   * @returns {VectorClock} Parsed clock
   */
  static fromString(str, nodeId) {
    const clock = {};

    // Remove braces
    const content = str.replace(/^\{|\}$/g, '');

    if (content) {
      const entries = content.split(',');

      for (const entry of entries) {
        const [node, value] = entry.split(':');
        clock[node.trim()] = parseInt(value.trim(), 10);
      }
    }

    return new VectorClock(nodeId, clock);
  }
}

/**
 * Vector Clock Manager
 *
 * Manages multiple vector clocks for different events/entities.
 */
export class VectorClockManager {
  /**
   * @param {string} nodeId - Unique node identifier
   */
  constructor(nodeId) {
    this.nodeId = nodeId;
    this.clocks = new Map();

    logger.info('Vector Clock Manager initialized', { nodeId });
  }

  /**
   * Get or create clock for entity
   *
   * @param {string} entityId - Entity identifier
   * @returns {VectorClock} Vector clock
   */
  getClock(entityId) {
    if (!this.clocks.has(entityId)) {
      this.clocks.set(entityId, new VectorClock(this.nodeId));
    }

    return this.clocks.get(entityId);
  }

  /**
   * Increment clock for entity
   *
   * @param {string} entityId - Entity identifier
   * @returns {VectorClock} Updated clock
   */
  increment(entityId) {
    const clock = this.getClock(entityId);
    clock.increment();
    return clock;
  }

  /**
   * Update clock with received clock
   *
   * @param {string} entityId - Entity identifier
   * @param {VectorClock|Object} receivedClock - Received clock
   * @returns {VectorClock} Updated clock
   */
  update(entityId, receivedClock) {
    const clock = this.getClock(entityId);
    clock.update(receivedClock);
    return clock;
  }

  /**
   * Compare two entity clocks
   *
   * @param {string} entityId1 - First entity
   * @param {string} entityId2 - Second entity
   * @returns {ClockComparison} Comparison result
   */
  compare(entityId1, entityId2) {
    const clock1 = this.getClock(entityId1);
    const clock2 = this.getClock(entityId2);
    return clock1.compare(clock2);
  }

  /**
   * Detect concurrent events
   *
   * @param {Array<{entityId: string, clock: VectorClock|Object}>} events - Events to check
   * @returns {Array<Array<number>>} Groups of concurrent event indices
   */
  detectConcurrent(events) {
    const concurrent = [];

    for (let i = 0; i < events.length; i++) {
      const group = [i];

      for (let j = i + 1; j < events.length; j++) {
        const clock1 = events[i].clock instanceof VectorClock
          ? events[i].clock
          : VectorClock.fromJSON(events[i].clock);

        const clock2 = events[j].clock instanceof VectorClock
          ? events[j].clock
          : VectorClock.fromJSON(events[j].clock);

        if (clock1.isConcurrent(clock2)) {
          group.push(j);
        }
      }

      if (group.length > 1) {
        concurrent.push(group);
      }
    }

    return concurrent;
  }

  /**
   * Sort events by causal order
   *
   * @param {Array<{entityId: string, clock: VectorClock|Object, data: *}>} events - Events to sort
   * @returns {Array<*>} Causally ordered events
   */
  causalSort(events) {
    // Convert to VectorClock instances
    const eventsWithClocks = events.map(event => ({
      ...event,
      clock: event.clock instanceof VectorClock
        ? event.clock
        : VectorClock.fromJSON(event.clock)
    }));

    // Sort using happens-before relationship
    // If neither happens-before, use Lamport timestamp for tie-breaking
    return eventsWithClocks.sort((a, b) => {
      const comparison = a.clock.compare(b.clock);

      if (comparison === ClockComparison.BEFORE) {
        return -1;
      } else if (comparison === ClockComparison.AFTER) {
        return 1;
      } else {
        // Concurrent or equal: use Lamport timestamp
        return a.clock.getLamportTimestamp() - b.clock.getLamportTimestamp();
      }
    });
  }

  /**
   * Export all clocks
   *
   * @returns {Object} Map of entityId -> clock
   */
  exportClocks() {
    const exported = {};

    for (const [entityId, clock] of this.clocks.entries()) {
      exported[entityId] = clock.toJSON();
    }

    return exported;
  }

  /**
   * Import clocks
   *
   * @param {Object} clocks - Map of entityId -> clock
   */
  importClocks(clocks) {
    for (const [entityId, clockData] of Object.entries(clocks)) {
      this.clocks.set(entityId, VectorClock.fromJSON(clockData));
    }

    logger.debug('Clocks imported', { count: Object.keys(clocks).length });
  }

  /**
   * Clear all clocks
   */
  clear() {
    this.clocks.clear();
    logger.debug('All clocks cleared');
  }

  /**
   * Get clock count
   *
   * @returns {number} Number of clocks
   */
  size() {
    return this.clocks.size;
  }
}

export default VectorClock;
