# Constraints: Hub-Spoke Network Foundation

## Fixed decisions

- Region is `eastus2` for new resources.
- Subscription is `c7a1d85d-159f-4cfc-bd13-51295c9acb96`.
- Hub address space is `10.10.0.0/16`.
- Spoke address space is `10.20.0.0/16`.
- Existing runner VNet address space is `172.16.0.0/16`.
- Public API hostname is `api.consultwithcloud.com`.
- APIM tier is Premium v2.
- Application Gateway WAF is the public ingress point.
- Azure Firewall Standard is the spoke egress point.

## Deliberate deferrals

- No AKS cluster yet.
- No private endpoints for Key Vault or ACR yet.
- No Azure DNS Private Resolver yet.
- No Azure Firewall DNS proxy yet.
- No VPN Gateway or ExpressRoute yet.
- No Bastion yet.
- No DDoS Protection plan yet.
- No production traffic load test yet.
- No full spoke workload design yet.

## Routing constraints

Application Gateway v2 should not be given a broad default route to a virtual
appliance in this design. APIM Premium v2 VNet injection also needs careful
service dependency behavior, so this scenario does not force APIM outbound
through Azure Firewall.

Spoke workload and future AKS subnets are the only first-pass subnets that
receive a default route to Azure Firewall.

## Operational constraints

The self-hosted runner must be able to deploy and validate the platform, but it
is not a normal application spoke. It is an operational dependency. It gets
direct peering because relying on hub transitivity would be wrong.

## Sources

- [Microsoft Learn, Application Gateway infrastructure][src-agw-infra]
- [Microsoft Learn, Inject Azure API Management Premium v2][src-apim-vnet]
- [Microsoft Learn, Create or change VNet peering][src-peering]

[src-agw-infra]:
  https://learn.microsoft.com/en-us/azure/application-gateway/configuration-infrastructure
[src-apim-vnet]:
  https://learn.microsoft.com/en-us/azure/api-management/inject-vnet-v2
[src-peering]:
  https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-manage-peering
