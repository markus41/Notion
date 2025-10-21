/**
 * Episodic Memory Layer
 *
 * Long-term storage of experiences and events with temporal context.
 * Based on cognitive psychology's episodic memory (autobiographical experiences).
 *
 * Characteristics:
 * - Duration: Persistent (no automatic expiry)
 * - Capacity: Unlimited (limited by database storage)
 * - Backend: Cosmos DB with temporal indexing
 * - Purpose: Store contextual experiences, conversations, and significant events
 *
 * @module memory/layers/episodic-memory
 */

import { createLogger } from '../../utils/logger.js';
import { EventEmitter } from 'events';

const logger = createLogger('EpisodicMemory');

/**
 * Episode types
 * @enum {string}
 */
export const EpisodeType = {
  CONVERSATION: 'conversation',
  TASK_EXECUTION: 'task_execution',
  DECISION_POINT: 'decision_point',
  ERROR_EVENT: 'error_event',
  USER_INTERACTION: 'user_interaction',
  SYSTEM_EVENT: 'system_event',
  LEARNING_MOMENT: 'learning_moment'
};

/**
 * Episode structure
 * @typedef {Object} Episode
 * @property {string} id - Unique identifier
 * @property {EpisodeType} type - Type of episode
 * @property {number} timestamp - Event timestamp
 * @property {number} duration - Duration in milliseconds
 * @property {Object} context - Contextual information
 * @property {Object} data - Episode data
 * @property {string[]} participants - Involved entities (users, agents)
 * @property {string[]} tags - Tags for categorization
 * @property {Object} emotions - Emotional valence (if applicable)
 * @property {string} summary - Compressed summary
 * @property {string[]} relatedEpisodes - Related episode IDs
 * @property {Object} metadata - Additional metadata
 */

/**
 * Temporal query structure
 * @typedef {Object} TemporalQuery
 * @property {number} [startTime] - Start timestamp
 * @property {number} [endTime] - End timestamp
 * @property {string} [timeframe] - Relative timeframe ('last_hour', 'today', 'this_week')
 * @property {EpisodeType} [type] - Filter by type
 * @property {string[]} [participants] - Filter by participants
 * @property {string[]} [tags] - Filter by tags
 * @property {number} [limit=50] - Maximum results
 */

/**
 * Episodic Memory Manager
 *
 * Manages long-term episodic memories with temporal indexing,
 * semantic compression, and contextual retrieval.
 */
export class EpisodicMemory extends EventEmitter {
  /**
   * @param {Object} config - Configuration object
   * @param {Object} config.cosmosClient - Cosmos DB client instance
   * @param {string} config.databaseId - Cosmos database ID
   * @param {string} config.containerId - Cosmos container ID
   * @param {number} [config.compressionThreshold=5000] - Bytes threshold for compression
   * @param {number} [config.maxEpisodesPerQuery=100] - Max episodes per query
   * @param {boolean} [config.enableChangeFeed=true] - Enable change feed
   */
  constructor(config) {
    super();

    this.cosmosClient = config.cosmosClient;
    this.databaseId = config.databaseId;
    this.containerId = config.containerId;
    this.compressionThreshold = config.compressionThreshold || 5000;
    this.maxEpisodesPerQuery = config.maxEpisodesPerQuery || 100;
    this.enableChangeFeed = config.enableChangeFeed !== false;

    // Initialize database connection
    this.database = null;
    this.container = null;
    this.changeFeedProcessor = null;

    this._initialize();

    logger.info('Episodic memory initialized', {
      databaseId: this.databaseId,
      containerId: this.containerId
    });
  }

  /**
   * Initialize Cosmos DB connection
   *
   * @private
   */
  async _initialize() {
    try {
      this.database = this.cosmosClient.database(this.databaseId);
      this.container = this.database.container(this.containerId);

      // Start change feed processor if enabled
      if (this.enableChangeFeed) {
        await this._startChangeFeed();
      }

      logger.info('Cosmos DB connection established');
    } catch (error) {
      logger.error('Failed to initialize Cosmos DB', { error: error.message });
      throw new Error(`Episodic memory initialization failed: ${error.message}`);
    }
  }

  /**
   * Store episode in episodic memory
   *
   * @param {EpisodeType} type - Type of episode
   * @param {Object} data - Episode data
   * @param {Object} [options={}] - Additional options
   * @param {Object} [options.context={}] - Contextual information
   * @param {string[]} [options.participants=[]] - Involved participants
   * @param {string[]} [options.tags=[]] - Tags
   * @param {number} [options.duration=0] - Duration in ms
   * @param {Object} [options.emotions={}] - Emotional context
   * @param {string[]} [options.relatedEpisodes=[]] - Related episode IDs
   * @returns {Promise<Episode>} Created episode
   */
  async store(type, data, options = {}) {
    try {
      const timestamp = Date.now();
      const id = `episode:${timestamp}:${Math.random().toString(36).substr(2, 9)}`;

      // Compress data if needed
      const compressedData = this._compressIfNeeded(data);

      // Generate semantic summary
      const summary = await this._generateSummary(type, data);

      const episode = {
        id,
        type,
        timestamp,
        duration: options.duration || 0,
        context: options.context || {},
        data: compressedData,
        participants: options.participants || [],
        tags: options.tags || [],
        emotions: options.emotions || {},
        summary,
        relatedEpisodes: options.relatedEpisodes || [],
        metadata: {
          compressed: compressedData !== data,
          originalSize: JSON.stringify(data).length,
          createdAt: new Date(timestamp).toISOString(),
          version: '1.0'
        }
      };

      // Store in Cosmos DB
      const { resource } = await this.container.items.create(episode);

      logger.debug('Episode stored', {
        id,
        type,
        compressed: episode.metadata.compressed
      });

      this.emit('episode:stored', resource);

      return resource;
    } catch (error) {
      logger.error('Failed to store episode', { error: error.message, type });
      throw new Error(`Episode storage failed: ${error.message}`);
    }
  }

  /**
   * Retrieve episode by ID
   *
   * @param {string} id - Episode ID
   * @param {Object} [options={}] - Retrieval options
   * @param {boolean} [options.decompress=true] - Decompress data if compressed
   * @returns {Promise<Episode|null>} Episode or null if not found
   */
  async retrieve(id, options = {}) {
    try {
      const { resource } = await this.container.item(id, id).read();

      if (!resource) {
        return null;
      }

      // Decompress data if needed
      if (options.decompress !== false && resource.metadata.compressed) {
        resource.data = this._decompress(resource.data);
      }

      logger.debug('Episode retrieved', { id });

      return resource;
    } catch (error) {
      if (error.code === 404) {
        return null;
      }

      logger.error('Failed to retrieve episode', { error: error.message, id });
      throw new Error(`Episode retrieval failed: ${error.message}`);
    }
  }

  /**
   * Query episodes with temporal and contextual filters
   *
   * @param {TemporalQuery} query - Query parameters
   * @returns {Promise<Episode[]>} Array of episodes
   */
  async query(query = {}) {
    try {
      // Build query
      let querySpec = {
        query: 'SELECT * FROM c WHERE 1=1',
        parameters: []
      };

      // Time range filters
      const timeRange = this._parseTimeRange(query);
      if (timeRange.startTime) {
        querySpec.query += ' AND c.timestamp >= @startTime';
        querySpec.parameters.push({ name: '@startTime', value: timeRange.startTime });
      }
      if (timeRange.endTime) {
        querySpec.query += ' AND c.timestamp <= @endTime';
        querySpec.parameters.push({ name: '@endTime', value: timeRange.endTime });
      }

      // Type filter
      if (query.type) {
        querySpec.query += ' AND c.type = @type';
        querySpec.parameters.push({ name: '@type', value: query.type });
      }

      // Participants filter
      if (query.participants && query.participants.length > 0) {
        querySpec.query += ' AND ARRAY_CONTAINS(@participants, c.participants, true)';
        querySpec.parameters.push({ name: '@participants', value: query.participants });
      }

      // Tags filter
      if (query.tags && query.tags.length > 0) {
        querySpec.query += ' AND EXISTS(SELECT VALUE t FROM t IN c.tags WHERE ARRAY_CONTAINS(@tags, t))';
        querySpec.parameters.push({ name: '@tags', value: query.tags });
      }

      // Order by timestamp descending
      querySpec.query += ' ORDER BY c.timestamp DESC';

      // Execute query
      const { resources } = await this.container.items
        .query(querySpec, {
          maxItemCount: Math.min(query.limit || 50, this.maxEpisodesPerQuery)
        })
        .fetchAll();

      logger.debug('Episodes queried', {
        results: resources.length,
        query: query
      });

      return resources;
    } catch (error) {
      logger.error('Failed to query episodes', { error: error.message });
      throw new Error(`Episode query failed: ${error.message}`);
    }
  }

  /**
   * Search episodes by semantic content
   *
   * @param {string} searchText - Search query
   * @param {Object} [options={}] - Search options
   * @param {number} [options.limit=20] - Maximum results
   * @param {EpisodeType} [options.type] - Filter by type
   * @returns {Promise<Episode[]>} Array of matching episodes
   */
  async search(searchText, options = {}) {
    try {
      // Build search query (simplified - in production, use full-text search)
      const querySpec = {
        query: `
          SELECT * FROM c
          WHERE CONTAINS(LOWER(c.summary), @searchText)
             OR CONTAINS(LOWER(c.type), @searchText)
             OR ARRAY_CONTAINS(c.tags, @searchText)
          ${options.type ? 'AND c.type = @type' : ''}
          ORDER BY c.timestamp DESC
        `,
        parameters: [
          { name: '@searchText', value: searchText.toLowerCase() }
        ]
      };

      if (options.type) {
        querySpec.parameters.push({ name: '@type', value: options.type });
      }

      const { resources } = await this.container.items
        .query(querySpec, {
          maxItemCount: options.limit || 20
        })
        .fetchAll();

      logger.debug('Episodes searched', {
        searchText,
        results: resources.length
      });

      return resources;
    } catch (error) {
      logger.error('Failed to search episodes', { error: error.message });
      throw new Error(`Episode search failed: ${error.message}`);
    }
  }

  /**
   * Update episode
   *
   * @param {string} id - Episode ID
   * @param {Object} updates - Fields to update
   * @returns {Promise<Episode>} Updated episode
   */
  async update(id, updates) {
    try {
      const episode = await this.retrieve(id);

      if (!episode) {
        throw new Error(`Episode not found: ${id}`);
      }

      // Apply updates
      const updated = { ...episode, ...updates };
      updated.metadata.updatedAt = new Date().toISOString();

      // Replace in Cosmos DB
      const { resource } = await this.container.item(id, id).replace(updated);

      logger.debug('Episode updated', { id });
      this.emit('episode:updated', resource);

      return resource;
    } catch (error) {
      logger.error('Failed to update episode', { error: error.message, id });
      throw new Error(`Episode update failed: ${error.message}`);
    }
  }

  /**
   * Delete episode
   *
   * @param {string} id - Episode ID
   * @returns {Promise<boolean>} True if deleted
   */
  async delete(id) {
    try {
      await this.container.item(id, id).delete();

      logger.debug('Episode deleted', { id });
      this.emit('episode:deleted', { id });

      return true;
    } catch (error) {
      if (error.code === 404) {
        return false;
      }

      logger.error('Failed to delete episode', { error: error.message, id });
      throw new Error(`Episode deletion failed: ${error.message}`);
    }
  }

  /**
   * Get episode count
   *
   * @param {Object} [filters={}] - Optional filters
   * @returns {Promise<number>} Episode count
   */
  async count(filters = {}) {
    try {
      let query = 'SELECT VALUE COUNT(1) FROM c';
      const parameters = [];

      if (filters.type) {
        query += ' WHERE c.type = @type';
        parameters.push({ name: '@type', value: filters.type });
      }

      const { resources } = await this.container.items
        .query({ query, parameters })
        .fetchAll();

      return resources[0] || 0;
    } catch (error) {
      logger.error('Failed to count episodes', { error: error.message });
      return 0;
    }
  }

  /**
   * Parse time range from query
   *
   * @private
   * @param {TemporalQuery} query - Query parameters
   * @returns {Object} Start and end timestamps
   */
  _parseTimeRange(query) {
    const now = Date.now();
    let startTime = query.startTime;
    let endTime = query.endTime;

    if (query.timeframe) {
      switch (query.timeframe) {
        case 'last_hour':
          startTime = now - 3600000;
          break;
        case 'today':
          startTime = new Date().setHours(0, 0, 0, 0);
          break;
        case 'this_week':
          const dayOfWeek = new Date().getDay();
          startTime = now - (dayOfWeek * 86400000);
          break;
        case 'this_month':
          startTime = new Date(new Date().getFullYear(), new Date().getMonth(), 1).getTime();
          break;
        case 'this_year':
          startTime = new Date(new Date().getFullYear(), 0, 1).getTime();
          break;
      }
      endTime = now;
    }

    return { startTime, endTime };
  }

  /**
   * Compress data if it exceeds threshold
   *
   * @private
   * @param {*} data - Data to compress
   * @returns {*} Compressed or original data
   */
  _compressIfNeeded(data) {
    const size = JSON.stringify(data).length;

    if (size > this.compressionThreshold) {
      // Simplified compression - in production, use proper compression library
      // This is a placeholder for semantic compression
      return {
        _compressed: true,
        _original: data
      };
    }

    return data;
  }

  /**
   * Decompress compressed data
   *
   * @private
   * @param {*} data - Potentially compressed data
   * @returns {*} Decompressed data
   */
  _decompress(data) {
    if (data && data._compressed) {
      return data._original;
    }
    return data;
  }

  /**
   * Generate semantic summary of episode
   *
   * @private
   * @param {EpisodeType} type - Episode type
   * @param {Object} data - Episode data
   * @returns {Promise<string>} Summary text
   */
  async _generateSummary(type, data) {
    // Simplified summary generation
    // In production, use AI summarization service
    try {
      const dataStr = JSON.stringify(data);
      const truncated = dataStr.length > 200
        ? dataStr.substring(0, 200) + '...'
        : dataStr;

      return `${type}: ${truncated}`;
    } catch (error) {
      return `${type} episode`;
    }
  }

  /**
   * Start change feed processor
   *
   * @private
   */
  async _startChangeFeed() {
    try {
      // Simplified change feed setup
      // In production, use proper change feed processor
      logger.info('Change feed processor would be initialized here');
      // this.changeFeedProcessor = await this.container.items.changeFeed().start();
    } catch (error) {
      logger.error('Failed to start change feed', { error: error.message });
    }
  }

  /**
   * Stop change feed processor
   */
  async stopChangeFeed() {
    if (this.changeFeedProcessor) {
      // await this.changeFeedProcessor.stop();
      this.changeFeedProcessor = null;
      logger.info('Change feed processor stopped');
    }
  }

  /**
   * Destroy episodic memory instance
   */
  async destroy() {
    await this.stopChangeFeed();
    this.removeAllListeners();
    logger.info('Episodic memory destroyed');
  }
}

export default EpisodicMemory;
