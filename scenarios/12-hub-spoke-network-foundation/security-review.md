# Security Review: Hub-Spoke Network Foundation

## Security posture

This scenario improves security posture by placing public API ingress behind
Application Gateway WAF, keeping APIM gateway access private, centralizing
future workload egress through Azure Firewall, and using Key Vault for
certificate material.

It is not a production security baseline. It intentionally defers private
endpoints, DDoS Protection, Bastion, VPN or ExpressRoute, and full workload
identity design.

## Positive controls

- Public API traffic terminates at Application Gateway WAF.
- APIM Premium v2 gateway is privately reachable through VNet injection.
- Future spoke workload and AKS subnets route egress through Azure Firewall.
- Key Vault stores the edge certificate.
- ACR admin user remains disabled.
- Diagnostics are sent to Log Analytics.
- Deployment workflows are expected to use manual dispatch, OIDC, runner group
  `consultwithcloud-azure` with label `[gh-linux]`, branch guards, actor
  guards, and environment approvals.

## Risks

| Risk                               | Why it matters                                                                                    | Required response                                               |
| ---------------------------------- | ------------------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| Public repo workflow exposure      | A public pull request must not trigger Azure deployment logic                                     | Keep deployment workflows manual only                           |
| APIM body logging                  | Prompts, completions, request bodies, response bodies, secrets, or regulated data can be ingested | Warn clearly and disable for sensitive use                      |
| Public Key Vault and ACR endpoints | Network restrictions depend on correct runner NAT IP configuration                                | Validate firewall rules and revisit private endpoints later     |
| WAF false positives                | Prevention mode can block legitimate API calls                                                    | Review WAF logs and add narrow exclusions only when justified   |
| DNS misconfiguration               | Public and private names can point to different paths                                             | Validate both public DNS and private APIM gateway resolution    |
| Over-trusted spoke                 | Reserved spoke subnets do not equal a secure workload design                                      | Require workload-specific threat modeling before deploying apps |

## Security questions for later spoke design

- Which workload identities will call APIM or backend services?
- Will AKS use private cluster mode, workload identity, and Azure CNI?
- Which private endpoints belong in the spoke, and which belong in the hub?
- Should spoke-to-spoke traffic ever be allowed?
- What data classification applies to APIM logs?
- What is the incident response path for WAF blocks, firewall denies, and APIM
  policy failures?

## Sources

- [Microsoft Learn, Azure Firewall and Application Gateway][src-fw-agw]
- [Microsoft Learn, Application Gateway infrastructure][src-agw-infra]
- [Microsoft Learn, Inject Azure API Management Premium v2][src-apim-vnet]

[src-fw-agw]:
  https://learn.microsoft.com/en-us/azure/architecture/example-scenario/gateway/firewall-application-gateway
[src-agw-infra]:
  https://learn.microsoft.com/en-us/azure/application-gateway/configuration-infrastructure
[src-apim-vnet]:
  https://learn.microsoft.com/en-us/azure/api-management/inject-vnet-v2
