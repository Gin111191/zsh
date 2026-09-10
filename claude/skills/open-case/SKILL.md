---
name: open-case
description: Mở "phiên bàn bạc" — từ đây CHỈ thảo luận/trao đổi với Gin, KHÔNG thực thi gì; gõ /close-case để chốt toàn bộ nội dung đã bàn thành plan.
---

# /open-case — discussion-only mode (until /close-case)

Gin wants to think out loud across MANY messages before anything is executed. From the moment
this skill is invoked until Gin types `/close-case`, you are in **discussion-only mode**.

## On invocation (do this once, immediately)

1. Create the state marker `_case-open.md` in the CURRENT working folder (the project/subfolder
   you are operating in — CLAUDE.md principle 10), with this skeleton:

   ```markdown
   # CASE OPEN — discussion-only mode (do NOT execute; close with /close-case)
   Opened: <date time>
   Topic: <one line — fill in from Gin's first message, update if it sharpens>

   ## Running log (1–3 lines per exchange — survives /compact; newest last)
   - <point Gin raised> → <direction/option discussed>
   ```

2. Reply briefly: confirm the case is open and invite Gin to talk.

## While the case is open — EVERY message until /close-case

- **Discuss only**: analyze, ask clarifying questions, surface trade-offs, sketch options,
  give a clear opinion when asked. This is the whole job right now.
- **Read-only tools are allowed** when they make the discussion concrete (Read/Grep, SQL
  SELECT, screenshots of the live app). Reading is not executing.
- **Forbidden until /close-case**: editing/creating project files (the marker file is the ONLY
  exception), any mutating Bash/SQL, commits, migrations, deployments, spawning agents or
  workflows, /checkpoint, writing plan files, ExitPlanMode.
- After each exchange, APPEND 1–3 summary lines to the marker's running log — the file is the
  source of truth if the chat gets compacted.
- End EVERY reply with the status line:
  `🔓 CASE ĐANG MỞ — chỉ bàn bạc, chưa thực thi (gõ /close-case để chốt & lên plan)`
- The mode does NOT expire on its own — not after many messages, not after /compact or /clear.
  If a `_case-open.md` exists in the working folder, the mode is ON. Honor it.
- If Gin asks you to execute something mid-case: remind him the case is open and ask whether to
  `/close-case` first. Do not execute. (Exception: Gin explicitly changing these mode rules /
  skill files themselves — that is tooling config, apply it; defer any commit to after close.)
- **Nesting (Gin 16/7):** `/open-feedback` MAY open INSIDE an open case (one level) — Gin often
  wants to dump many info messages mid-discussion. While nested, feedback's listen-only rules
  take precedence; on `/close-feedback` the digest feeds the CASE and discussion-only mode
  resumes. The reverse (opening a case inside feedback) is NOT allowed — ask.
