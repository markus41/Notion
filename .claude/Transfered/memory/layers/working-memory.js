/**
 * Working Memory Layer
 *
 * Active context management based on cognitive psychology's working memory model.
 * Implements Miller's Law (7±2 items) with chunking support for complex items.
 *
 * Characteristics:
 * - Duration: 1 hour TTL
 * - Capacity: 7±2 items (configurable 5-9)
 * - Backend: Redis Cache with LRU eviction
 * - Purpose: Maintain active task context and ongoing cognitive processes
 *
 * @module memory/layers/working-memory
 */

import { createLogger } from '../../utils/logger.js';
import { EventEmitter } from 'events';

const logger = createLogger('WorkingMemory');

/**
 * Working memory item types
 * @enum {string}
 */
export const WorkingItemType = {
  TASK_CONTEXT: 'task_context',
  ACTIVE_GOAL: 'active_goal',
  RECENT_INTERACTION: 'recent_interaction',
  CACHED_RESULT: 'cached_result',
  ATTENTION_FOCUS: 'attention_focus',
  CHUNK: 'chunk'
};

/**
 * Item priority levels
 * @enum {number}
 */
export const Priority = {
  CRITICAL: 5,
  HIGH: 4,
  NORMAL: 3,
  LOW: 2,
  BACKGROUND: 1
};

/**
 * Working memory item structure
 * @typedef {Object} WorkingItem
 * @property {string} id - Unique identifier
 * @property {WorkingItemType} type - Type of working memory item
 * @property {*} data - Item data
 * @property {number} timestamp - Creation timestamp
 * @property {number} lastAccessed - Last access timestamp
 * @property {number} accessCount - Number of accesses
 * @property {Priority} priority - Item priority
 * @property {string[]} tags - Tags for categorization
 * @property {Object} metadata - Additional metadata
 * @property {string[]} chunkIds - Related chunk IDs if chunked
 * @property {number} rehearsalCount - Number of rehearsals (refreshes)
 */

/**
 * Chunk structure for complex items
 * @typedef {Object} Chunk
 * @property {string} id - Chunk identifier
 * @property {string} parentId - Parent item ID
 * @property {*} data - Chunk data
 * @property {number} index - Chunk index in sequence
 * @property {number} totalChunks - Total chunks in parent
 */

/**
 * Working Memory Manager
 *
 * Manages active context with capacity constraints based on cognitive psychology.
 * Implements rehearsal, chunking, and promotion to long-term memory.
 */
export class WorkingMemory extends EventEmitter {
  /**
   * @param {Object} config - Configuration object
   * @param {Object} config.redisClient - Redis client instance
   * @param {number} [config.ttl=3600000] - Time-to-live in milliseconds (1 hour)
   * @param {number} [config.capacity=7] - Maximum items (Miller's Law: 7±2)
   * @param {number} [config.chunkSize=3] - Max sub-items per chunk
   * @param {string} [config.namespace='working'] - Redis namespace
   * @param {number} [config.rehearsalInterval=300000] - Rehearsal interval (5 min)
   * @param {number} [config.promotionThreshold=5] - Access count for promotion
   */
  constructor(config) {
    super();

    this.redis = config.redisClient;
    this.ttl = config.ttl || 3600000; // 1 hour
    this.capacity = Math.max(5, Math.min(9, config.capacity || 7)); // Enforce 5-9 range
    this.chunkSize = config.chunkSize || 3;
    this.namespace = config.namespace || 'working';
    this.rehearsalInterval = config.rehearsalInterval || 300000; // 5 minutes
    this.promotionThreshold = config.promotionThreshold || 5;

    // Redis keys
    this.itemsKey = `${this.namespace}:items`;
    this.chunksKey = `${this.namespace}:chunks`;
    this.metaKey = `${this.namespace}:meta`;
    this.indexKey = `${this.namespace}:index`;

    // Start rehearsal timer
    this.rehearsalTimer = null;
    this.startRehearsal();

    logger.info('Working memory initialized', {
      capacity: this.capacity,
      ttl: this.ttl,
      namespace: this.namespace
    });
  }

  /**
   * Add item to working memory
   *
   * @param {WorkingItemType} type - Type of item
   * @param {*} data - Item data
   * @param {Object} [options={}] - Additional options
   * @param {Priority} [options.priority=Priority.NORMAL] - Item priority
   * @param {string[]} [options.tags=[]] - Tags for categorization
   * @param {Object} [options.metadata={}] - Additional metadata
   * @param {boolean} [options.autoChunk=true] - Auto-chunk large objects
   * @returns {Promise<WorkingItem>} Created working memory item
   */
  async add(type, data, options = {}) {
    try {
      const timestamp = Date.now();
      const id = `${this.namespace}:${timestamp}:${Math.random().toString(36).substr(2, 9)}`;

      // Check if data needs chunking
      const shouldChunk = options.autoChunk !== false && this._shouldChunk(data);
      let chunkIds = [];

      if (shouldChunk) {
        chunkIds = await this._createChunks(id, data);
      }

      const item = {
        id,
        type,
        data: shouldChunk ? null : data, // Don't store data if chunked
        timestamp,
        lastAccessed: timestamp,
        accessCount: 1,
        priority: options.priority || Priority.NORMAL,
        tags: options.tags || [],
        metadata: options.metadata || {},
        chunkIds,
        rehearsalCount: 0
      };

      // Store item
      await this.redis.hset(this.itemsKey, id, JSON.stringify(item));

      // Update index for quick retrieval
      await this._updateIndex(item);

      // Enforce capacity
      await this._enforceCapacity();

      logger.debug('Working memory item added', {
        id,
        type,
        chunked: shouldChunk,
        chunks: chunkIds.length
      });

      this.emit('item:added', item);

      return item;
    } catch (error) {
      logger.error('Failed to add working memory item', { error: error.message, type });
      throw new Error(`Working memory add failed: ${error.message}`);
    }
  }

  /**
   * Retrieve item from working memory
   *
   * @param {string} id - Item ID
   * @param {Object} [options={}] - Retrieval options
   * @param {boolean} [options.includeChunks=true] - Reconstruct chunked data
   * @param {boolean} [options.rehearse=true] - Mark as rehearsed (refresh TTL)
   * @returns {Promise<WorkingItem|null>} Working memory item or null
   */
  async get(id, options = {}) {
    try {
      const itemJson = await this.redis.hget(this.itemsKey, id);

      if (!itemJson) {
        return null;
      }

      const item = JSON.parse(itemJson);

      // Reconstruct chunked data
      if (options.includeChunks !== false && item.chunkIds.length > 0) {
        item.data = await this._reconstructFromChunks(item.chunkIds);
      }

      // Update access metrics
      item.lastAccessed = Date.now();
      item.accessCount++;

      if (options.rehearse !== false) {
        item.rehearsalCount++;
      }

      // Save updated metrics
      await this.redis.hset(this.itemsKey, id, JSON.stringify(item));

      // Check for promotion to episodic memory
      if (item.accessCount >= this.promotionThreshold) {
        this.emit('promote:episodic', item);
        logger.debug('Item promoted to episodic memory', { id, accessCount: item.accessCount });
      }

      logger.debug('Working memory item retrieved', { id, accessCount: item.accessCount });

      return item;
    } catch (error) {
      logger.error('Failed to retrieve working memory item', { error: error.message, id });
      throw new Error(`Working memory retrieval failed: ${error.message}`);
    }
  }

  /**
   * Query working memory items
   *
   * @param {Object} [query={}] - Query parameters
   * @param {WorkingItemType} [query.type] - Filter by type
   * @param {string[]} [query.tags] - Filter by tags (OR logic)
   * @param {Priority} [query.minPriority] - Minimum priority
   * @param {number} [query.limit=10] - Maximum results
   * @param {string} [query.sortBy='lastAccessed'] - Sort field
   * @returns {Promise<WorkingItem[]>} Array of matching items
   */
  async query(query = {}) {
    try {
      // Get all items
      const allItems = await this.redis.hgetall(this.itemsKey);

      if (!allItems || Object.keys(allItems).length === 0) {
        return [];
      }

      // Parse and filter items
      let items = Object.values(allItems).map(json => JSON.parse(json));

      // Apply filters
      if (query.type) {
        items = items.filter(item => item.type === query.type);
      }

      if (query.tags && query.tags.length > 0) {
        items = items.filter(item =>
          item.tags.some(tag => query.tags.includes(tag))
        );
      }

      if (query.minPriority !== undefined) {
        items = items.filter(item => item.priority >= query.minPriority);
      }

      // Sort
      const sortBy = query.sortBy || 'lastAccessed';
      items.sort((a, b) => {
        const aVal = a[sortBy] || 0;
        const bVal = b[sortBy] || 0;
        return bVal - aVal; // Descending
      });

      // Limit results
      const limit = query.limit || 10;
      return items.slice(0, limit);
    } catch (error) {
      logger.error('Failed to query working memory', { error: error.message });
      throw new Error(`Working memory query failed: ${error.message}`);
    }
  }

  /**
   * Update item in working memory
   *
   * @param {string} id - Item ID
   * @param {Object} updates - Fields to update
   * @returns {Promise<WorkingItem>} Updated item
   */
  async update(id, updates) {
    try {
      const item = await this.get(id, { rehearse: false });

      if (!item) {
        throw new Error(`Item not found: ${id}`);
      }

      // Apply updates
      const updated = { ...item, ...updates };
      updated.lastAccessed = Date.now();

      // Store updated item
      await this.redis.hset(this.itemsKey, id, JSON.stringify(updated));

      logger.debug('Working memory item updated', { id });
      this.emit('item:updated', updated);

      return updated;
    } catch (error) {
      logger.error('Failed to update working memory item', { error: error.message, id });
      throw new Error(`Working memory update failed: ${error.message}`);
    }
  }

  /**
   * Remove item from working memory
   *
   * @param {string} id - Item ID
   * @returns {Promise<boolean>} True if removed
   */
  async remove(id) {
    try {
      const item = await this.get(id, { rehearse: false });

      if (!item) {
        return false;
      }

      // Remove chunks if exists
      if (item.chunkIds.length > 0) {
        await Promise.all(
          item.chunkIds.map(chunkId => this.redis.hdel(this.chunksKey, chunkId))
        );
      }

      // Remove item
      await this.redis.hdel(this.itemsKey, id);

      // Update index
      await this._removeFromIndex(item);

      logger.debug('Working memory item removed', { id });
      this.emit('item:removed', item);

      return true;
    } catch (error) {
      logger.error('Failed to remove working memory item', { error: error.message, id });
      throw new Error(`Working memory removal failed: ${error.message}`);
    }
  }

  /**
   * Get current working memory size
   *
   * @returns {Promise<number>} Number of items
   */
  async size() {
    try {
      const count = await this.redis.hlen(this.itemsKey);
      return count || 0;
    } catch (error) {
      logger.error('Failed to get working memory size', { error: error.message });
      return 0;
    }
  }

  /**
   * Clear all working memory
   *
   * @returns {Promise<void>}
   */
  async clear() {
    try {
      await this.redis.del(this.itemsKey);
      await this.redis.del(this.chunksKey);
      await this.redis.del(this.metaKey);
      await this.redis.del(this.indexKey);

      logger.info('Working memory cleared');
      this.emit('memory:cleared');
    } catch (error) {
      logger.error('Failed to clear working memory', { error: error.message });
      throw new Error(`Working memory clear failed: ${error.message}`);
    }
  }

  /**
   * Determine if data should be chunked
   *
   * @private
   * @param {*} data - Data to check
   * @returns {boolean} True if should chunk
   */
  _shouldChunk(data) {
    if (!data || typeof data !== 'object') {
      return false;
    }

    // Check if array with many items
    if (Array.isArray(data) && data.length > this.chunkSize) {
      return true;
    }

    // Check if object with many keys
    if (Object.keys(data).length > this.chunkSize * 2) {
      return true;
    }

    // Check size in bytes (rough estimate)
    const sizeEstimate = JSON.stringify(data).length;
    return sizeEstimate > 10000; // 10KB threshold
  }

  /**
   * Create chunks from large data
   *
   * @private
   * @param {string} parentId - Parent item ID
   * @param {*} data - Data to chunk
   * @returns {Promise<string[]>} Array of chunk IDs
   */
  async _createChunks(parentId, data) {
    try {
      const chunks = [];

      if (Array.isArray(data)) {
        // Chunk array
        for (let i = 0; i < data.length; i += this.chunkSize) {
          chunks.push(data.slice(i, i + this.chunkSize));
        }
      } else if (typeof data === 'object') {
        // Chunk object
        const entries = Object.entries(data);
        for (let i = 0; i < entries.length; i += this.chunkSize) {
          const chunkEntries = entries.slice(i, i + this.chunkSize);
          chunks.push(Object.fromEntries(chunkEntries));
        }
      }

      // Store chunks
      const chunkIds = await Promise.all(
        chunks.map(async (chunkData, index) => {
          const chunkId = `${parentId}:chunk:${index}`;
          const chunk = {
            id: chunkId,
            parentId,
            data: chunkData,
            index,
            totalChunks: chunks.length
          };

          await this.redis.hset(this.chunksKey, chunkId, JSON.stringify(chunk));
          return chunkId;
        })
      );

      logger.debug('Created chunks', { parentId, chunks: chunkIds.length });
      return chunkIds;
    } catch (error) {
      logger.error('Failed to create chunks', { error: error.message, parentId });
      return [];
    }
  }

  /**
   * Reconstruct data from chunks
   *
   * @private
   * @param {string[]} chunkIds - Array of chunk IDs
   * @returns {Promise<*>} Reconstructed data
   */
  async _reconstructFromChunks(chunkIds) {
    try {
      if (chunkIds.length === 0) {
        return null;
      }

      // Fetch all chunks
      const chunkJsons = await Promise.all(
        chunkIds.map(id => this.redis.hget(this.chunksKey, id))
      );

      const chunks = chunkJsons
        .filter(json => json !== null)
        .map(json => JSON.parse(json))
        .sort((a, b) => a.index - b.index);

      if (chunks.length === 0) {
        return null;
      }

      // Reconstruct based on type
      const firstChunk = chunks[0].data;

      if (Array.isArray(firstChunk)) {
        return chunks.flatMap(chunk => chunk.data);
      } else if (typeof firstChunk === 'object') {
        return chunks.reduce((acc, chunk) => ({ ...acc, ...chunk.data }), {});
      }

      return null;
    } catch (error) {
      logger.error('Failed to reconstruct from chunks', { error: error.message });
      return null;
    }
  }

  /**
   * Enforce capacity limit using priority-based eviction
   *
   * @private
   * @returns {Promise<void>}
   */
  async _enforceCapacity() {
    try {
      const currentSize = await this.size();

      if (currentSize > this.capacity) {
        const items = await this.query({ limit: 100 });

        // Sort by priority (ascending) and last accessed (ascending)
        items.sort((a, b) => {
          if (a.priority !== b.priority) {
            return a.priority - b.priority; // Lower priority first
          }
          return a.lastAccessed - b.lastAccessed; // Older first
        });

        // Remove lowest priority, oldest items
        const toRemove = currentSize - this.capacity;
        const itemsToRemove = items.slice(0, toRemove);

        for (const item of itemsToRemove) {
          await this.remove(item.id);
        }

        logger.debug('Enforced working memory capacity', { removed: toRemove });
        this.emit('capacity:enforced', { removed: toRemove });
      }
    } catch (error) {
      logger.error('Failed to enforce capacity', { error: error.message });
    }
  }

  /**
   * Update search index
   *
   * @private
   * @param {WorkingItem} item - Item to index
   * @returns {Promise<void>}
   */
  async _updateIndex(item) {
    // Index by type
    await this.redis.sadd(`${this.indexKey}:type:${item.type}`, item.id);

    // Index by tags
    for (const tag of item.tags) {
      await this.redis.sadd(`${this.indexKey}:tag:${tag}`, item.id);
    }
  }

  /**
   * Remove item from index
   *
   * @private
   * @param {WorkingItem} item - Item to remove from index
   * @returns {Promise<void>}
   */
  async _removeFromIndex(item) {
    await this.redis.srem(`${this.indexKey}:type:${item.type}`, item.id);

    for (const tag of item.tags) {
      await this.redis.srem(`${this.indexKey}:tag:${tag}`, item.id);
    }
  }

  /**
   * Rehearsal process to maintain active items
   *
   * @private
   * @returns {Promise<void>}
   */
  async _rehearse() {
    try {
      const items = await this.query({ limit: 100 });

      for (const item of items) {
        // Refresh TTL for active items
        const age = Date.now() - item.lastAccessed;

        if (age < this.rehearsalInterval * 2) {
          await this.redis.hset(this.itemsKey, item.id, JSON.stringify(item));
        }
      }

      logger.debug('Rehearsal completed', { items: items.length });
    } catch (error) {
      logger.error('Rehearsal failed', { error: error.message });
    }
  }

  /**
   * Start automatic rehearsal timer
   *
   * @private
   */
  startRehearsal() {
    if (this.rehearsalTimer) {
      clearInterval(this.rehearsalTimer);
    }

    this.rehearsalTimer = setInterval(() => {
      this._rehearse();
    }, this.rehearsalInterval);

    logger.debug('Rehearsal timer started', { interval: this.rehearsalInterval });
  }

  /**
   * Stop automatic rehearsal timer
   */
  stopRehearsal() {
    if (this.rehearsalTimer) {
      clearInterval(this.rehearsalTimer);
      this.rehearsalTimer = null;
      logger.debug('Rehearsal timer stopped');
    }
  }

  /**
   * Destroy working memory instance
   */
  async destroy() {
    this.stopRehearsal();
    await this.clear();
    this.removeAllListeners();
    logger.info('Working memory destroyed');
  }
}

export default WorkingMemory;
