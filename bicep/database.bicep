
param keyVaultName string
param location string
param prefix string

param databaseAccountName string = '${prefix}-cosmos-db-${uniqueString(resourceGroup().id)}'
param databaseName string = 'function-test'
param containerName string = 'Messages'

var locations = [
  {
    locationName: location
    failoverPriority: 0
    isZoneRedundant: false
  }
]

resource databaseAccount 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' = {
  name: databaseAccountName
  kind: 'GlobalDocumentDB'
  location: location
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: locations
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2022-05-15' = {
  name: databaseName
  parent: databaseAccount
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-05-15' = {
  name: containerName
  parent: database
  properties: {
    resource: {
      id: containerName
      partitionKey: {
        paths: [
          '/id'
        ]
        kind: 'Hash'
      }
    }
    options: {
      autoscaleSettings: {
        maxThroughput: 1000
      }
    }
  }
}

module connectionStringSecret 'keyVaultSecret.bicep' = {
  name: 'cosmosKeyVaultSecretPrimaryConnectionString'
  params: {
    keyVaultName: keyVaultName
    secretName: '${databaseAccountName}-PrimaryConnectionString'
    secretValue: databaseAccount.listConnectionStrings().connectionStrings[0].connectionString
  }
}

output connectionStringKeyVaultUri string = connectionStringSecret.outputs.keyVaultSecretUri
