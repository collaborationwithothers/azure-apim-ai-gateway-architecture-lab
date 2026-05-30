targetScope = 'resourceGroup'

param location string
param tags object
param firewallSubnetId string

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2024-05-01' = {
  name: 'afwp-cwc-ai-gw-ncus-001'
  location: location
  tags: tags
  properties: {
    sku: {
      tier: 'Standard'
    }
    threatIntelMode: 'Deny'
    dnsSettings: {
      enableProxy: false
    }
  }
}

resource firewallPublicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'pip-afw-cwc-ai-gw-ncus-001'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource azureFirewall 'Microsoft.Network/azureFirewalls@2024-05-01' = {
  name: 'afw-cwc-ai-gw-ncus-001'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    firewallPolicy: {
      id: firewallPolicy.id
    }
    ipConfigurations: [
      {
        name: 'configuration'
        properties: {
          subnet: {
            id: firewallSubnetId
          }
          publicIPAddress: {
            id: firewallPublicIp.id
          }
        }
      }
    ]
  }
}

output firewallName string = azureFirewall.name
output firewallId string = azureFirewall.id
output firewallPrivateIp string = azureFirewall.properties.ipConfigurations[0].properties.privateIPAddress
