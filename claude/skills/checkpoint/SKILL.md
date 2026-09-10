---
name: checkpoint
description: Sweep up whatever did not get written down during the session — the plan, the day's loose work, the LOG row — and commit the records, before /clear or /compact. Use when wrapping up a session, when about to clear/compact, or when context is filling up.
---

# /checkpoint — "put things away before bed"

Write down **exactly what git cannot record**, so the next session carries on without losing
anything. Full rules: `docs/HOW-WE-WORK.md`.

⚠️ **This is the FINISH half of one rule.** `HOW-WE-WORK.md` §3: **start the work → write the item;
finish it → update the progress.** The starting half happens during the session, not here — the ▶
heading in `task/` or the steps in `plan/`, then the ▶ row in `LOG.md`. `/checkpoint` only updates
progress on items that already exist. Writing an item here for the first time means §3 was skipped.

⚠️ **Most of this should already be done.** `HOW-WE-WORK.md` §4 says a decision is written the
moment it is made, and §3 says a row in `LOG.md` is written the moment the work STARTS — a plan when
its file is created, loose work when it begins. So `/checkpoint` is a **sweep for what got missed**,
not the moment the record comes into being. If it is finding a lot to do, the rule in §4 is being
skipped during the session.

## Find the docs folder

`<docs>` is **`docs/` at the repo root** — always. Do not search for it, and do not fall back to a
`docs/` folder nested inside a sub-project: those hold product documentation, not the records. If
none of the files exist yet, create them from the templates in `HOW-WE-WORK.md` §8.

⛔ **Never create `PROGRESS.md`, `PROGRESS-archive.md`, or `STATE.md`.** All three were retired —
the first two on 2026-08-06, `STATE.md` on 2026-08-07. Recreating any of them stands back up the
very thing that was cleared away.

## Four steps — do all of them, do not ask first

### 1. Update the plan in flight
Find it the way `/resume` does: the topmost ▶ row in `<docs>/LOG.md` whose link points at a plan
(a ▶ row can also point at the day's task file — that one is step 2). In that plan file:
- Tick the checklist boxes that are done
- **Re-derive every heading's status marker from its boxes** — all ticked ⇒ ✅, otherwise ▶. If the
  marker and the boxes disagree, **the boxes win** and the marker is the thing that is wrong. It is
  a summary for the eye, never a second source of truth.
- **Write down everything decided in the conversation** that is not already there — the date and
  the reason, in whatever section the record shape puts decisions in
- Bring the open questions up to date: add what is newly blocked, remove what Gin has answered
- Bring the verification owed up to date: what was checked, and what still has not been

⛔ **The record's SHAPE lives in `HOW-WE-WORK.md` §8 — read it, follow it, do not guess section
names from memory.** This skill deliberately does not list them: it is shared across every project,
and a project can change its shape (Êm Như Mây did, on 2026-09-09 — the old `## Stage N`,
`## Open questions`, `## Verification owed` are gone, and its commit hook now refuses any heading
outside the shape). A name written here goes stale silently; a pointer to §8 cannot.

The filter is one sentence: **"If the next session carries on without knowing this, will it get it
WRONG?"** Yes → write it. No → skip it.

### 2. Record the day's loose work
Work that belongs to no plan → add it to the day's own file `<docs>/task/<YYYY-MM-DD>.md` (ONE file
per day, not one per piece of work). Inside that file **each piece of work is one `##` heading
carrying its status marker** — `## ▶ …` while it runs, `## ✅ …` when it is done — and the pieces are
separated by `---`. The marker is derived from the boxes under it: every box ticked ⇒ ✅, otherwise
▶; if the two disagree, **the boxes win**. Where a slice was given to an agent, the tick carries the
evidence beside it — the check that ran and what it returned.

If something worth keeping turned up and it belongs in a permanent document (`DESIGN.md`,
`REQUIREMENTS.md`, …), **write it straight into that document** and leave only a pointer in the task
note.

### 2b. Sweep the mechanism file, if the project keeps one
A ruling about **how the app behaves** does not belong in a ticked box — it is unfindable there a
week later. If `HOW-WE-WORK.md` says this project keeps mechanism files (Êm Như Mây does, §7b:
`docs/mechanism/<area>.md`, one per AREA of the app), then before finishing:
- every ruling Gin gave this session is in it, with its reason and the `file:line` that proves it
- a ruling that REPLACED an older one deleted the old wording — two versions of a rule is worse
  than none
- a measurement written there earlier that this session proved stale is corrected, not left standing

### 3. Update the row in `<docs>/LOG.md`
The row **already exists** — it was written the moment the work started, plans and loose work alike.
Usually only the Done column changes (▶ ✅ ⏸ ✖). Old rows **keep their text unchanged**.

⛔ **The Done column goes ✅ only when every item of that work is ticked; until then it stays ▶.**

A piece of work with no row at all means that rule got skipped. Add the row now, at the **top** of
the table, and say so in the reply — work with no row is work that vanishes if the session drops.

⛔ **Every link is labelled with what it points at** — `[plan · docs-restructure]`, not `[plan]`.

### 4. Commit to git — the records only
```
git add <docs>/LOG.md <docs>/plan <docs>/task <docs>/mechanism && git commit
```
Include `<docs>/mechanism` whenever the project has one — committing the plan while leaving the
rulings behind is exactly the split that loses a decision.
- ⛔ **Never auto-commit source code.** Source files still half-done → say so in the reply and
  remind Gin. The count comes from `git status`, so it is never a stored number.
- Commit message in English, saying plainly what was decided.

## Report back to Gin (short)
Where we are · next step · how many questions are waiting on Gin · how many files are uncommitted.

⛔ **Name any agent work the lead has NOT re-measured.** Where a session hands slices to agents, it
can end with a diff that is green on its own checks and never verified against the real thing. That
is the one item the next session must not assume is true — so it is said out loud here, not left to
a tick that only means "the agent said so".
