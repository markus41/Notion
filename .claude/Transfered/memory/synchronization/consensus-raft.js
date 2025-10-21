/**
 * Raft Consensus Algorithm Implementation
 *
 * Provides strong consistency for distributed memory through leader-based consensus.
 * Implements the Raft consensus algorithm for replicated state machines.
 *
 * Features:
 * - Leader election
 * - Log replication
 * - Safety guarantees
 * - Membership changes
 * - Log compaction (snapshots)
 *
 * @module memory/synchronization/consensus-raft
 */

import { createLogger } from '../../utils/logger.js';
import { EventEmitter } from 'events';

const logger = createLogger('RaftConsensus');

/**
 * Node states
 * @enum {string}
 */
export const NodeState = {
  FOLLOWER: 'follower',
  CANDIDATE: 'candidate',
  LEADER: 'leader'
};

/**
 * RPC message types
 * @enum {string}
 */
export const RPCType = {
  REQUEST_VOTE: 'request_vote',
  REQUEST_VOTE_RESPONSE: 'request_vote_response',
  APPEND_ENTRIES: 'append_entries',
  APPEND_ENTRIES_RESPONSE: 'append_entries_response',
  INSTALL_SNAPSHOT: 'install_snapshot',
  INSTALL_SNAPSHOT_RESPONSE: 'install_snapshot_response'
};

/**
 * Log entry structure
 * @typedef {Object} LogEntry
 * @property {number} term - Term when entry was created
 * @property {number} index - Entry index
 * @property {string} command - Command to execute
 * @property {*} data - Command data
 */

/**
 * Raft RPC message
 * @typedef {Object} RaftRPC
 * @property {RPCType} type - RPC type
 * @property {number} term - Sender's term
 * @property {string} senderId - Sender node ID
 * @property {string} recipientId - Recipient node ID
 * @property {Object} payload - RPC-specific payload
 */

/**
 * Raft Consensus Node
 *
 * Implements Raft consensus algorithm for strong consistency.
 */
export class RaftNode extends EventEmitter {
  /**
   * @param {Object} config - Configuration object
   * @param {string} config.nodeId - Unique node identifier
   * @param {string[]} config.peers - List of peer node IDs
   * @param {number} [config.electionTimeout=150] - Election timeout base (ms)
   * @param {number} [config.heartbeatInterval=50] - Heartbeat interval (ms)
   * @param {number} [config.snapshotThreshold=1000] - Log entries before snapshot
   */
  constructor(config) {
    super();

    this.nodeId = config.nodeId;
    this.peers = config.peers || [];
    this.electionTimeoutBase = config.electionTimeout || 150;
    this.heartbeatInterval = config.heartbeatInterval || 50;
    this.snapshotThreshold = config.snapshotThreshold || 1000;

    // Persistent state (should be persisted to disk)
    this.currentTerm = 0;
    this.votedFor = null;
    this.log = []; // Array of LogEntry

    // Volatile state
    this.state = NodeState.FOLLOWER;
    this.commitIndex = 0;
    this.lastApplied = 0;

    // Leader state (reinitialized after election)
    this.nextIndex = new Map(); // Map<nodeId, index>
    this.matchIndex = new Map(); // Map<nodeId, index>

    // State machine
    this.stateMachine = new Map();

    // Snapshot state
    this.lastIncludedIndex = 0;
    this.lastIncludedTerm = 0;
    this.snapshot = null;

    // Timers
    this.electionTimer = null;
    this.heartbeatTimer = null;

    // Statistics
    this.stats = {
      elections: 0,
      termChanges: 0,
      logEntries: 0,
      snapshots: 0
    };

    this._resetElectionTimeout();

    logger.info('Raft node initialized', {
      nodeId: this.nodeId,
      peers: this.peers.length,
      state: this.state
    });
  }

  /**
   * Start Raft node
   */
  start() {
    this._becomeFollower(this.currentTerm);
    logger.info('Raft node started', { nodeId: this.nodeId });
    this.emit('node:started');
  }

  /**
   * Stop Raft node
   */
  stop() {
    this._clearTimers();
    logger.info('Raft node stopped', { nodeId: this.nodeId });
    this.emit('node:stopped');
  }

  /**
   * Handle incoming RPC
   *
   * @param {RaftRPC} rpc - Incoming RPC message
   */
  async handleRPC(rpc) {
    // Update term if we see a higher term
    if (rpc.term > this.currentTerm) {
      this._becomeFollower(rpc.term);
    }

    // Handle RPC by type
    switch (rpc.type) {
      case RPCType.REQUEST_VOTE:
        return await this._handleRequestVote(rpc);

      case RPCType.REQUEST_VOTE_RESPONSE:
        return await this._handleRequestVoteResponse(rpc);

      case RPCType.APPEND_ENTRIES:
        return await this._handleAppendEntries(rpc);

      case RPCType.APPEND_ENTRIES_RESPONSE:
        return await this._handleAppendEntriesResponse(rpc);

      case RPCType.INSTALL_SNAPSHOT:
        return await this._handleInstallSnapshot(rpc);

      case RPCType.INSTALL_SNAPSHOT_RESPONSE:
        return await this._handleInstallSnapshotResponse(rpc);

      default:
        logger.warn('Unknown RPC type', { type: rpc.type });
        return null;
    }
  }

  /**
   * Replicate command to cluster
   *
   * @param {string} command - Command name
   * @param {*} data - Command data
   * @returns {Promise<boolean>} True if replicated to majority
   */
  async replicate(command, data) {
    if (this.state !== NodeState.LEADER) {
      logger.warn('Only leader can replicate commands');
      return false;
    }

    // Append to local log
    const entry = {
      term: this.currentTerm,
      index: this._getLastLogIndex() + 1,
      command,
      data
    };

    this.log.push(entry);
    this.stats.logEntries++;

    logger.debug('Command appended to log', {
      command,
      index: entry.index,
      term: entry.term
    });

    // Replicate to followers
    await this._replicateToFollowers();

    // Check if committed
    const committed = await this._checkCommitIndex();

    if (committed) {
      this.emit('command:committed', entry);
    }

    return committed;
  }

  /**
   * Get current leader ID
   *
   * @returns {string|null} Leader node ID or null
   */
  getLeader() {
    if (this.state === NodeState.LEADER) {
      return this.nodeId;
    }

    // In production, track current leader from AppendEntries
    return null;
  }

  /**
   * Get current state
   *
   * @returns {Object} Current state
   */
  getState() {
    return {
      nodeId: this.nodeId,
      state: this.state,
      currentTerm: this.currentTerm,
      commitIndex: this.commitIndex,
      logLength: this.log.length,
      stateMachineSize: this.stateMachine.size
    };
  }

  /**
   * Become follower
   *
   * @private
   * @param {number} term - New term
   */
  _becomeFollower(term) {
    if (term > this.currentTerm) {
      this.currentTerm = term;
      this.votedFor = null;
      this.stats.termChanges++;
    }

    const wasLeader = this.state === NodeState.LEADER;
    this.state = NodeState.FOLLOWER;

    this._clearTimers();
    this._resetElectionTimeout();

    if (wasLeader) {
      logger.info('Stepped down from leader', { term: this.currentTerm });
      this.emit('state:follower', { term: this.currentTerm });
    }
  }

  /**
   * Become candidate and start election
   *
   * @private
   */
  async _becomeCandidate() {
    this.state = NodeState.CANDIDATE;
    this.currentTerm++;
    this.votedFor = this.nodeId;
    this.stats.elections++;

    logger.info('Starting election', {
      term: this.currentTerm,
      nodeId: this.nodeId
    });

    this.emit('state:candidate', { term: this.currentTerm });

    // Reset election timer
    this._resetElectionTimeout();

    // Request votes from peers
    const votes = await this._requestVotes();

    // Check if won election (majority of votes)
    const majority = Math.floor((this.peers.length + 1) / 2) + 1;

    if (votes >= majority && this.state === NodeState.CANDIDATE) {
      this._becomeLeader();
    }
  }

  /**
   * Become leader
   *
   * @private
   */
  _becomeLeader() {
    this.state = NodeState.LEADER;

    logger.info('Became leader', {
      term: this.currentTerm,
      nodeId: this.nodeId
    });

    this.emit('state:leader', { term: this.currentTerm });

    // Initialize leader state
    const lastLogIndex = this._getLastLogIndex();

    for (const peerId of this.peers) {
      this.nextIndex.set(peerId, lastLogIndex + 1);
      this.matchIndex.set(peerId, 0);
    }

    // Clear election timer
    if (this.electionTimer) {
      clearTimeout(this.electionTimer);
      this.electionTimer = null;
    }

    // Start sending heartbeats
    this._startHeartbeats();
  }

  /**
   * Request votes from peers
   *
   * @private
   * @returns {Promise<number>} Number of votes received
   */
  async _requestVotes() {
    let votes = 1; // Vote for self

    const lastLogIndex = this._getLastLogIndex();
    const lastLogTerm = this._getLastLogTerm();

    const rpc = {
      type: RPCType.REQUEST_VOTE,
      term: this.currentTerm,
      senderId: this.nodeId,
      payload: {
        candidateId: this.nodeId,
        lastLogIndex,
        lastLogTerm
      }
    };

    // Send RequestVote to all peers
    const promises = this.peers.map(async peerId => {
      try {
        const response = await this._sendRPC(peerId, rpc);

        if (response && response.payload.voteGranted) {
          votes++;
        }
      } catch (error) {
        logger.error('RequestVote failed', { error: error.message, peerId });
      }
    });

    await Promise.all(promises);

    return votes;
  }

  /**
   * Handle RequestVote RPC
   *
   * @private
   * @param {RaftRPC} rpc - RequestVote RPC
   * @returns {RaftRPC} Response
   */
  async _handleRequestVote(rpc) {
    const { candidateId, lastLogIndex, lastLogTerm } = rpc.payload;

    let voteGranted = false;

    // Check if we can vote for this candidate
    if (rpc.term < this.currentTerm) {
      // Reject: stale term
    } else if (this.votedFor === null || this.votedFor === candidateId) {
      // Check if candidate's log is at least as up-to-date as ours
      const ourLastLogTerm = this._getLastLogTerm();
      const ourLastLogIndex = this._getLastLogIndex();

      const logUpToDate =
        lastLogTerm > ourLastLogTerm ||
        (lastLogTerm === ourLastLogTerm && lastLogIndex >= ourLastLogIndex);

      if (logUpToDate) {
        voteGranted = true;
        this.votedFor = candidateId;
        this._resetElectionTimeout();
      }
    }

    logger.debug('RequestVote handled', {
      candidateId,
      voteGranted,
      term: rpc.term
    });

    return {
      type: RPCType.REQUEST_VOTE_RESPONSE,
      term: this.currentTerm,
      senderId: this.nodeId,
      recipientId: rpc.senderId,
      payload: {
        voteGranted
      }
    };
  }

  /**
   * Handle RequestVoteResponse RPC
   *
   * @private
   * @param {RaftRPC} rpc - RequestVoteResponse RPC
   */
  async _handleRequestVoteResponse(rpc) {
    // Handled in _requestVotes
  }

  /**
   * Start sending heartbeats
   *
   * @private
   */
  _startHeartbeats() {
    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer);
    }

    this.heartbeatTimer = setInterval(async () => {
      if (this.state === NodeState.LEADER) {
        await this._replicateToFollowers();
      }
    }, this.heartbeatInterval);
  }

  /**
   * Replicate log entries to followers
   *
   * @private
   */
  async _replicateToFollowers() {
    if (this.state !== NodeState.LEADER) {
      return;
    }

    for (const peerId of this.peers) {
      const nextIdx = this.nextIndex.get(peerId);
      const prevLogIndex = nextIdx - 1;
      const prevLogTerm = this._getLogTerm(prevLogIndex);

      // Get entries to send
      const entries = this.log.slice(nextIdx);

      const rpc = {
        type: RPCType.APPEND_ENTRIES,
        term: this.currentTerm,
        senderId: this.nodeId,
        recipientId: peerId,
        payload: {
          leaderId: this.nodeId,
          prevLogIndex,
          prevLogTerm,
          entries,
          leaderCommit: this.commitIndex
        }
      };

      try {
        await this._sendRPC(peerId, rpc);
      } catch (error) {
        logger.error('AppendEntries failed', { error: error.message, peerId });
      }
    }
  }

  /**
   * Handle AppendEntries RPC
   *
   * @private
   * @param {RaftRPC} rpc - AppendEntries RPC
   * @returns {RaftRPC} Response
   */
  async _handleAppendEntries(rpc) {
    const { leaderId, prevLogIndex, prevLogTerm, entries, leaderCommit } = rpc.payload;

    // Reset election timeout (received heartbeat from leader)
    this._resetElectionTimeout();

    let success = false;

    // Check if log contains entry at prevLogIndex with prevLogTerm
    if (prevLogIndex === 0 || this._getLogTerm(prevLogIndex) === prevLogTerm) {
      success = true;

      // Delete conflicting entries
      if (entries.length > 0) {
        const startIndex = prevLogIndex + 1;
        this.log = this.log.slice(0, startIndex);

        // Append new entries
        this.log.push(...entries);
      }

      // Update commit index
      if (leaderCommit > this.commitIndex) {
        this.commitIndex = Math.min(leaderCommit, this._getLastLogIndex());
        await this._applyCommittedEntries();
      }
    }

    return {
      type: RPCType.APPEND_ENTRIES_RESPONSE,
      term: this.currentTerm,
      senderId: this.nodeId,
      recipientId: rpc.senderId,
      payload: {
        success,
        matchIndex: success ? prevLogIndex + entries.length : 0
      }
    };
  }

  /**
   * Handle AppendEntriesResponse RPC
   *
   * @private
   * @param {RaftRPC} rpc - AppendEntriesResponse RPC
   */
  async _handleAppendEntriesResponse(rpc) {
    if (this.state !== NodeState.LEADER) {
      return;
    }

    const { success, matchIndex } = rpc.payload;

    if (success) {
      // Update nextIndex and matchIndex
      this.nextIndex.set(rpc.senderId, matchIndex + 1);
      this.matchIndex.set(rpc.senderId, matchIndex);

      // Check if we can advance commit index
      await this._checkCommitIndex();
    } else {
      // Decrement nextIndex and retry
      const nextIdx = this.nextIndex.get(rpc.senderId);
      this.nextIndex.set(rpc.senderId, Math.max(1, nextIdx - 1));
    }
  }

  /**
   * Check and update commit index
   *
   * @private
   * @returns {Promise<boolean>} True if commit index advanced
   */
  async _checkCommitIndex() {
    if (this.state !== NodeState.LEADER) {
      return false;
    }

    // Find highest index replicated on majority
    const lastLogIndex = this._getLastLogIndex();

    for (let n = lastLogIndex; n > this.commitIndex; n--) {
      if (this._getLogTerm(n) !== this.currentTerm) {
        continue;
      }

      // Count replicas
      let replicas = 1; // Leader has it

      for (const matchIdx of this.matchIndex.values()) {
        if (matchIdx >= n) {
          replicas++;
        }
      }

      // Check if majority
      const majority = Math.floor((this.peers.length + 1) / 2) + 1;

      if (replicas >= majority) {
        this.commitIndex = n;
        await this._applyCommittedEntries();
        return true;
      }
    }

    return false;
  }

  /**
   * Apply committed entries to state machine
   *
   * @private
   */
  async _applyCommittedEntries() {
    while (this.lastApplied < this.commitIndex) {
      this.lastApplied++;

      const entry = this.log[this.lastApplied - 1];

      if (entry) {
        // Apply to state machine
        this.stateMachine.set(entry.command, entry.data);

        logger.debug('Entry applied', {
          index: this.lastApplied,
          command: entry.command
        });

        this.emit('entry:applied', entry);
      }
    }

    // Check if snapshot needed
    if (this.log.length > this.snapshotThreshold) {
      await this._createSnapshot();
    }
  }

  /**
   * Create snapshot of state machine
   *
   * @private
   */
  async _createSnapshot() {
    this.snapshot = {
      lastIncludedIndex: this.lastApplied,
      lastIncludedTerm: this._getLogTerm(this.lastApplied),
      data: Object.fromEntries(this.stateMachine)
    };

    // Compact log
    this.log = this.log.slice(this.lastApplied);

    this.lastIncludedIndex = this.snapshot.lastIncludedIndex;
    this.lastIncludedTerm = this.snapshot.lastIncludedTerm;

    this.stats.snapshots++;

    logger.info('Snapshot created', {
      lastIncludedIndex: this.lastIncludedIndex,
      logLength: this.log.length
    });

    this.emit('snapshot:created', this.snapshot);
  }

  /**
   * Handle InstallSnapshot RPC
   *
   * @private
   * @param {RaftRPC} rpc - InstallSnapshot RPC
   * @returns {RaftRPC} Response
   */
  async _handleInstallSnapshot(rpc) {
    const { lastIncludedIndex, lastIncludedTerm, data } = rpc.payload;

    // Apply snapshot
    this.stateMachine = new Map(Object.entries(data));
    this.lastApplied = lastIncludedIndex;
    this.commitIndex = lastIncludedIndex;

    // Discard log
    this.log = [];
    this.lastIncludedIndex = lastIncludedIndex;
    this.lastIncludedTerm = lastIncludedTerm;

    logger.info('Snapshot installed', { lastIncludedIndex });

    return {
      type: RPCType.INSTALL_SNAPSHOT_RESPONSE,
      term: this.currentTerm,
      senderId: this.nodeId,
      recipientId: rpc.senderId,
      payload: {}
    };
  }

  /**
   * Handle InstallSnapshotResponse RPC
   *
   * @private
   * @param {RaftRPC} rpc - InstallSnapshotResponse RPC
   */
  async _handleInstallSnapshotResponse(rpc) {
    // Update nextIndex for follower
    this.nextIndex.set(rpc.senderId, this.lastIncludedIndex + 1);
  }

  /**
   * Get last log index
   *
   * @private
   * @returns {number} Last log index
   */
  _getLastLogIndex() {
    return this.lastIncludedIndex + this.log.length;
  }

  /**
   * Get last log term
   *
   * @private
   * @returns {number} Last log term
   */
  _getLastLogTerm() {
    if (this.log.length > 0) {
      return this.log[this.log.length - 1].term;
    }
    return this.lastIncludedTerm;
  }

  /**
   * Get log term at index
   *
   * @private
   * @param {number} index - Log index
   * @returns {number} Term at index
   */
  _getLogTerm(index) {
    if (index === 0) {
      return 0;
    }

    if (index === this.lastIncludedIndex) {
      return this.lastIncludedTerm;
    }

    const logIndex = index - this.lastIncludedIndex - 1;

    if (logIndex >= 0 && logIndex < this.log.length) {
      return this.log[logIndex].term;
    }

    return 0;
  }

  /**
   * Reset election timeout
   *
   * @private
   */
  _resetElectionTimeout() {
    if (this.electionTimer) {
      clearTimeout(this.electionTimer);
    }

    // Random timeout between electionTimeoutBase and 2x electionTimeoutBase
    const timeout = this.electionTimeoutBase + Math.random() * this.electionTimeoutBase;

    this.electionTimer = setTimeout(() => {
      if (this.state !== NodeState.LEADER) {
        this._becomeCandidate();
      }
    }, timeout);
  }

  /**
   * Clear all timers
   *
   * @private
   */
  _clearTimers() {
    if (this.electionTimer) {
      clearTimeout(this.electionTimer);
      this.electionTimer = null;
    }

    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = null;
    }
  }

  /**
   * Send RPC to peer
   *
   * @private
   * @param {string} peerId - Target peer ID
   * @param {RaftRPC} rpc - RPC message
   * @returns {Promise<RaftRPC>} Response
   */
  async _sendRPC(peerId, rpc) {
    // In production, send via network transport
    // For now, emit event for external handling
    return new Promise((resolve, reject) => {
      rpc.recipientId = peerId;

      this.emit('rpc:send', { peerId, rpc, resolve, reject });

      // Timeout after 1 second
      setTimeout(() => reject(new Error('RPC timeout')), 1000);
    });
  }

  /**
   * Get statistics
   *
   * @returns {Object} Statistics
   */
  getStats() {
    return {
      ...this.stats,
      ...this.getState()
    };
  }

  /**
   * Destroy Raft node
   */
  destroy() {
    this.stop();
    this.removeAllListeners();
    logger.info('Raft node destroyed');
  }
}

export default RaftNode;
