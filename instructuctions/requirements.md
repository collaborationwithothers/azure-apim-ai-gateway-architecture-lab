---
description: "This rule provides standards for requirements documents"
alwaysApply: true
---

# Project Rules

## Requirements Methodology

The project maintains numbered requirements documents for all significant features, workflow changes, and system integrations.

### Before Creating a Requirements Document
1. **Check `requirements/index.md`** for an existing document covering the request before creating a new one.
2. **Check `design-log/index.md`** — requirements and design logs are complementary; link them when related.
3. **Requirements not required** for trivial changes (typos, config tweaks, non-behavioral formatting) unless the change has cross-team or multi-PR scope.

### When Creating a Requirements Document
1. **Numbering & filename**:
   - Use a sequential 3-digit number and a short slug: `requirements/NNN-short-title.md` (example: `requirements/007-apim-hardening.md`)
   - Start the file with a front-matter block:
     ```
     ---
     id: REQ-NNN
     title: <descriptive title>
     created: <YYYY-MM-DD>
     status: Active | Superseded | Archived
     design-log: "<NNN or empty>"
     ---
     ```
2. **Structure**: Follow this section order:
   - Overview (Problem statement, Goals, Non-goals, Executive summary)
   - Stakeholders
   - Scope (In-scope, Out-of-scope, Repos and components affected)
   - Functional Requirements (FR-N numbered, each with Description, Rationale, Acceptance criteria)
   - Non-Functional Requirements (NFR-N numbered)
   - Data, Security, and Compliance
   - Networking and Connectivity
   - Open Questions (if any)
   - Assumptions (if any)
3. **Be specific**: Include parameter tables, decision tables, and named acceptance criteria.
4. **Link design log**: If a design log exists or will be created for this feature, reference it in the front-matter `design-log` field and in the requirements body.
5. **Never store secrets**: Record the *type* of secret needed, not its value.

### When Updating a Requirements Document
1. **Do not renumber existing FRs** — append new ones with the next available number.
2. **Mark superseded content** with a note rather than deleting, so the history is traceable.
3. **Update `requirements/index.md`** if the title or status changes.
4. **Update Status** in the front-matter when the requirement is fully implemented (`status: Active`) or replaced (`status: Superseded`).

### Requirements Index

1. **Maintain `requirements/index.md`**: Catalog all requirements documents by category in markdown tables.
2. **Check index first**: Before reading: check index.md to find relevant documents.
3. **After creating/updating**: Add new entries to the appropriate category table.
4. **Number source of truth**: The `NNN` in the filename is the requirements number used in references (e.g., "See REQ-007").
5. **Table format**:
   ```markdown
   ## Category Name
   | # | Title | Description |
   |---|-------|-------------|
   | NNN | [title](NNN-short-title.md) | date — brief one-line description |
   ```
6. **Group by feature area**: Core/Governance, Networking, Identity/RBAC, Foundry, Pipelines/CI-CD, etc.

### Relationship to Design Logs
- A requirements document captures **WHAT** is needed and **WHY**.
- A design log captures **HOW** it will be built and the trade-off decisions.
- For significant features, both should exist and cross-reference each other.
- Requirements come first; design logs are created after requirements are approved.

### Commitment Policy
- **Requirements documents ARE committed** to the repository (unlike the old root `Requirements.md` which was transient).
- They serve as the permanent record of what was asked for and agreed to.
- `Comments.md` remains transient (code review output only — do not commit).
