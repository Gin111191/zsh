---
name: open-feedback
description: Mở "phiên tiếp nhận" — Gin nói nhiều tin liên tiếp, bạn CHỈ ghi nhận từng tin (không trả lời, không bàn luận, không thực thi); gõ /close-feedback để tổng hợp rồi mới thảo luận.
---

# /open-feedback — listen-only mode (until /close-feedback)

Gin wants to dump information across MANY messages without being interrupted. From this moment
until he types `/close-feedback`, you only LISTEN and RECORD.

## On invocation (do this once, immediately)

1. Create the state marker `_feedback-open.md` in the CURRENT working folder:

   ```markdown
   # FEEDBACK OPEN — listen-only mode (record verbatim; close with /close-feedback)
   Opened: <date time>

   ## Log (verbatim, numbered — survives /compact)
   ```

2. Reply with one short line: you are listening, and how to close.

## While the session is open — EVERY message until /close-feedback

- **Do NOT answer, discuss, assess, or act on the content** — even if it contains questions,
  bug reports, or things that look urgent. Everything is information-only until close.
- APPEND each message **verbatim** to the marker log, numbered (`### N — <time>`), before
  replying. The file is the source of truth if the chat gets compacted.
- Reply with ONLY this single line (no analysis, no preview of opinions):
  `📝 Đã ghi nhận (#N) — đang nghe tiếp (gõ /close-feedback để tôi tổng hợp & thảo luận)`
- No other tools, no side work, no checkpoints while the session is open.
- The mode does NOT expire on its own — many messages, /compact, /clear: if
  `_feedback-open.md` exists in the working folder, the mode is ON. Honor it.
- **Nesting (Gin 16/7):** this skill MAY be opened INSIDE an open case (`_case-open.md`
  present) — note `Nested in case: yes` in the marker header. While nested, listen-only rules
  take precedence over case discussion; the ack line becomes:
  `📝 Đã ghi nhận (#N) — đang nghe tiếp (trong CASE; gõ /close-feedback để tổng hợp)`.
  On `/close-feedback` the digest feeds the case and discussion-only mode resumes.
