# Contributing

This project is a documentation-first Azure APIM AI Gateway architecture lab. Contributions should improve clarity, correctness, and verifiability.

## Local checks

Run these checks from the repository root before opening a pull request:

    git status --short
    git diff --check
    rg -n "PLACEHOLDER_SECRET|real-tenant|prod.example" .
    az bicep build --file infra/bicep/main.bicep
    xmllint --noout policies/examples/*.xml

Run Markdown linting when available:

    markdownlint "**/*.md"

## Documentation rules

- Use short, direct sections with descriptive headings.
- Use repository-relative paths in backticks.
- Do not invent Azure behavior. Mark uncertain details as assumptions or TODOs.
- Include real Microsoft Learn citations when making factual Azure claims.
- Do not commit real secrets, tenant IDs, keys, deployment outputs, or local parameter files.
- Keep examples architecture-grade until tested against a real environment.

## Scenario rules

Each scenario README must remain a mini system design case study with business problem, requirements, constraints, architecture, decision, implementation, security, performance, cost, failure modes, observability, test plan, demo script, and what it demonstrates.
