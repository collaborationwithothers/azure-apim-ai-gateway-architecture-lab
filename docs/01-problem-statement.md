# Problem Statement

Enterprise AI applications need central controls before requests reach shared model backends. Without a gateway, every application must implement identity enforcement, rate protection, token budgets, safety checks, logging, retries, failover, and cost attribution on its own.

The problem is not only technical. It is also ownership. A platform team needs repeatable rules that application teams can consume without embedding secrets or backend-specific logic in every client.

The lab frames APIM as that platform control point while calling out where APIM does not replace backend quota planning, model governance, data classification, or human operational review.

## Sources

- [AI gateway in Azure API Management](https://learn.microsoft.com/azure/api-management/genai-gateway-capabilities)
- [API Management policy reference](https://learn.microsoft.com/azure/api-management/api-management-policies)
- [Access Foundry Models and other language models through a gateway](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-guide)
- [Use a gateway in front of multiple Azure OpenAI deployments or instances](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-multi-backend)
- [Bicep what-if deployment preview](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deploy-what-if)
