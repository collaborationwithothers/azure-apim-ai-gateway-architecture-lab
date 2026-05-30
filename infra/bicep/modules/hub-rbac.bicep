targetScope = 'resourceGroup'

param keyVaultName string
param acrName string
param appGwIdentityPrincipalId string
param apimPrincipalId string
param deploymentAdminGroupObjectId string

var keyVaultAdministratorRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '00482a5a-887f-4fb3-b363-3b7fe8e74483')
var keyVaultSecretsUserRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
var keyVaultCertificateUserRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'db79e9a7-68ee-4b58-9aeb-b90e7c24fcba')
var acrPushRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8311e382-0749-4cb8-b61a-304f252e45ec')

resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' existing = {
  name: keyVaultName
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing = {
  name: acrName
}

resource kvAdministratorForDeploymentAdmins 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(keyVault.id, deploymentAdminGroupObjectId, keyVaultAdministratorRoleDefinitionId)
  properties: {
    roleDefinitionId: keyVaultAdministratorRoleDefinitionId
    principalId: deploymentAdminGroupObjectId
    principalType: 'Group'
    description: 'Permanent deployment administrators can manage certificates, secrets, and keys for lab deployment and certificate operations.'
  }
}

resource kvSecretUserForAppGw 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(keyVault.id, appGwIdentityPrincipalId, keyVaultSecretsUserRoleDefinitionId)
  properties: {
    roleDefinitionId: keyVaultSecretsUserRoleDefinitionId
    principalId: appGwIdentityPrincipalId
    principalType: 'ServicePrincipal'
    description: 'Application Gateway can retrieve the TLS certificate secret from the lab Key Vault.'
  }
}

resource kvSecretUserForApim 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(keyVault.id, apimPrincipalId, keyVaultSecretsUserRoleDefinitionId)
  properties: {
    roleDefinitionId: keyVaultSecretsUserRoleDefinitionId
    principalId: apimPrincipalId
    principalType: 'ServicePrincipal'
    description: 'APIM can retrieve the TLS certificate secret from the lab Key Vault.'
  }
}

resource kvCertificateUserForApim 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(keyVault.id, apimPrincipalId, keyVaultCertificateUserRoleDefinitionId)
  properties: {
    roleDefinitionId: keyVaultCertificateUserRoleDefinitionId
    principalId: apimPrincipalId
    principalType: 'ServicePrincipal'
    description: 'APIM can reference the TLS certificate stored in the lab Key Vault.'
  }
}

resource acrPushForDeploymentAdmins 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: acr
  name: guid(acr.id, deploymentAdminGroupObjectId, acrPushRoleDefinitionId)
  properties: {
    roleDefinitionId: acrPushRoleDefinitionId
    principalId: deploymentAdminGroupObjectId
    principalType: 'Group'
    description: 'Permanent deployment administrators can push and pull platform container images for lab deployment automation.'
  }
}
