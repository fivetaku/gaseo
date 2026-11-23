#!/usr/bin/env bash
# Fake-paseo regression test for register.sh (Claude + Codex paths). Never touches a real daemon.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
T="$(mktemp -d)"
mkdir -p "$T/bin" "$T/work" "$T/claude/projects" "$T/paseo/agents"
cat > "$T/bin/paseo" <<'F'
#!/usr/bin/env bash
echo "$@" >> "$FAKE_LOG"
if [ "$1" = import ] && [ "$2" = live-thread ]; then
  echo '{"error":{"message":"Failed to resume Codex thread live-thread: thread live-thread already has an active writer"}}'; exit 1
fi
case "$1" in import) echo '{"agentId":"agent-123"}';; esac
F
chmod +x "$T/bin/paseo"
# Fake `codex app-server`: answers initialize and thread/fork with a new thread id.
cat > "$T/bin/codex" <<'F'
#!/usr/bin/env python3
import json, sys
for line in sys.stdin:
    o = json.loads(line)
    if o.get("method") == "initialize":
        print(json.dumps({"id": o["id"], "result": {}}), flush=True)
    elif o.get("method") == "thread/fork":
        print(json.dumps({"id": o["id"], "result": {"thread": {"id": "fork-of-" + o["params"]["threadId"]}}}), flush=True)
F
chmod +x "$T/bin/codex"
export FAKE_LOG="$T/calls.log" PATH="$T/bin:$PATH" PASEO_HOME="$T/paseo" CLAUDE_CONFIG_DIR="$T/claude"
REG="$ROOT/skills/gaseo/scripts/register.sh"
fail=0; chk(){ if grep -qF -- "$2" "$3"; then echo "ok   $1"; else echo "FAIL $1 (missing: $2)"; fail=1; fi; }

unset CLAUDE_CODE_SESSION_ID; : > "$FAKE_LOG"
CODEX_THREAD_ID=test-thread bash "$REG" "$T/work" --title "gaseo Codex 등록" > "$T/o1" 2>&1; echo "exit=$?" >> "$T/o1"
chk codex-detected "DETECTED via=env provider=codex" "$T/o1"
chk codex-registered "REGISTERED session=test-thread" "$T/o1"
chk codex-import "import test-thread --provider codex --cwd $T/work" "$FAKE_LOG"
chk codex-name "agent update agent-123 --name gaseo Codex 등록" "$FAKE_LOG"
chk codex-exit "exit=0" "$T/o1"

# Live Codex thread: paseo refuses ("active writer") -> fork, register the fork with the source label.
: > "$FAKE_LOG"
CODEX_THREAD_ID=live-thread bash "$REG" "$T/work" --title "gaseo 포크 등록" > "$T/o3" 2>&1; echo "exit=$?" >> "$T/o3"
chk codex-forked "FORKED source=live-thread fork=fork-of-live-thread" "$T/o3"
chk codex-fork-registered "REGISTERED session=fork-of-live-thread" "$T/o3"
chk codex-fork-import "import fork-of-live-thread --provider codex --cwd $T/work --label gaseo-source=live-thread" "$FAKE_LOG"
chk codex-fork-exit "exit=0" "$T/o3"

D="$T/claude/projects/$(printf '%s' "$T/work" | sed 's/[^a-zA-Z0-9]/-/g')"; mkdir -p "$D"
echo '{"type":"user","message":{"content":"hello"}}' > "$D/sess-abc.jsonl"
: > "$FAKE_LOG"
CLAUDE_CODE_SESSION_ID=sess-abc CODEX_THREAD_ID=ignored bash "$REG" "$T/work" --title "t" > "$T/o2" 2>&1; echo "exit=$?" >> "$T/o2"
chk claude-detected "DETECTED via=env provider=claude" "$T/o2"
chk claude-import "import sess-abc --provider claude --cwd $T/work" "$FAKE_LOG"
chk claude-exit "exit=0" "$T/o2"
command -v trash >/dev/null && trash "$T"
[ $fail = 0 ] && echo "ALL PASS" || echo "SOME FAILED"; exit $fail
