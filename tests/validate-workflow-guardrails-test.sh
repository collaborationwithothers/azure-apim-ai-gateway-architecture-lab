#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
validator="$repo_root/tools/validate-workflow-guardrails.sh"
checkout_sha="34e114876b0b11c390a56381ad16ebd13914f8d5"
azure_login_sha="1384c340ab2dda50fed2bee3041d1d87018aa5e8"

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

expect_success_for_guarded_deployment_workflows() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  cat >"$dir/.github/workflows/infra-deploy.yml" <<EOF
name: Infra Deploy
on:
  workflow_dispatch:
    inputs:
      expected_repository:
        required: true
      mode:
        type: choice
        options:
          - validate
          - what-if
          - apply
      runner_allowed_public_ip:
        required: true
      enable_public_edge:
        type: choice
        options:
          - "false"
          - "true"
      enable_custom_domain:
        type: choice
        options:
          - "false"
          - "true"
permissions:
  contents: read
jobs:
  validate:
    if: >-
      github.event_name == 'workflow_dispatch' &&
      github.repository == 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab' &&
      github.actor == 'haripraghash' &&
      github.ref == 'refs/heads/main'
    runs-on: [self-hosted, linux, x64, cwc-azure-deploy]
    steps:
      - uses: actions/checkout@$checkout_sha
      - run: |
          az bicep restore --file infra/bicep/main.bicep
          az bicep build --file infra/bicep/main.bicep
  what-if:
    if: >-
      github.event_name == 'workflow_dispatch' &&
      github.repository == 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab' &&
      github.actor == 'haripraghash' &&
      github.ref == 'refs/heads/main'
    runs-on: [self-hosted, linux, x64, cwc-azure-deploy]
    environment: dev
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@$checkout_sha
      - uses: azure/login@$azure_login_sha
      - run: |
          az provider show --namespace Microsoft.Network
          az provider show --namespace Microsoft.ApiManagement
          az provider show --namespace Microsoft.ContainerRegistry
          az provider show --namespace Microsoft.KeyVault
          az provider show --namespace Microsoft.Insights
          az provider show --namespace Microsoft.OperationalInsights
          az provider show --namespace Microsoft.Web
          az deployment sub what-if --location eastus2 --template-file infra/bicep/main.bicep --parameters runnerAllowedPublicIp=203.0.113.10/32 enablePublicEdge=false enableCustomDomain=false
  apply:
    if: >-
      github.event_name == 'workflow_dispatch' &&
      github.repository == 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab' &&
      github.actor == 'haripraghash' &&
      github.ref == 'refs/heads/main'
    runs-on: [self-hosted, linux, x64, cwc-azure-deploy]
    environment: dev
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@$checkout_sha
      - uses: azure/login@$azure_login_sha
      - run: |
          az provider register --namespace Microsoft.Network
          az deployment sub create --location eastus2 --template-file infra/bicep/main.bicep --parameters runnerAllowedPublicIp=203.0.113.10/32 enablePublicEdge=false enableCustomDomain=false
EOF
  cat >"$dir/.github/workflows/certificate-issue.yml" <<EOF
name: Certificate Issue
on:
  workflow_dispatch:
    inputs:
      expected_repository:
        required: true
permissions:
  contents: read
jobs:
  issue:
    if: >-
      github.event_name == 'workflow_dispatch' &&
      github.repository == 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab' &&
      github.actor == 'haripraghash' &&
      github.ref == 'refs/heads/main'
    runs-on: [self-hosted, linux, x64, cwc-azure-deploy]
    environment: dev
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@$checkout_sha
      - uses: azure/login@$azure_login_sha
      - run: |
          echo api.consultwithcloud.com
          az network dns record-set txt add-record --record-set-name _acme-challenge
          az network dns record-set txt remove-record --record-set-name _acme-challenge
          openssl pkcs12 -export -out certificate.pfx
          az keyvault certificate import --name cert-api-consultwithcloud-com
EOF
  "$validator" --root "$dir" >/tmp/workflow-guardrails-deploy-success.out
}

expect_failure_for_deployment_missing_oidc() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  cat >"$dir/.github/workflows/infra-deploy.yml" <<EOF
name: Infra Deploy
on:
  workflow_dispatch:
    inputs:
      expected_repository:
        required: true
      mode:
        type: choice
        options: [validate, what-if, apply]
permissions:
  contents: read
jobs:
  bad:
    if: >-
      github.event_name == 'workflow_dispatch' &&
      github.repository == 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab' &&
      github.actor == 'haripraghash' &&
      github.ref == 'refs/heads/main'
    runs-on: [self-hosted, linux, x64, cwc-azure-deploy]
    environment: dev
    steps:
      - uses: actions/checkout@$checkout_sha
      - uses: azure/login@$azure_login_sha
      - run: az deployment sub what-if
EOF
  if "$validator" --root "$dir" >/tmp/workflow-guardrails-oidc.out 2>&1; then
    echo "expected deployment workflow without id-token permission to fail" >&2
    return 1
  fi
  grep -q "must set id-token: write permission" \
    /tmp/workflow-guardrails-oidc.out
}

expect_failure_for_deployment_top_level_oidc() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  cat >"$dir/.github/workflows/infra-deploy.yml" <<EOF
name: Infra Deploy
on:
  workflow_dispatch:
    inputs:
      expected_repository:
        required: true
      mode:
        type: choice
        options: [validate, what-if, apply]
permissions:
  contents: read
  id-token: write
jobs:
  bad:
    if: >-
      github.event_name == 'workflow_dispatch' &&
      github.repository == 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab' &&
      github.actor == 'haripraghash' &&
      github.ref == 'refs/heads/main'
    runs-on: [self-hosted, linux, x64, cwc-azure-deploy]
    environment: dev
    steps:
      - uses: actions/checkout@$checkout_sha
      - uses: azure/login@$azure_login_sha
      - run: az deployment sub what-if
EOF
  if "$validator" --root "$dir" >/tmp/workflow-guardrails-top-oidc.out 2>&1; then
    echo "expected workflow-level id-token permission to fail" >&2
    return 1
  fi
  grep -q "must scope id-token: write to Azure jobs" \
    /tmp/workflow-guardrails-top-oidc.out
}

expect_failure_for_deployment_missing_environment() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  cat >"$dir/.github/workflows/certificate-issue.yml" <<EOF
name: Certificate Issue
on:
  workflow_dispatch:
    inputs:
      expected_repository:
        required: true
permissions:
  contents: read
jobs:
  bad:
    if: >-
      github.event_name == 'workflow_dispatch' &&
      github.repository == 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab' &&
      github.actor == 'haripraghash' &&
      github.ref == 'refs/heads/main'
    runs-on: [self-hosted, linux, x64, cwc-azure-deploy]
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@$checkout_sha
      - uses: azure/login@$azure_login_sha
      - run: az keyvault certificate import --name cert-api-consultwithcloud-com
EOF
  if "$validator" --root "$dir" >/tmp/workflow-guardrails-environment.out 2>&1; then
    echo "expected Azure-changing workflow without environment to fail" >&2
    return 1
  fi
  grep -q "must require a GitHub Environment" \
    /tmp/workflow-guardrails-environment.out
}

expect_failure_for_input_environment() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  cat >"$dir/.github/workflows/certificate-issue.yml" <<EOF
name: Certificate Issue
on:
  workflow_dispatch:
    inputs:
      expected_repository:
        required: true
      github_environment:
        required: true
permissions:
  contents: read
jobs:
  issue:
    if: >-
      github.event_name == 'workflow_dispatch' &&
      github.repository == 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab' &&
      github.actor == 'haripraghash' &&
      github.ref == 'refs/heads/main'
    runs-on: [self-hosted, linux, x64, cwc-azure-deploy]
    environment: \${{ inputs.github_environment }}
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@$checkout_sha
      - uses: azure/login@$azure_login_sha
      - run: az keyvault certificate import --name cert-api-consultwithcloud-com
EOF
  if "$validator" --root "$dir" >/tmp/workflow-guardrails-input-environment.out 2>&1; then
    echo "expected caller-controlled environment to fail" >&2
    return 1
  fi
  grep -q "must not use caller-controlled inputs" \
    /tmp/workflow-guardrails-input-environment.out
}

expect_failure_for_caller_controlled_repository_guard() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  cat >"$dir/.github/workflows/infra-deploy.yml" <<EOF
name: Infra Deploy
on:
  workflow_dispatch:
    inputs:
      expected_repository:
        required: true
      mode:
        type: choice
        options: [validate, what-if, apply]
permissions:
  contents: read
jobs:
  bad:
    if: >-
      github.event_name == 'workflow_dispatch' &&
      github.repository == inputs.expected_repository &&
      github.actor == 'haripraghash' &&
      github.ref == 'refs/heads/main'
    runs-on: [self-hosted, linux, x64, cwc-azure-deploy]
    environment: dev
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@$checkout_sha
      - uses: azure/login@$azure_login_sha
      - run: az deployment sub create
EOF
  if "$validator" --root "$dir" >/tmp/workflow-guardrails-repo.out 2>&1; then
    echo "expected caller-controlled repository guard to fail" >&2
    return 1
  fi
  grep -q "must not use caller-controlled inputs.expected_repository" \
    /tmp/workflow-guardrails-repo.out
}

expect_failure_for_unpinned_actions() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  cat >"$dir/.github/workflows/certificate-issue.yml" <<'EOF'
name: Certificate Issue
on:
  workflow_dispatch:
    inputs:
      expected_repository:
        required: true
permissions:
  contents: read
jobs:
  issue:
    if: >-
      github.event_name == 'workflow_dispatch' &&
      github.repository == 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab' &&
      github.actor == 'haripraghash' &&
      github.ref == 'refs/heads/main'
    runs-on: [self-hosted, linux, x64, cwc-azure-deploy]
    environment: dev
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@v4
      - uses: azure/login@v2
      - run: |
          echo api.consultwithcloud.com
          az network dns record-set txt add-record --record-set-name _acme-challenge
          az network dns record-set txt remove-record --record-set-name _acme-challenge
          openssl pkcs12 -export -out certificate.pfx
          az keyvault certificate import --name cert-api-consultwithcloud-com
EOF
  if "$validator" --root "$dir" >/tmp/workflow-guardrails-pinning.out 2>&1; then
    echo "expected unpinned actions to fail" >&2
    return 1
  fi
  grep -q "must pin azure/login" /tmp/workflow-guardrails-pinning.out
  grep -q "must pin actions/checkout" /tmp/workflow-guardrails-pinning.out
}

expect_failure_for_deployment_command_in_unapproved_job() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  cat >"$dir/.github/workflows/infra-deploy.yml" <<EOF
name: Infra Deploy
on:
  workflow_dispatch:
    inputs:
      expected_repository:
        required: true
      mode:
        type: choice
        options: [validate, what-if, apply]
permissions:
  contents: read
jobs:
  validate:
    if: >-
      github.event_name == 'workflow_dispatch' &&
      github.repository == 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab' &&
      github.actor == 'haripraghash' &&
      github.ref == 'refs/heads/main'
    runs-on: [self-hosted, linux, x64, cwc-azure-deploy]
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@$checkout_sha
      - uses: azure/login@$azure_login_sha
      - run: az deployment sub create --location eastus2 --template-file infra/bicep/main.bicep
EOF
  if "$validator" --root "$dir" >/tmp/workflow-guardrails-command-env.out 2>&1; then
    echo "expected Azure-changing command in unapproved job to fail" >&2
    return 1
  fi
  grep -q "Azure-changing jobs: validate" \
    /tmp/workflow-guardrails-command-env.out
}

expect_failure_for_provider_register_in_what_if() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  cat >"$dir/.github/workflows/infra-deploy.yml" <<EOF
name: Infra Deploy
on:
  workflow_dispatch:
    inputs:
      expected_repository:
        required: true
      mode:
        type: choice
        options: [validate, what-if, apply]
permissions:
  contents: read
jobs:
  what-if:
    if: >-
      github.event_name == 'workflow_dispatch' &&
      github.repository == 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab' &&
      github.actor == 'haripraghash' &&
      github.ref == 'refs/heads/main'
    runs-on: [self-hosted, linux, x64, cwc-azure-deploy]
    environment: dev
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@$checkout_sha
      - uses: azure/login@$azure_login_sha
      - run: |
          az provider register --namespace Microsoft.Network
          az deployment sub what-if
EOF
  if "$validator" --root "$dir" >/tmp/workflow-guardrails-provider-what-if.out 2>&1; then
    echo "expected provider register in what-if to fail" >&2
    return 1
  fi
  grep -q "must not run az provider register in what-if jobs" \
    /tmp/workflow-guardrails-provider-what-if.out
}

expect_failure_for_deployment_missing_hardcoded_actor_guard() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  cat >"$dir/.github/workflows/infra-deploy.yml" <<EOF
name: Infra Deploy
on:
  workflow_dispatch:
    inputs:
      expected_repository:
        required: true
      mode:
        type: choice
        options: [validate, what-if, apply]
permissions:
  contents: read
jobs:
  bad:
    if: >-
      github.event_name == 'workflow_dispatch' &&
      github.repository == 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab' &&
      github.actor == inputs.expected_actor &&
      github.ref == 'refs/heads/main'
    runs-on: [self-hosted, linux, x64, cwc-azure-deploy]
    environment: dev
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@$checkout_sha
      - uses: azure/login@$azure_login_sha
      - run: az deployment sub create
EOF
  if "$validator" --root "$dir" >/tmp/workflow-guardrails-actor.out 2>&1; then
    echo "expected deployment workflow without hard-coded actor guard to fail" >&2
    return 1
  fi
  grep -q "must guard github.actor against haripraghash" \
    /tmp/workflow-guardrails-actor.out
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
expect_success_for_guarded_deployment_workflows
expect_failure_for_deployment_missing_oidc
expect_failure_for_deployment_top_level_oidc
expect_failure_for_deployment_missing_environment
expect_failure_for_input_environment
expect_failure_for_caller_controlled_repository_guard
expect_failure_for_unpinned_actions
expect_failure_for_deployment_command_in_unapproved_job
expect_failure_for_provider_register_in_what_if
expect_failure_for_deployment_missing_hardcoded_actor_guard
expect_failure_for_pr_trigger
expect_failure_for_missing_job_guard
expect_failure_for_github_hosted_runner
expect_failure_for_runner_mutation

echo "validate-workflow-guardrails tests passed"
