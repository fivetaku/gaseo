#!/usr/bin/env bash
# Shared helpers for gaseo scripts. Sourced, not executed.

PASEO_HOME="${PASEO_HOME:-$HOME/.paseo}"
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

# Claude Code stores a folder's sessions under a directory name derived from the
# absolute path with every non-alphanumeric character replaced by '-'.
# Note '_' also becomes '-'  (e.g. /Users/me/My_Repo -> -Users-me-My-Repo).
proj_dir_for() {
  printf '%s/projects/%s' "$CLAUDE_HOME" \
    "$(printf '%s' "$1" | sed 's/[^a-zA-Z0-9]/-/g')"
}

# Locate the paseo CLI: PATH first, then the known per-platform install paths.
find_paseo() {
  local p c
  p="$(command -v paseo 2>/dev/null || true)"
  if [ -n "$p" ]; then printf '%s' "$p"; return 0; fi
  for c in \
    "$HOME/.local/bin/paseo" \
    "/Applications/Paseo.app/Contents/Resources/bin/paseo" \
    "/opt/Paseo/resources/bin/paseo" \
    "/usr/lib/paseo/resources/bin/paseo" \
    "/usr/local/lib/paseo/resources/bin/paseo" \
    "${LOCALAPPDATA:-$HOME/AppData/Local}/Programs/Paseo/resources/bin/paseo.cmd" \
    "/c/Program Files/Paseo/resources/bin/paseo.cmd" \
    "/mnt/c/Program Files/Paseo/resources/bin/paseo.cmd"
  do
    [ -x "$c" ] && { printf '%s' "$c"; return 0; }
  done
  return 1
}

# Newest .jsonl in a directory. The session being talked to right now is still
# being appended to, so it is always the most recently modified one.
newest_jsonl() {
  local dir="$1" f newest=""
  for f in "$dir"/*.jsonl; do
    [ -e "$f" ] || continue
    if [ -z "$newest" ] || [ "$f" -nt "$newest" ]; then newest="$f"; fi
  done
  [ -n "$newest" ] || return 1
  printf '%s' "$newest"
}

# Modification time as "YYYY-MM-DD HH:MM" on both BSD (macOS) and GNU (Linux).
mtime_of() {
  stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$1" 2>/dev/null \
    || stat -c '%y' "$1" 2>/dev/null | cut -c1-16 \
    || echo '?'
}

# True when this session ID already appears in a Paseo agent record.
is_registered() {
  [ -d "$PASEO_HOME/agents" ] || return 1
  grep -rlF "\"$1\"" "$PASEO_HOME/agents" >/dev/null 2>&1
}

# First human-typed line of a session transcript, truncated. Used so the caller
# can confirm which session was picked before anything is registered.
first_message() {
  command -v python3 >/dev/null 2>&1 || return 0
  head -c 200000 "$1" 2>/dev/null | python3 -c '
import sys, json
for line in sys.stdin:
    try:
        d = json.loads(line)
    except Exception:
        continue
    if d.get("type") != "user":
        continue
    c = d.get("message", {}).get("content", "")
    if isinstance(c, list):
        c = " ".join(x.get("text", "") for x in c if isinstance(x, dict))
    c = " ".join(str(c).split())
    if c and not c.startswith("<") and not c.startswith("Caveat:"):
        print(c[:70])
        break
' 2>/dev/null || true
}
