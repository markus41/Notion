# Command Loader v2.0

Production-ready command loader for Claude Code v2.0 command definitions with validation, caching, and automatic v1.0 migration.

## Features

- **Multi-Format Loading**: Supports v2.0 JSON and v1.0 Markdown formats
- **Automatic Conversion**: Seamlessly migrates v1.0 commands to v2.0 format
- **JSON Schema Validation**: Comprehensive validation against v2.0 specification
- **Dependency Validation**: Detects circular dependencies and missing references
- **Context Validation**: Ensures context inputs have providers
- **File-Based Caching**: LRU cache with hash validation and TTL
- **Performance Optimized**: <100ms cache hits, <1s file loads
- **Clear Error Messages**: Detailed error codes with suggestions
- **TypeScript Native**: Full type safety with no dependencies

## Installation

```typescript
import { CommandLoader } from '.claude/lib/command-loader';
```

## Quick Start

```typescript
// Initialize loader
const loader = new CommandLoader({
  cacheEnabled: true,
  validateSchema: true,
  convertV1ToV2: true
});

// Load command from file (auto-detects format)
const command = await loader.load('.claude/commands/review-all.json');

// Validate
const validation = loader.validate(command.definition);
if (!validation.valid) {
  console.error('Validation errors:', validation.errors);
}

// Execute with orchestration engine
const engine = new OrchestrationEngine();
const result = await engine.execute(command.definition);
```

## API Reference

### CommandLoader

Main class for loading and validating commands.

#### Constructor

```typescript
constructor(config?: CommandLoaderConfig)
```

**Configuration Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `cacheEnabled` | boolean | `true` | Enable file-based caching |
| `validateSchema` | boolean | `true` | Validate against JSON schema |
| `convertV1ToV2` | boolean | `true` | Enable v1.0 → v2.0 conversion |
| `maxCacheSize` | number | `50` | Maximum cached commands |
| `cacheTTL` | number | `3600000` | Cache TTL in milliseconds (1 hour) |

#### Methods

##### load(source: string | CommandDefinition): Promise<LoadedCommand>

Load command from file path or programmatic definition.

**Parameters:**
- `source` - File path (`.json` or `.md`) or CommandDefinition object

**Returns:** LoadedCommand with definition and metadata

**Throws:** CommandLoadError on failure

**Example:**
```typescript
// From JSON file
const cmd1 = await loader.load('.claude/commands/review-all.json');

// From Markdown file (v1.0)
const cmd2 = await loader.load('.claude/commands/legacy.md');

// Programmatic
const cmd3 = await loader.load({
  version: '2.0.0',
  name: '/custom',
  description: 'Custom command',
  phases: [...]
});
```

##### loadJSON(path: string): Promise<LoadedCommand>

Load v2.0 JSON command from file.

**Parameters:**
- `path` - Path to `.json` file

**Returns:** LoadedCommand

**Throws:** CommandLoadError if file not found or invalid JSON

##### loadMarkdown(path: string): Promise<LoadedCommand>

Load v1.0 Markdown command and convert to v2.0.

**Parameters:**
- `path` - Path to `.md` file

**Returns:** LoadedCommand (converted to v2.0)

**Throws:** CommandLoadError if conversion fails

##### loadProgrammatic(definition: CommandDefinition): LoadedCommand

Load programmatic command definition.

**Parameters:**
- `definition` - CommandDefinition object

**Returns:** LoadedCommand

##### validate(command: CommandDefinition): SchemaValidationResult

Validate command against v2.0 specification.

**Parameters:**
- `command` - Command definition to validate

**Returns:** Validation result with errors and warnings

**Example:**
```typescript
const validation = loader.validate(command.definition);

if (!validation.valid) {
  validation.errors.forEach(error => {
    console.error(`${error.code}: ${error.message}`);
    if (error.field) {
      console.error(`  Field: ${error.field}`);
    }
  });
}

validation.warnings.forEach(warning => {
  console.warn(`${warning.message}`);
  if (warning.suggestion) {
    console.warn(`  Suggestion: ${warning.suggestion}`);
  }
});
```

##### clearCache(path?: string): void

Clear cache (all or specific path).

**Parameters:**
- `path` - Optional specific path to clear

##### getCacheStats(): CacheStats

Get cache statistics.

**Returns:** Object with `size`, `entries`, and `hitRate`

**Example:**
```typescript
const stats = loader.getCacheStats();
console.log(`Cache: ${stats.entries} entries, ${stats.hitRate.toFixed(1)}% hit rate`);
```

## Types

### LoadedCommand

```typescript
interface LoadedCommand {
  definition: CommandDefinition;
  metadata: CommandMetadata;
}
```

### CommandMetadata

```typescript
interface CommandMetadata {
  source: string;        // File path or 'programmatic'
  format: 'json' | 'markdown';
  version: string;       // Schema version
  loadedAt: number;      // Timestamp
  hash: string;          // SHA-256 hash
  fileSize: number;      // Bytes
  mtime: number;         // File modification time
}
```

### SchemaValidationResult

```typescript
interface SchemaValidationResult {
  valid: boolean;
  errors: ValidationError[];
  warnings: ValidationWarning[];
}
```

### ValidationError

```typescript
interface ValidationError {
  code: string;          // Error code (e.g., 'CIRCULAR_DEPENDENCY')
  message: string;       // Human-readable message
  field?: string;        // Field path (e.g., 'phases[0].agents[1].id')
  details?: any;         // Additional details
}
```

### ValidationWarning

```typescript
interface ValidationWarning {
  code: string;          // Warning code
  message: string;       // Human-readable message
  field?: string;        // Field path
  suggestion?: string;   // Suggested fix
}
```

### CommandLoadError

```typescript
class CommandLoadError extends Error {
  constructor(
    message: string,
    public code: string,
    public details?: any
  );
}
```

**Error Codes:**
- `FILE_NOT_FOUND` - File does not exist
- `INVALID_JSON` - JSON syntax error
- `INVALID_FORMAT` - v1.0 format error
- `CONVERSION_DISABLED` - v1.0 conversion disabled in config
- `VALIDATION_FAILED` - Validation errors present

## Validation

The loader performs comprehensive validation:

### Schema Validation

- Version must be `"2.0.0"`
- Name must start with `/` and be lowercase with hyphens
- Description required and ≤ 200 characters
- At least one phase required
- Phase IDs must be unique
- Agent IDs must be unique across entire command
- Agent must have `agentId` and `task`
- Dependencies must be an array

### Dependency Validation

- All dependencies must reference existing agent IDs
- No circular dependencies allowed
- Topological sort must succeed

### Context Validation

- Context inputs must have producers (previous agents with matching outputs)
- Output keys should not conflict
- TTL values must be positive

### Time Validation

- Timeout should be > estimatedTime (warns if not 3x)
- Estimates > 1 hour generate warnings

### Resource Validation

- No duplicate resource locks
- Lock types must be valid

## v1.0 → v2.0 Conversion

The loader automatically converts v1.0 Markdown commands to v2.0 JSON format.

### Conversion Rules

**Phase Detection:**
- Headers (`##` or `###`) create phases
- Commands without phases get default phase

**Step Parsing:**
- Numbered lists (`1. task`) become agent nodes
- Format: `1. agent-id - task description (time estimate)`
- Or: `1. task description (time estimate)` (uses `general-assistant`)

**Dependency Inference:**
- Patterns like "depends on 1", "depends on step 1", "depends on 1,2,3"
- Dependencies converted to node ID references

**Time Parsing:**
- Supports "5 min", "30 sec", "1 hour", etc.
- Default: 60 seconds if not specified

**Node ID Generation:**
- Unique IDs: `{agent-id}-{step-number}`
- Slugified: lowercase with hyphens

### Example Conversion

**v1.0 Input:**
```markdown
# /review-code

Review codebase for issues

## Analysis
1. Analyze structure (5 min)

## Review
2. Check quality (depends on 1, 10 min)
3. Check security (depends on 1, 10 min)

## Report
4. Generate report (depends on 2,3, 5 min)
```

**v2.0 Output:**
```json
{
  "version": "2.0.0",
  "name": "/review-code",
  "description": "Review codebase for issues",
  "phases": [
    {
      "id": "analysis",
      "name": "Analysis",
      "agents": [
        {
          "id": "analyze-structure-1",
          "agentId": "general-assistant",
          "task": "Analyze structure",
          "dependencies": [],
          "estimatedTime": 300000
        }
      ]
    },
    {
      "id": "review",
      "name": "Review",
      "agents": [
        {
          "id": "check-quality-2",
          "agentId": "general-assistant",
          "task": "Check quality",
          "dependencies": ["analyze-structure-1"],
          "estimatedTime": 600000
        },
        {
          "id": "check-security-3",
          "agentId": "general-assistant",
          "task": "Check security",
          "dependencies": ["analyze-structure-1"],
          "estimatedTime": 600000
        }
      ]
    },
    {
      "id": "report",
      "name": "Report",
      "agents": [
        {
          "id": "generate-report-4",
          "agentId": "general-assistant",
          "task": "Generate report",
          "dependencies": ["check-quality-2", "check-security-3"],
          "estimatedTime": 300000
        }
      ]
    }
  ]
}
```

## Caching

The loader implements intelligent file-based caching with LRU eviction.

### Cache Behavior

**Cache Key:** File path (absolute)

**Cache Hit Conditions:**
- File exists in cache
- File mtime unchanged
- Cache entry within TTL

**Cache Miss Conditions:**
- File not in cache
- File modified since cache
- Cache entry expired (TTL exceeded)

**Eviction Policy:** LRU (Least Recently Used)

**Cache Stats:**
- `entries`: Number of cached commands
- `size`: Total cache size in bytes
- `hitRate`: Percentage of cache hits

### Cache Configuration

```typescript
const loader = new CommandLoader({
  cacheEnabled: true,
  maxCacheSize: 100,      // Max 100 commands
  cacheTTL: 7200000       // 2 hour TTL
});
```

### Cache Management

```typescript
// Clear all cache
loader.clearCache();

// Clear specific entry
loader.clearCache('.claude/commands/review-all.json');

// Get statistics
const stats = loader.getCacheStats();
console.log(`Hit rate: ${stats.hitRate.toFixed(1)}%`);
```

## Performance

### Benchmarks

- **Cache Hit:** <100ms
- **JSON Load:** 500-1000ms (depends on file size)
- **Markdown Conversion:** 1000-2000ms (depends on complexity)
- **Validation:** 100-500ms (depends on command size)

### Optimization Tips

**Production Deployment:**
```typescript
const loader = new CommandLoader({
  cacheEnabled: true,
  maxCacheSize: 100,
  cacheTTL: 3600000,
  validateSchema: false  // Disable after testing
});
```

**Development:**
```typescript
const loader = new CommandLoader({
  cacheEnabled: true,
  validateSchema: true,
  convertV1ToV2: true
});
```

**Programmatic Use:**
```typescript
// Fastest - no file I/O
const loaded = loader.loadProgrammatic(definition);
```

## Error Handling

### Error Codes

| Code | Description | Recovery |
|------|-------------|----------|
| `FILE_NOT_FOUND` | File does not exist | Check file path |
| `INVALID_JSON` | JSON syntax error | Fix JSON syntax |
| `INVALID_FORMAT` | v1.0 format invalid | Check markdown structure |
| `CONVERSION_DISABLED` | v1.0 conversion off | Enable in config |
| `VALIDATION_FAILED` | Validation errors | Fix command definition |
| `INVALID_VERSION` | Version != "2.0.0" | Update version field |
| `INVALID_NAME` | Name format invalid | Use `/lowercase-name` |
| `CIRCULAR_DEPENDENCY` | Circular deps detected | Restructure dependencies |
| `MISSING_REFERENCE` | Dependency not found | Fix dependency IDs |
| `MISSING_CONTEXT_INPUT` | Context input missing | Add producer agent |

### Example Error Handling

```typescript
try {
  const command = await loader.load(path);

  const validation = loader.validate(command.definition);
  if (!validation.valid) {
    // Handle validation errors
    for (const error of validation.errors) {
      switch (error.code) {
        case 'CIRCULAR_DEPENDENCY':
          console.error('Fix circular dependency:', error.details.cycle);
          break;
        case 'MISSING_REFERENCE':
          console.error(`Add missing agent: ${error.details.missingDep}`);
          break;
        default:
          console.error(error.message);
      }
    }
  }

} catch (error) {
  if (error instanceof CommandLoadError) {
    console.error(`Load error [${error.code}]: ${error.message}`);
    console.error('Details:', error.details);
  } else {
    console.error('Unexpected error:', error);
  }
}
```

## Integration

### With Orchestration Engine

```typescript
import { CommandLoader } from '.claude/lib/command-loader';
import { OrchestrationEngine } from '.claude/lib/orchestration';

const loader = new CommandLoader();
const engine = new OrchestrationEngine();

// Load command
const command = await loader.load('.claude/commands/review-all.json');

// Validate
const validation = loader.validate(command.definition);
if (!validation.valid) {
  throw new Error('Invalid command');
}

// Execute
const result = await engine.execute(command.definition, context);
```

### With CLI

```typescript
import { CommandLoader } from '.claude/lib/command-loader';

const loader = new CommandLoader();

// Load command by name
const commandName = process.argv[2];
const commandPath = `.claude/commands/${commandName}.json`;

try {
  const command = await loader.load(commandPath);
  console.log(`Loaded: ${command.definition.name}`);

  // Execute command...
} catch (error) {
  console.error(`Failed to load ${commandName}:`, error.message);
  process.exit(1);
}
```

## Testing

Run tests:
```bash
npm test command-loader.test.ts
```

Test coverage target: **90%+**

Key test scenarios:
- Load v2.0 JSON commands
- Load v1.0 Markdown commands
- Programmatic loading
- Cache hit/miss
- Cache invalidation
- Validation (all error codes)
- Circular dependency detection
- Context validation
- v1.0 → v2.0 conversion
- Error handling

## Best Practices

1. **Enable Caching in Production**
   ```typescript
   const loader = new CommandLoader({ cacheEnabled: true });
   ```

2. **Validate During Development**
   ```typescript
   const loader = new CommandLoader({ validateSchema: true });
   ```

3. **Handle Validation Errors**
   ```typescript
   const validation = loader.validate(command.definition);
   if (!validation.valid) {
     // Log errors with field paths
     validation.errors.forEach(e => console.error(e.field, e.message));
   }
   ```

4. **Use Programmatic Loading When Possible**
   ```typescript
   // Fastest - no file I/O
   const loaded = loader.loadProgrammatic(definition);
   ```

5. **Set Appropriate Cache TTL**
   ```typescript
   // Development: short TTL for frequent changes
   const devLoader = new CommandLoader({ cacheTTL: 60000 });

   // Production: long TTL for stability
   const prodLoader = new CommandLoader({ cacheTTL: 3600000 });
   ```

6. **Monitor Cache Hit Rate**
   ```typescript
   const stats = loader.getCacheStats();
   if (stats.hitRate < 50) {
     console.warn('Low cache hit rate:', stats.hitRate);
   }
   ```

## Contributing

The Command Loader follows strict TypeScript best practices:

- **Type Safety**: No `any` types
- **Error Handling**: Custom error classes with codes
- **Documentation**: JSDoc comments on all public methods
- **Testing**: 90%+ code coverage
- **Performance**: <100ms cache hits
- **Validation**: Comprehensive schema and dependency checks

## License

MIT License - See LICENSE file for details

## See Also

- [Command Specification v2.0](../../docs/command-spec-v2.md)
- [Migration Patterns Guide](../../docs/migration-patterns.md)
- [Orchestration Engine](./orchestration/README.md)
- [ADR-008: Integration Architecture](../../docs/adr/008-integration-architecture.md)
