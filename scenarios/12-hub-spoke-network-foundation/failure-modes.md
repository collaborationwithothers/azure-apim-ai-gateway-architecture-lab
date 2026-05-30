# Failure Modes: Hub-Spoke Network Foundation

| Failure                                               | Impact                                                                     | Detection                                                            | Mitigation                                                                                |
| ----------------------------------------------------- | -------------------------------------------------------------------------- | -------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| Missing runner-to-spoke peering                       | Runner can deploy hub resources but cannot validate future spoke resources | Network connectivity test from runner to spoke IPs fails             | Create explicit bidirectional runner-spoke peering                                        |
| Incorrect default route on Application Gateway subnet | Backend health or control-plane behavior can fail                          | Application Gateway health and platform logs show failures           | Do not apply broad virtual appliance default route to `snet-appgw`                        |
| APIM private DNS missing or wrong                     | Application Gateway cannot reach APIM private gateway                      | Backend probe fails or resolves public/default hostname unexpectedly | Create private DNS or equivalent A record for APIM gateway private IP                     |
| Certificate not in Key Vault                          | HTTPS listener or APIM custom domain binding fails                         | Deployment fails or listener remains disabled                        | Use two-phase deployment: infrastructure, certificate workflow, custom-domain re-run      |
| Firewall route table points to wrong IP               | Future spoke egress fails or bypasses firewall                             | Effective routes and firewall logs do not match expected path        | Use firewall private IP output and validate effective routes                              |
| WAF prevention blocks valid traffic                   | API clients receive 403 responses                                          | WAF logs show rule matches                                           | Add narrow exclusions only after reviewing specific rule, hostname, and request component |
| Body logging captures sensitive data                  | Prompts, completions, secrets, or regulated data land in Log Analytics     | Log queries show sensitive fields                                    | Keep warnings explicit and disable body logging for sensitive environments                |
| Hub service capacity is undersized                    | Shared services become bottlenecks                                         | Metrics show saturation or throttling                                | Treat initial capacity as lab-only and review before production use                       |

## Recovery principles

- Do not delete resource groups to fix a routing problem until effective routes,
  DNS, and backend health have been checked.
- Keep certificate workflow recovery separate from infrastructure recovery.
- Prefer incremental Bicep correction over manual portal drift.
- Record any deviation in the ExecPlan and design log.
