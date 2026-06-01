targetScope = 'subscription'

@description('Azure region for all new hub-spoke platform resources.')
param location string = 'swedencentral'

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

@description('Set true only after the Key Vault certificate for api.lab.consultwithcloud.com exists and customDomainCertificateSecretUri is set.')
param enablePublicEdge bool = false

@description('Set true only after the Key Vault certificate exists and public DNS for api.lab.consultwithcloud.com resolves to the Application Gateway public edge.')
param enableCustomDomain bool = false

@description('Optional versionless Key Vault secret URI for the api.lab.consultwithcloud.com PFX. Leave empty until the lab certificate object name is confirmed.')
param customDomainCertificateSecretUri string = ''

@description('Microsoft Entra group object ID for permanent deployment administrators that receive lab Key Vault administration and ACR push access.')
param deploymentAdminGroupObjectId string = '4519227e-2736-47f7-b4da-c15be813677a'

@description('Optional allowed source CIDR list for Application Gateway WAF policy. Empty means no custom source allow rule is deployed.')
param wafAllowedSourceCidrs array = []

@description('Existing self-hosted runner VNet resource group.')
param runnerVnetResourceGroupName string = 'rg-dv-gh-actions-neu'

@description('Existing self-hosted runner VNet name.')
param runnerVnetName string = 'vnet-dv-gh-actions-neu'

@description('Delegated public DNS child zone reserved for the full lab demo.')
param labDnsZoneName string = 'lab.consultwithcloud.com'

@description('Existing persistent shared resource group created by bootstrap-persistent.yml.')
param sharedResourceGroupName string = 'rg-cwc-ai-gw-shared-swc-001'

@description('Existing persistent shared Key Vault created by bootstrap-persistent.yml.')
param sharedKeyVaultName string = 'kv-cwc-aigw-shr-swc-001'

@description('Future public APIM gateway hostname for the full lab demo.')
param apiLabHostname string = 'api.lab.consultwithcloud.com'

@description('Future public BFF app hostname for the full lab demo.')
param appLabHostname string = 'app.lab.consultwithcloud.com'

@description('Future public GitOps control plane hostname for the full lab demo.')
param argoLabHostname string = 'argo.lab.consultwithcloud.com'

@description('Feature flag for future AKS deployment. Issue #32 defines the contract only.')
param enableAks bool = false

@description('Feature flag for future Redis deployment. Issue #32 defines the contract only.')
param enableRedis bool = false

@description('Feature flag for future Foundry or model backend deployment. Issue #32 defines the contract only.')
param enableFoundryBackend bool = false

@description('Feature flag for future GitOps deployment. Issue #32 defines the contract only.')
param enableGitOps bool = false

@description('Feature flag for future BFF support. Issue #32 defines the contract only.')
param enableBff bool = false

@description('Future AKS SKU tier setting.')
param aksSkuTier string = 'Free'

@description('Future AKS system node pool VM size setting.')
param aksNodeVmSize string = 'Standard_B2s'

@description('Future AKS system node pool node count setting.')
@minValue(1)
param aksNodeCount int = 1

@description('Future AKS Kubernetes version setting. Empty means use the platform default selected by the later AKS slice.')
param aksKubernetesVersion string = ''

@description('Future AKS private cluster setting.')
param aksEnablePrivateCluster bool = false

@description('Future AKS outbound type setting.')
param aksOutboundType string = 'userDefinedRouting'

@description('Future Redis SKU name setting.')
param redisSkuName string = 'Basic'

@description('Future Redis capacity setting.')
@minValue(0)
param redisCapacity int = 0

@description('Future Redis family setting.')
param redisFamily string = 'C'

@description('Future Redis minimum TLS version setting.')
param redisMinimumTlsVersion string = '1.2'

@description('Future Foundry project name setting.')
param foundryProjectName string = 'cwc-ai-gw-demo'

@description('Future model name setting. Keep unresolved until availability is checked for the deployment region.')
param foundryModelName string = 'pending-model-selection'

@description('Future model version setting. Keep unresolved until availability is checked for the deployment region.')
param foundryModelVersion string = 'pending-version-selection'

@description('Future model deployment name setting.')
param foundryModelDeploymentName string = 'demo-model'

@description('Future model deployment SKU setting.')
param foundryModelDeploymentSkuName string = 'GlobalStandard'

@description('Future model deployment capacity setting.')
@minValue(1)
param foundryModelDeploymentCapacity int = 1

@description('Future GitOps repository URL setting.')
param gitOpsRepositoryUrl string = 'https://github.com/collaborationwithothers/azure-apim-ai-gateway-architecture-lab.git'

@description('Future GitOps revision setting.')
param gitOpsRevision string = 'main'

@description('Future GitOps path setting.')
param gitOpsPath string = 'gitops'

@description('Future GitOps automatic sync setting.')
param gitOpsAutoSync bool = true

@description('Future GitOps automatic prune setting.')
param gitOpsAutoPrune bool = false

@description('Future diagnostic log retention setting in days.')
@minValue(0)
param diagnosticLogRetentionDays int = 30

@description('Future verbose diagnostics setting.')
param enableVerboseDiagnostics bool = false

@description('Future Microsoft Entra app registration client ID for the BFF. Empty means unresolved.')
param bffAppRegistrationClientId string = ''

var hubRgName = 'rg-cwc-ai-gw-hub-swc-001'
var spokeRgName = 'rg-cwc-ai-gw-spoke-swc-001'
var hubVnetName = 'vnet-cwc-ai-gw-hub-swc-001'
var hubVnetId = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${hubRgName}/providers/Microsoft.Network/virtualNetworks/${hubVnetName}'
var runnerVnetId = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${runnerVnetResourceGroupName}/providers/Microsoft.Network/virtualNetworks/${runnerVnetName}'
var publicHostname = apiLabHostname
var apiLabDnsRecordName = 'api'
var appLabDnsRecordName = 'app'
var argoLabDnsRecordName = 'argo'
var certificateSecretUri = customDomainCertificateSecretUri
var spokeFullDemoContract = {
  labDns: {
    zoneName: labDnsZoneName
    recordNames: {
      api: apiLabDnsRecordName
      app: appLabDnsRecordName
      argo: argoLabDnsRecordName
    }
    hostnames: {
      api: apiLabHostname
      app: appLabHostname
      argo: argoLabHostname
    }
  }
  features: {
    aks: enableAks
    redis: enableRedis
    foundryBackend: enableFoundryBackend
    gitOps: enableGitOps
    bff: enableBff
  }
  aks: {
    enabled: enableAks
    skuTier: aksSkuTier
    nodeVmSize: aksNodeVmSize
    nodeCount: aksNodeCount
    kubernetesVersion: aksKubernetesVersion
    privateCluster: aksEnablePrivateCluster
    outboundType: aksOutboundType
  }
  redis: {
    enabled: enableRedis
    skuName: redisSkuName
    capacity: redisCapacity
    family: redisFamily
    minimumTlsVersion: redisMinimumTlsVersion
  }
  foundry: {
    enabled: enableFoundryBackend
    projectName: foundryProjectName
    modelName: foundryModelName
    modelVersion: foundryModelVersion
    deploymentName: foundryModelDeploymentName
    deploymentSkuName: foundryModelDeploymentSkuName
    deploymentCapacity: foundryModelDeploymentCapacity
  }
  gitOps: {
    enabled: enableGitOps
    repositoryUrl: gitOpsRepositoryUrl
    revision: gitOpsRevision
    path: gitOpsPath
    autoSync: gitOpsAutoSync
    autoPrune: gitOpsAutoPrune
  }
  diagnostics: {
    logRetentionDays: diagnosticLogRetentionDays
    verbose: enableVerboseDiagnostics
  }
  bff: {
    enabled: enableBff
    appHostname: appLabHostname
    appRegistrationClientId: bffAppRegistrationClientId
  }
  unresolvedDecisions: [
    'Redis product choice'
    'model availability'
    'certificate name'
    'Argo SSO groups'
    'BFF app registration'
  ]
  dependencies: {
    firstImplementationDependency: 'Issue #29'
    contractIssue: 'Issue #32'
    deploysDownstreamResources: false
  }
}
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

resource sharedRg 'Microsoft.Resources/resourceGroups@2024-03-01' existing = {
  name: sharedResourceGroupName
}

resource sharedKeyVault 'Microsoft.KeyVault/vaults@2024-11-01' existing = {
  name: sharedKeyVaultName
  scope: resourceGroup(sharedResourceGroupName)
}

resource labPublicDnsZone 'Microsoft.Network/dnsZones@2018-05-01' existing = {
  name: labDnsZoneName
  scope: resourceGroup(sharedResourceGroupName)
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
    sharedKeyVaultName: sharedKeyVault.name
    customDomainCertificateSecretUri: certificateSecretUri
    deploymentAdminGroupObjectId: deploymentAdminGroupObjectId
    wafAllowedSourceCidrs: wafAllowedSourceCidrs
  }
}

module sharedPublicDns './modules/shared-public-dns.bicep' = {
  name: 'shared-public-dns'
  scope: sharedRg
  params: {
    enablePublicEdge: enablePublicEdge
    labPublicDnsZoneName: labPublicDnsZone.name
    publicDnsRecordName: apiLabDnsRecordName
    applicationGatewayPublicIpId: hub.outputs.applicationGatewayPublicIpId
  }
}

module sharedKeyVaultRbac './modules/shared-key-vault-rbac.bicep' = {
  name: 'shared-key-vault-rbac'
  scope: sharedRg
  params: {
    keyVaultName: sharedKeyVault.name
    appGwIdentityPrincipalId: hub.outputs.appGwIdentityPrincipalId
    apimPrincipalId: hub.outputs.apimPrincipalId
    deploymentAdminGroupObjectId: deploymentAdminGroupObjectId
  }
}

module sharedKeyVaultDiagnostics './modules/shared-key-vault-diagnostics.bicep' = {
  name: 'shared-key-vault-diagnostics'
  scope: sharedRg
  params: {
    logAnalyticsWorkspaceId: hub.outputs.logAnalyticsWorkspaceId
    keyVaultName: sharedKeyVault.name
  }
}

module spoke './modules/spoke.bicep' = {
  name: 'spoke-platform'
  scope: spokeRg
  params: {
    location: location
    tags: tags
    firewallPrivateIp: hub.outputs.firewallPrivateIp
    hubVnetId: hubVnetId
    runnerVnetId: runnerVnetId
  }
}

module hubApimSpokePrivateDnsLink './modules/hub-apim-spoke-private-dns-link.bicep' = {
  name: 'hub-apim-spoke-private-dns-link'
  scope: hubRg
  params: {
    privateDnsZoneName: hub.outputs.apimPrivateDnsZoneName
    spokeVnetId: spoke.outputs.spokeVnetId
    tags: tags
  }
}

module hubPeerings './modules/hub-peerings.bicep' = {
  name: 'hub-peerings'
  scope: hubRg
  params: {
    hubVnetName: hubVnetName
    spokeVnetId: spoke.outputs.spokeVnetId
    runnerVnetId: runnerVnetId
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

module deploymentOutputs './outputs.bicep' = {
  name: 'deployment-outputs'
  params: {
    spokeNetwork: spoke.outputs.spokeNetwork
    spokeFullDemoContract: spokeFullDemoContract
  }
}

output hubResourceGroupName string = hubRg.name
output spokeResourceGroupName string = spokeRg.name
output spokeNetwork object = deploymentOutputs.outputs.spokeNetwork
output spokeFullDemoContract object = deploymentOutputs.outputs.spokeFullDemoContract
output logAnalyticsWorkspaceId string = hub.outputs.logAnalyticsWorkspaceId
output sharedResourceGroupName string = sharedRg.name
output keyVaultName string = sharedKeyVault.name
output keyVaultResourceGroupName string = sharedRg.name
output appGwSubnetId string = hub.outputs.appGwSubnetId
output apimSubnetId string = hub.outputs.apimSubnetId
output apimName string = hub.outputs.apimName
output applicationGatewayName string = hub.outputs.applicationGatewayName
output certificateSecretUri string = certificateSecretUri
output publicHostname string = publicHostname
output labPublicDnsZoneName string = labDnsZoneName
output labPublicDnsZoneNameServers array = labPublicDnsZone.properties.nameServers
output publicDnsZoneName string = labDnsZoneName
output expectedRepositoryGuard string = expectedRepository
