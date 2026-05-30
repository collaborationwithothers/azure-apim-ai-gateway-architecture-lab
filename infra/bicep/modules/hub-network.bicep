targetScope = 'resourceGroup'

param location string
param tags object

var hubVnetName = 'vnet-cwc-ai-gw-hub-ncus-001'

resource apimNsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-apim-cwc-ai-gw-ncus-001'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowOutboundStorageHttps'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Storage'
        }
      }
      {
        name: 'AllowOutboundKeyVaultHttps'
        properties: {
          priority: 110
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureKeyVault'
        }
      }
    ]
  }
}

resource hubVnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: hubVnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.10.0.0/26'
        }
      }
      {
        name: 'snet-appgw'
        properties: {
          addressPrefix: '10.10.1.0/24'
          serviceEndpoints: [
            {
              service: 'Microsoft.KeyVault'
            }
          ]
        }
      }
      {
        name: 'snet-apim'
        properties: {
          addressPrefix: '10.10.2.0/24'
          networkSecurityGroup: {
            id: apimNsg.id
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.KeyVault'
            }
          ]
          delegations: [
            {
              name: 'delegation-apim-premium-v2'
              properties: {
                serviceName: 'Microsoft.Web/hostingEnvironments'
              }
            }
          ]
        }
      }
      {
        name: 'snet-private-endpoints'
        properties: {
          addressPrefix: '10.10.3.0/24'
        }
      }
    ]
  }
}

output hubVnetId string = hubVnet.id
output appGwSubnetId string = '${hubVnet.id}/subnets/snet-appgw'
output apimSubnetId string = '${hubVnet.id}/subnets/snet-apim'
output firewallSubnetId string = '${hubVnet.id}/subnets/AzureFirewallSubnet'
