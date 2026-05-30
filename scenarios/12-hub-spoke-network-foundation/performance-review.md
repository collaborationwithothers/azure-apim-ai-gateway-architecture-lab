# Performance Review: Hub-Spoke Network Foundation

## Performance expectations

This network design adds hops: public client to Application Gateway, Application
Gateway to APIM, and later APIM to private backends. Future workload egress
through Azure Firewall adds another inspection point for outbound traffic.

The performance goal is not lowest possible latency. The goal is controlled
ingress, private APIM reachability, centralized egress, and diagnosable
behavior.

## Latency considerations

- Application Gateway WAF adds TLS termination, WAF inspection, and backend
  proxy latency.
- APIM adds gateway policy execution latency.
- Azure Firewall adds egress inspection latency for future spoke workloads.
- Global peering to the existing runner VNet can add deployment and validation
  latency.

## Throughput considerations

- Application Gateway autoscale bounds should match expected API concurrency.
- APIM Premium v2 unit count should match gateway throughput and policy
  complexity.
- Azure Firewall throughput and SNAT port capacity must be revisited before
  workload scale tests.
- Log Analytics ingestion volume can grow quickly if APIM body logging is
  enabled.

## Testing approach

Before workload tests, isolate platform latency:

1. Measure direct APIM private gateway health from a connected test host.
2. Measure Application Gateway to APIM backend health.
3. Measure public edge health through `api.consultwithcloud.com`.
4. Measure future spoke egress through firewall once a test host or workload
   exists.

## Current limitation

The spoke has no workload yet, so this scenario cannot make meaningful
application latency claims.
