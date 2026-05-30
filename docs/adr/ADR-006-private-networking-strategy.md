# 006: Private Networking Strategy

## Status

Accepted

## Context

This lab needs a clear architectural position for an enterprise AI gateway in front of Azure AI Foundry and Azure OpenAI workloads.

## Decision

Document private networking as an advanced scenario rather than the default first-pass deployment.

## Options considered

External APIM, internal APIM, external APIM with private backend, and Application Gateway or WAF in front of APIM.

## Tradeoffs

Private networking improves exposure control but increases DNS, routing, deployment, and troubleshooting complexity. A portfolio lab needs to show the decision process without pretending every workload needs the most restrictive option.

## Consequences

Scenario 09 models private endpoints, private DNS, firewall egress, and portal exposure choices without deploying them.

## Revisit criteria

Revisit when a regulated workload requires private-by-default deployment artifacts.

## Sources

- [AI gateway in Azure API Management](https://learn.microsoft.com/azure/api-management/genai-gateway-capabilities)
- [API Management policy reference](https://learn.microsoft.com/azure/api-management/api-management-policies)
- [Access Foundry Models and other language models through a gateway](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-guide)
- [Use a gateway in front of multiple Azure OpenAI deployments or instances](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-multi-backend)
- [Bicep what-if deployment preview](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deploy-what-if)
