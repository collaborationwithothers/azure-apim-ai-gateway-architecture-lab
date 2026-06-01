targetScope = 'resourceGroup'

param privateDnsZoneName string
param spokeVnetId string
param tags object

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: privateDnsZoneName
}

resource privateDnsSpokeLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: privateDnsZone
  name: 'link-spoke'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: spokeVnetId
    }
  }
}

output privateDnsSpokeLinkId string = privateDnsSpokeLink.id
