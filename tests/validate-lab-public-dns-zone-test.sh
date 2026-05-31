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

if ! jq -e '.parameters.labDnsZoneName.defaultValue == "lab.consultwithcloud.com"' "$compiled_template" >/dev/null; then
  echo "Compiled template is missing the lab.consultwithcloud.com public DNS zone name." >&2
  exit 1
fi

if ! jq -e '.outputs | has("labPublicDnsZoneNameServers")' "$compiled_template" >/dev/null; then
  echo "Compiled template is missing lab public DNS name server outputs." >&2
  exit 1
fi

if ! jq -e '.outputs.labPublicDnsZoneName.value == "[parameters('\''labDnsZoneName'\'')]"' "$compiled_template" >/dev/null; then
  echo "Compiled template must expose labPublicDnsZoneName from the labDnsZoneName parameter." >&2
  exit 1
fi

if ! jq -e '.outputs.publicDnsZoneName.value == "[parameters('\''labDnsZoneName'\'')]"' "$compiled_template" >/dev/null; then
  echo "Compiled template must treat lab.consultwithcloud.com as the public DNS zone." >&2
  exit 1
fi

if ! jq -e '.variables.publicHostname == "[parameters('\''apiLabHostname'\'')]" and .outputs.publicHostname.value == "[variables('\''publicHostname'\'')]"' "$compiled_template" >/dev/null; then
  echo "Compiled template must expose the public API hostname from apiLabHostname." >&2
  exit 1
fi

if ! jq -e '.resources[] | select(.name == "hub-platform") | .properties.parameters.labPublicDnsZoneName.value == "[parameters('\''labDnsZoneName'\'')]"' "$compiled_template" >/dev/null; then
  echo "Hub deployment must receive the lab public DNS zone from the labDnsZoneName parameter." >&2
  exit 1
fi

if ! jq -e '.resources[] | select(.name == "hub-platform") | .properties.parameters.publicHostname.value == "[variables('\''publicHostname'\'')]"' "$compiled_template" >/dev/null; then
  echo "Hub deployment must receive the public API hostname from apiLabHostname." >&2
  exit 1
fi

if ! jq -e '.resources[] | select(.name == "hub-platform") | .properties.parameters.publicDnsRecordName.value == "[variables('\''apiLabDnsRecordName'\'')]"' "$compiled_template" >/dev/null; then
  echo "Hub deployment must receive the api DNS record label separately from the lab DNS zone." >&2
  exit 1
fi

if ! grep -q "br/public:avm/res/network/dns-zone:0.6.0" "$repo_root/infra/bicep/modules/hub-edge.bicep"; then
  echo "The lab public DNS zone must use the pinned AVM public DNS zone module." >&2
  exit 1
fi

if ! grep -q "resource dnsZone 'Microsoft.Network/dnsZones@2018-05-01' existing" "$repo_root/infra/bicep/modules/hub-edge.bicep"; then
  echo "The lab DNS A record must attach to the lab DNS zone instead of creating a hostname zone." >&2
  exit 1
fi

if ! grep -q "name: publicDnsRecordName" "$repo_root/infra/bicep/modules/hub-edge.bicep"; then
  echo "The API public DNS record must use an explicit record-name parameter under lab.consultwithcloud.com." >&2
  exit 1
fi

if jq -e '.. | objects | select((.type? == "Microsoft.Network/dnsZones/A") or (.type? == "Microsoft.Network/dnsZones/CNAME")) | select(.name? | tostring | test("api\\.lab\\.consultwithcloud\\.com|app\\.lab\\.consultwithcloud\\.com|argo\\.lab\\.consultwithcloud\\.com|/app|/argo|app/|argo/"))' "$compiled_template" >/dev/null; then
  echo "The lab DNS record slice must not create hostname-shaped zones or app/argo records." >&2
  exit 1
fi

echo "Lab public DNS zone checks passed."
