#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
validator="$repo_root/tools/validate-doc-consistency.sh"

if [[ ! -x "$validator" && ! -f "$validator" ]]; then
  exit 0
fi

output_file="$(mktemp)"
trap 'rm -f "$output_file"' EXIT

if bash "$validator" --root "$repo_root" >"$output_file" 2>&1; then
  exit 0
fi

node -e '
const fs = require("fs");
const path = process.argv[1];
const output = fs.readFileSync(path, "utf8").trim();
process.stdout.write(JSON.stringify({
  continue: true,
  systemMessage:
    "Documentation consistency check reported issues:\n\n" + output
}));
' "$output_file"
