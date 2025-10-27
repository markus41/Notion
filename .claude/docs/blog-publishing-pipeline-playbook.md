# Blog Publishing Pipeline - Operational Playbook

**Version**: 1.0.0
**Status**: Production-Ready
**Last Updated**: 2025-10-27
**Owner**: Content Team + Engineering

---

## Executive Summary

Establish automated blog publishing infrastructure to streamline content delivery from Notion Knowledge Vault to Webflow Editorial Collection with multi-agent quality gates, brand compliance validation, and performance optimization.

**Best for**: Organizations requiring centralized content management with distributed publishing across web properties, maintaining strict brand consistency while enabling high-velocity content production.

---

## System Architecture

### Core Components

```mermaid
flowchart TD
    A[Knowledge Vault Entry] -->|PublishToWeb = true| B[Content Validation]
    B --> C{Required Fields?}
    C -->|Missing| D[Block Publication]
    C -->|Complete| E[Multi-Agent Quality Gates]

    E --> F[@blog-tone-guardian<br/>Brand Voice: 91/100]
    E --> G[@financial-compliance-analyst<br/>Legal: Approved]
    E --> H[Technical Accuracy<br/>Verified]

    F --> I{Score >= 80?}
    G --> I
    H --> I

    I -->|Failed| J[Return to Author]
    I -->|Approved| K[Content Transformation]

    K --> L[@notion-content-parser<br/>Markdown → HTML]
    K --> M[@asset-migration-handler<br/>Image Optimization]

    L --> N[Field Mapping]
    M --> N

    N --> O[@webflow-api-specialist<br/>Publish to CMS]

    O --> P[@web-content-sync<br/>Cache Invalidation]

    P --> Q[Verification]
    Q --> R{Published Successfully?}

    R -->|Yes| S[✅ Live on Webflow]
    R -->|No| T[❌ Retry/Escalate]

    S --> U[Update Notion<br/>PublishStatus = Published<br/>WebflowURL = URL]

    style E fill:#f9f,stroke:#333
    style I fill:#ff9,stroke:#333
    style S fill:#9f9,stroke:#333
```

---

## Agent Coordination Matrix

| Phase | Agent | Responsibilities | Duration | Success Criteria |
|-------|-------|-----------------|----------|------------------|
| **1. Validation** | @notion-mcp-specialist | Verify required fields, check approval status | 1-2 min | All fields populated, no conflicts |
| **2. Quality Gates** | @content-quality-orchestrator | Coordinate parallel reviews | 3-5 min | All gates approved |
| **2a. Brand** | @blog-tone-guardian | Score brand voice compliance (0-100) | 2 min | Score >= 80 |
| **2b. Legal** | @financial-compliance-analyst | Regulatory review, disclaimers | 2 min | No violations detected |
| **2c. Technical** | Domain expert | Verify technical claims, code accuracy | 2 min | No factual errors |
| **3. Transform** | @notion-content-parser | Markdown → HTML conversion | 1-2 min | Valid HTML, structure preserved |
| **3a. Assets** | @asset-migration-handler | Image optimization, CDN upload | 1-2 min | Images optimized, URLs rewritten |
| **4. Mapping** | @notion-webflow-syncer | Field mapping, category resolution | 1 min | All fields mapped, categories valid |
| **5. Publish** | @webflow-api-specialist | Create/update CMS item | 1-2 min | Item published, URL returned |
| **6. Cache** | @web-content-sync | Invalidate Redis + CDN | 30-60 sec | Cache purged, hit ratio >95% |
| **7. Verify** | Automated checks | URL accessibility, SEO, performance | 30 sec | Load time <2s, SEO valid |

**Total Duration**: 7-15 minutes (single post) | 30-45 minutes (batch of 5)

---

## Quality Gate Framework

### Brand Voice Compliance (@blog-tone-guardian)

**Scoring Rubric** (0-100 scale):

1. **Professional Tone** (20 points)
   - 18-20: Consistently professional, appropriate formality
   - 15-17: Mostly professional, minor casual phrases
   - 0-14: Needs revision

2. **Solution-Focus** (20 points)
   - 18-20: Every section ties to business outcomes
   - 15-17: Mostly outcome-focused
   - 0-14: Feature-heavy, needs reframing

3. **Consultative Positioning** (20 points)
   - 18-20: Partnership language, sustainability emphasis
   - 15-17: Mostly consultative
   - 0-14: Transactional, not consultative

4. **Language Pattern Usage** (20 points)
   - 18-20: Uses 4+ core Brookside patterns, no prohibited phrases
   - 15-17: Uses 2-3 core patterns
   - 0-14: No patterns, prohibited phrases present

5. **Audience Alignment** (20 points)
   - 18-20: Perfect alignment for target audience
   - 15-17: Mostly appropriate
   - 0-14: Wrong audience level

**Approval Thresholds**:
- **90-100**: Excellent - Publish with minor polish
- **80-89**: Good - Publish after recommended edits
- **70-79**: Needs Work - Significant revisions required
- **0-69**: Reject - Major rewrite needed

**Core Brookside Patterns** (MUST USE):
- ✅ "Establish structure and rules for..."
- ✅ "This solution is designed to..."
- ✅ "Organizations scaling [technology] across..."
- ✅ "Streamline workflows and improve visibility"
- ✅ "Drive measurable outcomes through structured approaches"
- ✅ "Best for: [clear use case context]"

**Prohibited Patterns** (NEVER USE):
- ❌ Overhype: "revolutionary," "game-changing," "disrupting"
- ❌ Casual: "gonna," "wanna," "tons of," "super easy"
- ❌ Vague: "makes things better," "improves performance"
- ❌ Financial hype: "to the moon," "can't lose," "guaranteed returns"

---

### Legal/Compliance Review (@financial-compliance-analyst)

**Triggers**:
- Content contains financial analysis, investment advice, or market commentary
- Mentions specific stocks, funds, or investment strategies
- Discusses regulatory topics (GDPR, SOC 2, HIPAA, etc.)

**Checklist**:
- ✅ Investment disclaimers present (if applicable)
- ✅ Risk disclosures included
- ✅ No guarantees or predictions of returns
- ✅ Data attribution and timestamps
- ✅ Conflict of interest disclosures
- ✅ Regulatory compliance (SEC, FINRA for financial content)

**Approval**:
- ✅ **Approved**: All requirements met, no violations
- ⚠️ **Conditional**: Minor additions needed (add disclaimers)
- ❌ **Rejected**: Critical violations, cannot publish without major changes

**Required Disclaimer Template** (Financial Content):
```
**Disclaimer**: This analysis is for informational purposes only and does not
constitute investment advice. Past performance does not guarantee future results.
Consult a qualified financial advisor before making investment decisions.

**Data Sources**: [Source] (retrieved [Date]), company filings, industry reports
```

---

### Technical Accuracy Validation

**Review Areas**:
- **Code Examples**: Syntax correct, runs without errors, follows best practices
- **Technical Claims**: Verifiable metrics, accurate performance numbers
- **Architecture Diagrams**: Logically sound, reflects current practices
- **API Documentation**: Accurate endpoints, correct parameter types
- **Tool Versions**: Current, not deprecated or EOL

**Verification Methods**:
- Code execution (if applicable)
- Cross-reference with official documentation
- Peer review by domain expert
- Automated linting/validation tools

**Approval**:
- ✅ **Verified**: All technical content accurate
- ⚠️ **Needs Correction**: Minor errors identified, specific fixes provided
- ❌ **Rejected**: Major inaccuracies, requires subject matter expert rewrite

---

## Automated Workflows

### Daily Batch Processing

**Schedule**: 2:00 AM daily (skips weekends)

**Configuration**:
```powershell
# Windows Task Scheduler
$trigger = New-ScheduledTaskTrigger -Daily -At 2:00AM
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-File C:\Users\MarkusAhling\Notion\.claude\utils\Daily-Blog-Batch-Processor.ps1"
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -RunOnlyIfNetworkAvailable

Register-ScheduledTask -TaskName "Blog-Daily-Batch-Publisher" `
    -Trigger $trigger -Action $action -Settings $settings `
    -Description "Automated blog publishing from Knowledge Vault to Webflow"
```

**Batch Processing Logic**:
1. Query Knowledge Vault for unpublished entries
   - Filter: `Status = Published` (in Knowledge Vault) AND `WebflowStatus != Published`
   - Filter: `ContentType = Technical Doc` OR `Case Study`
   - Filter: Body word count >= 800
   - Limit: 5 entries
2. Process each entry through full quality pipeline
3. Publish approved entries to Webflow
4. Log results, send notification if failures exceed threshold

**Success Criteria**:
- **Target**: Publish 5 blog posts daily
- **Acceptable Failure Rate**: <20% (1 of 5 may fail quality gates)
- **Notification Triggers**: >2 failures, API errors, cache invalidation issues

---

### Manual Single-Post Publishing

**Use Case**: Urgent content, high-priority announcements, manually triggered

**Command**:
```powershell
.\Blog-Publishing-Pipeline.ps1 -Mode single -NotionPageId "abc123..."
```

**Workflow**:
1. Fetch specific Notion page
2. Run full quality validation (same as batch)
3. Publish immediately if approved
4. Return public URL and status

**Duration**: 7-10 minutes (single post)

---

### Dry Run Mode (Preview)

**Use Case**: Test pipeline without publishing, preview transformations

**Command**:
```powershell
.\Blog-Publishing-Pipeline.ps1 -Mode batch -DryRun
```

**Behavior**:
- Executes all steps except Webflow API calls
- Shows what would be published (title, slug, category, SEO)
- Validates quality gates
- Reports success/failure without making changes

**Best for**: Testing pipeline changes, previewing batch before publishing

---

## Field Mapping Specifications

### Knowledge Vault → Webflow Editorial

| Notion Property | Webflow Field | Transformation | Required |
|----------------|---------------|----------------|----------|
| Article Title | name (Title) | Direct copy | ✅ |
| Summary | post-summary (Plain Text) | Direct copy | ✅ |
| Category | category (Reference) | Map Notion relation → Webflow ref ID | ✅ |
| Body (Markdown) | post-body (Rich Text) | Markdown → HTML conversion | ✅ |
| Published Date | published-date (Date) | ISO 8601 format | ✅ |
| Featured Image | hero-image (Image) | Upload to Webflow CDN, use URL | ✅ |
| Tags | tags (Multi-Select) | Direct copy array | Optional |
| Author | author (Plain Text) | Default: "Brookside BI Team" | Auto |
| Meta Title | seo-title (Plain Text) | Auto-generate (60 chars max) | Auto |
| Meta Description | seo-description (Plain Text) | Auto-generate (155 chars max) | Auto |
| Slug | slug (Plain Text) | Auto-generate from title (kebab-case) | Auto |
| Read Time | read-time-minutes (Number) | Calculate: (word_count / 200) + (code_blocks * 0.5) | Auto |

**Auto-Generated Fields**:

```javascript
// SEO Title
seoTitle = notionTitle.length <= 60
    ? notionTitle
    : notionTitle.substring(0, 60).trim()

// SEO Description
seoDescription = notionSummary.length <= 155
    ? notionSummary
    : notionSummary.substring(0, 155).trim()

// Slug
slug = notionTitle
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')

// Read Time
readTime = Math.ceil((wordCount / 200) + (codeBlockCount * 0.5))
```

---

## Error Handling Protocols

### Scenario 1: Validation Failure

**Error**: Required fields missing (title, category, body, hero image)

**Recovery**:
1. Identify missing fields
2. Update Notion: `PublishStatus = "Blocked"`, `BlockReason = "Missing: [fields]"`
3. Do NOT proceed to quality review
4. Notify user with specific action required

**Example**:
```
❌ PUBLISHING BLOCKED

Page: "Azure Functions Cost Tracking"
Issue: Missing required fields

Missing:
  - Category (multi-select): Not set
  - Featured Image: Missing
  - Meta Description: Empty

Action: Populate missing fields in Notion, then retry publishing
```

---

### Scenario 2: Quality Gate Rejection

**Error**: Brand score <80, legal rejected, or technical errors

**Recovery Path A - Needs Revision** (score 70-79):
1. Create Notion comment with specific edits required
2. Update `PublishStatus = "Needs Revision"`
3. Return to author for fixes
4. Allow retry after edits (max 2 revision cycles)

**Recovery Path B - Rejected** (score <70):
1. Block publishing completely
2. Escalate to human reviewer
3. Update `PublishStatus = "Rejected"`
4. Provide detailed rejection rationale

**Retry Logic**: Max 2 revision cycles before human escalation

---

### Scenario 3: Webflow API Failure

**Error Types**:
- 401: Authentication error
- 429: Rate limit exceeded
- 500: Server error

**Recovery**:

**401 Authentication**:
1. Verify Webflow API token (Azure Key Vault)
2. If expired → Refresh OAuth token
3. Retry publish (1x)

**429 Rate Limit**:
1. Exponential backoff (2s, 4s, 8s)
2. Retry up to 3x
3. If still rate-limited → Queue for later (delay 5 min)

**500 Server Error**:
1. Retry 2x with 3-second delay
2. If persistent → Create draft item (not published) + escalate

**Rollback**:
- Set `PublishStatus = "Failed"`, `ErrorDetails = [message]`
- Do NOT invalidate cache (content not live)
- Preserve Notion state for retry

---

### Scenario 4: Cache Invalidation Failure

**Error**: Redis unavailable or CDN purge fails

**Recovery**:

**Redis Unavailable**:
1. Proceed with publish (content live on Webflow)
2. Log cache invalidation failure
3. Set `CacheStatus = "Stale"` in Notion
4. Alert monitoring (cache hit ratio will drop)
5. Manual invalidation required

**CDN Purge Failure**:
1. Retry CDN purge (2x)
2. If still failing → Log warning (content refreshes via TTL)
3. Proceed with publishing (not a blocker)

**Impact**: Temporary stale content (<5 min), resolved automatically via TTL

---

## Performance Monitoring

### Key Metrics Dashboard

**Publishing Metrics**:
- **Publish Latency**: <30 seconds (approval → live)
- **Batch Throughput**: 20 items/minute
- **Success Rate**: >99% with auto-retry
- **Error Recovery**: <15% require human intervention

**Quality Metrics**:
- **First-time Approval**: >85%
- **Brand Compliance Avg**: >90
- **SEO Metadata Complete**: >95%

**Performance Metrics**:
- **Page Load Time**: <2 seconds (95th percentile)
- **Cache Hit Ratio**: >95% (post-invalidation stabilization)
- **CDN Availability**: >99.9%

**Monitoring Tools**:
- Azure Application Insights (API latency, error rates)
- Azure Monitor (cache hit ratio, CDN performance)
- Webflow Analytics (page views, engagement)
- Custom PowerShell logging (pipeline execution metrics)

---

## Security & Compliance

### API Key Management

**Storage**: Azure Key Vault (kv-brookside-secrets)

**Keys Required**:
- `notion-api-key` - Notion integration token
- `webflow-api-key` - Webflow API token
- `openai-api-key` - OpenAI DALL-E for image generation (Phase 2)

**Retrieval**:
```powershell
.\scripts\Get-KeyVaultSecret.ps1 -SecretName "webflow-api-key"
```

**Never**:
- ❌ Hardcode API keys in code
- ❌ Commit keys to git
- ❌ Log keys in error messages
- ❌ Share keys in Notion pages

---

### Data Privacy

**Notion Content**:
- Blog posts considered public content (intended for publication)
- No PII or confidential business data in blog posts
- Review Status workflow ensures human review before public exposure

**Image Handling**:
- Temporary download to local storage during sync
- Deleted after Webflow upload completes
- No persistent caching of Notion images

---

## Troubleshooting Guide

### Common Issues

**Issue**: "Category 'X' not found in Webflow"
**Solution**: Add missing category to Webflow Blog-Categories collection, refresh category cache

**Issue**: "Pixel art validation failed: Anti-aliasing detected"
**Solution**: Re-export image from design tool with nearest-neighbor scaling (no anti-aliasing)

**Issue**: "Webflow API rate limit exceeded"
**Solution**: Reduce batch size (`-MaxItems 3`) or wait 1 minute before retrying

**Issue**: "Image upload timeout"
**Solution**: Compress image to <5MB, verify internet connection stable

**Issue**: "Brand score below threshold (75/100)"
**Solution**: Review @blog-tone-guardian recommendations, apply suggested edits, retry

---

## Phase 2 Roadmap (Future Enhancements)

### AI-Generated Cover Images

**Agent**: `@pixel-art-generator`
**Capability**: Auto-generate 8-bit pixel art hero images if missing
**Integration**: Add to asset migration workflow as fallback

**Prompt Generation**:
```javascript
prompt = `
  Create 8-bit pixel art office scene in 1990s management sim style.
  Isometric perspective cubicle farm with ${characterCount} characters.

  Topic: ${postTitle}
  Emotion: ${mapComplexityToEmotion(expertiseLevel)}
  Technical Prop: ${extractTechnicalProp(postSummary)}

  Color Palette: Teal background, tan characters, brown furniture
  Style: Corporate exhaustion, no smiling, pixel-perfect hard edges
`
```

---

### Financial Content Integration

**Agents**:
- `@morningstar-data-analyst` - Fetch real-time stock/fund data
- `@financial-equity-analyst` - Generate investment analysis
- `@financial-market-researcher` - Market context and trends

**Use Case**: Blog posts analyzing stocks, funds, market trends with live data

---

### Analytics Integration

**Goal**: Measure blog performance and optimize content strategy

**Metrics**:
- Page views per post
- Average time on page
- Bounce rate
- Social shares
- Conversion rate (newsletter signups, demo requests)

**Tools**:
- Google Analytics 4
- Webflow Analytics
- Azure Application Insights (backend performance)

---

## Getting Help

**Documentation Issues**: Review this playbook, check agent specifications in `.claude/agents/`
**Pipeline Errors**: Check logs at `.claude/logs/blog-publishing/`
**Quality Questions**: Review brand guidelines in `CLAUDE.md`
**Technical Issues**: Escalate to engineering team

**Contact**: Consultations@BrooksideBI.com | +1 209 487 2047

---

## Change Log

**2025-10-27 - v1.0.0**:
- Initial release
- Multi-agent quality gate architecture
- Automated daily batch processing
- Comprehensive error handling
- Performance monitoring framework

---

**Brookside BI Innovation Nexus - Where Knowledge Becomes Content, and Content Drives Outcomes - Validated by AI, Approved by Humans.**
