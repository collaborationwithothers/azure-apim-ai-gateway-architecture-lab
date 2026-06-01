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

jq -e '.parameters.apiLabHostname.defaultValue == "api.lab.consultwithcloud.com"' "$compiled_template" >/dev/null
jq -e '.variables.publicHostname == "[parameters('\''apiLabHostname'\'')]"' "$compiled_template" >/dev/null
jq -e '.variables.apimGatewayHostname == "apim-cwc-ai-gw-swc-001.azure-api.net"' "$compiled_template" >/dev/null

jq -e '
  .. | objects
  | select(.type? == "Microsoft.ApiManagement/service")
  | .properties.hostnameConfigurations
  | . == []
' "$compiled_template" >/dev/null

jq -e '
  .. | objects
  | select(.type? == "Microsoft.Network/privateDnsZones")
  | .name == "[parameters('\''apimGatewayHostname'\'')]"
' "$compiled_template" >/dev/null

jq '
  [
    .. | objects
    | select(.type? == "Microsoft.Network/privateDnsZones/A")
    | select(.name == "[format('\''{0}/{1}'\'', parameters('\''apimGatewayHostname'\''), '\''@'\'')]")
  ]
' "$compiled_template" >/tmp/apim-private-dns-a-record.out

if [[ "$(jq 'length' /tmp/apim-private-dns-a-record.out)" != "0" ]]; then
  echo "APIM private DNS A record must not dereference apim.properties.privateIPAddresses[0] during ARM template evaluation." >&2
  cat /tmp/apim-private-dns-a-record.out >&2
  exit 1
fi

workflow="$repo_root/.github/workflows/infra-deploy.yml"

grep -q "APIM_SERVICE_NAME: apim-cwc-ai-gw-swc-001" "$workflow"
grep -q "APIM_RESOURCE_GROUP: rg-cwc-ai-gw-hub-swc-001" "$workflow"
grep -q "APIM_PRIVATE_DNS_ZONE_NAME: apim-cwc-ai-gw-swc-001.azure-api.net" "$workflow"
grep -q "Upsert APIM private gateway DNS record" "$workflow"
grep -q "az apim show" "$workflow"
grep -q "az network private-dns record-set a create" "$workflow"
grep -q "az network private-dns record-set a update" "$workflow"

if grep -q "privateIPAddresses\\[0\\]" "$repo_root/infra/bicep/modules/hub-apim.bicep"; then
  echo "hub-apim.bicep must not index privateIPAddresses[0] for DNS during the same deployment." >&2
  exit 1
fi

jq -e '
  [
    .. | objects
    | select(.type? == "Microsoft.Network/privateDnsZones/A")
    | .name
  ] | index("[format('\''{0}/{1}'\'', parameters('\''apimGatewayHostname'\''), '\''@'\'')]") | not
' "$compiled_template" >/dev/null

jq -e '
  .. | objects
  | select(.type? == "Microsoft.Network/applicationGateways")
  | (.properties.backendAddressPools[] | select(.name == "apim-private-gateway").properties.backendAddresses[0].fqdn == "[parameters('\''apimGatewayHostname'\'')]")
  and (.properties.probes[] | select(.name == "apim-health").properties.host == "[parameters('\''apimGatewayHostname'\'')]")
  and (.properties.backendHttpSettingsCollection[] | select(.name == "https-apim").properties.hostName == "[parameters('\''apimGatewayHostname'\'')]")
  and (.properties.httpListeners[] | select(.name == "https-api-consultwithcloud").properties.hostName == "[parameters('\''publicHostname'\'')]")
' "$compiled_template" >/dev/null

jq -e '
  [
    .. | objects
    | select(.type? == "Microsoft.Network/privateDnsZones/virtualNetworkLinks")
    | .name
  ] | index("[format('\''{0}/{1}'\'', parameters('\''apimGatewayHostname'\''), '\''link-hub'\'')]")
' "$compiled_template" >/dev/null

jq -e '
  [
    .. | objects
    | select(.type? == "Microsoft.Network/privateDnsZones/virtualNetworkLinks")
    | .name
  ] | index("[format('\''{0}/{1}'\'', parameters('\''privateDnsZoneName'\''), '\''link-spoke'\'')]")
' "$compiled_template" >/dev/null

if grep -R --include='*.bicep' "api.consultwithcloud.com" "$repo_root/infra/bicep" >/tmp/apim-lab-host-forbidden.out 2>&1; then
  echo "Bicep must not reference the old api.consultwithcloud.com hostname." >&2
  cat /tmp/apim-lab-host-forbidden.out >&2
  exit 1
fi

echo "APIM lab hostname and private DNS checks passed."
