#!/usr/bin/env bash
# Register a Claude Code session as a Paseo agent via `paseo import`.
#
#   register.sh [folder]              -> register the CURRENT session of that folder
#   register.sh [folder] <sessionId>  -> register one specific session
#
# A --title "<text>" option (anywhere in the arguments) names the imported agent
# AND its workspace. Without it Paseo titles the workspace after the git branch,
# so every session in one repo lands in the app as another row called "main".
#
# Import is a link, not a copy: Paseo stores only a pointer to the session ID,
# so the original transcript is never moved, altered, or duplicated.
#
# Which session is "current" is resolved in this order:
#   1. an explicit session ID argument
#   2. $CLAUDE_CODE_SESSION_ID, when its transcript lives in this folder's
#      project directory (Claude Code exports the live session's own ID)
#   3. the most recently modified transcript — a guess, since background
#      subagent and hook-spawned sessions write here too and can be newer
#
# Codex: when $CLAUDE_CODE_SESSION_ID is unset and $CODEX_THREAD_ID is set, the
# current Codex thread is imported with --provider codex (current session only).
# The live thread is locked by its terminal, so when Paseo refuses it ("active
# writer") the thread is forked and the fork is registered (FORKED line).
#
# Output contract:
#   stdout, exit 0 — [FORKED source=<codex thread> fork=<new thread>]
#                    REGISTERED session=<id> cwd=<path>
#                  | ALREADY_REGISTERED session=<id>
#   stderr, exit 1 — ERROR <message>
# Plus, for REGISTERED/ALREADY_REGISTERED, an informational line on stdout:
#   DETECTED via=explicit|env|mtime provider=claude|codex first_message=<first human line>
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=paseo-common.sh
. "$HERE/paseo-common.sh"

err() { echo "$1" >&2; exit 1; }

TITLE=""
POS=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --title)   TITLE="${2:-}"; shift 2 || err "ERROR: --title needs a value" ;;
    --title=*) TITLE="${1#--title=}"; shift ;;
    *)         POS+=("$1"); shift ;;
  esac
done

CWD="${POS[0]:-$PWD}"
[ -d "$CWD" ] || err "ERROR: not a directory: $CWD"
CWD="$(cd "$CWD" && pwd)"
WANTED="${POS[1]:-}"

PROVIDER="claude"
# Codex: no Claude session ID but a Codex thread ID -> register this Codex thread.
if [ -z "$WANTED" ] && [ -z "${CLAUDE_CODE_SESSION_ID:-}" ] && [ -n "${CODEX_THREAD_ID:-}" ]; then
  PROVIDER="codex"
fi

if [ "$PROVIDER" = "claude" ]; then
  PROJ_DIR="$(proj_dir_for "$CWD")"
  [ -d "$PROJ_DIR" ] || err "ERROR: no session directory for this folder: $PROJ_DIR"
fi

HOW="explicit"
if [ "$PROVIDER" = "codex" ]; then
  # Codex exports the live thread's own ID; paseo resumes it via the Codex app-server.
  SESSION_FILE=""
  SESSION_ID="$CODEX_THREAD_ID"
  HOW="env"
elif [ -n "$WANTED" ]; then
  SESSION_FILE="$PROJ_DIR/$WANTED.jsonl"
  [ -f "$SESSION_FILE" ] || err "ERROR: session $WANTED not found in $PROJ_DIR"
elif [ -n "${CLAUDE_CODE_SESSION_ID:-}" ] && [ -f "$PROJ_DIR/$CLAUDE_CODE_SESSION_ID.jsonl" ]; then
  # Authoritative: Claude Code exports the live session's own ID. Only trusted
  # when its transcript is actually in this folder's project directory — the
  # variable can survive into unrelated child contexts, and the target folder
  # may not be the one this session runs in.
  SESSION_FILE="$PROJ_DIR/$CLAUDE_CODE_SESSION_ID.jsonl"
  HOW="env"
else
  # Fallback: the live transcript is the one still being appended to. Background
  # subagent and hook-spawned sessions also write into this directory and can be
  # newer, so this path is a guess — hence the DETECTED line below.
  SESSION_FILE="$(newest_jsonl "$PROJ_DIR")" \
    || err "ERROR: no session files found in $PROJ_DIR"
  HOW="mtime"
fi
[ "$PROVIDER" = "codex" ] || SESSION_ID="$(basename "$SESSION_FILE" .jsonl)"

PASEO="$(find_paseo)" || err "ERROR: paseo CLI not found (checked PATH and the default install paths)"

# Show which session was picked, and how. `via=mtime` is a guess worth
# confirming; `via=env` came from Claude Code's own session ID.
if [ "$PROVIDER" = "codex" ]; then FIRST="(codex thread)"; else FIRST="$(first_message "$SESSION_FILE")"; fi
echo "DETECTED via=$HOW provider=$PROVIDER first_message=${FIRST:-(no message)}"

if is_registered "$SESSION_ID" "$PROVIDER"; then
  echo "ALREADY_REGISTERED session=$SESSION_ID"
  # Re-running with --title is the supported way to retitle an existing entry.
  if [ -n "$TITLE" ]; then
    EXISTING="$(agent_id_for_session "$SESSION_ID" "$PROVIDER")" || EXISTING=""
    [ -n "$EXISTING" ] && apply_title "$PASEO" "$EXISTING" "$TITLE"
  fi
  exit 0
fi

if ! OUT="$("$PASEO" import "$SESSION_ID" --provider "$PROVIDER" --cwd "$CWD" --json 2>&1)"; then
  # A live Codex thread is locked by the terminal writing it, so Paseo cannot resume it.
  # Fork it (conversation so far -> new thread) and register the fork; the label keeps the
  # original thread ID so a re-run finds it as ALREADY_REGISTERED.
  if [ "$PROVIDER" = "codex" ] && printf '%s' "$OUT" | grep -q 'active writer'; then
    FORK="$(python3 "$HERE/codex_fork.py" "$SESSION_ID" --cwd "$CWD" 2>&1)" \
      || err "ERROR: codex thread is in use and could not be forked: $FORK"
    echo "FORKED source=$SESSION_ID fork=$FORK"
    OUT="$("$PASEO" import "$FORK" --provider codex --cwd "$CWD" --label "gaseo-source=$SESSION_ID" --json 2>&1)" \
      || err "ERROR: paseo import failed: $OUT"
    SESSION_ID="$FORK"
  else
    err "ERROR: paseo import failed: $OUT"
  fi
fi

echo "REGISTERED session=$SESSION_ID cwd=$CWD"
echo "$OUT"

# `paseo import --json` reports the agent id but not the workspace it created,
# so the title is applied in a second step keyed off that id.
AGENT_ID="$(printf '%s' "$OUT" | sed -n 's/.*"agentId"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
[ -n "$AGENT_ID" ] && apply_title "$PASEO" "$AGENT_ID" "$TITLE"
