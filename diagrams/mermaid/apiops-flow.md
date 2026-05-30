# Apiops Flow

```mermaid
flowchart LR
  change[Policy or Bicep change] --> validate[Validate Markdown, XML, and Bicep]
  validate --> review[Pull request review]
  review --> promote[Environment promotion]
  promote --> observe[Post-deploy observation]
```
