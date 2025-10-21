/**
 * Deploy to Azure Activity Function
 *
 * Establishes automated infrastructure provisioning and application deployment
 * to Azure, streamlining cloud resource creation from architecture specifications.
 *
 * This solution is designed to support Infrastructure as Code practices where
 * Bicep templates are generated programmatically and deployed with proper
 * monitoring, identity management, and cost tracking.
 *
 * Best for: Organizations requiring scalable Azure deployment automation with
 * standardized resource configurations and governance compliance.
 */

const { exec } = require('child_process');
const { promisify } = require('util');
const fs = require('fs').promises;
const path = require('path');
const execAsync = promisify(exec);

/**
 * Main Activity Function
 *
 * @param {object} context - Durable Functions activity context
 * @returns {object} Deployment result with resource URLs
 */
module.exports = async function (context) {
  const input = context.bindings.context;
  const { architecture, buildName, repositoryUrl } = input;

  context.log('Deploying to Azure', {
    buildName,
    architectureType: architecture.details?.type || 'unknown'
  });

  try {
    // Sanitize names for Azure resources (alphanumeric, hyphens only)
    const resourcePrefix = sanitizeAzureName(buildName);
    const resourceGroupName = `rg-${resourcePrefix}`;
    const location = process.env.AZURE_LOCATION || 'eastus';
    const subscriptionId = process.env.AZURE_SUBSCRIPTION_ID;

    if (!subscriptionId) {
      throw new Error('AZURE_SUBSCRIPTION_ID not configured in environment');
    }

    // Verify Azure CLI authentication
    await verifyAzureCLI(context);

    // Set active subscription
    await execAsync(`az account set --subscription ${subscriptionId}`);

    // Create resource group
    await createResourceGroup(resourceGroupName, location, context);

    // Generate Bicep template from architecture
    const bicepTemplate = generateBicepTemplate(architecture, resourcePrefix, location);
    const bicepFilePath = `/tmp/${resourcePrefix}-infrastructure.bicep`;
    await fs.writeFile(bicepFilePath, bicepTemplate);

    context.log('Bicep template generated', {
      filePath: bicepFilePath,
      size: bicepTemplate.length
    });

    // Deploy infrastructure
    const deploymentResult = await deployBicepTemplate(
      resourceGroupName,
      bicepFilePath,
      resourcePrefix,
      context
    );

    // Extract deployed resource details
    const deployedResources = parseDeploymentOutputs(deploymentResult.outputs);

    // Configure application settings
    if (deployedResources.appServiceName) {
      await configureAppSettings(
        resourceGroupName,
        deployedResources.appServiceName,
        repositoryUrl,
        context
      );
    }

    // Set up continuous deployment from GitHub (if applicable)
    if (repositoryUrl && deployedResources.appServiceName) {
      await configureContinuousDeployment(
        resourceGroupName,
        deployedResources.appServiceName,
        repositoryUrl,
        context
      );
    }

    // Clean up temporary files
    await fs.unlink(bicepFilePath).catch(() => {});

    context.log('Azure deployment complete', {
      resourceGroupName,
      deployedResources
    });

    return {
      success: true,
      resourceGroupName,
      location,
      deployedResources,
      deploymentName: deploymentResult.name,
      subscriptionId
    };

  } catch (error) {
    context.log.error('Azure deployment failed', {
      error: error.message,
      stack: error.stack,
      buildName
    });

    return {
      success: false,
      error: error.message,
      buildName
    };
  }
};

/**
 * Sanitize Azure Name
 *
 * Converts name to Azure-compliant format (alphanumeric and hyphens).
 *
 * @param {string} name - Original name
 * @returns {string} Sanitized Azure-compliant name
 */
function sanitizeAzureName(name) {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9-]/g, '-')
    .replace(/--+/g, '-')
    .replace(/^-|-$/g, '')
    .substring(0, 50);  // Azure resource name length limits
}

/**
 * Verify Azure CLI
 *
 * Ensures Azure CLI is installed and authenticated.
 *
 * @param {object} context - Function context
 */
async function verifyAzureCLI(context) {
  try {
    const { stdout } = await execAsync('az account show');
    const account = JSON.parse(stdout);
    context.log('Azure CLI authenticated', {
      user: account.user.name,
      subscription: account.name
    });
  } catch (error) {
    throw new Error('Azure CLI not authenticated. Run "az login" first.');
  }
}

/**
 * Create Resource Group
 *
 * Establishes Azure resource group for infrastructure deployment.
 *
 * @param {string} resourceGroupName - Resource group name
 * @param {string} location - Azure region
 * @param {object} context - Function context
 */
async function createResourceGroup(resourceGroupName, location, context) {
  try {
    // Check if resource group exists
    await execAsync(`az group show --name ${resourceGroupName}`);
    context.log('Resource group already exists', { resourceGroupName });
  } catch (error) {
    // Create if doesn't exist
    context.log('Creating resource group', { resourceGroupName, location });
    await execAsync(`az group create --name ${resourceGroupName} --location ${location}`);
    context.log('Resource group created successfully');
  }
}

/**
 * Generate Bicep Template
 *
 * Constructs Infrastructure as Code template from architecture specification.
 *
 * @param {object} architecture - Architecture specification
 * @param {string} resourcePrefix - Resource name prefix
 * @param {string} location - Azure region
 * @returns {string} Bicep template content
 */
function generateBicepTemplate(architecture, resourcePrefix, location) {
  // Determine deployment pattern based on architecture
  const deploymentType = detectDeploymentType(architecture);

  let bicep = `// ${resourcePrefix} Infrastructure
// Generated automatically by Brookside BI Innovation Platform

param location string = '${location}'
param resourcePrefix string = '${resourcePrefix}'

`;

  if (deploymentType === 'app-service') {
    bicep += generateAppServiceBicep(resourcePrefix);
  } else if (deploymentType === 'function-app') {
    bicep += generateFunctionAppBicep(resourcePrefix);
  } else if (deploymentType === 'container-app') {
    bicep += generateContainerAppBicep(resourcePrefix);
  } else {
    // Default to App Service
    bicep += generateAppServiceBicep(resourcePrefix);
  }

  // Always include Application Insights for monitoring
  bicep += generateApplicationInsightsBicep(resourcePrefix);

  // Include storage if needed
  if (architecture.details?.requiresStorage || deploymentType === 'function-app') {
    bicep += generateStorageAccountBicep(resourcePrefix);
  }

  // Include database if specified
  if (architecture.details?.database) {
    if (architecture.details.database === 'cosmos') {
      bicep += generateCosmosDBBicep(resourcePrefix);
    } else if (architecture.details.database === 'sql') {
      bicep += generateSQLDatabaseBicep(resourcePrefix);
    }
  }

  // Output deployed resource details
  bicep += generateBicepOutputs(deploymentType);

  return bicep;
}

/**
 * Detect Deployment Type
 *
 * Analyzes architecture to determine appropriate Azure service.
 *
 * @param {object} architecture - Architecture specification
 * @returns {string} Deployment type
 */
function detectDeploymentType(architecture) {
  const archText = JSON.stringify(architecture).toLowerCase();

  if (archText.includes('function') || archText.includes('serverless')) {
    return 'function-app';
  }
  if (archText.includes('container') || archText.includes('docker')) {
    return 'container-app';
  }
  return 'app-service'; // Default
}

/**
 * Generate App Service Bicep
 */
function generateAppServiceBicep(resourcePrefix) {
  return `
// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'asp-\${resourcePrefix}'
  location: location
  sku: {
    name: 'B1'  // Basic tier for cost optimization
    tier: 'Basic'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// App Service
resource appService 'Microsoft.Web/sites@2022-09-01' = {
  name: 'app-\${resourcePrefix}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|18-lts'
      alwaysOn: false
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '18-lts'
        }
      ]
    }
  }
}

`;
}

/**
 * Generate Function App Bicep
 */
function generateFunctionAppBicep(resourcePrefix) {
  return `
// Function App Service Plan
resource functionAppPlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'asp-\${resourcePrefix}-func'
  location: location
  sku: {
    name: 'Y1'  // Consumption plan
    tier: 'Dynamic'
  }
}

// Function App
resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: 'func-\${resourcePrefix}'
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: functionAppPlan.id
    httpsOnly: true
    siteConfig: {
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
    }
  }
}

`;
}

/**
 * Generate Container App Bicep
 */
function generateContainerAppBicep(resourcePrefix) {
  return `
// Container Apps Environment
resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: 'cae-\${resourcePrefix}'
  location: location
  properties: {
    zoneRedundant: false
  }
}

// Container App
resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'ca-\${resourcePrefix}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 3000
      }
    }
    template: {
      containers: [
        {
          name: 'app'
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 3
      }
    }
  }
}

`;
}

/**
 * Generate Application Insights Bicep
 */
function generateApplicationInsightsBicep(resourcePrefix) {
  return `
// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-\${resourcePrefix}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

`;
}

/**
 * Generate Storage Account Bicep
 */
function generateStorageAccountBicep(resourcePrefix) {
  return `
// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: 'st\${replace(resourcePrefix, '-', '')}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

`;
}

/**
 * Generate Cosmos DB Bicep
 */
function generateCosmosDBBicep(resourcePrefix) {
  return `
// Cosmos DB Account (Serverless)
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2023-11-15' = {
  name: 'cosmos-\${resourcePrefix}'
  location: location
  properties: {
    databaseAccountOfferType: 'Standard'
    capabilities: [
      { name: 'EnableServerless' }
    ]
    locations: [
      {
        locationName: location
        failoverPriority: 0
      }
    ]
  }
}

`;
}

/**
 * Generate SQL Database Bicep
 */
function generateSQLDatabaseBicep(resourcePrefix) {
  return `
// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: 'sql-\${resourcePrefix}'
  location: location
  properties: {
    administratorLogin: 'sqladmin'
    administratorLoginPassword: uniqueString(resourceGroup().id)
  }
}

// SQL Database (Serverless)
resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: 'db-\${resourcePrefix}'
  location: location
  sku: {
    name: 'GP_S_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 1
  }
  properties: {
    autoPauseDelay: 60
    minCapacity: json('0.5')
  }
}

`;
}

/**
 * Generate Bicep Outputs
 */
function generateBicepOutputs(deploymentType) {
  let outputs = `
output resourceGroupName string = resourceGroup().name
output location string = location
`;

  if (deploymentType === 'app-service') {
    outputs += `output appServiceName string = appService.name
output appServiceUrl string = 'https://\${appService.properties.defaultHostName}'
`;
  } else if (deploymentType === 'function-app') {
    outputs += `output functionAppName string = functionApp.name
output functionAppUrl string = 'https://\${functionApp.properties.defaultHostName}'
`;
  } else if (deploymentType === 'container-app') {
    outputs += `output containerAppName string = containerApp.name
output containerAppUrl string = 'https://\${containerApp.properties.configuration.ingress.fqdn}'
`;
  }

  outputs += `output appInsightsName string = appInsights.name
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
`;

  return outputs;
}

/**
 * Deploy Bicep Template
 *
 * Executes Azure CLI deployment command.
 *
 * @param {string} resourceGroupName - Resource group name
 * @param {string} bicepFilePath - Path to Bicep template
 * @param {string} resourcePrefix - Resource name prefix
 * @param {object} context - Function context
 * @returns {object} Deployment result
 */
async function deployBicepTemplate(resourceGroupName, bicepFilePath, resourcePrefix, context) {
  const deploymentName = `${resourcePrefix}-${Date.now()}`;

  context.log('Deploying Bicep template', {
    deploymentName,
    resourceGroupName
  });

  const { stdout } = await execAsync(
    `az deployment group create --resource-group ${resourceGroupName} --name ${deploymentName} --template-file ${bicepFilePath} --parameters resourcePrefix=${resourcePrefix}`
  );

  const deployment = JSON.parse(stdout);

  context.log('Deployment complete', {
    deploymentName,
    provisioningState: deployment.properties.provisioningState
  });

  return deployment.properties;
}

/**
 * Parse Deployment Outputs
 *
 * Extracts resource details from Bicep deployment outputs.
 *
 * @param {object} outputs - Deployment outputs
 * @returns {object} Parsed resource details
 */
function parseDeploymentOutputs(outputs) {
  const resources = {};

  if (outputs.appServiceName) {
    resources.appServiceName = outputs.appServiceName.value;
    resources.appServiceUrl = outputs.appServiceUrl.value;
  }
  if (outputs.functionAppName) {
    resources.functionAppName = outputs.functionAppName.value;
    resources.functionAppUrl = outputs.functionAppUrl.value;
  }
  if (outputs.containerAppName) {
    resources.containerAppName = outputs.containerAppName.value;
    resources.containerAppUrl = outputs.containerAppUrl.value;
  }
  if (outputs.appInsightsName) {
    resources.appInsightsName = outputs.appInsightsName.value;
    resources.appInsightsInstrumentationKey = outputs.appInsightsInstrumentationKey.value;
  }

  return resources;
}

/**
 * Configure App Settings
 *
 * Sets environment variables and application settings for deployed app.
 *
 * @param {string} resourceGroupName - Resource group name
 * @param {string} appName - App Service or Function App name
 * @param {string} repositoryUrl - GitHub repository URL
 * @param {object} context - Function context
 */
async function configureAppSettings(resourceGroupName, appName, repositoryUrl, context) {
  try {
    const settings = [
      `GITHUB_REPOSITORY=${repositoryUrl}`,
      `DEPLOYMENT_PLATFORM=Brookside-BI-Innovation-Platform`,
      `AUTONOMOUS_BUILD=true`
    ];

    await execAsync(
      `az webapp config appsettings set --resource-group ${resourceGroupName} --name ${appName} --settings ${settings.join(' ')}`
    );

    context.log('App settings configured', { appName });
  } catch (error) {
    context.log.warn('Failed to configure app settings', {
      error: error.message
    });
  }
}

/**
 * Configure Continuous Deployment
 *
 * Sets up GitHub Actions deployment integration (placeholder for future implementation).
 *
 * @param {string} resourceGroupName - Resource group name
 * @param {string} appName - App Service name
 * @param {string} repositoryUrl - GitHub repository URL
 * @param {object} context - Function context
 */
async function configureContinuousDeployment(resourceGroupName, appName, repositoryUrl, context) {
  context.log('Continuous deployment configuration skipped (manual GitHub Actions setup required)', {
    appName,
    repositoryUrl
  });
  // Future: Configure GitHub Actions workflow with publish profile
}
