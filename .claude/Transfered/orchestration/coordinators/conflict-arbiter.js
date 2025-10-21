/**
 * Conflict Arbiter
 *
 * Conflict detection and resolution with multiple strategies:
 * priority-based, negotiation, optimization, and distributed consensus.
 *
 * @module orchestration/coordinators/conflict-arbiter
 */

import { EventEmitter } from 'events';

/**
 * @typedef {Object} Conflict
 * @property {string} id - Conflict identifier
 * @property {string} type - Conflict type (resource, priority, dependency, state)
 * @property {string[]} participants - IDs of conflicting entities
 * @property {Object} context - Conflict context
 * @property {string} status - Conflict status (detected, resolving, resolved, unresolved)
 * @property {Date} detectedAt - Detection timestamp
 * @property {Date} resolvedAt - Resolution timestamp
 */

/**
 * @typedef {Object} ResolutionStrategy
 * @property {string} name - Strategy name
 * @property {Function} resolver - Resolution function
 * @property {number} priority - Strategy priority
 * @property {Function} applicability - Function to check if strategy applies
 */

export class ConflictArbiter extends EventEmitter {
  constructor(options = {}) {
    super();

    this.defaultStrategy = options.defaultStrategy || 'priority';
    this.enableDeadlockPrevention = options.enableDeadlockPrevention !== false;
    this.consensusThreshold = options.consensusThreshold || 0.67;
    this.logger = options.logger || console.log;

    /** @type {Map<string, Conflict>} */
    this.conflicts = new Map();

    /** @type {Map<string, ResolutionStrategy>} */
    this.strategies = new Map();

    // Register default strategies
    this._registerDefaultStrategies();

    this.totalConflicts = 0;
    this.resolvedConflicts = 0;
    this.unresolvedConflicts = 0;
  }

  /**
   * Detects a conflict
   *
   * @param {string} type - Conflict type
   * @param {string[]} participants - Conflicting entity IDs
   * @param {Object} context - Conflict context
   * @returns {string} Conflict ID
   */
  detectConflict(type, participants, context = {}) {
    const conflict = {
      id: this._generateId(),
      type,
      participants,
      context,
      status: 'detected',
      detectedAt: new Date(),
      resolvedAt: null,
      resolution: null
    };

    this.conflicts.set(conflict.id, conflict);
    this.totalConflicts++;

    this.logger(`[ConflictArbiter] Conflict detected: ${type} between ${participants.join(', ')}`);

    this.emit('conflict:detected', { conflict });

    return conflict.id;
  }

  /**
   * Resolves a conflict using specified or default strategy
   *
   * @param {string} conflictId - Conflict ID
   * @param {string} [strategyName] - Strategy to use
   * @returns {Promise<any>} Resolution result
   */
  async resolve(conflictId, strategyName = null) {
    const conflict = this.conflicts.get(conflictId);

    if (!conflict) {
      throw new Error(`Conflict not found: ${conflictId}`);
    }

    if (conflict.status === 'resolved') {
      this.logger(`[ConflictArbiter] Conflict already resolved: ${conflictId}`);
      return conflict.resolution;
    }

    conflict.status = 'resolving';

    this.emit('conflict:resolving', { conflict });

    try {
      // Select resolution strategy
      const strategy = this._selectStrategy(conflict, strategyName);

      this.logger(`[ConflictArbiter] Resolving conflict ${conflictId} using ${strategy.name}`);

      // Apply strategy
      const resolution = await strategy.resolver(conflict);

      conflict.status = 'resolved';
      conflict.resolvedAt = new Date();
      conflict.resolution = resolution;

      this.resolvedConflicts++;

      this.logger(`[ConflictArbiter] Conflict resolved: ${conflictId}`);

      this.emit('conflict:resolved', { conflict, resolution });

      return resolution;

    } catch (error) {
      conflict.status = 'unresolved';
      conflict.error = error;

      this.unresolvedConflicts++;

      this.logger(`[ConflictArbiter] Failed to resolve conflict ${conflictId}: ${error.message}`);

      this.emit('conflict:unresolved', { conflict, error });

      throw error;
    }
  }

  /**
   * Registers a custom resolution strategy
   *
   * @param {ResolutionStrategy} strategy - Resolution strategy
   */
  registerStrategy(strategy) {
    this.strategies.set(strategy.name, strategy);

    this.logger(`[ConflictArbiter] Registered strategy: ${strategy.name}`);
  }

  /**
   * Selects appropriate resolution strategy
   *
   * @private
   * @param {Conflict} conflict - Conflict to resolve
   * @param {string} [preferredStrategy] - Preferred strategy name
   * @returns {ResolutionStrategy} Selected strategy
   */
  _selectStrategy(conflict, preferredStrategy = null) {
    // Use preferred strategy if specified
    if (preferredStrategy) {
      const strategy = this.strategies.get(preferredStrategy);

      if (strategy) {
        return strategy;
      }
    }

    // Find applicable strategies
    const applicable = Array.from(this.strategies.values())
      .filter(s => !s.applicability || s.applicability(conflict))
      .sort((a, b) => (b.priority || 0) - (a.priority || 0));

    if (applicable.length > 0) {
      return applicable[0];
    }

    // Fallback to default
    return this.strategies.get(this.defaultStrategy);
  }

  /**
   * Registers default resolution strategies
   *
   * @private
   */
  _registerDefaultStrategies() {
    // Priority-based resolution
    this.registerStrategy({
      name: 'priority',
      priority: 50,
      applicability: (conflict) => conflict.context.priorities !== undefined,
      resolver: async (conflict) => {
        const priorities = conflict.context.priorities || {};
        const participants = conflict.participants;

        // Select participant with highest priority
        let winner = participants[0];
        let maxPriority = priorities[winner] || 0;

        for (const participant of participants) {
          const priority = priorities[participant] || 0;

          if (priority > maxPriority) {
            maxPriority = priority;
            winner = participant;
          }
        }

        return {
          strategy: 'priority',
          winner,
          priority: maxPriority
        };
      }
    });

    // Negotiation-based resolution
    this.registerStrategy({
      name: 'negotiation',
      priority: 40,
      applicability: (conflict) => conflict.context.negotiate !== undefined,
      resolver: async (conflict) => {
        const participants = conflict.participants;
        const offers = {};

        // Collect offers from participants
        for (const participant of participants) {
          if (typeof conflict.context.negotiate === 'function') {
            offers[participant] = await conflict.context.negotiate(participant, conflict);
          }
        }

        // Find best offer
        const bestOffer = Object.entries(offers)
          .reduce((best, [participant, offer]) => {
            if (!best || offer.value > best.value) {
              return { participant, ...offer };
            }
            return best;
          }, null);

        return {
          strategy: 'negotiation',
          winner: bestOffer.participant,
          offer: bestOffer
        };
      }
    });

    // Optimization-based resolution
    this.registerStrategy({
      name: 'optimization',
      priority: 30,
      applicability: (conflict) => conflict.context.optimize !== undefined,
      resolver: async (conflict) => {
        const participants = conflict.participants;
        const scores = {};

        // Calculate optimization scores
        for (const participant of participants) {
          if (typeof conflict.context.optimize === 'function') {
            scores[participant] = await conflict.context.optimize(participant, conflict);
          }
        }

        // Select optimal participant
        const optimal = Object.entries(scores)
          .reduce((best, [participant, score]) => {
            if (!best || score > best.score) {
              return { participant, score };
            }
            return best;
          }, null);

        return {
          strategy: 'optimization',
          winner: optimal.participant,
          score: optimal.score
        };
      }
    });

    // Consensus-based resolution
    this.registerStrategy({
      name: 'consensus',
      priority: 60,
      applicability: (conflict) => conflict.context.voters !== undefined,
      resolver: async (conflict) => {
        const voters = conflict.context.voters || [];
        const votes = {};

        // Collect votes
        for (const voter of voters) {
          if (typeof conflict.context.vote === 'function') {
            const vote = await conflict.context.vote(voter, conflict);
            votes[vote] = (votes[vote] || 0) + 1;
          }
        }

        // Check if consensus reached
        const totalVotes = Object.values(votes).reduce((sum, v) => sum + v, 0);

        const winner = Object.entries(votes)
          .reduce((best, [participant, count]) => {
            if (!best || count > best.count) {
              return { participant, count };
            }
            return best;
          }, null);

        const consensusReached = winner && (winner.count / totalVotes) >= this.consensusThreshold;

        if (!consensusReached) {
          throw new Error('Consensus threshold not reached');
        }

        return {
          strategy: 'consensus',
          winner: winner.participant,
          votes: winner.count,
          consensusRate: ((winner.count / totalVotes) * 100).toFixed(2) + '%'
        };
      }
    });

    // First-come-first-served resolution
    this.registerStrategy({
      name: 'fcfs',
      priority: 10,
      resolver: async (conflict) => {
        // Use first participant
        const winner = conflict.participants[0];

        return {
          strategy: 'fcfs',
          winner
        };
      }
    });

    // Random resolution (fallback)
    this.registerStrategy({
      name: 'random',
      priority: 0,
      resolver: async (conflict) => {
        const participants = conflict.participants;
        const winner = participants[Math.floor(Math.random() * participants.length)];

        return {
          strategy: 'random',
          winner
        };
      }
    });
  }

  /**
   * Prevents deadlocks by detecting cycles
   *
   * @param {string[]} participants - Participant IDs
   * @param {Object} dependencies - Dependency graph
   * @returns {boolean} True if deadlock detected
   */
  detectDeadlock(participants, dependencies) {
    if (!this.enableDeadlockPrevention) {
      return false;
    }

    // Simple cycle detection in dependency graph
    const visited = new Set();
    const recursionStack = new Set();

    const hasCycle = (node) => {
      visited.add(node);
      recursionStack.add(node);

      const deps = dependencies[node] || [];

      for (const dep of deps) {
        if (!visited.has(dep)) {
          if (hasCycle(dep)) {
            return true;
          }
        } else if (recursionStack.has(dep)) {
          return true;
        }
      }

      recursionStack.delete(node);
      return false;
    };

    for (const participant of participants) {
      if (!visited.has(participant)) {
        if (hasCycle(participant)) {
          this.logger(`[ConflictArbiter] Deadlock detected among: ${participants.join(', ')}`);
          this.emit('deadlock:detected', { participants });
          return true;
        }
      }
    }

    return false;
  }

  /**
   * Gets conflict by ID
   *
   * @param {string} conflictId - Conflict ID
   * @returns {Conflict|null} Conflict
   */
  getConflict(conflictId) {
    return this.conflicts.get(conflictId) || null;
  }

  /**
   * Gets all conflicts by status
   *
   * @param {string} [status] - Filter by status
   * @returns {Conflict[]} Conflicts
   */
  getConflicts(status = null) {
    let conflicts = Array.from(this.conflicts.values());

    if (status) {
      conflicts = conflicts.filter(c => c.status === status);
    }

    return conflicts;
  }

  /**
   * Gets arbiter statistics
   *
   * @returns {Object} Statistics
   */
  getStats() {
    const resolutionRate = this.totalConflicts > 0
      ? (this.resolvedConflicts / this.totalConflicts) * 100
      : 0;

    const activeConflicts = this.getConflicts('detected').length +
                           this.getConflicts('resolving').length;

    return {
      totalConflicts: this.totalConflicts,
      resolvedConflicts: this.resolvedConflicts,
      unresolvedConflicts: this.unresolvedConflicts,
      activeConflicts,
      resolutionRate: resolutionRate.toFixed(2) + '%',
      strategies: this.strategies.size
    };
  }

  /**
   * Clears resolved conflicts
   */
  clearResolved() {
    for (const [id, conflict] of this.conflicts) {
      if (conflict.status === 'resolved') {
        this.conflicts.delete(id);
      }
    }

    this.emit('conflicts:cleared');
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

export default ConflictArbiter;
