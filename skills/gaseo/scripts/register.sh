#!/usr/bin/env bash
# Register a Claude Code session as a Paseo agent via `paseo import`.
#
#   register.sh [folder]              -> register the CURRENT session of that folder
#   register.sh [folder] <sessionId>  -> register one specific session
#
# Import is a link, not a copy: Paseo stores only a pointer to the session ID,
# so the original transcript is never moved, altered, or duplicated.
#
# Output contract:
#   stdout, exit 0 — REGISTERED session=<id> cwd=<path>
#                  | ALREADY_REGISTERED session=<id>
#   stderr, exit 1 — ERROR <message>
# Plus, for REGISTERED/ALREADY_REGISTERED, an informational line on stdout:
#   DETECTED first_message=<first human line of that session>
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=paseo-common.sh
. "$HERE/paseo-common.sh"

err() { echo "$1" >&2; exit 1; }

CWD="${1:-$PWD}"
[ -d "$CWD" ] || err "ERROR: not a directory: $CWD"
CWD="$(cd "$CWD" && pwd)"
WANTED="${2:-}"

PROJ_DIR="$(proj_dir_for "$CWD")"
[ -d "$PROJ_DIR" ] || err "ERROR: no session directory for this folder: $PROJ_DIR"

if [ -n "$WANTED" ]; then
  SESSION_FILE="$PROJ_DIR/$WANTED.jsonl"
  [ -f "$SESSION_FILE" ] || err "ERROR: session $WANTED not found in $PROJ_DIR"
else
  SESSION_FILE="$(newest_jsonl "$PROJ_DIR")" \
    || err "ERROR: no session files found in $PROJ_DIR"
fi
SESSION_ID="$(basename "$SESSION_FILE" .jsonl)"

PASEO="$(find_paseo)" || err "ERROR: paseo CLI not found (checked PATH and the default install paths)"

# Show which session was picked. With two sessions live in the same folder the
# newest-mtime rule can land on the other one, so the caller confirms this line.
FIRST="$(first_message "$SESSION_FILE")"
echo "DETECTED first_message=${FIRST:-(no message)}"

if is_registered "$SESSION_ID"; then
  echo "ALREADY_REGISTERED session=$SESSION_ID"
  exit 0
fi

OUT="$("$PASEO" import "$SESSION_ID" --provider claude --cwd "$CWD" --json 2>&1)" \
  || err "ERROR: paseo import failed: $OUT"

echo "REGISTERED session=$SESSION_ID cwd=$CWD"
echo "$OUT"
