# 003: Semantic Caching Strategy

## Status

Accepted

## Context

This lab needs a clear architectural position for an enterprise AI gateway in front of Azure AI Foundry and Azure OpenAI workloads.

## Decision

Use semantic caching only for low-risk, repeatable prompts with tenant-aware partitioning.

## Options considered

No cache, exact cache, semantic cache, and application-owned cache.

## Tradeoffs

Semantic caching can reduce repeated model calls and latency, but it introduces stale-answer, wrong-answer, poisoning, and data leakage risks. Tenant partitioning and conservative TTLs are mandatory in the design.

## Consequences

Scenario 03 documents good and bad candidates and separates lookup from store policies.

## Revisit criteria

Revisit if workloads are highly personalized, regulated, volatile, or require streaming.

## Sources

- [AI gateway in Azure API Management](https://learn.microsoft.com/azure/api-management/genai-gateway-capabilities)
- [API Management policy reference](https://learn.microsoft.com/azure/api-management/api-management-policies)
- [Access Foundry Models and other language models through a gateway](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-guide)
- [Use a gateway in front of multiple Azure OpenAI deployments or instances](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-multi-backend)
- [Bicep what-if deployment preview](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deploy-what-if)
