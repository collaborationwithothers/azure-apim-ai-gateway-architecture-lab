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
    if ! grep -q "northcentralus" "$file"; then
      fail "${file#$root/} references the hub-spoke platform without northcentralus"
    fi
  done < <(grep -RIl "Hub-Spoke APIM Edge Platform" \
    "${search_dirs[@]}" 2>/dev/null || true)
}

check_scenario_table
check_numbered_index "requirements" "requirements/index.md" "requirements"
check_numbered_index "design-log" "design-log/index.md" "design logs"
check_known_values

if [[ "$errors" -gt 0 ]]; then
  echo
  echo "$errors documentation consistency issue(s) found."
  exit 1
fi

echo "Documentation consistency checks passed."
