# Web Content Sync

Synchronize Notion databases to web cache layer with incremental updates for optimal performance.

## Purpose

Establish real-time synchronization pipeline between Notion Innovation Nexus and public web cache (Redis/Azure Cache), ensuring portfolio showcases reflect latest approved content within 30 seconds.

## Core Capabilities

- Sync Notion → Web cache layer (Azure Cache for Redis)
- Incremental updates via Notion webhooks
- Generate static JSON for CDN distribution
- Maintain data consistency across updates
- Handle webhook retry logic with exponential backoff
- Graceful degradation (fallback to direct Notion API if cache unavailable)

## Integration Points

**Notion Databases**:
- Example Builds (monitors: PublishToWeb changes)
- Knowledge Vault (monitors: Visibility = "Public" changes)

**Azure Services**:
- Azure Cache for Redis (cache layer)
- Azure Front Door CDN (static JSON distribution)
- Azure Function (webhook handler)

**Web Flow MCP Tools**:
- `web-flow__cache-refresh`
- `web-flow__get-cache-status`

## Sync Architecture

```
Notion Update (PublishToWeb = true)
  ↓
Notion Webhook → Azure Function (NotionWebhook)
  ↓
Invalidate Redis cache key (build:{id})
  ↓
Next request → Cache miss → Fetch from Notion MCP → Update cache
  ↓
Generate static JSON → Upload to CDN (optional)
```

## Cache Strategy

**Cache Keys**:
- `builds:list` - All published builds (TTL: 5 minutes)
- `build:{id}` - Individual build showcase (TTL: 1 hour)
- `knowledge:list` - All public articles (TTL: 10 minutes)
- `knowledge:{id}` - Individual article (TTL: 1 hour)
- `portfolio:stats` - Build count, tech stack summary (TTL: 1 hour)

**Invalidation Triggers**:
- Build marked `PublishToWeb = true` → Invalidate `builds:list` + `build:{id}`
- Build unmarked → Invalidate both + remove from CDN
- Knowledge visibility changed → Invalidate `knowledge:list` + `knowledge:{id}`

## Use Cases

1. Real-time portfolio updates (build published → visible within 30s)
2. Performance optimization (cache hit ratio >95%)
3. Cost reduction (minimize Notion API calls)
4. Offline resilience (serve stale cache if Notion unavailable)
5. Global distribution (CDN for low-latency worldwide access)

## Invocation

**Proactive**: Triggered by Notion webhook events
**On-Demand**: `/web:sync-cache [database]` or `/web:invalidate-cache [key]`

## Tools

Notion MCP, Bash (Azure CLI), Azure MCP, Read, Write

## Performance Targets

- Cache invalidation: <5 seconds after Notion update
- Cache hit ratio: >95%
- API response time: <50ms (cached), <2s (uncached)
- Webhook processing: <500ms

---

**Documentation**: [GitHub](https://github.com/brookside-bi/innovation-nexus/blob/main/.claude/agents/web-content-sync.md)
