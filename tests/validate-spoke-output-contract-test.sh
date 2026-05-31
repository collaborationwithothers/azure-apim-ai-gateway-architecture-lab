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

if ! grep -q '"spokeNetwork"' "$compiled_template"; then
  echo "Compiled template is missing the top-level spokeNetwork output." >&2
  exit 1
fi

required_contract_keys=(
  spokeVnetId
  spokeVnetName
  workloadSubnetId
  privateEndpointsSubnetId
  aksSubnetId
  workloadRouteTableId
  aksRouteTableId
)

for contract_key in "${required_contract_keys[@]}"; do
  if ! grep -q "\"$contract_key\"" "$compiled_template"; then
    echo "Compiled template is missing spoke contract key: $contract_key" >&2
    exit 1
  fi
done

required_names=(
  vnet-cwc-ai-gw-spoke-swc-001
  snet-workload
  snet-private-endpoints
  snet-aks
  rt-cwc-ai-gw-workload-swc-001
  rt-cwc-ai-gw-aks-swc-001
)

for resource_name in "${required_names[@]}"; do
  if ! grep -q "$resource_name" "$compiled_template"; then
    echo "Compiled template is missing spoke contract resource name: $resource_name" >&2
    exit 1
  fi
done

if ! grep -q '"addressPrefix": "0.0.0.0/0"' "$compiled_template"; then
  echo "Compiled template is missing the spoke default route to Azure Firewall." >&2
  exit 1
fi

if ! grep -q '"nextHopType": "VirtualAppliance"' "$compiled_template"; then
  echo "Compiled template is missing the spoke firewall next hop type." >&2
  exit 1
fi

forbidden_patterns=(
  Microsoft.ContainerService/managedClusters
  Microsoft.Cache/Redis
  Microsoft.Network/privateEndpoints
  Microsoft.MachineLearningServices
  Microsoft.CognitiveServices
  Microsoft.KubernetesConfiguration
  Microsoft.Kubernetes
  argocd
  istio
)

for pattern in "${forbidden_patterns[@]}"; do
  if grep -qi "$pattern" "$compiled_template"; then
    echo "Issue 30 must not deploy downstream spoke resources or markers: $pattern" >&2
    exit 1
  fi
done

echo "Spoke output contract checks passed."
