# Plan Spoke Full Demo Stack

This plan captures the agreed design for extending the current spoke from a network foundation into a full demo platform for the Azure APIM AI gateway lab.

The implementation must build on `requirements/001-hub-spoke-apim-edge-platform.md`, `design-log/001-hub-spoke-apim-edge-platform.md`, and the existing Bicep baseline under `infra/bicep/`.

## Summary

Extend the existing hub-spoke lab from a reserved spoke network into a full demo spoke platform. The stack will use AKS for a .NET backend-for-frontend app, Argo CD for GitOps, upstream Istio for in-cluster ingress, Redis for cache and session state, and a private Foundry project and model backend. APIM remains the AI gateway and policy control point.

The baseline flow is:

```text
Internet
  -> Application Gateway WAF
  -> app.lab.consultwithcloud.com
  -> Istio internal gateway
  -> .NET BFF
  -> APIM at api.lab.consultwithcloud.com
  -> private Foundry and model endpoints
```

Argo CD is exposed at `argo.lab.consultwithcloud.com` behind Application Gateway WAF with Microsoft Entra SSO only.

## Key Decisions

- Replace the current `api.consultwithcloud.com` DNS assumption with delegated public zone `lab.consultwithcloud.com`.
- Use public hostnames `api.lab.consultwithcloud.com`, `app.lab.consultwithcloud.com`, and `argo.lab.consultwithcloud.com`.
- Use one Let's Encrypt SAN certificate for the three public lab hostnames and store it in Key Vault.
- Add spoke resources for AKS, Redis, Foundry project resources, model deployments, private endpoints, private DNS links, and BFF app support.
- Keep shared Key Vault, ACR, Log Analytics, APIM, Application Gateway, and Azure Firewall in the hub unless a service requires spoke placement.
- Use Azure CNI Overlay plus `userDefinedRouting` so AKS egress follows the existing hub firewall pattern.
- Use the lowest-cost AKS posture, but document reduced availability and add manual stop/start plus destroy workflows for cost control.
- Use upstream Istio installed by Helm, with an internal Azure Load Balancer for Istio ingress.
- Use the Azure Argo CD extension for GitOps.
- Expose Argo CD publicly through Application Gateway WAF, but require Entra OIDC SSO, group RBAC, and disabling the built-in `admin` account after bootstrap.
- Use PR-based image promotion: GitHub Actions builds and pushes immutable BFF images to ACR, then updates GitOps values through protected branch review.
- Use Argo CD automated sync with self-heal and no automatic prune.

## Security And Identity

- AKS API server remains public and unrestricted because that was explicitly chosen. This is not recommended and must be documented as a management-plane exposure risk.
- Foundry and model endpoints use private endpoints plus trusted Azure service access where required.
- Public user access uses Microsoft Entra ID.
- The .NET BFF handles sign-in and calls APIM using on-behalf-of user tokens.
- APIM validates user JWTs inbound and uses managed identity outbound to Foundry and model endpoints.
- Include agent-ready audit fields now: user ID, app ID, future agent ID, scenario ID, policy decision ID, correlation ID, model deployment, and APIM request ID.
- Use Key Vault CSI with AKS Workload Identity for Kubernetes secret consumption.
- Defer AKS admission policy and Azure Policy enforcement, but record this as a risk because the AKS API and Argo CD UI are internet-exposed.

## Implementation Changes

- Update Bicep to parameterize the lab DNS zone, public hostnames, SAN certificate secret URI, Foundry or model deployment settings, AKS settings, Redis settings, and GitOps settings.
- Extend Application Gateway with separate HTTPS listeners and routing rules for `api`, `app`, and `argo` under `lab.consultwithcloud.com`.
- Update the certificate workflow to issue and import a SAN certificate covering all three lab hostnames.
- Add AKS with Azure CNI Overlay, `userDefinedRouting`, lowest-cost development posture, and ACR pull access.
- Add upstream Istio installation through GitOps or bootstrap Helm values, with an internal ingress gateway service.
- Add Argo CD through the Azure extension, configure Entra OIDC, RBAC, and public WAF routing.
- Add Redis with private networking for BFF session state and APIM semantic cache scenarios where supported.
- Add Foundry project and model deployment resources using `GlobalStandard` deployment SKU and parameterized model names.
- Add private endpoints and private DNS links needed by Foundry, model, Redis, and workload access paths.
- Add a .NET BFF app with Microsoft.Identity.Web, OpenTelemetry, OBO token acquisition, and APIM calls.
- Add dashboards or workbooks for APIM, BFF, AKS, Redis, Foundry/model usage, WAF, and correlation tracing.

## Public Interfaces

- `api.lab.consultwithcloud.com`: APIM public gateway hostname through Application Gateway WAF.
- `app.lab.consultwithcloud.com`: public BFF app hostname through Application Gateway WAF and internal Istio ingress.
- `argo.lab.consultwithcloud.com`: public Argo CD hostname through Application Gateway WAF and Entra SSO.
- GitOps path: create a narrow path such as `gitops/` for Argo CD tracked manifests and Helm values.
- Image promotion: CI must update GitOps values through reviewed PRs, not from an in-cluster writer by default.

## Test Plan

- Bicep: run `az bicep build --file infra/bicep/main.bicep` and a subscription-scope what-if.
- DNS and certificate: verify child zone delegation, SAN certificate import, and Application Gateway listener bindings.
- Network: verify hub-to-spoke, APIM-to-private-model, BFF-to-APIM, and Application Gateway-to-Istio paths.
- Auth: verify Entra sign-in, BFF OBO token acquisition, APIM JWT validation, and APIM managed identity to model backend.
- GitOps: verify Argo SSO, RBAC, sync from protected main branch, no auto-prune, and image tag promotion by reviewed PR.
- Observability: verify OpenTelemetry traces from BFF, APIM diagnostics, Application Gateway WAF logs, AKS logs, Redis metrics, model request metrics, and dashboards.
- Cost controls: verify AKS stop/start workflow and guarded destroy workflow.

## Assumptions

- `lab.consultwithcloud.com` can be delegated from the parent DNS host to Azure DNS.
- `GlobalStandard` is accepted for lab model deployments, including the documented global inference processing tradeoff.
- Model names and availability remain parameterized and must be checked live before deployment.
- The public unrestricted AKS API decision is intentional, but the implementation must label it as a risk and should not present it as a secure default.
- Azure Verified Modules must be checked before adding local Bicep modules. Use raw Bicep only where AVM does not fit or cross-resource wiring is clearer.

## References

- [Hub-spoke APIM edge requirement](../../requirements/001-hub-spoke-apim-edge-platform.md)
- [Hub-spoke APIM edge design log](../../design-log/001-hub-spoke-apim-edge-platform.md)
- [Existing spoke Bicep module](../../infra/bicep/modules/spoke.bicep)
- [APIM AI gateway capabilities](https://learn.microsoft.com/en-ie/azure/api-management/genai-gateway-capabilities)
- [AKS private clusters](https://learn.microsoft.com/en-us/azure/aks/private-clusters)
- [AKS Azure CNI Overlay](https://learn.microsoft.com/en-us/azure/aks/azure-cni-overlay)
- [Argo CD security](https://argo-cd.readthedocs.io/en/release-2.7/operator-manual/security/)
- [Azure DNS child zones](https://learn.microsoft.com/en-us/azure/dns/tutorial-public-dns-zones-child)
- [Foundry private link](https://learn.microsoft.com/en-us/azure/ai-foundry/how-to/configure-private-link?tabs=azure-portal&view=azureml-api-1)
- [APIM managed identity policy](https://learn.microsoft.com/da-dk/azure/api-management/authentication-managed-identity-policy)
- [AKS Key Vault CSI](https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-driver)
