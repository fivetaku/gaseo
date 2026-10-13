# Changelog


## 0.2.2 — 2026-10-13
- **gptaku-core 라우팅 적용.** `gptaku-core`를 의존성으로 선언하고 `routing.json`을 추가해, 이 플러그인 스킬에 맞는 요청이 오면 직접 처리하거나 기본 도구를 쓰기 전에 이 스킬을 먼저 쓰게 했다. 기존 사용자는 업데이트 후 `/reload-plugins`를 실행하거나 플러그인을 다시 설치해야 gptaku-core가 함께 설치된다. 끄기: `GPTAKU_ROUTER=off`.

## 0.2.1 — 2026-08-27

- **제목 형식을 못박았다.** 0.2.0의 지시문은 "30자 안팎 요약"이라는 산문
  가이드라인뿐이어서, 결국 요청 문장을 줄인 제목이 나왔다. 이제 형식이
  `<대상> <한 일>` 명사구 15~30자로 규정되고, 두 요소가 모두 필수다 —
  대상만 있으면 같은 플러그인 세션끼리 구분이 안 되고, 한 일만 있으면
  어디를 건드렸는지가 빠진다. 첫 메시지 → 제목 변환 예시 4개를 추가했다.

## 0.2.0 — 2026-08-27

- **등록 시 제목을 붙인다.** `paseo import`가 만드는 워크스페이스는 제목이
  비어 있어 깃 브랜치 이름으로 표시된다 — 한 레포에서 세션을 여러 개 보내면
  Paseo 앱에 `main`이 줄줄이 쌓여 어느 게 뭔지 구분되지 않았다.
  `register.sh`에 `--title "<text>"`를 추가하고, 등록 직후 그 제목을
  에이전트 이름(`paseo agent update --name`)과 워크스페이스 제목
  (`paseo workspace rename`)에 함께 적용한다.
- 커맨드·스킬은 이제 등록 전에 제목을 직접 쓰도록 지시한다 — 첫 메시지를
  그대로 복사하지 말고(`/model`, 붙여넣은 경로, 잘린 장문이 그대로 이름이
  되던 문제) 무슨 작업이었는지 30자 안팎으로 요약한다.
- 이미 등록된 세션에 `--title`을 다시 주면 제목만 갱신된다 — 잘못 붙은
  이름을 고치는 경로.

## 0.1.4 — 2026-08-24

- **Fix: first-run setup could wipe `settings.json`** — if the file was corrupted or contained comments (JSONC), the shared update-notifier installer re-wrote it as an empty object plus the hook, silently destroying all user settings. It now refuses to write when parsing fails and writes atomically (tmp + rename). Marketplace-wide propagation of the fix found in the ddiring v0.1.1 external review; reproduction-verified.

## 0.1.3 — 2026-08-08

- Dropped 가세요 from the trigger lists entirely. The triggers are `/gaseo` and
  가세오 phrasings ("파세오로 가세오", "이 세션 파세오로 가세오", "가세오 해줘") —
  keeping the old spelling around as an alternate only muddied which name is
  the real one. Supersedes the note in 0.1.2.

## 0.1.2 — 2026-08-08

- Corrected the Korean name: the plugin is **가세오**, not 가세요 — it rhymes with
  파세오 (Paseo). Renamed across all five READMEs and the skill, and regenerated
  the hero image with the corrected wordmark.
- "파세오로 가세요" stays in the trigger lists as an alternate phrasing, since
  that is the natural Korean imperative users actually say.

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
