// Brookside BI Repository Analyzer - Azure Infrastructure
// Establishes serverless infrastructure for automated weekly repository scanning

targetScope = 'resourceGroup'

@description('Environment name (dev, prod)')
@allowed(['dev', 'prod'])
param environment string = 'prod'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Existing Key Vault name for secrets')
param keyVaultName string = 'kv-brookside-secrets'

@description('GitHub organization name')
param githubOrg string = 'brookside-bi'

@description('Notion workspace ID')
param notionWorkspaceId string = '81686779-099a-8195-b49e-00037e25c23e'

// Resource naming conventions
var functionAppName = 'func-repo-analyzer-${environment}'
var appServicePlanName = 'plan-repo-analyzer-${environment}'
var storageAccountName = 'strepoanalyzer${environment}'
var appInsightsName = 'appi-repo-analyzer-${environment}'

// Tags for resource organization
var tags = {
  Environment: environment
  Project: 'Brookside BI Innovation Nexus'
  Component: 'Repository Analyzer'
  ManagedBy: 'Bicep'
  CostCenter: 'Engineering'
}

// Storage Account for Function App
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    accessTier: 'Hot'
    encryption: {
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

// Application Insights for monitoring and observability
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
    RetentionInDays: 30
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Consumption App Service Plan (Linux)
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// Function App with System-Assigned Managed Identity
resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  location: location
  tags: tags
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.11'
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
          value: 'python'
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
          name: 'GITHUB_ORG'
          value: githubOrg
        }
        {
          name: 'NOTION_WORKSPACE_ID'
          value: notionWorkspaceId
        }
        {
          name: 'PYTHON_ENABLE_WORKER_EXTENSIONS'
          value: '1'
        }
      ]
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      alwaysOn: false // Consumption plan doesn't support alwaysOn
      http20Enabled: true
      functionAppScaleLimit: 10 // Max instances for cost control
    }
    httpsOnly: true
  }
}

// Reference existing Key Vault (created separately)
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

// Grant Function App "Key Vault Secrets User" role
resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, functionApp.id, 'Key Vault Secrets User')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User
    )
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Metric Alert: Function execution failures
resource functionFailureAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${functionAppName}-failures'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when repository analyzer function executes with errors'
    severity: 2 // Warning severity
    enabled: true
    scopes: [
      functionApp.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'FunctionErrors'
          metricName: 'FunctionExecutionErrors'
          operator: 'GreaterThan'
          threshold: 0
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
  }
}

// Metric Alert: Long execution duration (>9 min)
resource longExecutionAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${functionAppName}-long-execution'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when function execution exceeds 9 minutes (approaching timeout)'
    severity: 3 // Informational
    enabled: true
    scopes: [
      functionApp.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'LongExecution'
          metricName: 'FunctionExecutionUnits'
          operator: 'GreaterThan'
          threshold: 540000 // 9 minutes in milliseconds
          timeAggregation: 'Maximum'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
  }
}

// Outputs for deployment validation
output functionAppName string = functionApp.name
output functionAppUrl string = 'https://${functionApp.properties.defaultHostName}'
output functionAppPrincipalId string = functionApp.identity.principalId
output storageAccountName string = storageAccount.name
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output keyVaultUri string = keyVault.properties.vaultUri
