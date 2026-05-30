# Scenario: Private Networking

## 1. Business problem

Enterprise teams need internal APIM, external APIM, private endpoints, private DNS, VNet integration, firewall egress, WAF, and portal exposure. Without a gateway pattern, each client implements these controls differently and backend governance becomes inconsistent.

## 2. Requirements

### Functional requirements

- Route requests through APIM before they reach model backends.
- Keep backend details out of client applications.
- Provide clear policy and testing placeholders for this scenario.

### Non-functional requirements

- Avoid real secrets, tenant IDs, and production endpoints.
- Make security, performance, cost, and operational tradeoffs explicit.
- Keep the scenario understandable without a live Azure subscription.

## 3. Constraints

This is a first-pass lab scaffold. Policy XML is illustrative and must be reviewed against the current APIM policy schema before deployment. Environment-specific values belong outside source control.

## 4. Architecture

Client applications call APIM. APIM applies scenario-specific policy, records dimensions needed for operations, and forwards to a placeholder AI backend. Supporting services such as Key Vault, Redis-compatible cache, Application Insights, Log Analytics, private DNS, and private endpoints are introduced only when the scenario requires them.

## 5. Design decision

### Chosen approach

Use APIM as the central policy enforcement point and keep the implementation intentionally environment-neutral.

### Alternatives considered

| Option | Pros | Cons | Decision |
|---|---|---|---|
| Direct backend calls | Lowest initial latency | Weak governance and duplicated controls | Rejected |
| Custom gateway | Maximum control | Higher build and operations burden | Deferred |
| APIM gateway | Managed policy layer and Azure operations fit | Adds gateway cost and policy testing needs | Chosen |

## 6. Implementation approach

Start with documentation and policy placeholders. Add mock backend tests before any live deployment. Use Bicep modules only after the resource boundaries and environment inputs are reviewed.

## 7. Security considerations

Use managed identity where supported, validate caller identity, avoid prompt and completion logging by default, and make tenant boundaries explicit. Review cache keys and telemetry fields for sensitive data exposure.

## 8. Performance considerations

Measure APIM latency separately from backend model latency. Treat retries, fallback, semantic caching, and streaming as workload-specific choices that need tests.

## 9. Cost considerations

Track token usage, APIM capacity, monitoring ingestion, cache tier, region count, and backend model selection. Do not assume gateway policy alone controls total spend.

## 10. Failure modes

| Failure | Impact | Mitigation |
|---|---|---|
| Backend throttling | User requests fail or slow down | Apply quotas, fallback, and explicit retry budgets |
| Policy misconfiguration | Requests are blocked or routed incorrectly | Validate policy XML and add contract tests |
| Telemetry gap | Operators cannot diagnose incidents | Emit tenant, model, route, latency, and status dimensions |

## 11. Observability

Record request count, status code, backend selection, APIM latency, backend latency, token usage when available, and tenant or product dimensions. Use KQL placeholders under `observability/app-insights-kql/` as starting points.

## 12. Test plan

Validate Markdown, policy XML, and Bicep skeletons locally. In a future implementation, add contract tests that call a mock backend through APIM policy imports.

## 13. Demo script

1. Open this README and explain the business problem.
2. Show the architecture and tradeoff sections.
3. Open the policy example when present.
4. Show the related Mermaid diagram or KQL placeholder.
5. Explain what must be supplied before any live Azure deployment.

## 14. What this scenario demonstrates

Private networking improves security posture but increases DNS, routing, deployment, and troubleshooting complexity.
