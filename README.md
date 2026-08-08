English | [한국어](README.ko.md) | [中文](README.zh.md) | [日本語](README.ja.md) | [Español](README.es.md)

# gaseo (가세오)

<p align="center">
  <img src="assets/gaseo-hero-01.png" alt="gaseo" width="320">
</p>

> **Send the session you're in right now over to Paseo — and pick it up there.**

[Paseo](https://paseo.app) lists only the agents it launched itself. A session you started by typing `claude` in a terminal never shows up, and there is no way to resume it from the app. `gaseo` closes that gap: say "가세오" and the conversation you are having this second appears in Paseo under its own title, ready to continue.

[Quick Start](#quick-start) • [Why gaseo?](#why-gaseo) • [How it works](#how-it-works) • [Features](#features) • [Commands](#commands) • [Requirements](#requirements)

---

## Quick Start

### 1. Add the marketplace

```
/plugin marketplace add https://github.com/fivetaku/gptaku_plugins.git
```

### 2. Install

```
/plugin install gaseo
```

### 3. Restart Claude Code

(New commands only register after a restart.)

### 4. Run

```
/gaseo
```

That's it — the session you're in is now in Paseo. Open the app and keep talking.

To bring in older conversations from this folder instead:

```
/gaseo past
```

Or just say it:

- "파세오로 가세오"
- "이 세션 파세오로 가세오"
- "가세오 해줘"
- "register this session to paseo"
- "import my past sessions into paseo"

---

## Why gaseo?

**Your terminal sessions are invisible to Paseo.** Paseo shows the agents it started. Everything you ran yourself from a shell — which is most of your real work — simply isn't in the list, and there's no import button in the UI.

**It's a link, not a copy.** `gaseo` runs `paseo import`, which writes nothing but a pointer to the session ID. Your transcript stays exactly where Claude Code put it. Archive the agent in Paseo later and the original conversation is still untouched.

**Walk away from the desk mid-task.** Register the session, close the laptop, and carry on from the Paseo app — same conversation, same history, no re-explaining.

**Nothing gets registered twice.** Sessions Paseo already knows about — including the ones Paseo launched — are detected and skipped.

**Folders Paseo has never seen are fine.** The workspace is created on import.

---

## How it works

```
/gaseo
  → find this folder's session directory
      ~/.claude/projects/<folder path with non-alphanumerics as '-'>/
  → $CLAUDE_CODE_SESSION_ID if its transcript is here, else newest .jsonl
  → already in ~/.paseo/agents? → skip, report, done
  → paseo import <sessionId> --provider claude --cwd <folder>
  → appears in Paseo under its original title
```

Paseo stores no conversation of its own. Each agent record holds a
`persistence.nativeHandle` pointer to a Claude session ID — which is why import
is instant, needs no daemon restart, and never duplicates your data.

---

## Features

| Feature | Description |
|---------|-------------|
| Current-session register | `/gaseo` picks up the session you're talking in, no ID needed |
| Past-session picker | `/gaseo past` lists earlier sessions with first message, time and registration status |
| Duplicate-safe | Already-registered sessions are reported, not re-imported |
| New workspaces | Imports into folders Paseo has never seen, creating the workspace |
| Link, not copy | Original transcripts are never moved, altered or duplicated |
| Confirmable detection | Shows the first message of the session it picked before you rely on it |

---

## Commands

| Command | Description |
|---------|-------------|
| `/gaseo` | Register the current session |
| `/gaseo past` | List this folder's past sessions and choose which to register |
| `/gaseo <folder>` | Register the current session of another folder |
| `/gaseo past <folder>` | Past-session picker for another folder |

### Natural language triggers

- `/gaseo`, "파세오로 가세오", "이 세션 파세오로 가세오", "가세오 해줘", "파세오에 등록해줘"
- "과거 세션 파세오로 가져와줘", "지난 대화 파세오에 추가해줘"
- "register this session to paseo", "send this session to paseo"
- "import my past sessions into paseo"

---

## Notes and limits

**How the current session is identified.** `gaseo` reads `$CLAUDE_CODE_SESSION_ID`, the ID Claude Code exports for the live session, and confirms a matching transcript exists in the folder. Only when that is unavailable does it fall back to picking the most recently written transcript — a guess, because background subagents and hook-spawned sessions write into the same directory and are often newer. The output labels which route was used (`via=env` or `via=mtime`); on a `via=mtime` guess, check the first message it prints, or use `/gaseo past` to choose explicitly.

**Claude sessions only.** Codex sessions are stored by date rather than by folder, so the folder-to-session mapping this relies on doesn't apply to them yet.

**The daemon is never restarted for you.** If `paseo import` fails because the daemon is down, `gaseo` reports it and stops. Restarting kills every running agent, so that call stays yours.

---

## Requirements

- [Claude Code](https://docs.anthropic.com/claude-code) CLI
- [Paseo](https://paseo.app) installed, with its daemon running (`paseo status`)
- The `paseo` CLI on `PATH`, or at its default install location

---

## License

MIT — see [LICENSE](LICENSE) and [DISCLAIMER.md](DISCLAIMER.md).

---

<div align="center">

**Your session doesn't have to stay in the terminal.**

</div>
