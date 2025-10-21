// Main Infrastructure Template for Autonomous Innovation Platform
// Establishes scalable Azure resources for Notion-triggered automation workflows
//
// Best for: Organizations requiring fully autonomous innovation pipelines with
// pattern learning, agent orchestration, and minimal human intervention

@description('Location for all resources')
param location string = resourceGroup().location

@description('Environment name (dev, staging, prod)')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environment string = 'dev'

@description('Unique suffix for resource naming')
param uniqueSuffix string = uniqueString(resourceGroup().id)

@description('Key Vault name containing secrets')
param keyVaultName string = 'kv-brookside-secrets'

@description('Notion workspace ID')
param notionWorkspaceId string

@description('GitHub organization name')
param githubOrganization string = 'brookside-bi'

// ============================================================================
// VARIABLES
// ============================================================================

var resourcePrefix = 'brookside-innovation'
var tags = {
  Environment: environment
  Project: 'Autonomous Innovation Platform'
  ManagedBy: 'Bicep'
  CostCenter: 'Innovation'
}

// Resource names with environment suffix
var functionAppName = '${resourcePrefix}-orchestrator-${environment}-${uniqueSuffix}'
var storageAccountName = replace('${resourcePrefix}store${environment}${uniqueSuffix}', '-', '')
var appInsightsName = '${resourcePrefix}-insights-${environment}'
var cosmosDbAccountName = '${resourcePrefix}-patterns-${environment}-${uniqueSuffix}'
var cosmosDbDatabaseName = 'PatternLibrary'
var logAnalyticsName = '${resourcePrefix}-logs-${environment}'

// ============================================================================
// STORAGE ACCOUNT (for function app and state management)
// ============================================================================

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: take(storageAccountName, 24) // Storage account names max 24 chars
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
    encryption: {
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
        table: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }

  // Table Storage for workflow state management
  resource tableService 'tableServices@2023-01-01' = {
    name: 'default'

    resource workflowStateTable 'tables@2023-01-01' = {
      name: 'WorkflowState'
    }

    resource executionLogsTable 'tables@2023-01-01' = {
      name: 'ExecutionLogs'
    }

    resource patternCacheTable 'tables@2023-01-01' = {
      name: 'PatternCache'
    }
  }
}

// ============================================================================
// LOG ANALYTICS WORKSPACE
// ============================================================================

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 90
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// ============================================================================
// APPLICATION INSIGHTS
// ============================================================================

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    RetentionInDays: 90
    IngestionMode: 'LogAnalytics'
  }
}

// ============================================================================
// COSMOS DB (Pattern Learning Database)
// ============================================================================

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2023-11-15' = {
  name: cosmosDbAccountName
  location: location
  tags: tags
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
  }
}

resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-11-15' = {
  parent: cosmosDbAccount
  name: cosmosDbDatabaseName
  properties: {
    resource: {
      id: cosmosDbDatabaseName
    }
  }
}

// Pattern Library Container
resource patternContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-11-15' = {
  parent: cosmosDb
  name: 'Patterns'
  properties: {
    resource: {
      id: 'Patterns'
      partitionKey: {
        paths: [
          '/patternType'
        ]
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
    }
  }
}

// Build History Container (for pattern learning)
resource buildHistoryContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-11-15' = {
  parent: cosmosDb
  name: 'BuildHistory'
  properties: {
    resource: {
      id: 'BuildHistory'
      partitionKey: {
        paths: [
          '/buildId'
        ]
        kind: 'Hash'
      }
    }
  }
}

// ============================================================================
// FUNCTION APP (Consumption Plan)
// ============================================================================

resource hostingPlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: '${functionAppName}-plan'
  location: location
  tags: tags
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}

resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: functionAppName
  location: location
  tags: tags
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${az.environment().suffixes.storage}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${az.environment().suffixes.storage}'
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
          value: 'node'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~18'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        // Cosmos DB Connection
        {
          name: 'COSMOS_DB_ENDPOINT'
          value: cosmosDbAccount.properties.documentEndpoint
        }
        {
          name: 'COSMOS_DB_KEY'
          value: cosmosDbAccount.listKeys().primaryMasterKey
        }
        {
          name: 'COSMOS_DB_DATABASE_NAME'
          value: cosmosDbDatabaseName
        }
        // Table Storage Connection
        {
          name: 'TABLE_STORAGE_CONNECTION_STRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${az.environment().suffixes.storage}'
        }
        // Notion Configuration
        {
          name: 'NOTION_WORKSPACE_ID'
          value: notionWorkspaceId
        }
        {
          name: 'NOTION_API_KEY'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}${az.environment().suffixes.keyvaultDns}/secrets/notion-api-key/)'
        }
        // GitHub Configuration
        {
          name: 'GITHUB_ORGANIZATION'
          value: githubOrganization
        }
        {
          name: 'GITHUB_PERSONAL_ACCESS_TOKEN'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}${az.environment().suffixes.keyvaultDns}/secrets/github-personal-access-token/)'
        }
        // Azure Configuration
        {
          name: 'AZURE_TENANT_ID'
          value: subscription().tenantId
        }
        {
          name: 'AZURE_SUBSCRIPTION_ID'
          value: subscription().subscriptionId
        }
      ]
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      cors: {
        allowedOrigins: [
          'https://api.notion.com'
          'https://www.notion.so'
        ]
      }
    }
    httpsOnly: true
  }
}

// ============================================================================
// KEY VAULT ACCESS POLICY
// Grant Function App access to secrets
// ============================================================================

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: functionApp.identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output functionAppName string = functionApp.name
output functionAppUrl string = 'https://${functionApp.properties.defaultHostName}'
output webhookEndpoint string = 'https://${functionApp.properties.defaultHostName}/api/notion-webhook'
output cosmosDbEndpoint string = cosmosDbAccount.properties.documentEndpoint
output storageAccountName string = storageAccount.name
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output resourceGroupName string = resourceGroup().name
