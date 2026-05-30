# Tradeoffs: Hub-Spoke Network Foundation

## Hub-spoke instead of one VNet

| Choice    | Benefit                                                     | Cost                                                  |
| --------- | ----------------------------------------------------------- | ----------------------------------------------------- |
| One VNet  | Simple deployment and routing                               | Weak separation between shared controls and workloads |
| Hub-spoke | Clear ownership, shared services, future workload isolation | More peering, routing, DNS, and troubleshooting work  |

The lab chooses hub-spoke because it is trying to demonstrate enterprise gateway
architecture, not the smallest possible network.

## Central Application Gateway

Putting Application Gateway WAF in the hub makes the public edge a shared
platform control. It also couples the hub to public ingress capacity,
certificate management, WAF tuning, and backend health troubleshooting.

The alternative is per-spoke ingress, which gives teams more independence but
duplicates WAF and certificate operations. That is a later decision if the lab
adds multiple workload spokes.

## Azure Firewall for spoke egress

Central firewall egress gives one policy point for future workload outbound
traffic. It also adds latency, cost, SNAT considerations, and route-table
complexity.

The lab routes future workload and AKS egress through Azure Firewall but does
not force Application Gateway or APIM through that same path. That keeps
service-specific routing constraints explicit.

## Minimal spoke

The spoke contains only reserved subnet space and egress routing. This avoids
premature AKS and workload decisions, but it means the scenario cannot yet prove
workload-to-APIM or workload-to-model traffic.

That is intentional. A partly designed spoke is better than a fictional workload
design.

## Direct runner peerings

Direct peerings from the runner VNet to hub and spoke add cross-region peering
cost and latency. They also avoid a false assumption that the runner can reach
the spoke through hub peering alone.

## Deferred private endpoints

Private endpoints for Key Vault and ACR would improve private network posture.
They would also require private DNS design, additional endpoint subnets, and
stricter deployment ordering. The lab defers them so the first pass can focus on
the edge path and egress model.

## Sources

- [Microsoft Learn, Hub-spoke network topology in Azure][src-hub-spoke]
- [Microsoft Learn, Azure Firewall and Application Gateway][src-fw-agw]
- [Microsoft Learn, Create or change VNet peering][src-peering]

[src-hub-spoke]:
  https://learn.microsoft.com/en-us/azure/architecture/networking/architecture/hub-spoke
[src-fw-agw]:
  https://learn.microsoft.com/en-us/azure/architecture/example-scenario/gateway/firewall-application-gateway
[src-peering]:
  https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-manage-peering
