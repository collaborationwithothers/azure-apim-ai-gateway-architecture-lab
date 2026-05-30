# Azure APIM AI Gateway Architecture Lab

This repository is a documentation-first architecture lab and portfolio project
for designing Azure API Management as an enterprise AI gateway in front of Azure
AI Foundry and Azure OpenAI workloads. It is not a production deployment
template and does not include real tenant IDs, secrets, endpoints, or
subscription-specific parameters.

Modern enterprise AI applications should not call LLM backends directly. They
need an AI gateway layer to centralise access control, token governance,
routing, safety, observability, cost control, resilience, and multitenant
isolation. Azure API Management provides many of these gateway capabilities as
managed platform features, but the architecture still requires careful design
around identity, caching, backend quotas, regional failover, security, and
operational ownership.

## Problem statement

Teams often begin with direct application calls to a model endpoint. That
pattern is simple, but it spreads access control, rate protection, safety
checks, logging, cost attribution, retry logic, and backend routing across every
application. This lab demonstrates how an enterprise gateway layer can
centralize those concerns while keeping the model backends replaceable.

## Reference architecture

The reference architecture uses clients, products, and subscriptions at the
edge; Azure API Management for gateway policy enforcement; Azure AI Foundry or
Azure OpenAI deployments as backends; Azure Managed Redis or a compatible
RediSearch cache for semantic caching; Application Insights and Log Analytics
for observability; Key Vault for configuration; and optional private networking
for regulated environments.

See [docs/02-reference-architecture.md](docs/02-reference-architecture.md) and
[diagrams/mermaid/high-level-architecture.md](diagrams/mermaid/high-level-architecture.md).

## Why APIM as an AI gateway

Azure API Management is a managed gateway with policy-based request and response
processing. Microsoft documents AI gateway capabilities such as token-based rate
limiting, semantic caching, token metrics, content safety checks, backend load
balancing, and circuit breaking. This lab treats those capabilities as building
blocks, not as a complete solution. The design still requires explicit choices
for identity, tenant isolation, cache partitioning, logging sensitivity,
failover behavior, cost controls, and ownership.

## Scenario table

| Scenario | Focus                           | Policy example |
| -------- | ------------------------------- | -------------- |
| 00       | Baseline Foundry proxy          | Yes            |
| 01       | Auth and identity               | Yes            |
| 02       | Token governance                | Yes            |
| 03       | Semantic caching                | Yes            |
| 04       | Model routing                   | Yes            |
| 05       | Load balancing and failover     | Yes            |
| 06       | Content safety                  | Yes            |
| 07       | Observability and cost tracking | Yes            |
| 08       | Multitenant isolation           | Yes            |
| 09       | Private networking              | No             |
| 10       | Streaming responses             | Yes            |
| 11       | APIOps CI-CD                    | No             |
| 12       | Hub-spoke network foundation    | No             |

## Repository structure

| Path                              | Purpose                                                                                    |
| --------------------------------- | ------------------------------------------------------------------------------------------ |
| `docs/`                           | Executive, system design, threat, cost, performance, and operability documents.            |
| `docs/adr/`                       | Architecture decision records with options, tradeoffs, consequences, and revisit criteria. |
| `scenarios/`                      | Thirteen mini system design case studies.                                                  |
| `policies/examples/`              | Illustrative APIM policy XML files with environment-specific TODOs.                        |
| `diagrams/mermaid/`               | Mermaid source diagrams for the architecture flows.                                        |
| `observability/app-insights-kql/` | KQL placeholders for token, latency, cache, throttling, and cost analysis.                 |
| `infra/bicep/`                    | Safe Bicep skeleton only. It compiles but intentionally does not deploy resources yet.     |
| `.github/workflows/`              | Safe validation workflow templates.                                                        |

## How to use this repo

1. Start with this README and
   [docs/00-executive-summary.md](docs/00-executive-summary.md).
2. Review the scenario folders in order. Each README is a mini case study.
3. Inspect the example policies under [policies/examples/](policies/examples/).
4. Render the Mermaid files or view them directly in GitHub.
5. Run local validation commands before changing the scaffold.

Local checks:

    git diff --check
    rg -n "PLACEHOLDER_SECRET|real-tenant|prod.example" .
    az bicep build --file infra/bicep/main.bicep
    xmllint --noout policies/examples/*.xml

## Demo roadmap

The first pass is intentionally documentation-first. The next implementation
waves are:

1. Add a mock backend and contract tests.
2. Add APIM policy import automation.
3. Add safe Bicep modules for APIM, monitoring, Key Vault, cache, and optional
   private networking.
4. Add load tests and sample dashboards.
5. Add a controlled dev deployment path once environment-specific values are
   supplied outside source control.

## Architecture principles

- Treat the gateway as a control point, not as a magic security boundary.
- Prefer managed identity to shared keys for backend access where supported.
- Keep tenant identity, quota, cache partitioning, routing, and logging
  dimensions aligned.
- Avoid logging prompts or completions unless there is a reviewed data handling
  policy.
- Make failure behavior explicit before enabling retries, fallback, or degraded
  mode.
- Validate policy behavior with contract tests and operational queries before
  deployment.

## Security disclaimer

This repository contains illustrative architecture and placeholders. It is not a
hardened production baseline. Do not copy policy examples into a live APIM
instance without reviewing identity, network exposure, data logging, content
safety, cache partitioning, rate limits, backend auth, and incident response
requirements.

## Cost disclaimer

The examples discuss cost drivers but do not estimate real subscription charges.
APIM tier, Azure OpenAI model choice, Provisioned Throughput Units, token
volume, cache tier, monitoring ingestion, region count, and network design can
materially change cost.

## Next steps

Use the scenario packs to decide which controls matter for your workload, then
convert the TODOs into environment-specific implementation tasks. Keep source
control free of secrets, generated deployment outputs, and local parameter
files.

## Sources

- [AI gateway in Azure API Management](https://learn.microsoft.com/azure/api-management/genai-gateway-capabilities)
- [API Management policy reference](https://learn.microsoft.com/azure/api-management/api-management-policies)
- [Access Foundry Models and other language models through a gateway](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-guide)
- [Use a gateway in front of multiple Azure OpenAI deployments or instances](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-multi-backend)
- [Bicep what-if deployment preview](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deploy-what-if)
