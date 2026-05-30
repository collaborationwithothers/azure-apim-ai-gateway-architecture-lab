# System Design Process

The design process starts with business outcomes, expected consumers, and risk tolerance. It then maps functional requirements such as chat completion, summarisation, and embeddings to non-functional requirements such as latency, throughput, cost controls, privacy, and availability.

Each scenario follows the same pattern: state the problem, list constraints, choose an architecture, explain alternatives, identify failure modes, define observability, and describe a demo. This makes tradeoffs explicit instead of hiding them in policy snippets.

The first-pass output is intentionally testable as a repository scaffold. Future passes should add mock services, contract tests, load tests, and controlled deployment automation.

## Sources

- [AI gateway in Azure API Management](https://learn.microsoft.com/azure/api-management/genai-gateway-capabilities)
- [API Management policy reference](https://learn.microsoft.com/azure/api-management/api-management-policies)
- [Access Foundry Models and other language models through a gateway](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-guide)
- [Use a gateway in front of multiple Azure OpenAI deployments or instances](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-multi-backend)
- [Bicep what-if deployment preview](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deploy-what-if)
