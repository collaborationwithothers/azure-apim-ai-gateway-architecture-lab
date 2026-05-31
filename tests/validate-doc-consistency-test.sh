#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
validator="$repo_root/tools/validate-doc-consistency.sh"

make_fixture() {
  local dir="$1"
  mkdir -p "$dir/scenarios/00-alpha" "$dir/scenarios/01-beta"
  mkdir -p "$dir/requirements" "$dir/design-log"
  cat >"$dir/README.md" <<'EOF'
# Fixture

## Scenario table

| Scenario | Focus | Policy example |
| -------- | ----- | -------------- |
| 00       | Alpha | No             |
| 01       | Beta  | No             |

| `scenarios/` | Two mini system design case studies. |
EOF
  touch "$dir/scenarios/00-alpha/README.md"
  touch "$dir/scenarios/01-beta/README.md"
  cat >"$dir/requirements/index.md" <<'EOF'
# Requirements Index

| 001 | [Alpha](001-alpha.md) | First requirement. |
EOF
  cat >"$dir/requirements/001-alpha.md" <<'EOF'
---
id: REQ-001
title: Alpha
---

# Alpha
EOF
  cat >"$dir/design-log/index.md" <<'EOF'
# Design Log Index

| 001 | [Alpha](001-alpha.md) | First design log. |
EOF
  cat >"$dir/design-log/001-alpha.md" <<'EOF'
# Design Log #001: Alpha
EOF
}

expect_success() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  "$validator" --root "$dir" >/tmp/doc-consistency-success.out
}

expect_failure_for_missing_scenario_row() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  mkdir -p "$dir/scenarios/02-gamma"
  touch "$dir/scenarios/02-gamma/README.md"
  if "$validator" --root "$dir" >/tmp/doc-consistency-failure.out 2>&1; then
    echo "expected missing scenario row to fail" >&2
    return 1
  fi
  grep -q "README.md scenario table is missing 02" /tmp/doc-consistency-failure.out
}

expect_failure_for_missing_requirement_index_entry() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  cat >"$dir/requirements/002-beta.md" <<'EOF'
---
id: REQ-002
title: Beta
---

# Beta
EOF
  if "$validator" --root "$dir" >/tmp/doc-consistency-req.out 2>&1; then
    echo "expected missing requirements index entry to fail" >&2
    return 1
  fi
  grep -q "requirements/index.md is missing 002-beta.md" \
    /tmp/doc-consistency-req.out
}

expect_failure_for_missing_design_log_index_entry() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  cat >"$dir/design-log/002-beta.md" <<'EOF'
# Design Log #002: Beta
EOF
  if "$validator" --root "$dir" >/tmp/doc-consistency-design.out 2>&1; then
    echo "expected missing design-log index entry to fail" >&2
    return 1
  fi
  grep -q "design-log/index.md is missing 002-beta.md" \
    /tmp/doc-consistency-design.out
}

expect_failure_for_missing_persistent_lifecycle_text() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  mkdir -p "$dir/infra/bicep" "$dir/docs/plans"
  cat >"$dir/infra/bicep/README.md" <<'EOF'
# Hub-Spoke Bicep Deployment
EOF
  cat >"$dir/requirements/001-hub-spoke-apim-edge-platform.md" <<'EOF'
# Hub-Spoke APIM Edge Platform
swedencentral
EOF
  cat >"$dir/design-log/001-hub-spoke-apim-edge-platform.md" <<'EOF'
# Design Log #001: Hub-Spoke APIM Edge Platform
swedencentral
EOF
  cat >"$dir/docs/plans/2026-05-31-spoke-full-demo-stack.md" <<'EOF'
# Plan
EOF
  if "$validator" --root "$dir" >/tmp/doc-consistency-lifecycle.out 2>&1; then
    echo "expected missing persistent lifecycle text to fail" >&2
    return 1
  fi
  grep -q "rg-cwc-ai-gw-shared-swc-001" /tmp/doc-consistency-lifecycle.out
}

expect_success
expect_failure_for_missing_scenario_row
expect_failure_for_missing_requirement_index_entry
expect_failure_for_missing_design_log_index_entry
expect_failure_for_missing_persistent_lifecycle_text

echo "validate-doc-consistency tests passed"
