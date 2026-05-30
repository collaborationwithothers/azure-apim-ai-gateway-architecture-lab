targetScope = 'resourceGroup'

param location string
param tags object
param enableCustomDomain bool
param publicHostname string
param customDomainCertificateSecretUri string
param hubVnetId string
param apimSubnetId string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: publicHostname
  location: 'global'
  tags: tags
}

resource privateDnsHubLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: privateDnsZone
  name: 'link-hub'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: hubVnetId
    }
  }
}

resource apim 'Microsoft.ApiManagement/service@2025-09-01-preview' = {
  name: 'apim-cwc-ai-gw-eus2-001'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'PremiumV2'
    capacity: 1
  }
  properties: {
    publisherName: 'Consult With Cloud'
    publisherEmail: 'hari.s@consultwithcloud.com'
    virtualNetworkType: 'Internal'
    virtualNetworkConfiguration: {
      subnetResourceId: apimSubnetId
    }
    publicNetworkAccess: 'Enabled'
    configurationApi: {
      legacyApi: 'Disabled'
    }
    developerPortalStatus: 'Enabled'
    hostnameConfigurations: enableCustomDomain ? [
      {
        type: 'Proxy'
        hostName: publicHostname
        certificateSource: 'KeyVault'
        keyVaultId: customDomainCertificateSecretUri
        identityClientId: 'SystemAssigned'
        defaultSslBinding: true
        negotiateClientCertificate: false
      }
    ] : []
  }
}

resource apimAzureMonitorDiagnostic 'Microsoft.ApiManagement/service/diagnostics@2025-09-01-preview' = {
  parent: apim
  name: 'azuremonitor'
  properties: {
    loggerId: 'azuremonitor'
    alwaysLog: 'allErrors'
    logClientIp: true
    sampling: {
      samplingType: 'fixed'
      percentage: 100
    }
    frontend: {
      request: {
        headers: [
          'Content-Type'
          'User-Agent'
        ]
        body: {
          bytes: 8192
        }
      }
      response: {
        headers: [
          'Content-Type'
        ]
        body: {
          bytes: 8192
        }
      }
    }
    backend: {
      request: {
        headers: [
          'Content-Type'
        ]
        body: {
          bytes: 8192
        }
      }
      response: {
        headers: [
          'Content-Type'
        ]
        body: {
          bytes: 8192
        }
      }
    }
    largeLanguageModel: {
      logs: 'enabled'
      requests: {
        messages: 'all'
        maxSizeInBytes: 32768
      }
      responses: {
        messages: 'all'
        maxSizeInBytes: 32768
      }
    }
  }
}

resource privateApimRecord 'Microsoft.Network/privateDnsZones/A@2024-06-01' = if (enableCustomDomain) {
  parent: privateDnsZone
  name: '@'
  properties: {
    ttl: 300
    aRecords: [
      {
        ipv4Address: apim.properties.privateIPAddresses[0]
      }
    ]
  }
}

output apimName string = apim.name
output apimId string = apim.id
output apimPrincipalId string = apim.identity.principalId
output privateDnsZoneName string = privateDnsZone.name
