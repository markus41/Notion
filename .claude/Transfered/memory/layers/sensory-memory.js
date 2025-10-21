/**
 * Sensory Memory Layer
 *
 * Ultra-short term memory inspired by human sensory buffer (iconic/echoic memory).
 * Stores high-frequency sensory input with rapid decay and automatic cleanup.
 *
 * Characteristics:
 * - Duration: 5 seconds TTL (automatic decay)
 * - Capacity: 100 items (FIFO eviction)
 * - Backend: Redis Streams for temporal ordering
 * - Purpose: Buffer raw sensory input before attention filtering
 *
 * @module memory/layers/sensory-memory
 */

import { createLogger } from '../../utils/logger.js';
import { EventEmitter } from 'events';

const logger = createLogger('SensoryMemory');

/**
 * Sensory input types
 * @enum {string}
 */
export const SensoryType = {
  VISUAL: 'visual',
  AUDITORY: 'auditory',
  TEXTUAL: 'textual',
  SYSTEM: 'system',
  USER_INPUT: 'user_input',
  API_RESPONSE: 'api_response'
};

/**
 * Attention trigger thresholds for promotion to working memory
 * @typedef {Object} AttentionTrigger
 * @property {number} novelty - Novelty score (0-1)
 * @property {number} importance - Importance score (0-1)
 * @property {number} relevance - Relevance to current context (0-1)
 * @property {string[]} keywords - Keywords that trigger attention
 */

/**
 * Sensory memory item structure
 * @typedef {Object} SensoryItem
 * @property {string} id - Unique identifier
 * @property {SensoryType} type - Type of sensory input
 * @property {*} data - Raw sensory data
 * @property {number} timestamp - Creation timestamp (ms)
 * @property {number} intensity - Signal strength (0-1)
 * @property {Object} metadata - Additional metadata
 * @property {number} attentionScore - Computed attention score
 */

/**
 * Sensory Memory Manager
 *
 * Manages ultra-short term sensory buffer with automatic decay,
 * FIFO eviction, and attention-based promotion to working memory.
 */
export class SensoryMemory extends EventEmitter {
  /**
   * @param {Object} config - Configuration object
   * @param {Object} config.redisClient - Redis client instance
   * @param {number} [config.ttl=5000] - Time-to-live in milliseconds
   * @param {number} [config.capacity=100] - Maximum items in buffer
   * @param {string} [config.streamKey='sensory:stream'] - Redis stream key
   * @param {number} [config.cleanupInterval=1000] - Cleanup interval in ms
   * @param {AttentionTrigger} [config.attentionThreshold] - Attention trigger config
   */
  constructor(config) {
    super();

    this.redis = config.redisClient;
    this.ttl = config.ttl || 5000; // 5 seconds default
    this.capacity = config.capacity || 100;
    this.streamKey = config.streamKey || 'sensory:stream';
    this.cleanupInterval = config.cleanupInterval || 1000;
    this.metadataKey = `${this.streamKey}:metadata`;

    // Attention threshold for promotion to working memory
    this.attentionThreshold = config.attentionThreshold || {
      novelty: 0.7,
      importance: 0.6,
      relevance: 0.5,
      keywords: ['error', 'critical', 'urgent', 'user', 'security']
    };

    // Start automatic cleanup
    this.cleanupTimer = null;
    this.startCleanup();

    logger.info('Sensory memory initialized', {
      ttl: this.ttl,
      capacity: this.capacity,
      streamKey: this.streamKey
    });
  }

  /**
   * Add sensory input to the buffer
   *
   * @param {SensoryType} type - Type of sensory input
   * @param {*} data - Raw sensory data
   * @param {Object} [options={}] - Additional options
   * @param {number} [options.intensity=0.5] - Signal intensity (0-1)
   * @param {Object} [options.metadata={}] - Additional metadata
   * @returns {Promise<SensoryItem>} Created sensory item
   */
  async add(type, data, options = {}) {
    try {
      const timestamp = Date.now();
      const id = `sensory:${timestamp}:${Math.random().toString(36).substr(2, 9)}`;

      const item = {
        id,
        type,
        data,
        timestamp,
        intensity: options.intensity || 0.5,
        metadata: options.metadata || {},
        attentionScore: 0
      };

      // Compute attention score
      item.attentionScore = this._computeAttentionScore(item);

      // Add to Redis Stream
      await this.redis.xadd(
        this.streamKey,
        '*',
        'id', id,
        'type', type,
        'data', JSON.stringify(data),
        'timestamp', timestamp.toString(),
        'intensity', item.intensity.toString(),
        'metadata', JSON.stringify(item.metadata),
        'attentionScore', item.attentionScore.toString()
      );

      // Store metadata for efficient retrieval
      await this.redis.hset(this.metadataKey, id, JSON.stringify(item));
      await this.redis.expire(this.metadataKey, Math.ceil(this.ttl / 1000) + 1);

      // Enforce capacity limit (FIFO eviction)
      await this._enforceCapacity();

      logger.debug('Sensory input added', { id, type, attentionScore: item.attentionScore });

      // Emit event for attention-based processing
      this.emit('sensory:input', item);

      // Check for promotion to working memory
      if (this._shouldPromote(item)) {
        this.emit('promote:working', item);
        logger.debug('Sensory item promoted to working memory', { id });
      }

      return item;
    } catch (error) {
      logger.error('Failed to add sensory input', { error: error.message, type });
      throw new Error(`Sensory memory add failed: ${error.message}`);
    }
  }

  /**
   * Retrieve items from sensory buffer
   *
   * @param {Object} [options={}] - Query options
   * @param {number} [options.count=10] - Number of items to retrieve
   * @param {SensoryType} [options.type] - Filter by type
   * @param {number} [options.minIntensity] - Minimum intensity threshold
   * @param {number} [options.minAttentionScore] - Minimum attention score
   * @returns {Promise<SensoryItem[]>} Array of sensory items
   */
  async retrieve(options = {}) {
    try {
      const count = options.count || 10;

      // Read from stream (most recent items)
      const entries = await this.redis.xrevrange(
        this.streamKey,
        '+',
        '-',
        'COUNT',
        count * 2 // Fetch extra for filtering
      );

      if (!entries || entries.length === 0) {
        return [];
      }

      // Parse entries
      const items = await Promise.all(
        entries.map(async ([streamId, fields]) => {
          const fieldMap = {};
          for (let i = 0; i < fields.length; i += 2) {
            fieldMap[fields[i]] = fields[i + 1];
          }

          return {
            id: fieldMap.id,
            type: fieldMap.type,
            data: JSON.parse(fieldMap.data),
            timestamp: parseInt(fieldMap.timestamp),
            intensity: parseFloat(fieldMap.intensity),
            metadata: JSON.parse(fieldMap.metadata),
            attentionScore: parseFloat(fieldMap.attentionScore),
            streamId
          };
        })
      );

      // Apply filters
      let filtered = items;

      if (options.type) {
        filtered = filtered.filter(item => item.type === options.type);
      }

      if (options.minIntensity !== undefined) {
        filtered = filtered.filter(item => item.intensity >= options.minIntensity);
      }

      if (options.minAttentionScore !== undefined) {
        filtered = filtered.filter(item => item.attentionScore >= options.minAttentionScore);
      }

      // Return only requested count
      return filtered.slice(0, count);
    } catch (error) {
      logger.error('Failed to retrieve sensory items', { error: error.message });
      throw new Error(`Sensory memory retrieval failed: ${error.message}`);
    }
  }

  /**
   * Get current buffer size
   *
   * @returns {Promise<number>} Number of items in buffer
   */
  async size() {
    try {
      const length = await this.redis.xlen(this.streamKey);
      return length || 0;
    } catch (error) {
      logger.error('Failed to get sensory buffer size', { error: error.message });
      return 0;
    }
  }

  /**
   * Clear sensory buffer
   *
   * @returns {Promise<void>}
   */
  async clear() {
    try {
      await this.redis.del(this.streamKey);
      await this.redis.del(this.metadataKey);
      logger.info('Sensory buffer cleared');
      this.emit('buffer:cleared');
    } catch (error) {
      logger.error('Failed to clear sensory buffer', { error: error.message });
      throw new Error(`Sensory memory clear failed: ${error.message}`);
    }
  }

  /**
   * Compute attention score based on item characteristics
   *
   * @private
   * @param {SensoryItem} item - Sensory item
   * @returns {number} Attention score (0-1)
   */
  _computeAttentionScore(item) {
    let score = 0;

    // Base intensity contributes to attention
    score += item.intensity * 0.3;

    // Novelty: Check if similar items exist in recent history
    // (Simplified - in production, use similarity comparison)
    const novelty = 0.5; // Placeholder
    score += novelty * 0.3;

    // Keyword matching
    const dataString = JSON.stringify(item.data).toLowerCase();
    const hasKeyword = this.attentionThreshold.keywords.some(keyword =>
      dataString.includes(keyword.toLowerCase())
    );
    if (hasKeyword) {
      score += 0.4;
    }

    // Normalize to 0-1 range
    return Math.min(1, Math.max(0, score));
  }

  /**
   * Determine if item should be promoted to working memory
   *
   * @private
   * @param {SensoryItem} item - Sensory item
   * @returns {boolean} True if should promote
   */
  _shouldPromote(item) {
    return (
      item.attentionScore >= this.attentionThreshold.relevance ||
      item.intensity >= this.attentionThreshold.importance
    );
  }

  /**
   * Enforce capacity limit using FIFO eviction
   *
   * @private
   * @returns {Promise<void>}
   */
  async _enforceCapacity() {
    try {
      const currentSize = await this.size();

      if (currentSize > this.capacity) {
        const toRemove = currentSize - this.capacity;

        // Get oldest entries
        const oldestEntries = await this.redis.xrange(
          this.streamKey,
          '-',
          '+',
          'COUNT',
          toRemove
        );

        // Remove oldest entries
        for (const [streamId, fields] of oldestEntries) {
          await this.redis.xdel(this.streamKey, streamId);

          // Extract id from fields
          const fieldMap = {};
          for (let i = 0; i < fields.length; i += 2) {
            fieldMap[fields[i]] = fields[i + 1];
          }

          if (fieldMap.id) {
            await this.redis.hdel(this.metadataKey, fieldMap.id);
          }
        }

        logger.debug('Enforced capacity limit', { removed: toRemove });
        this.emit('capacity:enforced', { removed: toRemove });
      }
    } catch (error) {
      logger.error('Failed to enforce capacity', { error: error.message });
    }
  }

  /**
   * Clean up expired items based on TTL
   *
   * @private
   * @returns {Promise<void>}
   */
  async _cleanup() {
    try {
      const now = Date.now();
      const expiryThreshold = now - this.ttl;

      // Get all entries
      const entries = await this.redis.xrange(this.streamKey, '-', '+');

      let removed = 0;
      for (const [streamId, fields] of entries) {
        const fieldMap = {};
        for (let i = 0; i < fields.length; i += 2) {
          fieldMap[fields[i]] = fields[i + 1];
        }

        const timestamp = parseInt(fieldMap.timestamp);

        if (timestamp < expiryThreshold) {
          await this.redis.xdel(this.streamKey, streamId);

          if (fieldMap.id) {
            await this.redis.hdel(this.metadataKey, fieldMap.id);
          }

          removed++;
        }
      }

      if (removed > 0) {
        logger.debug('Cleaned up expired sensory items', { removed });
        this.emit('cleanup:completed', { removed });
      }
    } catch (error) {
      logger.error('Cleanup failed', { error: error.message });
    }
  }

  /**
   * Start automatic cleanup timer
   *
   * @private
   */
  startCleanup() {
    if (this.cleanupTimer) {
      clearInterval(this.cleanupTimer);
    }

    this.cleanupTimer = setInterval(() => {
      this._cleanup();
    }, this.cleanupInterval);

    logger.debug('Cleanup timer started', { interval: this.cleanupInterval });
  }

  /**
   * Stop automatic cleanup timer
   */
  stopCleanup() {
    if (this.cleanupTimer) {
      clearInterval(this.cleanupTimer);
      this.cleanupTimer = null;
      logger.debug('Cleanup timer stopped');
    }
  }

  /**
   * Destroy sensory memory instance
   */
  async destroy() {
    this.stopCleanup();
    await this.clear();
    this.removeAllListeners();
    logger.info('Sensory memory destroyed');
  }
}

export default SensoryMemory;
