# Hub-Spoke Bicep Deployment

`infra/bicep/main.bicep` is the subscription-scope entry point for the hub-spoke APIM edge platform. It creates the hub and spoke resource groups, deploys hub shared services, deploys spoke network foundations, and adds direct peerings to the existing self-hosted runner VNet.

## Module Layout

`infra/bicep/main.bicep` stays as the subscription-scope deployment target. It creates the hub and spoke resource groups and delegates resource-group deployments to modules.

`infra/bicep/modules/hub.bicep` is a hub facade module. It preserves the outputs consumed by `main.bicep` while delegating hub resources to focused child modules:

| Module | Responsibility |
| --- | --- |
| `hub-network.bicep` | Hub VNet, APIM NSG, and subnet ID outputs. |
| `hub-observability.bicep` | Log Analytics workspace and workspace-based Application Insights. |
| `hub-security.bicep` | ACR, Application Gateway managed identity, and runner IP network restrictions for ACR. |
| `hub-firewall.bicep` | Firewall Policy, Azure Firewall public IP, and Azure Firewall. |
| `hub-apim.bicep` | APIM Premium v2, APIM Azure Monitor diagnostic configuration, private DNS zone, hub VNet link, and private APIM A record. |
| `hub-edge.bicep` | WAF policy, Application Gateway public IP, Application Gateway, and public DNS alias in the existing lab DNS zone. |
| `hub-rbac.bicep` | ACR role assignment for deployment administrators at the hub resource group scope. |
| `hub-diagnostics.bicep` | Azure Monitor diagnostic settings for hub resources. |
| `shared-key-vault-rbac.bicep` | Shared Key Vault role assignments deployed at the shared resource group scope. |
| `shared-key-vault-diagnostics.bicep` | Shared Key Vault diagnostic settings deployed at the shared resource group scope. |
| `shared-public-dns.bicep` | Public DNS alias records deployed into the existing shared lab DNS zone. |

Keep cross-module contracts explicit. Pass resource names, IDs, principal IDs, and private IPs through module parameters and outputs instead of relying on implicit resource ordering across files.

## Spoke Output Contract

The spoke module exposes non-sensitive network outputs so later slices can
attach AKS, private endpoints, Redis, Foundry, GitOps, and workload components
without rediscovering resource IDs. `infra/bicep/outputs.bicep` shapes those
values into the top-level `spokeNetwork` deployment output. These outputs are
contracts for downstream modules and workflows. They are not proof that those
downstream resources exist.

Current spoke outputs:

- `spokeVnetId`
- `spokeVnetName`
- `workloadSubnetId`
- `privateEndpointsSubnetId`
- `aksSubnetId`
- `workloadRouteTableId`
- `aksRouteTableId`

The workload and AKS route tables continue to send `0.0.0.0/0` to Azure
Firewall through the existing `VirtualAppliance` next hop. Issue #30 does not
deploy AKS, Redis, Foundry, Istio, Argo CD, private endpoints, or application
workloads.

## Issue #32 Full Demo Contract

Issue #32 adds only a Bicep parameter and output contract for later full demo
spoke slices. It does not deploy AKS, Redis, Foundry/model backends, GitOps,
BFF resources, private endpoints, Kubernetes configuration, Istio, Argo CD, or
workloads.

The contract reserves these public names:

- `lab.consultwithcloud.com`
- `api.lab.consultwithcloud.com`
- `app.lab.consultwithcloud.com`
- `argo.lab.consultwithcloud.com`

Feature flags for AKS, Redis, Foundry/model backend, GitOps, and BFF support
default to `false`. The related sizing and configuration parameters are
non-secret placeholders for later implementation issues.

`infra/bicep/outputs.bicep` exposes the non-sensitive
`spokeFullDemoContract` output. The output includes DNS names, feature states,
AKS sizing placeholders, Redis placeholders, Foundry/model placeholders, GitOps
settings, diagnostic settings, BFF app registration placeholders, unresolved
decisions, and dependency markers. It must not include keys, tokens,
kubeconfigs, Redis access keys, certificate material, tenant secrets, client
secrets, or secret identifiers.

Unresolved decisions for later issues:

- Redis product choice remains unresolved.
- model availability remains unresolved and must be checked live before deployment.
- certificate name remains unresolved for the lab certificate.
- Argo SSO groups remain unresolved.
- BFF app registration remains unresolved.

The persistent bootstrap slice is the first implementation dependency because
the delegated `lab.consultwithcloud.com` public DNS zone and shared Key Vault
must exist before future hostname, certificate, and listener slices depend on
them.

AVM fit for issue #32 was checked against the Azure Verified Modules Bicep
module index. No new resource module is added because this slice is a
contract-only parameter and output change. Later resource implementation issues
must check and document AVM fit again before adding AKS, Redis, Foundry/model,
GitOps, private endpoint, or workload modules.

## Parameters

| Parameter | Purpose |
| --- | --- |
| `location` | Azure region for new resources. Defaults to `swedencentral`. |
| `environmentName` | Tag value for the lab environment. Defaults to `dev`. |
| `expectedRepository` | Repository value carried through deployment metadata. Defaults to this repository. |
| `runnerAllowedPublicIp` | Runner NAT public IP in CIDR form, for example `203.0.113.10/32`. Required. |
| `enablePublicEdge` | Deploys Application Gateway and the public DNS alias after the certificate exists. Defaults to `false`. |
| `customDomainCertificateSecretUri` | Optional versionless certificate secret URI for direct Bicep runs. The guarded workflow infers it from `cert-lab-consultwithcloud-com` when `enablePublicEdge` is `true`. |
| `deploymentAdminGroupObjectId` | Microsoft Entra group object ID for permanent deployment administrators. Defaults to the lab deployment admin group. |
| `wafAllowedSourceCidrs` | Optional source CIDR allow list for the WAF policy. When set, requests outside the list are blocked before managed rules run. Empty means no custom source block rule. |
| `runnerVnetResourceGroupName` | Existing runner VNet resource group. Defaults to `rg-dv-gh-actions-neu`. |
| `runnerVnetName` | Existing runner VNet. Defaults to `vnet-dv-gh-actions-neu`. |
| `labDnsZoneName` | Future lab DNS zone contract value. Defaults to `lab.consultwithcloud.com`. |
| `sharedResourceGroupName` | Existing persistent shared resource group created by `.github/workflows/bootstrap-persistent.yml`. Defaults to `rg-cwc-ai-gw-shared-swc-001`. |
| `sharedKeyVaultName` | Existing persistent shared Key Vault created by `.github/workflows/bootstrap-persistent.yml`. Defaults to `kv-cwc-aigw-shr-swc-001`. |
| `apiLabHostname` | Public Application Gateway API hostname contract value. Defaults to `api.lab.consultwithcloud.com`. |
| `appLabHostname` | Future BFF app hostname contract value. Defaults to `app.lab.consultwithcloud.com`. |
| `argoLabHostname` | Future GitOps control plane hostname contract value. Defaults to `argo.lab.consultwithcloud.com`. |
| `enableAks` | Future AKS feature flag. Defaults to `false`. |
| `enableRedis` | Future Redis feature flag. Defaults to `false`. |
| `enableFoundryBackend` | Future Foundry/model backend feature flag. Defaults to `false`. |
| `enableGitOps` | Future GitOps feature flag. Defaults to `false`. |
| `enableBff` | Future BFF support feature flag. Defaults to `false`. |
| `aksSkuTier`, `aksNodeVmSize`, `aksNodeCount`, `aksKubernetesVersion`, `aksEnablePrivateCluster`, `aksOutboundType` | Future AKS sizing and configuration placeholders. |
| `redisSkuName`, `redisCapacity`, `redisFamily`, `redisMinimumTlsVersion` | Future Redis settings placeholders. |
| `foundryProjectName`, `foundryModelName`, `foundryModelVersion`, `foundryModelDeploymentName`, `foundryModelDeploymentSkuName`, `foundryModelDeploymentCapacity` | Future Foundry/model backend settings placeholders. |
| `gitOpsRepositoryUrl`, `gitOpsRevision`, `gitOpsPath`, `gitOpsAutoSync`, `gitOpsAutoPrune` | Future GitOps settings placeholders. |
| `diagnosticLogRetentionDays`, `enableVerboseDiagnostics` | Future diagnostics settings placeholders. |
| `bffAppRegistrationClientId` | Future BFF Microsoft Entra app registration client ID placeholder. Empty means unresolved. |

## Expected Resource Groups

The template creates these resource groups in `swedencentral`:

- `rg-cwc-ai-gw-hub-swc-001`
- `rg-cwc-ai-gw-spoke-swc-001`

The existing runner VNet is referenced, not recreated, in `rg-dv-gh-actions-neu`.
The persistent shared resource group `rg-cwc-ai-gw-shared-swc-001` is created
or updated only by `.github/workflows/bootstrap-persistent.yml`.

## Public DNS Zones

The persistent bootstrap template creates the Azure DNS public child zone
`lab.consultwithcloud.com` in `rg-cwc-ai-gw-shared-swc-001`. The hub-spoke
template references that zone as an existing resource and creates records in it.
That zone, not `api.lab.consultwithcloud.com` or `api.consultwithcloud.com`, is
the public DNS zone. The public API record is the `api` label under that zone.

Use the `labPublicDnsZoneNameServers` deployment output to create `NS` records
for `lab` in Cloudflare, which owns the parent `consultwithcloud.com` zone.
Cloudflare delegation is an operator action and is not performed by Bicep.

The lab hostname contract is:

- `api.lab.consultwithcloud.com`
- `app.lab.consultwithcloud.com`
- `argo.lab.consultwithcloud.com`

## Deployment Flow

Run persistent bootstrap first in `apply` mode. This creates
`rg-cwc-ai-gw-shared-swc-001`, shared Key Vault `kv-cwc-aigw-shr-swc-001`, and
the `lab.consultwithcloud.com` public DNS zone. The bootstrap workflow is
create/update only and has no destroy mode.

Run phase 1 of the hub-spoke deployment with `enablePublicEdge = false`. This
creates the hub and spoke foundations, APIM, Log Analytics, ACR, Firewall, and
peerings without binding the certificate-dependent edge resources. It references
the shared Key Vault and public DNS zone as existing resources.

### Future Lab Zone Delegation

After phase 1 completes, copy the `labPublicDnsZoneNameServers` output and add
those name servers as `NS` records for `lab` in the Cloudflare
`consultwithcloud.com` zone. This prepares the full demo hostnames only. It
does not issue a certificate or bind an APIM custom hostname.

The persistent bootstrap workflow always looks up the fixed GitHub runner
subnet `snet-github-actions-private-runner-neu` in `vnet-dv-gh-actions-neu` and
passes that subnet resource ID to Bicep for the shared vault network rules. This
keeps runner access on the Key Vault service endpoint path instead of relying
only on the runner NAT IP firewall rule.

After the hub subnets exist, rerun persistent bootstrap in `apply` mode. The
workflow also looks for `snet-appgw` and `snet-apim` in
`vnet-cwc-ai-gw-hub-swc-001`. If both exist, it passes their subnet resource
IDs along with the runner subnet ID to Bicep and updates the shared vault
network rules. If neither exists, it passes only the runner subnet ID for the
first bootstrap run. If only one exists, the workflow fails because the hub
network is in a partial state. This keeps the manual Cloudflare delegation
intact.

### Lab API Hostname Flow

The public API edge hostname is `api.lab.consultwithcloud.com`. Delegate the
parent DNS zone `consultwithcloud.com` so `lab.consultwithcloud.com` uses the
Azure DNS name servers created by the lab child zone. Then run
`.github/workflows/certificate-issue.yml` to create temporary ACME DNS-01 TXT
records in `lab.consultwithcloud.com` and import the Let's Encrypt SAN
certificate into Key Vault as `cert-lab-consultwithcloud-com`. Parent zone
delegation must be in place before production issuance. The certificate
workflow uses the fixed `rg-cwc-ai-gw-shared-swc-001` public DNS resource group
and `kv-cwc-aigw-shr-swc-001` Key Vault. It installs `certbot` if the runner
image does not already provide it and imports a PFX file because
Application Gateway TLS termination requires PFX certificates in Key Vault.

Run phase 2 with `enablePublicEdge = true` after the certificate exists. The
guarded workflow looks up `cert-lab-consultwithcloud-com` in
`kv-cwc-aigw-shr-swc-001`, strips the secret version, and passes the versionless
URI to Bicep. This deploys Application Gateway and creates the public DNS alias
record for `api.lab.consultwithcloud.com`.

Application Gateway terminates public TLS for `api.lab.consultwithcloud.com` and
re-encrypts to the APIM default gateway hostname
`apim-cwc-ai-gw-swc-001.azure-api.net`. APIM does not bind
`api.lab.consultwithcloud.com` as a custom hostname. The deployment creates a
private DNS zone named `apim-cwc-ai-gw-swc-001.azure-api.net`, adds an apex A
record to the APIM private IP, and links that zone to both the hub VNet and the
spoke VNet as resolution-only links. This keeps the public lab hostname on
Application Gateway and avoids the APIM Premium v2 public CNAME ownership check.

## Destroy Flow

Use `.github/workflows/infra-destroy.yml` to clean up the lab when it is not in
use. The workflow is manual, destructive, and guarded to run only from `main` by
the repository owner through the fixed `dev` GitHub Environment.

Preview mode is non-mutating and lists the exact cleanup targets. Destroy mode
requires the exact confirmation phrase `destroy` before it removes the runner-side
peerings `peer-to-cwc-ai-gw-hub` and `peer-to-cwc-ai-gw-spoke` from
`vnet-dv-gh-actions-neu` in `rg-dv-gh-actions-neu`, then deletes only these lab
resource groups:

- `rg-cwc-ai-gw-hub-swc-001`
- `rg-cwc-ai-gw-spoke-swc-001`

The workflow retains the runner VNet, the runner resource group, subscription
deployment history, `rg-cwc-ai-gw-shared-swc-001`, `kv-cwc-aigw-shr-swc-001`,
the `lab.consultwithcloud.com` public DNS zone, and the manual Cloudflare
delegation. After deleting the hub and spoke resource groups, destroy mode
purges soft-deleted APIM service `apim-cwc-ai-gw-swc-001` in `swedencentral`.
APIM purge is permanent.

## Local Validation

Run these checks before opening a pull request:

    git diff --check
    az bicep build --file infra/bicep/persistent.bicep
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

Run persistent bootstrap what-if:

    az deployment sub what-if \
      --name apim-ai-gateway-persistent-swc \
      --location swedencentral \
      --template-file infra/bicep/persistent.bicep \
      --parameters runnerAllowedPublicIp=<runner-nat-public-ip>

Run hub-spoke what-if:

    az deployment sub what-if \
      --name apim-ai-gateway-lab-swc \
      --location swedencentral \
      --template-file infra/bicep/main.bicep \
      --parameters runnerAllowedPublicIp=<runner-nat-public-ip> enablePublicEdge=false

Run persistent bootstrap apply:

    az deployment sub create \
      --name apim-ai-gateway-persistent-swc \
      --location swedencentral \
      --template-file infra/bicep/persistent.bicep \
      --parameters runnerAllowedPublicIp=<runner-nat-public-ip>

Run hub-spoke apply:

    az deployment sub create \
      --name apim-ai-gateway-lab-swc \
      --location swedencentral \
      --template-file infra/bicep/main.bicep \
      --parameters runnerAllowedPublicIp=<runner-nat-public-ip> enablePublicEdge=false

For phase 2, set `enablePublicEdge=true` after the confirmed lab certificate
exists in Key Vault. The guarded workflow infers
`customDomainCertificateSecretUri` from the fixed lab certificate object. The
certificate workflow uses the same OIDC identity path as the infrastructure
workflow and relies on deployment admin group membership for Key Vault
certificate operations.

Use the guarded workflow for normal operation. Manual commands are for local operator preflight only.

To inspect the lab zone delegation values after an apply, read the
subscription deployment output:

    az deployment sub show \
      --name apim-ai-gateway-lab-swc \
      --query "properties.outputs.labPublicDnsZoneNameServers.value" \
      --output tsv

## RBAC Model

The permanent deployment admin group receives Key Vault Administrator at the
shared Key Vault scope and AcrPush at the lab ACR scope. These assignments let
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

The persistent bootstrap pass uses pinned Azure Verified Modules
`br/public:avm/res/key-vault/vault:0.12.1` for shared Key Vault and
`br/public:avm/res/network/dns-zone:0.6.0` for the
`lab.consultwithcloud.com` public DNS zone because both resources are isolated
fits. The `api` alias record remains local raw Bicep because it is wired
directly to the Application Gateway public IP in the edge slice.

The rest of the deployment uses local raw Bicep resources. The deployment needs
tight cross-resource wiring for APIM private gateway, Application Gateway,
private DNS, diagnostic settings, route tables, and VNet peerings. Local Bicep
keeps the first deployable slice inspectable and avoids wrapping many AVM
modules before the lab has stable parameters. Revisit AVM composition after the
first successful what-if and apply.

## Open Operational Inputs

- `RUNNER_ALLOWED_PUBLIC_IP_CIDR` variable on the `dev` GitHub Environment.
- Management-plane role assignment permissions for the workflow identity before first deployment.
- `dev` GitHub Environment approval setup for Azure-changing jobs.
- Azure federated identity credentials for GitHub OIDC.
- Parent DNS zone delegation for `lab.consultwithcloud.com`.
- Key Vault certificate object `cert-lab-consultwithcloud-com`.
- Confirmation that APIM Premium v2 capacity and required Azure OpenAI model quota are available in `swedencentral` at deployment time.

## Data Warning

APIM body logging is intentionally enabled for this lab. It can ingest prompts, completions, request bodies, response bodies, secrets, or regulated data into Azure Monitor and Log Analytics. Do not send real sensitive traffic through the lab unless logging and retention have been reviewed.
