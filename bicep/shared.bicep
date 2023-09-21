
param location string
param prefix string

param logAnalyticsWorkspace1Name string = '${prefix}-loganalytics-1-${uniqueString(resourceGroup().id)}'
param appInsights1Name string = '${prefix}-appinsights-1-${uniqueString(resourceGroup().id)}'


resource logAnalyticsWorkspace1 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: logAnalyticsWorkspace1Name
  location: location
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

resource appInsights1 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsights1Name
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace1.id
  }
}

output appInsights1ConnectionString string = appInsights1.properties.ConnectionString
