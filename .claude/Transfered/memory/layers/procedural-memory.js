/**
 * Procedural Memory Layer
 *
 * Long-term storage of skills, patterns, and learned procedures.
 * Based on cognitive psychology's procedural memory (motor skills, habits).
 *
 * Characteristics:
 * - Duration: Persistent with versioning
 * - Capacity: Unlimited (limited by Git repository)
 * - Backend: Git-based versioning system
 * - Purpose: Store learned patterns, workflows, and executable skills
 *
 * @module memory/layers/procedural-memory
 */

import { createLogger } from '../../utils/logger.js';
import { EventEmitter } from 'events';
import fs from 'fs/promises';
import path from 'path';
import { execSync } from 'child_process';

const logger = createLogger('ProceduralMemory');

/**
 * Skill types
 * @enum {string}
 */
export const SkillType = {
  CODE_PATTERN: 'code_pattern',
  WORKFLOW: 'workflow',
  AUTOMATION: 'automation',
  TEMPLATE: 'template',
  FUNCTION: 'function',
  ALGORITHM: 'algorithm',
  HEURISTIC: 'heuristic'
};

/**
 * Skill execution context
 * @typedef {Object} ExecutionContext
 * @property {Object} inputs - Input parameters
 * @property {Object} environment - Environment variables
 * @property {Object} state - Current state
 */

/**
 * Skill structure
 * @typedef {Object} Skill
 * @property {string} id - Unique identifier
 * @property {SkillType} type - Type of skill
 * @property {string} name - Skill name
 * @property {string} description - Description
 * @property {string} code - Executable code or pattern
 * @property {Object} metadata - Metadata
 * @property {string[]} tags - Tags
 * @property {string[]} dependencies - Required dependencies
 * @property {Object} performance - Performance metrics
 * @property {number} usageCount - Times executed
 * @property {number} successRate - Success rate (0-1)
 * @property {string} version - Git commit hash
 * @property {number} timestamp - Creation timestamp
 */

/**
 * Skill execution result
 * @typedef {Object} ExecutionResult
 * @property {boolean} success - Execution success
 * @property {*} output - Execution output
 * @property {number} duration - Execution duration (ms)
 * @property {Error} [error] - Error if failed
 * @property {Object} metrics - Performance metrics
 */

/**
 * Procedural Memory Manager
 *
 * Manages learned skills and patterns with Git-based versioning,
 * execution tracking, and performance optimization.
 */
export class ProceduralMemory extends EventEmitter {
  /**
   * @param {Object} config - Configuration object
   * @param {string} config.repositoryPath - Git repository path
   * @param {string} [config.skillsDirectory='skills'] - Skills subdirectory
   * @param {string} [config.branch='main'] - Git branch
   * @param {boolean} [config.autoCommit=true] - Auto-commit changes
   * @param {number} [config.performanceThreshold=1000] - Performance threshold (ms)
   */
  constructor(config) {
    super();

    this.repositoryPath = config.repositoryPath;
    this.skillsDirectory = config.skillsDirectory || 'skills';
    this.branch = config.branch || 'main';
    this.autoCommit = config.autoCommit !== false;
    this.performanceThreshold = config.performanceThreshold || 1000;

    // Full path to skills directory
    this.skillsPath = path.join(this.repositoryPath, this.skillsDirectory);

    // In-memory skill cache
    this.skillCache = new Map();

    // Performance tracking
    this.executionHistory = new Map();

    this._initialize();

    logger.info('Procedural memory initialized', {
      repository: this.repositoryPath,
      skillsPath: this.skillsPath,
      branch: this.branch
    });
  }

  /**
   * Initialize Git repository and skills directory
   *
   * @private
   */
  async _initialize() {
    try {
      // Ensure repository exists
      await fs.mkdir(this.repositoryPath, { recursive: true });
      await fs.mkdir(this.skillsPath, { recursive: true });

      // Initialize Git if needed
      try {
        execSync('git rev-parse --git-dir', {
          cwd: this.repositoryPath,
          stdio: 'ignore'
        });
        logger.info('Git repository already initialized');
      } catch (error) {
        execSync('git init', { cwd: this.repositoryPath });
        execSync(`git checkout -b ${this.branch}`, { cwd: this.repositoryPath });
        logger.info('Git repository initialized');
      }

      // Load existing skills
      await this._loadSkills();
    } catch (error) {
      logger.error('Failed to initialize procedural memory', { error: error.message });
      throw new Error(`Procedural memory initialization failed: ${error.message}`);
    }
  }

  /**
   * Store skill in procedural memory
   *
   * @param {SkillType} type - Type of skill
   * @param {string} name - Skill name
   * @param {string} code - Executable code or pattern
   * @param {Object} [options={}] - Additional options
   * @param {string} [options.description=''] - Description
   * @param {string[]} [options.tags=[]] - Tags
   * @param {string[]} [options.dependencies=[]] - Dependencies
   * @param {Object} [options.metadata={}] - Additional metadata
   * @returns {Promise<Skill>} Created skill
   */
  async store(type, name, code, options = {}) {
    try {
      const timestamp = Date.now();
      const id = this._generateSkillId(name);

      const skill = {
        id,
        type,
        name,
        description: options.description || '',
        code,
        metadata: options.metadata || {},
        tags: options.tags || [],
        dependencies: options.dependencies || [],
        performance: {
          averageDuration: 0,
          minDuration: Infinity,
          maxDuration: 0
        },
        usageCount: 0,
        successRate: 1.0,
        version: '',
        timestamp
      };

      // Write skill to file
      const skillPath = this._getSkillPath(id);
      await fs.writeFile(skillPath, JSON.stringify(skill, null, 2), 'utf-8');

      // Git commit
      if (this.autoCommit) {
        const version = await this._commitSkill(id, 'Add skill');
        skill.version = version;
      }

      // Cache skill
      this.skillCache.set(id, skill);

      logger.debug('Skill stored', { id, type, name });
      this.emit('skill:stored', skill);

      return skill;
    } catch (error) {
      logger.error('Failed to store skill', { error: error.message, name });
      throw new Error(`Skill storage failed: ${error.message}`);
    }
  }

  /**
   * Retrieve skill by ID
   *
   * @param {string} id - Skill ID
   * @param {Object} [options={}] - Retrieval options
   * @param {string} [options.version] - Specific version (Git commit hash)
   * @returns {Promise<Skill|null>} Skill or null if not found
   */
  async retrieve(id, options = {}) {
    try {
      // Check cache first
      if (!options.version && this.skillCache.has(id)) {
        return this.skillCache.get(id);
      }

      const skillPath = this._getSkillPath(id);

      // Get specific version if requested
      if (options.version) {
        const content = execSync(
          `git show ${options.version}:${path.relative(this.repositoryPath, skillPath)}`,
          { cwd: this.repositoryPath, encoding: 'utf-8' }
        );
        return JSON.parse(content);
      }

      // Read current version
      try {
        const content = await fs.readFile(skillPath, 'utf-8');
        const skill = JSON.parse(content);

        // Update cache
        this.skillCache.set(id, skill);

        return skill;
      } catch (error) {
        if (error.code === 'ENOENT') {
          return null;
        }
        throw error;
      }
    } catch (error) {
      logger.error('Failed to retrieve skill', { error: error.message, id });
      throw new Error(`Skill retrieval failed: ${error.message}`);
    }
  }

  /**
   * Query skills by criteria
   *
   * @param {Object} [query={}] - Query parameters
   * @param {SkillType} [query.type] - Filter by type
   * @param {string[]} [query.tags] - Filter by tags
   * @param {number} [query.minSuccessRate] - Minimum success rate
   * @param {number} [query.limit=50] - Maximum results
   * @returns {Promise<Skill[]>} Array of skills
   */
  async query(query = {}) {
    try {
      let skills = Array.from(this.skillCache.values());

      // Apply filters
      if (query.type) {
        skills = skills.filter(skill => skill.type === query.type);
      }

      if (query.tags && query.tags.length > 0) {
        skills = skills.filter(skill =>
          skill.tags.some(tag => query.tags.includes(tag))
        );
      }

      if (query.minSuccessRate !== undefined) {
        skills = skills.filter(skill => skill.successRate >= query.minSuccessRate);
      }

      // Sort by usage count and success rate
      skills.sort((a, b) => {
        const scoreA = a.usageCount * a.successRate;
        const scoreB = b.usageCount * b.successRate;
        return scoreB - scoreA;
      });

      // Limit results
      const limit = query.limit || 50;
      return skills.slice(0, limit);
    } catch (error) {
      logger.error('Failed to query skills', { error: error.message });
      throw new Error(`Skill query failed: ${error.message}`);
    }
  }

  /**
   * Execute skill with context
   *
   * @param {string} id - Skill ID
   * @param {ExecutionContext} context - Execution context
   * @returns {Promise<ExecutionResult>} Execution result
   */
  async execute(id, context) {
    const startTime = Date.now();

    try {
      const skill = await this.retrieve(id);

      if (!skill) {
        throw new Error(`Skill not found: ${id}`);
      }

      logger.debug('Executing skill', { id, name: skill.name });

      // Execute skill (simplified - in production, use proper sandboxing)
      let output;
      try {
        // Create execution function
        const executionFn = new Function(
          'context',
          `
          const { inputs, environment, state } = context;
          ${skill.code}
          `
        );

        output = await executionFn(context);
      } catch (error) {
        throw new Error(`Skill execution error: ${error.message}`);
      }

      const duration = Date.now() - startTime;

      // Update performance metrics
      await this._updatePerformance(id, duration, true);

      const result = {
        success: true,
        output,
        duration,
        metrics: {
          averageDuration: skill.performance.averageDuration,
          performanceScore: this._calculatePerformanceScore(duration)
        }
      };

      logger.debug('Skill executed successfully', { id, duration });
      this.emit('skill:executed', { skill, result });

      return result;
    } catch (error) {
      const duration = Date.now() - startTime;

      // Update performance metrics (failure)
      await this._updatePerformance(id, duration, false);

      const result = {
        success: false,
        output: null,
        duration,
        error,
        metrics: {}
      };

      logger.error('Skill execution failed', { error: error.message, id });
      this.emit('skill:error', { id, error });

      return result;
    }
  }

  /**
   * Compose multiple skills into workflow
   *
   * @param {string} name - Workflow name
   * @param {string[]} skillIds - Skill IDs in execution order
   * @param {Object} [options={}] - Composition options
   * @returns {Promise<Skill>} Composed workflow skill
   */
  async compose(name, skillIds, options = {}) {
    try {
      // Load all skills
      const skills = await Promise.all(
        skillIds.map(id => this.retrieve(id))
      );

      if (skills.some(skill => !skill)) {
        throw new Error('One or more skills not found');
      }

      // Generate composed code
      const composedCode = `
        // Composed workflow: ${name}
        const results = [];
        ${skills.map((skill, idx) => `
          // Step ${idx + 1}: ${skill.name}
          try {
            ${skill.code}
            results.push({ step: ${idx}, success: true, output });
          } catch (error) {
            results.push({ step: ${idx}, success: false, error });
            throw error;
          }
        `).join('\n')}
        return results;
      `;

      // Store composed skill
      const composedSkill = await this.store(
        SkillType.WORKFLOW,
        name,
        composedCode,
        {
          description: `Composed workflow from ${skillIds.length} skills`,
          tags: [...new Set(skills.flatMap(s => s.tags))],
          dependencies: [...new Set(skills.flatMap(s => s.dependencies))],
          metadata: {
            ...options.metadata,
            composedFrom: skillIds,
            stepCount: skills.length
          }
        }
      );

      logger.info('Skills composed into workflow', { name, steps: skillIds.length });
      this.emit('skill:composed', composedSkill);

      return composedSkill;
    } catch (error) {
      logger.error('Failed to compose skills', { error: error.message });
      throw new Error(`Skill composition failed: ${error.message}`);
    }
  }

  /**
   * Update skill
   *
   * @param {string} id - Skill ID
   * @param {Object} updates - Fields to update
   * @returns {Promise<Skill>} Updated skill
   */
  async update(id, updates) {
    try {
      const skill = await this.retrieve(id);

      if (!skill) {
        throw new Error(`Skill not found: ${id}`);
      }

      // Apply updates
      const updated = { ...skill, ...updates };
      updated.metadata.updatedAt = new Date().toISOString();

      // Write to file
      const skillPath = this._getSkillPath(id);
      await fs.writeFile(skillPath, JSON.stringify(updated, null, 2), 'utf-8');

      // Git commit
      if (this.autoCommit) {
        const version = await this._commitSkill(id, 'Update skill');
        updated.version = version;
      }

      // Update cache
      this.skillCache.set(id, updated);

      logger.debug('Skill updated', { id });
      this.emit('skill:updated', updated);

      return updated;
    } catch (error) {
      logger.error('Failed to update skill', { error: error.message, id });
      throw new Error(`Skill update failed: ${error.message}`);
    }
  }

  /**
   * Delete skill
   *
   * @param {string} id - Skill ID
   * @returns {Promise<boolean>} True if deleted
   */
  async delete(id) {
    try {
      const skillPath = this._getSkillPath(id);

      // Remove file
      await fs.unlink(skillPath);

      // Git commit
      if (this.autoCommit) {
        await this._commitSkill(id, 'Delete skill');
      }

      // Remove from cache
      this.skillCache.delete(id);
      this.executionHistory.delete(id);

      logger.debug('Skill deleted', { id });
      this.emit('skill:deleted', { id });

      return true;
    } catch (error) {
      if (error.code === 'ENOENT') {
        return false;
      }

      logger.error('Failed to delete skill', { error: error.message, id });
      throw new Error(`Skill deletion failed: ${error.message}`);
    }
  }

  /**
   * Get skill version history
   *
   * @param {string} id - Skill ID
   * @returns {Promise<Array<{version: string, message: string, date: string}>>} Version history
   */
  async getHistory(id) {
    try {
      const skillPath = path.relative(this.repositoryPath, this._getSkillPath(id));

      const log = execSync(
        `git log --format="%H|%s|%ad" --date=iso -- "${skillPath}"`,
        { cwd: this.repositoryPath, encoding: 'utf-8' }
      );

      if (!log.trim()) {
        return [];
      }

      return log.trim().split('\n').map(line => {
        const [version, message, date] = line.split('|');
        return { version, message, date };
      });
    } catch (error) {
      logger.error('Failed to get skill history', { error: error.message, id });
      return [];
    }
  }

  /**
   * Load all skills from repository
   *
   * @private
   */
  async _loadSkills() {
    try {
      const files = await fs.readdir(this.skillsPath);

      for (const file of files) {
        if (file.endsWith('.json')) {
          const filePath = path.join(this.skillsPath, file);
          const content = await fs.readFile(filePath, 'utf-8');
          const skill = JSON.parse(content);
          this.skillCache.set(skill.id, skill);
        }
      }

      logger.info('Skills loaded', { count: this.skillCache.size });
    } catch (error) {
      logger.error('Failed to load skills', { error: error.message });
    }
  }

  /**
   * Generate skill ID from name
   *
   * @private
   * @param {string} name - Skill name
   * @returns {string} Skill ID
   */
  _generateSkillId(name) {
    return `skill:${name.toLowerCase().replace(/[^a-z0-9]/g, '-')}`;
  }

  /**
   * Get file path for skill
   *
   * @private
   * @param {string} id - Skill ID
   * @returns {string} File path
   */
  _getSkillPath(id) {
    return path.join(this.skillsPath, `${id}.json`);
  }

  /**
   * Commit skill changes to Git
   *
   * @private
   * @param {string} id - Skill ID
   * @param {string} message - Commit message
   * @returns {Promise<string>} Commit hash
   */
  async _commitSkill(id, message) {
    try {
      const skillPath = path.relative(this.repositoryPath, this._getSkillPath(id));

      execSync(`git add "${skillPath}"`, { cwd: this.repositoryPath });
      execSync(`git commit -m "${message}: ${id}"`, { cwd: this.repositoryPath });

      const hash = execSync('git rev-parse HEAD', {
        cwd: this.repositoryPath,
        encoding: 'utf-8'
      }).trim();

      return hash;
    } catch (error) {
      logger.error('Failed to commit skill', { error: error.message, id });
      return '';
    }
  }

  /**
   * Update performance metrics
   *
   * @private
   * @param {string} id - Skill ID
   * @param {number} duration - Execution duration
   * @param {boolean} success - Execution success
   */
  async _updatePerformance(id, duration, success) {
    try {
      const skill = await this.retrieve(id);

      if (!skill) {
        return;
      }

      // Update usage count
      skill.usageCount++;

      // Update performance metrics
      const perf = skill.performance;
      perf.averageDuration = (perf.averageDuration * (skill.usageCount - 1) + duration) / skill.usageCount;
      perf.minDuration = Math.min(perf.minDuration, duration);
      perf.maxDuration = Math.max(perf.maxDuration, duration);

      // Update success rate
      const history = this.executionHistory.get(id) || [];
      history.push(success);

      // Keep last 100 executions
      if (history.length > 100) {
        history.shift();
      }

      this.executionHistory.set(id, history);

      const successCount = history.filter(s => s).length;
      skill.successRate = successCount / history.length;

      // Save updated skill
      await this.update(id, { performance: perf, usageCount: skill.usageCount, successRate: skill.successRate });
    } catch (error) {
      logger.error('Failed to update performance metrics', { error: error.message, id });
    }
  }

  /**
   * Calculate performance score
   *
   * @private
   * @param {number} duration - Execution duration
   * @returns {number} Performance score (0-1)
   */
  _calculatePerformanceScore(duration) {
    if (duration <= this.performanceThreshold) {
      return 1.0;
    }

    // Exponential decay
    return Math.exp(-(duration - this.performanceThreshold) / this.performanceThreshold);
  }

  /**
   * Destroy procedural memory instance
   */
  async destroy() {
    this.skillCache.clear();
    this.executionHistory.clear();
    this.removeAllListeners();
    logger.info('Procedural memory destroyed');
  }
}

export default ProceduralMemory;
