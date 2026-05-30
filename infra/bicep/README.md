# Hub-Spoke Bicep Deployment

`infra/bicep/main.bicep` is the subscription-scope entry point for the hub-spoke APIM edge platform. It creates the hub and spoke resource groups, deploys hub shared services, deploys spoke network foundations, and adds direct peerings to the existing self-hosted runner VNet.

## Module Layout

`infra/bicep/main.bicep` stays as the subscription-scope deployment target. It creates the hub and spoke resource groups and delegates resource-group deployments to modules.

`infra/bicep/modules/hub.bicep` is a hub facade module. It preserves the outputs consumed by `main.bicep` while delegating hub resources to focused child modules:

| Module | Responsibility |
| --- | --- |
| `hub-network.bicep` | Hub VNet, APIM NSG, and subnet ID outputs. |
| `hub-observability.bicep` | Log Analytics workspace and workspace-based Application Insights. |
| `hub-security.bicep` | Key Vault, ACR, Application Gateway managed identity, and runner IP network restrictions. |
| `hub-firewall.bicep` | Firewall Policy, Azure Firewall public IP, and Azure Firewall. |
| `hub-apim.bicep` | APIM Premium v2, APIM Azure Monitor diagnostic configuration, private DNS zone, hub VNet link, and private APIM A record. |
| `hub-edge.bicep` | WAF policy, Application Gateway public IP, public DNS child zone, Application Gateway, and public DNS alias. |
| `hub-rbac.bicep` | Key Vault and ACR role assignments for deployment administrators, APIM, and Application Gateway. |
| `hub-diagnostics.bicep` | Azure Monitor diagnostic settings for hub resources. |

Keep cross-module contracts explicit. Pass resource names, IDs, principal IDs, and private IPs through module parameters and outputs instead of relying on implicit resource ordering across files.

## Required Parameters

| Parameter | Purpose |
| --- | --- |
| `location` | Azure region for new resources. Defaults to `eastus2`. |
| `environmentName` | Tag value for the lab environment. Defaults to `dev`. |
| `expectedRepository` | Repository value carried through deployment metadata. Defaults to this repository. |
| `runnerAllowedPublicIp` | Runner NAT public IP in CIDR form, for example `203.0.113.10/32`. Required. |
| `enablePublicEdge` | Deploys Application Gateway and the public DNS alias after the certificate exists. Defaults to `false`. |
| `enableCustomDomain` | Binds the APIM custom domain after the public edge DNS record is created and resolvable. Defaults to `false`. |
| `customDomainCertificateSecretUri` | Versionless Key Vault secret URI for `cert-api-consultwithcloud-com`. |
| `deploymentAdminGroupObjectId` | Microsoft Entra group object ID for permanent deployment administrators. Defaults to the lab deployment admin group. |
| `wafAllowedSourceCidrs` | Optional source CIDR allow list for the WAF policy. When set, requests outside the list are blocked before managed rules run. Empty means no custom source block rule. |
| `runnerVnetResourceGroupName` | Existing runner VNet resource group. Defaults to `rg-dv-gh-actions-neu`. |
| `runnerVnetName` | Existing runner VNet. Defaults to `vnet-dv-gh-actions-neu`. |

## Expected Resource Groups

The template creates these resource groups in `eastus2`:

- `rg-cwc-ai-gw-hub-eus2-001`
- `rg-cwc-ai-gw-spoke-eus2-001`

The existing runner VNet is referenced, not recreated, in `rg-dv-gh-actions-neu`.

## Deployment Flow

Run phase 1 with `enablePublicEdge = false` and `enableCustomDomain = false`. This creates the hub and spoke foundations, DNS child zone, Key Vault, APIM, Log Analytics, ACR, Firewall, and peerings without binding the certificate-dependent edge resources.

After phase 1 completes, delegate the parent DNS zone `consultwithcloud.com` so `api.consultwithcloud.com` uses the Azure DNS name servers created in the child zone. Then run `.github/workflows/certificate-issue.yml` to create temporary ACME DNS-01 TXT records and import the Let's Encrypt certificate into Key Vault as `cert-api-consultwithcloud-com`. The certificate workflow imports a PFX file because Application Gateway TLS termination requires PFX certificates in Key Vault.

Run phase 2 with `enablePublicEdge = true` and `enableCustomDomain = false` after the certificate exists. This deploys Application Gateway and creates the public DNS alias record without binding the APIM v2 custom domain.

Run phase 3 with `enablePublicEdge = true` and `enableCustomDomain = true` only after public DNS for `api.consultwithcloud.com` resolves to Application Gateway. This binds `api.consultwithcloud.com` on APIM and creates the private APIM resolution record.

## Local Validation

Run these checks before opening a pull request:

    git diff --check
    az bicep build --file infra/bicep/main.bicep
    rg -n "pull_request|pull_request_target" .github/workflows
    rg -n "client-secret|password|PFX|BEGIN PRIVATE KEY|PLACEHOLDER_SECRET" .

Run the workflow guardrail tests after editing workflows:

    bash tools/validate-workflow-guardrails.sh
    bash tests/validate-workflow-guardrails-test.sh

## GitHub Environment Configuration

Set `RUNNER_ALLOWED_PUBLIC_IP_CIDR` as a variable on the `dev` GitHub
Environment before running `.github/workflows/infra-deploy.yml` in `what-if` or
`apply` mode. The value must be the runner NAT public IP in CIDR form, for
example `203.0.113.10/32`.

## Manual Azure Commands

Validate from an authenticated shell:

    az bicep build --file infra/bicep/main.bicep

Run what-if:

    az deployment sub what-if \
      --name apim-ai-gateway-lab \
      --location eastus2 \
      --template-file infra/bicep/main.bicep \
      --parameters runnerAllowedPublicIp=<runner-nat-public-ip> enablePublicEdge=false enableCustomDomain=false

Run apply:

    az deployment sub create \
      --name apim-ai-gateway-lab \
      --location eastus2 \
      --template-file infra/bicep/main.bicep \
      --parameters runnerAllowedPublicIp=<runner-nat-public-ip> enablePublicEdge=false enableCustomDomain=false

For phase 2, set `enablePublicEdge=true` after `cert-api-consultwithcloud-com` exists in Key Vault. For phase 3, keep `enablePublicEdge=true` and set `enableCustomDomain=true` after public DNS resolution is visible. The certificate workflow uses the same OIDC identity path as the infrastructure workflow and relies on deployment admin group membership for Key Vault certificate operations.

Use the guarded workflow for normal operation. Manual commands are for local operator preflight only.

## RBAC Model

The permanent deployment admin group receives Key Vault Administrator at the lab
Key Vault scope and AcrPush at the lab ACR scope. These assignments let
deployment service principals in the group perform certificate operations and
push platform images without granting those runtime rights to APIM or
Application Gateway.

The workflow identity must already have management-plane permission to create
role assignments before this template can grant Key Vault or ACR access. Key
Vault Administrator is a data-plane role on the vault; it does not grant
permission to create Azure RBAC assignments.

APIM receives Key Vault Secrets User and Key Vault Certificate User because it
references the gateway certificate from Key Vault. Application Gateway receives
Key Vault Secrets User because it retrieves the TLS certificate secret. ACR
access for APIM, Application Gateway, and future workload identities is
intentionally deferred until a concrete container image consumer exists. ACR
ABAC and repository-scoped permissions are also deferred to a separate design
decision.

## AVM Decision

This pass uses local raw Bicep resources instead of Azure Verified Modules. The deployment needs tight cross-resource wiring for APIM private gateway, Application Gateway, DNS alias records, private DNS, diagnostic settings, route tables, and VNet peerings. Local Bicep keeps the first deployable slice inspectable and avoids wrapping many AVM modules before the lab has stable parameters. Revisit AVM composition after the first successful what-if and apply.

## Open Operational Inputs

- `RUNNER_ALLOWED_PUBLIC_IP_CIDR` variable on the `dev` GitHub Environment.
- Management-plane role assignment permissions for the workflow identity before first deployment.
- `dev` GitHub Environment approval setup for Azure-changing jobs.
- Azure federated identity credentials for GitHub OIDC.
- Parent DNS zone delegation for `api.consultwithcloud.com`.
- Confirmation that APIM Premium v2 capacity is available in `eastus2` at deployment time.

## Data Warning

APIM body logging is intentionally enabled for this lab. It can ingest prompts, completions, request bodies, response bodies, secrets, or regulated data into Azure Monitor and Log Analytics. Do not send real sensitive traffic through the lab unless logging and retention have been reviewed.
