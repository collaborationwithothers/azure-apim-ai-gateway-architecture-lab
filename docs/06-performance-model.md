# Performance Model

APIM adds a network hop and policy execution time. The benefit is central governance and resilience. The performance design must measure gateway latency, backend latency, token generation time, cache hit ratio, throttling rate, retry behavior, and streaming behavior separately.

Semantic caching can reduce latency for repeated prompts but can return stale or incorrect answers if the threshold, TTL, or partition key is wrong. Load balancing can improve throughput but complicates debugging and conversation consistency.

The first-pass repo provides performance review templates and KQL placeholders. Future passes should add k6 tests, APIM trace captures, and synthetic checks.

## Sources

- [AI gateway in Azure API Management](https://learn.microsoft.com/azure/api-management/genai-gateway-capabilities)
- [API Management policy reference](https://learn.microsoft.com/azure/api-management/api-management-policies)
- [Access Foundry Models and other language models through a gateway](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-guide)
- [Use a gateway in front of multiple Azure OpenAI deployments or instances](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-multi-backend)
- [Bicep what-if deployment preview](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deploy-what-if)
