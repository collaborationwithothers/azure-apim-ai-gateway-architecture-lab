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

is_guarded_deployment_workflow() {
  case "$1" in
    .github/workflows/infra-deploy.yml|.github/workflows/certificate-issue.yml)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
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

    in_job && /(az deployment sub (what-if|create)|az provider register|az keyvault certificate import|az network dns record-set txt (add-record|remove-record|create|delete))/ {
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

  if is_guarded_deployment_workflow "$rel"; then
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

  if ! grep -q "runs-on: \\[self-hosted, linux, x64, cwc-azure-deploy\\]" \
      "$workflow"; then
    fail "$rel must use the managed Azure VNet runner labels"
  fi

  if grep -Eq 'sudo |apt-get|InstallAzureCLIDeb|curl .*\|.*bash' "$workflow"; then
    fail "$rel must not mutate the managed runner at runtime"
  fi

  if is_guarded_deployment_workflow "$rel"; then
    if ! grep -q "id-token: write" "$workflow"; then
      fail "$rel must set id-token: write permission"
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
  fi

  if [[ "$rel" == ".github/workflows/infra-deploy.yml" ]]; then
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

  if [[ "$rel" == ".github/workflows/certificate-issue.yml" ]]; then
    for expected in \
      "api.consultwithcloud.com" \
      "az network dns record-set txt add-record" \
      "az network dns record-set txt remove-record" \
      "az keyvault certificate import" \
      "openssl pkcs12" \
      "cert-api-consultwithcloud-com"; do
      if ! has_literal "$expected" "$workflow"; then
        fail "$rel is missing required certificate content: $expected"
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
