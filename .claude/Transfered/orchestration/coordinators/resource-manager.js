/**
 * Resource Manager
 *
 * Dynamic resource allocation with load balancing, capacity planning,
 * and resource contention resolution.
 *
 * @module orchestration/coordinators/resource-manager
 */

import { EventEmitter } from 'events';

/**
 * @typedef {Object} Resource
 * @property {string} id - Resource identifier
 * @property {string} name - Resource name
 * @property {string} type - Resource type
 * @property {number} capacity - Total capacity
 * @property {number} available - Available capacity
 * @property {Map<string, number>} allocations - Current allocations (consumer -> amount)
 * @property {Object} metadata - Resource metadata
 */

/**
 * @typedef {Object} AllocationRequest
 * @property {string} consumerId - Consumer identifier
 * @property {string} resourceId - Resource identifier
 * @property {number} amount - Amount requested
 * @property {number} priority - Request priority
 * @property {number} duration - Expected duration in ms
 */

export class ResourceManager extends EventEmitter {
  constructor(options = {}) {
    super();

    this.enableLoadBalancing = options.enableLoadBalancing !== false;
    this.allocationStrategy = options.allocationStrategy || 'fair';
    this.overcommitRatio = options.overcommitRatio || 1.0;
    this.logger = options.logger || console.log;

    /** @type {Map<string, Resource>} */
    this.resources = new Map();

    /** @type {AllocationRequest[]} */
    this.pendingRequests = [];

    this.totalAllocations = 0;
    this.totalDeallocations = 0;
    this.totalRejections = 0;
  }

  /**
   * Registers a resource
   *
   * @param {Resource} resource - Resource to register
   * @returns {string} Resource ID
   */
  registerResource(resource) {
    if (!resource.id) {
      resource.id = this._generateId();
    }

    resource.available = resource.capacity;
    resource.allocations = new Map();

    this.resources.set(resource.id, resource);

    this.logger(`[ResourceManager] Registered resource: ${resource.name} (capacity: ${resource.capacity})`);
    this.emit('resource:registered', { resource });

    return resource.id;
  }

  /**
   * Unregisters a resource
   *
   * @param {string} resourceId - Resource ID
   * @returns {boolean} Success status
   */
  unregisterResource(resourceId) {
    const resource = this.resources.get(resourceId);

    if (!resource) {
      return false;
    }

    if (resource.allocations.size > 0) {
      this.logger(`[ResourceManager] Warning: Unregistering resource with active allocations`);
    }

    this.resources.delete(resourceId);

    this.emit('resource:unregistered', { resourceId });

    return true;
  }

  /**
   * Allocates resources to a consumer
   *
   * @param {AllocationRequest} request - Allocation request
   * @returns {Promise<boolean>} Success status
   */
  async allocate(request) {
    const resource = this.resources.get(request.resourceId);

    if (!resource) {
      throw new Error(`Resource not found: ${request.resourceId}`);
    }

    // Check if enough capacity available
    if (resource.available >= request.amount) {
      return this._performAllocation(request);
    }

    // Check if we can overcommit
    const effectiveCapacity = resource.capacity * this.overcommitRatio;

    if (resource.capacity - resource.available + request.amount <= effectiveCapacity) {
      return this._performAllocation(request);
    }

    // Need to queue request
    this.logger(`[ResourceManager] Insufficient resources, queueing request`);

    this.pendingRequests.push(request);

    // Sort by priority
    this.pendingRequests.sort((a, b) => b.priority - a.priority);

    this.emit('allocation:queued', { request });

    return false;
  }

  /**
   * Performs resource allocation
   *
   * @private
   * @param {AllocationRequest} request - Allocation request
   * @returns {boolean} Success status
   */
  _performAllocation(request) {
    const resource = this.resources.get(request.resourceId);

    if (resource.available < request.amount) {
      this.totalRejections++;
      this.emit('allocation:rejected', { request, reason: 'insufficient_capacity' });
      return false;
    }

    // Allocate
    resource.available -= request.amount;
    resource.allocations.set(request.consumerId, request.amount);

    this.totalAllocations++;

    this.logger(`[ResourceManager] Allocated ${request.amount} of ${resource.name} to ${request.consumerId}`);

    this.emit('allocation:completed', { request, resource });

    return true;
  }

  /**
   * Deallocates resources from a consumer
   *
   * @param {string} consumerId - Consumer ID
   * @param {string} resourceId - Resource ID
   * @returns {boolean} Success status
   */
  deallocate(consumerId, resourceId) {
    const resource = this.resources.get(resourceId);

    if (!resource) {
      return false;
    }

    const amount = resource.allocations.get(consumerId);

    if (!amount) {
      return false;
    }

    // Deallocate
    resource.available += amount;
    resource.allocations.delete(consumerId);

    this.totalDeallocations++;

    this.logger(`[ResourceManager] Deallocated ${amount} of ${resource.name} from ${consumerId}`);

    this.emit('deallocation:completed', { consumerId, resourceId, amount });

    // Process pending requests
    this._processPendingRequests(resourceId);

    return true;
  }

  /**
   * Processes pending allocation requests
   *
   * @private
   * @param {string} resourceId - Resource ID
   */
  _processPendingRequests(resourceId) {
    const pendingForResource = this.pendingRequests.filter(r =>
      r.resourceId === resourceId
    );

    for (const request of pendingForResource) {
      if (this._performAllocation(request)) {
        // Remove from pending
        const index = this.pendingRequests.indexOf(request);
        if (index > -1) {
          this.pendingRequests.splice(index, 1);
        }
      }
    }
  }

  /**
   * Gets resource by ID
   *
   * @param {string} resourceId - Resource ID
   * @returns {Resource|null} Resource
   */
  getResource(resourceId) {
    return this.resources.get(resourceId) || null;
  }

  /**
   * Gets resources by type
   *
   * @param {string} type - Resource type
   * @returns {Resource[]} Resources
   */
  getResourcesByType(type) {
    return Array.from(this.resources.values())
      .filter(r => r.type === type);
  }

  /**
   * Gets resource utilization
   *
   * @param {string} resourceId - Resource ID
   * @returns {number} Utilization percentage (0-100)
   */
  getUtilization(resourceId) {
    const resource = this.resources.get(resourceId);

    if (!resource) {
      return 0;
    }

    return ((resource.capacity - resource.available) / resource.capacity) * 100;
  }

  /**
   * Rebalances resource allocations
   *
   * @param {string} resourceId - Resource ID
   */
  async rebalance(resourceId) {
    const resource = this.resources.get(resourceId);

    if (!resource) {
      return;
    }

    this.logger(`[ResourceManager] Rebalancing resource: ${resource.name}`);

    if (this.allocationStrategy === 'fair') {
      await this._rebalanceFair(resource);
    } else if (this.allocationStrategy === 'priority') {
      await this._rebalancePriority(resource);
    }

    this.emit('resource:rebalanced', { resourceId });
  }

  /**
   * Rebalances with fair allocation strategy
   *
   * @private
   * @param {Resource} resource - Resource
   */
  async _rebalanceFair(resource) {
    const consumers = Array.from(resource.allocations.keys());

    if (consumers.length === 0) {
      return;
    }

    const fairShare = Math.floor(resource.capacity / consumers.length);

    for (const consumerId of consumers) {
      const current = resource.allocations.get(consumerId);

      if (current > fairShare) {
        const excess = current - fairShare;
        resource.available += excess;
        resource.allocations.set(consumerId, fairShare);

        this.emit('allocation:adjusted', {
          consumerId,
          resourceId: resource.id,
          from: current,
          to: fairShare
        });
      }
    }
  }

  /**
   * Rebalances with priority allocation strategy
   *
   * @private
   * @param {Resource} resource - Resource
   */
  async _rebalancePriority(resource) {
    // Implementation would prioritize based on consumer priority
    // Simplified for this example
  }

  /**
   * Gets resource manager statistics
   *
   * @returns {Object} Statistics
   */
  getStats() {
    const resources = Array.from(this.resources.values());

    const totalCapacity = resources.reduce((sum, r) => sum + r.capacity, 0);
    const totalAvailable = resources.reduce((sum, r) => sum + r.available, 0);
    const totalAllocated = totalCapacity - totalAvailable;

    const utilizationRate = totalCapacity > 0
      ? (totalAllocated / totalCapacity) * 100
      : 0;

    return {
      totalResources: resources.length,
      totalCapacity,
      totalAllocated,
      totalAvailable,
      utilizationRate: utilizationRate.toFixed(2) + '%',
      pendingRequests: this.pendingRequests.length,
      totalAllocations: this.totalAllocations,
      totalDeallocations: this.totalDeallocations,
      totalRejections: this.totalRejections
    };
  }

  /**
   * Gets capacity planning recommendations
   *
   * @returns {Object} Recommendations
   */
  getCapacityRecommendations() {
    const resources = Array.from(this.resources.values());
    const recommendations = [];

    for (const resource of resources) {
      const utilization = this.getUtilization(resource.id);

      if (utilization > 90) {
        recommendations.push({
          resourceId: resource.id,
          recommendation: 'increase_capacity',
          reason: `High utilization: ${utilization.toFixed(2)}%`,
          suggestedIncrease: Math.ceil(resource.capacity * 0.5)
        });
      } else if (utilization < 20) {
        recommendations.push({
          resourceId: resource.id,
          recommendation: 'decrease_capacity',
          reason: `Low utilization: ${utilization.toFixed(2)}%`,
          suggestedDecrease: Math.ceil(resource.capacity * 0.3)
        });
      }
    }

    return recommendations;
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

export default ResourceManager;
