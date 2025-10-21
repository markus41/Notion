/**
 * Semantic Memory Layer
 *
 * Long-term knowledge storage using vector embeddings for semantic retrieval.
 * Based on cognitive psychology's semantic memory (factual knowledge, concepts).
 *
 * Characteristics:
 * - Duration: Persistent (no automatic expiry)
 * - Capacity: Unlimited (limited by vector database)
 * - Backend: Pinecone with OpenAI embeddings
 * - Purpose: Store factual knowledge, concepts, and learned patterns
 *
 * @module memory/layers/semantic-memory
 */

import { createLogger } from '../../utils/logger.js';
import { EventEmitter } from 'events';

const logger = createLogger('SemanticMemory');

/**
 * Knowledge types
 * @enum {string}
 */
export const KnowledgeType = {
  FACT: 'fact',
  CONCEPT: 'concept',
  RELATIONSHIP: 'relationship',
  RULE: 'rule',
  PATTERN: 'pattern',
  DEFINITION: 'definition',
  EXAMPLE: 'example'
};

/**
 * Knowledge item structure
 * @typedef {Object} KnowledgeItem
 * @property {string} id - Unique identifier
 * @property {KnowledgeType} type - Type of knowledge
 * @property {string} content - Text content
 * @property {number[]} embedding - Vector embedding
 * @property {Object} metadata - Additional metadata
 * @property {string[]} tags - Tags for categorization
 * @property {string[]} relatedConcepts - Related concept IDs
 * @property {number} confidence - Confidence score (0-1)
 * @property {string} source - Source of knowledge
 * @property {number} timestamp - Creation timestamp
 */

/**
 * Similarity query structure
 * @typedef {Object} SimilarityQuery
 * @property {string} [text] - Query text (will be embedded)
 * @property {number[]} [vector] - Pre-computed query vector
 * @property {number} [topK=10] - Number of results
 * @property {number} [threshold=0.7] - Minimum similarity score
 * @property {Object} [filter] - Metadata filters
 * @property {boolean} [includeMetadata=true] - Include metadata in results
 */

/**
 * Semantic Memory Manager
 *
 * Manages long-term semantic knowledge using vector embeddings
 * for similarity-based retrieval and knowledge graph construction.
 */
export class SemanticMemory extends EventEmitter {
  /**
   * @param {Object} config - Configuration object
   * @param {Object} config.pineconeClient - Pinecone client instance
   * @param {string} config.indexName - Pinecone index name
   * @param {Object} config.embeddingClient - OpenAI client for embeddings
   * @param {string} [config.embeddingModel='text-embedding-ada-002'] - Embedding model
   * @param {number} [config.embeddingDimension=1536] - Embedding dimension
   * @param {number} [config.similarityThreshold=0.7] - Default similarity threshold
   * @param {number} [config.maxBatchSize=100] - Max batch size for operations
   */
  constructor(config) {
    super();

    this.pineconeClient = config.pineconeClient;
    this.indexName = config.indexName;
    this.embeddingClient = config.embeddingClient;
    this.embeddingModel = config.embeddingModel || 'text-embedding-ada-002';
    this.embeddingDimension = config.embeddingDimension || 1536;
    this.similarityThreshold = config.similarityThreshold || 0.7;
    this.maxBatchSize = config.maxBatchSize || 100;

    // Initialize index
    this.index = null;
    this._initialize();

    logger.info('Semantic memory initialized', {
      indexName: this.indexName,
      model: this.embeddingModel,
      dimension: this.embeddingDimension
    });
  }

  /**
   * Initialize Pinecone index
   *
   * @private
   */
  async _initialize() {
    try {
      this.index = this.pineconeClient.Index(this.indexName);
      logger.info('Pinecone index connected', { indexName: this.indexName });
    } catch (error) {
      logger.error('Failed to initialize Pinecone index', { error: error.message });
      throw new Error(`Semantic memory initialization failed: ${error.message}`);
    }
  }

  /**
   * Store knowledge item in semantic memory
   *
   * @param {KnowledgeType} type - Type of knowledge
   * @param {string} content - Text content
   * @param {Object} [options={}] - Additional options
   * @param {string[]} [options.tags=[]] - Tags
   * @param {string[]} [options.relatedConcepts=[]] - Related concept IDs
   * @param {number} [options.confidence=1.0] - Confidence score
   * @param {string} [options.source='user'] - Source of knowledge
   * @param {Object} [options.metadata={}] - Additional metadata
   * @returns {Promise<KnowledgeItem>} Created knowledge item
   */
  async store(type, content, options = {}) {
    try {
      const timestamp = Date.now();
      const id = `knowledge:${timestamp}:${Math.random().toString(36).substr(2, 9)}`;

      // Generate embedding
      const embedding = await this._generateEmbedding(content);

      const knowledgeItem = {
        id,
        type,
        content,
        embedding,
        metadata: {
          ...options.metadata,
          tags: options.tags || [],
          relatedConcepts: options.relatedConcepts || [],
          confidence: options.confidence || 1.0,
          source: options.source || 'user',
          timestamp,
          createdAt: new Date(timestamp).toISOString()
        }
      };

      // Upsert to Pinecone
      await this.index.upsert([
        {
          id,
          values: embedding,
          metadata: {
            type,
            content,
            ...knowledgeItem.metadata
          }
        }
      ]);

      logger.debug('Knowledge item stored', { id, type });
      this.emit('knowledge:stored', knowledgeItem);

      return knowledgeItem;
    } catch (error) {
      logger.error('Failed to store knowledge item', { error: error.message, type });
      throw new Error(`Knowledge storage failed: ${error.message}`);
    }
  }

  /**
   * Store multiple knowledge items in batch
   *
   * @param {Array<{type: KnowledgeType, content: string, options?: Object}>} items - Items to store
   * @returns {Promise<KnowledgeItem[]>} Created knowledge items
   */
  async storeBatch(items) {
    try {
      const results = [];

      // Process in batches
      for (let i = 0; i < items.length; i += this.maxBatchSize) {
        const batch = items.slice(i, i + this.maxBatchSize);

        // Generate embeddings in parallel
        const embeddings = await Promise.all(
          batch.map(item => this._generateEmbedding(item.content))
        );

        // Create knowledge items
        const knowledgeItems = batch.map((item, idx) => {
          const timestamp = Date.now();
          const id = `knowledge:${timestamp}:${idx}:${Math.random().toString(36).substr(2, 9)}`;

          return {
            id,
            type: item.type,
            content: item.content,
            embedding: embeddings[idx],
            metadata: {
              ...(item.options?.metadata || {}),
              tags: item.options?.tags || [],
              relatedConcepts: item.options?.relatedConcepts || [],
              confidence: item.options?.confidence || 1.0,
              source: item.options?.source || 'user',
              timestamp,
              createdAt: new Date(timestamp).toISOString()
            }
          };
        });

        // Upsert batch to Pinecone
        const vectors = knowledgeItems.map(item => ({
          id: item.id,
          values: item.embedding,
          metadata: {
            type: item.type,
            content: item.content,
            ...item.metadata
          }
        }));

        await this.index.upsert(vectors);
        results.push(...knowledgeItems);
      }

      logger.info('Knowledge batch stored', { count: results.length });
      this.emit('knowledge:batch_stored', { count: results.length });

      return results;
    } catch (error) {
      logger.error('Failed to store knowledge batch', { error: error.message });
      throw new Error(`Knowledge batch storage failed: ${error.message}`);
    }
  }

  /**
   * Retrieve knowledge item by ID
   *
   * @param {string} id - Knowledge item ID
   * @returns {Promise<KnowledgeItem|null>} Knowledge item or null
   */
  async retrieve(id) {
    try {
      const result = await this.index.fetch([id]);

      if (!result.vectors || !result.vectors[id]) {
        return null;
      }

      const vector = result.vectors[id];

      return {
        id: vector.id,
        type: vector.metadata.type,
        content: vector.metadata.content,
        embedding: vector.values,
        metadata: vector.metadata
      };
    } catch (error) {
      logger.error('Failed to retrieve knowledge item', { error: error.message, id });
      throw new Error(`Knowledge retrieval failed: ${error.message}`);
    }
  }

  /**
   * Search for similar knowledge items
   *
   * @param {SimilarityQuery} query - Similarity query
   * @returns {Promise<Array<{item: KnowledgeItem, score: number}>>} Similar items with scores
   */
  async search(query) {
    try {
      let queryVector;

      // Get query vector
      if (query.vector) {
        queryVector = query.vector;
      } else if (query.text) {
        queryVector = await this._generateEmbedding(query.text);
      } else {
        throw new Error('Either text or vector must be provided');
      }

      // Build query options
      const queryOptions = {
        topK: query.topK || 10,
        includeMetadata: query.includeMetadata !== false,
        includeValues: true
      };

      // Add filters if provided
      if (query.filter) {
        queryOptions.filter = query.filter;
      }

      // Execute similarity search
      const results = await this.index.query({
        vector: queryVector,
        ...queryOptions
      });

      // Filter by threshold and format results
      const threshold = query.threshold || this.similarityThreshold;
      const formattedResults = results.matches
        .filter(match => match.score >= threshold)
        .map(match => ({
          item: {
            id: match.id,
            type: match.metadata?.type,
            content: match.metadata?.content,
            embedding: match.values,
            metadata: match.metadata
          },
          score: match.score
        }));

      logger.debug('Similarity search completed', {
        query: query.text || 'vector',
        results: formattedResults.length
      });

      return formattedResults;
    } catch (error) {
      logger.error('Failed to search knowledge', { error: error.message });
      throw new Error(`Knowledge search failed: ${error.message}`);
    }
  }

  /**
   * Find related concepts using knowledge graph traversal
   *
   * @param {string} conceptId - Starting concept ID
   * @param {Object} [options={}] - Traversal options
   * @param {number} [options.maxDepth=2] - Maximum traversal depth
   * @param {number} [options.maxResults=20] - Maximum related concepts
   * @returns {Promise<KnowledgeItem[]>} Related concepts
   */
  async findRelated(conceptId, options = {}) {
    try {
      const maxDepth = options.maxDepth || 2;
      const maxResults = options.maxResults || 20;

      const visited = new Set([conceptId]);
      const related = [];
      const queue = [{ id: conceptId, depth: 0 }];

      while (queue.length > 0 && related.length < maxResults) {
        const { id, depth } = queue.shift();

        if (depth >= maxDepth) {
          continue;
        }

        // Get concept
        const concept = await this.retrieve(id);

        if (!concept) {
          continue;
        }

        // Add to results (skip the starting concept)
        if (id !== conceptId) {
          related.push(concept);
        }

        // Add related concepts to queue
        const relatedConceptIds = concept.metadata.relatedConcepts || [];
        for (const relatedId of relatedConceptIds) {
          if (!visited.has(relatedId)) {
            visited.add(relatedId);
            queue.push({ id: relatedId, depth: depth + 1 });
          }
        }
      }

      logger.debug('Related concepts found', { conceptId, count: related.length });

      return related.slice(0, maxResults);
    } catch (error) {
      logger.error('Failed to find related concepts', { error: error.message, conceptId });
      throw new Error(`Related concept search failed: ${error.message}`);
    }
  }

  /**
   * Cluster similar knowledge items
   *
   * @param {Object} [options={}] - Clustering options
   * @param {KnowledgeType} [options.type] - Filter by type
   * @param {number} [options.numClusters=5] - Number of clusters
   * @param {number} [options.sampleSize=1000] - Sample size for clustering
   * @returns {Promise<Array<{cluster: number, items: KnowledgeItem[]}>>} Clustered items
   */
  async cluster(options = {}) {
    try {
      // Simplified clustering implementation
      // In production, use k-means or hierarchical clustering

      // Query random sample
      const queryVector = new Array(this.embeddingDimension).fill(0);
      const results = await this.index.query({
        vector: queryVector,
        topK: options.sampleSize || 1000,
        includeMetadata: true,
        includeValues: true,
        filter: options.type ? { type: options.type } : undefined
      });

      // Group by similarity (simplified clustering)
      const numClusters = options.numClusters || 5;
      const clusters = Array.from({ length: numClusters }, () => []);

      results.matches.forEach((match, idx) => {
        const clusterIdx = idx % numClusters;
        clusters[clusterIdx].push({
          id: match.id,
          type: match.metadata?.type,
          content: match.metadata?.content,
          embedding: match.values,
          metadata: match.metadata
        });
      });

      const formattedClusters = clusters.map((items, idx) => ({
        cluster: idx,
        items
      }));

      logger.debug('Knowledge clustered', { clusters: numClusters, totalItems: results.matches.length });

      return formattedClusters;
    } catch (error) {
      logger.error('Failed to cluster knowledge', { error: error.message });
      throw new Error(`Knowledge clustering failed: ${error.message}`);
    }
  }

  /**
   * Update knowledge item
   *
   * @param {string} id - Knowledge item ID
   * @param {Object} updates - Fields to update
   * @returns {Promise<KnowledgeItem>} Updated knowledge item
   */
  async update(id, updates) {
    try {
      // Get existing item
      const existing = await this.retrieve(id);

      if (!existing) {
        throw new Error(`Knowledge item not found: ${id}`);
      }

      // Determine if content changed (need new embedding)
      const contentChanged = updates.content && updates.content !== existing.content;
      let embedding = existing.embedding;

      if (contentChanged) {
        embedding = await this._generateEmbedding(updates.content);
      }

      // Merge metadata
      const updatedMetadata = {
        ...existing.metadata,
        ...updates.metadata,
        updatedAt: new Date().toISOString()
      };

      // Update in Pinecone
      await this.index.upsert([
        {
          id,
          values: embedding,
          metadata: {
            type: updates.type || existing.type,
            content: updates.content || existing.content,
            ...updatedMetadata
          }
        }
      ]);

      const updated = {
        id,
        type: updates.type || existing.type,
        content: updates.content || existing.content,
        embedding,
        metadata: updatedMetadata
      };

      logger.debug('Knowledge item updated', { id });
      this.emit('knowledge:updated', updated);

      return updated;
    } catch (error) {
      logger.error('Failed to update knowledge item', { error: error.message, id });
      throw new Error(`Knowledge update failed: ${error.message}`);
    }
  }

  /**
   * Delete knowledge item
   *
   * @param {string} id - Knowledge item ID
   * @returns {Promise<boolean>} True if deleted
   */
  async delete(id) {
    try {
      await this.index.delete1([id]);

      logger.debug('Knowledge item deleted', { id });
      this.emit('knowledge:deleted', { id });

      return true;
    } catch (error) {
      logger.error('Failed to delete knowledge item', { error: error.message, id });
      throw new Error(`Knowledge deletion failed: ${error.message}`);
    }
  }

  /**
   * Delete multiple knowledge items
   *
   * @param {string[]} ids - Knowledge item IDs
   * @returns {Promise<number>} Number of items deleted
   */
  async deleteBatch(ids) {
    try {
      // Process in batches
      let deleted = 0;

      for (let i = 0; i < ids.length; i += this.maxBatchSize) {
        const batch = ids.slice(i, i + this.maxBatchSize);
        await this.index.delete1(batch);
        deleted += batch.length;
      }

      logger.info('Knowledge batch deleted', { count: deleted });
      this.emit('knowledge:batch_deleted', { count: deleted });

      return deleted;
    } catch (error) {
      logger.error('Failed to delete knowledge batch', { error: error.message });
      throw new Error(`Knowledge batch deletion failed: ${error.message}`);
    }
  }

  /**
   * Get index statistics
   *
   * @returns {Promise<Object>} Index statistics
   */
  async getStats() {
    try {
      const stats = await this.index.describeIndexStats();

      logger.debug('Index statistics retrieved', stats);

      return stats;
    } catch (error) {
      logger.error('Failed to get index stats', { error: error.message });
      return { totalVectorCount: 0 };
    }
  }

  /**
   * Generate embedding for text
   *
   * @private
   * @param {string} text - Text to embed
   * @returns {Promise<number[]>} Embedding vector
   */
  async _generateEmbedding(text) {
    try {
      const response = await this.embeddingClient.embeddings.create({
        model: this.embeddingModel,
        input: text
      });

      const embedding = response.data[0].embedding;

      if (embedding.length !== this.embeddingDimension) {
        throw new Error(
          `Embedding dimension mismatch: expected ${this.embeddingDimension}, got ${embedding.length}`
        );
      }

      return embedding;
    } catch (error) {
      logger.error('Failed to generate embedding', { error: error.message });
      throw new Error(`Embedding generation failed: ${error.message}`);
    }
  }

  /**
   * Destroy semantic memory instance
   */
  async destroy() {
    this.removeAllListeners();
    logger.info('Semantic memory destroyed');
  }
}

export default SemanticMemory;
