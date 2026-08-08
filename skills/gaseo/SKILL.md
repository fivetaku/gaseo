---
name: gaseo
description: Registers a Claude Code session with the Paseo app so it appears in Paseo's agent list and the conversation can be continued there. Handles both the session running right now and past sessions of a folder, via `paseo import` (a pointer, not a copy). Korean triggers "파세오로 가세오", "이 세션 파세오로 가세오", "가세오 해줘", "파세오에 등록해줘", "과거 세션 파세오로 가져와줘", "지난 대화 파세오에 추가해줘". English triggers "gaseo", "register this session to paseo", "send this session to paseo", "import my past sessions into paseo". Not for creating or managing new Paseo agents — the `paseo` skill owns that.
---

# gaseo

Register a Claude Code session with Paseo so it shows up in the app and can be
continued there. `paseo import` writes only a pointer to the session ID, so the
original transcript is never moved, copied, or altered — archiving the agent in
Paseo does not delete the session.

Paseo lists only the agents it launched itself. A session started by running
`claude` in a terminal is invisible to it, with no way to resume. That is the
gap this skill closes.

## Workflow

### Step 1 — Decide the mode

Read the request:

- `/gaseo` / "파세오로 가세오" / "이 세션 등록해줘" / "파세오에 추가해줘" → **current-session mode** (Step 2)
- "과거 세션 가져와줘" / "지난 대화 등록해줘" / `past` → **past-session mode** (Step 3)

The target folder is whichever folder the user names; with none named, use the
current working directory.

### Step 2 — Register the current session

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/gaseo/scripts/register.sh" [folder]
```

Read the output:

| Line | Meaning | Response |
|------|---------|----------|
| `DETECTED via=env …` | Resolved from Claude Code's own session ID | Reliable — mention the title in passing |
| `DETECTED via=mtime …` | Guessed from the newest transcript | Quote the first message back and have the user confirm before relying on it |
| `REGISTERED session=… cwd=…` | Success | Report that it now appears in Paseo under its original title |
| `ALREADY_REGISTERED session=…` | Session is already a Paseo agent | Report that nothing was duplicated |
| `ERROR …` (stderr, exit 1) | Failure | Go to Step 5 |

How the current session is resolved, in order:

1. **`$CLAUDE_CODE_SESSION_ID`** — Claude Code exports the live session's own ID.
   Used only when a matching transcript exists in the target folder's project
   directory, since the variable can survive into unrelated child contexts and
   the named folder may not be the one this session runs in.
2. **Newest transcript** — a live session's `.jsonl` is appended to continuously,
   so the most recently modified file is usually the current one. This is a
   guess: background subagents and hook-spawned sessions write into the same
   directory and are frequently newer. When the output says `via=mtime`, confirm
   before trusting it, or use `/gaseo past` to pick explicitly.

### Step 3 — List past sessions

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/gaseo/scripts/list-sessions.sh" [folder] [limit]
```

Default limit is 10. Each row is
`n | sessionId | modified | registered|- | first user message`.

Present only the **unregistered** rows as choices; show already-registered ones
as context but never offer them.

- **4 or fewer unregistered** → AskUserQuestion with `multiSelect: true`. Use the
  first message as the option label (shortened), the date as the description.
- **5 or more** → print the numbered list as text and ask which numbers to
  register ("등록할 번호를 말해주세요 — 예: 1, 3, 5 / 전부"). AskUserQuestion
  caps at 4 options, so a list is the only way past that.

### Step 4 — Register the chosen past sessions

Call the same script once per chosen session ID:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/gaseo/scripts/register.sh" <folder> <sessionId>
```

The folder must be the one the session actually ran in — the same folder the
list came from — because Paseo keys the agent by `--cwd`. A folder Paseo has
never seen is fine: the workspace is created on import.

Report the count registered and each title on its own line.

### Step 5 — Errors

| Error | What to tell the user |
|-------|----------------------|
| `no session directory for this folder` | Claude Code has never run in that folder. Ask for the right path. |
| `session <id> not found` | That ID is not in this folder's history. Re-run Step 3 and pick again. |
| `paseo CLI not found` | Paseo is not installed, or its CLI is not on `PATH`. Point to https://paseo.app and check for a `paseo` symlink in `~/.local/bin`. |
| `paseo import failed` | The daemon is likely down. Run `paseo status` and report what it says. **Never restart the daemon without explicit approval — a restart kills every running agent.** |

## Scripts

- `scripts/register.sh` — detects the current session (or takes an explicit ID),
  skips duplicates, runs `paseo import`. Args: `[folder] [sessionId]`
- `scripts/list-sessions.sh` — recent sessions of a folder with registration
  status. Args: `[folder] [limit]`
- `scripts/paseo-common.sh` — shared helpers (CLI lookup across macOS/Linux/
  Windows, session-directory naming, mtime, dedup). Sourced by both scripts.

## How it works

- Paseo stores no conversation of its own. Each agent record at
  `~/.paseo/agents/{workspace}/{agentId}.json` holds a `persistence.nativeHandle`
  pointer to a Claude session ID.
- Claude Code keeps transcripts at
  `~/.claude/projects/{absolute path with every non-alphanumeric char replaced by '-'}/{sessionId}.jsonl`.
  Underscores become `-` too, so `My_Repo` maps to `My-Repo`.
- Duplicate detection greps `~/.paseo/agents` for the session ID, which also
  covers sessions Paseo launched itself.
- Only the `claude` provider is supported. Codex sessions are stored by date
  rather than by folder, so folder-to-session mapping does not apply to them.
