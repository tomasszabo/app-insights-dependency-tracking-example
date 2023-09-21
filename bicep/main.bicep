@description('Azure location where resources should be deployed (e.g., westeurope)')
param location string = 'westeurope'
param prefix string = 'as'

module sharedModule './shared.bicep' = {
  name: 'sharedModule'
  params: {
    location: location
    prefix: prefix
  }
}

module keyVaultModule './keyVault.bicep' = {
  name: 'keyVaultModule'
  params: {
    location: location
    prefix: prefix
  }
}

module databaseModule './database.bicep' = {
  name: 'databaseModule'
  params: {
    location: location
    prefix: prefix
    keyVaultName: keyVaultModule.outputs.keyVaultName
  }
}

module serviceBusModule './serviceBus.bicep' = {
  name: 'serviceBusModule'
  dependsOn: [
    keyVaultModule
  ]
  params: {
    location: location
    prefix: prefix
    keyVaultName: keyVaultModule.outputs.keyVaultName
  }
}

module storageModule './storage.bicep' = {
  name: 'storageModule'
  dependsOn: [
    keyVaultModule
  ]
  params: {
    location: location
    prefix: prefix
    keyVaultName: keyVaultModule.outputs.keyVaultName
  }
}

module computeModule './compute.bicep' = {
  name: 'computeModule'
  dependsOn: [
    sharedModule
  ]
  params: {
    location: location
    prefix: prefix
    keyVaultName: keyVaultModule.outputs.keyVaultName
    appInsights1ConnectionString: sharedModule.outputs.appInsights1ConnectionString
    serviceBusKeyVaultUri: serviceBusModule.outputs.connectionStringKeyVaultUri
    storageKeyVaultUri: storageModule.outputs.connectionStringKeyVaultUri
    cosmosDbKeyVaultUri: databaseModule.outputs.connectionStringKeyVaultUri
  }
}
