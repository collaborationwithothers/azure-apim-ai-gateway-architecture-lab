targetScope = 'resourceGroup'

param location string
param tags object
param runnerAllowedPublicIp string

resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: 'acrcwcaigwswc001'
  location: location
  tags: tags
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
    networkRuleSet: {
      defaultAction: 'Deny'
      ipRules: [
        {
          action: 'Allow'
          value: runnerAllowedPublicIp
        }
      ]
    }
  }
}

resource appGwIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-agw-cwc-ai-gw-swc-001'
  location: location
  tags: tags
}

output acrName string = acr.name
output acrId string = acr.id
output appGwIdentityId string = appGwIdentity.id
output appGwIdentityPrincipalId string = appGwIdentity.properties.principalId
