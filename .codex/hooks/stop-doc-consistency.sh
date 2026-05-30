#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
validators=(
  "$repo_root/tools/validate-doc-consistency.sh"
  "$repo_root/tools/validate-workflow-guardrails.sh"
)

output_file="$(mktemp)"
trap 'rm -f "$output_file"' EXIT

failed=0

for validator in "${validators[@]}"; do
  [[ -f "$validator" ]] || continue
  if ! bash "$validator" --root "$repo_root" >>"$output_file" 2>&1; then
    failed=1
  fi
done

[[ "$failed" -eq 1 ]] || exit 0

node -e '
const fs = require("fs");
const path = process.argv[1];
const output = fs.readFileSync(path, "utf8").trim();
process.stdout.write(JSON.stringify({
  continue: true,
  systemMessage:
    "Repository guardrail checks reported issues:\n\n" + output
}));
' "$output_file"
