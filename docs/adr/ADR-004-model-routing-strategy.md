# 004: Model Routing Strategy

## Status

Accepted

## Context

This lab needs a clear architectural position for an enterprise AI gateway in front of Azure AI Foundry and Azure OpenAI workloads.

## Decision

Route by request class, tenant tier, capability, region, and degraded-mode policy.

## Options considered

Single model, client-chosen model, gateway routing, and application service routing.

## Tradeoffs

Gateway routing centralizes cost and resilience policy but makes behavior harder to test because model outputs can differ. Client-chosen routing is flexible but weakens governance.

## Consequences

Scenario 04 uses explicit routing tables and fallback rules rather than implicit model selection.

## Revisit criteria

Revisit when real model evaluation data shows routing harms quality or compliance.

## Sources

- [AI gateway in Azure API Management](https://learn.microsoft.com/azure/api-management/genai-gateway-capabilities)
- [API Management policy reference](https://learn.microsoft.com/azure/api-management/api-management-policies)
- [Access Foundry Models and other language models through a gateway](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-guide)
- [Use a gateway in front of multiple Azure OpenAI deployments or instances](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-multi-backend)
- [Bicep what-if deployment preview](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deploy-what-if)
