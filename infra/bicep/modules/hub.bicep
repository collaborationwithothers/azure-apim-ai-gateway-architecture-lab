targetScope = 'resourceGroup'

param location string
param tags object
param runnerAllowedPublicIp string
param enablePublicEdge bool
param enableCustomDomain bool
param publicHostname string
param sharedKeyVaultName string
param customDomainCertificateSecretUri string
param deploymentAdminGroupObjectId string
param wafAllowedSourceCidrs array

module network './hub-network.bicep' = {
  name: 'hub-network'
  params: {
    location: location
    tags: tags
  }
}

module observability './hub-observability.bicep' = {
  name: 'hub-observability'
  params: {
    location: location
    tags: tags
  }
}

module security './hub-security.bicep' = {
  name: 'hub-security'
  params: {
    location: location
    tags: tags
    runnerAllowedPublicIp: runnerAllowedPublicIp
  }
}

module firewall './hub-firewall.bicep' = {
  name: 'hub-firewall'
  params: {
    location: location
    tags: tags
    firewallSubnetId: network.outputs.firewallSubnetId
  }
}

module apim './hub-apim.bicep' = {
  name: 'hub-apim'
  params: {
    location: location
    tags: tags
    enableCustomDomain: enableCustomDomain
    publicHostname: publicHostname
    customDomainCertificateSecretUri: customDomainCertificateSecretUri
    hubVnetId: network.outputs.hubVnetId
    apimSubnetId: network.outputs.apimSubnetId
  }
}

module edge './hub-edge.bicep' = {
  name: 'hub-edge'
  params: {
    location: location
    tags: tags
    enablePublicEdge: enablePublicEdge
    publicHostname: publicHostname
    customDomainCertificateSecretUri: customDomainCertificateSecretUri
    wafAllowedSourceCidrs: wafAllowedSourceCidrs
    appGwSubnetId: network.outputs.appGwSubnetId
    appGwIdentityId: security.outputs.appGwIdentityId
  }
}

module rbac './hub-rbac.bicep' = {
  name: 'hub-rbac'
  params: {
    acrName: security.outputs.acrName
    deploymentAdminGroupObjectId: deploymentAdminGroupObjectId
  }
}

module diagnostics './hub-diagnostics.bicep' = {
  name: 'hub-diagnostics'
  params: {
    logAnalyticsWorkspaceId: observability.outputs.logAnalyticsWorkspaceId
    acrName: security.outputs.acrName
    firewallName: firewall.outputs.firewallName
    apimName: apim.outputs.apimName
    applicationGatewayName: edge.outputs.applicationGatewayName
    enablePublicEdge: enablePublicEdge
  }
}

output hubVnetId string = network.outputs.hubVnetId
output appGwSubnetId string = network.outputs.appGwSubnetId
output apimSubnetId string = network.outputs.apimSubnetId
output firewallPrivateIp string = firewall.outputs.firewallPrivateIp
output logAnalyticsWorkspaceId string = observability.outputs.logAnalyticsWorkspaceId
output keyVaultName string = sharedKeyVaultName
output acrName string = security.outputs.acrName
output apimPrincipalId string = apim.outputs.apimPrincipalId
output appGwIdentityPrincipalId string = security.outputs.appGwIdentityPrincipalId
output apimName string = apim.outputs.apimName
output applicationGatewayName string = edge.outputs.applicationGatewayName
output applicationGatewayPublicIpId string = edge.outputs.applicationGatewayPublicIpId
output certificateSecretUri string = customDomainCertificateSecretUri
