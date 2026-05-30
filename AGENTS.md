# Repository Guidelines

## Project Structure & Module Organization

This repository is currently documentation-first for an Azure APIM AI Gateway architecture lab. Keep planning and source-of-truth documents in these locations:

- `requirements/`: numbered requirements documents plus `requirements/index.md`.
- `design-log/`: numbered architecture and implementation decision logs plus `design-log/index.md`.
- `prompts/`: prompts used to generate or guide repository content.
- `instructuctions/`: local authoring rules for requirements, design logs, and ExecPlans. Preserve the existing directory spelling unless the project is deliberately migrated.

The planned lab structure is described in `prompts/apim-ai-gateway-codex-prompt.md`; do not claim directories such as `docs/`, `infra/`, `policies/`, `apps/`, or `tests/` exist until they are created.

## Build, Test, and Development Commands

There is no application build or test runner yet. Use lightweight validation before committing documentation changes:

- `git status --short`: inspect pending changes.
- `rg --files`: list tracked and untracked repository files quickly.
- `git diff --check`: catch trailing whitespace and patch formatting issues.
- `markdownlint "**/*.md"`: lint Markdown if `markdownlint` is installed.

When infrastructure is added, use Azure Bicep under the planned `infra/bicep/` and `infra/modules/` directories. Prefer Azure Verified Modules (AVM) from the public Bicep registry over locally authored Bicep modules whenever an AVM resource or pattern module already exists for the Azure resource being deployed. Before creating a local module under `infra/modules/`, check the AVM Bicep module index and document one of these outcomes in the related requirement, design log, or pull request:

- Use the AVM module because it exists and fits the resource need.
- Wrap or compose the AVM module only when local orchestration, naming, tagging, diagnostics, or opinionated defaults are required.
- Create a local module only when no suitable AVM module exists, the AVM module lacks a required capability, or the lab intentionally needs to demonstrate the raw resource shape.

Pin AVM module versions explicitly, keep environment-specific values in parameters, and avoid copying AVM source code into this repository. Validate templates before deployment, for example with `az bicep build --file infra/bicep/main.bicep` once that file exists.

## Coding Style & Naming Conventions

Write Markdown in short, direct sections with descriptive headings. Use repository-relative paths in backticks, for example `requirements/007-apim-hardening.md`.

Requirements documents must use `requirements/NNN-short-title.md`, include front matter with `id: REQ-NNN`, and update `requirements/index.md`. Design logs must use `design-log/NNN-short-title.md`, start with `# Design Log #NNN: <Title>`, and update `design-log/index.md`.

## Testing Guidelines

No automated tests are present yet. For documentation-only changes, verify links, numbering, index entries, and terminology manually. For future code, add tests under the planned `tests/` tree and document the exact command needed to run them.

## Commit & Pull Request Guidelines

The current Git history only shows `Initial commit`, so there is no established convention. Use concise, imperative commit subjects, such as `Add APIM token governance requirements`.

Pull requests should include a short summary, changed paths, validation performed, and linked requirement or design-log numbers. Include screenshots or rendered diagrams when visual architecture content changes.

## Security & Configuration Tips

Do not commit secrets, keys, tenant-specific credentials, local Bicep parameter files, or generated deployment outputs. Document required secret names and configuration values, not their actual values.
