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

var healthPath = '/status-0123456789abcdef'
var keyVaultName = 'kv-cwc-ai-gw-eus2-001'

resource apimNsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-apim-cwc-ai-gw-eus2-001'
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
  name: 'vnet-cwc-ai-gw-hub-eus2-001'
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

resource appGwSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: hubVnet
  name: 'snet-appgw'
}

resource apimSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: hubVnet
  name: 'snet-apim'
}

resource firewallSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: hubVnet
  name: 'AzureFirewallSubnet'
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'log-cwc-ai-gw-eus2-001'
  location: location
  tags: tags
  properties: {
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-cwc-ai-gw-eus2-001'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    RetentionInDays: 30
    DisableLocalAuth: true
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    tenantId: tenant().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
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
        {
          id: appGwSubnet.id
        }
        {
          id: apimSubnet.id
        }
      ]
    }
  }
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: 'acrcwcaigweus2001'
  location: location
  tags: tags
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
    networkRuleSet: {
      defaultAction: 'Deny'
      ipRules: [
        {
          action: 'Allow'
          value: runnerAllowedPublicIp
        }
      ]
    }
  }
}

resource appGwIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-agw-cwc-ai-gw-eus2-001'
  location: location
  tags: tags
}

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2024-05-01' = {
  name: 'afwp-cwc-ai-gw-eus2-001'
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
  name: 'pip-afw-cwc-ai-gw-eus2-001'
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
  name: 'afw-cwc-ai-gw-eus2-001'
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
            id: firewallSubnet.id
          }
          publicIPAddress: {
            id: firewallPublicIp.id
          }
        }
      }
    ]
  }
}

resource appGwPublicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'pip-agw-cwc-ai-gw-eus2-001'
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

resource dnsZone 'Microsoft.Network/dnsZones@2018-05-01' = {
  name: publicHostname
  location: 'global'
  tags: tags
}

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
      id: hubVnet.id
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
      subnetResourceId: apimSubnet.id
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

resource wafPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2024-05-01' = {
  name: 'wafpol-cwc-ai-gw-eus2-001'
  location: location
  tags: tags
  properties: {
    policySettings: {
      state: 'Enabled'
      mode: 'Prevention'
    }
    customRules: length(wafAllowedSourceCidrs) == 0 ? [] : [
      {
        name: 'BlockUnlistedSources'
        priority: 10
        ruleType: 'MatchRule'
        action: 'Block'
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'RemoteAddr'
              }
            ]
            operator: 'IPMatch'
            negationConditon: true
            matchValues: wafAllowedSourceCidrs
          }
        ]
      }
    ]
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
        }
      ]
    }
  }
}

resource appGateway 'Microsoft.Network/applicationGateways@2024-05-01' = if (enablePublicEdge) {
  name: 'agw-cwc-ai-gw-eus2-001'
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appGwIdentity.id}': {}
    }
  }
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
    }
    autoscaleConfiguration: {
      minCapacity: 1
      maxCapacity: 3
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: appGwSubnet.id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'publicFrontend'
        properties: {
          publicIPAddress: {
            id: appGwPublicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port-443'
        properties: {
          port: 443
        }
      }
    ]
    sslCertificates: [
      {
        name: 'cert-api-consultwithcloud-com'
        properties: {
          keyVaultSecretId: customDomainCertificateSecretUri
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'apim-private-gateway'
        properties: {
          backendAddresses: [
            {
              fqdn: publicHostname
            }
          ]
        }
      }
    ]
    probes: [
      {
        name: 'apim-health'
        properties: {
          protocol: 'Https'
          host: publicHostname
          path: healthPath
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'https-apim'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 60
          hostName: publicHostname
          pickHostNameFromBackendAddress: false
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', 'agw-cwc-ai-gw-eus2-001', 'apim-health')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'https-api-consultwithcloud'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', 'agw-cwc-ai-gw-eus2-001', 'publicFrontend')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', 'agw-cwc-ai-gw-eus2-001', 'port-443')
          }
          protocol: 'Https'
          hostName: publicHostname
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', 'agw-cwc-ai-gw-eus2-001', 'cert-api-consultwithcloud-com')
          }
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'route-to-apim'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', 'agw-cwc-ai-gw-eus2-001', 'https-api-consultwithcloud')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', 'agw-cwc-ai-gw-eus2-001', 'apim-private-gateway')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', 'agw-cwc-ai-gw-eus2-001', 'https-apim')
          }
        }
      }
    ]
    firewallPolicy: {
      id: wafPolicy.id
    }
    enableHttp2: true
  }
}

resource publicDnsAlias 'Microsoft.Network/dnsZones/A@2018-05-01' = if (enablePublicEdge) {
  parent: dnsZone
  name: '@'
  properties: {
    TTL: 300
    targetResource: {
      id: appGwPublicIp.id
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

resource kvSecretUserForAppGw 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(keyVault.id, appGwIdentity.id, 'Key Vault Secrets User')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: appGwIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource kvSecretUserForApim 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(keyVault.id, apim.id, 'Key Vault Secrets User')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: apim.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource kvCertificateUserForApim 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(keyVault.id, apim.id, 'Key Vault Certificate User')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'db79e9a7-68ee-4b58-9aeb-b90e7c24fcba')
    principalId: apim.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource kvCertificatesOfficerForIssuer 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(certificateIssuerPrincipalId)) {
  scope: keyVault
  name: guid(keyVault.id, certificateIssuerPrincipalId, 'Key Vault Certificates Officer')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a4417e6f-fecd-4de8-b567-7b0420556985')
    principalId: certificateIssuerPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource kvSecretUserForIssuer 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(certificateIssuerPrincipalId)) {
  scope: keyVault
  name: guid(keyVault.id, certificateIssuerPrincipalId, 'Key Vault Secrets User')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: certificateIssuerPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource lawDiagnosticsForKeyVault 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: keyVault
  name: 'send-to-log-analytics'
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource lawDiagnosticsForAcr 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: acr
  name: 'send-to-log-analytics'
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource lawDiagnosticsForFirewall 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: azureFirewall
  name: 'send-to-log-analytics'
  properties: {
    workspaceId: logAnalytics.id
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource lawDiagnosticsForApim 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: apim
  name: 'send-to-log-analytics'
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource lawDiagnosticsForAppGateway 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enablePublicEdge) {
  scope: appGateway
  name: 'send-to-log-analytics'
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output hubVnetId string = hubVnet.id
output firewallPrivateIp string = azureFirewall.properties.ipConfigurations[0].properties.privateIPAddress
output logAnalyticsWorkspaceId string = logAnalytics.id
output keyVaultName string = keyVault.name
output apimName string = apim.name
output applicationGatewayName string = enablePublicEdge ? appGateway.name : 'not-deployed-until-enablePublicEdge-true'
output certificateSecretUri string = customDomainCertificateSecretUri
