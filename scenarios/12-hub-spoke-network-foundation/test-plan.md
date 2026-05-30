# Test Plan: Hub-Spoke Network Foundation

## Documentation checks

Run from the repository root:

```sh
git diff --check
markdownlint "**/*.md"
```

If `markdownlint` is not installed, note that it could not be run.

## Static repository checks

Run:

```sh
rg -n "pull_request|pull_request_target" .github/workflows
rg -n "client-secret|password|PFX|BEGIN PRIVATE KEY|PLACEHOLDER_SECRET" .
```

Deployment workflows must not be pull-request triggered. Secret scans must not
reveal real private key or credential material.

## Bicep checks

Run:

```sh
az bicep build --file infra/bicep/main.bicep
```

Expected result: successful build. If Azure CLI is unavailable, document that
validation could not run.

## Azure pre-apply checks

Run a subscription-scope what-if from an authenticated shell or guarded
workflow:

```sh
az deployment sub what-if \
  --location eastus2 \
  --template-file infra/bicep/main.bicep \
  --parameters location=eastus2 \
  --parameters runnerAllowedPublicIp=<runner-nat-public-ip>
```

Expected result: only the intended hub, spoke, edge, diagnostics, DNS,
certificate-support, and peering resources appear.

For the GitHub Actions path, `runnerAllowedPublicIp` is populated from the
`RUNNER_ALLOWED_PUBLIC_IP_CIDR` variable on the `dev` GitHub Environment.

## Post-apply checks

- Hub and spoke resource groups exist in `eastus2`.
- Hub, spoke, and runner VNets have bidirectional peerings.
- Spoke route tables send future workload and AKS default egress to Azure
  Firewall private IP.
- Application Gateway frontend public IP exists.
- Public DNS child zone exists.
- APIM Premium v2 exists with private gateway behavior.
- Log Analytics receives diagnostics from platform services.
- After certificate binding, Application Gateway backend health for APIM is
  healthy.

## Out-of-scope tests

- No AKS workload test.
- No private endpoint test.
- No production load test.
- No spoke application security test.
