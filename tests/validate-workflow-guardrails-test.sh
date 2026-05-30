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
    runs-on:
      group: consultwithcloud-azure
      labels: [gh-linux]
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
      inputs.expected_repository == 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab' &&
      github.actor == 'haripraghash' &&
      github.ref == 'refs/heads/main'
    runs-on:
      group: consultwithcloud-azure
      labels: [gh-linux]
    steps:
      - uses: actions/checkout@$checkout_sha
      - run: |
          az bicep restore --file infra/bicep/main.bicep
          az bicep build --file infra/bicep/main.bicep
  what-if:
    if: >-
      github.event_name == 'workflow_dispatch' &&
      github.repository == 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab' &&
      inputs.expected_repository == 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab' &&
      github.actor == 'haripraghash' &&
      github.ref == 'refs/heads/main'
    runs-on:
      group: consultwithcloud-azure
      labels: [gh-linux]
    environment: dev
    permissions:
      contents: read
      id-token: write
    env:
      RUNNER_ALLOWED_PUBLIC_IP: \${{ vars.RUNNER_ALLOWED_PUBLIC_IP_CIDR }}
    steps:
      - uses: actions/checkout@$checkout_sha
      - uses: azure/login@$azure_login_sha
      - run: |
          if [[ ! "\$RUNNER_ALLOWED_PUBLIC_IP" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}$ ]]; then
            echo "RUNNER_ALLOWED_PUBLIC_IP_CIDR must be an IPv4 CIDR value, for example 203.0.113.10/32." >&2
            exit 1
          fi
          az provider show --namespace Microsoft.Network
          az provider show --namespace Microsoft.ApiManagement
          az provider show --namespace Microsoft.ContainerRegistry
          az provider show --namespace Microsoft.KeyVault
          az provider show --namespace Microsoft.Insights
          az provider show --namespace Microsoft.OperationalInsights
          az provider show --namespace Microsoft.Web
          az deployment sub what-if --location eastus2 --template-file infra/bicep/main.bicep --parameters runnerAllowedPublicIp="\$RUNNER_ALLOWED_PUBLIC_IP" enablePublicEdge=false enableCustomDomain=false
  apply:
    if: >-
      github.event_name == 'workflow_dispatch' &&
      github.repository == 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab' &&
      inputs.expected_repository == 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab' &&
      github.actor == 'haripraghash' &&
      github.ref == 'refs/heads/main'
    runs-on:
      group: consultwithcloud-azure
      labels: [gh-linux]
    environment: dev
    permissions:
      contents: read
      id-token: write
    env:
      RUNNER_ALLOWED_PUBLIC_IP: \${{ vars.RUNNER_ALLOWED_PUBLIC_IP_CIDR }}
    steps:
      - uses: actions/checkout@$checkout_sha
      - uses: azure/login@$azure_login_sha
      - run: |
          if [[ ! "\$RUNNER_ALLOWED_PUBLIC_IP" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}$ ]]; then
            echo "RUNNER_ALLOWED_PUBLIC_IP_CIDR must be an IPv4 CIDR value, for example 203.0.113.10/32." >&2
            exit 1
          fi
          az provider register --namespace Microsoft.Network
          az deployment sub create --location eastus2 --template-file infra/bicep/main.bicep --parameters runnerAllowedPublicIp="\$RUNNER_ALLOWED_PUBLIC_IP" enablePublicEdge=false enableCustomDomain=false
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
      inputs.expected_repository == 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab' &&
      github.actor == 'haripraghash' &&
      github.ref == 'refs/heads/main'
    runs-on:
      group: consultwithcloud-azure
      labels: [gh-linux]
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

expect_success_for_guarded_destroy_workflow() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  cat >"$dir/.github/workflows/infra-destroy.yml" <<EOF
name: Infra Destroy
on:
  workflow_dispatch:
    inputs:
      expected_repository:
        required: true
      mode:
        type: choice
        options:
          - preview
          - destroy
      confirm_destroy:
        required: false
permissions:
  contents: read
env:
  HUB_RESOURCE_GROUP_NAME: rg-cwc-ai-gw-hub-eus2-001
  SPOKE_RESOURCE_GROUP_NAME: rg-cwc-ai-gw-spoke-eus2-001
  RUNNER_VNET_RESOURCE_GROUP_NAME: rg-dv-gh-actions-neu
  RUNNER_VNET_NAME: vnet-dv-gh-actions-neu
  HUB_RUNNER_PEERING_NAME: peer-to-cwc-ai-gw-hub
  SPOKE_RUNNER_PEERING_NAME: peer-to-cwc-ai-gw-spoke
  CONFIRM_DESTROY_PHRASE: destroy rg-cwc-ai-gw-hub-eus2-001 rg-cwc-ai-gw-spoke-eus2-001
jobs:
  preview:
    if: >-
      github.event_name == 'workflow_dispatch' &&
      github.repository == 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab' &&
      inputs.expected_repository == 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab' &&
      github.actor == 'haripraghash' &&
      github.ref == 'refs/heads/main' &&
      inputs.mode == 'preview'
    runs-on:
      group: consultwithcloud-azure
      labels: [gh-linux]
    steps:
      - run: |
          echo preview
          echo rg-cwc-ai-gw-hub-eus2-001
          echo rg-cwc-ai-gw-spoke-eus2-001
  destroy:
    if: >-
      github.event_name == 'workflow_dispatch' &&
      github.repository == 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab' &&
      inputs.expected_repository == 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab' &&
      github.actor == 'haripraghash' &&
      github.ref == 'refs/heads/main' &&
      inputs.mode == 'destroy'
    runs-on:
      group: consultwithcloud-azure
      labels: [gh-linux]
    environment: dev
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@$checkout_sha
      - uses: azure/login@$azure_login_sha
      - run: |
          if [[ "\${{ inputs.confirm_destroy }}" != "\$CONFIRM_DESTROY_PHRASE" ]]; then
            echo "confirm_destroy must exactly match"
            exit 1
          fi
          az network vnet peering show --resource-group "\$RUNNER_VNET_RESOURCE_GROUP_NAME" --vnet-name "\$RUNNER_VNET_NAME" --name "\$HUB_RUNNER_PEERING_NAME"
          az network vnet peering delete --resource-group "\$RUNNER_VNET_RESOURCE_GROUP_NAME" --vnet-name "\$RUNNER_VNET_NAME" --name "\$HUB_RUNNER_PEERING_NAME"
          az network vnet peering delete --resource-group "\$RUNNER_VNET_RESOURCE_GROUP_NAME" --vnet-name "\$RUNNER_VNET_NAME" --name "\$SPOKE_RUNNER_PEERING_NAME"
          az group exists --name "\$SPOKE_RESOURCE_GROUP_NAME"
          az group delete --name "\$SPOKE_RESOURCE_GROUP_NAME" --yes
          az group delete --name "\$HUB_RESOURCE_GROUP_NAME" --yes
EOF
  "$validator" --root "$dir" >/tmp/workflow-guardrails-destroy-success.out
}

expect_failure_for_destroy_target_inputs() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  cat >"$dir/.github/workflows/infra-destroy.yml" <<EOF
name: Infra Destroy
on:
  workflow_dispatch:
    inputs:
      expected_repository:
        required: true
      mode:
        type: choice
        options: [preview, destroy]
      confirm_destroy:
        required: false
      hub_resource_group_name:
        required: true
permissions:
  contents: read
env:
  SPOKE_RESOURCE_GROUP_NAME: rg-cwc-ai-gw-spoke-eus2-001
  RUNNER_VNET_RESOURCE_GROUP_NAME: rg-dv-gh-actions-neu
  RUNNER_VNET_NAME: vnet-dv-gh-actions-neu
  HUB_RUNNER_PEERING_NAME: peer-to-cwc-ai-gw-hub
  SPOKE_RUNNER_PEERING_NAME: peer-to-cwc-ai-gw-spoke
  CONFIRM_DESTROY_PHRASE: destroy rg-cwc-ai-gw-hub-eus2-001 rg-cwc-ai-gw-spoke-eus2-001
jobs:
  destroy:
    if: >-
      github.event_name == 'workflow_dispatch' &&
      github.repository == 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab' &&
      github.actor == 'haripraghash' &&
      github.ref == 'refs/heads/main'
    runs-on:
      group: consultwithcloud-azure
      labels: [gh-linux]
    environment: dev
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@$checkout_sha
      - uses: azure/login@$azure_login_sha
      - run: |
          if [[ "\${{ inputs.confirm_destroy }}" != "\$CONFIRM_DESTROY_PHRASE" ]]; then
            echo "confirm_destroy must exactly match"
            exit 1
          fi
          echo preview
          az network vnet peering show --resource-group "\$RUNNER_VNET_RESOURCE_GROUP_NAME" --vnet-name "\$RUNNER_VNET_NAME" --name "\$HUB_RUNNER_PEERING_NAME"
          az network vnet peering delete --resource-group "\$RUNNER_VNET_RESOURCE_GROUP_NAME" --vnet-name "\$RUNNER_VNET_NAME" --name "\$HUB_RUNNER_PEERING_NAME"
          az group delete --name "\${{ inputs.hub_resource_group_name }}" --yes
EOF
  if "$validator" --root "$dir" >/tmp/workflow-guardrails-destroy-target-input.out 2>&1; then
    echo "expected caller-controlled destroy target input to fail" >&2
    return 1
  fi
  grep -q "must not accept caller-controlled destroy target input" \
    /tmp/workflow-guardrails-destroy-target-input.out
}

expect_failure_for_destroy_missing_confirmation_check() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  cat >"$dir/.github/workflows/infra-destroy.yml" <<EOF
name: Infra Destroy
on:
  workflow_dispatch:
    inputs:
      expected_repository:
        required: true
      mode:
        type: choice
        options: [preview, destroy]
permissions:
  contents: read
env:
  HUB_RESOURCE_GROUP_NAME: rg-cwc-ai-gw-hub-eus2-001
  SPOKE_RESOURCE_GROUP_NAME: rg-cwc-ai-gw-spoke-eus2-001
  RUNNER_VNET_RESOURCE_GROUP_NAME: rg-dv-gh-actions-neu
  RUNNER_VNET_NAME: vnet-dv-gh-actions-neu
  HUB_RUNNER_PEERING_NAME: peer-to-cwc-ai-gw-hub
  SPOKE_RUNNER_PEERING_NAME: peer-to-cwc-ai-gw-spoke
jobs:
  destroy:
    if: >-
      github.event_name == 'workflow_dispatch' &&
      github.repository == 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab' &&
      github.actor == 'haripraghash' &&
      github.ref == 'refs/heads/main'
    runs-on:
      group: consultwithcloud-azure
      labels: [gh-linux]
    environment: dev
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@$checkout_sha
      - uses: azure/login@$azure_login_sha
      - run: |
          echo preview
          az network vnet peering show --resource-group "\$RUNNER_VNET_RESOURCE_GROUP_NAME" --vnet-name "\$RUNNER_VNET_NAME" --name "\$HUB_RUNNER_PEERING_NAME"
          az network vnet peering delete --resource-group "\$RUNNER_VNET_RESOURCE_GROUP_NAME" --vnet-name "\$RUNNER_VNET_NAME" --name "\$HUB_RUNNER_PEERING_NAME"
          az group delete --name "\$SPOKE_RESOURCE_GROUP_NAME" --yes
          az group delete --name "\$HUB_RESOURCE_GROUP_NAME" --yes
EOF
  if "$validator" --root "$dir" >/tmp/workflow-guardrails-destroy-confirm.out 2>&1; then
    echo "expected destroy workflow without confirmation check to fail" >&2
    return 1
  fi
  grep -q "is missing required destroy content: confirm_destroy:" \
    /tmp/workflow-guardrails-destroy-confirm.out
}

expect_failure_for_destroy_command_outside_guarded_workflow() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  cat >"$dir/.github/workflows/manual-cleanup.yml" <<'EOF'
name: Manual Cleanup
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
  cleanup:
    if: >-
      github.event_name == 'workflow_dispatch' &&
      github.repository == inputs.expected_repository &&
      github.actor == inputs.expected_actor &&
      github.ref == 'refs/heads/main'
    runs-on:
      group: consultwithcloud-azure
      labels: [gh-linux]
    steps:
      - run: az group delete --name rg-cwc-ai-gw-hub-eus2-001 --yes
EOF
  if "$validator" --root "$dir" >/tmp/workflow-guardrails-destroy-outside.out 2>&1; then
    echo "expected destructive command outside guarded deployment workflow to fail" >&2
    return 1
  fi
  grep -q "must not contain destructive Azure delete commands outside guarded deployment workflows" \
    /tmp/workflow-guardrails-destroy-outside.out
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
    runs-on:
      group: consultwithcloud-azure
      labels: [gh-linux]
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
    runs-on:
      group: consultwithcloud-azure
      labels: [gh-linux]
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
    runs-on:
      group: consultwithcloud-azure
      labels: [gh-linux]
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
    runs-on:
      group: consultwithcloud-azure
      labels: [gh-linux]
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
    runs-on:
      group: consultwithcloud-azure
      labels: [gh-linux]
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

expect_failure_for_manual_runner_ip_input() {
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
      runner_allowed_public_ip:
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
    runs-on:
      group: consultwithcloud-azure
      labels: [gh-linux]
    environment: dev
    permissions:
      contents: read
      id-token: write
    env:
      RUNNER_ALLOWED_PUBLIC_IP: \${{ vars.RUNNER_ALLOWED_PUBLIC_IP_CIDR }}
    steps:
      - uses: actions/checkout@$checkout_sha
      - uses: azure/login@$azure_login_sha
      - run: |
          echo "RUNNER_ALLOWED_PUBLIC_IP_CIDR must be an IPv4 CIDR value, for example 203.0.113.10/32."
          az deployment sub create --parameters runnerAllowedPublicIp="\$RUNNER_ALLOWED_PUBLIC_IP"
EOF
  if "$validator" --root "$dir" >/tmp/workflow-guardrails-runner-input.out 2>&1; then
    echo "expected manual runner_allowed_public_ip input to fail" >&2
    return 1
  fi
  grep -q "must not require runner_allowed_public_ip as a manual workflow input" \
    /tmp/workflow-guardrails-runner-input.out
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
    runs-on:
      group: consultwithcloud-azure
      labels: [gh-linux]
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
    runs-on:
      group: consultwithcloud-azure
      labels: [gh-linux]
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
    runs-on:
      group: consultwithcloud-azure
      labels: [gh-linux]
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
    runs-on:
      group: consultwithcloud-azure
      labels: [gh-linux]
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
  grep -q "must use the consultwithcloud-azure runner group with the gh-linux label" \
    /tmp/workflow-guardrails-runner.out
}

expect_failure_for_mixed_runner_jobs() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  cat >"$dir/.github/workflows/mixed-runners.yml" <<'EOF'
name: Mixed Runners

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
  good:
    if: >-
      github.event_name == 'workflow_dispatch' &&
      github.repository == inputs.expected_repository &&
      github.actor == inputs.expected_actor &&
      github.ref == 'refs/heads/main'
    runs-on:
      group: consultwithcloud-azure
      labels: [gh-linux]
    steps:
      - run: echo good
  bad:
    if: >-
      github.event_name == 'workflow_dispatch' &&
      github.repository == inputs.expected_repository &&
      github.actor == inputs.expected_actor &&
      github.ref == 'refs/heads/main'
    runs-on: [self-hosted, linux]
    steps:
      - run: echo bad
EOF
  if "$validator" --root "$dir" >/tmp/workflow-guardrails-mixed-runner.out 2>&1; then
    echo "expected mixed runner jobs to fail" >&2
    return 1
  fi
  grep -q "must use the consultwithcloud-azure runner group with the gh-linux label for every job: bad" \
    /tmp/workflow-guardrails-mixed-runner.out
}

expect_failure_for_runner_group_keys_outside_runs_on() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  cat >"$dir/.github/workflows/runner-bypass.yml" <<'EOF'
name: Runner Bypass

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
  bypass:
    if: >-
      github.event_name == 'workflow_dispatch' &&
      github.repository == inputs.expected_repository &&
      github.actor == inputs.expected_actor &&
      github.ref == 'refs/heads/main'
    runs-on: [self-hosted, linux]
    outputs:
      group: consultwithcloud-azure
      labels: [gh-linux]
    steps:
      - run: echo bypass
EOF
  if "$validator" --root "$dir" >/tmp/workflow-guardrails-runner-bypass.out 2>&1; then
    echo "expected runner group keys outside runs-on to fail" >&2
    return 1
  fi
  grep -q "must use the consultwithcloud-azure runner group with the gh-linux label for every job: bypass" \
    /tmp/workflow-guardrails-runner-bypass.out
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
    runs-on:
      group: consultwithcloud-azure
      labels: [gh-linux]
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
expect_success_for_guarded_destroy_workflow
expect_failure_for_destroy_target_inputs
expect_failure_for_destroy_missing_confirmation_check
expect_failure_for_destroy_command_outside_guarded_workflow
expect_failure_for_deployment_missing_oidc
expect_failure_for_deployment_top_level_oidc
expect_failure_for_deployment_missing_environment
expect_failure_for_input_environment
expect_failure_for_caller_controlled_repository_guard
expect_failure_for_manual_runner_ip_input
expect_failure_for_unpinned_actions
expect_failure_for_deployment_command_in_unapproved_job
expect_failure_for_provider_register_in_what_if
expect_failure_for_deployment_missing_hardcoded_actor_guard
expect_failure_for_pr_trigger
expect_failure_for_missing_job_guard
expect_failure_for_github_hosted_runner
expect_failure_for_mixed_runner_jobs
expect_failure_for_runner_group_keys_outside_runs_on
expect_failure_for_runner_mutation

echo "validate-workflow-guardrails tests passed"
