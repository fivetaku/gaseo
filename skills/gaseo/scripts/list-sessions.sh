#!/usr/bin/env bash
# List recent Claude Code sessions for a folder, newest first.
#
#   list-sessions.sh [folder] [limit=10]
#
# Output: one row per session, pipe-separated —
#   <n> | <sessionId> | <YYYY-MM-DD HH:MM> | registered|- | <first user message>
# The first row is the current session when run from a live session's folder.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=paseo-common.sh
. "$HERE/paseo-common.sh"

CWD="${1:-$PWD}"
[ -d "$CWD" ] || { echo "ERROR: not a directory: $CWD" >&2; exit 1; }
CWD="$(cd "$CWD" && pwd)"
LIMIT="${2:-10}"
case "$LIMIT" in ''|*[!0-9]*) echo "ERROR: limit must be a number: $LIMIT" >&2; exit 1;; esac

PROJ_DIR="$(proj_dir_for "$CWD")"
[ -d "$PROJ_DIR" ] || { echo "ERROR: no session directory: $PROJ_DIR" >&2; exit 1; }

# Sort by mtime descending without parsing `ls` output.
files=()
while IFS= read -r -d '' line; do
  files+=("${line#* }")
done < <(
  for f in "$PROJ_DIR"/*.jsonl; do
    [ -e "$f" ] || continue
    printf '%s %s\0' "$(stat -f '%m' "$f" 2>/dev/null || stat -c '%Y' "$f")" "$f"
  done | sort -z -rn
)

[ "${#files[@]}" -gt 0 ] || { echo "ERROR: no session files found in $PROJ_DIR" >&2; exit 1; }

n=0
for f in "${files[@]}"; do
  n=$((n + 1))
  [ "$n" -gt "$LIMIT" ] && break
  sid="$(basename "$f" .jsonl)"
  reg="-"
  is_registered "$sid" && reg="registered"
  first="$(first_message "$f")"
  echo "$n | $sid | $(mtime_of "$f") | $reg | ${first:-(no message)}"
done
