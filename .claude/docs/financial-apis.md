# Financial Data APIs - Integration Guide

**Purpose**: Establish access to Morningstar and Bloomberg financial data APIs to support market research, investment analysis, portfolio tracking, and competitive intelligence across Innovation Nexus agents.

**Best for**: Agents requiring real-time market data, stock/fund research, financial analytics, or business intelligence for viability assessments and strategic decision-making.

---

## Overview

### Active Financial APIs

| API | Purpose | Authentication | Cost | Status |
|-----|---------|---------------|------|--------|
| **Morningstar** | Stock/fund research, portfolio analytics, ESG ratings | API Key | ~$500-2000/month | ⏸️ Provisioning |
| **Bloomberg** | Real-time market data, news, financial analytics | Terminal credentials or BLPAPI | ~$2000-2400/month | ⏸️ Provisioning |

**Key Capabilities**:
- Real-time and historical market data
- Fundamental analysis (P/E ratios, market cap, financials)
- Investment research and fund ratings
- ESG (Environmental, Social, Governance) scoring
- News monitoring and sentiment analysis
- Portfolio performance tracking
- Competitive benchmarking

---

## Morningstar Financial Data API

### Overview

Morningstar provides comprehensive investment research and portfolio analytics data through their Direct API (enterprise) or Cloud API (developer-friendly). Designed for organizations requiring detailed fundamental analysis, fund ratings, and ESG data.

**Use Cases**:
- Software cost benchmarking against market multiples
- Investment portfolio tracking for organizational assets
- Competitive analysis using market data
- Financial viability scoring for new business ideas
- ESG compliance tracking

### Authentication

**Method**: API Key stored in Azure Key Vault

**Setup**:
```powershell
# Retrieve API key from Key Vault
.\scripts\Get-KeyVaultSecret.ps1 -SecretName "morningstar-api-key" -AsPlainText

# Set environment variable
$env:MORNINGSTAR_API_KEY = "<key-from-vault>"

# Verify (included in Set-MCPEnvironment.ps1)
.\scripts\Set-MCPEnvironment.ps1
```

**Key Vault Secret Details**:
- Secret Name: `morningstar-api-key`
- Vault: `kv-brookside-secrets`
- URI: `https://kv-brookside-secrets.vault.azure.net/`
- Rotation: Quarterly (tracked in Software & Cost Tracker)

### API Endpoints

**Base URL**: `https://api.morningstar.com/v1/` (or region-specific)

**Primary Endpoints**:
- `/equity/data` - Stock fundamentals and pricing
- `/fund/rating` - Mutual fund analysis and Morningstar ratings
- `/portfolio/performance` - Portfolio analytics
- `/esg/rating` - ESG scores and sustainability metrics
- `/screener/results` - Custom screening queries

### Key Operations

#### Query Stock Fundamentals
```typescript
// Example: Get Microsoft stock data
const stockData = await morningstarAPI.getEquityData({
  ticker: "MSFT",
  fields: [
    "price",           // Current stock price
    "pe_ratio",        // Price-to-earnings ratio
    "market_cap",      // Total market capitalization
    "52_week_high",    // Annual high
    "52_week_low",     // Annual low
    "dividend_yield",  // Dividend percentage
    "beta"             // Market volatility measure
  ],
  currency: "USD"
});

// Response structure
{
  ticker: "MSFT",
  price: 378.91,
  pe_ratio: 35.2,
  market_cap: 2814000000000,  // $2.81 trillion
  52_week_high: 384.30,
  52_week_low: 309.45,
  dividend_yield: 0.78,
  beta: 0.89,
  last_updated: "2025-10-27T16:00:00Z"
}
```

#### Fund Research and Ratings
```typescript
// Example: Analyze Vanguard S&P 500 Index Fund
const fundAnalysis = await morningstarAPI.getFundRating({
  ticker: "VFIAX",
  includeESG: true,
  includePerformance: true,
  timePeriod: "5Y"  // 5-year analysis
});

// Response structure
{
  ticker: "VFIAX",
  name: "Vanguard 500 Index Fund Admiral Shares",
  morningstar_rating: 4,  // 1-5 stars
  expense_ratio: 0.04,    // 0.04% annual fee
  category: "Large Blend",
  esg_score: 23.45,       // Lower is better for ESG
  performance_5y: 15.32,  // 5-year annualized return
  risk_rating: "Average",
  manager_tenure: 12
}
```

#### Portfolio Performance Tracking
```typescript
// Example: Track organizational investment portfolio
const portfolioMetrics = await morningstarAPI.getPortfolioPerformance({
  holdings: [
    { ticker: "MSFT", quantity: 1000 },
    { ticker: "AAPL", quantity: 500 },
    { ticker: "GOOGL", quantity: 250 }
  ],
  benchmarkIndex: "SP500",
  startDate: "2024-01-01",
  endDate: "2025-10-27"
});

// Response structure
{
  total_value: 987543.21,
  total_return: 0.2134,        // 21.34% return
  benchmark_return: 0.1845,    // S&P 500: 18.45%
  alpha: 0.0289,               // Outperformance vs benchmark
  sharpe_ratio: 1.23,
  volatility: 0.1567,
  holdings_breakdown: [...],
  sector_allocation: {
    "Technology": 0.75,
    "Consumer": 0.15,
    "Healthcare": 0.10
  }
}
```

#### ESG Ratings and Sustainability
```typescript
// Example: Evaluate ESG compliance for investment decisions
const esgData = await morningstarAPI.getESGRating({
  ticker: "MSFT",
  includeControversies: true
});

// Response structure
{
  ticker: "MSFT",
  esg_score: 21.3,             // Sustainalytics score (lower = better)
  esg_risk_category: "Low",    // Low/Medium/High/Severe
  environmental_score: 19.8,
  social_score: 22.1,
  governance_score: 22.0,
  controversies: [
    {
      category: "Business Ethics",
      severity: "Low",
      description: "Antitrust investigation (resolved)"
    }
  ],
  percentile_rank: 15          // Top 15% in sector
}
```

### Rate Limiting

**Limits**:
- Direct API: 10 requests/second, 100,000 requests/month (enterprise tier)
- Cloud API: 5 requests/second, 10,000 requests/month (standard tier)

**Best Practices**:
```typescript
// ✅ Correct - Batch requests
const tickers = ["MSFT", "AAPL", "GOOGL"];
const batchData = await morningstarAPI.getBatchEquityData({ tickers });

// ❌ Wrong - Sequential requests
for (const ticker of tickers) {
  const data = await morningstarAPI.getEquityData({ ticker });  // Rate limit risk
}
```

**Retry Strategy**:
```typescript
// Implement exponential backoff
async function queryWithRetry(request, maxRetries = 3) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await morningstarAPI.query(request);
    } catch (error) {
      if (error.status === 429 && attempt < maxRetries) {
        const delay = Math.pow(2, attempt) * 1000;  // 2s, 4s, 8s
        await sleep(delay);
        continue;
      }
      throw error;
    }
  }
}
```

---

## Bloomberg Terminal/API

### Overview

Bloomberg provides the most comprehensive financial data platform globally, with real-time market data, news, analytics, and Excel integration. Available through Bloomberg Terminal (desktop application) or Bloomberg API (BLPAPI for programmatic access).

**Use Cases**:
- Real-time cost benchmarking for Azure/software services
- Competitive intelligence and market positioning
- Industry trend analysis for viability assessment
- News monitoring for strategic opportunities
- Financial modeling and scenario planning

### Authentication

**Method**: Bloomberg Anywhere credentials or BLPAPI authentication

**Setup Option 1 - Bloomberg Terminal** (if desktop access available):
```powershell
# Launch Bloomberg Terminal
Start-Process "C:\blp\API\Bloomberg.exe"

# Authenticate via Bloomberg Anywhere
# User: <bloomberg-username>@brookside-bi
# Password: <from-key-vault>

# Terminal provides API access automatically
```

**Setup Option 2 - BLPAPI** (programmatic access):
```powershell
# Retrieve credentials from Key Vault
.\scripts\Get-KeyVaultSecret.ps1 -SecretName "bloomberg-api-username" -AsPlainText
.\scripts\Get-KeyVaultSecret.ps1 -SecretName "bloomberg-api-password" -AsPlainText

# Set environment variables
$env:BLOOMBERG_USERNAME = "<username-from-vault>"
$env:BLOOMBERG_PASSWORD = "<password-from-vault>"

# Install BLPAPI SDK (if using Python/Node.js)
pip install blpapi
# or
npm install @bloomberg/blpapi
```

**Key Vault Secret Details**:
- Secrets: `bloomberg-api-username`, `bloomberg-api-password`
- Vault: `kv-brookside-secrets`
- Rotation: Monthly (tracked in Software & Cost Tracker)
- Terminal License: Tracked separately (physical device + user license)

### API Access Patterns

**Bloomberg Terminal Functions** (using Excel add-in or desktop):
- `BDP()` - Bloomberg Data Point (single value)
- `BDH()` - Bloomberg Data History (time series)
- `BDS()` - Bloomberg Data Set (multiple fields)
- `BQL()` - Bloomberg Query Language (advanced queries)

**BLPAPI SDK** (programmatic access):
- Reference Data Service - Historical and current data
- Market Data Service - Real-time streaming
- API Fields Service - Discover available fields

### Key Operations

#### Real-Time Market Data
```typescript
// Example: Get current market data for tech stocks
const marketData = await bloombergAPI.getSecurityData({
  securities: [
    "MSFT US Equity",
    "AAPL US Equity",
    "GOOGL US Equity"
  ],
  fields: [
    "PX_LAST",          // Last price
    "VOLUME",           // Trading volume
    "EQY_BETA",         // Beta
    "PE_RATIO",         // P/E ratio
    "MARKET_CAP",       // Market cap
    "52WK_HIGH",        // 52-week high
    "52WK_LOW"          // 52-week low
  ]
});

// Response structure
{
  "MSFT US Equity": {
    PX_LAST: 378.91,
    VOLUME: 23456789,
    EQY_BETA: 0.89,
    PE_RATIO: 35.2,
    MARKET_CAP: 2814000,   // in millions
    "52WK_HIGH": 384.30,
    "52WK_LOW": 309.45
  },
  // ... other securities
}
```

#### Historical Price Data
```typescript
// Example: Analyze 1-year price trend
const priceHistory = await bloombergAPI.getHistoricalData({
  security: "MSFT US Equity",
  fields: ["PX_LAST", "PX_OPEN", "PX_HIGH", "PX_LOW"],
  startDate: "20241027",
  endDate: "20251027",
  periodicitySelection: "DAILY"
});

// Response structure
{
  security: "MSFT US Equity",
  data: [
    {
      date: "2024-10-27",
      PX_LAST: 320.45,
      PX_OPEN: 318.90,
      PX_HIGH: 322.10,
      PX_LOW: 317.80
    },
    // ... 365 days of data
  ]
}
```

#### News Monitoring
```typescript
// Example: Monitor cloud computing news
const newsResults = await bloombergAPI.getNews({
  topic: "Cloud Computing",
  companies: ["MSFT", "AMZN", "GOOGL"],
  timeRange: "24h",
  limit: 50
});

// Response structure
{
  total_results: 47,
  articles: [
    {
      headline: "Microsoft Azure Revenue Grows 29% in Q4",
      source: "Bloomberg",
      timestamp: "2025-10-27T14:32:00Z",
      sentiment: "Positive",
      companies: ["MSFT"],
      categories: ["Technology", "Earnings"],
      url: "https://bloomberg.com/news/..."
    },
    // ... more articles
  ]
}
```

#### Industry Analytics
```typescript
// Example: Analyze cloud infrastructure market
const industryData = await bloombergAPI.getIndustryAnalysis({
  industry: "Cloud Services",
  metrics: [
    "MARKET_SIZE",
    "GROWTH_RATE_5Y",
    "TOP_PLAYERS",
    "CONCENTRATION_RATIO"
  ],
  region: "Global"
});

// Response structure
{
  industry: "Cloud Services",
  market_size_usd: 545000000000,     // $545B
  growth_rate_5y: 0.21,              // 21% CAGR
  top_players: [
    { company: "AWS", market_share: 0.32 },
    { company: "Azure", market_share: 0.23 },
    { company: "Google Cloud", market_share: 0.11 }
  ],
  concentration_ratio: 0.66,         // Top 3 = 66% share
  forecast_2030_usd: 1250000000000   // $1.25T
}
```

### Rate Limiting

**Bloomberg Terminal**:
- No programmatic rate limits (desktop GUI usage)
- Excel API: ~100 requests/minute per worksheet
- Manual usage tracked via terminal session monitoring

**BLPAPI**:
- Reference Data: 50 requests/second
- Market Data: Real-time streaming (no request limit)
- Historical Data: 1000 data points per request recommended

**Best Practices**:
```typescript
// ✅ Correct - Request multiple fields in single call
const data = await bloomberg.getSecurityData({
  securities: ["MSFT US Equity"],
  fields: ["PX_LAST", "VOLUME", "PE_RATIO", "MARKET_CAP"]
});

// ❌ Wrong - Separate calls for each field
const price = await bloomberg.getSecurityData({ securities: ["MSFT"], fields: ["PX_LAST"] });
const volume = await bloomberg.getSecurityData({ securities: ["MSFT"], fields: ["VOLUME"] });
```

---

## Agent Integration Patterns

### @cost-analyst Agent

**Primary Use Cases**:
- Software cost benchmarking (compare Azure/M365 spend to market)
- Investment portfolio tracking (organizational assets)
- Cost-per-user analysis vs industry standards
- ROI calculation using market multiples

**Example Integration**:
```typescript
// Compare Azure spending to market benchmarks
async function analyzeCostEfficiency() {
  // 1. Get current Azure spend
  const azureSpend = await querySoftwareTracker({ vendor: "Microsoft Azure" });

  // 2. Get market data for cloud infrastructure costs
  const marketData = await bloombergAPI.getIndustryAnalysis({
    industry: "Cloud Infrastructure",
    metrics: ["AVG_COST_PER_USER", "BENCHMARK_SPENDING"]
  });

  // 3. Calculate efficiency score
  const efficiencyScore = azureSpend.cost_per_user / marketData.avg_cost_per_user;

  return {
    status: efficiencyScore < 1.0 ? "Below Market" : "Above Market",
    savings_opportunity: efficiencyScore > 1.2 ? "High" : "Low"
  };
}
```

### @research-coordinator Agent

**Primary Use Cases**:
- Market size validation for new ideas
- Competitive landscape analysis
- Industry trend identification
- Investment thesis development

**Example Integration**:
```typescript
// Validate market opportunity for new idea
async function validateMarketOpportunity(ideaTitle) {
  // 1. Extract industry from idea
  const industry = extractIndustry(ideaTitle);

  // 2. Query market size and growth
  const marketData = await bloombergAPI.getIndustryAnalysis({
    industry: industry,
    metrics: ["MARKET_SIZE", "GROWTH_RATE_5Y"]
  });

  // 3. Get competitive landscape
  const competitors = await morningstarAPI.getCompanyScreener({
    industry: industry,
    minMarketCap: 1000000000  // $1B+ companies
  });

  return {
    market_size: marketData.market_size_usd,
    growth_rate: marketData.growth_rate_5y,
    competition_level: competitors.length > 10 ? "High" : "Moderate",
    viability_score: calculateViabilityScore(marketData, competitors)
  };
}
```

### @viability-assessor Agent

**Primary Use Cases**:
- Financial feasibility scoring (0-100)
- Market potential quantification
- Risk assessment using market volatility
- Break-even timeline estimation

**Example Integration**:
```typescript
// Calculate financial viability score
async function calculateFinancialViability(ideaDetails) {
  // 1. Get target market data
  const marketMetrics = await morningstarAPI.getIndustryMetrics({
    sector: ideaDetails.sector
  });

  // 2. Analyze competitive positioning
  const competitorData = await bloombergAPI.getCompetitorAnalysis({
    companies: ideaDetails.competitors
  });

  // 3. Calculate viability components
  const marketSizeScore = scoreMarketSize(marketMetrics.market_size);
  const growthScore = scoreGrowth(marketMetrics.growth_rate);
  const competitionScore = scoreCompetition(competitorData);

  // 4. Weighted average (0-100 scale)
  return {
    overall_score: (marketSizeScore * 0.4) + (growthScore * 0.3) + (competitionScore * 0.3),
    breakdown: { marketSizeScore, growthScore, competitionScore }
  };
}
```

### @market-researcher Agent

**Primary Use Cases**:
- Demand validation through market data
- Pricing strategy development using comps
- Market entry timing analysis
- Addressable market calculation (TAM/SAM/SOM)

**Example Integration**:
```typescript
// Calculate Total Addressable Market (TAM)
async function calculateTAM(productDetails) {
  // 1. Get global market size
  const globalMarket = await bloombergAPI.getIndustryAnalysis({
    industry: productDetails.industry,
    region: "Global"
  });

  // 2. Get regional breakdown
  const regionalData = await morningstarAPI.getRegionalMarketData({
    industry: productDetails.industry,
    regions: ["North America", "Europe", "Asia"]
  });

  // 3. Calculate serviceable markets
  const TAM = globalMarket.market_size_usd;
  const SAM = regionalData["North America"].market_size * 0.3;  // 30% serviceable
  const SOM = SAM * 0.05;  // 5% obtainable market share

  return { TAM, SAM, SOM, confidence: "High" };
}
```

---

## Performance Optimization

### Caching Strategies

**Cache Market Data** (low volatility):
```typescript
// ✅ Correct - Cache fundamentals (update daily)
const cache = new Map();

async function getStockFundamentals(ticker) {
  const cacheKey = `fundamentals:${ticker}:${getCurrentDate()}`;

  if (cache.has(cacheKey)) {
    return cache.get(cacheKey);
  }

  const data = await morningstarAPI.getEquityData({ ticker });
  cache.set(cacheKey, data);

  return data;
}

// ❌ Wrong - Fetch fundamentals repeatedly
// These don't change intraday, wasteful to query every time
```

**Real-Time Data** (don't cache):
```typescript
// ✅ Correct - Always fetch real-time prices
async function getCurrentPrice(ticker) {
  return await bloombergAPI.getSecurityData({
    securities: [ticker],
    fields: ["PX_LAST"]
  });
}

// ❌ Wrong - Caching real-time data defeats the purpose
```

### Batch Operations

**Batch Queries** for multiple securities:
```typescript
// ✅ Correct - Single request for multiple tickers
const data = await morningstarAPI.getBatchEquityData({
  tickers: ["MSFT", "AAPL", "GOOGL", "AMZN", "META"],
  fields: ["price", "pe_ratio", "market_cap"]
});

// ❌ Wrong - Separate request per ticker
for (const ticker of tickers) {
  const data = await morningstarAPI.getEquityData({ ticker });
}
```

---

## Cost Management

### Monthly Costs

**Morningstar**:
- Direct API (Enterprise): ~$1500-2000/month
- Cloud API (Standard): ~$500-1000/month
- Included data: Equities, funds, ESG, screener
- Additional: Fixed income (+$500), alternatives (+$300)

**Bloomberg**:
- Terminal License: ~$2000-2400/month per user
- BLPAPI Access: Included with terminal license
- Data License: Separate enterprise pricing (contact Bloomberg)
- Minimum commitment: 2-year contract typical

**Total Financial API Spend**: ~$2500-4400/month

**Tracked in Software & Cost Tracker**:
- Morningstar Direct API: $1500/month
- Bloomberg Terminal (1 license): $2400/month

---

## Troubleshooting

### Issue: "API authentication failed"

**Possible Causes**:
1. Expired API key
2. Incorrect credentials
3. Key Vault access denied

**Solutions**:
```powershell
# 1. Verify Key Vault secrets exist
.\scripts\Get-KeyVaultSecret.ps1 -SecretName "morningstar-api-key"

# 2. Test environment variable
echo $env:MORNINGSTAR_API_KEY

# 3. Re-run setup script
.\scripts\Set-MCPEnvironment.ps1
```

### Issue: "Rate limit exceeded"

**Possible Causes**:
1. Too many rapid requests
2. Inefficient query patterns
3. Missing batch operations

**Solutions**:
- Implement exponential backoff retry logic
- Use batch endpoints for multiple securities
- Cache low-volatility data (fundamentals, ratings)
- Spread requests over time

### Issue: "Bloomberg Terminal not responding"

**Possible Causes**:
1. Terminal session expired
2. Network connectivity issues
3. License problem

**Solutions**:
```powershell
# 1. Restart Bloomberg Terminal
Stop-Process -Name "Bloomberg" -Force
Start-Process "C:\blp\API\Bloomberg.exe"

# 2. Check license status
# Launch terminal → HELP <GO> → Check license

# 3. Verify network connectivity
Test-Connection bloomberg.com -Count 4
```

---

## Related Resources

**Scripts**:
- [Set-MCPEnvironment.ps1](../scripts/Set-MCPEnvironment.ps1) - Daily environment setup
- [Test-FinancialAPIs.ps1](../scripts/Test-FinancialAPIs.ps1) - API health checks
- [Get-KeyVaultSecret.ps1](../scripts/Get-KeyVaultSecret.ps1) - Retrieve API keys

**Documentation**:
- [MCP Configuration](./mcp-configuration.md) - Complete MCP server setup
- [Azure Infrastructure](./azure-infrastructure.md) - Key Vault and secrets management
- [Agent Guidelines](./agent-guidelines.md) - General agent usage patterns

**External**:
- [Morningstar Direct API Docs](https://developer.morningstar.com/)
- [Bloomberg API Documentation](https://www.bloomberg.com/professional/support/api-library/)
- [BLPAPI Python Guide](https://bloomberg.github.io/blpapi-docs/python/)

---

**Last Updated**: 2025-10-27 | **Status**: Documentation Complete | **APIs**: Provisioning
