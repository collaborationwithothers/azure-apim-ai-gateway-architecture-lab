targetScope = 'subscription'

@description('Azure region for all new hub-spoke platform resources.')
param location string = 'eastus2'

@description('Short environment name used for tags and workflow inputs.')
@allowed([
  'dev'
  'test'
  'prod'
])
param environmentName string = 'dev'

@description('Expected GitHub repository for guarded deployment workflows.')
param expectedRepository string = 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab'

@description('Public NAT IP address of the self-hosted runner. Use CIDR notation, for example 203.0.113.10/32.')
param runnerAllowedPublicIp string

@description('Set true only after the Key Vault certificate cert-api-consultwithcloud-com exists.')
param enablePublicEdge bool = false

@description('Set true only after the Key Vault certificate exists and public DNS for api.consultwithcloud.com resolves to the Application Gateway public edge.')
param enableCustomDomain bool = false

@description('Optional versionless Key Vault secret URI for the api.consultwithcloud.com PFX. Leave empty to use the lab Key Vault certificate secret.')
param customDomainCertificateSecretUri string = ''

@description('Microsoft Entra group object ID for permanent deployment administrators that receive lab Key Vault administration and ACR push access.')
param deploymentAdminGroupObjectId string = '4519227e-2736-47f7-b4da-c15be813677a'

@description('Optional allowed source CIDR list for Application Gateway WAF policy. Empty means no custom source allow rule is deployed.')
param wafAllowedSourceCidrs array = []

@description('Existing self-hosted runner VNet resource group.')
param runnerVnetResourceGroupName string = 'rg-dv-gh-actions-neu'

@description('Existing self-hosted runner VNet name.')
param runnerVnetName string = 'vnet-dv-gh-actions-neu'

var hubRgName = 'rg-cwc-ai-gw-hub-eus2-001'
var spokeRgName = 'rg-cwc-ai-gw-spoke-eus2-001'
var hubVnetName = 'vnet-cwc-ai-gw-hub-eus2-001'
var publicHostname = 'api.consultwithcloud.com'
var keyVaultName = 'kv-cwc-ai-gw-eus2-001'
var certificateSecretUri = empty(customDomainCertificateSecretUri) ? 'https://${keyVaultName}${environment().suffixes.keyvaultDns}/secrets/cert-api-consultwithcloud-com' : customDomainCertificateSecretUri
var tags = {
  workload: 'cwc-ai-gw'
  environment: environmentName
  region: location
  owner: 'haripraghash'
  'managed-by': 'bicep'
  repo: 'azure-apim-ai-gateway-architecture-lab'
  'cost-center': 'personal-lab'
  'data-classification': 'non-production'
}

resource hubRg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: hubRgName
  location: location
  tags: tags
}

resource spokeRg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: spokeRgName
  location: location
  tags: tags
}

module hub './modules/hub.bicep' = {
  name: 'hub-platform'
  scope: hubRg
  params: {
    location: location
    tags: tags
    runnerAllowedPublicIp: runnerAllowedPublicIp
    enablePublicEdge: enablePublicEdge
    enableCustomDomain: enableCustomDomain
    publicHostname: publicHostname
    customDomainCertificateSecretUri: certificateSecretUri
    deploymentAdminGroupObjectId: deploymentAdminGroupObjectId
    wafAllowedSourceCidrs: wafAllowedSourceCidrs
  }
}

module spoke './modules/spoke.bicep' = {
  name: 'spoke-platform'
  scope: spokeRg
  params: {
    location: location
    tags: tags
    firewallPrivateIp: hub.outputs.firewallPrivateIp
    hubVnetId: resourceId(hubRgName, 'Microsoft.Network/virtualNetworks', hubVnetName)
    runnerVnetId: resourceId(runnerVnetResourceGroupName, 'Microsoft.Network/virtualNetworks', runnerVnetName)
  }
}

module hubPeerings './modules/hub-peerings.bicep' = {
  name: 'hub-peerings'
  scope: hubRg
  params: {
    hubVnetName: hubVnetName
    spokeVnetId: spoke.outputs.spokeVnetId
    runnerVnetId: resourceId(runnerVnetResourceGroupName, 'Microsoft.Network/virtualNetworks', runnerVnetName)
  }
}

module runnerPeerings './modules/runner-peerings.bicep' = {
  name: 'runner-peerings'
  scope: resourceGroup(runnerVnetResourceGroupName)
  params: {
    runnerVnetName: runnerVnetName
    hubVnetId: hub.outputs.hubVnetId
    spokeVnetId: spoke.outputs.spokeVnetId
  }
}

output hubResourceGroupName string = hubRg.name
output spokeResourceGroupName string = spokeRg.name
output logAnalyticsWorkspaceId string = hub.outputs.logAnalyticsWorkspaceId
output publicDnsZoneName string = publicHostname
output keyVaultName string = hub.outputs.keyVaultName
output apimName string = hub.outputs.apimName
output applicationGatewayName string = hub.outputs.applicationGatewayName
output certificateSecretUri string = certificateSecretUri
output expectedRepositoryGuard string = expectedRepository
