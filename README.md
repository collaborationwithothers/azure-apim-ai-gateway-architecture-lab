# Azure APIM AI Gateway Architecture Lab

This repository is an architecture lab and deployable Azure APIM AI gateway
foundation. It contains scenario documentation, APIM policy examples, and a
guarded hub-spoke deployment path for `api.consultwithcloud.com`. It is not a
production baseline and does not include real tenant secrets, local parameter
files, or generated deployment outputs.

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

The first deployable platform slice is the hub-spoke APIM edge platform in
`swedencentral`. It creates hub and spoke resource groups, deploys APIM Premium v2 in
a delegated hub subnet, places Application Gateway WAF v2 in front of APIM,
routes future spoke workload egress through Azure Firewall Standard, and sends
diagnostics to Log Analytics. The public hostname is
`api.consultwithcloud.com`.

The spoke network exports a non-sensitive `spokeNetwork` output with IDs for
its VNet, workload subnet, private endpoint subnet, AKS subnet, and workload or
AKS route tables. These are contracts for later implementation slices and do not
mean AKS, Redis, Foundry, GitOps, private endpoints, or application workloads
have been deployed.

Sweden Central is the selected single-region target because Microsoft
documentation lists it for APIM Premium v2 and for the Azure OpenAI Responses
API required by later AI backend scenarios, and the live APIM SKU API lists
`PremiumV2` for this subscription in `swedencentral`.

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
| `infra/bicep/`                    | Subscription-scope Bicep for the hub-spoke APIM edge platform.                             |
| `.github/workflows/`              | Manual guarded workflows for validation, deployment, cleanup, and certificate issuance.     |

## How to use this repo

1. Start with this README and
   [docs/00-executive-summary.md](docs/00-executive-summary.md).
2. Review the scenario folders in order. Each README is a mini case study.
3. Inspect the example policies under [policies/examples/](policies/examples/).
4. Render the Mermaid files or view them directly in GitHub.
5. Review [infra/bicep/README.md](infra/bicep/README.md) before running deployment workflows.

Local checks:

    git diff --check
    rg -n "PLACEHOLDER_SECRET|real-tenant|prod.example" .
    az bicep build --file infra/bicep/main.bicep
    rg -n "pull_request|pull_request_target" .github/workflows
    bash tools/validate-workflow-guardrails.sh
    xmllint --noout policies/examples/*.xml

## Deployment overview

Deployments are manual, guarded, and intended for the repository owner from
`main` only. Azure-changing jobs run on the `consultwithcloud-azure` runner
group with the `[gh-linux]` label, use OIDC through a SHA-pinned `azure/login`, require
`github.actor == 'haripraghash'`, check the literal repository name, and use
the fixed `dev` GitHub Environment approval.

Use `.github/workflows/infra-deploy.yml` for `validate`, `what-if`, and `apply`.
The workflow reads the runner NAT CIDR from the `RUNNER_ALLOWED_PUBLIC_IP_CIDR`
variable on the `dev` GitHub Environment. It accepts the remaining non-secret
deployment inputs directly, including `enable_public_edge`,
`enable_custom_domain`, and `deployment_name`. The lab Key Vault certificate
secret URI is inferred by Bicep from the fixed lab resource names.
The Bicep deployment assigns the permanent deployment admin group Key Vault
Administrator on the lab vault and AcrPush on the lab registry. The workflow
identity must already have the management-plane permissions needed to create
role assignments.
The initial infrastructure deployment also creates the future
`lab.consultwithcloud.com` Azure DNS public child zone. Copy the
`labPublicDnsZoneNameServers` output into Cloudflare as `NS` records for the
`lab` subdomain of `consultwithcloud.com`. This Cloudflare delegation prepares
the later `api.lab.consultwithcloud.com`, `app.lab.consultwithcloud.com`, and
`argo.lab.consultwithcloud.com` hostnames only; it does not issue certificates
or change APIM custom-domain binding.
Use `.github/workflows/certificate-issue.yml` only after phase 1 has created the
Azure DNS child zone and Key Vault. The certificate workflow imports a PFX
certificate into Key Vault for Application Gateway TLS termination. The
deployment is two-phase:

1. Run infrastructure with `enablePublicEdge = false` and `enableCustomDomain = false`.
2. Delegate `api.consultwithcloud.com` from the parent DNS zone.
3. Run the certificate workflow to import `cert-api-consultwithcloud-com`.
4. Rerun infrastructure with `enablePublicEdge = true` and `enableCustomDomain = false`.
5. After public DNS resolves to Application Gateway, rerun with `enablePublicEdge = true` and `enableCustomDomain = true`.

Use `.github/workflows/infra-destroy.yml` to tear down the lab when it is not in
use. The workflow is manual and destructive. Preview mode lists the runner-side
peerings and lab resource groups that would be deleted. Destroy mode requires
the exact confirmation phrase, removes the runner-side peerings, and deletes
only `rg-cwc-ai-gw-hub-swc-001` and `rg-cwc-ai-gw-spoke-swc-001`.

The destroy workflow does not delete the runner VNet, runner resource group,
parent DNS delegation, subscription deployment history, or unrelated resources.
Key Vault purge protection may keep the deleted vault name reserved after
cleanup. Parent DNS delegation for `api.consultwithcloud.com` may need manual
cleanup outside this workflow.

## Demo roadmap

The first deployable infrastructure slice is now captured in Bicep and guarded
workflows. Next implementation waves are:

1. Run the first subscription what-if from the self-hosted runner.
2. Add a mock backend and contract tests.
3. Add APIM policy import automation.
4. Add load tests and sample dashboards.
5. Revisit AVM composition after the first successful apply.

## Architecture principles

- Treat the gateway as a control point, not as a magic security boundary.
- Prefer managed identity to shared keys for backend access where supported.
- Keep tenant identity, quota, cache partitioning, routing, and logging
  dimensions aligned.
- Treat APIM body logging as sensitive telemetry that needs reviewed data
  handling before real traffic is sent.
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

APIM body logging is intentionally enabled for the lab. It can ingest prompts,
completions, request bodies, response bodies, secrets, or regulated data into
Azure Monitor and Log Analytics. Do not send production, customer, credential,
or regulated data through this lab until logging, masking, retention, and access
controls have been reviewed.

## Cost disclaimer

The examples discuss cost drivers but do not estimate real subscription charges.
APIM tier, Azure OpenAI model choice, Provisioned Throughput Units, token
volume, cache tier, monitoring ingestion, region count, and network design can
materially change cost.

## Next steps

Use the scenario packs to decide which controls matter for your workload, then
run deployment preflight from the guarded workflow. Keep source control free of
secrets, generated deployment outputs, local parameter files, certificate files,
PFX files, and ACME account keys.

## Sources

- [AI gateway in Azure API Management](https://learn.microsoft.com/azure/api-management/genai-gateway-capabilities)
- [API Management policy reference](https://learn.microsoft.com/azure/api-management/api-management-policies)
- [Access Foundry Models and other language models through a gateway](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-guide)
- [Use a gateway in front of multiple Azure OpenAI deployments or instances](https://learn.microsoft.com/azure/architecture/ai-ml/guide/azure-openai-gateway-multi-backend)
- [Bicep what-if deployment preview](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deploy-what-if)
- [TLS termination with Key Vault certificates](https://learn.microsoft.com/azure/application-gateway/key-vault-certs)
