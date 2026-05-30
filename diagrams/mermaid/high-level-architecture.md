# High Level Architecture

```mermaid
flowchart LR
  client[Client apps] --> apim[Azure API Management]
  apim --> policies[Gateway policies]
  policies --> aoai[Azure AI Foundry or Azure OpenAI]
  policies --> kv[Key Vault]
  policies --> redis[Managed Redis or compatible cache]
  apim --> ai[Application Insights]
  ai --> law[Log Analytics]
```
