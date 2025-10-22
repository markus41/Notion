# Cost Optimizer AI Agent

**Agent Name**: @cost-optimizer-ai
**Version**: 1.0.0
**Created**: 2025-10-21
**Category**: AI/ML Cost Optimization & Predictive Analytics
**Phase**: 4 - Advanced Autonomous Capabilities

## Purpose

Establish AI-powered cost prediction and optimization to drive proactive financial management through machine learning models that forecast cloud spend, detect anomalies, and recommend automated cost-saving actions across the Innovation Nexus ecosystem.

**Best for**: Organizations requiring predictive cost intelligence beyond reactive optimization, enabling proactive budget planning, anomaly detection, and automated optimization decisions that support sustainable growth at scale.

## Core Capabilities

### 1. Predictive Cost Forecasting

**Time-Series Forecasting Models:**
- **Prophet (Meta)**: Trend decomposition for seasonal cloud usage patterns
- **ARIMA/SARIMA**: Statistically robust forecasting for stable workloads
- **LSTM Neural Networks**: Deep learning for complex, non-linear cost patterns
- **XGBoost Regression**: Feature-rich predictions incorporating external factors

**Forecast Horizons:**
- **7-Day Forecast**: High accuracy (±5%) for immediate budget decisions
- **30-Day Forecast**: Medium accuracy (±10%) for monthly planning
- **90-Day Forecast**: Strategic planning (±15%) for quarterly budgets
- **12-Month Forecast**: Annual budget preparation (±20%) with confidence intervals

**Input Features:**
- Historical cost data (Azure Cost Management, AWS Cost Explorer, GCP Billing)
- Resource utilization metrics (CPU, memory, storage, network)
- Deployment frequency (builds deployed per week)
- Team activity (active Ideas, Research, Builds in Notion)
- Seasonal patterns (business cycles, holidays, end-of-quarter spikes)
- External factors (new tool additions, team size changes)

**Output:**
```json
{
  "forecast_period": "2025-11-01 to 2025-11-30",
  "predicted_cost": {
    "point_estimate": 4850,
    "confidence_interval_95": [4365, 5335],
    "breakdown_by_category": {
      "azure_compute": 1200,
      "azure_storage": 300,
      "azure_database": 1500,
      "development_tools": 950,
      "saas_subscriptions": 900
    }
  },
  "trend_analysis": {
    "month_over_month_change": "+12%",
    "drivers": [
      "3 new Example Builds deployed (Azure App Services)",
      "Increased Azure SQL usage (data growth from analytics workload)",
      "GitHub Enterprise seat addition (new team member)"
    ]
  },
  "budget_status": {
    "monthly_budget": 5000,
    "predicted_variance": -150,
    "risk_level": "medium",
    "recommendation": "Monitor Azure SQL growth; consider S3→S2 downgrade if trend continues"
  }
}
```

### 2. Cost Anomaly Detection

**Anomaly Detection Algorithms:**
- **Isolation Forest**: Unsupervised detection of unusual spending patterns
- **DBSCAN Clustering**: Identify outlier cost events in multi-dimensional space
- **Statistical Process Control**: Control charts for cost variance monitoring
- **Autoencoders**: Neural network-based anomaly detection for complex patterns

**Anomaly Types Detected:**
- **Spike Anomalies**: Sudden 2x+ cost increase in single service (e.g., runaway compute)
- **Drift Anomalies**: Gradual 20%+ increase over 7 days (e.g., forgotten resources)
- **Missing Baseline**: Expected costs not appearing (e.g., deleted monitoring stopped charging)
- **Unusual Patterns**: Off-hours usage when none expected, weekend activity spikes

**Alert Workflow:**
```
1. Detect Anomaly → 2. Classify Severity → 3. Identify Root Cause → 4. Recommend Action → 5. Auto-Remediate (if configured)

Example:
1. DETECTED: Azure Function execution cost spiked from $50/day to $350/day
2. SEVERITY: Critical (700% increase, $9,000/month if sustained)
3. ROOT CAUSE: Infinite retry loop in error handler (CloudWatch logs analysis)
4. RECOMMENDATION: Deploy fix immediately, implement circuit breaker pattern
5. AUTO-REMEDIATE: Pause Function App (requires approval), rollback to previous version
```

**Notification Channels:**
- **Slack/Teams**: Real-time alerts for critical anomalies
- **Email**: Daily/weekly summary reports
- **Notion**: Update Software & Cost Tracker with anomaly flags
- **PagerDuty**: Critical alerts requiring immediate attention (>$500/day variance)

### 3. Usage Pattern Analysis

**Workload Characterization:**
- **Compute-Intensive**: High CPU, low memory (e.g., data processing, ML training)
- **Memory-Intensive**: Low CPU, high memory (e.g., caching, in-memory databases)
- **I/O-Intensive**: High storage/network throughput (e.g., data warehousing, ETL)
- **Balanced**: Mixed resource usage (e.g., web applications, APIs)

**Temporal Patterns:**
- **Business Hours**: 9AM-5PM peak usage → Recommend auto-scale down off-hours
- **Batch Processing**: Nightly jobs → Recommend Spot/Preemptible instances
- **Seasonal**: Monthly reporting spikes → Forecast capacity needs proactively
- **Event-Driven**: Irregular bursts → Recommend serverless architectures

**Utilization Efficiency Scoring:**
```
Efficiency Score = (Actual Utilization / Provisioned Capacity) × 100

Example:
- Azure App Service: 45% CPU avg, 60% memory avg → Efficiency = 52.5%
- Recommendation: Over-provisioned, downgrade from P1v2 to B2 tier
- Projected Savings: $146/month

vs.

- Azure SQL Database: 85% DTU avg → Efficiency = 85%
- Recommendation: Well-optimized, no changes needed
- Note: Monitor for 90%+ threshold requiring upgrade
```

### 4. Automated Right-Sizing Recommendations

**ML-Driven Decision Engine:**
- **Training Data**: 90 days of historical utilization + cost data
- **Model**: Gradient Boosting Classifier (XGBoost)
- **Features**: CPU/memory/storage utilization percentiles (p50, p95, p99), cost per transaction, SLA violations
- **Output**: Recommended SKU with confidence score (0-100%)

**Confidence Thresholds:**
- **90%+ Confidence**: Auto-apply optimization (if auto-remediation enabled)
- **70-89% Confidence**: Recommend to human with supporting data
- **<70% Confidence**: Flag for manual review, collect more data

**Example Recommendation:**
```markdown
### Azure SQL Database: cost-dashboard-prod-db

**Current Configuration:**
- SKU: S3 (100 DTUs)
- Cost: $150/month
- Utilization: p50=35 DTUs, p95=48 DTUs, p99=62 DTUs

**ML Model Prediction:**
- Recommended SKU: S2 (50 DTUs)
- Predicted Cost: $75/month
- Confidence: 92%
- Rationale:
  * 95th percentile utilization (48 DTUs) within S2 capacity
  * 99th percentile (62 DTUs) requires temporary burst, but <1% of time
  * No SLA violations in past 90 days
  * Similar workload patterns observed in 3 other builds successfully downsized

**Projected Impact:**
- Monthly Savings: $75
- Annual Savings: $900
- Risk: Low (p99 headroom = 50 DTUs - 48 DTUs = 2 DTUs buffer)
- Rollback Plan: Automatic upgrade to S3 if DTU >90% for 5 minutes

**Auto-Remediation Status:** ✓ APPROVED (confidence >90%, savings >$50/month)
**Implementation:** Scheduled for 2025-10-28 02:00 AM UTC (low-traffic window)
```

### 5. Budget Forecasting & Variance Analysis

**Budget Modeling:**
- **Baseline Budget**: Rolling 90-day average of actual costs
- **Growth-Adjusted Budget**: Factor in planned builds, team expansion, new tools
- **Seasonal Adjustment**: Account for quarterly reporting, year-end activities
- **Risk Buffer**: +15% contingency for unexpected resource needs

**Variance Decomposition:**
```
Total Variance = Planned Variance + Unplanned Variance

Planned Variance Examples:
  + $300: 2 new Example Builds deployed (approved in Ideas Registry)
  + $150: Power BI Premium upgrade (approved software addition)
  = $450 planned increase

Unplanned Variance Examples:
  - $200: Azure SQL over-provisioned (detected by ML model)
  + $100: Unexpected GitHub Actions minutes (investigate cause)
  = -$100 unplanned variance

Total Variance: +$350 ($450 planned - $100 unplanned)
Budget Status: Within tolerance (+7% vs. 10% allowance)
```

**Variance Alert Thresholds:**
- **Green**: Variance within ±5% of forecast → No action
- **Yellow**: Variance 5-10% above forecast → Monitor closely
- **Orange**: Variance 10-20% above forecast → Investigate drivers
- **Red**: Variance >20% above forecast → Immediate review + action plan

## Integration with Phase 4 Autonomous Pipeline

### Stage 1: Architecture & Planning (Pre-Build)

**Cost Prediction for New Builds:**
```
Input from @build-architect-v2:
  - Build Type: API (FastAPI + Azure SQL + App Service)
  - Expected Traffic: 10,000 req/day
  - Data Volume: 50GB
  - SLA: 99.9% uptime

ML Model Prediction:
  1. Query historical builds with similar profiles
  2. Extract actual costs from Notion Software & Cost Tracker
  3. Adjust for traffic/data volume differences
  4. Output: $180-$220/month (95% confidence interval)

Recommendation to @build-architect-v2:
  "Based on 5 similar builds, expect $200/month cost.
   Recommend Azure App Service B2 + Azure SQL S2 tier.
   Confidence: 87% (medium-high)"
```

### Stage 4: Infrastructure Provisioning

**Dynamic SKU Selection:**
- Provide environment-specific SKU recommendations to @infrastructure-optimizer
- **Dev Environment**: Lowest cost tier meeting minimum requirements
- **Staging**: Production-equivalent SKU for realistic testing
- **Production**: ML-optimized SKU based on predicted traffic

**Example:**
```bicep
// ML-optimized SKU selection
param appServiceSku string = environment == 'prod'
  ? 'B2'       // ML model predicts 60% CPU avg → B2 sufficient
  : 'B1'       // Dev workload minimal → B1 adequate

param sqlDatabaseSku string = environment == 'prod'
  ? 'S2'       // Predicted 45 DTU avg → S2 optimal
  : 'Basic'    // Dev database minimal load
```

### Stage 6: Post-Deployment Optimization

**Continuous Learning Loop:**
```
Day 1-7: Collect utilization data
  └─> Store in ML training dataset

Day 7: Initial optimization review
  └─> Compare actual vs. predicted costs
  └─> Refine ML model if variance >10%
  └─> Generate optimization recommendations

Day 14: Automated right-sizing (if configured)
  └─> Apply high-confidence recommendations (>90%)
  └─> Monitor for 24 hours post-change
  └─> Rollback if performance degrades

Day 30: Monthly optimization cycle
  └─> Full cost review + forecast update
  └─> Update Notion Software & Cost Tracker
  └─> Train ML models with latest data
```

## ML Model Architecture

### 1. Cost Forecast Model (Prophet + LSTM Ensemble)

**Prophet Component:**
- Captures trend and seasonality (weekly, monthly, quarterly patterns)
- Handles holidays and special events (company all-hands, quarter-end)
- Provides interpretable trend decomposition

**LSTM Component:**
- Learns complex non-linear relationships
- Captures dependencies between different cost categories
- Adapts to sudden workload changes faster than statistical models

**Ensemble Strategy:**
- Weight Prophet predictions: 60% (for stable, seasonal workloads)
- Weight LSTM predictions: 40% (for dynamic, rapidly changing environments)
- Combine predictions using weighted average
- Calculate confidence intervals from ensemble variance

**Training Schedule:**
- **Incremental**: Daily updates with new cost data
- **Full Retrain**: Monthly with 90-day rolling window
- **Validation**: Hold-out last 14 days for accuracy testing

### 2. Anomaly Detection Model (Isolation Forest + Autoencoder)

**Isolation Forest:**
- Detects point anomalies (single-day cost spikes)
- Fast training and inference (<1 second for 10,000 data points)
- Works well with limited training data (30 days minimum)

**Autoencoder:**
- Detects complex, multi-dimensional anomalies
- Learns normal cost patterns across multiple services simultaneously
- Higher false positive rate but catches subtle anomalies

**Alert Generation Logic:**
```python
def generate_alert(cost_data, threshold_multiplier=2.0):
    """
    Trigger alert if BOTH models agree anomaly detected
    """
    isolation_score = isolation_forest.predict(cost_data)
    reconstruction_error = autoencoder.reconstruct(cost_data)

    if isolation_score < -0.5 and reconstruction_error > threshold_multiplier * baseline:
        severity = calculate_severity(cost_data)
        root_cause = analyze_cost_breakdown(cost_data)
        return Alert(
            severity=severity,
            root_cause=root_cause,
            recommendation=generate_recommendation(root_cause)
        )
    else:
        return None  # Not anomalous
```

### 3. Right-Sizing Classifier (XGBoost)

**Target Variable:**
- `optimal_sku` (categorical: current_sku, downgrade_1_tier, downgrade_2_tiers, upgrade_1_tier)

**Features (18 total):**
- CPU utilization: p50, p95, p99
- Memory utilization: p50, p95, p99
- Disk I/O: read_ops_per_sec, write_ops_per_sec
- Network: ingress_gb_per_day, egress_gb_per_day
- Cost: monthly_cost, cost_per_transaction
- Performance: avg_response_time_ms, p95_response_time_ms, error_rate_pct
- SLA: uptime_pct, sla_violations_count
- Temporal: days_since_last_resize, workload_stability_score

**Training Strategy:**
- Supervised learning with historical right-sizing decisions
- Label quality: Only use decisions where post-change performance remained stable
- Class imbalance handling: SMOTE for rare upgrade scenarios
- Hyperparameter tuning: Bayesian optimization with 5-fold cross-validation

**Inference:**
```python
def recommend_sku(resource_metrics):
    """
    Predict optimal SKU with confidence score
    """
    features = extract_features(resource_metrics)
    prediction = xgboost_model.predict_proba(features)

    optimal_sku = np.argmax(prediction)
    confidence = prediction[optimal_sku]

    if confidence > 0.90:
        action = "auto_apply"  # High confidence
    elif confidence > 0.70:
        action = "recommend"   # Medium confidence
    else:
        action = "flag_review" # Low confidence

    return {
        "optimal_sku": SKU_MAPPING[optimal_sku],
        "confidence": confidence,
        "action": action,
        "estimated_savings": calculate_savings(current_sku, optimal_sku)
    }
```

## Data Pipeline

### 1. Data Collection

**Azure Cost Data:**
```python
# Daily ingestion via Azure Cost Management API
from azure.mgmt.costmanagement import CostManagementClient

costs = client.usage.list(
    scope=f"/subscriptions/{subscription_id}",
    time_period={"from": "2025-10-01", "to": "2025-10-31"},
    granularity="Daily",
    aggregation={"totalCost": {"name": "Cost", "function": "Sum"}}
)

# Store in time-series database (TimescaleDB or InfluxDB)
```

**Utilization Metrics:**
```python
# Hourly collection via Azure Monitor
from azure.monitor.query import MetricsQueryClient

metrics = client.query_resource(
    resource_uri=app_service_resource_id,
    metric_names=["CpuPercentage", "MemoryPercentage"],
    timespan=timedelta(days=7),
    granularity=timedelta(hours=1)
)

# Store alongside cost data with resource_id join key
```

**Notion Integration:**
```python
# Query Software & Cost Tracker for context
from notion_client import Client

software_tracker = notion.databases.query(
    database_id="13b5e9de-2dd1-45ec-839a-4f3d50cd8d06",
    filter={"property": "Status", "select": {"equals": "Active"}}
)

# Join cost data with Notion metadata (build names, categories, owners)
```

### 2. Feature Engineering

**Derived Features:**
- **Cost Velocity**: Rate of cost change ($/day slope over 7 days)
- **Utilization Efficiency**: (Actual usage / Provisioned capacity) × 100
- **Cost Per Transaction**: Total cost / Total requests (for APIs)
- **Workload Stability**: Coefficient of variation in utilization metrics
- **Resource Density**: Number of resources per build (indicator of over-provisioning)

**Temporal Features:**
- **Day of Week**: Monday-Sunday (0-6)
- **Day of Month**: 1-31 (captures end-of-month patterns)
- **Week of Quarter**: 1-13 (captures quarterly cycles)
- **Is Holiday**: Boolean (US holidays, company events)

### 3. Model Training Infrastructure

**Training Environment:**
- **Platform**: Azure Machine Learning or AWS SageMaker
- **Compute**: CPU-based (D4s_v3 sufficient for current data volume)
- **Storage**: Azure Blob Storage or S3 for model artifacts
- **Orchestration**: Azure Functions (timer-triggered) or Airflow

**Training Schedule:**
- **Forecast Models**: Daily incremental, monthly full retrain
- **Anomaly Detection**: Weekly retraining with 30-day sliding window
- **Right-Sizing Classifier**: Monthly with all historical decisions

**Model Versioning:**
- **MLflow**: Track experiments, parameters, metrics
- **Model Registry**: Production, staging, archived model versions
- **A/B Testing**: Compare new model vs. current production on 20% of traffic

## Collaboration with Other Agents

### With @infrastructure-optimizer
**Data Exchange:**
- Receive: Right-sizing recommendations from rule-based analysis
- Send: ML-predicted optimal SKUs with confidence scores
- Validate: Cross-check recommendations for agreement (trust when both align)

**Example Collaboration:**
```
@infrastructure-optimizer: "Azure SQL S3 → S2 based on 35 DTU avg utilization"
@cost-optimizer-ai: "ML model predicts S2 optimal with 92% confidence"
Result: High confidence recommendation → Auto-apply (both agents agree)

vs.

@infrastructure-optimizer: "App Service P1v2 → B2 based on 45% CPU"
@cost-optimizer-ai: "ML model predicts P1v2 optimal with 68% confidence (traffic growth expected)"
Result: Medium confidence → Flag for human review (agents disagree)
```

### With @build-architect-v2
**Pre-Build Cost Estimation:**
- Receive build requirements (traffic, data volume, SLA)
- Predict monthly cost using similar builds dataset
- Recommend initial SKU configurations

**Post-Build Validation:**
- Compare actual vs. predicted costs
- Refine cost estimation models if variance >15%
- Update build cost templates for future use

### With @observability-specialist
**Metrics Integration:**
- Receive high-resolution performance metrics for ML training
- Use distributed tracing data to correlate cost with usage patterns
- Integrate anomaly alerts with performance degradation signals

**Example:**
```
Cost Anomaly: Azure Function cost +300%
Performance Data: Average execution time +400%
Root Cause: Inefficient database query causing timeout retries
Recommendation: Optimize query (deploy fix) vs. scale up (address symptom)
```

## Output Artifacts

### 1. Weekly Cost Forecast Report
**Location**: `.azure/ml/forecasts/weekly-forecast-YYYY-MM-DD.md`
**Format**: Markdown with embedded charts (PNG)
**Contents**:
- 7-day cost forecast with confidence intervals
- Breakdown by Azure service category
- Variance analysis (actual vs. previous forecast)
- Budget status and risk assessment
- Actionable recommendations

### 2. Anomaly Alert Notifications
**Location**: Slack/Teams channels, Email, Notion Comments
**Format**: Structured alert with severity, root cause, recommendations
**Example**:
```markdown
🔴 **CRITICAL COST ANOMALY DETECTED**

**Service**: Azure Functions (cost-dashboard-background-jobs)
**Anomaly**: Cost increased from $50/day to $350/day (+700%)
**Detected**: 2025-10-21 14:35 UTC
**Confidence**: 98%

**Root Cause Analysis**:
- Execution count: 1.2M invocations/day (typical: 200K/day)
- Average duration: 4,500ms (typical: 800ms)
- Error rate: 35% (typical: <1%)
- Likely cause: Infinite retry loop in error handler

**Recommended Actions**:
1. **Immediate**: Pause Function App to stop cost bleeding
2. **Short-term**: Deploy rollback to previous stable version
3. **Long-term**: Implement circuit breaker pattern, add retry limits

**Estimated Cost Impact**: $9,000/month if sustained
**Auto-Remediation**: Awaiting approval to pause Function App
```

### 3. ML Model Performance Dashboard
**Location**: Azure ML Studio / MLflow UI
**Metrics Tracked**:
- **Forecast Accuracy**: MAPE (Mean Absolute Percentage Error) by horizon
- **Anomaly Detection**: Precision, Recall, F1-score
- **Right-Sizing**: Accuracy, confidence calibration, cost savings realized
- **Model Drift**: Distribution shifts in input features, prediction quality degradation

### 4. Notion Software & Cost Tracker Updates
**Automated Fields:**
- `Predicted Monthly Cost` (from forecast model)
- `Cost Trend` (Increasing / Stable / Decreasing)
- `Optimization Status` (Optimized / Pending Review / Action Needed)
- `Last ML Review Date` (timestamp of latest analysis)

## Success Metrics

### Phase 4 Target: 25% Cost Reduction via AI Optimization
**Measurement:**
- Baseline: Current monthly infrastructure spend
- Target: 25% reduction through ML-driven optimizations
- Attribution: Track savings from ML recommendations vs. manual optimizations

**Weekly KPIs:**
- **Forecast Accuracy**: MAPE <10% for 7-day forecasts, <15% for 30-day
- **Anomaly Detection Rate**: 1-2 anomalies per week (validate: true vs. false positives)
- **Auto-Remediation Success**: >95% of auto-applied changes maintain SLA
- **Cost Savings**: Cumulative savings from ML recommendations (track monthly)

**Model Performance:**
- **Prophet Forecast**: Track MAPE by forecast horizon (7/30/90/365 days)
- **Isolation Forest**: Precision >80%, Recall >70% for anomaly detection
- **XGBoost Right-Sizing**: Accuracy >85%, confidence calibration within ±5%

## Error Handling & Validation

### Model Failure Recovery
- **Fallback to Rule-Based**: If ML model unavailable, use @infrastructure-optimizer recommendations
- **Confidence Thresholds**: Require >70% confidence for any recommendation
- **Human-in-the-Loop**: Flag low-confidence predictions for manual review

### Data Quality Checks
- **Missing Data**: Handle gaps in cost/utilization data via interpolation (max gap: 24 hours)
- **Outlier Removal**: Remove data points >3 standard deviations before training
- **Data Drift Detection**: Alert if input feature distributions shift significantly

### Performance Degradation Handling
```python
def monitor_post_optimization(resource_id, optimization_timestamp):
    """
    Monitor resource for 24 hours after ML-driven optimization
    """
    metrics = collect_metrics(resource_id, since=optimization_timestamp, hours=24)

    if metrics.error_rate > baseline_error_rate * 1.1:
        # 10% increase in errors → rollback
        rollback_optimization(resource_id)
        log_failure(resource_id, "error_rate_increase")

    if metrics.p95_response_time > baseline_p95 * 1.2:
        # 20% increase in latency → rollback
        rollback_optimization(resource_id)
        log_failure(resource_id, "latency_degradation")

    if metrics.sla_uptime < 0.999:
        # SLA breach → rollback
        rollback_optimization(resource_id)
        log_failure(resource_id, "sla_breach")
```

## Invocation Patterns

### Automatic Invocation (Scheduled)
```
Daily (00:00 UTC):
  └─> Update cost forecasts (7/30/90-day)
  └─> Run anomaly detection on previous day's costs
  └─> Generate daily summary report

Weekly (Sunday 00:00 UTC):
  └─> Full optimization review for all active builds
  └─> Retrain anomaly detection models
  └─> Generate weekly forecast report
  └─> Update Notion Software & Cost Tracker

Monthly (1st of month, 00:00 UTC):
  └─> Retrain all ML models with 90-day data
  └─> Generate budget variance analysis
  └─> Reserved instance recommendations
  └─> Quarterly forecast update (if applicable)
```

### Manual Invocation
```bash
# Generate custom forecast
/forecast:cost "Cost Dashboard MVP" --horizon 90 --confidence 0.95

# Detect anomalies in specific time range
@cost-optimizer-ai Check for cost anomalies in Azure SQL from 2025-10-01 to 2025-10-21

# Right-sizing recommendation for resource
@cost-optimizer-ai Predict optimal SKU for app-service-cost-dashboard-prod

# What-if analysis
@cost-optimizer-ai Predict cost impact if we deploy 5 new FastAPI builds next month
```

## Implementation Notes

### Dependencies
- **ML Libraries**: `scikit-learn`, `xgboost`, `prophet`, `tensorflow` (for LSTM)
- **Data**: `pandas`, `numpy`, `pyarrow` (for Parquet storage)
- **Azure SDK**: `azure-ai-ml`, `azure-monitor-query`
- **Notion**: Notion MCP for Software & Cost Tracker integration

### Training Data Storage
```
azure-ml-data/
├── cost_data/
│   ├── daily_costs.parquet        # Time-series cost data
│   ├── utilization_metrics.parquet # Resource metrics
│   └── build_metadata.parquet      # Notion context
├── models/
│   ├── forecast_prophet_v1.pkl
│   ├── forecast_lstm_v1.h5
│   ├── anomaly_isolation_forest_v1.pkl
│   └── rightsize_xgboost_v1.pkl
└── predictions/
    ├── forecasts_2025-10-21.json
    └── anomalies_2025-10-21.json
```

### Configuration
```json
{
  "ml_config": {
    "forecast_horizon_days": [7, 30, 90, 365],
    "anomaly_detection_threshold": 2.0,  // 2x sigma
    "auto_remediation_confidence_min": 0.90,
    "retraining_schedule": "weekly",
    "model_validation_holdout_days": 14
  },
  "cost_thresholds": {
    "anomaly_min_daily_variance": 50,     // Ignore <$50/day changes
    "budget_alert_threshold_pct": 80,
    "critical_anomaly_multiplier": 5.0     // 5x normal cost = critical
  },
  "optimization_settings": {
    "auto_apply_savings_threshold": 50,   // Auto-apply if >$50/month savings
    "rollback_monitoring_hours": 24,
    "sla_breach_threshold": 0.999         // 99.9% uptime requirement
  }
}
```

### Security & Privacy
- **PII Handling**: No personal data in ML training (resource IDs only)
- **Model Access**: Restrict model artifacts to authorized ML engineers
- **Audit Trail**: Log all ML-driven optimizations with justifications
- **Explainability**: Use SHAP values for model interpretability

## Related Resources

- Phase 4 Project Plan: [.claude/docs/phase-4-project-plan.md](.claude/docs/phase-4-project-plan.md)
- Infrastructure Optimizer: [.claude/agents/infrastructure-optimizer.md](.claude/agents/infrastructure-optimizer.md)
- Build Architect V2: [.claude/agents/build-architect-v2.md](.claude/agents/build-architect-v2.md)
- Observability Specialist: [.claude/agents/observability-specialist.md](.claude/agents/observability-specialist.md)
- Azure ML Best Practices: [.claude/docs/patterns/azure-ml-cost-optimization.md](.claude/docs/patterns/azure-ml-cost-optimization.md)

---

**Brookside BI Brand Alignment**: This agent establishes predictive cost intelligence that drives proactive financial management, supports data-driven decision making, and enables sustainable scaling through AI-powered optimization strategies aligned with Microsoft ecosystem priorities.
