/**
 * Event Sourcing Pattern
 *
 * Implements event-driven coordination with append-only event log,
 * state reconstruction, and time-travel debugging capabilities.
 *
 * @module orchestration/patterns/event-sourcing
 */

import { EventEmitter } from 'events';

/**
 * @typedef {Object} Event
 * @property {string} id - Unique event identifier
 * @property {string} type - Event type
 * @property {string} aggregateId - ID of the aggregate this event belongs to
 * @property {number} version - Event version number
 * @property {any} data - Event data payload
 * @property {Object} metadata - Event metadata (user, timestamp, etc.)
 * @property {Date} timestamp - Event timestamp
 */

/**
 * @typedef {Object} EventHandler
 * @property {string} eventType - Type of event this handler processes
 * @property {Function} handler - Handler function
 * @property {number} priority - Handler priority
 * @property {boolean} async - Whether handler is async
 */

/**
 * @typedef {Object} Snapshot
 * @property {string} aggregateId - Aggregate ID
 * @property {number} version - Snapshot version
 * @property {any} state - Aggregate state at this version
 * @property {Date} timestamp - Snapshot timestamp
 */

export class EventSourcing extends EventEmitter {
  /**
   * Creates a new Event Sourcing system
   *
   * @param {Object} options - Configuration options
   * @param {number} [options.snapshotInterval=10] - Create snapshot every N events
   * @param {number} [options.maxEventLogSize=10000] - Maximum events to keep in memory
   * @param {boolean} [options.enableTimeTravel=true] - Enable time-travel debugging
   * @param {Function} [options.logger] - Logger function
   */
  constructor(options = {}) {
    super();

    this.snapshotInterval = options.snapshotInterval || 10;
    this.maxEventLogSize = options.maxEventLogSize || 10000;
    this.enableTimeTravel = options.enableTimeTravel !== false;
    this.logger = options.logger || console.log;

    /** @type {Event[]} Append-only event log */
    this.eventLog = [];

    /** @type {Map<string, EventHandler[]>} Event handlers by event type */
    this.handlers = new Map();

    /** @type {Map<string, Snapshot>} Snapshots by aggregate ID */
    this.snapshots = new Map();

    /** @type {Map<string, any>} Current state by aggregate ID */
    this.currentStates = new Map();

    /** @type {Map<string, Function>} State reducers by aggregate type */
    this.reducers = new Map();

    this.eventCount = 0;
  }

  /**
   * Registers an event handler
   *
   * @param {string} eventType - Event type to handle
   * @param {Function} handler - Handler function
   * @param {Object} [options={}] - Handler options
   * @param {number} [options.priority=0] - Handler priority
   * @returns {string} Handler ID
   */
  on(eventType, handler, options = {}) {
    const handlerObj = {
      id: this._generateId(),
      eventType,
      handler,
      priority: options.priority || 0,
      async: handler.constructor.name === 'AsyncFunction'
    };

    if (!this.handlers.has(eventType)) {
      this.handlers.set(eventType, []);
    }

    this.handlers.get(eventType).push(handlerObj);

    // Sort handlers by priority (highest first)
    this.handlers.get(eventType).sort((a, b) => b.priority - a.priority);

    this.logger(`[EventSourcing] Registered handler for event type: ${eventType}`);

    return handlerObj.id;
  }

  /**
   * Unregisters an event handler
   *
   * @param {string} handlerId - Handler ID to unregister
   * @returns {boolean} Success status
   */
  off(handlerId) {
    for (const [eventType, handlers] of this.handlers) {
      const index = handlers.findIndex(h => h.id === handlerId);

      if (index !== -1) {
        handlers.splice(index, 1);
        this.logger(`[EventSourcing] Unregistered handler: ${handlerId}`);
        return true;
      }
    }

    return false;
  }

  /**
   * Registers a state reducer for an aggregate type
   *
   * @param {string} aggregateType - Aggregate type
   * @param {Function} reducer - Reducer function (state, event) => newState
   */
  registerReducer(aggregateType, reducer) {
    if (typeof reducer !== 'function') {
      throw new Error('Reducer must be a function');
    }

    this.reducers.set(aggregateType, reducer);
    this.logger(`[EventSourcing] Registered reducer for aggregate type: ${aggregateType}`);
  }

  /**
   * Appends an event to the log
   *
   * @param {string} type - Event type
   * @param {string} aggregateId - Aggregate ID
   * @param {any} data - Event data
   * @param {Object} [metadata={}] - Event metadata
   * @returns {Promise<Event>} The appended event
   */
  async appendEvent(type, aggregateId, data, metadata = {}) {
    // Get current version for this aggregate
    const currentVersion = this._getAggregateVersion(aggregateId);

    const event = {
      id: this._generateId(),
      type,
      aggregateId,
      version: currentVersion + 1,
      data,
      metadata: {
        ...metadata,
        correlationId: metadata.correlationId || this._generateId(),
        causationId: metadata.causationId || null
      },
      timestamp: new Date()
    };

    // Append to log (append-only)
    this.eventLog.push(event);
    this.eventCount++;

    this.logger(`[EventSourcing] Event appended: ${type} (version ${event.version})`);

    this.emit('event:appended', { event });

    // Process event handlers
    await this._processEventHandlers(event);

    // Update current state
    await this._applyEventToState(event);

    // Create snapshot if needed
    if (event.version % this.snapshotInterval === 0) {
      await this._createSnapshot(aggregateId);
    }

    // Prune event log if too large
    if (this.eventLog.length > this.maxEventLogSize) {
      this._pruneEventLog();
    }

    return event;
  }

  /**
   * Reconstructs state from events
   *
   * @param {string} aggregateId - Aggregate ID
   * @param {string} aggregateType - Aggregate type
   * @param {number} [toVersion] - Reconstruct to specific version (for time-travel)
   * @returns {any} Reconstructed state
   */
  async reconstructState(aggregateId, aggregateType, toVersion = null) {
    this.logger(`[EventSourcing] Reconstructing state for aggregate: ${aggregateId}`);

    // Get reducer for this aggregate type
    const reducer = this.reducers.get(aggregateType);

    if (!reducer) {
      throw new Error(`No reducer registered for aggregate type: ${aggregateType}`);
    }

    // Find the latest snapshot before toVersion
    let state = null;
    let startVersion = 0;

    const snapshot = this.snapshots.get(aggregateId);

    if (snapshot && (!toVersion || snapshot.version <= toVersion)) {
      state = snapshot.state;
      startVersion = snapshot.version;
      this.logger(`[EventSourcing] Starting from snapshot at version ${startVersion}`);
    }

    // Get events for this aggregate
    const events = this.eventLog.filter(e =>
      e.aggregateId === aggregateId &&
      e.version > startVersion &&
      (!toVersion || e.version <= toVersion)
    );

    // Apply events to reconstruct state
    for (const event of events) {
      state = await reducer(state, event);
    }

    return state;
  }

  /**
   * Gets current state of an aggregate
   *
   * @param {string} aggregateId - Aggregate ID
   * @returns {any} Current state
   */
  getCurrentState(aggregateId) {
    return this.currentStates.get(aggregateId);
  }

  /**
   * Gets all events for an aggregate
   *
   * @param {string} aggregateId - Aggregate ID
   * @param {Object} [options={}] - Query options
   * @param {number} [options.fromVersion] - Start version
   * @param {number} [options.toVersion] - End version
   * @returns {Event[]} Matching events
   */
  getEvents(aggregateId, options = {}) {
    return this.eventLog.filter(e =>
      e.aggregateId === aggregateId &&
      (!options.fromVersion || e.version >= options.fromVersion) &&
      (!options.toVersion || e.version <= options.toVersion)
    );
  }

  /**
   * Gets all events of a specific type
   *
   * @param {string} eventType - Event type
   * @param {Object} [options={}] - Query options
   * @returns {Event[]} Matching events
   */
  getEventsByType(eventType, options = {}) {
    return this.eventLog.filter(e => e.type === eventType);
  }

  /**
   * Replays events to rebuild state
   *
   * @param {string} aggregateId - Aggregate ID
   * @param {string} aggregateType - Aggregate type
   * @returns {Promise<any>} Rebuilt state
   */
  async replay(aggregateId, aggregateType) {
    this.logger(`[EventSourcing] Replaying events for aggregate: ${aggregateId}`);

    const state = await this.reconstructState(aggregateId, aggregateType);

    this.currentStates.set(aggregateId, state);

    this.emit('state:replayed', { aggregateId, state });

    return state;
  }

  /**
   * Time-travel to a specific point in time
   *
   * @param {string} aggregateId - Aggregate ID
   * @param {string} aggregateType - Aggregate type
   * @param {Date|number} pointInTime - Timestamp or version number
   * @returns {Promise<any>} State at that point in time
   */
  async timeTravel(aggregateId, aggregateType, pointInTime) {
    if (!this.enableTimeTravel) {
      throw new Error('Time-travel debugging is disabled');
    }

    this.logger(`[EventSourcing] Time-traveling for aggregate: ${aggregateId}`);

    let toVersion;

    if (typeof pointInTime === 'number') {
      // Version number
      toVersion = pointInTime;
    } else {
      // Timestamp
      const events = this.getEvents(aggregateId);
      const event = events.find(e => e.timestamp <= pointInTime);
      toVersion = event ? event.version : 0;
    }

    const state = await this.reconstructState(aggregateId, aggregateType, toVersion);

    this.emit('timetravel:completed', { aggregateId, toVersion, state });

    return state;
  }

  /**
   * Creates a snapshot of aggregate state
   *
   * @private
   * @param {string} aggregateId - Aggregate ID
   */
  async _createSnapshot(aggregateId) {
    const state = this.currentStates.get(aggregateId);

    if (!state) {
      return;
    }

    const version = this._getAggregateVersion(aggregateId);

    const snapshot = {
      aggregateId,
      version,
      state: JSON.parse(JSON.stringify(state)), // Deep clone
      timestamp: new Date()
    };

    this.snapshots.set(aggregateId, snapshot);

    this.logger(`[EventSourcing] Snapshot created for aggregate ${aggregateId} at version ${version}`);

    this.emit('snapshot:created', { snapshot });
  }

  /**
   * Gets the current version of an aggregate
   *
   * @private
   * @param {string} aggregateId - Aggregate ID
   * @returns {number} Current version
   */
  _getAggregateVersion(aggregateId) {
    const events = this.eventLog.filter(e => e.aggregateId === aggregateId);

    if (events.length === 0) {
      return 0;
    }

    return Math.max(...events.map(e => e.version));
  }

  /**
   * Processes event handlers for an event
   *
   * @private
   * @param {Event} event - Event to process
   */
  async _processEventHandlers(event) {
    const handlers = this.handlers.get(event.type) || [];

    if (handlers.length === 0) {
      return;
    }

    this.logger(`[EventSourcing] Processing ${handlers.length} handlers for event: ${event.type}`);

    for (const handlerObj of handlers) {
      try {
        await handlerObj.handler(event);
      } catch (error) {
        this.logger(`[EventSourcing] Handler error: ${error.message}`);
        this.emit('handler:error', { event, handler: handlerObj, error });
      }
    }
  }

  /**
   * Applies an event to current state
   *
   * @private
   * @param {Event} event - Event to apply
   */
  async _applyEventToState(event) {
    // Find reducer by trying common aggregate type patterns
    let reducer = null;
    let aggregateType = null;

    // Try to find reducer from event metadata
    if (event.metadata.aggregateType) {
      aggregateType = event.metadata.aggregateType;
      reducer = this.reducers.get(aggregateType);
    }

    // Try to infer from event type (e.g., "UserCreated" -> "User")
    if (!reducer) {
      const match = event.type.match(/^(\w+)/);
      if (match) {
        aggregateType = match[1];
        reducer = this.reducers.get(aggregateType);
      }
    }

    if (!reducer) {
      // No reducer found, skip state update
      return;
    }

    const currentState = this.currentStates.get(event.aggregateId);
    const newState = await reducer(currentState, event);

    this.currentStates.set(event.aggregateId, newState);

    this.emit('state:updated', { aggregateId: event.aggregateId, state: newState });
  }

  /**
   * Prunes old events from the log
   *
   * @private
   */
  _pruneEventLog() {
    // Keep only recent events that are after the last snapshots
    const keptEvents = [];

    for (const event of this.eventLog) {
      const snapshot = this.snapshots.get(event.aggregateId);

      if (!snapshot || event.version > snapshot.version) {
        keptEvents.push(event);
      }
    }

    const pruned = this.eventLog.length - keptEvents.length;
    this.eventLog = keptEvents;

    this.logger(`[EventSourcing] Pruned ${pruned} events from log`);

    this.emit('log:pruned', { pruned, remaining: keptEvents.length });
  }

  /**
   * Gets event stream statistics
   *
   * @returns {Object} Statistics
   */
  getStats() {
    return {
      totalEvents: this.eventCount,
      eventsInLog: this.eventLog.length,
      aggregates: this.currentStates.size,
      snapshots: this.snapshots.size,
      handlers: Array.from(this.handlers.values()).reduce((sum, h) => sum + h.length, 0)
    };
  }

  /**
   * Exports event log
   *
   * @param {Object} [options={}] - Export options
   * @returns {Event[]} Event log
   */
  exportEventLog(options = {}) {
    let events = [...this.eventLog];

    if (options.aggregateId) {
      events = events.filter(e => e.aggregateId === options.aggregateId);
    }

    if (options.eventType) {
      events = events.filter(e => e.type === options.eventType);
    }

    if (options.fromTimestamp) {
      events = events.filter(e => e.timestamp >= options.fromTimestamp);
    }

    if (options.toTimestamp) {
      events = events.filter(e => e.timestamp <= options.toTimestamp);
    }

    return events;
  }

  /**
   * Imports event log
   *
   * @param {Event[]} events - Events to import
   * @param {Object} [options={}] - Import options
   * @param {boolean} [options.replay=true] - Replay events after import
   */
  async importEventLog(events, options = {}) {
    const replay = options.replay !== false;

    this.logger(`[EventSourcing] Importing ${events.length} events`);

    // Add events to log
    for (const event of events) {
      this.eventLog.push(event);
    }

    // Sort by version
    this.eventLog.sort((a, b) => a.version - b.version);

    if (replay) {
      // Replay all aggregates
      const aggregateIds = new Set(events.map(e => e.aggregateId));

      for (const aggregateId of aggregateIds) {
        const event = events.find(e => e.aggregateId === aggregateId);
        if (event && event.metadata.aggregateType) {
          await this.replay(aggregateId, event.metadata.aggregateType);
        }
      }
    }

    this.emit('log:imported', { events: events.length });
  }

  /**
   * Clears all data
   */
  clear() {
    this.eventLog = [];
    this.snapshots.clear();
    this.currentStates.clear();
    this.eventCount = 0;

    this.emit('system:cleared');
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

export default EventSourcing;
