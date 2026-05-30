# Cost Model

AI gateway costs come from APIM tier and scale, model token consumption, Provisioned Throughput Units where used, cache tier, monitoring ingestion, private networking, data transfer, and engineering operations. The cheapest gateway is not always the cheapest system if it allows uncontrolled token use.

Token limits, semantic caching, routing to lower-cost models, and cost-attribution telemetry are the main cost-control mechanisms in this lab. They must be paired with backend quota planning and budget governance.

Cost analysis remains illustrative until real request volumes, model choices, regions, APIM tiers, cache tiers, and monitoring retention settings are known.

## Sources

- [AI gateway in Azure API Management](https://learn.microsoft.com/azure/api-management/genai-gateway-capabilities)
- [API Management policy reference](https://learn.microsoft.com/azure/api-management/api-management-policies)
- [Access Foundry Models and other language models through a gateway](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-guide)
- [Use a gateway in front of multiple Azure OpenAI deployments or instances](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-multi-backend)
- [Bicep what-if deployment preview](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deploy-what-if)
