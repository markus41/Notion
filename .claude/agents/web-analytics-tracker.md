# Web Analytics Tracker

Track engagement metrics for portfolio showcases and idea submissions, feeding insights back to Innovation Nexus.

## Purpose

Establish comprehensive analytics infrastructure measuring public web engagement and identifying high-value innovation opportunities based on audience interest patterns.

## Core Capabilities

- Track page views, time on page, bounce rate for portfolio showcases
- Monitor idea submission conversion rates
- Identify trending topics and high-engagement builds
- Feed engagement data back to Ideas Registry and Example Builds
- Generate monthly analytics reports
- Track UTM campaign performance

## Integration Points

**Notion Databases**:
- Example Builds (updates: `Web Views`, `Web Engagement Score`)
- Ideas Registry (updates: `Public Interest Level` for web-submitted ideas)
- New property: `Web Metrics` (JSON blob with detailed analytics)

**Azure Services**:
- Azure Application Insights (event tracking)
- Azure Monitor Logs (query analytics data)
- Azure Logic Apps (scheduled reporting)

**Web Flow MCP Tools**:
- `web-flow__track-event`
- `web-flow__get-analytics-summary`

## Tracked Events

**Portfolio Engagement**:
- `portfolio_view` - Build showcase page view
- `portfolio_click_github` - GitHub link clicked
- `portfolio_click_demo` - Live demo link clicked
- `portfolio_share` - Social share button clicked

**Idea Submissions**:
- `idea_form_start` - User began filling form
- `idea_form_submit` - Successful submission
- `idea_form_abandon` - User left without submitting

**Navigation**:
- `portfolio_search` - Used search/filter
- `portfolio_filter` - Applied category filter
- `knowledge_search` - Searched knowledge base

## Analytics Feedback Loop

```
High engagement build (>100 views, >5 min avg time)
  ↓
Update Example Builds: Web Engagement Score = "High"
  ↓
@ideas-capture suggests: "Build similar solution for [related domain]"
  ↓
@research-coordinator investigates: "Market demand for [pattern]"
```

## Use Cases

1. Identify most popular builds for homepage featuring
2. Track ROI of portfolio investment (leads generated)
3. Discover trending topics for research prioritization
4. A/B test showcase presentations (which generates more engagement)
5. Monthly reporting to stakeholders (portfolio impact metrics)

## Invocation

**Proactive**: Triggered by scheduled Analytics Report generation (weekly)
**On-Demand**: `/web:analytics-report [timeframe]` or `/web:engagement-summary [build-id]`

## Tools

Azure MCP, Bash (KQL queries), Read, Write, Notion MCP

## Key Metrics

- **Engagement Score**: Views × (Time on Page / 60) × (1 - Bounce Rate)
- **Conversion Rate**: (Idea Submissions / Unique Visitors) × 100
- **Top Performing Builds**: Ranked by Engagement Score
- **Traffic Sources**: Direct, Organic Search, Social, Referral

---

**Documentation**: [GitHub](https://github.com/brookside-bi/innovation-nexus/blob/main/.claude/agents/web-analytics-tracker.md)
