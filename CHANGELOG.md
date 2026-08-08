# Changelog

## 0.1.1 — 2026-08-08

- Current-session detection now uses `$CLAUDE_CODE_SESSION_ID`, the ID Claude
  Code exports for the live session, and falls back to the newest-transcript
  guess only when that is unavailable or points outside the target folder.
  The old guess reliably mis-fired: background subagents and hook-spawned
  sessions write transcripts into the same directory and are often newer, so
  `/gaseo` could register a security-review sidecar instead of your conversation.
- The `DETECTED` line now reports `via=env`, `via=mtime` or `via=explicit`, so a
  guessed match is visibly a guess.

## 0.1.0 — 2026-08-08

- First release. `/gaseo` registers the Claude Code session you are talking to
  right now with the Paseo app, so it appears in Paseo's list and you can carry
  the same conversation on from there.
- `/gaseo past` lists a folder's earlier sessions — with first message, time and
  registration status — and registers the ones you pick.
- Registration goes through `paseo import`, which stores a pointer to the
  session ID rather than a copy. The original transcript is never moved or
  altered, and archiving the agent in Paseo does not delete it.
- Sessions already known to Paseo (including ones Paseo launched) are detected
  and skipped instead of being duplicated.
- A folder Paseo has never seen is accepted — the workspace is created on
  import.
- Claude provider only. Codex sessions are stored by date rather than by folder,
  so folder-to-session mapping does not apply to them yet.
