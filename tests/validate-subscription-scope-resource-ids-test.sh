#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
compiled_template="$(mktemp)"
trap 'rm -f "$compiled_template"' EXIT

if [[ -x "$HOME/.azure/bin/bicep" ]]; then
  "$HOME/.azure/bin/bicep" build "$repo_root/infra/bicep/main.bicep" --outfile "$compiled_template"
else
  az bicep build --file "$repo_root/infra/bicep/main.bicep" --outfile "$compiled_template"
fi

if grep -q "resourceId(variables('hubRgName'), 'Microsoft.Network/virtualNetworks'" "$compiled_template"; then
  echo "Hub VNet ID must include the subscription and resource group path explicitly." >&2
  exit 1
fi

if grep -q "resourceId(parameters('runnerVnetResourceGroupName'), 'Microsoft.Network/virtualNetworks'" "$compiled_template"; then
  echo "Runner VNet ID must include the subscription and resource group path explicitly." >&2
  exit 1
fi

if ! grep -q "/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Network/virtualNetworks/{2}" "$compiled_template"; then
  echo "Compiled template is missing explicit cross-resource-group VNet ID formatting." >&2
  exit 1
fi

echo "Subscription-scope resource ID checks passed."
