targetScope = 'resourceGroup'

param acrName string
param deploymentAdminGroupObjectId string

var acrPushRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8311e382-0749-4cb8-b61a-304f252e45ec')

resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing = {
  name: acrName
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
