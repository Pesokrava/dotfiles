---
name: review-cycles
description: Use when the user asks for a fixed number of review-and-fix rounds on code they have written — "run 2 review cycles", "3 rounds of review", "/review-cycles 2", "review and address, twice", "keep reviewing and fixing N times" — or whenever both a Linus-style review and a fleet review are wanted on the same work.
---

# review-cycles

## Overview

Run **N** review-and-fix cycles over the working code. One cycle is:

```
review (linus-review + review-fleet) → address findings → verify
```

`N` cycles means the reviewers run `N` times and the fixer runs `N` times. Cycle 2
exists to catch what cycle 1's *fixes* broke — that is the whole point, so a clean
cycle 1 is not a reason to skip cycle 2.

**The core rule: the number of cycles is set by the user, not by how the code looks
to you.** You do not get to end early because the findings were "all minor" or
because you are confident the fixes were correct.

## Inputs

| Input | Default |
|---|---|
| `N` — number of cycles | **2** if the user said "cycles" without a number |
| Scope — what to review | the current branch diff vs. its merge base, unless the user names a PR, path set, or commit range |

State both back to the user in one line before cycle 1, then start. Do not ask
permission to begin.

## The cycle

Repeat exactly `N` times. Announce `### Cycle k/N` at the top of each.

### 1. Freeze

Record the scope and `git rev-parse HEAD` for this cycle. **Change no files** until
both reviews of this cycle are complete — both reviewers must judge identical code,
otherwise their findings can't be merged or trusted.

### 2. Review — both, every cycle

**REQUIRED SUB-SKILL:** `review-fleet`, invoked in **review-only mode** (its §3A:
single round, strictly read-only, no internal fix loop). Say "review-only" when you
invoke it. Its own fix-loop must stay off — this skill's step 3 is the single
accountable fixer.

**REQUIRED SUB-SKILL:** `linus-review`, on the same frozen scope.

Run the fleet first (it produces a report file), then the Linus pass — you cannot
read code carefully while orchestrating a fleet. Both run in **every** cycle. One
reviewer does not stand in for the other: the fleet gives breadth across specialist
lanes with evidence gates; Linus gives one senior pass on correctness, data
structures, and taste, and returns a merge verdict.

### 3. Merge findings

Build one list for the cycle:

- Same `file:line` + same defect from both reviewers → one item, highest severity wins.
- Keep the reviewer names on each item; disagreement between them is signal, not noise.
- Sort BLOCKER → MAJOR → MINOR (fleet severities map onto Linus's).

### 4. Address

Fix, in order:

- **Every BLOCKER and MAJOR.** No deferrals.
- **MINOR** only when the fix is smaller than the argument about it.

A finding you decline must be listed in the cycle log with the technical reason.
"Out of scope" is a reason only if the finding is genuinely outside the frozen scope
— then say which ticket it belongs to.

### 5. Verify

Run the project's build and tests. Paste the actual result. If they fail, that
failure is a cycle-`k` finding: fix it inside this cycle, before cycle `k+1`.

### 6. Log

One block per cycle:

```
Cycle k/N — <n> findings (<b> blocker, <m> major, <x> minor)
  fixed:    file:line — one line each
  declined: file:line — one line each, with the reason
  verify:   <build/test command> → pass | fail
```

## Stopping

Complete all `N` cycles. The one legitimate early exit:

> A cycle's reviewers return **zero** findings **and** you changed no files in the
> previous cycle.

Then the remaining cycles would re-review byte-identical code. Stop, and say
explicitly which cycles you skipped and why. Any other reason to stop early is a
rationalization — see the table.

## Output

After the last cycle:

| Cycle | Findings | Fixed | Declined | Linus verdict | Tests |
|---|---|---|---|---|---|
| 1/2 | 7 | 6 | 1 | MERGE AFTER FIXES | pass |
| 2/2 | 2 | 2 | 0 | MERGE | pass |

Then: the final Linus verdict, every still-open declined finding, and one line on
whether the code is merge-ready. Do not commit or push unless the user asked.

## Red flags — you are about to break the contract

- "Cycle 1 was clean, so cycle 2 is a waste" — cycle 2 reviews *your fixes*.
- "The fleet already covers what Linus would say" — run both.
- "I'll fix these as the reviewers find them" — that unfreezes the code mid-cycle.
- "I'll re-review the original diff" — every cycle reviews the code as it stands *now*.
- "This finding is minor, I'll note it instead of fixing" — for BLOCKER/MAJOR, no.
- "Let me just let review-fleet's own loop handle the fixes" — two fixers, one file.
- "Tests were passing before my fix, no need to re-run" — re-run. Every cycle.

**All of these mean: go back and run the cycle as written.**

## Rationalizations to reject

| Thought | Reality |
|---|---|
| "Nothing changed, so cycle 2 will find nothing" | Then it costs one round and proves it. If files *did* change, cycle 2 is the only thing reviewing them. |
| "The remaining findings are all style" | Fine — log them as declined MINORs with reasons. That is not the same as skipping a cycle. |
| "Diminishing returns after one round" | The fixes are the least-reviewed code in the diff. They get a round. |
| "I can review it myself instead of spawning the fleet" | You wrote it. Author review finds the bugs you already thought about. |
| "N cycles will take too long" | The user chose N knowing that. If it's genuinely infeasible, say so before cycle 1, not after. |
| "Marking it won't-fix gets me to a clean cycle" | A clean cycle is an outcome, not a target. Gaming it hides a real defect. |

## Common mistakes

- **Merging severities wrong.** A fleet MEDIUM and a Linus MAJOR on the same line is one MAJOR, not two items.
- **Losing the frozen scope.** After cycle 1's fixes, the diff grew. That is correct — review the grown diff, don't re-freeze to the old base.
- **Silent scope drift.** Fixing a BLOCKER often reveals adjacent rot. Fix the finding; log the rot as a separate declined item with a ticket, don't refactor sideways.
- **Skipping verify on the last cycle.** The last cycle's fixes are the ones nobody has tested.
