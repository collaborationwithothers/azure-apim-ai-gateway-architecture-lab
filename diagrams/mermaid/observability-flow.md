# Observability Flow

```mermaid
flowchart LR
  apim[APIM gateway] --> metrics[Token and latency metrics]
  apim --> logs[Request logs]
  metrics --> appi[Application Insights]
  logs --> law[Log Analytics]
  law --> workbook[Workbooks and dashboards]
```
