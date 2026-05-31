targetScope = 'resourceGroup'

param enablePublicEdge bool
param labPublicDnsZoneName string
param publicDnsRecordName string
param applicationGatewayPublicIpId string

resource dnsZone 'Microsoft.Network/dnsZones@2018-05-01' existing = {
  name: labPublicDnsZoneName
}

resource publicDnsAlias 'Microsoft.Network/dnsZones/A@2018-05-01' = if (enablePublicEdge) {
  parent: dnsZone
  name: publicDnsRecordName
  properties: {
    TTL: 300
    targetResource: {
      id: applicationGatewayPublicIpId
    }
  }
}
