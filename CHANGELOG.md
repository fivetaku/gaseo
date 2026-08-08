# Changelog

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
