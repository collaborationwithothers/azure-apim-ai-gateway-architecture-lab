# Reference Architecture

The reference architecture has clients call APIM products and APIs rather than model endpoints directly. APIM validates caller identity, applies product or tenant policy, chooses a backend, authenticates to Azure AI services with managed identity where supported, and emits operational telemetry.

Supporting services include Key Vault for named values and secrets, Application Insights and Log Analytics for telemetry, Azure Managed Redis or a compatible RediSearch cache for semantic caching, and optional private endpoints and private DNS for locked-down environments.

The architecture supports both a simple baseline path and advanced variants for multitenancy, regional failover, semantic caching, and APIOps.

## Sources

- [AI gateway in Azure API Management](https://learn.microsoft.com/azure/api-management/genai-gateway-capabilities)
- [API Management policy reference](https://learn.microsoft.com/azure/api-management/api-management-policies)
- [Access Foundry Models and other language models through a gateway](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-guide)
- [Use a gateway in front of multiple Azure OpenAI deployments or instances](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-multi-backend)
- [Bicep what-if deployment preview](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deploy-what-if)
