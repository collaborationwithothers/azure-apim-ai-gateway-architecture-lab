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

required_parameters=(
  labDnsZoneName
  apiLabHostname
  appLabHostname
  argoLabHostname
  enableAks
  enableRedis
  enableFoundryBackend
  enableGitOps
  enableBff
  aksSkuTier
  aksNodeVmSize
  aksNodeCount
  aksKubernetesVersion
  aksEnablePrivateCluster
  aksOutboundType
  redisSkuName
  redisCapacity
  redisFamily
  redisMinimumTlsVersion
  foundryProjectName
  foundryModelName
  foundryModelVersion
  foundryModelDeploymentName
  foundryModelDeploymentSkuName
  foundryModelDeploymentCapacity
  gitOpsRepositoryUrl
  gitOpsRevision
  gitOpsPath
  gitOpsAutoSync
  gitOpsAutoPrune
  diagnosticLogRetentionDays
  enableVerboseDiagnostics
  bffAppRegistrationClientId
)

for parameter_name in "${required_parameters[@]}"; do
  if ! jq -e --arg parameter_name "$parameter_name" '.parameters | has($parameter_name)' "$compiled_template" >/dev/null; then
    echo "Compiled template is missing issue 32 parameter: $parameter_name" >&2
    exit 1
  fi
done

declare -A expected_parameter_defaults=(
  [labDnsZoneName]=lab.consultwithcloud.com
  [apiLabHostname]=api.lab.consultwithcloud.com
  [appLabHostname]=app.lab.consultwithcloud.com
  [argoLabHostname]=argo.lab.consultwithcloud.com
)

for parameter_name in "${!expected_parameter_defaults[@]}"; do
  if ! jq -e --arg parameter_name "$parameter_name" --arg expected_value "${expected_parameter_defaults[$parameter_name]}" '.parameters[$parameter_name].defaultValue == $expected_value' "$compiled_template" >/dev/null; then
    echo "Compiled template has an unexpected default for issue 32 parameter: $parameter_name" >&2
    exit 1
  fi
done

required_contract_outputs=(
  labDns
  features
  aks
  redis
  foundry
  gitOps
  diagnostics
  bff
  unresolvedDecisions
  dependencies
)

if ! jq -e '.outputs | has("spokeFullDemoContract")' "$compiled_template" >/dev/null; then
  echo "Compiled template is missing the top-level spokeFullDemoContract output." >&2
  exit 1
fi

for output_key in "${required_contract_outputs[@]}"; do
  if ! jq -e --arg output_key "$output_key" '.variables.spokeFullDemoContract | has($output_key)' "$compiled_template" >/dev/null; then
    echo "Compiled template is missing issue 32 output contract key: $output_key" >&2
    exit 1
  fi
done

required_hostnames=(
  lab.consultwithcloud.com
  api.lab.consultwithcloud.com
  app.lab.consultwithcloud.com
  argo.lab.consultwithcloud.com
)

for hostname in "${required_hostnames[@]}"; do
  if ! jq -e --arg hostname "$hostname" '[.parameters[]?.defaultValue? | select(. == $hostname)] | length == 1' "$compiled_template" >/dev/null; then
    echo "Compiled template is missing lab hostname contract value: $hostname" >&2
    exit 1
  fi
done

for forbidden_output in secretUri kubeconfig accessKey pfx clientSecret token; do
  if jq -e --arg forbidden_output "$forbidden_output" '.variables.spokeFullDemoContract | tostring | test($forbidden_output; "i")' "$compiled_template" >/dev/null; then
    echo "Compiled template exposes forbidden sensitive output marker: $forbidden_output" >&2
    exit 1
  fi
done

for forbidden_resource in \
  Microsoft.ContainerService/managedClusters \
  Microsoft.Cache/Redis \
  Microsoft.Network/privateEndpoints \
  Microsoft.MachineLearningServices \
  Microsoft.CognitiveServices/accounts/deployments \
  Microsoft.KubernetesConfiguration \
  Microsoft.Kubernetes; do
  if jq -e --arg forbidden_resource "$forbidden_resource" '.. | objects | select(.type? == $forbidden_resource)' "$compiled_template" >/dev/null; then
    echo "Issue 32 must not deploy downstream resources: $forbidden_resource" >&2
    exit 1
  fi
done

required_docs=(
  'Redis product choice'
  'model availability'
  'certificate name'
  'Argo SSO groups'
  'BFF app registration'
  'Issue #29 remains the first implementation dependency'
  'AVM fit for issue #32'
)

for doc_marker in "${required_docs[@]}"; do
  if ! grep -q "$doc_marker" "$repo_root/infra/bicep/README.md"; then
    echo "infra/bicep/README.md is missing issue 32 documentation marker: $doc_marker" >&2
    exit 1
  fi
done

echo "Spoke full demo contract checks passed."
