targetScope = 'resourceGroup'

@description('Azure region for future lab resources.')
param location string = resourceGroup().location

@description('Short environment name used for future resource naming.')
@allowed([
  'dev'
  'test'
  'prod'
])
param environmentName string = 'dev'

@description('Name prefix for future lab resources. Keep this generic in source control.')
param namePrefix string = 'ai-gateway-lab'

var tags = {
  workload: 'apim-ai-gateway-lab'
  environment: environmentName
  purpose: 'architecture-lab'
}

// TODO: Add APIM instance module after SKU, publisher, network mode, and diagnostics are decided.
// TODO: Add Azure AI Foundry or Azure OpenAI account and deployment modules after model choices are reviewed.
// TODO: Add Application Insights and Log Analytics resources for gateway telemetry.
// TODO: Add Redis-compatible cache resource for semantic caching.
// TODO: Add Key Vault for named values and backend configuration.
// TODO: Add private endpoints and private DNS zones for private networking scenario.
// TODO: Add role assignments for APIM managed identity to call AI backends.

output labMetadata object = {
  location: location
  environmentName: environmentName
  namePrefix: namePrefix
  tags: tags
}
