# Requirements: Hub-Spoke Network Foundation

## Functional requirements

| ID       | Requirement                                               | Rationale                                                                       |
| -------- | --------------------------------------------------------- | ------------------------------------------------------------------------------- |
| HSN-FR-1 | Create a hub VNet for shared platform services            | Centralized controls are easier to operate and reason about                     |
| HSN-FR-2 | Create a spoke VNet for future workloads                  | Workloads need isolation from shared platform services                          |
| HSN-FR-3 | Expose public API traffic through Application Gateway WAF | APIM gateway remains private while public clients have a managed HTTPS edge     |
| HSN-FR-4 | Deploy APIM Premium v2 with VNet injection                | APIM gateway traffic stays private inside the network                           |
| HSN-FR-5 | Route future spoke egress through Azure Firewall          | Outbound control belongs in the hub                                             |
| HSN-FR-6 | Peer runner, hub, and spoke directly                      | VNet peering is not transitive                                                  |
| HSN-FR-7 | Send platform diagnostics to Log Analytics                | Operators need a shared place to troubleshoot edge, firewall, and APIM behavior |

## Non-functional requirements

| ID        | Requirement                                    | Rationale                                                                       |
| --------- | ---------------------------------------------- | ------------------------------------------------------------------------------- |
| HSN-NFR-1 | Keep the spoke minimal until a workload exists | Avoid premature AKS, API, and private endpoint decisions                        |
| HSN-NFR-2 | Keep deployment manual and guarded             | The repository is public and the runner has Azure network access                |
| HSN-NFR-3 | Keep naming and CIDR choices deterministic     | Future agents need stable references                                            |
| HSN-NFR-4 | Preserve rerunnable deployments                | The platform should support validate, what-if, and incremental apply            |
| HSN-NFR-5 | Document tradeoffs beside the design           | Hub-spoke networking fails when routing and ownership assumptions stay implicit |

## Acceptance signals

- The new scenario explains why the spoke is deliberately reserved rather than
  complete.
- The hub owns shared ingress, egress, APIM, diagnostics, DNS, certificate, and
  registry concerns.
- The scenario identifies unsupported or deferred choices instead of hiding
  them.
- The scenario links back to the implementation plan and REQ-001.
