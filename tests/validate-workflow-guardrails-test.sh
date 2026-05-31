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
  bash "$validator" --root "$dir" >/tmp/workflow-guardrails-success.out
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
      deployment_location:
        default: swedencentral
      deployment_name:
        default: apim-ai-gateway-lab-swc
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
      DEPLOYMENT_LOCATION: swedencentral
      DEPLOYMENT_NAME: apim-ai-gateway-lab-swc
      SHARED_KEY_VAULT_NAME: kv-cwc-aigw-shr-swc-001
      LAB_CERTIFICATE_NAME: cert-lab-consultwithcloud-com
      RUNNER_ALLOWED_PUBLIC_IP: \${{ vars.RUNNER_ALLOWED_PUBLIC_IP_CIDR }}
    steps:
      - uses: actions/checkout@$checkout_sha
      - uses: azure/login@$azure_login_sha
      - run: |
          if [[ "\$DEPLOYMENT_LOCATION" == "swedencentral" && "\$DEPLOYMENT_NAME" != *-swc ]]; then
            echo "deployment_name must end with -swc when deployment_location is swedencentral." >&2
            exit 1
          fi
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
          echo "Infer custom domain certificate secret URI"
          az keyvault certificate show --vault-name "\$SHARED_KEY_VAULT_NAME" --name "\$LAB_CERTIFICATE_NAME" --query sid -o tsv
          echo "enable_public_edge=true requires certificate cert-lab-consultwithcloud-com in Key Vault kv-cwc-aigw-shr-swc-001"
          echo "CUSTOM_DOMAIN_CERTIFICATE_SECRET_URI=example" >> "\$GITHUB_ENV"
          az deployment sub what-if --name "\$DEPLOYMENT_NAME" --location "\$DEPLOYMENT_LOCATION" --template-file infra/bicep/main.bicep --parameters runnerAllowedPublicIp="\$RUNNER_ALLOWED_PUBLIC_IP" enablePublicEdge=false enableCustomDomain=false customDomainCertificateSecretUri="\$CUSTOM_DOMAIN_CERTIFICATE_SECRET_URI"
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
      DEPLOYMENT_LOCATION: swedencentral
      DEPLOYMENT_NAME: apim-ai-gateway-lab-swc
      SHARED_KEY_VAULT_NAME: kv-cwc-aigw-shr-swc-001
      LAB_CERTIFICATE_NAME: cert-lab-consultwithcloud-com
      RUNNER_ALLOWED_PUBLIC_IP: \${{ vars.RUNNER_ALLOWED_PUBLIC_IP_CIDR }}
    steps:
      - uses: actions/checkout@$checkout_sha
      - uses: azure/login@$azure_login_sha
      - run: |
          if [[ "\$DEPLOYMENT_LOCATION" == "swedencentral" && "\$DEPLOYMENT_NAME" != *-swc ]]; then
            echo "deployment_name must end with -swc when deployment_location is swedencentral." >&2
            exit 1
          fi
          if [[ ! "\$RUNNER_ALLOWED_PUBLIC_IP" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}$ ]]; then
            echo "RUNNER_ALLOWED_PUBLIC_IP_CIDR must be an IPv4 CIDR value, for example 203.0.113.10/32." >&2
            exit 1
          fi
          az provider register --namespace Microsoft.Network
          echo "Infer custom domain certificate secret URI"
          az keyvault certificate show --vault-name "\$SHARED_KEY_VAULT_NAME" --name "\$LAB_CERTIFICATE_NAME" --query sid -o tsv
          echo "enable_public_edge=true requires certificate cert-lab-consultwithcloud-com in Key Vault kv-cwc-aigw-shr-swc-001"
          echo "CUSTOM_DOMAIN_CERTIFICATE_SECRET_URI=example" >> "\$GITHUB_ENV"
          az deployment sub create --name "\$DEPLOYMENT_NAME" --location "\$DEPLOYMENT_LOCATION" --template-file infra/bicep/main.bicep --parameters runnerAllowedPublicIp="\$RUNNER_ALLOWED_PUBLIC_IP" enablePublicEdge=false enableCustomDomain=false customDomainCertificateSecretUri="\$CUSTOM_DOMAIN_CERTIFICATE_SECRET_URI"
EOF
  cat >"$dir/.github/workflows/certificate-issue.yml" <<EOF
name: Certificate Issue
on:
  workflow_dispatch:
    inputs:
      expected_repository:
        required: true
      dns_zone_name:
        default: lab.consultwithcloud.com
      acme_server:
        type: choice
        default: staging
        options:
          - staging
          - production
permissions:
  contents: read
env:
  CERTIFICATE_DOMAINS: api.lab.consultwithcloud.com app.lab.consultwithcloud.com argo.lab.consultwithcloud.com
  KEY_VAULT_CERTIFICATE_NAME: cert-lab-consultwithcloud-com
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
          echo "api.lab.consultwithcloud.com"
          echo "app.lab.consultwithcloud.com"
          echo "argo.lab.consultwithcloud.com"
          echo "rg-cwc-ai-gw-shared-swc-001"
          echo "kv-cwc-aigw-shr-swc-001"
          echo "_acme-challenge.api"
          echo "_acme-challenge.app"
          echo "_acme-challenge.argo"
          echo "--test-cert"
          echo "Install certbot if missing"
          sudo apt-get install -y certbot
          echo "::add-mask::secret"
          az network dns record-set txt add-record --zone-name lab.consultwithcloud.com --record-set-name _acme-challenge.api
          az network dns record-set txt show --zone-name lab.consultwithcloud.com --name _acme-challenge.api --query txtRecords
          az network dns record-set txt remove-record --zone-name lab.consultwithcloud.com --record-set-name _acme-challenge.api
          openssl pkcs12 -export -out "\$KEY_VAULT_CERTIFICATE_NAME.pfx"
          az keyvault certificate import --name "\$KEY_VAULT_CERTIFICATE_NAME"
EOF
  bash "$validator" --root "$dir" >/tmp/workflow-guardrails-deploy-success.out
}

expect_failure_for_certificate_name_input() {
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
      certificate_name:
        required: true
      acme_server:
        type: choice
        default: staging
        options:
          - staging
          - production
permissions:
  contents: read
env:
  CERTIFICATE_DOMAINS: api.lab.consultwithcloud.com app.lab.consultwithcloud.com argo.lab.consultwithcloud.com
  KEY_VAULT_CERTIFICATE_NAME: cert-lab-consultwithcloud-com
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
          echo "rg-cwc-ai-gw-shared-swc-001"
          echo "kv-cwc-aigw-shr-swc-001"
          echo "lab.consultwithcloud.com"
          echo "api.lab.consultwithcloud.com"
          echo "app.lab.consultwithcloud.com"
          echo "argo.lab.consultwithcloud.com"
          echo "_acme-challenge.api"
          echo "_acme-challenge.app"
          echo "_acme-challenge.argo"
          echo "--test-cert"
          echo "Install certbot if missing"
          sudo apt-get install -y certbot
          echo "::add-mask::secret"
          az network dns record-set txt add-record --zone-name lab.consultwithcloud.com --record-set-name _acme-challenge.api
          az network dns record-set txt show --zone-name lab.consultwithcloud.com --name _acme-challenge.api --query txtRecords
          az network dns record-set txt remove-record --zone-name lab.consultwithcloud.com --record-set-name _acme-challenge.api
          openssl pkcs12 -export -out "\$KEY_VAULT_CERTIFICATE_NAME.pfx"
          az keyvault certificate import --name "\$KEY_VAULT_CERTIFICATE_NAME"
EOF
  if bash "$validator" --root "$dir" >/tmp/workflow-guardrails-certificate-name-input.out 2>&1; then
    echo "expected certificate_name dispatch input to fail" >&2
    return 1
  fi
  grep -q "must use the fixed lab SAN certificate object name instead of a dispatch certificate_name input" \
    /tmp/workflow-guardrails-certificate-name-input.out
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
  HUB_RESOURCE_GROUP_NAME: rg-cwc-ai-gw-hub-swc-001
  SPOKE_RESOURCE_GROUP_NAME: rg-cwc-ai-gw-spoke-swc-001
  RUNNER_VNET_RESOURCE_GROUP_NAME: rg-dv-gh-actions-neu
  RUNNER_VNET_NAME: vnet-dv-gh-actions-neu
  HUB_RUNNER_PEERING_NAME: peer-to-cwc-ai-gw-hub
  SPOKE_RUNNER_PEERING_NAME: peer-to-cwc-ai-gw-spoke
  PERSISTENT_RESOURCE_GROUP_NAME: rg-cwc-ai-gw-shared-swc-001
  PERSISTENT_KEY_VAULT_NAME: kv-cwc-aigw-shr-swc-001
  LAB_PUBLIC_DNS_ZONE_NAME: lab.consultwithcloud.com
  APIM_SERVICE_NAME: apim-cwc-ai-gw-swc-001
  APIM_LOCATION: swedencentral
  CONFIRM_DESTROY_PHRASE: destroy
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
          echo rg-cwc-ai-gw-hub-swc-001
          echo rg-cwc-ai-gw-spoke-swc-001
          echo rg-cwc-ai-gw-shared-swc-001
          echo kv-cwc-aigw-shr-swc-001
          echo lab.consultwithcloud.com
          echo Cloudflare delegation
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
          echo rg-cwc-ai-gw-shared-swc-001
          echo kv-cwc-aigw-shr-swc-001
          echo lab.consultwithcloud.com
          echo Cloudflare delegation
          az apim deletedservice show --service-name "\$APIM_SERVICE_NAME" --location "\$APIM_LOCATION"
          az apim deletedservice purge --service-name "\$APIM_SERVICE_NAME" --location "\$APIM_LOCATION"
EOF
  bash "$validator" --root "$dir" >/tmp/workflow-guardrails-destroy-success.out
}

expect_failure_for_destroy_deletes_persistent_resource_group() {
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
permissions:
  contents: read
env:
  HUB_RESOURCE_GROUP_NAME: rg-cwc-ai-gw-hub-swc-001
  SPOKE_RESOURCE_GROUP_NAME: rg-cwc-ai-gw-spoke-swc-001
  RUNNER_VNET_RESOURCE_GROUP_NAME: rg-dv-gh-actions-neu
  RUNNER_VNET_NAME: vnet-dv-gh-actions-neu
  HUB_RUNNER_PEERING_NAME: peer-to-cwc-ai-gw-hub
  SPOKE_RUNNER_PEERING_NAME: peer-to-cwc-ai-gw-spoke
  PERSISTENT_RESOURCE_GROUP_NAME: rg-cwc-ai-gw-shared-swc-001
  PERSISTENT_KEY_VAULT_NAME: kv-cwc-aigw-shr-swc-001
  LAB_PUBLIC_DNS_ZONE_NAME: lab.consultwithcloud.com
  APIM_SERVICE_NAME: apim-cwc-ai-gw-swc-001
  APIM_LOCATION: swedencentral
  CONFIRM_DESTROY_PHRASE: destroy
jobs:
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
          echo rg-cwc-ai-gw-hub-swc-001
          echo rg-cwc-ai-gw-spoke-swc-001
          echo rg-cwc-ai-gw-shared-swc-001
          echo kv-cwc-aigw-shr-swc-001
          echo lab.consultwithcloud.com
          echo Cloudflare delegation
          az network vnet peering show --resource-group "\$RUNNER_VNET_RESOURCE_GROUP_NAME" --vnet-name "\$RUNNER_VNET_NAME" --name "\$HUB_RUNNER_PEERING_NAME"
          az network vnet peering delete --resource-group "\$RUNNER_VNET_RESOURCE_GROUP_NAME" --vnet-name "\$RUNNER_VNET_NAME" --name "\$HUB_RUNNER_PEERING_NAME"
          az network vnet peering delete --resource-group "\$RUNNER_VNET_RESOURCE_GROUP_NAME" --vnet-name "\$RUNNER_VNET_NAME" --name "\$SPOKE_RUNNER_PEERING_NAME"
          az group delete --name "\$SPOKE_RESOURCE_GROUP_NAME" --yes
          az group delete --name "\$HUB_RESOURCE_GROUP_NAME" --yes
          az group delete --name "\$PERSISTENT_RESOURCE_GROUP_NAME" --yes
          az apim deletedservice show --service-name "\$APIM_SERVICE_NAME" --location "\$APIM_LOCATION"
          az apim deletedservice purge --service-name "\$APIM_SERVICE_NAME" --location "\$APIM_LOCATION"
EOF
  if bash "$validator" --root "$dir" >/tmp/workflow-guardrails-destroy-shared-rg.out 2>&1; then
    echo "expected destroy workflow deleting persistent resource group to fail" >&2
    return 1
  fi
  grep -q "must not delete persistent resource group rg-cwc-ai-gw-shared-swc-001" \
    /tmp/workflow-guardrails-destroy-shared-rg.out
}

expect_failure_for_persistent_bootstrap_destroy_mode() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  cat >"$dir/.github/workflows/bootstrap-persistent.yml" <<EOF
name: Bootstrap Persistent
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
          - destroy
      confirm_destroy:
        required: false
      key_vault_virtual_network_rule_subnet_ids:
        required: false
permissions:
  contents: read
env:
  DEPLOYMENT_NAME: apim-ai-gateway-persistent-swc
  KEY_VAULT_VNET_RULE_SUBNET_IDS: \${{ inputs.key_vault_virtual_network_rule_subnet_ids }}
jobs:
  apply:
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
          echo "infra/bicep/persistent.bicep"
          echo "keyVaultVirtualNetworkRuleSubnetIds"
          echo "Microsoft.KeyVault"
          echo "Microsoft.Network"
          az deployment sub what-if --name "\$DEPLOYMENT_NAME" --template-file infra/bicep/persistent.bicep
          az deployment sub create --name "\$DEPLOYMENT_NAME" --template-file infra/bicep/persistent.bicep
EOF
  if bash "$validator" --root "$dir" >/tmp/workflow-guardrails-bootstrap-destroy-mode.out 2>&1; then
    echo "expected bootstrap destroy mode to fail" >&2
    return 1
  fi
  grep -q "must be create/update only and must not include destroy mode" \
    /tmp/workflow-guardrails-bootstrap-destroy-mode.out
}

expect_failure_for_persistent_bootstrap_subnet_input() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  cat >"$dir/.github/workflows/bootstrap-persistent.yml" <<EOF
name: Bootstrap Persistent
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
      key_vault_virtual_network_rule_subnet_ids:
        required: true
permissions:
  contents: read
env:
  DEPLOYMENT_NAME: apim-ai-gateway-persistent-swc
  KEY_VAULT_VNET_RULE_SUBNET_IDS: \${{ inputs.key_vault_virtual_network_rule_subnet_ids }}
jobs:
  apply:
    if: >-
      github.event_name == 'workflow_dispatch' &&
      github.repository == 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab' &&
      inputs.expected_repository == 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab' &&
      github.actor == 'haripraghash' &&
      github.ref == 'refs/heads/main' &&
      inputs.mode == 'apply'
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
          echo "infra/bicep/persistent.bicep"
          echo "HUB_RESOURCE_GROUP_NAME: rg-cwc-ai-gw-hub-swc-001"
          echo "HUB_VNET_NAME: vnet-cwc-ai-gw-hub-swc-001"
          echo "APPGW_SUBNET_NAME: snet-appgw"
          echo "APIM_SUBNET_NAME: snet-apim"
          echo "Infer Key Vault VNet rules"
          echo "Both hub Key Vault client subnets must exist, or neither should exist."
          echo "Microsoft.KeyVault"
          echo "Microsoft.Network"
          az network vnet subnet show --name snet-appgw
          az deployment sub what-if --name "\$DEPLOYMENT_NAME" --template-file infra/bicep/persistent.bicep
          az deployment sub create --name "\$DEPLOYMENT_NAME" --template-file infra/bicep/persistent.bicep --parameters keyVaultVirtualNetworkRuleSubnetIds="\$KEY_VAULT_VNET_RULE_SUBNET_IDS"
EOF
  if bash "$validator" --root "$dir" >/tmp/workflow-guardrails-bootstrap-subnet-input.out 2>&1; then
    echo "expected bootstrap subnet ID input to fail" >&2
    return 1
  fi
  grep -q "must infer Key Vault subnet rules instead of accepting subnet IDs as dispatch input" \
    /tmp/workflow-guardrails-bootstrap-subnet-input.out
}

write_planned_spoke_workflow() {
  local file="$1"
  local command="$2"

  cat >"$file" <<EOF
name: Planned Spoke Workflow
on:
  workflow_dispatch:
    inputs:
      expected_repository:
        required: true
permissions:
  contents: read
jobs:
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
    steps:
      - uses: actions/checkout@$checkout_sha
      - uses: azure/login@$azure_login_sha
      - run: |
          $command
EOF
}

expect_success_for_planned_spoke_workflow_taxonomy() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"

  write_planned_spoke_workflow "$dir/.github/workflows/aks-power.yml" \
    "az aks start --resource-group rg-cwc-ai-gw-spoke-swc-001 --name aks-cwc-ai-gw-swc-001"
  write_planned_spoke_workflow "$dir/.github/workflows/gitops-bootstrap.yml" \
    "az k8s-extension create --name argocd --cluster-name aks-cwc-ai-gw-swc-001"
  write_planned_spoke_workflow "$dir/.github/workflows/apiops-publish.yml" \
    "az apim api import --resource-group rg-cwc-ai-gw-hub-swc-001 --service-name apim-cwc-ai-gw-swc-001"
  write_planned_spoke_workflow "$dir/.github/workflows/acr-image-build.yml" \
    "az acr build --registry acrcwcaigwswc001 --image bff:sha ."
  write_planned_spoke_workflow "$dir/.github/workflows/image-promotion.yml" \
    "az acr repository show-tags --name acrcwcaigwswc001 --repository bff"
  write_planned_spoke_workflow "$dir/.github/workflows/lab-certificate-issue.yml" \
    "az keyvault certificate import --vault-name kv-cwc-aigw-shr-swc-001 --name cert-lab-consultwithcloud-com"

  bash "$validator" --root "$dir" >/tmp/workflow-guardrails-planned-spoke-success.out
}

expect_failure_for_planned_workflow_caller_controlled_target() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  cat >"$dir/.github/workflows/aks-power.yml" <<EOF
name: AKS Power
on:
  workflow_dispatch:
    inputs:
      expected_repository:
        required: true
      aks_cluster_name:
        required: true
permissions:
  contents: read
jobs:
  stop:
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
      - run: az aks stop --resource-group rg-cwc-ai-gw-spoke-swc-001 --name "\${{ inputs.aks_cluster_name }}"
EOF
  if bash "$validator" --root "$dir" >/tmp/workflow-guardrails-planned-target-input.out 2>&1; then
    echo "expected caller-controlled planned workflow target to fail" >&2
    return 1
  fi
  grep -q "must not accept caller-controlled Azure target input" \
    /tmp/workflow-guardrails-planned-target-input.out
}

expect_failure_for_azure_changing_push_trigger() {
  local dir
  dir="$(mktemp -d)"
  make_fixture "$dir"
  cat >"$dir/.github/workflows/acr-image-build.yml" <<EOF
name: ACR Image Build
on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      expected_repository:
        required: true
permissions:
  contents: read
jobs:
  build:
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
      - run: az acr build --registry acrcwcaigwswc001 --image bff:sha .
EOF
  if bash "$validator" --root "$dir" >/tmp/workflow-guardrails-push-trigger.out 2>&1; then
    echo "expected Azure-changing push trigger to fail" >&2
    return 1
  fi
  grep -q "must not contain push triggers" \
    /tmp/workflow-guardrails-push-trigger.out
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
  SPOKE_RESOURCE_GROUP_NAME: rg-cwc-ai-gw-spoke-swc-001
  RUNNER_VNET_RESOURCE_GROUP_NAME: rg-dv-gh-actions-neu
  RUNNER_VNET_NAME: vnet-dv-gh-actions-neu
  HUB_RUNNER_PEERING_NAME: peer-to-cwc-ai-gw-hub
  SPOKE_RUNNER_PEERING_NAME: peer-to-cwc-ai-gw-spoke
  CONFIRM_DESTROY_PHRASE: destroy rg-cwc-ai-gw-hub-swc-001 rg-cwc-ai-gw-spoke-swc-001
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
  if bash "$validator" --root "$dir" >/tmp/workflow-guardrails-destroy-target-input.out 2>&1; then
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
  HUB_RESOURCE_GROUP_NAME: rg-cwc-ai-gw-hub-swc-001
  SPOKE_RESOURCE_GROUP_NAME: rg-cwc-ai-gw-spoke-swc-001
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
  if bash "$validator" --root "$dir" >/tmp/workflow-guardrails-destroy-confirm.out 2>&1; then
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
      - run: az group delete --name rg-cwc-ai-gw-hub-swc-001 --yes
EOF
  if bash "$validator" --root "$dir" >/tmp/workflow-guardrails-destroy-outside.out 2>&1; then
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
  if bash "$validator" --root "$dir" >/tmp/workflow-guardrails-oidc.out 2>&1; then
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
  if bash "$validator" --root "$dir" >/tmp/workflow-guardrails-top-oidc.out 2>&1; then
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
  if bash "$validator" --root "$dir" >/tmp/workflow-guardrails-environment.out 2>&1; then
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
  if bash "$validator" --root "$dir" >/tmp/workflow-guardrails-input-environment.out 2>&1; then
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
  if bash "$validator" --root "$dir" >/tmp/workflow-guardrails-repo.out 2>&1; then
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
  if bash "$validator" --root "$dir" >/tmp/workflow-guardrails-runner-input.out 2>&1; then
    echo "expected manual runner_allowed_public_ip input to fail" >&2
    return 1
  fi
  grep -q "must not require runner_allowed_public_ip as a manual workflow input" \
    /tmp/workflow-guardrails-runner-input.out
}

expect_failure_for_manual_custom_domain_secret_uri_input() {
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
      custom_domain_certificate_secret_uri:
        required: false
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
      CUSTOM_DOMAIN_CERTIFICATE_SECRET_URI: \${{ inputs.custom_domain_certificate_secret_uri }}
    steps:
      - uses: actions/checkout@$checkout_sha
      - uses: azure/login@$azure_login_sha
      - run: |
          echo "RUNNER_ALLOWED_PUBLIC_IP_CIDR must be an IPv4 CIDR value, for example 203.0.113.10/32."
          az deployment sub create --parameters runnerAllowedPublicIp="\$RUNNER_ALLOWED_PUBLIC_IP" customDomainCertificateSecretUri="\$CUSTOM_DOMAIN_CERTIFICATE_SECRET_URI"
EOF
  if bash "$validator" --root "$dir" >/tmp/workflow-guardrails-custom-domain-secret-input.out 2>&1; then
    echo "expected manual custom_domain_certificate_secret_uri input to fail" >&2
    return 1
  fi
  grep -q "must not require custom_domain_certificate_secret_uri as a manual workflow input" \
    /tmp/workflow-guardrails-custom-domain-secret-input.out
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
          echo "KEY_VAULT_CERTIFICATE_NAME: cert-lab-consultwithcloud-com"
          echo "--test-cert"
          echo lab.consultwithcloud.com
          echo api.lab.consultwithcloud.com
          echo app.lab.consultwithcloud.com
          echo argo.lab.consultwithcloud.com
          echo "_acme-challenge.api"
          echo "_acme-challenge.app"
          echo "_acme-challenge.argo"
          echo "--test-cert"
          echo "Install certbot if missing"
          sudo apt-get install -y certbot
          echo "::add-mask::secret"
          az network dns record-set txt add-record --zone-name lab.consultwithcloud.com --record-set-name _acme-challenge.api
          az network dns record-set txt show --zone-name lab.consultwithcloud.com --name _acme-challenge.api --query txtRecords
          az network dns record-set txt remove-record --zone-name lab.consultwithcloud.com --record-set-name _acme-challenge.api
          openssl pkcs12 -export -out "$KEY_VAULT_CERTIFICATE_NAME.pfx"
          az keyvault certificate import --name "$KEY_VAULT_CERTIFICATE_NAME"
EOF
  if bash "$validator" --root "$dir" >/tmp/workflow-guardrails-pinning.out 2>&1; then
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
      - run: az deployment sub create --location swedencentral --template-file infra/bicep/main.bicep
EOF
  if bash "$validator" --root "$dir" >/tmp/workflow-guardrails-command-env.out 2>&1; then
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
  if bash "$validator" --root "$dir" >/tmp/workflow-guardrails-provider-what-if.out 2>&1; then
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
  if bash "$validator" --root "$dir" >/tmp/workflow-guardrails-actor.out 2>&1; then
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
  if bash "$validator" --root "$dir" >/tmp/workflow-guardrails-pr.out 2>&1; then
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
  if bash "$validator" --root "$dir" >/tmp/workflow-guardrails-guard.out 2>&1; then
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
  if bash "$validator" --root "$dir" >/tmp/workflow-guardrails-runner.out 2>&1; then
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
  if bash "$validator" --root "$dir" >/tmp/workflow-guardrails-mixed-runner.out 2>&1; then
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
  if bash "$validator" --root "$dir" >/tmp/workflow-guardrails-runner-bypass.out 2>&1; then
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
  if bash "$validator" --root "$dir" >/tmp/workflow-guardrails-mutate.out 2>&1; then
    echo "expected runner mutation to fail" >&2
    return 1
  fi
  grep -q "must not mutate the managed runner" \
    /tmp/workflow-guardrails-mutate.out
}

expect_failure_for_certificate_unapproved_runner_mutation() {
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
      acme_server:
        type: choice
        default: staging
        options:
          - staging
          - production
permissions:
  contents: read
env:
  CERTIFICATE_DOMAINS: api.lab.consultwithcloud.com app.lab.consultwithcloud.com argo.lab.consultwithcloud.com
  KEY_VAULT_CERTIFICATE_NAME: cert-lab-consultwithcloud-com
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
          echo "rg-cwc-ai-gw-shared-swc-001"
          echo "kv-cwc-aigw-shr-swc-001"
          echo "lab.consultwithcloud.com"
          echo "api.lab.consultwithcloud.com"
          echo "app.lab.consultwithcloud.com"
          echo "argo.lab.consultwithcloud.com"
          echo "_acme-challenge.api"
          echo "_acme-challenge.app"
          echo "_acme-challenge.argo"
          echo "--test-cert"
          echo "Install certbot if missing"
          sudo apt-get install -y certbot
          echo "::add-mask::secret"
          sudo apt-get install -y jq
          az network dns record-set txt add-record --zone-name lab.consultwithcloud.com --record-set-name _acme-challenge.api
          az network dns record-set txt show --zone-name lab.consultwithcloud.com --name _acme-challenge.api --query txtRecords
          az network dns record-set txt remove-record --zone-name lab.consultwithcloud.com --record-set-name _acme-challenge.api
          openssl pkcs12 -export -out "\$KEY_VAULT_CERTIFICATE_NAME.pfx"
          az keyvault certificate import --name "\$KEY_VAULT_CERTIFICATE_NAME"
EOF
  if bash "$validator" --root "$dir" >/tmp/workflow-guardrails-certificate-mutate.out 2>&1; then
    echo "expected unapproved certificate runner mutation to fail" >&2
    return 1
  fi
  grep -q "must not mutate the managed runner" \
    /tmp/workflow-guardrails-certificate-mutate.out
}

expect_success
expect_success_for_guarded_deployment_workflows
expect_failure_for_certificate_name_input
expect_success_for_guarded_destroy_workflow
expect_success_for_planned_spoke_workflow_taxonomy
expect_failure_for_destroy_deletes_persistent_resource_group
expect_failure_for_persistent_bootstrap_destroy_mode
expect_failure_for_persistent_bootstrap_subnet_input
expect_failure_for_planned_workflow_caller_controlled_target
expect_failure_for_azure_changing_push_trigger
expect_failure_for_destroy_target_inputs
expect_failure_for_destroy_missing_confirmation_check
expect_failure_for_destroy_command_outside_guarded_workflow
expect_failure_for_deployment_missing_oidc
expect_failure_for_deployment_top_level_oidc
expect_failure_for_deployment_missing_environment
expect_failure_for_input_environment
expect_failure_for_caller_controlled_repository_guard
expect_failure_for_manual_runner_ip_input
expect_failure_for_manual_custom_domain_secret_uri_input
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
expect_failure_for_certificate_unapproved_runner_mutation

echo "validate-workflow-guardrails tests passed"
