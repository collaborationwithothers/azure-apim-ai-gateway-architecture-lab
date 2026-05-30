# Bicep Skeleton

This folder contains a safe first-pass Bicep skeleton. It is intended to compile locally and document resource boundaries. It does not deploy APIM, Azure AI services, monitoring, cache, Key Vault, private endpoints, or private DNS yet.

## Validate

    az bicep build --file infra/bicep/main.bicep

## TODOs

- Add APIM module.
- Add Azure AI Foundry or Azure OpenAI module.
- Add Application Insights and Log Analytics module.
- Add Redis-compatible cache module for semantic caching.
- Add Key Vault module for named values and secrets.
- Add private endpoints and private DNS modules for private networking.
