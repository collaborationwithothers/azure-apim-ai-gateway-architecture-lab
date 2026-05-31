#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
compiled_template="$(mktemp)"
trap 'rm -f "$compiled_template"' EXIT

if [[ -x "$HOME/.azure/bin/bicep" ]]; then
  "$HOME/.azure/bin/bicep" build "$repo_root/infra/bicep/persistent.bicep" --outfile "$compiled_template"
else
  az bicep build --file "$repo_root/infra/bicep/persistent.bicep" --outfile "$compiled_template"
fi

jq -e '.resources[] | select(.type == "Microsoft.Resources/resourceGroups") | .name == "[variables('\''sharedRgName'\'')]"' "$compiled_template" >/dev/null
jq -e '.resources[] | select(.type == "Microsoft.Resources/deployments") | .resourceGroup == "[variables('\''sharedRgName'\'')]"' "$compiled_template" >/dev/null
jq -e '.variables.sharedRgName == "rg-cwc-ai-gw-shared-swc-001"' "$compiled_template" >/dev/null
jq -e '.variables.keyVaultName == "kv-cwc-aigw-shr-swc-001"' "$compiled_template" >/dev/null
jq -e '.parameters.labDnsZoneName.defaultValue == "lab.consultwithcloud.com"' "$compiled_template" >/dev/null
jq -e '.parameters.keyVaultVirtualNetworkRuleSubnetIds.defaultValue == []' "$compiled_template" >/dev/null

workflow="$repo_root/.github/workflows/bootstrap-persistent.yml"
grep -q "key_vault_virtual_network_rule_subnet_ids:" "$workflow"
grep -q 'default: "\[\]"' "$workflow"
grep -q "jq -e 'type == \"array\" and all(.\[\]; type == \"string\")'" "$workflow"
grep -q 'keyVaultVirtualNetworkRuleSubnetIds="$KEY_VAULT_VNET_RULE_SUBNET_IDS"' "$workflow"

if grep -R --include='*.bicep' "api.consultwithcloud.com" "$repo_root/infra/bicep" >/tmp/persistent-forbidden.out 2>&1; then
  echo "Bicep must not create or reference a public api.consultwithcloud.com DNS zone." >&2
  cat /tmp/persistent-forbidden.out >&2
  exit 1
fi

echo "Persistent bootstrap checks passed."
