#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
validator="$repo_root/tools/validate-workflow-guardrails.sh"

make_fixture() {
  local dir="$1"
  mkdir -p "$dir/.github/workflows"
}

expect_success() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  cat >"$dir/.github/workflows/manual.yml" <<'EOF'
name: Manual

on:
  workflow_dispatch:
    inputs:
      expected_repository:
        required: true
        default: collaborationwithothers/azure-apim-ai-gateway-architecture-lab
      expected_actor:
        required: true
        default: haripraghash

permissions:
  contents: read

jobs:
  validate:
    if: >-
      github.event_name == 'workflow_dispatch' &&
      github.repository == inputs.expected_repository &&
      github.actor == inputs.expected_actor &&
      github.ref == 'refs/heads/main'
    runs-on: [self-hosted, linux, x64, cwc-azure-deploy]
    steps:
      - run: echo ok
EOF
  "$validator" --root "$dir" >/tmp/workflow-guardrails-success.out
}

expect_failure_for_pr_trigger() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  cat >"$dir/.github/workflows/pr.yml" <<'EOF'
name: Bad
on:
  pull_request:
jobs:
  bad:
    runs-on: ubuntu-latest
    steps:
      - run: echo bad
EOF
  if "$validator" --root "$dir" >/tmp/workflow-guardrails-pr.out 2>&1; then
    echo "expected pull_request trigger to fail" >&2
    return 1
  fi
  grep -q "must not contain pull_request triggers" \
    /tmp/workflow-guardrails-pr.out
}

expect_failure_for_missing_job_guard() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  cat >"$dir/.github/workflows/missing-guard.yml" <<'EOF'
name: Missing Guard
on:
  workflow_dispatch:
jobs:
  bad:
    runs-on: ubuntu-latest
    steps:
      - run: echo bad
EOF
  if "$validator" --root "$dir" >/tmp/workflow-guardrails-guard.out 2>&1; then
    echo "expected missing job guard to fail" >&2
    return 1
  fi
  grep -q "is missing required guard" /tmp/workflow-guardrails-guard.out
}

expect_failure_for_github_hosted_runner() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  cat >"$dir/.github/workflows/github-hosted.yml" <<'EOF'
name: GitHub Hosted

on:
  workflow_dispatch:
    inputs:
      expected_repository:
        required: true
        default: collaborationwithothers/azure-apim-ai-gateway-architecture-lab
      expected_actor:
        required: true
        default: haripraghash

permissions:
  contents: read

jobs:
  bad:
    if: >-
      github.event_name == 'workflow_dispatch' &&
      github.repository == inputs.expected_repository &&
      github.actor == inputs.expected_actor &&
      github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - run: echo bad
EOF
  if "$validator" --root "$dir" >/tmp/workflow-guardrails-runner.out 2>&1; then
    echo "expected GitHub-hosted runner to fail" >&2
    return 1
  fi
  grep -q "must use the managed Azure VNet runner labels" \
    /tmp/workflow-guardrails-runner.out
}

expect_failure_for_runner_mutation() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  cat >"$dir/.github/workflows/mutates-runner.yml" <<'EOF'
name: Mutates Runner

on:
  workflow_dispatch:
    inputs:
      expected_repository:
        required: true
        default: collaborationwithothers/azure-apim-ai-gateway-architecture-lab
      expected_actor:
        required: true
        default: haripraghash

permissions:
  contents: read

jobs:
  bad:
    if: >-
      github.event_name == 'workflow_dispatch' &&
      github.repository == inputs.expected_repository &&
      github.actor == inputs.expected_actor &&
      github.ref == 'refs/heads/main'
    runs-on: [self-hosted, linux, x64, cwc-azure-deploy]
    steps:
      - run: sudo apt-get update
EOF
  if "$validator" --root "$dir" >/tmp/workflow-guardrails-mutate.out 2>&1; then
    echo "expected runner mutation to fail" >&2
    return 1
  fi
  grep -q "must not mutate the managed runner" \
    /tmp/workflow-guardrails-mutate.out
}

expect_success
expect_failure_for_pr_trigger
expect_failure_for_missing_job_guard
expect_failure_for_github_hosted_runner
expect_failure_for_runner_mutation

echo "validate-workflow-guardrails tests passed"
