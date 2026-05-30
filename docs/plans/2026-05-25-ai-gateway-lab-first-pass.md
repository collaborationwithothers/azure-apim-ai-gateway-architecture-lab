# Build the First-Pass Azure APIM AI Gateway Architecture Lab

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds. This document follows `instructuctions/PLAN.md`.

## Purpose / Big Picture

This change turns a mostly empty repository into a portfolio-ready architecture lab that shows how Azure API Management can sit in front of Azure AI Foundry and Azure OpenAI workloads as an enterprise AI gateway. After this work, a reader can inspect scenario packs, architecture documents, policy examples, diagrams, observability queries, Bicep skeletons, and workflow templates without needing a live Azure subscription. The observable result is the presence of the required scaffold and successful local validation commands.

## Progress

- [x] (2026-05-25) Read the repository prompt and local ExecPlan rules.
- [x] (2026-05-25) Verified the repository is on feature branch `hp/feature/repo-setup` and preserved existing dirty files.
- [x] (2026-05-25) Created top-level documentation, core docs, ADRs, scenarios, policies, diagrams, KQL, Bicep, and workflow templates.
- [x] (2026-05-25) Ran local validation checks and recorded the outcomes in this plan.

## Surprises & Discoveries

- Observation: The existing checkout already had a modified `.gitignore` that removed unrelated infrastructure ignore rules and added Azure Bicep local artifact rules.
  Evidence: `git diff -- .gitignore` showed the Azure-specific ignore list before implementation.

- Observation: The local prompt asks for one KQL file named `content-safety-annotations.kql` in addition to the five KQL files listed in the implementation plan summary.
  Evidence: `prompts/apim-ai-gateway-codex-prompt.md` includes `observability/app-insights-kql/content-safety-annotations.kql`, so the scaffold includes it.

- Observation: `markdownlint` is not installed in the local shell.
  Evidence: `markdownlint "**/*.md"` returned `zsh:1: command not found: markdownlint`.

## Decision Log

- Decision: Keep this as a first-pass architecture lab rather than a deployable production baseline.
  Rationale: The prompt explicitly asks for documentation-first content with sensible placeholders and no live Azure deployment.
  Date/Author: 2026-05-25, Codex.

- Decision: Use Bicep as the only infrastructure-as-code direction.
  Rationale: The user plan requires Azure infrastructure to use Bicep only, and local validation searches for other infrastructure formats.
  Date/Author: 2026-05-25, Codex.

- Decision: Use TODO comments for environment-specific resource names, identities, endpoints, policies, and private networking details.
  Rationale: The repo must avoid real secrets, real tenant IDs, and production endpoints while still showing the intended architecture.
  Date/Author: 2026-05-25, Codex.

- Decision: Omit scenario-level policy XML from private networking and APIOps scenarios.
  Rationale: The plan identifies those as deployment and process scenarios rather than runtime policy examples.
  Date/Author: 2026-05-25, Codex.

## Outcomes & Retrospective

The scaffold now represents all first-pass acceptance criteria from the local prompt: required top-level docs, eight core docs, six ADRs, twelve scenario packs, ten scenario policy examples, eight reusable policy examples, ten Mermaid files, six KQL placeholders, a safe Bicep skeleton, and four workflow templates. Remaining work is intentionally deferred to future implementation waves: tested APIM import automation, mock backend apps, real Bicep modules, load tests, dashboards, and environment-specific deployment instructions.

Validation completed on 2026-05-25. `git diff --check` returned no errors. The blocked infrastructure-term search returned no matches. The required file existence check returned exit code 0. Scenario Markdown count was `144`. Policy example XML count was `8`. `az bicep build --file infra/bicep/main.bicep` returned exit code 0. `xmllint --noout policies/examples/*.xml` returned exit code 0. `markdownlint "**/*.md"` could not run because `markdownlint` is not installed.

## Context and Orientation

The repository is `azure-apim-ai-gateway-architecture-lab`. It began as a documentation-first project with `requirements/`, `design-log/`, `prompts/`, and `instructuctions/`. The local prompt at `prompts/apim-ai-gateway-codex-prompt.md` defines the desired first-pass scaffold.

Azure API Management, abbreviated APIM, is a managed Azure gateway for HTTP APIs. In this repo, APIM is the policy enforcement layer between client applications and model backends. Azure AI Foundry and Azure OpenAI are treated as backend model providers. A policy is APIM runtime configuration that can validate, transform, route, cache, or log a request or response. Semantic caching means reusing a previous model response when a new prompt is similar enough according to an embeddings comparison.

## Plan of Work

Create the top-level README, contribution guide, and ignore rules. Add the required docs under `docs/`, decision records under `docs/adr/`, scenario packs under `scenarios/`, APIM policy examples under `policies/`, Mermaid diagrams under `diagrams/mermaid/`, KQL placeholders under `observability/app-insights-kql/`, a safe Bicep skeleton under `infra/bicep/`, and safe workflow templates under `.github/workflows/`. Do not create real Azure resources. Do not add real secrets, tenant IDs, or production endpoints.

## Concrete Steps

Run from the repository root:

    git status --short
    rg --files

Generate the documentation and skeleton files. Then validate with:

    git diff --check
    rg -n "<blocked non-Bicep infrastructure terms>" .
    test -f README.md && test -f CONTRIBUTING.md && test -f infra/bicep/main.bicep
    find scenarios -mindepth 2 -maxdepth 2 -name '*.md' | wc -l
    find policies/examples -maxdepth 1 -name '*.xml' | wc -l
    az bicep build --file infra/bicep/main.bicep
    xmllint --noout policies/examples/*.xml
    markdownlint "**/*.md"

## Validation and Acceptance

Acceptance is met when the repo contains the required scaffold, scenario Markdown count is `144`, policy example count is `8`, Bicep compiles, policy XML is well-formed, and no blocked non-Bicep infrastructure terms appear in the repository. If `markdownlint`, `az`, or `xmllint` is not installed, record that the command could not be run.

## Idempotence and Recovery

The scaffold is additive and can be regenerated by reapplying the same file contents. If validation fails, inspect the named file, fix it in place, and rerun the exact failing command. The Bicep skeleton creates no Azure resources and the workflows are validation templates, so no cloud cleanup is required.

## Artifacts and Notes

The main artifacts are the scenario packs, docs, policy examples, diagrams, KQL files, Bicep skeleton, and workflow templates. The validation commands above are the evidence of completion.

## Interfaces and Dependencies

The repository depends on standard Markdown, APIM policy XML, Mermaid diagram syntax, KQL text files, GitHub Actions YAML, and Bicep. Optional local tools are `az`, `xmllint`, and `markdownlint`. No live Azure subscription is required for the first pass.

## Change Note

2026-05-25: Created this ExecPlan to document the first-pass scaffold implementation and the decisions needed to keep the repository safe, documentation-first, and reproducible.
