# ADR-010: Context Manager Design

## Status

**Accepted** - December 2024

## Context

In the Claude Code Orchestration system, multiple agents work on related tasks within a single command execution. These agents often need similar information:

### The Problem

1. **Redundant Work**: Agents repeatedly gather the same information (file contents, analysis results, configurations)
2. **Inconsistent State**: Different agents might see different versions of the same data
3. **Performance Impact**: Repeated expensive operations (file I/O, API calls, computations)
4. **Memory Waste**: Same data stored multiple times in different agent contexts
5. **No Knowledge Sharing**: Agents can't benefit from work done by previous agents

### Real-World Example

```typescript
// Without context sharing - redundant work
Agent1: Read package.json, analyze dependencies  // 2s
Agent2: Read package.json again, check versions  // 2s
Agent3: Read package.json again, update deps     // 2s
Total: 6s of redundant I/O

// With context manager - shared context
Agent1: Read package.json, cache result          // 2s
Agent2: Use cached package.json                  // 0.1s
Agent3: Use cached package.json                  // 0.1s
Total: 2.2s with caching
```

### Requirements

- Eliminate redundant operations across agents
- Ensure data consistency within a command execution
- Support different data types (files, analysis results, API responses)
- Provide efficient lookups with O(1) average complexity
- Handle memory constraints gracefully
- Support persistence for recovery scenarios

### Constraints

- Cannot exceed memory limits (100MB default)
- Must maintain data freshness (TTL support)
- Must handle concurrent access safely
- Cannot introduce significant latency (<10ms overhead)
- Must support both structured and unstructured data

## Decision

We will implement a **hybrid Context Manager** with intelligent caching, deduplication, and configurable eviction policies.

### Core Design

```typescript
interface ContextManager {
  // Core operations
  get(key: string): Promise<any>
  set(key: string, value: any, options?: CacheOptions): void

  // Deduplication
  deduplicate(value: any): string  // Returns hash

  // Memory management
  evict(policy: EvictionPolicy): void
  getSize(): number

  // Persistence
  persist(): Promise<void>
  restore(): Promise<void>
}

interface CacheOptions {
  ttl?: number           // Time-to-live in ms
  priority?: number      // Cache priority (0-10)
  immutable?: boolean    // Value won't change
  compress?: boolean     // Compress large values
}
```

### Architecture Components

1. **Immutable Context Objects**
   ```typescript
   class Context {
     readonly version: number
     readonly timestamp: Date
     private readonly data: Map<string, CacheEntry>

     // Copy-on-write for modifications
     set(key: string, value: any): Context {
       return new Context(this.version + 1, new Map(this.data).set(key, value))
     }
   }
   ```

2. **Hash-Based Deduplication**
   ```typescript
   // Content-addressable storage
   const hash = crypto.createHash('sha256')
     .update(JSON.stringify(value))
     .digest('hex')

   if (deduplicationMap.has(hash)) {
     return deduplicationMap.get(hash)  // Return reference
   }
   ```

3. **Multi-Level Cache Strategy**
   - **L1 Cache**: Hot data in memory (LRU)
   - **L2 Cache**: Warm data compressed in memory
   - **L3 Cache**: Cold data on disk (optional)

4. **Eviction Policies**
   - **LRU (Least Recently Used)**: Default for general data
   - **LFU (Least Frequently Used)**: For access pattern optimization
   - **TTL (Time-To-Live)**: For time-sensitive data
   - **Priority-Based**: Manual priority assignment
   - **Size-Based**: Evict largest items first

5. **Memory Management**
   ```typescript
   class MemoryManager {
     private maxSize = 100 * 1024 * 1024  // 100MB
     private currentSize = 0

     canAllocate(size: number): boolean {
       return this.currentSize + size <= this.maxSize
     }

     enforceLimit(): void {
       while (this.currentSize > this.maxSize * 0.9) {  // 90% threshold
         this.evictNext()
       }
     }
   }
   ```

## Alternatives Considered

### 1. No Caching (Simple Pass-Through)

**Pros:**
- Zero memory overhead
- No cache invalidation issues
- Simplest implementation

**Cons:**
- Massive redundant work
- Poor performance
- No benefit from previous computations

**Why Rejected:** Unacceptable performance for complex commands with multiple agents

### 2. Database-Backed Cache (Redis/SQLite)

**Pros:**
- Unlimited storage capacity
- Built-in persistence
- Distributed cache possibility
- Professional cache features

**Cons:**
- External dependency
- Network/disk I/O latency
- Complex setup and maintenance
- Overkill for command execution

**Why Rejected:** Adds unnecessary complexity and latency for our embedded use case

### 3. In-Memory Only Cache

**Pros:**
- Fast access (nanoseconds)
- Simple implementation
- No disk I/O

**Cons:**
- Limited by available memory
- Lost on process restart
- No persistence for recovery

**Why Rejected:** Insufficient for large contexts and doesn't support recovery scenarios

### 4. File-System Based Cache

**Pros:**
- Large capacity
- Natural persistence
- Simple implementation

**Cons:**
- Slow access (milliseconds)
- File system limitations
- Cleanup complexity

**Why Rejected:** Too slow for frequent access patterns during execution

## Consequences

### Positive Consequences

1. **Performance Gains**
   - 80-100% cache hit rate for common operations
   - 10-100x speedup for cached operations
   - Reduced API calls and I/O operations

2. **Resource Efficiency**
   - Deduplication saves 30-50% memory
   - Compression reduces large object footprint by 60-80%
   - Optimal memory utilization through eviction

3. **Consistency**
   - All agents see same data version
   - Immutable contexts prevent race conditions
   - Versioning enables rollback

4. **Developer Experience**
   - Transparent caching
   - Simple get/set interface
   - Automatic memory management

5. **Observability**
   - Cache hit/miss metrics
   - Memory usage tracking
   - Performance profiling data

### Negative Consequences

1. **Memory Overhead**
   - Cache metadata (keys, timestamps, counters)
   - Deduplication map storage
   - Version history retention

2. **Complexity**
   - Cache invalidation logic
   - Eviction policy implementation
   - Persistence and recovery mechanisms

3. **Potential Issues**
   - Stale data if TTL too high
   - Memory pressure if limit too low
   - Cache stampede on cold start

### Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Memory Exhaustion** | High - OOM crash | Hard limits, aggressive eviction, monitoring |
| **Cache Invalidation** | Medium - Stale data | TTL, version tracking, explicit invalidation |
| **Cache Stampede** | Low - Performance spike | Warm-up phase, gradual loading |
| **Data Corruption** | Medium - Wrong results | Checksums, immutable objects, validation |
| **Performance Regression** | Low - Slower than expected | Metrics, profiling, bypass option |

## Validation

### Success Metrics

1. **Cache Hit Rate**: >80% for repeated operations
2. **Memory Usage**: <100MB under normal load
3. **Latency**: <10ms overhead for cache operations
4. **Deduplication**: 30%+ memory savings
5. **Recovery**: <5s to restore from checkpoint

### Validation Approach

1. **Unit Tests**
   - Cache operations (get, set, evict)
   - Deduplication algorithm
   - Eviction policies
   - Memory limits

2. **Integration Tests**
   - Multi-agent context sharing
   - Persistence and recovery
   - Memory pressure scenarios

3. **Performance Tests**
   - Benchmark cache vs. no-cache
   - Memory usage under load
   - Eviction performance

4. **Stress Tests**
   - Maximum capacity handling
   - Concurrent access patterns
   - Recovery from corruption

## Implementation Notes

### Configuration Schema

```typescript
interface ContextManagerConfig {
  maxMemoryMB: number        // Default: 100
  enablePersistence: boolean  // Default: true
  persistencePath: string     // Default: .claude/cache
  defaultTTL: number         // Default: 3600000 (1 hour)
  evictionPolicy: 'lru' | 'lfu' | 'ttl' | 'priority'
  compressionThreshold: number // Bytes, default: 1024
  deduplicationEnabled: boolean // Default: true
}
```

### Cache Entry Structure

```typescript
interface CacheEntry {
  key: string
  value: any
  hash: string           // Content hash
  size: number          // Bytes
  created: Date
  accessed: Date
  accessCount: number
  ttl?: number
  priority?: number
  compressed: boolean
}
```

### Performance Characteristics

| Operation | Time Complexity | Space Complexity |
|-----------|----------------|------------------|
| Get | O(1) average | O(1) |
| Set | O(1) average | O(n) for value |
| Evict (LRU) | O(1) | O(1) |
| Evict (Priority) | O(log n) | O(1) |
| Deduplicate | O(1) average | O(1) |
| Persist | O(n) | O(n) |

## Related Documents

- [ADR-009: DAG-Based Orchestration](./ADR-009-dag-based-orchestration.md)
- [ADR-011: TodoWrite Integration](./ADR-011-todowrite-integration.md)
- [C4 Architecture Diagrams](../architecture/orchestration-c4.md)

## Decision History

- 2024-12-01: Initial context sharing proposal
- 2024-12-03: Added deduplication requirement
- 2024-12-07: Hybrid approach selected
- 2024-12-10: Accepted with eviction policies
- 2024-12-12: Implementation started