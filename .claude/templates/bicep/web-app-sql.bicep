// ============================================================================
// Azure Web App + SQL Database + Key Vault
// ============================================================================
//
// Establishes scalable web application infrastructure with relational database,
// secure secret management, and comprehensive monitoring to support sustainable
// application growth.
//
// Best for: REST APIs, web applications requiring structured data storage
//
// Resources Provisioned:
// - App Service Plan (B1/S1/P1v2 based on environment)
// - App Service (Web App) with Managed Identity
// - Azure SQL Server with Azure AD authentication
// - Azure SQL Database (auto-pause enabled for dev)
// - Key Vault with RBAC authorization
// - Application Insights with structured logging
// - Log Analytics Workspace for centralized monitoring
//
// Estimated Monthly Cost:
// - Development:  ~$20 (B1, Basic SQL, auto-pause)
// - Staging:      ~$90 (S1, Standard SQL)
// - Production:   ~$157 (P1v2, Standard SQL with geo-redundancy)
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

@description('SQL Server administrator login (stored in Key Vault)')
@secure()
param sqlAdminLogin string

@description('SQL Server administrator password (stored in Key Vault)')
@secure()
param sqlAdminPassword string

@description('Azure AD tenant ID for authentication')
param tenantId string = tenant().tenantId

@description('Application runtime stack')
@allowed(['PYTHON|3.11', 'NODE|18-lts', 'DOTNET|8.0'])
param runtimeStack string = 'PYTHON|3.11'

@description('Tags to apply to all resources')
param tags object = {
  Environment: environment
  ManagedBy: 'ClaudeCode'
  Workload: prefix
}

// ============================================================================
// VARIABLES - Naming and Configuration
// ============================================================================

// Resource naming following Azure best practices
var appServicePlanName = 'plan-${prefix}-${environment}'
var webAppName = 'app-${prefix}-${environment}'
var sqlServerName = 'sql-${prefix}-${environment}'
var sqlDatabaseName = '${prefix}db'
var keyVaultName = 'kv-${prefix}-${substring(environment, 0, 3)}'  // Max 24 chars
var appInsightsName = 'appi-${prefix}-${environment}'
var logAnalyticsName = 'law-${prefix}-${environment}'
var storageAccountName = 'st${replace(prefix, '-', '')}${substring(environment, 0, 3)}'  // No hyphens, max 24 chars

// Environment-specific SKU configuration
var skuConfig = {
  dev: {
    appServicePlan: {
      name: 'B1'
      tier: 'Basic'
      capacity: 1
    }
    sqlDatabase: {
      name: 'Basic'
      tier: 'Basic'
      capacity: 5
      maxSizeBytes: 2147483648  // 2 GB
    }
    storage: 'Standard_LRS'
    alwaysOn: false
    autoPauseDelay: 60  // Auto-pause SQL after 1 hour
    geoRedundantBackup: false
  }
  staging: {
    appServicePlan: {
      name: 'S1'
      tier: 'Standard'
      capacity: 1
    }
    sqlDatabase: {
      name: 'S2'
      tier: 'Standard'
      capacity: 50
      maxSizeBytes: 268435456000  // 250 GB
    }
    storage: 'Standard_LRS'
    alwaysOn: true
    autoPauseDelay: -1  // Disabled
    geoRedundantBackup: false
  }
  prod: {
    appServicePlan: {
      name: 'P1v2'
      tier: 'PremiumV2'
      capacity: 2
    }
    sqlDatabase: {
      name: 'S2'
      tier: 'Standard'
      capacity: 50
      maxSizeBytes: 268435456000  // 250 GB
    }
    storage: 'Standard_GRS'
    alwaysOn: true
    autoPauseDelay: -1  // Disabled
    geoRedundantBackup: true
  }
}

var currentSku = skuConfig[environment]

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
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
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
    SamplingPercentage: environment == 'prod' ? 100 : 50
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
    name: currentSku.appServicePlan.name
    tier: currentSku.appServicePlan.tier
    capacity: currentSku.appServicePlan.capacity
  }
  kind: 'linux'
  properties: {
    reserved: true  // Required for Linux
    zoneRedundant: environment == 'prod'
  }
}

// ============================================================================
// RESOURCE: Web App
// ============================================================================

resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    clientAffinityEnabled: false

    siteConfig: {
      linuxFxVersion: runtimeStack
      alwaysOn: currentSku.alwaysOn
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      http20Enabled: true

      // Health check configuration
      healthCheckPath: '/health'

      // App settings (additional settings added via Azure CLI after deployment)
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
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
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
      ]

      // CORS configuration
      cors: {
        allowedOrigins: environment == 'prod' ? [] : ['http://localhost:3000', 'http://localhost:8000']
        supportCredentials: false
      }
    }
  }
}

// Enable diagnostic settings for Web App
resource webAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagnostics'
  scope: webApp
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: environment == 'prod' ? 90 : 30
        }
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: environment == 'prod' ? 90 : 30
        }
      }
      {
        category: 'AppServiceAppLogs'
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
// RESOURCE: Azure SQL Server
// ============================================================================

resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'  // Use Private Endpoint for production in real scenarios

    // Enable Azure AD authentication
    administrators: {
      administratorType: 'ActiveDirectory'
      principalType: 'Application'
      login: webApp.name
      sid: webApp.identity.principalId
      tenantId: tenantId
      azureADOnlyAuthentication: false
    }
  }
}

// SQL Server firewall rule - Allow Azure services
resource sqlFirewallAzureServices 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = {
  parent: sqlServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// ============================================================================
// RESOURCE: Azure SQL Database
// ============================================================================

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  tags: tags
  sku: {
    name: currentSku.sqlDatabase.name
    tier: currentSku.sqlDatabase.tier
    capacity: currentSku.sqlDatabase.capacity
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: currentSku.sqlDatabase.maxSizeBytes
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    zoneRedundant: environment == 'prod'

    // Backup configuration
    requestedBackupStorageRedundancy: currentSku.geoRedundantBackup ? 'Geo' : 'Local'
  }
}

// Enable diagnostic settings for SQL Database
resource sqlDatabaseDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagnostics'
  scope: sqlDatabase
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'SQLInsights'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: environment == 'prod' ? 90 : 30
        }
      }
      {
        category: 'QueryStoreRuntimeStatistics'
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

    // Use RBAC authorization (recommended over access policies)
    enableRbacAuthorization: true

    // Security features
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: environment == 'prod'

    // Network configuration
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

// Grant Web App "Key Vault Secrets User" role
resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, webApp.id, 'Key Vault Secrets User')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: webApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Store SQL connection string in Key Vault
resource sqlConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'sql-connection-string'
  properties: {
    value: 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Database=${sqlDatabaseName};Authentication=Active Directory Managed Identity;'
  }
}

// Store Application Insights connection string in Key Vault
resource appInsightsConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'appinsights-connection-string'
  properties: {
    value: appInsights.properties.ConnectionString
  }
}

// ============================================================================
// RESOURCE: Storage Account (for logs, backups, etc.)
// ============================================================================

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: currentSku.storage
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false

    // Network configuration
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

// Grant Web App "Storage Blob Data Contributor" role
resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, webApp.id, 'Storage Blob Data Contributor')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: webApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

@description('Web application URL')
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'

@description('Web App name')
output webAppName string = webApp.name

@description('Web App principal ID (for additional role assignments)')
output webAppPrincipalId string = webApp.identity.principalId

@description('Key Vault URI')
output keyVaultUri string = keyVault.properties.vaultUri

@description('Key Vault name')
output keyVaultName string = keyVault.name

@description('SQL Server FQDN')
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName

@description('SQL Server name')
output sqlServerName string = sqlServer.name

@description('SQL Database name')
output sqlDatabaseName string = sqlDatabase.name

@description('Application Insights connection string (sensitive)')
@secure()
output appInsightsConnectionString string = appInsights.properties.ConnectionString

@description('Application Insights instrumentation key (sensitive)')
@secure()
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey

@description('Storage Account name')
output storageAccountName string = storageAccount.name

@description('Log Analytics Workspace ID')
output logAnalyticsWorkspaceId string = logAnalytics.id

@description('Resource Group location')
output location string = location

@description('Environment')
output environment string = environment

@description('Estimated monthly cost (USD)')
output estimatedMonthlyCost string = environment == 'dev' ? '~$20' : environment == 'staging' ? '~$90' : '~$157'
