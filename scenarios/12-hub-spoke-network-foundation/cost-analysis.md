# Cost Analysis: Hub-Spoke Network Foundation

## Cost drivers

| Component                  | Cost driver                                  | Notes                                                                |
| -------------------------- | -------------------------------------------- | -------------------------------------------------------------------- |
| APIM Premium v2            | Instance unit count and runtime hours        | The selected private gateway pattern is not the cheapest APIM option |
| Application Gateway WAF v2 | Running capacity, autoscale, data processed  | WAF is required for the public edge design                           |
| Azure Firewall Standard    | Running hours, data processed, public IPs    | Central egress control has a meaningful fixed cost                   |
| Log Analytics              | Data ingestion and retention                 | APIM body logging can materially increase ingestion                  |
| Key Vault                  | Operations and certificate storage           | Small in the lab, but operationally important                        |
| ACR Premium                | Registry SKU and storage                     | Premium is chosen for future network and enterprise features         |
| VNet peering               | Cross-region or global peering data transfer | Existing runner VNet is outside the new `swedencentral` region             |
| Public DNS                 | Zone and query costs                         | Low, but required for public ingress                                 |

## Cost tradeoff

This scenario chooses architectural clarity and enterprise control over minimum
cost. A cheaper lab could use a single VNet, no firewall, no WAF, and public
APIM. That would not demonstrate the target architecture.

## Cost controls

- Use one APIM unit initially.
- Use Application Gateway autoscale minimum 1 and maximum 3.
- Use Azure Firewall Standard, not Premium.
- Use 30-day Log Analytics retention.
- Keep the spoke empty until a workload has a real requirement.
- Revisit APIM body logging before any sensitive or high-volume test.

## Cost warning

Do not leave this platform running without a cost review. APIM Premium v2, Azure
Firewall, and Application Gateway WAF are persistent-cost services.
