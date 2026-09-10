---
name: close-case
description: Đóng phiên /open-case — gom TOÀN BỘ nội dung đã bàn (từ lúc mở đến giờ) thành một plan mạch lạc trình Gin duyệt.
---

# /close-case — close the discussion, synthesize the plan

Gin has finished deliberating. Turn the WHOLE discussion into one coherent plan.

## Steps

1. **Gather everything**: read `_case-open.md` (running log) in the working folder AND re-read
   the conversation from `/open-case` to now — including any nested /open-feedback digests
   (their items are case material). Merge all — files win where compaction ate the chat. Nothing Gin said in the case window may be dropped; if two points conflict, the
   LATER one wins (note the override in the plan).
2. **Synthesize ONE plan** covering all agreed points: goal, decisions made during the
   discussion (with the "why" captured from the chat), concrete steps, verification, open
   questions that were NOT settled (list them — do not silently resolve them).
3. **Follow Gin's plan law** (plan-mode habit): explain the plan simply IN CHAT first as a
   text-only message and wait for his OK before writing the plan file / calling ExitPlanMode.
   Execution starts only after he approves.
4. After the plan file exists, DELETE `_case-open.md` (its content now lives in the plan) and
   drop the case status line from replies.

If there is no `_case-open.md` and no /open-case in the visible conversation, say so and ask
what to do — do not invent a case.
