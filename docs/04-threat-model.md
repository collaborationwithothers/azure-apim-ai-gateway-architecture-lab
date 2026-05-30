# Threat Model

The gateway must reduce risk from unauthorized callers, token abuse, prompt injection, unsafe outputs, cache leakage, sensitive telemetry, and backend key exposure. It must also account for misconfiguration, weak tenant partitioning, and excessive trust in fallback paths.

Key trust boundaries are the client-to-APIM boundary, APIM-to-backend boundary, APIM-to-cache boundary, APIM-to-observability boundary, and management-plane access to APIM configuration. Each boundary needs identity, authorization, logging, and data handling decisions.

This lab does not claim that APIM alone solves AI security. It shows where gateway controls can help and where application, model, data, and operations controls still matter.

## Sources

- [AI gateway in Azure API Management](https://learn.microsoft.com/azure/api-management/genai-gateway-capabilities)
- [API Management policy reference](https://learn.microsoft.com/azure/api-management/api-management-policies)
- [Access Foundry Models and other language models through a gateway](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-guide)
- [Use a gateway in front of multiple Azure OpenAI deployments or instances](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-multi-backend)
- [Bicep what-if deployment preview](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deploy-what-if)
