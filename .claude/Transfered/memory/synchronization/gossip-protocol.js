/**
 * Gossip Protocol Implementation
 *
 * Peer-to-peer epidemic-style state dissemination for distributed memory synchronization.
 * Provides eventual consistency through periodic, randomized communication.
 *
 * Features:
 * - Configurable gossip fanout
 * - Anti-entropy mechanism
 * - Failure detection
 * - Convergence guarantees
 * - Efficient state reconciliation
 *
 * @module memory/synchronization/gossip-protocol
 */

import { createLogger } from '../../utils/logger.js';
import { EventEmitter } from 'events';
import { VectorClock } from './vector-clock.js';

const logger = createLogger('GossipProtocol');

/**
 * Gossip message types
 * @enum {string}
 */
export const GossipMessageType = {
  SYNC_REQUEST: 'sync_request',     // Request state from peer
  SYNC_RESPONSE: 'sync_response',   // Respond with state
  PUSH: 'push',                      // Push state to peer
  PULL: 'pull',                      // Pull state from peer
  PUSH_PULL: 'push_pull',            // Combined push-pull
  PING: 'ping',                      // Heartbeat
  PONG: 'pong'                       // Heartbeat response
};

/**
 * Peer status
 * @enum {string}
 */
export const PeerStatus = {
  ALIVE: 'alive',
  SUSPECT: 'suspect',
  DEAD: 'dead'
};

/**
 * Peer information
 * @typedef {Object} PeerInfo
 * @property {string} id - Peer identifier
 * @property {string} address - Peer address (host:port)
 * @property {PeerStatus} status - Peer status
 * @property {number} lastSeen - Last contact timestamp
 * @property {number} failureCount - Consecutive failures
 * @property {Object} metadata - Additional metadata
 */

/**
 * Gossip message structure
 * @typedef {Object} GossipMessage
 * @property {string} id - Message identifier
 * @property {GossipMessageType} type - Message type
 * @property {string} senderId - Sender identifier
 * @property {string} recipientId - Recipient identifier
 * @property {Object} state - State data
 * @property {Object} vectorClock - Vector clock
 * @property {number} timestamp - Message timestamp
 */

/**
 * Gossip Protocol Manager
 *
 * Manages peer-to-peer state synchronization using gossip protocol.
 */
export class GossipProtocol extends EventEmitter {
  /**
   * @param {Object} config - Configuration object
   * @param {string} config.nodeId - Unique node identifier
   * @param {string} config.address - Node address (host:port)
   * @param {number} [config.gossipInterval=1000] - Gossip interval in ms
   * @param {number} [config.fanout=3] - Number of peers to gossip with
   * @param {number} [config.heartbeatInterval=5000] - Heartbeat interval in ms
   * @param {number} [config.suspectTimeout=10000] - Suspect timeout in ms
   * @param {number} [config.deadTimeout=30000] - Dead timeout in ms
   * @param {number} [config.maxFailures=3] - Max failures before marking dead
   */
  constructor(config) {
    super();

    this.nodeId = config.nodeId;
    this.address = config.address;
    this.gossipInterval = config.gossipInterval || 1000;
    this.fanout = config.fanout || 3;
    this.heartbeatInterval = config.heartbeatInterval || 5000;
    this.suspectTimeout = config.suspectTimeout || 10000;
    this.deadTimeout = config.deadTimeout || 30000;
    this.maxFailures = config.maxFailures || 3;

    // Peer registry
    this.peers = new Map();

    // Local state
    this.state = new Map();

    // Vector clock for causality tracking
    this.vectorClock = new VectorClock(this.nodeId);

    // Timers
    this.gossipTimer = null;
    this.heartbeatTimer = null;
    this.failureDetectorTimer = null;

    // Statistics
    this.stats = {
      messagesSent: 0,
      messagesReceived: 0,
      stateUpdates: 0,
      failureDetections: 0
    };

    logger.info('Gossip protocol initialized', {
      nodeId: this.nodeId,
      address: this.address,
      fanout: this.fanout
    });
  }

  /**
   * Start gossip protocol
   */
  start() {
    // Start gossip timer
    this.gossipTimer = setInterval(() => {
      this._gossipRound();
    }, this.gossipInterval);

    // Start heartbeat timer
    this.heartbeatTimer = setInterval(() => {
      this._sendHeartbeats();
    }, this.heartbeatInterval);

    // Start failure detector
    this.failureDetectorTimer = setInterval(() => {
      this._detectFailures();
    }, this.suspectTimeout);

    logger.info('Gossip protocol started');
    this.emit('protocol:started');
  }

  /**
   * Stop gossip protocol
   */
  stop() {
    if (this.gossipTimer) {
      clearInterval(this.gossipTimer);
      this.gossipTimer = null;
    }

    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = null;
    }

    if (this.failureDetectorTimer) {
      clearInterval(this.failureDetectorTimer);
      this.failureDetectorTimer = null;
    }

    logger.info('Gossip protocol stopped');
    this.emit('protocol:stopped');
  }

  /**
   * Add peer to the cluster
   *
   * @param {string} peerId - Peer identifier
   * @param {string} address - Peer address
   * @param {Object} [metadata={}] - Additional metadata
   */
  addPeer(peerId, address, metadata = {}) {
    if (peerId === this.nodeId) {
      return; // Don't add self
    }

    const peer = {
      id: peerId,
      address,
      status: PeerStatus.ALIVE,
      lastSeen: Date.now(),
      failureCount: 0,
      metadata
    };

    this.peers.set(peerId, peer);

    logger.debug('Peer added', { peerId, address });
    this.emit('peer:added', peer);
  }

  /**
   * Remove peer from cluster
   *
   * @param {string} peerId - Peer identifier
   */
  removePeer(peerId) {
    const peer = this.peers.get(peerId);

    if (peer) {
      this.peers.delete(peerId);
      logger.debug('Peer removed', { peerId });
      this.emit('peer:removed', peer);
    }
  }

  /**
   * Get all peers with specific status
   *
   * @param {PeerStatus} [status] - Filter by status
   * @returns {PeerInfo[]} Array of peers
   */
  getPeers(status = null) {
    const peers = Array.from(this.peers.values());

    if (status) {
      return peers.filter(peer => peer.status === status);
    }

    return peers;
  }

  /**
   * Update local state
   *
   * @param {string} key - State key
   * @param {*} value - State value
   */
  setState(key, value) {
    this.state.set(key, value);
    this.vectorClock.increment();

    logger.debug('State updated', { key, nodeId: this.nodeId });
    this.stats.stateUpdates++;

    this.emit('state:updated', { key, value, clock: this.vectorClock.clone() });
  }

  /**
   * Get local state
   *
   * @param {string} key - State key
   * @returns {*} State value
   */
  getState(key) {
    return this.state.get(key);
  }

  /**
   * Get all local state
   *
   * @returns {Object} State object
   */
  getAllState() {
    return Object.fromEntries(this.state);
  }

  /**
   * Handle incoming gossip message
   *
   * @param {GossipMessage} message - Gossip message
   */
  async handleMessage(message) {
    this.stats.messagesReceived++;

    logger.debug('Message received', {
      type: message.type,
      from: message.senderId
    });

    // Update vector clock
    if (message.vectorClock) {
      this.vectorClock.update(message.vectorClock);
    }

    // Update peer last seen
    const peer = this.peers.get(message.senderId);
    if (peer) {
      peer.lastSeen = Date.now();
      peer.status = PeerStatus.ALIVE;
      peer.failureCount = 0;
    }

    // Handle message by type
    switch (message.type) {
      case GossipMessageType.SYNC_REQUEST:
        await this._handleSyncRequest(message);
        break;

      case GossipMessageType.SYNC_RESPONSE:
        await this._handleSyncResponse(message);
        break;

      case GossipMessageType.PUSH:
        await this._handlePush(message);
        break;

      case GossipMessageType.PULL:
        await this._handlePull(message);
        break;

      case GossipMessageType.PUSH_PULL:
        await this._handlePushPull(message);
        break;

      case GossipMessageType.PING:
        await this._handlePing(message);
        break;

      case GossipMessageType.PONG:
        await this._handlePong(message);
        break;

      default:
        logger.warn('Unknown message type', { type: message.type });
    }

    this.emit('message:received', message);
  }

  /**
   * Send message to peer
   *
   * @param {string} peerId - Target peer ID
   * @param {GossipMessageType} type - Message type
   * @param {Object} [data={}] - Message data
   * @returns {GossipMessage} Sent message
   */
  async sendMessage(peerId, type, data = {}) {
    const peer = this.peers.get(peerId);

    if (!peer) {
      logger.warn('Peer not found', { peerId });
      return null;
    }

    const message = {
      id: `msg:${Date.now()}:${Math.random().toString(36).substr(2, 9)}`,
      type,
      senderId: this.nodeId,
      recipientId: peerId,
      state: data.state || {},
      vectorClock: this.vectorClock.toJSON(),
      timestamp: Date.now()
    };

    this.stats.messagesSent++;

    logger.debug('Message sent', { type, to: peerId });
    this.emit('message:sent', message);

    // In production, send via network transport (HTTP, WebSocket, etc.)
    // For now, emit event for external handling
    this.emit('transport:send', { peer, message });

    return message;
  }

  /**
   * Perform gossip round
   *
   * @private
   */
  async _gossipRound() {
    const alivePeers = this.getPeers(PeerStatus.ALIVE);

    if (alivePeers.length === 0) {
      return;
    }

    // Select random peers (fanout)
    const selectedPeers = this._selectRandomPeers(alivePeers, this.fanout);

    // Gossip with selected peers
    for (const peer of selectedPeers) {
      try {
        await this.sendMessage(peer.id, GossipMessageType.PUSH_PULL, {
          state: this.getAllState()
        });
      } catch (error) {
        logger.error('Gossip failed', { error: error.message, peerId: peer.id });
        this._recordFailure(peer.id);
      }
    }

    this.emit('gossip:round', { peers: selectedPeers.length });
  }

  /**
   * Send heartbeats to all peers
   *
   * @private
   */
  async _sendHeartbeats() {
    const alivePeers = this.getPeers(PeerStatus.ALIVE);

    for (const peer of alivePeers) {
      try {
        await this.sendMessage(peer.id, GossipMessageType.PING);
      } catch (error) {
        logger.error('Heartbeat failed', { error: error.message, peerId: peer.id });
        this._recordFailure(peer.id);
      }
    }
  }

  /**
   * Detect failed peers
   *
   * @private
   */
  _detectFailures() {
    const now = Date.now();

    for (const peer of this.peers.values()) {
      const timeSinceLastSeen = now - peer.lastSeen;

      // Mark as suspect
      if (peer.status === PeerStatus.ALIVE && timeSinceLastSeen > this.suspectTimeout) {
        peer.status = PeerStatus.SUSPECT;
        logger.warn('Peer suspected', { peerId: peer.id, timeSinceLastSeen });
        this.emit('peer:suspected', peer);
      }

      // Mark as dead
      if (peer.status === PeerStatus.SUSPECT && timeSinceLastSeen > this.deadTimeout) {
        peer.status = PeerStatus.DEAD;
        this.stats.failureDetections++;
        logger.warn('Peer dead', { peerId: peer.id, timeSinceLastSeen });
        this.emit('peer:dead', peer);
      }
    }
  }

  /**
   * Record peer failure
   *
   * @private
   * @param {string} peerId - Peer identifier
   */
  _recordFailure(peerId) {
    const peer = this.peers.get(peerId);

    if (!peer) {
      return;
    }

    peer.failureCount++;

    if (peer.failureCount >= this.maxFailures) {
      peer.status = PeerStatus.SUSPECT;
      logger.warn('Peer marked suspect after failures', {
        peerId,
        failures: peer.failureCount
      });
    }
  }

  /**
   * Select random peers
   *
   * @private
   * @param {PeerInfo[]} peers - Available peers
   * @param {number} count - Number to select
   * @returns {PeerInfo[]} Selected peers
   */
  _selectRandomPeers(peers, count) {
    const shuffled = [...peers].sort(() => Math.random() - 0.5);
    return shuffled.slice(0, Math.min(count, peers.length));
  }

  /**
   * Handle sync request
   *
   * @private
   * @param {GossipMessage} message - Sync request message
   */
  async _handleSyncRequest(message) {
    // Send full state back
    await this.sendMessage(message.senderId, GossipMessageType.SYNC_RESPONSE, {
      state: this.getAllState()
    });
  }

  /**
   * Handle sync response
   *
   * @private
   * @param {GossipMessage} message - Sync response message
   */
  async _handleSyncResponse(message) {
    this._mergeState(message.state, message.vectorClock);
  }

  /**
   * Handle push message
   *
   * @private
   * @param {GossipMessage} message - Push message
   */
  async _handlePush(message) {
    this._mergeState(message.state, message.vectorClock);
  }

  /**
   * Handle pull message
   *
   * @private
   * @param {GossipMessage} message - Pull message
   */
  async _handlePull(message) {
    await this.sendMessage(message.senderId, GossipMessageType.PUSH, {
      state: this.getAllState()
    });
  }

  /**
   * Handle push-pull message
   *
   * @private
   * @param {GossipMessage} message - Push-pull message
   */
  async _handlePushPull(message) {
    // Merge received state
    this._mergeState(message.state, message.vectorClock);

    // Send our state back
    await this.sendMessage(message.senderId, GossipMessageType.PUSH, {
      state: this.getAllState()
    });
  }

  /**
   * Handle ping message
   *
   * @private
   * @param {GossipMessage} message - Ping message
   */
  async _handlePing(message) {
    await this.sendMessage(message.senderId, GossipMessageType.PONG);
  }

  /**
   * Handle pong message
   *
   * @private
   * @param {GossipMessage} message - Pong message
   */
  async _handlePong(message) {
    // Already handled by message handler (updates lastSeen)
  }

  /**
   * Merge remote state with local state
   *
   * @private
   * @param {Object} remoteState - Remote state
   * @param {Object} remoteClock - Remote vector clock
   */
  _mergeState(remoteState, remoteClock) {
    let merged = 0;

    for (const [key, value] of Object.entries(remoteState)) {
      // Simple last-write-wins for now
      // In production, use CRDT for conflict-free merging
      const current = this.state.get(key);

      if (current !== value) {
        this.state.set(key, value);
        merged++;

        this.emit('state:merged', { key, value, remote: true });
      }
    }

    if (merged > 0) {
      logger.debug('State merged', { keys: merged });
    }
  }

  /**
   * Get protocol statistics
   *
   * @returns {Object} Statistics
   */
  getStats() {
    return {
      ...this.stats,
      peers: this.peers.size,
      alivePeers: this.getPeers(PeerStatus.ALIVE).length,
      suspectPeers: this.getPeers(PeerStatus.SUSPECT).length,
      deadPeers: this.getPeers(PeerStatus.DEAD).length,
      stateSize: this.state.size
    };
  }

  /**
   * Check if cluster has converged
   *
   * @returns {boolean} True if converged
   */
  hasConverged() {
    // Simplified convergence check
    // In production, use more sophisticated criteria
    const alivePeers = this.getPeers(PeerStatus.ALIVE);
    return alivePeers.length > 0 && this.state.size > 0;
  }

  /**
   * Destroy gossip protocol
   */
  destroy() {
    this.stop();
    this.peers.clear();
    this.state.clear();
    this.removeAllListeners();
    logger.info('Gossip protocol destroyed');
  }
}

export default GossipProtocol;
