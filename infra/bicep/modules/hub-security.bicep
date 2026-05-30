targetScope = 'resourceGroup'

param location string
param tags object
param runnerAllowedPublicIp string
param appGwSubnetId string
param apimSubnetId string

var keyVaultName = 'kv-cwc-ai-gw-eus2-001'

resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    tenantId: tenant().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: [
        {
          value: runnerAllowedPublicIp
        }
      ]
      virtualNetworkRules: [
        {
          id: appGwSubnetId
        }
        {
          id: apimSubnetId
        }
      ]
    }
  }
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: 'acrcwcaigweus2001'
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
  name: 'id-agw-cwc-ai-gw-eus2-001'
  location: location
  tags: tags
}

output keyVaultName string = keyVault.name
output keyVaultId string = keyVault.id
output acrName string = acr.name
output acrId string = acr.id
output appGwIdentityId string = appGwIdentity.id
output appGwIdentityPrincipalId string = appGwIdentity.properties.principalId
