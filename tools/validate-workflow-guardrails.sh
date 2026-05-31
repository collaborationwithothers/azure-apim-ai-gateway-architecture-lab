#!/usr/bin/env bash
set -euo pipefail

root="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      root="${2:?missing value for --root}"
      shift 2
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

root="$(cd "$root" && pwd)"
workflow_dir="$root/.github/workflows"
errors=0

fail() {
  echo "ERROR: $*"
  errors=$((errors + 1))
}

has_literal() {
  local literal="$1"
  local file="$2"
  grep -Fq -- "$literal" "$file"
}

has_destructive_destroy_command() {
  local file="$1"
  grep -Eq 'az (group delete|network vnet peering delete)' "$file"
}

has_azure_changing_command() {
  local file="$1"
  grep -Eq '(az deployment sub (what-if|create)|az provider register|az keyvault certificate import|az network dns record-set txt (add-record|remove-record|create|delete)|az network vnet peering delete|az group delete|az aks (start|stop|update|get-credentials)|az acr (build|login|import|repository)|az apim |az k8s-extension |az k8s-configuration |kubectl (apply|delete|patch|create|rollout|set)|helm (install|upgrade|uninstall)|argocd|apiops)' "$file"
}

is_existing_guarded_workflow() {
  case "$1" in
    .github/workflows/infra-deploy.yml|.github/workflows/infra-destroy.yml|.github/workflows/certificate-issue.yml)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_planned_spoke_workflow_name() {
  case "$1" in
    .github/workflows/aks-power.yml|\
    .github/workflows/aks-start-stop.yml|\
    .github/workflows/gitops-bootstrap.yml|\
    .github/workflows/apiops-publish.yml|\
    .github/workflows/acr-image-build.yml|\
    .github/workflows/image-build.yml|\
    .github/workflows/image-promotion.yml|\
    .github/workflows/lab-certificate-issue.yml|\
    .github/workflows/certificate-lab-san.yml)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_guarded_deployment_workflow() {
  local rel="$1"
  local file="${2:-}"

  if is_existing_guarded_workflow "$rel" || is_planned_spoke_workflow_name "$rel"; then
    return 0
  fi

  if [[ -n "$file" ]] && has_azure_changing_command "$file"; then
    return 0
  fi

  return 1
}

caller_controlled_azure_target_inputs() {
  local file="$1"
  local matches=()

  for target_input in \
    resource_group_name \
    hub_resource_group_name \
    spoke_resource_group_name \
    aks_cluster_name \
    acr_name \
    apim_service_name \
    key_vault_name \
    dns_zone_name \
    certificate_name \
    foundry_account_name \
    model_deployment_name \
    subscription_id \
    tenant_id; do
    if has_literal "${target_input}:" "$file"; then
      matches+=("$target_input")
    fi
  done

  if [[ "${#matches[@]}" -gt 0 ]]; then
    printf '%s\n' "${matches[@]}"
  fi
}

has_top_level_oidc_permission() {
  local file="$1"
  awk '
    /^permissions:[[:space:]]*$/ {
      in_top_permissions = 1
      next
    }

    /^jobs:[[:space:]]*$/ {
      in_top_permissions = 0
    }

    in_top_permissions && /^  id-token:[[:space:]]*write[[:space:]]*$/ {
      found = 1
    }

    END {
      exit found ? 0 : 1
    }
  ' "$file"
}

azure_changing_jobs_without_environment() {
  local file="$1"
  awk '
    function flush_job() {
      if (in_job && has_azure_change && !has_environment) {
        print job_name
      }
    }

    /^jobs:[[:space:]]*$/ {
      in_jobs = 1
      next
    }

    in_jobs && /^[^[:space:]]/ {
      flush_job()
      in_jobs = 0
      in_job = 0
    }

    in_jobs && /^  [A-Za-z0-9_-]+:[[:space:]]*$/ {
      flush_job()
      in_job = 1
      job_name = $1
      sub(/:$/, "", job_name)
      has_environment = 0
      has_azure_change = 0
      next
    }

    in_job && /^    environment:/ {
      has_environment = 1
    }

    in_job && /(az deployment sub (what-if|create)|az provider register|az keyvault certificate import|az network dns record-set txt (add-record|remove-record|create|delete)|az network vnet peering delete|az group delete|az aks (start|stop|update|get-credentials)|az acr (build|login|import|repository)|az apim |az k8s-extension |az k8s-configuration |kubectl (apply|delete|patch|create|rollout|set)|helm (install|upgrade|uninstall)|argocd|apiops)/ {
      has_azure_change = 1
    }

    END {
      flush_job()
    }
  ' "$file"
}

what_if_jobs_with_provider_registration() {
  local file="$1"
  awk '
    function flush_job() {
      if (in_job && job_name == "what-if" && has_provider_register) {
        print job_name
      }
    }

    /^jobs:[[:space:]]*$/ {
      in_jobs = 1
      next
    }

    in_jobs && /^[^[:space:]]/ {
      flush_job()
      in_jobs = 0
      in_job = 0
    }

    in_jobs && /^  [A-Za-z0-9_-]+:[[:space:]]*$/ {
      flush_job()
      in_job = 1
      job_name = $1
      sub(/:$/, "", job_name)
      has_provider_register = 0
      next
    }

    in_job && /az provider register/ {
      has_provider_register = 1
    }

    END {
      flush_job()
    }
  ' "$file"
}

jobs_without_required_runner_group() {
  local file="$1"
  awk '
    function flush_job() {
      if (in_job && !(has_runs_on && has_runner_group && has_runner_label)) {
        print job_name
      }
    }

    /^jobs:[[:space:]]*$/ {
      in_jobs = 1
      next
    }

    in_jobs && /^[^[:space:]]/ {
      flush_job()
      in_jobs = 0
      in_job = 0
    }

    in_jobs && /^  [A-Za-z0-9_-]+:[[:space:]]*$/ {
      flush_job()
      in_job = 1
      job_name = $1
      sub(/:$/, "", job_name)
      has_runs_on = 0
      has_runner_group = 0
      has_runner_label = 0
      in_runs_on = 0
      next
    }

    in_job && /^    runs-on:[[:space:]]*$/ {
      has_runs_on = 1
      in_runs_on = 1
      next
    }

    in_job && in_runs_on && /^    [A-Za-z0-9_-]+:/ {
      in_runs_on = 0
    }

    in_job && in_runs_on && /^      group:[[:space:]]*consultwithcloud-azure[[:space:]]*$/ {
      has_runner_group = 1
    }

    in_job && in_runs_on && /^      labels:[[:space:]]*\[gh-linux\][[:space:]]*$/ {
      has_runner_label = 1
    }

    END {
      flush_job()
    }
  ' "$file"
}

[[ -d "$workflow_dir" ]] || {
  echo "No workflow directory found."
  exit 0
}

while IFS= read -r workflow; do
  rel="${workflow#$root/}"

  if grep -Eq '(^|[[:space:]])pull_request(_target)?[[:space:]]*:' "$workflow" ||
      grep -Eq 'pull_request(_target)?' "$workflow"; then
    fail "$rel must not contain pull_request triggers"
  fi

  if grep -Eq '^[[:space:]]*push[[:space:]]*:' "$workflow" ||
      grep -Eq '^[[:space:]]*on:[[:space:]]*\[.*push' "$workflow"; then
    fail "$rel must not contain push triggers"
  fi

  if ! grep -q "workflow_dispatch:" "$workflow"; then
    fail "$rel must be manually triggerable with workflow_dispatch"
  fi

  if ! grep -q "expected_repository:" "$workflow"; then
    fail "$rel must define expected_repository workflow_dispatch input"
  fi

  for guard in \
    "github.event_name == 'workflow_dispatch'" \
    "github.ref == 'refs/heads/main'"; do
    if ! has_literal "$guard" "$workflow"; then
      fail "$rel is missing required guard: $guard"
    fi
  done

  if is_guarded_deployment_workflow "$rel" "$workflow"; then
    if ! has_literal "github.repository == 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab'" "$workflow"; then
      fail "$rel must guard github.repository against the literal repository name"
    fi

    if has_literal "github.repository == inputs.expected_repository" "$workflow"; then
      fail "$rel must not use caller-controlled inputs.expected_repository as the repository guard"
    fi

    if ! has_literal "github.actor == 'haripraghash'" "$workflow"; then
      fail "$rel must guard github.actor against haripraghash"
    fi
  else
    if ! grep -q "expected_actor:" "$workflow"; then
      fail "$rel must define expected_actor workflow_dispatch input"
    fi

    if ! has_literal "github.actor == inputs.expected_actor" "$workflow"; then
      fail "$rel is missing required guard: github.actor == inputs.expected_actor"
    fi
  fi

  if ! grep -q "contents: read" "$workflow"; then
    fail "$rel must set contents: read permission"
  fi

  if grep -q "ubuntu-latest" "$workflow"; then
    fail "$rel must not use GitHub-hosted runners"
  fi

  invalid_runner_jobs="$(jobs_without_required_runner_group "$workflow")"
  if [[ -n "$invalid_runner_jobs" ]]; then
    fail "$rel must use the consultwithcloud-azure runner group with the gh-linux label for every job: ${invalid_runner_jobs//$'\n'/, }"
  fi

  if grep -Eq 'sudo |apt-get|InstallAzureCLIDeb|curl .*\|.*bash' "$workflow"; then
    fail "$rel must not mutate the managed runner at runtime"
  fi

  if [[ "$rel" != ".github/workflows/infra-destroy.yml" ]] && has_destructive_destroy_command "$workflow"; then
    fail "$rel must not contain destructive Azure delete commands outside guarded deployment workflows"
  fi

  if is_guarded_deployment_workflow "$rel" "$workflow"; then
    if ! grep -q "id-token: write" "$workflow"; then
      fail "$rel must set id-token: write permission"
    fi

    if ! has_literal "inputs.expected_repository == 'collaborationwithothers/azure-apim-ai-gateway-architecture-lab'" "$workflow"; then
      fail "$rel must guard inputs.expected_repository against the literal repository name"
    fi

    if has_top_level_oidc_permission "$workflow"; then
      fail "$rel must scope id-token: write to Azure jobs instead of workflow-level permissions"
    fi

    if ! grep -Eq 'uses: azure/login@[0-9a-f]{40}' "$workflow"; then
      fail "$rel must pin azure/login to a full commit SHA"
    fi

    if ! grep -Eq 'uses: actions/checkout@[0-9a-f]{40}' "$workflow"; then
      fail "$rel must pin actions/checkout to a full commit SHA"
    fi

    if grep -q "client-secret" "$workflow"; then
      fail "$rel must not use an Azure client secret"
    fi

    missing_environment_jobs="$(azure_changing_jobs_without_environment "$workflow")"
    if [[ -n "$missing_environment_jobs" ]]; then
      fail "$rel must require a GitHub Environment for Azure-changing jobs: ${missing_environment_jobs//$'\n'/, }"
    fi

    if grep -Eq 'environment:[[:space:]]*\$\{\{[[:space:]]*inputs\.' "$workflow"; then
      fail "$rel must not use caller-controlled inputs for GitHub Environment selection"
    fi

    if ! has_literal "environment: dev" "$workflow"; then
      fail "$rel must use the fixed dev GitHub Environment for Azure-changing jobs"
    fi

    if ! is_existing_guarded_workflow "$rel"; then
      caller_controlled_targets="$(caller_controlled_azure_target_inputs "$workflow")"
      if [[ -n "$caller_controlled_targets" ]]; then
        fail "$rel must not accept caller-controlled Azure target input: ${caller_controlled_targets//$'\n'/, }"
      fi
    fi
  fi

  if [[ "$rel" == ".github/workflows/infra-deploy.yml" ]]; then
    if has_literal "runner_allowed_public_ip:" "$workflow"; then
      fail "$rel must not require runner_allowed_public_ip as a manual workflow input"
    fi

    if has_literal "custom_domain_certificate_secret_uri:" "$workflow"; then
      fail "$rel must not require custom_domain_certificate_secret_uri as a manual workflow input"
    fi

    if has_literal "CUSTOM_DOMAIN_CERTIFICATE_SECRET_URI" "$workflow"; then
      fail "$rel must not pass custom_domain_certificate_secret_uri from workflow inputs"
    fi

    if has_literal "customDomainCertificateSecretUri" "$workflow"; then
      fail "$rel must not pass customDomainCertificateSecretUri from the deployment workflow"
    fi

    if ! has_literal "vars.RUNNER_ALLOWED_PUBLIC_IP_CIDR" "$workflow"; then
      fail "$rel must read the runner NAT CIDR from vars.RUNNER_ALLOWED_PUBLIC_IP_CIDR"
    fi

    if ! has_literal "RUNNER_ALLOWED_PUBLIC_IP_CIDR must be an IPv4 CIDR value" "$workflow"; then
      fail "$rel must validate the runner NAT CIDR GitHub variable before deployment"
    fi

    provider_register_in_what_if="$(what_if_jobs_with_provider_registration "$workflow")"
    if [[ -n "$provider_register_in_what_if" ]]; then
      fail "$rel must not run az provider register in what-if jobs"
    fi

    for expected in \
      "mode:" \
      "type: choice" \
      "validate" \
      "what-if" \
      "apply" \
      "deployment_name:" \
      "apim-ai-gateway-lab-swc" \
      "DEPLOYMENT_NAME" \
      "deployment_name must end with -swc when deployment_location is swedencentral" \
      "runnerAllowedPublicIp" \
      "enablePublicEdge" \
      "enableCustomDomain" \
      "az bicep restore" \
      "az bicep build" \
      "az provider show" \
      "az deployment sub what-if" \
      "az deployment sub create" \
      "Microsoft.Network" \
      "Microsoft.ApiManagement" \
      "Microsoft.ContainerRegistry" \
      "Microsoft.KeyVault" \
      "Microsoft.Insights" \
      "Microsoft.OperationalInsights" \
      "Microsoft.Web"; do
      if ! has_literal "$expected" "$workflow"; then
        fail "$rel is missing required deployment content: $expected"
      fi
    done
  fi

  if [[ "$rel" == ".github/workflows/infra-destroy.yml" ]]; then
    for forbidden_input in \
      "hub_resource_group_name:" \
      "spoke_resource_group_name:" \
      "runner_vnet_resource_group_name:" \
      "runner_vnet_name:"; do
      if has_literal "$forbidden_input" "$workflow"; then
        fail "$rel must not accept caller-controlled destroy target input: $forbidden_input"
      fi
    done

    for expected in \
      "mode:" \
      "type: choice" \
      "preview" \
      "destroy" \
      "confirm_destroy:" \
      "CONFIRM_DESTROY_PHRASE" \
      "inputs.confirm_destroy" \
      "confirm_destroy must exactly match" \
      "rg-cwc-ai-gw-hub-swc-001" \
      "rg-cwc-ai-gw-spoke-swc-001" \
      "rg-dv-gh-actions-neu" \
      "vnet-dv-gh-actions-neu" \
      "peer-to-cwc-ai-gw-hub" \
      "peer-to-cwc-ai-gw-spoke" \
      "az network vnet peering show" \
      "az network vnet peering delete" \
      "az group delete"; do
      if ! has_literal "$expected" "$workflow"; then
        fail "$rel is missing required destroy content: $expected"
      fi
    done
  fi

  if [[ "$rel" == ".github/workflows/certificate-issue.yml" ]]; then
    for expected in \
      "certificate_name:" \
      "KEY_VAULT_CERTIFICATE_NAME: \${{ inputs.certificate_name }}" \
      "certificate_name must be a confirmed Key Vault certificate object name" \
      "CERTIFICATE_DOMAIN: api.lab.consultwithcloud.com" \
      "lab.consultwithcloud.com" \
      "api.lab.consultwithcloud.com" \
      "_acme-challenge.api" \
      "staging" \
      "production" \
      "--test-cert" \
      "az network dns record-set txt add-record" \
      "az network dns record-set txt remove-record" \
      "az keyvault certificate import" \
      "openssl pkcs12"; do
      if ! has_literal "$expected" "$workflow"; then
        fail "$rel is missing required certificate content: $expected"
      fi
    done

    for forbidden in \
      "api.consultwithcloud.com" \
      "cert-api-consultwithcloud-com"; do
      if has_literal "$forbidden" "$workflow"; then
        fail "$rel must not keep old single-host certificate content: $forbidden"
      fi
    done
  fi
done < <(find "$workflow_dir" -maxdepth 1 -type f \
  \( -name '*.yml' -o -name '*.yaml' \) | sort)

if [[ "$errors" -gt 0 ]]; then
  echo
  echo "$errors workflow guardrail issue(s) found."
  exit 1
fi

echo "Workflow guardrail checks passed."
