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

  if ! grep -q "expected_actor:" "$workflow"; then
    fail "$rel must define expected_actor workflow_dispatch input"
  fi

  for guard in \
    "github.event_name == 'workflow_dispatch'" \
    "github.repository == inputs.expected_repository" \
    "github.actor == inputs.expected_actor" \
    "github.ref == 'refs/heads/main'"; do
    if ! grep -q "$guard" "$workflow"; then
      fail "$rel is missing required guard: $guard"
    fi
  done

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
done < <(find "$workflow_dir" -maxdepth 1 -type f \
  \( -name '*.yml' -o -name '*.yaml' \) | sort)

if [[ "$errors" -gt 0 ]]; then
  echo
  echo "$errors workflow guardrail issue(s) found."
  exit 1
fi

echo "Workflow guardrail checks passed."
