#!/usr/bin/env bash
# Fake-paseo regression test for register.sh (Claude + Codex paths). Never touches a real daemon.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
T="$(mktemp -d)"
mkdir -p "$T/bin" "$T/work" "$T/claude/projects" "$T/paseo/agents"
cat > "$T/bin/paseo" <<'F'
#!/usr/bin/env bash
echo "$@" >> "$FAKE_LOG"
case "$1" in import) echo '{"agentId":"agent-123"}';; esac
F
chmod +x "$T/bin/paseo"
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

D="$T/claude/projects/$(printf '%s' "$T/work" | sed 's/[^a-zA-Z0-9]/-/g')"; mkdir -p "$D"
echo '{"type":"user","message":{"content":"hello"}}' > "$D/sess-abc.jsonl"
: > "$FAKE_LOG"
CLAUDE_CODE_SESSION_ID=sess-abc CODEX_THREAD_ID=ignored bash "$REG" "$T/work" --title "t" > "$T/o2" 2>&1; echo "exit=$?" >> "$T/o2"
chk claude-detected "DETECTED via=env provider=claude" "$T/o2"
chk claude-import "import sess-abc --provider claude --cwd $T/work" "$FAKE_LOG"
chk claude-exit "exit=0" "$T/o2"
command -v trash >/dev/null && trash "$T"
[ $fail = 0 ] && echo "ALL PASS" || echo "SOME FAILED"; exit $fail
