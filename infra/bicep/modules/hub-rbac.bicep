targetScope = 'resourceGroup'

param keyVaultName string
param appGwIdentityId string
param appGwIdentityPrincipalId string
param apimId string
param apimPrincipalId string
param certificateIssuerPrincipalId string

resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' existing = {
  name: keyVaultName
}

resource kvSecretUserForAppGw 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(keyVault.id, appGwIdentityId, 'Key Vault Secrets User')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: appGwIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource kvSecretUserForApim 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(keyVault.id, apimId, 'Key Vault Secrets User')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: apimPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource kvCertificateUserForApim 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(keyVault.id, apimId, 'Key Vault Certificate User')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'db79e9a7-68ee-4b58-9aeb-b90e7c24fcba')
    principalId: apimPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource kvCertificatesOfficerForIssuer 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(certificateIssuerPrincipalId)) {
  scope: keyVault
  name: guid(keyVault.id, certificateIssuerPrincipalId, 'Key Vault Certificates Officer')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a4417e6f-fecd-4de8-b567-7b0420556985')
    principalId: certificateIssuerPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource kvSecretUserForIssuer 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(certificateIssuerPrincipalId)) {
  scope: keyVault
  name: guid(keyVault.id, certificateIssuerPrincipalId, 'Key Vault Secrets User')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: certificateIssuerPrincipalId
    principalType: 'ServicePrincipal'
  }
}
