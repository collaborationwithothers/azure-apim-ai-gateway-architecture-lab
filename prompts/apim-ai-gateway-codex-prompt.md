# Codex Prompt: Build Azure APIM AI Gateway Architecture Lab

You are an expert Azure cloud architect, API Management engineer, and technical documentation writer.

Build the initial version of a GitHub portfolio repository called:

`azure-apim-ai-gateway-architecture-lab`

## Primary goal

Create a portfolio-grade architecture lab that demonstrates how Azure API Management can be used as an enterprise AI gateway in front of Azure AI Foundry / Azure OpenAI workloads.

This repository must show architectural thinking, not just code.

The repo should demonstrate:

- Azure API Management as an AI gateway
- Azure AI Foundry / Azure OpenAI backend integration
- Token governance
- Semantic caching
- Model routing
- Load balancing and failover
- Content safety and prompt governance
- Observability and cost tracking
- Multitenant isolation
- Private networking
- Streaming considerations
- APIOps / CI-CD deployment

The intended audience is senior architects, and engineering leads evaluating whether the repo owner can operate as an AI Architect.

## Important instruction

Do not create a shallow sample repo.

Every scenario must explain:

1. Business problem
2. Requirements
3. Constraints
4. Architecture
5. Implementation approach
6. Security considerations
7. Performance considerations
8. Cost considerations
9. Operational considerations
10. Failure modes
11. Tradeoffs
12. Test plan
13. Demo script

Where implementation is not yet complete, create high-quality placeholders with clear TODOs.

Do not invent unsupported Azure behaviour. Mark uncertain implementation details as assumptions or TODOs.

---

# Required top-level repository structure

Create this structure:

```text
azure-apim-ai-gateway-architecture-lab/
│
├── README.md
├── docs/
│   ├── 00-executive-summary.md
│   ├── 01-problem-statement.md
│   ├── 02-reference-architecture.md
│   ├── 03-system-design-process.md
│   ├── 04-threat-model.md
│   ├── 05-cost-model.md
│   ├── 06-performance-model.md
│   ├── 07-operability-model.md
│   └── adr/
│       ├── ADR-001-why-apim-as-ai-gateway.md
│       ├── ADR-002-apim-vs-custom-gateway.md
│       ├── ADR-003-semantic-caching-strategy.md
│       ├── ADR-004-model-routing-strategy.md
│       ├── ADR-005-token-governance-strategy.md
│       └── ADR-006-private-networking-strategy.md
│
├── scenarios/
│   ├── 00-baseline-foundry-proxy/
│   ├── 01-auth-and-identity/
│   ├── 02-token-governance/
│   ├── 03-semantic-caching/
│   ├── 04-model-routing/
│   ├── 05-load-balancing-and-failover/
│   ├── 06-content-safety/
│   ├── 07-observability-and-cost-tracking/
│   ├── 08-multitenant-isolation/
│   ├── 09-private-networking/
│   ├── 10-streaming-responses/
│   └── 11-apiops-ci-cd/
│
├── infra/
│   ├── bicep/
│   └── modules/
│
├── policies/
│   ├── fragments/
│   ├── inbound/
│   ├── outbound/
│   ├── backend/
│   └── examples/
│
├── apps/
│   ├── dotnet-client/
│   ├── load-test-client/
│   └── mock-ai-backend/
│
├── tests/
│   ├── postman/
│   ├── k6/
│   ├── playwright/
│   └── contract-tests/
│
├── observability/
│   ├── app-insights-kql/
│   ├── workbooks/
│   └── dashboards/
│
├── cost-models/
│   ├── standard-vs-provisioned.md
│   └── token-cost-calculator.md
│
├── diagrams/
│   ├── drawio/
│   ├── mermaid/
│   └── png/
│
└── .github/
    └── workflows/
        ├── validate-markdown.yml
        ├── validate-policies.yml
        ├── bicep-plan.yml
        └── deploy-dev.yml
```

---

# First implementation scope

Do not try to fully implement all Azure infrastructure in the first pass.

In the first pass, create a strong documentation-first architecture repo with sensible placeholders.

Create these files with real content:

## Top-level

- `README.md`
- `.gitignore`
- `LICENSE`
- `CONTRIBUTING.md`

## Docs

- `docs/00-executive-summary.md`
- `docs/01-problem-statement.md`
- `docs/02-reference-architecture.md`
- `docs/03-system-design-process.md`
- `docs/04-threat-model.md`
- `docs/05-cost-model.md`
- `docs/06-performance-model.md`
- `docs/07-operability-model.md`

## ADRs

- `docs/adr/ADR-001-why-apim-as-ai-gateway.md`
- `docs/adr/ADR-002-apim-vs-custom-gateway.md`
- `docs/adr/ADR-003-semantic-caching-strategy.md`
- `docs/adr/ADR-004-model-routing-strategy.md`
- `docs/adr/ADR-005-token-governance-strategy.md`
- `docs/adr/ADR-006-private-networking-strategy.md`

## Scenarios

For every scenario folder from `00` to `11`, create:

```text
README.md
requirements.md
constraints.md
architecture.md
tradeoffs.md
security-review.md
performance-review.md
cost-analysis.md
failure-modes.md
observability.md
test-plan.md
demo-script.md
```

For scenarios where policy examples make sense, also create:

```text
policy.xml
```

## Policies

Create example APIM policies under:

```text
policies/examples/
```

Include:

```text
baseline-foundry-proxy.xml
token-governance.xml
semantic-cache-lookup.xml
semantic-cache-store.xml
model-routing.xml
load-balancing-and-failover.xml
content-safety-placeholder.xml
observability-logging.xml
```

Policy files can be illustrative and should include comments/TODOs where environment-specific values are needed.

Do not include real secrets, keys, tenant IDs, or production endpoints.

## Diagrams

Create Mermaid diagrams under:

```text
diagrams/mermaid/
```

Include:

```text
high-level-architecture.md
request-flow.md
semantic-cache-flow.md
token-governance-flow.md
model-routing-flow.md
load-balancing-failover-flow.md
multitenant-isolation.md
private-networking.md
observability-flow.md
apiops-flow.md
```

## Observability

Create KQL placeholder files:

```text
observability/app-insights-kql/token-usage-by-tenant.kql
observability/app-insights-kql/cache-hit-ratio.kql
observability/app-insights-kql/throttling-by-backend.kql
observability/app-insights-kql/p95-latency-by-model.kql
observability/app-insights-kql/top-expensive-consumers.kql
observability/app-insights-kql/content-safety-annotations.kql
```

Each KQL file should have:

- Purpose
- Assumptions about log schema
- Query
- TODOs for adapting field names

## Infra

Create placeholder Bicep structure:

```text
infra/bicep/
├── README.md
├── main.bicep
├── variables.bicep
├── outputs.bicep
└── env/
```

Bicep should be a safe skeleton only. Include TODO comments for:

- Resource group
- APIM instance
- Azure AI Foundry / Azure OpenAI account
- Application Insights
- Log Analytics workspace
- Redis cache for semantic caching
- Key Vault
- Private endpoints
- Private DNS zones

Do not create complex or potentially broken bicep.

## GitHub Actions

Create placeholder workflows:

```text
.github/workflows/validate-markdown.yml
.github/workflows/validate-policies.yml
.github/workflows/bicep-plan.yml
.github/workflows/deploy-dev.yml
```

These should be safe templates with comments and TODOs.

---

# README.md requirements

The top-level README must include:

1. Title
2. Portfolio positioning
3. Problem statement
4. Reference architecture
5. Why APIM as an AI gateway
6. Scenario table
7. Repository structure
8. How to use the repo
9. Demo roadmap
10. Architecture principles
11. Security disclaimer
12. Cost disclaimer
13. Next steps

Use this positioning:

> Modern enterprise AI applications should not call LLM backends directly. They need an AI gateway layer to centralise access control, token governance, routing, safety, observability, cost control, resilience, and multitenant isolation. Azure API Management provides many of these gateway capabilities as managed platform features, but the architecture still requires careful design around identity, caching, backend quotas, regional failover, security, and operational ownership.

The README should make clear that this repository is an architecture lab and portfolio project.

---

# Scenario documentation template

For each scenario README, use this structure:

```markdown
# Scenario: <Scenario Name>

## 1. Business problem

## 2. Requirements

### Functional requirements

### Non-functional requirements

## 3. Constraints

## 4. Architecture

## 5. Design decision

### Chosen approach

### Alternatives considered

| Option | Pros | Cons | Decision |
|---|---|---|---|

## 6. Implementation approach

## 7. Security considerations

## 8. Performance considerations

## 9. Cost considerations

## 10. Failure modes

| Failure | Impact | Mitigation |
|---|---|---|

## 11. Observability

## 12. Test plan

## 13. Demo script

## 14. What this scenario demonstrates
```

Every scenario should read like a mini system design case study.

---

# Scenario details

## 00-baseline-foundry-proxy

Demonstrate:

- Client -> APIM -> Azure AI Foundry / Azure OpenAI
- Basic API facade
- Backend abstraction
- Named values
- Why direct client-to-model access is risky
- Basic policy placeholder

Key tradeoff:

APIM adds latency and cost, but centralises governance, security, observability, and operational control.

## 01-auth-and-identity

Demonstrate:

- Entra ID JWT validation
- Subscription keys
- Product-based access
- Managed identity from APIM to backend
- Key Vault-backed named values
- Per-application access control

Key tradeoff:

Subscription keys are simple but weak as a primary enterprise identity mechanism. Entra ID gives stronger identity but requires more onboarding and token management.

## 02-token-governance

Demonstrate:

- Tokens-per-minute protection
- Quotas per tenant/application/product
- Prompt token estimation
- Cost guardrails
- Noisy-neighbour mitigation

Example table:

| Consumer type | TPM | Daily quota | Model access | Reason |
|---|---:|---:|---|---|
| Internal dev | 20k | 1M | mini model | Engineering testing |
| Production app | 200k | 20M | mini + flagship model | Customer workload |
| Trial tenant | 5k | 100k | mini only | Cost control |

Key tradeoff:

Gateway token limits protect shared backend capacity but do not replace Azure OpenAI quota planning, PTU sizing, or application-level budget governance.

## 03-semantic-caching

Demonstrate:

- Semantic cache lookup
- Semantic cache store
- Redis / RediSearch-compatible cache
- Tenant-aware cache partitioning
- Cache TTL
- Similarity threshold
- Cache poisoning risk
- Stale answer risk
- PII leakage risk

Good candidates:

- FAQ-style prompts
- Documentation Q&A
- Repeated support questions
- Non-personalised responses

Bad candidates:

- Legal advice
- Medical advice
- User-specific financial advice
- Prompts containing volatile data
- Prompts with strong authorisation context

Key tradeoff:

Semantic caching can reduce latency and token cost, but it can return stale or semantically incorrect answers if the cache key, similarity threshold, TTL, or tenant partitioning are poorly designed.

## 04-model-routing

Demonstrate:

- Routing by request type
- Routing by tenant tier
- Routing by model capability
- Routing by region
- Routing by cost profile
- Degraded-mode fallback

Example routing table:

| Request type | Primary model | Fallback | Reason |
|---|---|---|---|
| Low-cost summarisation | mini model | mini model secondary region | Cost efficiency |
| Complex reasoning | flagship model | mini model degraded mode | Quality first |
| High-priority tenant | PTU deployment | standard spillover | Predictability |
| Internal testing | standard deployment | none | Cost control |

Key tradeoff:

Model routing improves cost and resilience but increases testing complexity because different models can produce different behaviours.

## 05-load-balancing-and-failover

Demonstrate:

- Active-active backends
- Priority-based backend selection
- Weighted routing
- Circuit breaker pattern
- 429 and 503 handling
- PTU primary with standard spillover
- Regional failover

Failure tests:

- Backend returns 429
- Backend returns 503
- Region unavailable
- Latency above threshold
- PTU exhausted
- Standard deployment throttled

Key tradeoff:

Load balancing improves resilience and capacity usage but makes debugging, quota management, regional compliance, and conversation consistency harder.

## 06-content-safety

Demonstrate:

- Prompt moderation
- Completion moderation
- Annotate vs block
- Audit logging
- Tenant-specific safety posture
- Human review workflow placeholder

Key tradeoff:

Blocking improves safety but can create false positives. Annotating improves forensic visibility but requires downstream governance and monitoring.

## 07-observability-and-cost-tracking

Demonstrate:

- Token usage by tenant
- Token usage by product
- Cost by model
- Cache hit ratio
- 429 rate
- Backend latency
- APIM latency
- Prompt/completion size
- Top expensive consumers

Key tradeoff:

Detailed observability improves governance and FinOps but can increase logging cost and data sensitivity risk if prompts/completions are logged without controls.

## 08-multitenant-isolation

Demonstrate:

- Tenant identification
- Subscription key per tenant
- Product per tenant tier
- Quota per tenant
- Cache partition per tenant
- Logging dimensions
- Backend routing per tenant

Isolation model table:

| Model | Description | Pros | Cons |
|---|---|---|---|
| Shared APIM, shared backend | Lowest cost | Simple | Weakest isolation |
| Shared APIM, per-tenant backend | Better isolation | Good SaaS pattern | More routing complexity |
| Per-environment APIM | Strong env separation | Clean Dev/Test/Prod | Higher cost |
| Per-tenant APIM | Strongest isolation | Regulated workloads | Expensive/operationally heavy |

Key tradeoff:

Shared APIM is cost-effective for SaaS, but identity, quota, cache, logs, and routing must all be tenant-aware.

## 09-private-networking

Demonstrate:

- Internal APIM vs external APIM
- Private endpoint to AI backend
- Private DNS zones
- VNet integration
- Azure Firewall egress
- Application Gateway/WAF in front
- Management plane vs data plane
- Developer portal exposure decision

Key tradeoff:

Private networking improves security posture but increases DNS, routing, deployment, and troubleshooting complexity.

## 10-streaming-responses

Demonstrate:

- Streaming preservation
- Client cancellation
- Backend cancellation
- Timeout behaviour
- Observability limitations
- Response inspection limitations

Key tradeoff:

Streaming improves user experience but complicates response inspection, retries, completion logging, semantic caching, and safety checks.

## 11-apiops-ci-cd

Demonstrate:

- GitHub Actions
- Policy validation
- Bicep plan
- Environment promotion
- Dev/Test/Prod parameterisation
- Pull request review
- Least privilege deployment model

Key tradeoff:

APIOps improves governance and repeatability but requires strong environment strategy, testing, and policy review discipline.

---

# Architecture principles to document

Use these principles throughout the repo:

1. Do not let applications call LLM backends directly unless there is a deliberate exception.
2. Centralise authentication, authorization, quota, routing, safety, and logging at the gateway.
3. Keep business orchestration out of APIM policy where it becomes too complex.
4. Use APIM for gateway concerns; use application services for domain logic and agent orchestration.
5. Make tenant identity explicit in every governance decision.
6. Treat tokens as a cost and capacity resource.
7. Prefer managed identity over static keys where possible.
8. Design cache partitioning before enabling semantic cache.
9. Assume backend throttling will happen.
10. Monitor token usage, cache hit ratio, throttling, and latency from day one.
11. Treat prompt and completion logs as sensitive data.
12. Make private networking decisions explicit because they affect operations heavily.

---

# ADR format

Each ADR should use this format:

```markdown
# ADR-XXX: <Title>

## Status

Proposed

## Context

## Decision

## Options considered

| Option | Pros | Cons |
|---|---|---|

## Consequences

### Positive

### Negative

### Risks

## When to revisit this decision
```

---

# Policy file guidance

Create illustrative APIM policy XML files.

Policy files must:

- Be formatted XML
- Include comments explaining intent
- Use placeholders like `{{azure-openai-backend-url}}`
- Avoid real secrets
- Avoid fake production endpoints
- Include TODOs for environment-specific values
- Prefer reusable policy fragments where sensible

Do not claim the policies are production-ready unless they are fully validated.

---

# Mermaid diagram guidance

Use Mermaid diagrams that render in GitHub.

At minimum, include:

1. High-level architecture
2. Request flow
3. Semantic cache flow
4. Token governance flow
5. Model routing flow
6. Load balancing/failover flow
7. Multitenant isolation model
8. Private networking model
9. Observability flow
10. APIOps flow

---

# Acceptance criteria

The first Codex output is successful if:

- The repo structure is created.
- All required folders exist.
- The top-level README is strong and portfolio-ready.
- Each scenario folder contains the required markdown files.
- Scenario README files are meaningful, not empty.
- ADRs contain real architectural reasoning.
- Mermaid diagrams exist and are useful.
- Example policy XML files exist and are clearly labelled as illustrative.
- KQL files exist with purpose, assumptions, and TODOs.
- Bicep skeleton exists but does not attempt unsafe complete deployment.
- GitHub Actions skeletons exist.
- There are no secrets or real tenant-specific values.
- The repo reads like an architecture lab, not a random sample.

---

# Quality bar

Write like a senior Azure architect.

Prefer clear, concise, professional documentation.

Use tables where tradeoffs are important.

Use TODOs only where real implementation details depend on environment-specific decisions.

Avoid marketing language.

Avoid overclaiming.

The final result should be something that can be pushed to GitHub as the first commit of a serious portfolio project.
