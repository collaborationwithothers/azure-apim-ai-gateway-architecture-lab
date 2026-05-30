# Scenario: Hub-Spoke Network Foundation

## 1. Business problem

The lab needs a real network foundation for an AI gateway, not just APIM policy
examples. Public clients need a controlled HTTPS entry point, APIM needs private
gateway reachability, future workloads need a place to land, and the self-hosted
runner needs enough network access to deploy and validate the platform.

The hard part is not creating a hub VNet and a spoke VNet. The hard part is
choosing which controls belong in the hub, which decisions can wait until the
spoke workload exists, and which Azure routing patterns are safe for Application
Gateway, APIM, Azure Firewall, and VNet peering.

## 2. Scenario intent

This scenario documents the architectural thinking behind the hub-spoke setup
used by `requirements/001-hub-spoke-apim-edge-platform.md` and
`design-log/001-hub-spoke-apim-edge-platform.md`.

The spoke is intentionally not fully fleshed out. It is a reserved workload
boundary with egress routing, future private endpoint space, and future AKS
space. The scenario focuses on why that boundary exists, what the hub owns now,
and which spoke choices remain open until a workload is designed.

## 3. Requirements

### Functional requirements

- Put shared ingress, egress, observability, certificate, DNS, and APIM gateway
  services in the hub.
- Put future workload subnets in the spoke without deploying a workload yet.
- Expose `api.consultwithcloud.com` through Application Gateway WAF.
- Keep APIM Premium v2 reachable privately through VNet injection.
- Route spoke workload egress through Azure Firewall.
- Peer the existing self-hosted runner VNet directly to hub and spoke because
  VNet peering is not transitive.

### Non-functional requirements

- Keep the first deployment explainable and manually reviewable.
- Avoid over-designing the spoke before workload requirements exist.
- Keep public repository deployment workflows manual, guarded, and OIDC-based.
- Make routing, DNS, certificate, logging, and cost tradeoffs explicit.

## 4. Constraints

- All new resources target `northcentralus`, which is currently listed for both
  APIM Premium v2 and the Azure OpenAI Responses API.
- APIM uses Premium v2 with VNet injection.
- Application Gateway WAF v2 is the public HTTPS edge.
- Azure Firewall Standard controls spoke egress, not Application Gateway or APIM
  control-plane traffic.
- No AKS cluster is deployed in this scenario.
- No Azure DNS Private Resolver, VPN Gateway, ExpressRoute, Bastion, DDoS
  Protection, or private endpoints are deployed in the first pass.
- Key Vault and ACR use public network restrictions rather than private
  endpoints in this pass.

## 5. Architecture summary

The hub VNet hosts shared platform services:

- Application Gateway WAF for public ingress.
- APIM Premium v2 private gateway for API policy enforcement.
- Azure Firewall Standard for spoke workload egress.
- Log Analytics for platform diagnostics.
- Key Vault for edge certificate storage.
- ACR for future workload images.
- DNS zones and records needed for public ingress and private APIM reachability.

The spoke VNet hosts workload-ready network space:

- `snet-workload` for future private APIs or application services.
- `snet-private-endpoints` for future private endpoints.
- `snet-aks` for a future AKS cluster.
- Route tables that send future workload and AKS outbound traffic to Azure
  Firewall.

The existing runner VNet is not a workload spoke. It is an operational network
that needs direct peering to both hub and spoke for deployment and validation.

## 6. Design decision

### Chosen approach

Use a customer-managed hub-spoke topology with a central hub in `northcentralus`, one
workload spoke, and direct peering to the existing runner VNet.

### Alternatives considered

| Option                       | Pros                                                 | Cons                                                              | Decision         |
| ---------------------------- | ---------------------------------------------------- | ----------------------------------------------------------------- | ---------------- |
| Single VNet                  | Simple routing and fewer resources                   | Weak workload isolation and poor future expansion boundary        | Rejected         |
| Hub with reserved spoke      | Clear shared-service boundary and room for workloads | More routing and DNS decisions                                    | Chosen           |
| Azure Virtual WAN hub        | Managed transit and scale features                   | More service scope than needed for this lab pass                  | Deferred         |
| Full mesh peerings           | Direct paths between every VNet                      | Operationally noisy and does not express shared-service ownership | Rejected for now |
| Private endpoints everywhere | Stronger service isolation                           | More DNS and deployment complexity before workloads exist         | Deferred         |

## 7. Implementation approach

Start with subscription-scope Bicep that creates the hub and spoke resource
groups. Deploy the hub shared services first, then the spoke network and route
tables, then peerings, then APIM, Application Gateway, workflows, and
certificate automation.

The first live validation is not an end-user workload. It is a platform
validation:

1. Bicep builds.
2. What-if shows the expected hub and spoke resources.
3. Peerings connect hub, spoke, and runner.
4. Application Gateway resolves and reaches private APIM.
5. Diagnostics appear in Log Analytics.

## 8. What this scenario demonstrates

Hub-spoke design is an ownership and control model, not just a VNet diagram. The
hub centralizes shared controls. The spoke reserves space for workloads without
inventing a workload prematurely. The main tradeoff is that central control
improves governance but increases routing, DNS, certificate, and troubleshooting
complexity.

## 9. Sources

- [Microsoft Learn, Hub-spoke network topology in Azure][src-hub-spoke]
- [Microsoft Learn, Azure Firewall and Application Gateway][src-fw-agw]
- [Microsoft Learn, Inject Azure API Management Premium v2][src-apim-vnet]
- [Microsoft Learn, Create or change VNet peering][src-peering]
- [Microsoft Learn, Application Gateway infrastructure][src-agw-infra]

[src-hub-spoke]:
  https://learn.microsoft.com/en-us/azure/architecture/networking/architecture/hub-spoke
[src-fw-agw]:
  https://learn.microsoft.com/en-us/azure/architecture/example-scenario/gateway/firewall-application-gateway
[src-apim-vnet]:
  https://learn.microsoft.com/en-us/azure/api-management/inject-vnet-v2
[src-peering]:
  https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-manage-peering
[src-agw-infra]:
  https://learn.microsoft.com/en-us/azure/application-gateway/configuration-infrastructure
