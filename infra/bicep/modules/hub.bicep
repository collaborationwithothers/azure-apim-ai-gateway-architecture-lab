targetScope = 'resourceGroup'

param location string
param tags object
param runnerAllowedPublicIp string
param enablePublicEdge bool
param enableCustomDomain bool
param publicHostname string
param customDomainCertificateSecretUri string
param certificateIssuerPrincipalId string
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
    appGwSubnetId: network.outputs.appGwSubnetId
    apimSubnetId: network.outputs.apimSubnetId
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
    keyVaultName: security.outputs.keyVaultName
    appGwIdentityId: security.outputs.appGwIdentityId
    appGwIdentityPrincipalId: security.outputs.appGwIdentityPrincipalId
    apimId: apim.outputs.apimId
    apimPrincipalId: apim.outputs.apimPrincipalId
    certificateIssuerPrincipalId: certificateIssuerPrincipalId
  }
}

module diagnostics './hub-diagnostics.bicep' = {
  name: 'hub-diagnostics'
  params: {
    logAnalyticsWorkspaceId: observability.outputs.logAnalyticsWorkspaceId
    keyVaultName: security.outputs.keyVaultName
    acrName: security.outputs.acrName
    firewallName: firewall.outputs.firewallName
    apimName: apim.outputs.apimName
    applicationGatewayName: edge.outputs.applicationGatewayName
    enablePublicEdge: enablePublicEdge
  }
}

output hubVnetId string = network.outputs.hubVnetId
output firewallPrivateIp string = firewall.outputs.firewallPrivateIp
output logAnalyticsWorkspaceId string = observability.outputs.logAnalyticsWorkspaceId
output keyVaultName string = security.outputs.keyVaultName
output apimName string = apim.outputs.apimName
output applicationGatewayName string = edge.outputs.applicationGatewayName
output certificateSecretUri string = customDomainCertificateSecretUri
