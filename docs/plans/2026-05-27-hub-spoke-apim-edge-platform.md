# Implement Hub-Spoke APIM Edge Platform

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This plan follows `instructuctions/PLAN.md` in this repository. A future agent should treat this file as the source of truth for implementing the first deployable hub-spoke APIM edge platform.

## Purpose / Big Picture

After this change, the repository will no longer be only an architecture scaffold. A repository owner will be able to manually run guarded GitHub Actions workflows from a self-hosted runner to deploy a real Azure hub-spoke foundation in `swedencentral`. The public hostname `api.consultwithcloud.com` will terminate at Application Gateway WAF, re-encrypt to a private APIM Premium v2 gateway, and emit diagnostics to Log Analytics.

The observable result is a successful Bicep build, a subscription-scope Azure what-if showing the expected hub and spoke resources, and after apply plus certificate import, a healthy Application Gateway backend to APIM and usable DNS for `api.consultwithcloud.com`.

## Progress

- [x] (2026-05-27) Captured user decisions through the grill-me design interrogation.
- [x] (2026-05-27) Created `requirements/001-hub-spoke-apim-edge-platform.md`.
- [x] (2026-05-27) Created `design-log/001-hub-spoke-apim-edge-platform.md`.
- [x] (2026-05-27) Created this implementation plan.
- [x] (2026-05-30) Refactored Bicep from resource-group scope to subscription scope.
- [x] (2026-05-30) Added hub, spoke, and runner peering Bicep modules.
- [x] (2026-05-30) Added guarded GitHub Actions deployment workflow.
- [x] (2026-05-30) Added guarded certificate issuance workflow.
- [x] (2026-05-30) Updated README and infra README with run instructions and warnings.
- [x] (2026-05-30) Validated Bicep build and documentation formatting.
- [x] (2026-05-31) Added the future `lab.consultwithcloud.com` public DNS child zone and name server deployment output.

## Surprises & Discoveries

- Observation: New APIM Premium v2 creation is currently unavailable in East US 2.
  Evidence: Microsoft APIM v2 region availability lists a temporary capacity limitation for new Premium v2 instances in East US 2.

- Observation: Sweden Central is currently listed for both APIM Premium v2 and the Azure OpenAI Responses API.
  Evidence: Microsoft APIM v2 region availability lists Premium v2 for Sweden Central, and Microsoft Azure OpenAI Responses API documentation lists `swedencentral` in the supported regions.

- Observation: APIM Premium v2 availability must be validated against the live subscription SKU API, not only static region tables.
  Evidence: North Central US failed deployment with `SkuNotSupportedInRegion`, while the APIM SKU API for the target subscription lists `PremiumV2` in `swedencentral`.

- Observation: APIM Premium v2 does not support the classic direct management endpoint pattern.
  Evidence: Microsoft APIM v2 tier documentation lists Direct Management API access as unavailable in v2 tiers.

- Observation: VNet peering is not transitive.
  Evidence: Microsoft VNet peering guidance requires direct peering or routing through an NVA for VNet-to-VNet transit beyond a peering pair.

- Observation: Application Gateway v2 should not have a default route to Azure Firewall.
  Evidence: Microsoft Application Gateway infrastructure guidance warns against unsupported UDR patterns for v2 gateway control-plane and health behavior.

## Decision Log

- Decision: Deploy all new resources to `swedencentral`.
  Rationale: It is currently in the documented intersection of APIM Premium v2 support and Azure OpenAI Responses API support, passes live APIM SKU validation for the target subscription, and avoids the East US 2 temporary capacity limitation for new APIM Premium v2 instances.
  Date/Author: 2026-05-31 / Codex and user.

- Decision: Use subscription `c7a1d85d-159f-4cfc-bd13-51295c9acb96`.
  Rationale: It contains the existing GitHub runner network and NAT Gateway.
  Date/Author: 2026-05-27 / Codex and user.

- Decision: Use APIM Premium v2 with VNet injection.
  Rationale: It provides private gateway connectivity and can call backends in connected VNets.
  Date/Author: 2026-05-27 / Codex and user.

- Decision: Put Application Gateway WAF v2 in front of APIM.
  Rationale: APIM gateway is private, but `api.consultwithcloud.com` must be publicly reachable.
  Date/Author: 2026-05-27 / Codex and user.

- Decision: Manage APIM through Azure portal, ARM, and GitHub Actions only.
  Rationale: Premium v2 does not support Direct Management API access and the user has no VPN to the new VNets.
  Date/Author: 2026-05-27 / Codex and user.

- Decision: Leave Developer Portal on the default APIM hostname and require manual Entra ID sign-in configuration.
  Rationale: Premium v2 has custom-domain limitations and the portal remains publicly accessible through its managed endpoint.
  Date/Author: 2026-05-27 / Codex and user.

- Decision: Use direct runner-to-hub and runner-to-spoke peerings.
  Rationale: Peering is not transitive and the runner must reach future spoke resources.
  Date/Author: 2026-05-27 / Codex and user.

- Decision: Do not use Key Vault or ACR private endpoints in this pass.
  Rationale: The user chose public network restrictions with the runner NAT public IP instead.
  Date/Author: 2026-05-27 / Codex and user.

- Decision: Enable APIM body logging and warn in README.
  Rationale: The lab values observability, but the data sensitivity risk must be explicit.
  Date/Author: 2026-05-27 / Codex and user.

- Decision: Use normal incremental Bicep deployment, not deployment stacks.
  Rationale: Delete lifecycle management is not needed for the first pass and stacks add operational risk.
  Date/Author: 2026-05-27 / Codex and user.

- Decision: Add a fixed-target guarded manual destroy workflow for cost control.
  Rationale: The lab needs a safe teardown path that deletes only the known lab resource groups and runner-side peerings without adopting deployment stacks.
  Date/Author: 2026-05-30 / Codex and user.

## Outcomes & Retrospective

The first implementation pass created the subscription-scope Bicep entry point, resource-group-scoped hub and spoke modules, runner peering module, guarded deployment workflow, guarded certificate workflow, and deployment runbook documentation. Local validation completed for Bicep build, workflow guardrails, Markdown linting, whitespace, workflow trigger search, and secret-pattern search.

## Context and Orientation

The repository root is `/Users/harisubramaniam/learning/azure-ai/azure-apim-ai-gateway-architecture-lab`.

The infrastructure file `infra/bicep/main.bicep` is now a subscription-scope deployment because the target state creates two resource groups and deploys resources into both.

The repository already has placeholder workflow files under `.github/workflows/`. They must be replaced or updated so public forked pull requests cannot run Azure deployment logic.

Important terms:

- Hub VNet: the central Azure virtual network that contains shared services such as firewall, APIM, Application Gateway, DNS support, Key Vault, ACR, and Log Analytics.
- Spoke VNet: the workload virtual network that contains subnets for future applications and AKS.
- VNet peering: an Azure connection between two virtual networks. It is not transitive, so if A peers to B and B peers to C, A does not automatically reach C.
- APIM: Azure API Management. In this plan it is the API gateway service.
- VNet injection: a Premium v2 APIM deployment mode where the gateway endpoint is reachable through a private IP in a delegated subnet.
- Application Gateway WAF: Azure layer 7 reverse proxy with Web Application Firewall. It accepts public HTTPS traffic and forwards it to APIM over HTTPS.
- ACME DNS-01: a Let's Encrypt certificate validation method that proves domain ownership by creating DNS TXT records.
- OIDC: OpenID Connect. GitHub Actions uses it to get short-lived Azure tokens without storing a client secret.

## Plan of Work

Start by changing `infra/bicep/main.bicep` to `targetScope = 'subscription'`. Add parameters for subscription-scale settings: `location`, `environmentName`, `namePrefix`, `expectedRepository`, `runnerAllowedPublicIp`, `enablePublicEdge`, and `enableCustomDomain`. Keep any certificate secret URI value as an optional Bicep override; the GitHub deployment workflow uses the inferred lab Key Vault secret URI. Create both resource groups in this file, then call resource-group-scoped modules for hub and spoke.

Create a module folder under `infra/bicep/modules/`. Use Azure Verified Modules for resource types where the module is available, works cleanly, and can be pinned to an explicit version. Use raw Bicep for VNet peerings, route tables, diagnostic settings, DNS records, and other cross-resource wiring where raw resources are clearer.

Implement the hub module first. It must deploy the hub VNet and subnets, Azure Firewall Standard and Firewall Policy, Log Analytics workspace, Key Vault, ACR, Application Gateway WAF, APIM Premium v2, public DNS zone, private DNS for APIM gateway resolution, identities, role assignments, and diagnostic settings. The deployment admin group receives Key Vault Administrator at the lab vault scope and AcrPush at the lab ACR scope. The workflow identity must already have management-plane permission to create role assignments before the template can create these assignments.

Implement the spoke module second. It must deploy the spoke VNet and subnets, route tables for `snet-workload` and `snet-aks`, and spoke-side diagnostic-ready tags. It must not deploy AKS.

Implement peerings after both VNets exist. Add bidirectional peering for hub-spoke, hub-runner, and spoke-runner. Reference the runner VNet as existing in resource group `rg-dv-gh-actions-neu` with name `vnet-dv-gh-actions-neu`.

Add `infra-deploy.yml` as a guarded manual workflow. It must accept `mode` as `validate`, `what-if`, or `apply`. It must run on the `consultwithcloud-azure` runner group with the `[gh-linux]` label, use SHA-pinned OIDC Azure login, restore and build Bicep, and only run what-if or apply after the actor, literal repository, branch, and fixed `dev` environment approval checks pass. The apply job registers required Azure providers. The what-if job only verifies provider registration state before running what-if.

Add `certificate-issue.yml` as a separate guarded manual workflow. It runs after initial infrastructure exists. It must create the ACME DNS-01 challenge in the Azure DNS child zone, issue a Let's Encrypt certificate for `api.consultwithcloud.com`, and import it into Key Vault as `cert-api-consultwithcloud-com`. Do not commit certificate files or ACME secrets.

Update `README.md` and `infra/bicep/README.md`. The README must warn that APIM body logging is enabled and can ingest prompts, completions, request bodies, response bodies, secrets, or regulated data. The infra README must describe the staged deployment: initial infrastructure, certificate issuance, public edge and DNS alias, then APIM custom domain binding after DNS resolution is visible.

## Concrete Steps

Run all commands from the repository root unless stated otherwise.

First, inspect current state:

    git status --short
    rg --files infra .github requirements design-log docs/plans

Then update Bicep:

    az bicep restore --file infra/bicep/main.bicep
    az bicep build --file infra/bicep/main.bicep

Expected successful build output is no terminal output and a generated or updated JSON artifact if Azure CLI is configured to emit one. If `az` is not installed, document that validation could not run.

For deployment preflight, use the self-hosted runner workflow or run manually from an authenticated shell:

    az account set --subscription c7a1d85d-159f-4cfc-bd13-51295c9acb96
    az provider register --namespace Microsoft.Network
    az provider register --namespace Microsoft.ApiManagement
    az provider register --namespace Microsoft.ContainerRegistry
    az provider register --namespace Microsoft.KeyVault
    az provider register --namespace Microsoft.Insights
    az provider register --namespace Microsoft.OperationalInsights
    az provider register --namespace Microsoft.Web

Run what-if before apply:

    az deployment sub what-if \
      --name apim-ai-gateway-lab-swc \
      --location swedencentral \
      --template-file infra/bicep/main.bicep \
      --parameters location=swedencentral \
      --parameters runnerAllowedPublicIp=<runner-nat-public-ip> enablePublicEdge=false enableCustomDomain=false

Run apply only after reviewing what-if:

    az deployment sub create \
      --name apim-ai-gateway-lab-swc \
      --location swedencentral \
      --template-file infra/bicep/main.bicep \
      --parameters location=swedencentral \
      --parameters runnerAllowedPublicIp=<runner-nat-public-ip> enablePublicEdge=false enableCustomDomain=false

After phase one, capture the `labPublicDnsZoneNameServers` deployment output and create `NS` records for child name `lab` in the Cloudflare-managed parent zone `consultwithcloud.com`. This delegates `lab.consultwithcloud.com` for future full demo hostnames only. It does not create records for `api.lab.consultwithcloud.com`, `app.lab.consultwithcloud.com`, or `argo.lab.consultwithcloud.com`.

For the current edge path, delegate the existing `api.consultwithcloud.com` DNS child zone from the parent DNS host before running the certificate workflow. The certificate workflow imports a PFX certificate into Key Vault using the same OIDC identity path as the infrastructure workflow and relies on deployment admin group membership for certificate operations. After the certificate exists in Key Vault, re-run the infrastructure workflow with `enablePublicEdge=true` and `enableCustomDomain=false`. After public DNS resolution is visible, re-run with both values set to `true`.

For the guarded workflow path, set `RUNNER_ALLOWED_PUBLIC_IP_CIDR` as a variable on the `dev` GitHub Environment. The workflow passes that value to the Bicep `runnerAllowedPublicIp` parameter so operators do not type the runner NAT CIDR for every run.

## Validation and Acceptance

Documentation validation:

    git diff --check

Infrastructure validation:

    az bicep build --file infra/bicep/main.bicep

Workflow validation:

    rg -n "pull_request|pull_request_target" .github/workflows

This search must not find deployment workflow triggers. If placeholder validation workflows use pull requests, deployment workflows must still be isolated and documented.

Security validation:

    rg -n "client-secret|password|PFX|BEGIN PRIVATE KEY|PLACEHOLDER_SECRET" .

This search must not reveal real secrets or committed private key material.

Azure validation after apply:

- The hub and spoke resource groups exist in `swedencentral`.
- The hub, spoke, and runner VNets have bidirectional peerings.
- Application Gateway frontend public IP exists.
- Public DNS zone `api.consultwithcloud.com` exists and has an alias `A` record to the Application Gateway public IP.
- Public DNS zone `lab.consultwithcloud.com` exists and `labPublicDnsZoneNameServers` lists the Azure DNS name servers required for Cloudflare delegation.
- APIM Premium v2 exists with a private gateway and one unit.
- Key Vault has purge protection enabled.
- ACR admin user is disabled.
- The deployment admin group has Key Vault Administrator on the lab vault.
- The deployment admin group has AcrPush on the lab ACR.
- APIM and Application Gateway have only their required Key Vault certificate access roles.
- Log Analytics has 30-day retention.
- Azure Firewall threat intelligence mode is `Alert and deny`.
- Azure Firewall logs land in resource-specific tables such as `AZFWApplicationRule`.
- Application Gateway backend health for APIM is healthy after certificate binding.

End-to-end acceptance after certificate and DNS:

    curl -i https://api.consultwithcloud.com/status-0123456789abcdef

Expected result is HTTP 200 with APIM service health content. If the public DNS child zone is not delegated yet, use in-network DNS or host-file validation from a connected test host and document the limitation.

## Idempotence and Recovery

Bicep deployments must be incremental and safe to rerun. Re-running the validate and what-if modes must not modify Azure resources. What-if checks provider registration state but does not register providers. Re-running apply should update drifted settings back to the declared state.

If certificate issuance fails, leave infrastructure intact. Remove only temporary ACME challenge DNS records created by the workflow, then rerun the certificate workflow.

If APIM custom domain binding fails because the certificate or public DNS is not ready, rerun the infrastructure deployment with `enablePublicEdge = true` and `enableCustomDomain = false`, confirm the certificate workflow has imported `cert-api-consultwithcloud-com`, confirm public DNS resolution, then rerun with both values set to `true`.

If WAF Prevention blocks legitimate APIM traffic, inspect Application Gateway WAF logs in Log Analytics and add narrow exclusions only for the specific rule, request component, and hostname required. Do not disable WAF globally.

If cleanup is needed, use `.github/workflows/infra-destroy.yml`. Preview mode
lists the runner-side peerings and lab resource groups, and destroy mode
requires the exact confirmation phrase before it removes the runner-side
peerings and deletes the hub and spoke resource groups. Key Vault purge
protection means the deleted vault is not purged and the vault name may remain
reserved until the retention period expires. Parent DNS delegation is outside
the workflow and may need manual cleanup.

## Artifacts and Notes

Existing runner network:

    subscription: c7a1d85d-159f-4cfc-bd13-51295c9acb96
    resource group: rg-dv-gh-actions-neu
    vnet: vnet-dv-gh-actions-neu
    vnet cidr: 172.16.0.0/16
    subnet: snet-github-actions-private-runner-neu
    subnet cidr: 172.16.0.0/24
    NAT Gateway: /subscriptions/c7a1d85d-159f-4cfc-bd13-51295c9acb96/resourceGroups/rg-dv-gh-actions-neu/providers/Microsoft.Network/natGateways/natgw-gh-actions-neu

Resource naming:

    rg-cwc-ai-gw-hub-swc-001
    rg-cwc-ai-gw-spoke-swc-001
    vnet-cwc-ai-gw-hub-swc-001
    vnet-cwc-ai-gw-spoke-swc-001
    afw-cwc-ai-gw-swc-001
    afwp-cwc-ai-gw-swc-001
    log-cwc-ai-gw-swc-001
    acrcwcaigwswc001
    kv-cwc-ai-gw-swc-001
    apim-cwc-ai-gw-swc-001
    agw-cwc-ai-gw-swc-001
    pip-agw-cwc-ai-gw-swc-001

Standard tags:

    workload = cwc-ai-gw
    environment = dev
    region = swedencentral
    owner = haripraghash
    managed-by = bicep
    repo = azure-apim-ai-gateway-architecture-lab
    cost-center = personal-lab
    data-classification = non-production

## Interfaces and Dependencies

Use Bicep and Azure CLI. The parent Bicep file must be:

    infra/bicep/main.bicep

with:

    targetScope = 'subscription'

Minimum parameters:

    param location string = 'swedencentral'
    param environmentName string = 'dev'
    param expectedRepository string
    param runnerAllowedPublicIp string
    param enablePublicEdge bool = false
    param enableCustomDomain bool = false

Expected GitHub workflow permissions:

    permissions:
      contents: read
      id-token: write

Expected deployment workflow job guard:

    if: github.actor == 'haripraghash' && github.repository == 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab' && github.ref == 'refs/heads/main'

Use these documentation sources during implementation:

- APIM v2 tiers overview: https://learn.microsoft.com/en-us/azure/api-management/v2-service-tiers-overview
- APIM v2 tier region availability: https://learn.microsoft.com/en-us/azure/api-management/api-management-region-availability
- APIM SKU list API: https://learn.microsoft.com/en-us/rest/api/apimanagement/api-management-skus/list?view=rest-apimanagement-2024-05-01
- Azure OpenAI Responses API: https://learn.microsoft.com/en-us/azure/foundry/openai/how-to/responses
- APIM Premium v2 VNet injection: https://learn.microsoft.com/en-us/azure/api-management/inject-vnet-v2
- APIM custom domains: https://learn.microsoft.com/en-us/azure/api-management/configure-custom-domain
- Application Gateway backend settings: https://learn.microsoft.com/en-us/azure/application-gateway/configuration-http-settings
- Application Gateway WAF overview: https://learn.microsoft.com/en-us/azure/web-application-firewall/ag/ag-overview
- Azure Firewall structured logs: https://learn.microsoft.com/en-us/azure/firewall/firewall-structured-logs
- VNet peering overview: https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-peering-overview
- Azure DNS alias records: https://learn.microsoft.com/en-us/azure/dns/dns-alias
- Azure DNS domain delegation: https://learn.microsoft.com/en-us/azure/dns/dns-delegate-domain-azure-dns
- Key Vault soft delete: https://learn.microsoft.com/en-us/azure/key-vault/general/soft-delete-overview
- ACR authentication: https://learn.microsoft.com/en-us/azure/container-registry/container-registry-authentication
- Bicep GitHub Actions deployment: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-github-actions
- GitHub OIDC reference: https://docs.github.com/en/actions/reference/security/oidc

## Revision Notes

- 2026-05-31: Added issue #29 public DNS zone output for `lab.consultwithcloud.com` and clarified that Cloudflare delegation is an operator step before future lab hostnames, certificates, and custom domains.

2026-05-27: Initial ExecPlan created after grill-me discovery. The plan captures the APIM Premium v2 design, guarded public repository workflow constraints, existing runner VNet peering model, and two-phase certificate binding model.

2026-05-30: Updated the deploy target to `northcentralus` after Microsoft documentation showed new APIM Premium v2 instance creation is temporarily unavailable in East US 2 and the Azure OpenAI Responses API is available in North Central US.

2026-05-31: Updated the deploy target to `swedencentral` after North Central US failed deployment with `SkuNotSupportedInRegion` for `PremiumV2` and live APIM SKU validation listed `PremiumV2` for Sweden Central in the target subscription.
