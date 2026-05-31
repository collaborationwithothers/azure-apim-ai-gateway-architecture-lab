#!/usr/bin/env bash
set -euo pipefail

root="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      root="${2:?missing value for --root}"
      shift 2
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

root="$(cd "$root" && pwd)"
errors=0

fail() {
  echo "ERROR: $*"
  errors=$((errors + 1))
}

number_word() {
  case "$1" in
    0) echo "Zero" ;;
    1) echo "One" ;;
    2) echo "Two" ;;
    3) echo "Three" ;;
    4) echo "Four" ;;
    5) echo "Five" ;;
    6) echo "Six" ;;
    7) echo "Seven" ;;
    8) echo "Eight" ;;
    9) echo "Nine" ;;
    10) echo "Ten" ;;
    11) echo "Eleven" ;;
    12) echo "Twelve" ;;
    13) echo "Thirteen" ;;
    14) echo "Fourteen" ;;
    15) echo "Fifteen" ;;
    16) echo "Sixteen" ;;
    17) echo "Seventeen" ;;
    18) echo "Eighteen" ;;
    19) echo "Nineteen" ;;
    20) echo "Twenty" ;;
    *) echo "$1" ;;
  esac
}

check_file_exists() {
  local path="$1"
  [[ -f "$root/$path" ]] || fail "$path is missing"
}

check_scenario_table() {
  check_file_exists "README.md"
  [[ -d "$root/scenarios" ]] || return 0

  local count expected_word
  count="$(find "$root/scenarios" -maxdepth 1 -type d \
    -name '[0-9][0-9]-*' | wc -l | tr -d ' ')"
  expected_word="$(number_word "$count")"

  if ! grep -q "| \`scenarios/\`" "$root/README.md"; then
    fail "README.md repository structure table is missing scenarios row"
  elif ! grep -q "| \`scenarios/\`.*$expected_word mini system design case studies" \
      "$root/README.md"; then
    fail "README.md scenario count should say $expected_word"
  fi

  local dir base number
  while IFS= read -r dir; do
    base="$(basename "$dir")"
    number="${base%%-*}"
    if ! grep -Eq "^\|[[:space:]]*$number[[:space:]]*\|" \
        "$root/README.md"; then
      fail "README.md scenario table is missing $number ($base)"
    fi
  done < <(find "$root/scenarios" -maxdepth 1 -type d \
    -name '[0-9][0-9]-*' | sort)
}

check_numbered_index() {
  local dir="$1"
  local index="$2"
  local label="$3"

  [[ -d "$root/$dir" ]] || return 0
  check_file_exists "$index"
  [[ -f "$root/$index" ]] || return 0

  local file base number
  while IFS= read -r file; do
    base="$(basename "$file")"
    number="${base%%-*}"
    if ! grep -q "$base" "$root/$index"; then
      fail "$index is missing $base"
    fi
    if ! grep -Eq "^\|[[:space:]]*$number[[:space:]]*\|" \
        "$root/$index"; then
      fail "$index is missing table row for $number ($base)"
    fi
  done < <(find "$root/$dir" -maxdepth 1 -type f \
    -name '[0-9][0-9][0-9]-*.md' | sort)
}

check_known_values() {
  local search_dirs=()
  local dir file
  for dir in requirements design-log docs scenarios; do
    [[ -d "$root/$dir" ]] && search_dirs+=("$root/$dir")
  done
  [[ "${#search_dirs[@]}" -gt 0 ]] || return 0

  while IFS= read -r file; do
    if ! grep -q "swedencentral" "$file"; then
      fail "${file#$root/} references the hub-spoke platform without swedencentral"
    fi
  done < <(grep -RIl "Hub-Spoke APIM Edge Platform" \
    "${search_dirs[@]}" 2>/dev/null || true)
}

require_literal_if_file_exists() {
  local path="$1"
  local literal="$2"

  [[ -f "$root/$path" ]] || return 0
  if ! grep -qF "$literal" "$root/$path"; then
    fail "$path is missing required text: $literal"
  fi
}

reject_literal_if_file_exists() {
  local path="$1"
  local literal="$2"

  [[ -f "$root/$path" ]] || return 0
  if grep -qF "$literal" "$root/$path"; then
    fail "$path must not contain stale text: $literal"
  fi
}

check_persistent_lifecycle_docs() {
  [[ -f "$root/infra/bicep/README.md" || -f "$root/requirements/001-hub-spoke-apim-edge-platform.md" ]] || return 0

  for path in \
    README.md \
    infra/bicep/README.md \
    requirements/001-hub-spoke-apim-edge-platform.md \
    design-log/001-hub-spoke-apim-edge-platform.md \
    docs/plans/2026-05-31-spoke-full-demo-stack.md; do
    require_literal_if_file_exists "$path" "rg-cwc-ai-gw-shared-swc-001"
    require_literal_if_file_exists "$path" "kv-cwc-aigw-shr-swc-001"
    require_literal_if_file_exists "$path" "lab.consultwithcloud.com"
  done

  require_literal_if_file_exists "README.md" "confirmation phrase"
  require_literal_if_file_exists "README.md" "destroy"
  require_literal_if_file_exists "README.md" "APIM purge is permanent"
  require_literal_if_file_exists "infra/bicep/README.md" "APIM purge is permanent"
  require_literal_if_file_exists "requirements/001-hub-spoke-apim-edge-platform.md" 'No public DNS zone is created for `api.consultwithcloud.com`'
  require_literal_if_file_exists "design-log/001-hub-spoke-apim-edge-platform.md" 'There is no public DNS zone for `api.consultwithcloud.com`'
}

check_scenario_table
check_numbered_index "requirements" "requirements/index.md" "requirements"
check_numbered_index "design-log" "design-log/index.md" "design logs"
check_known_values
check_persistent_lifecycle_docs

if [[ "$errors" -gt 0 ]]; then
  echo
  echo "$errors documentation consistency issue(s) found."
  exit 1
fi

echo "Documentation consistency checks passed."
