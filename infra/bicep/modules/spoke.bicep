targetScope = 'resourceGroup'

param location string
param tags object
param firewallPrivateIp string
param hubVnetId string
param runnerVnetId string

resource workloadRouteTable 'Microsoft.Network/routeTables@2024-05-01' = {
  name: 'rt-cwc-ai-gw-workload-swc-001'
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'default-to-azure-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ]
  }
}

resource aksRouteTable 'Microsoft.Network/routeTables@2024-05-01' = {
  name: 'rt-cwc-ai-gw-aks-swc-001'
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'default-to-azure-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ]
  }
}

resource spokeVnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-cwc-ai-gw-spoke-swc-001'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.20.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'snet-workload'
        properties: {
          addressPrefix: '10.20.1.0/24'
          routeTable: {
            id: workloadRouteTable.id
          }
        }
      }
      {
        name: 'snet-private-endpoints'
        properties: {
          addressPrefix: '10.20.2.0/24'
        }
      }
      {
        name: 'snet-aks'
        properties: {
          addressPrefix: '10.20.10.0/23'
          routeTable: {
            id: aksRouteTable.id
          }
        }
      }
    ]
  }
}

resource spokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: spokeVnet
  name: 'peer-to-hub'
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

resource spokeToRunnerPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: spokeVnet
  name: 'peer-to-runner'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: runnerVnetId
    }
  }
}

output spokeVnetId string = spokeVnet.id
output spokeNetwork object = {
  spokeVnetId: spokeVnet.id
  spokeVnetName: spokeVnet.name
  workloadSubnetId: '${spokeVnet.id}/subnets/snet-workload'
  privateEndpointsSubnetId: '${spokeVnet.id}/subnets/snet-private-endpoints'
  aksSubnetId: '${spokeVnet.id}/subnets/snet-aks'
  workloadRouteTableId: workloadRouteTable.id
  aksRouteTableId: aksRouteTable.id
}
