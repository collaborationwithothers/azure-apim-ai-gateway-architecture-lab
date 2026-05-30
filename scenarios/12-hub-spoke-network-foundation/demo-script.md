# Demo Script: Hub-Spoke Network Foundation

## Goal

Explain the hub-spoke design choices without implying that the spoke workload is
complete.

## Walkthrough

1. Open `requirements/001-hub-spoke-apim-edge-platform.md` and show the problem
   statement.
2. Open this scenario README and explain the difference between the hub, spoke,
   and runner networks.
3. Open `architecture.md` and walk through the ingress path from public DNS to
   Application Gateway to private APIM.
4. Explain why future spoke egress goes through Azure Firewall.
5. Explain why Application Gateway and APIM do not receive broad default routes
   to Azure Firewall in this pass.
6. Explain why the runner VNet is peered directly to both hub and spoke.
7. Open `tradeoffs.md` and discuss the deferred decisions: AKS, private
   endpoints, DNS Private Resolver, and full workload design.
8. Open `failure-modes.md` and show how routing and DNS errors would be
   diagnosed.
9. End with the key message: this scenario demonstrates platform network
   thinking, not a completed workload spoke.

## Demo close

The hub-spoke foundation is ready when reviewers can answer three questions:

- What shared controls live in the hub?
- What workload assumptions are intentionally deferred in the spoke?
- Which validation proves that the edge and routing model is working?
