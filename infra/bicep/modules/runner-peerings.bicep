targetScope = 'resourceGroup'

param runnerVnetName string
param hubVnetId string
param spokeVnetId string

resource runnerVnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: runnerVnetName
}

resource runnerToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: runnerVnet
  name: 'peer-to-cwc-ai-gw-hub'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubVnetId
    }
  }
}

resource runnerToSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: runnerVnet
  name: 'peer-to-cwc-ai-gw-spoke'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: spokeVnetId
    }
  }
}
