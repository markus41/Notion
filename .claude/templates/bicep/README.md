# Bicep Template Library

Comprehensive collection of production-ready Azure Bicep templates for autonomous build pipeline deployment. All templates follow Microsoft best practices with cost optimization, security hardening, and monitoring built-in.

## Template Categories

### 1. **Web Applications**
- `web-app-sql.bicep` - App Service + Azure SQL Database + Key Vault
- `web-app-cosmos.bicep` - App Service + Cosmos DB + Key Vault
- `web-app-storage.bicep` - App Service + Storage Account + CDN

### 2. **Serverless Functions**
- `function-app-storage.bicep` - Azure Functions (Consumption) + Storage
- `function-app-cosmos.bicep` - Azure Functions + Cosmos DB
- `function-app-servicebus.bicep` - Azure Functions + Service Bus + Storage

### 3. **Container Applications**
- `container-app.bicep` - Azure Container Apps + Container Registry
- `aks-cluster.bicep` - AKS cluster with managed identity

### 4. **Data & Analytics**
- `data-lake-analytics.bicep` - Data Lake Gen2 + Synapse Analytics
- `sql-database-advanced.bicep` - SQL with geo-replication + failover groups

### 5. **Common Modules**
- `modules/app-service-plan.bicep` - Reusable App Service Plan
- `modules/key-vault.bicep` - Key Vault with RBAC
- `modules/app-insights.bicep` - Application Insights
- `modules/sql-server.bicep` - SQL Server with Azure AD admin
- `modules/storage-account.bicep` - Storage Account with lifecycle policies

## Usage

All templates support three environments: `dev`, `staging`, `prod`

**Environment-Specific SKUs:**
- **Dev**: Cost-optimized (B1, Basic SQL, Standard storage)
- **Staging**: Production-like (S1, Standard SQL)
- **Production**: High availability (P1v2, Premium SQL with geo-redundancy)

**Deployment Example:**
```bash
# Deploy to development
az deployment group create \
  --resource-group rg-myapp-dev \
  --template-file .claude/templates/bicep/web-app-sql.bicep \
  --parameters environment=dev prefix=myapp location=eastus2

# Deploy to production
az deployment group create \
  --resource-group rg-myapp-prod \
  --template-file .claude/templates/bicep/web-app-sql.bicep \
  --parameters environment=prod prefix=myapp location=eastus2
```

## Standard Features

All templates include:

✅ **Security Best Practices**
- Managed Identity for all services
- RBAC authorization (no access keys)
- Soft delete enabled on critical resources
- TLS 1.2+ enforcement
- Private endpoints for production

✅ **Cost Optimization**
- Environment-based SKU selection
- Auto-pause for dev SQL databases
- Lifecycle policies for storage
- Consumption plans where appropriate

✅ **Monitoring & Observability**
- Application Insights integration
- Diagnostic settings to Log Analytics
- Automatic alerts for critical metrics
- Structured logging configuration

✅ **Resilience**
- Health checks configured
- Geo-redundant backups (production)
- Automatic failover (where applicable)
- Disaster recovery ready

## Naming Conventions

All resources follow Azure naming best practices:

| Resource Type | Pattern | Example |
|---------------|---------|---------|
| Resource Group | `rg-{workload}-{environment}` | `rg-customerapi-prod` |
| App Service Plan | `plan-{workload}-{environment}` | `plan-customerapi-prod` |
| Web App | `app-{workload}-{environment}` | `app-customerapi-prod` |
| Function App | `func-{workload}-{environment}` | `func-notifications-prod` |
| SQL Server | `sql-{workload}-{environment}` | `sql-customerapi-prod` |
| SQL Database | `{workload}db` | `customerapidb` |
| Key Vault | `kv-{workload}-{env}` | `kv-customerapi-prod` |
| Storage Account | `st{workload}{env}` | `stcustomerapiprod` |
| App Insights | `appi-{workload}-{environment}` | `appi-customerapi-prod` |
| Container Registry | `cr{workload}{env}` | `crcustomerapiprod` |

## Template Selection Guide

**Choose template based on workload:**

| Workload Type | Recommended Template | Monthly Cost (Dev/Prod) |
|---------------|---------------------|------------------------|
| REST API with relational data | `web-app-sql.bicep` | $18 / $75 |
| REST API with document data | `web-app-cosmos.bicep` | $25 / $100 |
| Event-driven processing | `function-app-servicebus.bicep` | $8 / $40 |
| Scheduled jobs/batch | `function-app-storage.bicep` | $5 / $30 |
| Microservices | `container-app.bicep` | $20 / $80 |
| Static web app with API | `web-app-storage.bicep` | $15 / $60 |

## Cost Estimates

**Development Environment:**
- App Service (B1): $13.14/month
- Azure SQL (Basic): $4.99/month
- Key Vault: $0.03/month
- Application Insights: ~$2.30/month
- Storage (LRS): ~$0.02/month
- **Total: ~$20/month**

**Production Environment:**
- App Service (P1v2): $72.27/month
- Azure SQL (S2): $74.97/month
- Key Vault: $0.03/month
- Application Insights: ~$10/month
- Storage (GRS): ~$0.05/month
- **Total: ~$157/month**

## Best Practices

1. **Always use modules** for reusable components (App Service Plan, Key Vault, etc.)
2. **Parameter files** for each environment instead of inline parameters
3. **Incremental deployment mode** to avoid deleting unmanaged resources
4. **What-if validation** before production deployments
5. **Tag all resources** with `Environment`, `ManagedBy`, `CostCenter`
6. **Export outputs** for use in application configuration
7. **Enable diagnostic settings** on all production resources

## Contributing

When adding new templates:
1. Follow existing naming conventions
2. Include parameter validation and defaults
3. Add comprehensive comments explaining resource purpose
4. Test in all three environments
5. Document cost estimates
6. Include usage examples
