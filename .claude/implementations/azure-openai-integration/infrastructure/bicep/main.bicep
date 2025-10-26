// ============================================================================
// Azure OpenAI Integration - Main Bicep Template
// Establish scalable AI infrastructure for Brookside BI Innovation Nexus
// Best for: Organizations deploying Azure OpenAI with enterprise security
// ============================================================================

targetScope = 'resourceGroup'

// ============================================================================
// PARAMETERS
// ============================================================================

@description('Environment name for resource naming and configuration')
@allowed(['dev', 'staging', 'prod'])
param environment string

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Resource name prefix (organization identifier)')
@minLength(3)
@maxLength(10)
param prefix string = 'brookside'

@description('Azure OpenAI model deployment configuration')
param modelDeployment object = {
  modelName: 'gpt-4'
  modelVersion: '0125-preview'
  deploymentName: 'gpt-4-turbo'
  scaleType: 'Standard'
  capacity: environment == 'prod' ? 30 : 10
}

@description('Enable diagnostic logging to Log Analytics Workspace')
param enableDiagnostics bool = true

@description('Log Analytics Workspace resource ID for diagnostic logs')
param logAnalyticsWorkspaceId string = ''

@description('Enable private endpoint for network isolation (production only)')
param enablePrivateEndpoint bool = false

@description('Virtual Network subnet resource ID for private endpoint')
param subnetId string = ''

@description('Budget alert threshold amounts in USD')
param budgetAlerts object = {
  threshold50: 50
  threshold75: 75
  threshold90: 100
}

@description('Resource tags for cost tracking and governance')
param tags object = {
  Environment: environment
  ManagedBy: 'ClaudeCode'
  Project: 'InnovationNexus'
  CostCenter: 'Engineering'
  Workload: 'AI-Integration'
}

// ============================================================================
// VARIABLES
// ============================================================================

// Consistent naming convention: {service}-{prefix}-{environment}-{region}
var aoaiAccountName = 'aoai-${prefix}-${environment}-${location}'
var managedIdentityName = 'id-${prefix}-aoai-${environment}'
var privateEndpointName = 'pe-${prefix}-aoai-${environment}'
var budgetName = 'budget-aoai-${environment}'

// SKU selection based on environment
var aoaiSku = environment == 'prod' ? {
  name: 'S0'  // Standard pay-as-you-go
  tier: 'Standard'
} : {
  name: 'S0'  // Same SKU, different capacity limits
  tier: 'Standard'
}

// Network access configuration
var publicNetworkAccess = enablePrivateEndpoint ? 'Disabled' : 'Enabled'

// ============================================================================
// RESOURCES
// ============================================================================

// Managed Identity for Azure OpenAI Service
// Establishes secure authentication without credentials for application access
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
  tags: tags
}

// Azure OpenAI Service Account
// Core AI infrastructure with GPT-4 Turbo deployment for innovation workflows
resource azureOpenAI 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: aoaiAccountName
  location: location
  kind: 'OpenAI'
  sku: aoaiSku
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    customSubDomainName: aoaiAccountName
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      defaultAction: enablePrivateEndpoint ? 'Deny' : 'Allow'
      ipRules: []
      virtualNetworkRules: []
    }
    disableLocalAuth: true  // Enforce Azure AD authentication only
    restrictOutboundNetworkAccess: false
  }
}

// GPT-4 Turbo Model Deployment
// Production-ready GPT-4 Turbo deployment with environment-specific capacity
resource modelDeploymentResource 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: azureOpenAI
  name: modelDeployment.deploymentName
  sku: {
    name: modelDeployment.scaleType
    capacity: modelDeployment.capacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: modelDeployment.modelName
      version: modelDeployment.modelVersion
    }
    raiPolicyName: 'Microsoft.Default'  // Responsible AI content filtering
  }
}

// RBAC Role Assignment: Cognitive Services OpenAI User
// Grant managed identity least-privilege access to Azure OpenAI Service
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(azureOpenAI.id, managedIdentity.id, 'CognitiveServicesOpenAIUser')
  scope: azureOpenAI
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd')  // Cognitive Services OpenAI User
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Diagnostic Settings
// Stream logs and metrics to Log Analytics for monitoring and troubleshooting
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics && !empty(logAnalyticsWorkspaceId)) {
  name: 'diag-${aoaiAccountName}'
  scope: azureOpenAI
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
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

// Private Endpoint (Optional - Production Only)
// Establishes network isolation for Azure OpenAI Service
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = if (enablePrivateEndpoint && !empty(subnetId)) {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointName}-connection'
        properties: {
          privateLinkServiceId: azureOpenAI.id
          groupIds: ['account']
        }
      }
    ]
  }
}

// Budget Alert
// Monitor Azure OpenAI costs with proactive alerting at configurable thresholds
resource budget 'Microsoft.Consumption/budgets@2023-05-01' = {
  name: budgetName
  properties: {
    timePeriod: {
      startDate: '2025-01-01'
      endDate: '2026-12-31'
    }
    timeGrain: 'Monthly'
    amount: budgetAlerts.threshold90
    category: 'Cost'
    notifications: {
      Actual_50_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 50
        contactEmails: [
          'consultations@brooksidebi.com'
        ]
        thresholdType: 'Actual'
      }
      Actual_75_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 75
        contactEmails: [
          'consultations@brooksidebi.com'
        ]
        thresholdType: 'Actual'
      }
      Actual_90_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 90
        contactEmails: [
          'consultations@brooksidebi.com'
        ]
        thresholdType: 'Actual'
      }
    }
    filter: {
      dimensions: {
        name: 'ResourceId'
        operator: 'In'
        values: [
          azureOpenAI.id
        ]
      }
    }
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

@description('Azure OpenAI Service resource ID')
output azureOpenAIId string = azureOpenAI.id

@description('Azure OpenAI Service endpoint URL')
output azureOpenAIEndpoint string = azureOpenAI.properties.endpoint

@description('Azure OpenAI Service account name')
output azureOpenAIName string = azureOpenAI.name

@description('Managed Identity principal ID for RBAC assignments')
output managedIdentityPrincipalId string = managedIdentity.properties.principalId

@description('Managed Identity client ID for application configuration')
output managedIdentityClientId string = managedIdentity.properties.clientId

@description('Managed Identity resource ID')
output managedIdentityId string = managedIdentity.id

@description('GPT-4 Turbo deployment name for API calls')
output deploymentName string = modelDeploymentResource.name

@description('Private endpoint resource ID (if enabled)')
output privateEndpointId string = enablePrivateEndpoint ? privateEndpoint.id : ''

@description('Budget resource ID for cost tracking')
output budgetId string = budget.id
