# Operability Model

An AI gateway needs clear operational ownership. Platform teams usually own APIM configuration, shared policies, networking, and observability conventions. Application teams own request semantics, tenant onboarding needs, model behavior, and user-facing fallback behavior.

Operational runbooks should cover throttling, backend outage, regional failover, cache degradation, content safety false positives, unexpected cost spikes, and telemetry pipeline issues. Alerts should distinguish gateway failures from backend quota failures.

The lab includes KQL placeholders and workflow templates so future implementation can move from documentation to repeatable operations.

## Sources

- [AI gateway in Azure API Management](https://learn.microsoft.com/azure/api-management/genai-gateway-capabilities)
- [API Management policy reference](https://learn.microsoft.com/azure/api-management/api-management-policies)
- [Access Foundry Models and other language models through a gateway](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-guide)
- [Use a gateway in front of multiple Azure OpenAI deployments or instances](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-multi-backend)
- [Bicep what-if deployment preview](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deploy-what-if)
