---
name: resume
description: Open the session — work out where we are from git and the plan that is in flight, then summarize "where we are + next step" without needing the transcript. Use at the start of a new session, after /clear or /compact, or when asked "where are we". The other half of /checkpoint (IN ↔ OUT).
---

# /resume — "read the notes in the morning"

There is no note to read. The state is **worked out**, in four steps, and then **stop right there**.
Do not read other documents. Full rules: `docs/HOW-WE-WORK.md`.

## Find the docs folder

`<docs>` is **`docs/` at the repo root** — always. Do not search for it, and do not fall back to a
`docs/` folder nested inside a sub-project: those hold product documentation, not the records.

⚠️ If there is no `<docs>/LOG.md`: do not go looking for `PROGRESS.md` or `STATE.md`. Both were
retired (2026-08-06 and 2026-08-07). Read `git log --oneline -8`, say plainly that **there is no
record yet**, and ask Gin.

## 1. Ask git

```
git --no-pager log --oneline -8
git --no-pager status -s
```

That is where the last commit and the uncommitted count come from. They are never stored anywhere,
so they can never be out of date.

## 2. Read `<docs>/LOG.md` — every row marked ▶

Each ▶ row is a piece of work still in flight — a row is written the moment work STARTS, plans and
loose work alike. So the link in its last column points at **either** a plan file in `<docs>/plan/`
**or** the day's file in `<docs>/task/`, and the label on the link says which. There is usually
one ▶ **plan** row; there may be two. Three plan rows is the signal that this way of working has
broken (§9). The day's task row is not counted — §9 counts plan files.

No ▶ row means nothing was left in flight. Say that plainly, report from git alone, and ask Gin what
is next — do not go hunting through `<docs>/task/` for work the log does not claim is running.

## 3. Open what the ▶ rows point at — plan files and task files alike

- **The next step** comes from the **topmost** ▶ row: the first unticked box in the file it points
  at. **A ▶ heading with no boxes under it is work that had only just begun** — the heading itself
  is then the whole of what is known, so report it as barely started and say so plainly rather than
  reading more into it.
- ⚠️ **`## Open questions` and `## Verification owed` are collected from EVERY ▶ row, not just the
  topmost — task rows count too.** A question blocking the second one is still blocking, and reading
  only the top one hides it — measured 2026-08-07, when four questions sat in the second ▶ plan.
- **The status marker on each heading says where to look without reading the whole file** — on each
  `## Stage N — …` in a plan, and on each piece of work in a task file. The first heading still
  marked ▶ is the unfinished one. The marker is only a summary: if it disagrees with the boxes under
  it, **the boxes win**.
- **`## Pitfalls already paid for`** in the plan you are about to work on: what not to walk into
  again.

## 4. Report back — short, ≤8 lines

- **Where we are** (1–2 lines)
- **The exact next step** — copy it from the first unticked box
- **Waiting on Gin** — the questions that are blocking
- **Verification owed**, if any
- Ask: carry on with that step, or switch to something else?

⚠️ `/checkpoint` and `/resume` are **shared across every project** — changing one changes every
other project too.

## Only read more when you really have to

Everything needed is in git plus the one file the ▶ row points at. If it takes a **third** file
before you understand where you are ⇒ this way of working has broken, tell Gin (see
`HOW-WE-WORK.md` §9).

## What this used to do, and why it no longer does

There used to be a `STATE.md` holding a stored copy of all of the above, and a step that compared
its `Last commit` line against git to catch it going stale. Both are gone. **The check existed only
because the copy existed** — and the copy did go stale: on 2026-08-07 it claimed commit `18f8b45`
and 0 uncommitted files while git said `bb504c7` and 156.
