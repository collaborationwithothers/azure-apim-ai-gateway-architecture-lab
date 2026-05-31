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

if ! grep -q '"labPublicDnsZoneName": "lab.consultwithcloud.com"' "$compiled_template"; then
  echo "Compiled template is missing the lab.consultwithcloud.com public DNS zone name." >&2
  exit 1
fi

if ! grep -q '"labPublicDnsZoneNameServers"' "$compiled_template"; then
  echo "Compiled template is missing lab public DNS name server outputs." >&2
  exit 1
fi

if ! grep -q "br/public:avm/res/network/dns-zone:0.6.0" "$repo_root/infra/bicep/modules/hub-edge.bicep"; then
  echo "The lab public DNS zone must use the pinned AVM public DNS zone module." >&2
  exit 1
fi

if rg -n "api\\.lab\\.consultwithcloud\\.com|app\\.lab\\.consultwithcloud\\.com|argo\\.lab\\.consultwithcloud\\.com|parent: labPublicDnsZone|labPublicDnsZone.*dnsZones/A" "$repo_root/infra/bicep" --glob "*.bicep"; then
  echo "Issue 29 must not create lab.consultwithcloud.com DNS records or aliases." >&2
  exit 1
fi

echo "Lab public DNS zone checks passed."
