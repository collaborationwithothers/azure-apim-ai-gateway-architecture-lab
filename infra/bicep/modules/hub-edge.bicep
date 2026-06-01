targetScope = 'resourceGroup'

param location string
param tags object
param enablePublicEdge bool
param publicHostname string
param apimGatewayHostname string
param customDomainCertificateSecretUri string
param wafAllowedSourceCidrs array
param appGwSubnetId string
param appGwIdentityId string

var applicationGatewayName = 'agw-cwc-ai-gw-swc-001'
var healthPath = '/status-0123456789abcdef'
var appGatewayCertificateName = 'public-edge-certificate'

resource appGwPublicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'pip-agw-cwc-ai-gw-swc-001'
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

resource wafPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2024-05-01' = {
  name: 'wafpol-cwc-ai-gw-swc-001'
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
  name: applicationGatewayName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appGwIdentityId}': {}
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
            id: appGwSubnetId
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
        name: appGatewayCertificateName
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
              fqdn: apimGatewayHostname
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
          host: apimGatewayHostname
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
          hostName: apimGatewayHostname
          pickHostNameFromBackendAddress: false
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', applicationGatewayName, 'apim-health')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'https-api-consultwithcloud'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'publicFrontend')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'port-443')
          }
          protocol: 'Https'
          hostName: publicHostname
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', applicationGatewayName, appGatewayCertificateName)
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
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'https-api-consultwithcloud')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'apim-private-gateway')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'https-apim')
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

output applicationGatewayName string = enablePublicEdge ? appGateway.name : 'not-deployed-until-enablePublicEdge-true'
output applicationGatewayId string = enablePublicEdge ? appGateway.id : ''
output applicationGatewayPublicIpId string = appGwPublicIp.id
