#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
apim_module="$repo_root/infra/bicep/modules/hub-apim.bicep"

if grep -q "loggerId: 'azuremonitor'" "$apim_module"; then
  echo "APIM Azure Monitor diagnostics must use /loggers/azuremonitor, not bare azuremonitor." >&2
  exit 1
fi

if ! grep -q "loggerId: '/loggers/azuremonitor'" "$apim_module"; then
  echo "APIM Azure Monitor diagnostics loggerId is missing /loggers/azuremonitor." >&2
  exit 1
fi

echo "APIM diagnostic logger checks passed."
