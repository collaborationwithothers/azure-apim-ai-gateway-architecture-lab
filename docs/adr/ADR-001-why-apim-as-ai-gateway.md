# 001: Why APIM as AI Gateway

## Status

Accepted

## Context

This lab needs a clear architectural position for an enterprise AI gateway in front of Azure AI Foundry and Azure OpenAI workloads.

## Decision

Use Azure API Management as the managed gateway layer for the lab.

## Options considered

Direct client access, custom gateway, and managed APIM gateway.

## Tradeoffs

APIM centralizes policy enforcement and has documented AI gateway capabilities. A custom gateway gives maximum control but raises build and operations cost. Direct access is simplest but spreads governance across applications.

## Consequences

APIM is the default control point for scenarios, with explicit TODOs where real configuration is required.

## Revisit criteria

Revisit if APIM policy support cannot meet required streaming, routing, identity, or latency needs.

## Sources

- [AI gateway in Azure API Management](https://learn.microsoft.com/azure/api-management/genai-gateway-capabilities)
- [API Management policy reference](https://learn.microsoft.com/azure/api-management/api-management-policies)
- [Access Foundry Models and other language models through a gateway](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-guide)
- [Use a gateway in front of multiple Azure OpenAI deployments or instances](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-multi-backend)
- [Bicep what-if deployment preview](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deploy-what-if)
