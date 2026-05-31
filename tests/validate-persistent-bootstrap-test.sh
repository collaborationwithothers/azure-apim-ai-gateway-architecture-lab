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
if grep -q "key_vault_virtual_network_rule_subnet_ids:" "$workflow"; then
  echo "Bootstrap workflow must infer Key Vault subnet rules instead of accepting subnet IDs as dispatch input." >&2
  exit 1
fi
grep -q "Infer Key Vault VNet rules" "$workflow"
grep -q "HUB_RESOURCE_GROUP_NAME: rg-cwc-ai-gw-hub-swc-001" "$workflow"
grep -q "HUB_VNET_NAME: vnet-cwc-ai-gw-hub-swc-001" "$workflow"
grep -q "APPGW_SUBNET_NAME: snet-appgw" "$workflow"
grep -q "APIM_SUBNET_NAME: snet-apim" "$workflow"
grep -q "az network vnet subnet show" "$workflow"
grep -q "Both hub Key Vault client subnets must exist, or neither should exist." "$workflow"
grep -q 'keyVaultVirtualNetworkRuleSubnetIds="$KEY_VAULT_VNET_RULE_SUBNET_IDS"' "$workflow"

if grep -R --include='*.bicep' "api.consultwithcloud.com" "$repo_root/infra/bicep" >/tmp/persistent-forbidden.out 2>&1; then
  echo "Bicep must not create or reference a public api.consultwithcloud.com DNS zone." >&2
  cat /tmp/persistent-forbidden.out >&2
  exit 1
fi

echo "Persistent bootstrap checks passed."
