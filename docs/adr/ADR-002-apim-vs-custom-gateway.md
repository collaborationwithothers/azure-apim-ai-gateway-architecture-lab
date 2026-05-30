# 002: APIM vs Custom Gateway

## Status

Accepted

## Context

This lab needs a clear architectural position for an enterprise AI gateway in front of Azure AI Foundry and Azure OpenAI workloads.

## Decision

Prefer APIM for the portfolio lab and defer custom code to edge cases.

## Options considered

APIM, custom container gateway, service mesh, and direct SDK integration.

## Tradeoffs

APIM provides managed API lifecycle, products, subscriptions, policies, observability integration, and Azure operations alignment. Custom code is better for advanced algorithms but requires full lifecycle ownership.

## Consequences

The lab uses APIM policies first and documents custom gateway only as an alternative.

## Revisit criteria

Revisit if policy complexity becomes harder to test than equivalent application code.

## Sources

- [AI gateway in Azure API Management](https://learn.microsoft.com/azure/api-management/genai-gateway-capabilities)
- [API Management policy reference](https://learn.microsoft.com/azure/api-management/api-management-policies)
- [Access Foundry Models and other language models through a gateway](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-guide)
- [Use a gateway in front of multiple Azure OpenAI deployments or instances](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-multi-backend)
- [Bicep what-if deployment preview](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deploy-what-if)
