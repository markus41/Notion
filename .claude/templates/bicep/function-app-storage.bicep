// ============================================================================
// Azure Functions + Storage Account + Key Vault
// ============================================================================
//
// Establishes serverless compute infrastructure with event-driven processing,
// secure secret management, and cost-optimized consumption-based billing.
//
// Best for: Event-driven workloads, scheduled jobs, API backends, data processing
//
// Resources Provisioned:
// - Storage Account (required for Functions runtime)
// - App Service Plan (Consumption Y1 for dev, Elastic Premium EP1 for prod)
// - Function App with Managed Identity
// - Key Vault with RBAC authorization
// - Application Insights with distributed tracing
// - Log Analytics Workspace
//
// Estimated Monthly Cost:
// - Development:  ~$5 (Consumption plan, pay-per-execution)
// - Staging:      ~$15 (Consumption with moderate load)
// - Production:   ~$73 (Elastic Premium EP1 for guaranteed performance)
//
// ============================================================================

targetScope = 'resourceGroup'

// ============================================================================
// PARAMETERS
// ============================================================================

@description('Environment name (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string

@description('Workload name used for resource naming')
@minLength(3)
@maxLength(15)
param prefix string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Azure AD tenant ID')
param tenantId string = tenant().tenantId

@description('Function App runtime')
@allowed(['dotnet', 'node', 'python', 'java'])
param functionRuntime string = 'python'

@description('Function App runtime version')
param functionRuntimeVersion string = '3.11'

@description('Tags to apply to all resources')
param tags object = {
  Environment: environment
  ManagedBy: 'ClaudeCode'
  Workload: prefix
}

// ============================================================================
// VARIABLES
// ============================================================================

var functionAppName = 'func-${prefix}-${environment}'
var appServicePlanName = 'plan-${prefix}-${environment}'
var storageAccountName = 'st${replace(prefix, '-', '')}${substring(environment, 0, 3)}'
var keyVaultName = 'kv-${prefix}-${substring(environment, 0, 3)}'
var appInsightsName = 'appi-${prefix}-${environment}'
var logAnalyticsName = 'law-${prefix}-${environment}'

// Environment-specific configuration
var hostingPlan = environment == 'prod' ? 'ElasticPremium' : 'Consumption'
var skuName = environment == 'prod' ? 'EP1' : 'Y1'
var skuTier = environment == 'prod' ? 'ElasticPremium' : 'Dynamic'

// Runtime configuration mapping
var runtimeConfigs = {
  dotnet: {
    linuxFxVersion: 'DOTNET-ISOLATED|8.0'
    FUNCTIONS_WORKER_RUNTIME: 'dotnet-isolated'
  }
  node: {
    linuxFxVersion: 'NODE|18'
    FUNCTIONS_WORKER_RUNTIME: 'node'
  }
  python: {
    linuxFxVersion: 'PYTHON|${functionRuntimeVersion}'
    FUNCTIONS_WORKER_RUNTIME: 'python'
  }
  java: {
    linuxFxVersion: 'JAVA|17'
    FUNCTIONS_WORKER_RUNTIME: 'java'
  }
}

// ============================================================================
// RESOURCE: Log Analytics Workspace
// ============================================================================

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: environment == 'prod' ? 90 : 30
  }
}

// ============================================================================
// RESOURCE: Application Insights
// ============================================================================

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
    RetentionInDays: environment == 'prod' ? 90 : 30
    SamplingPercentage: 100
  }
}

// ============================================================================
// RESOURCE: Storage Account (Required for Functions)
// ============================================================================

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: environment == 'prod' ? 'Standard_GRS' : 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true  // Required for Functions runtime

    // Network configuration
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

// ============================================================================
// RESOURCE: App Service Plan
// ============================================================================

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuTier
  }
  kind: 'linux'
  properties: {
    reserved: true  // Required for Linux
    maximumElasticWorkerCount: environment == 'prod' ? 20 : 1
  }
}

// ============================================================================
// RESOURCE: Function App
// ============================================================================

resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppName
  location: location
  tags: tags
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    clientAffinityEnabled: false

    siteConfig: {
      linuxFxVersion: runtimeConfigs[functionRuntime].linuxFxVersion
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      http20Enabled: true
      use32BitWorkerProcess: false

      // Health check for premium plans
      healthCheckPath: environment == 'prod' ? '/api/health' : null

      // App settings
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: runtimeConfigs[functionRuntime].FUNCTIONS_WORKER_RUNTIME
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'AZURE_KEYVAULT_URI'
          value: keyVault.properties.vaultUri
        }
        {
          name: 'ENVIRONMENT'
          value: environment
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        // Enable distributed tracing
        {
          name: 'WEBSITE_ENABLE_SYNC_UPDATE_SITE'
          value: 'true'
        }
      ]

      cors: {
        allowedOrigins: environment == 'prod' ? [] : ['http://localhost:3000', 'http://localhost:7071']
        supportCredentials: false
      }
    }
  }
}

// Enable diagnostic settings
resource functionAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagnostics'
  scope: functionApp
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'FunctionAppLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: environment == 'prod' ? 90 : 30
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: environment == 'prod' ? 90 : 30
        }
      }
    ]
  }
}

// ============================================================================
// RESOURCE: Key Vault
// ============================================================================

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: environment == 'prod'

    publicNetworkAccess: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

// Grant Function App "Key Vault Secrets User" role
resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, functionApp.id, 'Key Vault Secrets User')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Grant Function App "Storage Blob Data Contributor" role
resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, functionApp.id, 'Storage Blob Data Contributor')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Store Application Insights connection string
resource appInsightsConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'appinsights-connection-string'
  properties: {
    value: appInsights.properties.ConnectionString
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

@description('Function App URL')
output functionAppUrl string = 'https://${functionApp.properties.defaultHostName}'

@description('Function App name')
output functionAppName string = functionApp.name

@description('Function App principal ID')
output functionAppPrincipalId string = functionApp.identity.principalId

@description('Key Vault URI')
output keyVaultUri string = keyVault.properties.vaultUri

@description('Key Vault name')
output keyVaultName string = keyVault.name

@description('Storage Account name')
output storageAccountName string = storageAccount.name

@description('Application Insights connection string')
@secure()
output appInsightsConnectionString string = appInsights.properties.ConnectionString

@description('Log Analytics Workspace ID')
output logAnalyticsWorkspaceId string = logAnalytics.id

@description('Estimated monthly cost (USD)')
output estimatedMonthlyCost string = environment == 'dev' ? '~$5' : environment == 'staging' ? '~$15' : '~$73'
