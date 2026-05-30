# Observability: Hub-Spoke Network Foundation

## What to observe

The first observable outcome is platform health, not workload behavior. The
platform should show whether traffic reaches Application Gateway, whether
Application Gateway can reach APIM privately, whether future spoke egress is
routed through Azure Firewall, and whether diagnostics are landing in Log
Analytics.

## Diagnostic sources

| Source                                           | Why it matters                                                                 |
| ------------------------------------------------ | ------------------------------------------------------------------------------ |
| Application Gateway access logs                  | Confirm public edge traffic, status codes, backend pool, and listener behavior |
| Application Gateway WAF logs                     | Explain blocks and rule matches                                                |
| Application Gateway performance metrics          | Track backend health, failed requests, capacity, and latency                   |
| APIM gateway logs                                | Confirm API gateway policy execution and response behavior                     |
| Azure Firewall application and network rule logs | Confirm spoke egress and deny behavior                                         |
| Key Vault diagnostic logs                        | Confirm certificate and secret access patterns                                 |
| ACR diagnostic logs                              | Prepare for future workload image operations                                   |
| Log Analytics workspace metrics                  | Track ingestion volume and retention impact                                    |

## Useful validation questions

- Does public DNS resolve `api.consultwithcloud.com` to Application Gateway?
- Does Application Gateway backend health show APIM as healthy?
- Does private DNS resolve the APIM gateway name to the APIM private IP from the
  hub?
- Do firewall logs show expected future spoke egress tests?
- Do WAF logs explain any blocked requests?
- Do APIM logs include body logging as intentionally configured for the lab?

## Example KQL starting points

The repository already has KQL placeholders in
`observability/app-insights-kql/`. This scenario should eventually add
network-specific queries for:

- Application Gateway 4xx and 5xx by listener and backend.
- WAF blocked requests by rule ID.
- Azure Firewall denies by source subnet and destination FQDN.
- APIM gateway requests by hostname and operation.
- Log Analytics ingestion by resource type.

## Known observability gap

Because no workload is deployed in the spoke yet, this scenario cannot prove
workload-level behavior. It can only validate network foundation readiness.
