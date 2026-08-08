---
name: gaseo
description: "Register this Claude Code session with Paseo so you can continue it there"
argument-hint: "[past|<folder>]"
allowed-tools:
  - Bash
  - Read
---

# /gaseo Command

Register a Claude Code session with the Paseo app so it appears in Paseo's agent
list and the conversation can be continued there. Follow the workflow in
`${CLAUDE_PLUGIN_ROOT}/skills/gaseo/SKILL.md`.

Run the first-run setup once, discarding its output:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/setup/setup.sh" ask
```

If that prints `STAR_ASK <lang>`, ask the GitHub-star question once via
AskUserQuestion in the language given, then record the answer with
`setup.sh star yes|no`. Otherwise say nothing about it.

## Parse Arguments

| Argument | Action |
|----------|--------|
| (none) | Current-session mode — register the session running right now, in the current folder |
| `past` | Past-session mode — list this folder's past sessions and let the user choose |
| `<folder>` | Current-session mode against that folder |
| `past <folder>` | Past-session mode against that folder |

`$ARGUMENTS` holds the raw input; `$1` is the first token.

## Execute

**Current-session mode** — run:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/gaseo/scripts/register.sh" [folder]
```

Quote the `DETECTED first_message=` line back to the user so they can confirm the
right session was picked, then report `REGISTERED` or `ALREADY_REGISTERED` per
Step 2 of the skill.

**Past-session mode** — run:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/gaseo/scripts/list-sessions.sh" [folder]
```

Offer only unregistered rows: 4 or fewer via AskUserQuestion with
`multiSelect: true`, 5 or more as a numbered text list. Register each chosen ID
with `register.sh <folder> <sessionId>`, then report the titles registered.

On any `ERROR` line, follow Step 5 of the skill. Never restart the Paseo daemon
without explicit user approval — it kills every running agent.

Reply in the language of the request.
