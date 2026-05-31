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

if ! jq -e '.resources[] | select(.name == "hub-platform") | .properties.parameters.labPublicDnsZoneName.value == "[parameters('\''labDnsZoneName'\'')]"' "$compiled_template" >/dev/null; then
  echo "Hub deployment must receive the lab public DNS zone from the labDnsZoneName parameter." >&2
  exit 1
fi

if ! grep -q "br/public:avm/res/network/dns-zone:0.6.0" "$repo_root/infra/bicep/modules/hub-edge.bicep"; then
  echo "The lab public DNS zone must use the pinned AVM public DNS zone module." >&2
  exit 1
fi

if jq -e '.. | objects | select((.type? == "Microsoft.Network/dnsZones/A") or (.type? == "Microsoft.Network/dnsZones/CNAME")) | select(.name? | tostring | test("labPublicDnsZoneName|labDnsZoneName|lab\\.consultwithcloud\\.com|/api|/app|/argo|api/|app/|argo/"))' "$compiled_template" >/dev/null; then
  echo "Issue 29 must not create lab.consultwithcloud.com DNS records or aliases." >&2
  exit 1
fi

echo "Lab public DNS zone checks passed."
