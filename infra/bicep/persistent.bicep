targetScope = 'subscription'

@description('Azure region for persistent shared lab resources.')
param location string = 'swedencentral'

@description('Short environment name used for tags.')
@allowed([
  'dev'
  'test'
  'prod'
])
param environmentName string = 'dev'

@description('Public NAT IP address of the self-hosted runner. Use CIDR notation, for example 203.0.113.10/32.')
param runnerAllowedPublicIp string

@description('Delegated public DNS child zone reserved for the lab.')
param labDnsZoneName string = 'lab.consultwithcloud.com'

@description('Optional hub subnet resource IDs allowed to reach the persistent Key Vault. Provide APIM and Application Gateway subnet IDs after they exist.')
param keyVaultVirtualNetworkRuleSubnetIds array = []

var sharedRgName = 'rg-cwc-ai-gw-shared-swc-001'
var keyVaultName = 'kv-cwc-aigw-shr-swc-001'
var tags = {
  workload: 'cwc-ai-gw'
  environment: environmentName
  region: location
  owner: 'haripraghash'
  'managed-by': 'bicep'
  repo: 'azure-apim-ai-gateway-architecture-lab'
  'cost-center': 'personal-lab'
  'data-classification': 'non-production'
  persistence: 'shared-bootstrap'
}

resource sharedRg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: sharedRgName
  location: location
  tags: tags
}

module keyVault 'br/public:avm/res/key-vault/vault:0.12.1' = {
  name: 'shared-key-vault'
  scope: sharedRg
  params: {
    name: keyVaultName
    location: location
    tags: tags
    sku: 'standard'
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
        for subnetId in keyVaultVirtualNetworkRuleSubnetIds: {
          id: subnetId
        }
      ]
    }
  }
}

module labPublicDnsZone 'br/public:avm/res/network/dns-zone:0.6.0' = {
  name: 'lab-public-dns-zone'
  scope: sharedRg
  params: {
    name: labDnsZoneName
    tags: tags
  }
}

output sharedResourceGroupName string = sharedRg.name
output keyVaultName string = keyVault.outputs.name
output keyVaultUri string = keyVault.outputs.uri
output labPublicDnsZoneName string = labDnsZoneName
output labPublicDnsZoneNameServers array = labPublicDnsZone.outputs.nameServers
