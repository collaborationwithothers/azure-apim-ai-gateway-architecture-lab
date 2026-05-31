---
id: REQ-001
title: Hub-Spoke APIM Edge Platform
created: 2026-05-27
status: Active
design-log: "001"
---

# Hub-Spoke APIM Edge Platform

## Overview

### Problem statement

The lab needs a deployable Azure hub-spoke foundation for an API Management based AI gateway. The repository now contains the first implementation pass for the hub network, spoke network, firewall, APIM, edge routing, DNS, certificate automation, diagnostics, and guarded GitHub Actions deployment path.

### Goals

Build a subscription-scope Bicep deployment that creates the hub and spoke resource groups in `swedencentral`, deploys shared edge and security services into the hub, deploys workload network foundations into the spoke, peers the existing GitHub runner VNet to both hub and spoke, and can be run only through guarded manual GitHub Actions workflows.

### Non-goals

- Do not deploy AKS in this requirement. Create only the AKS subnet.
- Do not deploy Azure DNS Private Resolver.
- Do not enable Azure Firewall DNS proxy.
- Do not create private endpoints for Key Vault or ACR in this pass.
- Do not expose an APIM direct management endpoint.
- Do not add VPN, ExpressRoute, Bastion, DDoS Protection, or Azure Firewall Premium.
- Do not deploy Azure AI Foundry, Azure OpenAI, mock APIs, or workload applications.

### Executive summary

The target platform uses Application Gateway WAF v2 as the public entry point for `api.lab.consultwithcloud.com`, forwards HTTPS traffic privately to APIM Premium v2 in the hub VNet, and keeps APIM management through Azure portal, ARM, and GitHub Actions. Azure Firewall Standard controls spoke workload and future AKS outbound traffic. Log Analytics receives diagnostics from deployed platform resources. GitHub Actions uses manual dispatch, OIDC, runner group `consultwithcloud-azure` with label `[gh-linux]`, environment approval, and strict job guards.

## Stakeholders

| Stakeholder | Responsibility |
|---|---|
| Repository owner | Approves workflow runs, owns public repo visibility and deployment intent. |
| Platform implementer | Builds Bicep, workflows, validation, and documentation. |
| Azure subscription owner | Grants deployment identity permissions and validates cost-impacting services. |
| Future workload owner | Uses the spoke network and later AKS subnet for application deployment. |

## Scope

### In-scope

- Subscription-scope Bicep deployment.
- Hub resource group and spoke resource group in `swedencentral`.
- Hub VNet, spoke VNet, and direct peerings among hub, spoke, and existing runner VNet.
- Non-sensitive spoke network outputs for downstream implementation slices.
- Azure Firewall Standard, Firewall Policy, public IP, and structured diagnostics.
- Application Gateway WAF v2 in Prevention mode.
- APIM Premium v2 with VNet injection in the hub.
- Public DNS child zone `lab.consultwithcloud.com` for the lab edge and full demo hostnames.
- Key Vault Standard with soft delete and purge protection.
- Let's Encrypt certificate issuance workflow using ACME DNS-01 and Key Vault import.
- ACR Premium with admin user disabled, diagnostics, and public IP firewall restriction.
- Log Analytics workspace with 30-day retention.
- GitHub Actions workflows limited to manual, guarded execution.
- Documentation updates and implementation plan.

### Out-of-scope

- AKS cluster deployment.
- Developer portal Entra ID automation.
- Private endpoints for ACR and Key Vault.
- Complete-mode or deployment-stack cleanup automation. A fixed-target guarded
  manual destroy workflow is allowed for lab cost control.
- Production traffic load testing.
- Azure AI backend deployment.

### Repos and components affected

| Path | Required change |
|---|---|
| `infra/bicep/main.bicep` | Subscription-scope orchestration entry point. |
| `infra/bicep/modules/` | Hub, spoke, and runner peering modules. |
| `.github/workflows/` | Guarded manual deployment and certificate workflows. |
| `README.md` | Deployment, safety, APIM body logging, and public repo workflow warnings. |
| `infra/bicep/README.md` | Deployment and parameter instructions. |
| `requirements/index.md` | Add REQ-001. |
| `design-log/index.md` | Add Design Log #001. |
| `docs/plans/` | Add the executable implementation plan. |

## Functional Requirements

### FR-1: Subscription-scope deployment

Description: The deployment must use `targetScope = 'subscription'` and create both resource groups before deploying resources into them.

Rationale: The hub and spoke live in separate resource groups in the same subscription.

Acceptance criteria:

- `az bicep build --file infra/bicep/main.bicep` succeeds.
- `az deployment sub what-if` can evaluate both resource groups from one template.
- Hub RG is `rg-cwc-ai-gw-hub-swc-001`.
- Spoke RG is `rg-cwc-ai-gw-spoke-swc-001`.

### FR-2: Region and subscription

Description: All newly deployed resources must use `swedencentral` and target subscription `c7a1d85d-159f-4cfc-bd13-51295c9acb96`.

Rationale: Microsoft documentation lists Sweden Central for both APIM Premium v2 and the Azure OpenAI Responses API, and the live APIM SKU API lists `PremiumV2` for this subscription in `swedencentral`. East US 2 is not usable for this lab while new APIM Premium v2 instance creation is temporarily unavailable there.

Acceptance criteria:

- Bicep defaults `location` to `swedencentral`.
- Workflows require the subscription ID as an explicit environment variable or parameter.
- No newly created resource defaults to the runner VNet region.

### FR-3: Hub network

Description: Deploy hub VNet `vnet-cwc-ai-gw-hub-swc-001` with address space `10.10.0.0/16`.

Rationale: The hub contains shared network, edge, diagnostics, and security services.

Acceptance criteria:

- Hub subnets include:
  - `AzureFirewallSubnet`: `10.10.0.0/26`
  - `snet-appgw`: `10.10.1.0/24`
  - `snet-apim`: `10.10.2.0/24`
  - `snet-private-endpoints`: `10.10.3.0/24`
- `snet-apim` is dedicated to one APIM Premium v2 instance and delegated to `Microsoft.Web/hostingEnvironments`.
- `snet-appgw` has no default route to Azure Firewall.

### FR-4: Spoke network

Description: Deploy spoke VNet `vnet-cwc-ai-gw-spoke-swc-001` with address space `10.20.0.0/16`.

Rationale: The spoke is the future workload network.

Acceptance criteria:

- Spoke subnets include:
  - `snet-workload`: `10.20.1.0/24`
  - `snet-private-endpoints`: `10.20.2.0/24`
  - `snet-aks`: `10.20.10.0/23`
- Route tables send `0.0.0.0/0` from `snet-workload` and `snet-aks` to the Azure Firewall private IP.
- `disableBgpRoutePropagation` remains `false`.
- The deployment exposes a non-sensitive `spokeNetwork` output for downstream
  slices with:
  - `spokeVnetId`
  - `spokeVnetName`
  - `workloadSubnetId`
  - `privateEndpointsSubnetId`
  - `aksSubnetId`
  - `workloadRouteTableId`
  - `aksRouteTableId`
- Spoke outputs are contracts for downstream slices and do not prove AKS,
  Redis, Foundry, GitOps, private endpoints, or workloads exist.

### FR-5: Existing runner VNet connectivity

Description: Reference the existing runner VNet and peer it directly to hub and spoke.

Rationale: VNet peering is not transitive. The runner must reach future spoke resources and hub deployment endpoints.

Acceptance criteria:

- Existing runner VNet is referenced, not recreated:
  - Resource group: `rg-dv-gh-actions-neu`
  - VNet: `vnet-dv-gh-actions-neu`
  - Address space: `172.16.0.0/16`
  - Runner subnet: `snet-github-actions-private-runner-neu`
  - Runner subnet address: `172.16.0.0/24`
- Peerings exist for hub-to-spoke, spoke-to-hub, runner-to-hub, hub-to-runner, runner-to-spoke, and spoke-to-runner.
- Global peering to the existing runner VNet is documented as an accepted cost and latency trade-off.

### FR-6: Azure Firewall

Description: Deploy Azure Firewall Standard in the hub with Firewall Policy.

Rationale: The hub provides centralized outbound inspection for spoke workload and future AKS subnets.

Acceptance criteria:

- Firewall SKU is `Standard`.
- Threat intelligence mode is `Alert and deny`.
- No Azure Firewall DNS proxy is enabled.
- Initial allow rules prefer application rules for HTTPS FQDN filtering.
- No NAT Gateway is attached to `AzureFirewallSubnet`.
- Diagnostics use resource-specific tables in Log Analytics.

### FR-7: Application Gateway WAF

Description: Deploy Application Gateway WAF v2 as the public entry point for `api.lab.consultwithcloud.com`.

Rationale: APIM Premium v2 gateway is privately reachable through VNet injection, so public ingress needs a reverse proxy and WAF.

Acceptance criteria:

- WAF mode is `Prevention`.
- Autoscale is enabled with minimum `1` and maximum `3`.
- Listener hostname is `api.lab.consultwithcloud.com`.
- Listener uses the Key Vault certificate after certificate import.
- Backend uses HTTPS to APIM with host/SNI `api.lab.consultwithcloud.com`.
- Health probe uses APIM gateway health path `/status-0123456789abcdef`.
- WAF source allow lists are parameterized.
- No initial WAF exclusions are configured.

### FR-8: APIM Premium v2

Description: Deploy APIM Premium v2 in the hub VNet with VNet injection.

Rationale: Premium v2 supports the required private gateway pattern in `swedencentral`, and the same region is currently listed for the Azure OpenAI Responses API that later AI backend scenarios require.

Acceptance criteria:

- SKU is `PremiumV2` with `1` initial unit.
- APIM subnet is `snet-apim`.
- APIM gateway custom domain is bound to `api.lab.consultwithcloud.com` after the certificate exists and public DNS resolution to Application Gateway is visible.
- Publisher name is `Consult With Cloud`.
- Publisher email is `hari.s@consultwithcloud.com`.
- APIM has system-assigned managed identity.
- APIM is managed through Azure portal, ARM, and GitHub Actions only.
- No APIM direct management endpoint is exposed.
- Developer portal remains on the default APIM hostname and is secured manually with Microsoft Entra ID sign-in.

### FR-9: End-to-end TLS

Description: Encrypt client-to-Application Gateway and Application Gateway-to-APIM traffic.

Rationale: The public edge terminates TLS for WAF inspection, then re-encrypts to the private APIM gateway.

Acceptance criteria:

- The same Let's Encrypt certificate for `api.lab.consultwithcloud.com` is stored in Key Vault and referenced by Application Gateway and APIM.
- Key Vault certificate references use versionless secret URIs where supported.
- Backend HTTPS settings preserve the expected host/SNI.
- mTLS is not enabled in the first pass.

### FR-10: DNS

Description: Create public and private DNS records required by the edge design.

Rationale: Public clients resolve Application Gateway, while Application Gateway must resolve APIM privately.

Acceptance criteria:

- Public DNS child zone `lab.consultwithcloud.com` exists in Azure DNS.
- The deployment outputs the Azure DNS name servers required to delegate `lab.consultwithcloud.com` from Cloudflare.
- `api` A record in that child zone is an alias to the Application Gateway public IP.
- A private DNS zone or equivalent private record maps APIM gateway hostname to the APIM private IP and is linked to the hub VNet.
- No Azure DNS Private Resolver is deployed.

### FR-11: Key Vault

Description: Deploy Key Vault Standard for certificate storage.

Rationale: Application Gateway and APIM need a managed certificate source.

Acceptance criteria:

- SKU is `Standard`.
- Soft delete and purge protection are enabled with 90-day retention.
- Diagnostic settings send logs and metrics to Log Analytics.
- Public network access is restricted to selected networks and the runner NAT public IP.
- Application Gateway user-assigned identity can read certificate secrets.
- APIM system-assigned identity can read the certificate.

### FR-12: ACR

Description: Deploy ACR Premium in the hub.

Rationale: Future AKS and build flows need a private container registry.

Acceptance criteria:

- SKU is `Premium`.
- Admin user is disabled.
- Diagnostic settings send logs and metrics to Log Analytics.
- Public network access is restricted to selected networks and the runner NAT public IP.
- No private endpoint is created in this pass.

### FR-13: Certificate automation

Description: Provide a separate manual GitHub Actions workflow for Let's Encrypt DNS-01 issuance and Key Vault import.

Rationale: ACME issuance is procedural and requires the DNS zone and Key Vault to exist first.

Acceptance criteria:

- Workflow is `workflow_dispatch` only.
- Workflow uses OIDC, not a client secret.
- Workflow imports the certificate using fixed Key Vault certificate object name `cert-lab-consultwithcloud-com`.
- Workflow imports a PFX certificate for Application Gateway TLS termination.
- The lab SAN certificate object name is `cert-lab-consultwithcloud-com`.
- Workflow has the same repository, actor, branch, runner, and environment guards as deployment.

### FR-14: GitHub Actions guardrails

Description: Deployments must not be triggerable by public contributors or forked pull requests.

Rationale: The repo is public and deploys from a runner with Azure network access.

Acceptance criteria:

- No deployment workflow has `pull_request` or `pull_request_target`.
- Deployment workflows use `workflow_dispatch` only.
- Jobs run on runner group `consultwithcloud-azure` with label `[gh-linux]`.
- Jobs have guards for:
  - expected actor `haripraghash`
  - literal repository `collaborationwithothers/azure-apim-ai-gateway-architecture-lab`
  - `refs/heads/main`
- Workflow permissions are:
  - `contents: read`
  - `id-token: write` only on Azure jobs that need OIDC
- The fixed `dev` GitHub Environment approval is required before Azure-changing jobs.
- Deployment workflows pin third-party actions to full commit SHAs.
- Planned spoke demo workflows for AKS power control, GitOps bootstrap, APIOps
  publishing, ACR image build or push, image promotion, and lab SAN certificate
  issuance follow the same guardrail posture before they are added.
- Azure-changing workflows reject `push`, `pull_request`, and
  `pull_request_target` triggers.
- Planned Azure-changing workflows do not accept caller-controlled Azure target
  names such as resource group, AKS cluster, ACR, APIM, Key Vault, DNS zone,
  certificate, subscription, tenant, Foundry account, or model deployment names.

### FR-15: Diagnostics

Description: Send diagnostics to a 30-day Log Analytics workspace.

Rationale: The lab must demonstrate observable infrastructure behavior.

Acceptance criteria:

- Log Analytics workspace is `log-cwc-ai-gw-swc-001`.
- Retention is `30` days.
- Azure Firewall uses resource-specific tables.
- Application Gateway WAF, APIM, Key Vault, and ACR diagnostics are enabled.
- APIM request and response body logging is enabled.
- README warns that body logging can ingest prompts, completions, and sensitive data.

### FR-16: Azure resource providers

Description: Deployment workflow apply must register required Azure resource providers, while what-if must only check registration state.

Rationale: APIM Premium v2 VNet injection and subnet delegation require registered providers.

Acceptance criteria:

- Workflow registers:
  - `Microsoft.Network`
  - `Microsoft.ApiManagement`
  - `Microsoft.ContainerRegistry`
  - `Microsoft.KeyVault`
  - `Microsoft.Insights`
  - `Microsoft.OperationalInsights`
  - `Microsoft.Web`

## Non-Functional Requirements

### NFR-1: Safety

All cloud-changing workflows must be manual, guarded, environment-approved, and OIDC-based.

### NFR-2: Cost control

Use low initial capacity where compatible with requirements: APIM Premium v2 `1` unit, Application Gateway autoscale `1` to `3`, Azure Firewall Standard, 30-day Log Analytics retention, and no DDoS Protection.

### NFR-3: Maintainability

Use Azure Verified Modules where they fit and pin versions explicitly. Use raw Bicep where cross-resource wiring is clearer or AVM support is incomplete.

### NFR-4: Idempotence

The Bicep deployment and workflows must be safe to re-run. Certificate issuance must handle existing Key Vault certificate versions without replacing unrelated resources.

### NFR-5: Documentation

README, infra README, requirements, design log, and ExecPlan must remain aligned.

## Data, Security, and Compliance

- APIM body logging is intentionally enabled for the lab and must be clearly warned about because it can ingest prompts, completions, request bodies, response bodies, secrets, or regulated data.
- Do not commit secrets, PFX files, ACME account keys, tenant credentials, or generated deployment outputs.
- The certificate workflow uses the same OIDC identity path as the infrastructure workflow. Deployment service principals must receive Key Vault certificate operation access through the permanent deployment admin group.
- The permanent deployment admin group must receive Key Vault Administrator at the lab vault scope and AcrPush at the lab ACR scope.
- The workflow identity must already have management-plane permission to create role assignments before the Bicep deployment can grant Key Vault or ACR access.
- APIM receives Key Vault Secrets User and Key Vault Certificate User. Application Gateway receives Key Vault Secrets User.
- ACR access for APIM, Application Gateway, and future workload identities is intentionally deferred until a concrete container image consumer exists.
- The APIM Premium v2 injected subnet must include the service dependency NSG rules required for outbound Storage and Azure Key Vault access.
- The Application Gateway and APIM subnets must have Key Vault service endpoint access to the vault so managed identities can retrieve TLS certificates through restricted vault networking.
- Key Vault must use soft delete and purge protection.
- ACR admin user must remain disabled.
- Public repo workflows must not run from pull requests or forks.
- WAF runs in Prevention mode from the first deployment.

## Networking and Connectivity

| Item | Decision |
|---|---|
| Region | `swedencentral` for all new resources |
| Hub VNet | `10.10.0.0/16` |
| Spoke VNet | `10.20.0.0/16` |
| Runner VNet | Existing `172.16.0.0/16`, likely North Europe |
| Peering | Direct hub-spoke, runner-hub, and runner-spoke peering |
| APIM subnet routing | No default UDR to firewall |
| App Gateway subnet routing | No default UDR to firewall |
| Spoke workload routing | `0.0.0.0/0` to Azure Firewall |
| DNS resolver | Azure-provided DNS, no Azure DNS Private Resolver |
| Firewall DNS proxy | Disabled |

## Open Questions

- What is the current public IP address associated with NAT Gateway `natgw-gh-actions-neu`? The `dev` GitHub Environment should define `RUNNER_ALLOWED_PUBLIC_IP_CIDR` before workflow deployment.
- What will the expected repository name be after moving to a GitHub organization? The workflow currently uses a literal repository guard and must be deliberately changed during the move.
- Which exact AVM module versions will be selected during implementation?

## Assumptions

- The deployment identity can be granted `Contributor` at subscription scope and an additional role assignment-capable role where needed before the template creates scoped role assignments.
- The existing self-hosted runner is reachable through the runner VNet and has Azure CLI, Bicep, and required certificate tooling installed or installable.
- The parent DNS zone `consultwithcloud.com` can delegate `lab.consultwithcloud.com` to Azure DNS name servers.
- APIM Premium v2 capacity and the required Azure OpenAI model quota are available in `swedencentral` at deployment time.

## Sources

- [APIM v2 tiers overview](https://learn.microsoft.com/en-us/azure/api-management/v2-service-tiers-overview)
- [APIM v2 tier region availability](https://learn.microsoft.com/en-us/azure/api-management/api-management-region-availability)
- [APIM SKU list API](https://learn.microsoft.com/en-us/rest/api/apimanagement/api-management-skus/list?view=rest-apimanagement-2024-05-01)
- [Azure OpenAI Responses API](https://learn.microsoft.com/en-us/azure/foundry/openai/how-to/responses)
- [Inject APIM Premium v2 in a private VNet](https://learn.microsoft.com/en-us/azure/api-management/inject-vnet-v2)
- [Configure APIM custom domains](https://learn.microsoft.com/en-us/azure/api-management/configure-custom-domain)
- [Application Gateway WAF overview](https://learn.microsoft.com/en-us/azure/web-application-firewall/ag/ag-overview)
- [Application Gateway backend settings](https://learn.microsoft.com/en-us/azure/application-gateway/configuration-http-settings)
- [Azure Firewall structured logs](https://learn.microsoft.com/en-us/azure/firewall/firewall-structured-logs)
- [Azure VNet peering overview](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-peering-overview)
- [Azure DNS alias records](https://learn.microsoft.com/en-us/azure/dns/dns-alias)
- [Delegate a domain to Azure DNS](https://learn.microsoft.com/en-us/azure/dns/dns-delegate-domain-azure-dns)
- [Key Vault soft delete overview](https://learn.microsoft.com/en-us/azure/key-vault/general/soft-delete-overview)
- [ACR authentication options](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-authentication)
- [Deploy Bicep with GitHub Actions](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-github-actions)
- [GitHub OIDC reference](https://docs.github.com/en/actions/reference/security/oidc)
- [GitHub self-hosted runner groups](https://docs.github.com/actions/how-tos/manage-runners/self-hosted-runners/manage-access)
