# 005: Token Governance Strategy

## Status

Accepted

## Context

This lab needs a clear architectural position for an enterprise AI gateway in front of Azure AI Foundry and Azure OpenAI workloads.

## Decision

Apply token limits at the gateway and treat backend quota planning as a separate responsibility.

## Options considered

No token limits, request rate limits only, token limits by subscription, token limits by tenant claim, and application budget controls.

## Tradeoffs

Token limits match LLM resource consumption better than request counts, but they do not replace Azure OpenAI quota, PTU sizing, or application-level budgets.

## Consequences

Scenario 02 defines tiers and KQL placeholders for token usage analysis.

## Revisit criteria

Revisit when real usage data shows limits are too coarse or counters need cross-region aggregation.

## Sources

- [AI gateway in Azure API Management](https://learn.microsoft.com/azure/api-management/genai-gateway-capabilities)
- [API Management policy reference](https://learn.microsoft.com/azure/api-management/api-management-policies)
- [Access Foundry Models and other language models through a gateway](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-guide)
- [Use a gateway in front of multiple Azure OpenAI deployments or instances](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-multi-backend)
- [Bicep what-if deployment preview](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deploy-what-if)
