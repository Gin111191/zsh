---
name: close-feedback
description: Đóng phiên /open-feedback — tổng hợp TOÀN BỘ các tin đã ghi thành một bản digest theo chủ đề, rồi mới bắt đầu trả lời/thảo luận từng điểm với Gin.
---

# /close-feedback — synthesize everything, then start talking

The listen-only window ends here. Now digest, then discuss.

## Steps

1. **Gather everything**: read the full log in `_feedback-open.md` AND the conversation from
   `/open-feedback` to now; merge (file wins where compaction ate the chat). Every message
   must appear in the digest — dropping one is a failure.
2. **Produce ONE consolidated digest** in chat, grouped by topic, numbered, each item tagged:
   - `❓` — questions to ANSWER (Gin's ❓ rule: answer/clarify, do not execute);
   - `🛠` — feedback/requests that imply work (needs discussion + his go before executing);
   - `ℹ️` — pure information to remember.
3. **Now start the discussion**: answer the ❓ items, give your assessment of the 🛠 items with
   a clear recommendation and what you'd do next. STILL do not execute changes — normal rules
   resume, so execution needs Gin's explicit go (or a plan he approves).
4. **If nested inside an open case** (`_case-open.md` present): after delivering the digest,
   RESUME the case's discussion-only mode — no execution, case status line returns; append the
   digest's headline items to the case's running log (they are now case material, gathered at
   /close-case). Skip registry folding here — it happens when the case's plan lands.
5. Housekeeping after the digest is delivered: fold durable decisions per the folder's registry
   law if one exists (e.g. `_pending.md`; skip when nested — see step 4), then DELETE
   `_feedback-open.md` and drop the feedback status line.

If there is no `_feedback-open.md` and no /open-feedback in the visible conversation, say so
and ask what to do — do not invent a session.
