
param location string
param prefix string
param keyVaultName string
param appInsights1ConnectionString string
param serviceBusKeyVaultUri string
param storageKeyVaultUri string
param cosmosDbKeyVaultUri string

param webHostingPlanName string = '${prefix}-web-app-asp-${uniqueString(resourceGroup().id)}'
param webAppName string = '${prefix}-web-api-${uniqueString(resourceGroup().id)}'
param webApiName string = '${prefix}-web-app-${uniqueString(resourceGroup().id)}'
param functionHostingPlan1Name string = '${prefix}-func-asp-01-${uniqueString(resourceGroup().id)}'
param function1AppName string = '${prefix}-func-app-01-${uniqueString(resourceGroup().id)}'
param functionHostingPlan2Name string = '${prefix}-func-asp-02-${uniqueString(resourceGroup().id)}'
param function2AppName string = '${prefix}-func-app-02-${uniqueString(resourceGroup().id)}'

resource webHostingPlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: webHostingPlanName
  location: location
  sku: {
    name: 'S1'
    tier: 'Standard'
  }
  properties: {}
}

resource webApi 'Microsoft.Web/sites@2022-09-01' = {
  name: webApiName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: webHostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights1ConnectionString  
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'  
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'recommended'  
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_PreemptSdk'
          value: '1'  
        }
      ]
      connectionStrings: [
        {
          name: 'CosmosDB'
          type: 'Custom'
          connectionString: '@Microsoft.KeyVault(SecretUri=${cosmosDbKeyVaultUri})'
        }
        {
          name: 'BlobStorage'
          type: 'Custom'
          connectionString: '@Microsoft.KeyVault(SecretUri=${storageKeyVaultUri})'
        }
      ]
      cors: {
        allowedOrigins: [
          '*'
        ]
      }
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      use32BitWorkerProcess: false
      netFrameworkVersion: '6.0'
      functionsRuntimeScaleMonitoringEnabled: false
    }
    
    httpsOnly: true
  }
}

resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: webHostingPlan.id
    siteConfig: {
      cors: {
        allowedOrigins: [
          '*'
        ]
      }
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      use32BitWorkerProcess: false
      netFrameworkVersion: '6.0'
      functionsRuntimeScaleMonitoringEnabled: false
    }
    
    httpsOnly: true
  }
}

resource functionHostingPlan1 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: functionHostingPlan1Name
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}

resource functionHostingPlan2 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: functionHostingPlan2Name
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}

resource functionApp1 'Microsoft.Web/sites@2022-03-01' = {
  name: function1AppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: functionHostingPlan1.id
    siteConfig: {
      connectionStrings: [
        {
          name: 'ServiceBus'
          type: 'Custom'
          connectionString: '@Microsoft.KeyVault(SecretUri=${serviceBusKeyVaultUri})'
        }
      ]
      cors: {
        allowedOrigins: [
          '*'
        ]
      }
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      use32BitWorkerProcess: false
      netFrameworkVersion: '6.0'
    }
    
    httpsOnly: true
  }
}

resource functionApp2 'Microsoft.Web/sites@2022-03-01' = {
  name: function2AppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: functionHostingPlan2.id
    siteConfig: {
      connectionStrings: [
        {
          name: 'CosmosDB'
          type: 'Custom'
          connectionString: '@Microsoft.KeyVault(SecretUri=${cosmosDbKeyVaultUri})'
        }
        {
          name: 'ServiceBus'
          type: 'Custom'
          connectionString: '@Microsoft.KeyVault(SecretUri=${serviceBusKeyVaultUri})'
        }
      ]
      cors: {
        allowedOrigins: [
          '*'
        ]
      }
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      use32BitWorkerProcess: false
      netFrameworkVersion: '6.0'
    }
    
    httpsOnly: true
  }
}

// need to grant access to KeyVault for Logic App first before we can set the app settings
module keyVaultAccessPolicyModule './keyVaultAccessPolicy.bicep' = { 
  name: 'keyVaultAccessPolicyModule'
  params: {
    keyVaultName: keyVaultName
    applicationIds: [webApi.identity.principalId, webApp.identity.principalId, functionApp1.identity.principalId, functionApp2.identity.principalId]
  }
}

resource function1Settings 'Microsoft.Web/sites/config@2022-09-01' = {
  parent: functionApp1
  name: 'appsettings'
  dependsOn: [
    keyVaultAccessPolicyModule
  ]
  properties: {
    AzureWebJobsStorage: '@Microsoft.KeyVault(SecretUri=${storageKeyVaultUri})'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: '@Microsoft.KeyVault(SecretUri=${storageKeyVaultUri})'
    WEBSITE_CONTENTSHARE: toLower(function1AppName)
    FUNCTIONS_EXTENSION_VERSION: '~4'
    APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights1ConnectionString
    FUNCTIONS_WORKER_RUNTIME: 'dotnet'
  }
}

resource function2Settings 'Microsoft.Web/sites/config@2022-09-01' = {
  parent: functionApp2
  name: 'appsettings'
  dependsOn: [
    keyVaultAccessPolicyModule
  ]
  properties: {
    AzureWebJobsStorage: '@Microsoft.KeyVault(SecretUri=${storageKeyVaultUri})'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: '@Microsoft.KeyVault(SecretUri=${storageKeyVaultUri})'
    WEBSITE_CONTENTSHARE: toLower(function2AppName)
    FUNCTIONS_EXTENSION_VERSION: '~4'
    APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights1ConnectionString
    FUNCTIONS_WORKER_RUNTIME: 'dotnet'
  }
}
