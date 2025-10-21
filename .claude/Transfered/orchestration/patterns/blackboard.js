/**
 * Blackboard Pattern
 *
 * Implements shared knowledge space for multi-agent collaboration
 * with pattern recognition, synthesis, and conflict resolution.
 *
 * @module orchestration/patterns/blackboard
 */

import { EventEmitter } from 'events';

/**
 * @typedef {Object} KnowledgeSource
 * @property {string} id - Unique identifier
 * @property {string} name - Knowledge source name
 * @property {string} domain - Domain of expertise
 * @property {number} priority - Priority level (higher = more important)
 * @property {Function} canContribute - Function to check if KS can contribute
 * @property {Function} contribute - Function to make contributions
 * @property {string[]} triggers - Events that trigger this KS
 */

/**
 * @typedef {Object} KnowledgeEntry
 * @property {string} id - Entry identifier
 * @property {string} type - Entry type (fact, hypothesis, solution, etc.)
 * @property {string} sourceId - ID of contributing knowledge source
 * @property {any} content - Entry content
 * @property {number} confidence - Confidence score (0-1)
 * @property {Object} metadata - Additional metadata
 * @property {Date} timestamp - Creation timestamp
 * @property {string[]} tags - Categorization tags
 * @property {string[]} relatedEntries - Related entry IDs
 */

/**
 * @typedef {Object} Problem
 * @property {string} id - Problem identifier
 * @property {string} description - Problem description
 * @property {Object} initialState - Initial problem state
 * @property {Function} isSolved - Function to check if problem is solved
 * @property {Object} constraints - Problem constraints
 */

export class Blackboard extends EventEmitter {
  /**
   * Creates a new Blackboard system
   *
   * @param {Object} options - Configuration options
   * @param {number} [options.maxIterations=100] - Maximum reasoning iterations
   * @param {number} [options.convergenceThreshold=0.95] - Confidence threshold for solution
   * @param {number} [options.conflictResolutionStrategy='priority'] - Conflict resolution strategy
   * @param {Function} [options.logger] - Logger function
   */
  constructor(options = {}) {
    super();

    this.maxIterations = options.maxIterations || 100;
    this.convergenceThreshold = options.convergenceThreshold || 0.95;
    this.conflictResolutionStrategy = options.conflictResolutionStrategy || 'priority';
    this.logger = options.logger || console.log;

    /** @type {Map<string, KnowledgeEntry>} */
    this.knowledge = new Map();

    /** @type {Map<string, KnowledgeSource>} */
    this.knowledgeSources = new Map();

    /** @type {Problem|null} */
    this.currentProblem = null;

    /** @type {Object} */
    this.blackboardState = {
      facts: new Map(),
      hypotheses: new Map(),
      solutions: new Map(),
      agenda: []
    };

    this.iterationCount = 0;
  }

  /**
   * Registers a knowledge source
   *
   * @param {KnowledgeSource} ks - Knowledge source to register
   */
  registerKnowledgeSource(ks) {
    this._validateKnowledgeSource(ks);

    this.knowledgeSources.set(ks.id, ks);
    this.logger(`[Blackboard] Registered knowledge source: ${ks.name} (${ks.domain})`);

    this.emit('ks:registered', { ks });
  }

  /**
   * Unregisters a knowledge source
   *
   * @param {string} ksId - Knowledge source ID
   * @returns {boolean} Success status
   */
  unregisterKnowledgeSource(ksId) {
    const deleted = this.knowledgeSources.delete(ksId);

    if (deleted) {
      this.logger(`[Blackboard] Unregistered knowledge source: ${ksId}`);
      this.emit('ks:unregistered', { ksId });
    }

    return deleted;
  }

  /**
   * Solves a problem using collaborative reasoning
   *
   * @param {Problem} problem - Problem to solve
   * @returns {Promise<Object>} Solution with confidence score
   */
  async solve(problem) {
    this.logger(`[Blackboard] Starting problem solving: ${problem.description}`);

    this.currentProblem = problem;
    this.iterationCount = 0;

    // Initialize blackboard with problem state
    this._initializeBlackboard(problem);

    this.emit('problem:started', { problem });

    try {
      // Main reasoning loop
      while (this.iterationCount < this.maxIterations) {
        this.iterationCount++;

        this.logger(`[Blackboard] Iteration ${this.iterationCount}`);
        this.emit('iteration:started', { iteration: this.iterationCount });

        // Build agenda of knowledge sources ready to contribute
        const agenda = await this._buildAgenda();

        if (agenda.length === 0) {
          this.logger(`[Blackboard] No knowledge sources can contribute`);
          break;
        }

        // Execute top priority knowledge source
        const topKS = agenda[0];
        await this._executeKnowledgeSource(topKS);

        // Check for solution
        const solution = await this._checkForSolution();

        if (solution) {
          this.logger(`[Blackboard] Solution found with confidence: ${solution.confidence}`);
          this.emit('problem:solved', { problem, solution });
          return solution;
        }

        // Detect and resolve conflicts
        await this._resolveConflicts();

        // Synthesize patterns
        await this._synthesizePatterns();

        this.emit('iteration:completed', { iteration: this.iterationCount });
      }

      // No solution found
      const bestAttempt = this._getBestSolution();
      this.logger(`[Blackboard] Max iterations reached. Best solution confidence: ${bestAttempt?.confidence || 0}`);

      this.emit('problem:unsolved', { problem, bestAttempt });

      return bestAttempt || {
        content: null,
        confidence: 0,
        reason: 'No solution found within iteration limit'
      };

    } catch (error) {
      this.logger(`[Blackboard] Problem solving failed: ${error.message}`);
      this.emit('problem:failed', { problem, error });
      throw error;
    }
  }

  /**
   * Writes knowledge to the blackboard
   *
   * @param {string} type - Entry type
   * @param {string} sourceId - Source knowledge source ID
   * @param {any} content - Entry content
   * @param {number} confidence - Confidence score (0-1)
   * @param {Object} [metadata={}] - Additional metadata
   * @returns {KnowledgeEntry} Created entry
   */
  write(type, sourceId, content, confidence, metadata = {}) {
    const entry = {
      id: this._generateId(),
      type,
      sourceId,
      content,
      confidence: Math.max(0, Math.min(1, confidence)),
      metadata,
      timestamp: new Date(),
      tags: metadata.tags || [],
      relatedEntries: metadata.relatedEntries || []
    };

    this.knowledge.set(entry.id, entry);

    // Update state based on type
    if (type === 'fact') {
      this.blackboardState.facts.set(entry.id, entry);
    } else if (type === 'hypothesis') {
      this.blackboardState.hypotheses.set(entry.id, entry);
    } else if (type === 'solution') {
      this.blackboardState.solutions.set(entry.id, entry);
    }

    this.logger(`[Blackboard] Knowledge written: ${type} (confidence: ${confidence})`);
    this.emit('knowledge:written', { entry });

    return entry;
  }

  /**
   * Reads knowledge from the blackboard
   *
   * @param {Object} [query={}] - Query parameters
   * @param {string} [query.type] - Entry type filter
   * @param {string} [query.sourceId] - Source filter
   * @param {string[]} [query.tags] - Tags filter
   * @param {number} [query.minConfidence] - Minimum confidence
   * @returns {KnowledgeEntry[]} Matching entries
   */
  read(query = {}) {
    let entries = Array.from(this.knowledge.values());

    // Apply filters
    if (query.type) {
      entries = entries.filter(e => e.type === query.type);
    }

    if (query.sourceId) {
      entries = entries.filter(e => e.sourceId === query.sourceId);
    }

    if (query.tags && query.tags.length > 0) {
      entries = entries.filter(e =>
        query.tags.some(tag => e.tags.includes(tag))
      );
    }

    if (query.minConfidence !== undefined) {
      entries = entries.filter(e => e.confidence >= query.minConfidence);
    }

    // Sort by confidence (highest first)
    entries.sort((a, b) => b.confidence - a.confidence);

    return entries;
  }

  /**
   * Updates an existing knowledge entry
   *
   * @param {string} entryId - Entry ID to update
   * @param {Object} updates - Updates to apply
   * @returns {boolean} Success status
   */
  update(entryId, updates) {
    const entry = this.knowledge.get(entryId);

    if (!entry) {
      return false;
    }

    // Apply updates
    Object.assign(entry, updates);

    this.emit('knowledge:updated', { entry });

    return true;
  }

  /**
   * Removes knowledge from the blackboard
   *
   * @param {string} entryId - Entry ID to remove
   * @returns {boolean} Success status
   */
  remove(entryId) {
    const entry = this.knowledge.get(entryId);

    if (!entry) {
      return false;
    }

    this.knowledge.delete(entryId);

    // Remove from state
    this.blackboardState.facts.delete(entryId);
    this.blackboardState.hypotheses.delete(entryId);
    this.blackboardState.solutions.delete(entryId);

    this.emit('knowledge:removed', { entryId });

    return true;
  }

  /**
   * Initializes the blackboard with problem state
   *
   * @private
   * @param {Problem} problem - Problem to initialize with
   */
  _initializeBlackboard(problem) {
    this.knowledge.clear();
    this.blackboardState = {
      facts: new Map(),
      hypotheses: new Map(),
      solutions: new Map(),
      agenda: []
    };

    // Add initial facts from problem state
    if (problem.initialState) {
      for (const [key, value] of Object.entries(problem.initialState)) {
        this.write('fact', 'system', { key, value }, 1.0, {
          tags: ['initial', 'system']
        });
      }
    }
  }

  /**
   * Builds agenda of knowledge sources ready to contribute
   *
   * @private
   * @returns {Promise<KnowledgeSource[]>} Sorted list of ready knowledge sources
   */
  async _buildAgenda() {
    const ready = [];

    for (const ks of this.knowledgeSources.values()) {
      try {
        const canContribute = await ks.canContribute(this.blackboardState, this.currentProblem);

        if (canContribute) {
          ready.push(ks);
        }
      } catch (error) {
        this.logger(`[Blackboard] Error checking KS ${ks.id}: ${error.message}`);
      }
    }

    // Sort by priority (highest first)
    ready.sort((a, b) => b.priority - a.priority);

    this.blackboardState.agenda = ready;

    return ready;
  }

  /**
   * Executes a knowledge source
   *
   * @private
   * @param {KnowledgeSource} ks - Knowledge source to execute
   */
  async _executeKnowledgeSource(ks) {
    this.logger(`[Blackboard] Executing KS: ${ks.name}`);

    this.emit('ks:executing', { ks });

    try {
      await ks.contribute(this, this.currentProblem);

      this.emit('ks:executed', { ks });

    } catch (error) {
      this.logger(`[Blackboard] KS execution failed: ${ks.id} - ${error.message}`);
      this.emit('ks:failed', { ks, error });
    }
  }

  /**
   * Checks if a solution has been found
   *
   * @private
   * @returns {Promise<Object|null>} Solution if found
   */
  async _checkForSolution() {
    // Check if problem-specific solution checker exists
    if (this.currentProblem && typeof this.currentProblem.isSolved === 'function') {
      const solved = await this.currentProblem.isSolved(this.blackboardState);

      if (solved) {
        return this._getBestSolution();
      }
    }

    // Check if we have high-confidence solution
    const solutions = Array.from(this.blackboardState.solutions.values());

    if (solutions.length > 0) {
      const bestSolution = solutions.reduce((best, sol) =>
        sol.confidence > best.confidence ? sol : best
      );

      if (bestSolution.confidence >= this.convergenceThreshold) {
        return bestSolution;
      }
    }

    return null;
  }

  /**
   * Gets the best solution available
   *
   * @private
   * @returns {Object|null} Best solution
   */
  _getBestSolution() {
    const solutions = Array.from(this.blackboardState.solutions.values());

    if (solutions.length === 0) {
      return null;
    }

    return solutions.reduce((best, sol) =>
      sol.confidence > best.confidence ? sol : best
    );
  }

  /**
   * Resolves conflicts between knowledge entries
   *
   * @private
   */
  async _resolveConflicts() {
    // Find conflicting entries (same topic, different conclusions)
    const conflicts = this._detectConflicts();

    if (conflicts.length === 0) {
      return;
    }

    this.logger(`[Blackboard] Resolving ${conflicts.length} conflicts`);

    for (const conflict of conflicts) {
      await this._resolveConflict(conflict);
    }
  }

  /**
   * Detects conflicts in knowledge base
   *
   * @private
   * @returns {Array} Detected conflicts
   */
  _detectConflicts() {
    const conflicts = [];
    const entries = Array.from(this.knowledge.values());

    // Group entries by tags
    const tagGroups = new Map();

    for (const entry of entries) {
      for (const tag of entry.tags) {
        if (!tagGroups.has(tag)) {
          tagGroups.set(tag, []);
        }
        tagGroups.get(tag).push(entry);
      }
    }

    // Check each group for conflicts
    for (const [tag, group] of tagGroups) {
      if (group.length > 1) {
        // Simple conflict detection: different content for same tag
        const contents = new Set(group.map(e => JSON.stringify(e.content)));

        if (contents.size > 1) {
          conflicts.push({
            tag,
            entries: group
          });
        }
      }
    }

    return conflicts;
  }

  /**
   * Resolves a specific conflict
   *
   * @private
   * @param {Object} conflict - Conflict to resolve
   */
  async _resolveConflict(conflict) {
    const { entries } = conflict;

    if (this.conflictResolutionStrategy === 'priority') {
      // Keep highest priority source's entry
      const best = entries.reduce((best, entry) => {
        const ks1 = this.knowledgeSources.get(entry.sourceId);
        const ks2 = this.knowledgeSources.get(best.sourceId);

        return (ks1?.priority || 0) > (ks2?.priority || 0) ? entry : best;
      });

      // Remove others
      for (const entry of entries) {
        if (entry.id !== best.id) {
          this.remove(entry.id);
        }
      }

    } else if (this.conflictResolutionStrategy === 'confidence') {
      // Keep highest confidence entry
      const best = entries.reduce((best, entry) =>
        entry.confidence > best.confidence ? entry : best
      );

      // Remove others
      for (const entry of entries) {
        if (entry.id !== best.id) {
          this.remove(entry.id);
        }
      }

    } else if (this.conflictResolutionStrategy === 'voting') {
      // Majority voting
      const votes = new Map();

      for (const entry of entries) {
        const key = JSON.stringify(entry.content);
        votes.set(key, (votes.get(key) || 0) + entry.confidence);
      }

      const winner = Array.from(votes.entries())
        .reduce((best, [key, score]) => score > best.score ? { key, score } : best, { score: 0 });

      // Keep entries matching winner
      for (const entry of entries) {
        if (JSON.stringify(entry.content) !== winner.key) {
          this.remove(entry.id);
        }
      }
    }

    this.emit('conflict:resolved', { conflict });
  }

  /**
   * Synthesizes patterns from knowledge base
   *
   * @private
   */
  async _synthesizePatterns() {
    // Look for patterns in facts and hypotheses
    const facts = Array.from(this.blackboardState.facts.values());
    const hypotheses = Array.from(this.blackboardState.hypotheses.values());

    // Simple pattern: if we have multiple high-confidence hypotheses, synthesize
    const highConfidenceHypotheses = hypotheses.filter(h => h.confidence > 0.7);

    if (highConfidenceHypotheses.length >= 2) {
      // Combine them into a synthesis
      const synthesis = {
        type: 'synthesis',
        sources: highConfidenceHypotheses.map(h => h.id),
        confidence: highConfidenceHypotheses.reduce((sum, h) => sum + h.confidence, 0) / highConfidenceHypotheses.length
      };

      this.emit('pattern:synthesized', { synthesis });
    }
  }

  /**
   * Validates a knowledge source
   *
   * @private
   * @param {KnowledgeSource} ks - Knowledge source to validate
   * @throws {Error} If validation fails
   */
  _validateKnowledgeSource(ks) {
    if (!ks.id || !ks.name || !ks.domain) {
      throw new Error('Knowledge source must have id, name, and domain');
    }

    if (typeof ks.canContribute !== 'function') {
      throw new Error('Knowledge source must have canContribute function');
    }

    if (typeof ks.contribute !== 'function') {
      throw new Error('Knowledge source must have contribute function');
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
   * Clears the blackboard
   */
  clear() {
    this.knowledge.clear();
    this.blackboardState = {
      facts: new Map(),
      hypotheses: new Map(),
      solutions: new Map(),
      agenda: []
    };
    this.currentProblem = null;
    this.iterationCount = 0;

    this.emit('blackboard:cleared');
  }
}

export default Blackboard;
