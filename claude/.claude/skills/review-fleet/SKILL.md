---
name: review-fleet
description: Use when the user invokes "/review-fleet", asks for a fleet review, or asks to run a parallel multi-reviewer code review on a repo, branch, PR, diff, or file set. Also use for review-only, audit, report-only, or read-only fleet sessions.
---

# review-fleet — Parallel Multi-Reviewer, Multi-Round Code Review

`review-fleet` runs a fleet of read-only specialist reviewers in parallel,
mechanically merges and **adversarially verifies** what they find, fixes only
what survives verification, then re-reviews the fixed code to confirm the fixes
worked **and** to catch any new problems the fixes introduced — looping up to 5
rounds before handing control to the user.

The design goal is the highest-signal review possible: **find every issue that
matters — especially the high-severity ones — with near-zero false positives.**
The two are not in tension here. **Recall** comes from exhaustive
investigation: whole-file and cross-file context, cross-area consultation on
anything that straddles lanes, and reviewers digging as deep as the problem
needs (token cost is not a reason to look less). **Precision** comes from the
gates — evidence grounding, the per-severity confidence floors, and adversarial
verification — *not* from reviewers staying quiet. Industry-best reviewers run
95–98% precision and trust collapses nonlinearly past a ~10% false-positive
rate, so the gates below are strict; but they are what let the fleet be
aggressive on recall without flooding the human with noise. Surface every
important issue you can ground; let the gates — not timidity — remove the wrong
ones.

This file is the **orchestrator**, run by the main agent. Per-reviewer
instructions live in `reviewers/<area>.md`. The binding behavior + output
schema every reviewer obeys lives in `reviewers/_contract.md` (read it — the
field names, enums, confidence floors, and the single-JSON-object output format
used throughout this orchestrator are defined there). Report shapes live in
`templates/round-report.md` and `templates/final-status.md`.

---

## 0. Operating principles (read first)

- **Reviewers never edit code.** They are read-only, evidence-gated analysts
  (`_contract.md` §1). Only the orchestrator edits files. This prevents parallel
  agents from fighting over the same files and keeps a single accountable fixer.
- **Evidence before verdict.** A finding exists only if every claim it makes is
  grounded in verbatim quoted source (`_contract.md` §1.2, §4). Ungrounded
  findings are rejected at CONSOLIDATE, not surfaced with a caveat.
- **Adversarial verification gates every fix.** No above-floor finding is fixed
  until it is independently re-checked and survives a refutation attempt
  (Phase B2). This is the primary false-positive killer; use the ensemble to
  *falsify*, never to democratically average.
- **Cross-area consultation on complex findings.** When a finding is
  cross-cutting — its real severity, likelihood, or blast radius depends on a
  lane other than the one that spotted it — the finding reviewer consults the
  owning sibling area(s), directly (agent-to-agent messaging where supported) or
  by spawning a dedicated read-only reviewer of that area, and folds the combined
  assessment into the finding (`_contract.md` §1.6a). This widens coverage on the
  issues most likely to be under-rated.
- **Recall is bought by investigation, precision by the gates.** Reviewers
  investigate exhaustively and never suppress a real, grounded in-lane issue;
  the confidence floors and adversarial verification — not reviewer timidity —
  are what keep the false-positive rate near zero.
- **Confidence-gated.** Reviewers self-gate per severity floor; the orchestrator
  re-gates at merge. Below floor ⇒ the finding does not drive a fix.
- **When applying fixes, work on a dedicated git branch.** Before the first
  auto-fix round, create `review-fleet/<timestamp>` (or ask the user for a
  branch). Commit once per round so every round is revertible and the user can
  diff exactly what changed. `review-only` and `propose-only` remain read-only:
  no branch, no edits, no commits.
- **Keep the build green every round.** After each fix phase, run the project's
  build, linters, type-checker, and tests. A fix that breaks them is itself a
  defect — fix or revert it within the same round before recording.
- **Never destructive.** No force-push, no history rewrite, no deleting files
  outside scope, no dependency upgrades unless a finding requires it and the
  user approved fixes. Never push or merge without explicit approval.
- **Determinism over chatter.** Reviewers return findings in the exact
  `_contract.md` §3/§6 schema so the orchestrator merges them mechanically.

---

## 1. Trigger & intake

Activate when the user says `/review-fleet`, "fleet review", or asks to run the
parallel multi-reviewer review.

### Codex subagent approval preflight

In Codex, this workflow requires `multi_agent_v1.spawn_agent` for the reviewer
fleet. It may also use read-only verifier agents and reviewer-internal helper
agents. Codex policy requires explicit user authorization for subagents,
delegation, or parallel agent work. Therefore, before reading files, resolving
scope, creating branches, or doing any other intake, ask immediately:

> `review-fleet uses parallel read-only subagents for the reviewer fleet and may use read-only verifier/helper subagents. Do you approve spawning those subagents for this run?`

If the user's triggering message already explicitly approves parallel/subagent
work, record that approval and continue. Otherwise wait for a clear yes before
continuing. Do not run a degraded single-agent version by default; that loses
the core behavior of the skill. If the user declines, stop and offer to run a
different ordinary review workflow instead.

After approval, if `multi_agent_v1` is not already available in Codex, use
`tool_search` to load the subagent/parallel-agent tools before continuing.

Before round 1, establish (ask only for what you cannot infer):

1. **Scope** — one of: whole repo · a directory · an explicit file list · a
   branch-vs-base diff · a PR · the working-tree changes. Resolve it
   **deterministically, by scope**:
   - **PR / branch-vs-base:** `BASE_REF = git merge-base <target-branch> HEAD`;
     `TARGET_FILES = git diff --name-only <BASE_REF>...HEAD`; the change each
     reviewer reads is `git diff <BASE_REF>...HEAD`.
   - **Working-tree changes:** `BASE_REF = HEAD`; `TARGET_FILES = git status
     --porcelain` (staged + unstaged); the change is `git diff HEAD`.
   - **Whole repo / a directory / an explicit file list:** there is **no diff
     baseline** — `TARGET_FILES` = the named files (or all tracked files under the
     path/repo); set `BASE_REF = <none>` and tell every reviewer to treat the
     **whole file** as in scope. Here *only*, relax the §4.3 "review the change,
     not the repo's debt" rule — say so explicitly so reviewers don't suppress
     pre-existing issues.
   For diff scopes the fleet reviews the **change**, not the whole repo's debt
   (`_contract.md` §4.3); `{{BASE_REF}}` / "Net diff vs base" report fields read
   `<none>` for the no-baseline scopes.
2. **Chunk large scope.** Detection drops sharply past ~400 changed LOC per
   review unit. If the change is large, split `TARGET_FILES` into cohesive
   sub-batches and run the round per batch; never dilute one reviewer across a
   1000-line diff. Batches partition the **review (Phase A) only**: run Phase A
   per batch, then **merge all batches into one ledger** before
   CONSOLIDATE/verify/FIX/RECORD — dedup, verification, fixing, and convergence
   are computed **once per round across all batches**, never per batch. A
   reviewer must still follow a root cause across batch boundaries
   (`_contract.md` §1.6) and cite the cross-batch locations in `occurrences[]`.
3. **Mode** — choose exactly one:
   - `fix-loop` (default): the multi-round REVIEW→FIX loop below; applies
     surviving fixes each round.
   - `propose-only`: one read-only REVIEW→CONSOLIDATE pass with mandatory
     adversarial verification for at/above-floor findings, then a verified fix
     plan; no branch, edits, commits, or loop.
   - `review-only`: one read-only round → one Markdown findings report, no
     adversarial-verification gate, no fixes, no loop — see §3A.
   Select `review-only` or `propose-only` only when the user asks for that mode,
   or when the project has **no discoverable build/test/lint command** (item 7)
   and auto-fixes cannot be verified green; in that case default to
   `propose-only` or ask before auto-fixing.
4. **Severity floor for fixing** (the *fix floor* — a **severity** threshold;
   distinct from the per-severity **confidence floors** in `_contract.md` §3.3,
   which are a probability gate) — default: fix `blocker`, `critical`, `major`;
   log `minor`/`info` without auto-fixing. (A `minor`/`info` is fixed only if the
   user raises the fix floor to include it — never via an ad-hoc "trivial and
   safe" exception, since below-floor findings skip the B2 verification gate.)
   Enums per `_contract.md` §3.2.
5. **Round budget** — default `up to 5`. (User can change at the checkpoint.)
6. **Reviewer subset** — default: all 22. The user may include/exclude areas.
7. **Project facts** — build/test/lint/type-check commands, language(s), spec or
   originating issue/PRD if any, and any conventions doc (`CONTRIBUTING.md`, lint
   config, style guide). Capture as `REPO_CONVENTIONS` and `SPEC_CONTEXT` and
   pass both to every reviewer. A flagged "issue" that the spec explicitly allows
   is acceptable variance, not a defect — feeding the spec prevents that class of
   false positive.
8. **PR comment history** — when the scope is a PR, or when the user asks to add
   code-review comments to a PR, fetch and read **all existing review comments,
   review-thread replies, top-level review bodies, and issue comments** before
   dispatching reviewers or posting anything. Capture them as `PR_PRIOR_COMMENTS`
   with author, URL, file/line when present, body, resolution/outdated state when
   available, and a short duplicate-suppression summary. Pass the relevant summary
   to reviewers and use it during CONSOLIDATE. Do not add a new comment for a
   root cause that was already reported, even if the wording or anchor differs.

Echo the resolved plan back in one short block, then proceed.

---

## 2. The reviewer roster

Each reviewer is one agent, spawned from `reviewers/_contract.md` (prepended) +
its own file (appended). The twenty-two reviewers — the `area` id is the closed
taxonomy from `_contract.md` §2; each reviewer emits findings under its own id
only:

| `area` id | Area file | Focus |
|-----------|-----------|-------|
| `correctness` | `reviewers/correctness.md` | logic, edge/boundary cases, termination (no endless loops/recursion), null/None, idempotency, control-flow completeness |
| `concurrency-resources` | `reviewers/concurrency-resources.md` | race conditions, deadlocks, atomicity, thread/async safety, cancellation, memory/fd leaks, resource cleanup on all paths |
| `performance` | `reviewers/performance.md` | complexity, hot paths, redundant work, N+1, allocations/copies, batching/caching, local throughput/latency (only on reached paths) |
| `scale` | `reviewers/scale.md` | tenant/user/data/load growth, fan-out, capacity, quotas, backpressure, partitioning, autoscaling, overload, noisy-neighbor isolation |
| `error-handling` | `reviewers/error-handling.md` | exception correctness, swallowed/over-broad catches, propagation, validation, retry/timeout, graceful degradation, fail-closed |
| `architecture-design` | `reviewers/architecture-design.md` | separation of concerns, coupling/cohesion, module/layer boundaries, dependency direction, API design, over-engineering |
| `api-contract` | `reviewers/api-contract.md` | API/public contract compatibility, REST/HTTP semantics, OpenAPI/schema drift, generated clients, versioning, idempotency, pagination/filtering |
| `data-migrations` | `reviewers/data-migrations.md` | schema/data migration safety, expand/migrate/contract, backfills, locks, constraints, rollback/forward compatibility, mixed-version behavior |
| `release-rollout` | `reviewers/release-rollout.md` | deployment sequencing, feature flags, canary/blue-green, rollback, kill switches, runtime config, mixed-version compatibility |
| `duplication-reuse` | `reviewers/duplication-reuse.md` | duplicated logic/DRY, copy-paste drift, dead/unreachable code, missed reuse of existing utilities |
| `readability-maintainability` | `reviewers/readability-maintainability.md` | naming, function/file size, nesting depth, magic values, comment quality, convention consistency (where no formatter owns it) |
| `security` | `reviewers/security.md` | injection, authn/authz/IDOR, secrets, crypto misuse, unsafe deserialization, SSRF/XSS/CSRF, data exposure, dependency risk (attach CWE) |
| `privacy-governance` | `reviewers/privacy-governance.md` | PII classification, minimization, consent/purpose limits, retention/deletion/export, telemetry privacy, anonymization, cross-context linkage |
| `supply-chain-ci` | `reviewers/supply-chain-ci.md` | CI/CD workflow safety, build provenance, pinned actions/images/tools, artifact integrity, SBOMs, workflow permissions, dependency update posture |
| `ai-llm-safety` | `reviewers/ai-llm-safety.md` | always-on LLM/agent/RAG safety, prompt injection, insecure output handling, excessive agency, sensitive output disclosure, model DoS/cost |
| `testing` | `reviewers/testing.md` | coverage of the CHANGED logic, tests that fail when code breaks, edge/negative cases, testability, no over-mocking, regression tests |
| `observability` | `reviewers/observability.md` | log level/context/noise, PII/secret leakage in logs, metrics/counters for new behavior, tracing, debuggability |
| `reliability-resilience` | `reviewers/reliability-resilience.md` | SLO impact, overload/cascading failure, graceful degradation, failover, recovery paths, critical state, data integrity, launch readiness |
| `accessibility` | `reviewers/accessibility.md` | keyboard/focus, semantic roles/names, contrast, forms/errors, status messages, reduced motion, pointer alternatives, WCAG-backed user impact |
| `internationalization` | `reviewers/internationalization.md` | locale-aware dates/numbers/currency, Unicode, encoding, bidi/RTL, translation/pluralization, collation/sorting, timezone display/storage |
| `product-domain` | `reviewers/product-domain.md` | domain invariants, business rules, entitlements, approval/state-machine flows, abuse-sensitive workflows, billing/legal semantics |
| `documentation` | `reviewers/documentation.md` | public/exported API docs, "why" comments, README/changelog/migration, doc↔code drift, accurate examples, deprecations |

Each reviewer reads every assigned human-written line in **whole-file context**,
not the hunk in isolation — most false positives come from missing a guard or
contract that sits outside the diff (`_contract.md` §2, §4.1).

`ai-llm-safety` is intentionally **always in the default fleet**, not a
conditional add-on. If the change has no LLM, agent, tool-calling, prompt,
retrieval, embedding, model, or AI-adjacent surface, that reviewer returns an
empty findings array with a clear summary.

---

## 3. The round loop (`fix-loop` mode)

Run rounds `1..N` (N = round budget, default 5). Each round has four phases —
**REVIEW (parallel) → CONSOLIDATE → FIX → RECORD**; Phase B (CONSOLIDATE)
carries two sub-steps (mechanical merge, then adversarial verification).

### Phase A — REVIEW (parallel)

Spawn **all selected reviewers at once** — issue every reviewer agent in a
**single assistant message with multiple Task/Agent tool calls** so they run
concurrently (mechanics in §5). Give each agent exactly:

- the prepended `reviewers/_contract.md`,
- its own `reviewers/<area>.md`,
- `TARGET_FILES`, `REPO_CONVENTIONS`, `SPEC_CONTEXT`, `ROUND_NUMBER`,
- `PR_PRIOR_COMMENTS` when reviewing or commenting on a PR,
- from round 2 onward: `PREVIOUS_FIX_DIFF` (the unified diff applied last round),
  `OPEN_FINDINGS` (the still-open findings, JSON per schema), and
  `REFUTED_FINDINGS` (ids + a one-line reason for findings refuted/dropped in
  earlier rounds — **do not re-raise these** unless new evidence overturns the
  refutation, and then cite what changed). Each reviewer
  must, per `_contract.md` §5, in order: **(a)** re-judge each `OPEN_FINDING` it
  owns and set `status` (`resolved` / `partially_resolved` / `not_addressed` /
  `regressed`) against re-quoted current code, reusing the original `id`;
  **(b)** treat every line in `PREVIOUS_FIX_DIFF` as freshly written code under
  maximum suspicion and hunt regressions the fixes introduced (new `id`,
  `introduced_by_fix: true`); **(c)** complete a full area scan. A fix in one
  area often breaks another, so **every** reviewer inspects **every** change,
  not only its own prior comments.

Reviewers investigate as deeply as each issue needs and **consult sibling areas
on cross-cutting findings** (`_contract.md` §1.6a): when a finding's combined
severity/likelihood/impact depends on another lane, the spotting reviewer either
messages that lane's reviewer directly (where the platform supports
agent-to-agent messaging) or spawns a dedicated read-only reviewer of the needed
area, then folds the result into the finding and records it in `cross_area_note`.
These consult sub-agents count against the parallel cap (§5). Do not skip a
consult that would change an important finding's assessment merely to save
tokens; under a hard platform cap (or when the user has prioritized cost),
serialize consults into later reviewer waves (§5) rather than dropping them.

Collect each agent's output: the single JSON object per `_contract.md` §6 (its
`summary`, `verification[]`, and `findings[]`).

### Phase B — CONSOLIDATE (merge, then adversarially verify)

**B1 — Mechanical merge & dedup.** Build one ledger from all reviewers' JSON:

- **Validate schema first.** Reject any finding with a missing/unknown field, a
  bad enum, a non-numeric `confidence`, or an empty/ungrounded `evidence`. A
  finding that cannot quote real source does not enter the ledger.
- **Re-gate confidence.** Drop any finding whose `confidence` is below its
  severity's floor (`_contract.md` §3.3: blocker/critical ≥0.90, major ≥0.80,
  minor/info ≥0.60). You may keep a sub-floor finding only by downgrading it to
  a severity whose floor it clears **and only when the finding's own evidence
  supports that lower severity** — never to retain a finding the evidence does
  not ground. A finding downgraded here is re-ranked at its new severity; if it
  now sits below the fix floor, it is logged without a fix, exactly like a B2
  `downgraded` verdict.
- **Re-gate source-of-truth.** A finding whose claim depends on an external
  library/API, standard, protocol, CVE/advisory, accessibility/privacy rule, or
  spec (`_contract.md` §1.7–1.8) MUST carry a non-empty `references[]`. If such a
  finding has `references: []`, send it back to the owning reviewer for a source
  or drop it — do not surface it. `references: []` is valid only for purely
  internal code facts.
- **Dedup on the structural finding `id`, not text.** The merge key is the
  finding `id` (`area:path:symbol:root-cause-slug`, **no line numbers** —
  `_contract.md` §3.1), which is stable across rounds even as lines shift. Two
  differently worded findings sharing an `id`/root cause collapse into one
  entry; union their `evidence`/`occurrences`, keep the **highest severity and
  best-grounded** instance, and record every reporting area. Never dedup on
  message similarity.
- **Dedup against existing PR discussion before surfacing/posting.** If
  `PR_PRIOR_COMMENTS` exists, compare each candidate finding's root cause,
  affected behavior, file/line, and recommendation against every previous
  comment and reply. Drop or mark as already-reported when the same root cause
  was raised by anyone, including bots, even if the old comment is anchored on a
  different line or uses different phrasing. Only keep a related finding if it
  is materially broader or different; in that case explicitly state what is new.
- **Independent agreement is a corroboration signal (a prior, not a verdict).**
  When two or more reviewers independently reach the same root-cause `id`, record
  every reporting area and treat the corroboration as a positive prior on the
  finding being real — a multi-lane finding is a strong fix candidate. This never
  *substitutes* for the evidence gate or the B2 refutation: agreement raises
  attention, it does not lower the bar. Use the ensemble to corroborate and the
  verifier to falsify; a finding three reviewers agree on still drops if B2
  refutes it.
- **Resolve conflicts.** When two areas pull opposite ways (e.g. performance vs
  readability), record the trade-off, decide per the severity floor and project
  priorities, and note the rejected option.
- **Update round-tracking.** Carry each prior-round finding's `status` from the
  reviewers' re-judgement (`resolved` / `partially_resolved` / `not_addressed` /
  `regressed`) — **but spot-verify, against the re-quoted current code yourself:
  every `resolved` on an actionable (≥ fix-floor) finding whenever this round
  would otherwise converge (so a false `resolved` cannot end the loop), and any
  `regressed` that would raise a finding to or above the fix floor.** A
  `resolved` that ends the loop is a convergence decision; verify it, don't take
  it on the reviewer's word.
- Rank the ledger by `severity`, then `confidence`, then `effort`.

**B2 — Adversarial verification (the false-positive gate).** For **every finding
at or above the fix floor** (§1 item 4), independently re-check it **before** it
is allowed to drive a fix:

- Open the cited `file:line_start..line_end`, confirm the `evidence` is verbatim
  and current, and decompose the finding into atomic claims (`_contract.md`
  §4.1). Map each claim to a quoted line; one unmapped claim ⇒ refute.
- **Attempt to refute, not confirm.** Actively look for the guard, contract,
  caller, or spec clause that would defuse the finding — read the surrounding
  whole-file context and callers/callees. Name the concrete reachable input/path
  that makes it bite; if you cannot, it is a hypothesis, not a finding — drop it.
- **Corroborate deterministically when possible.** If a type-checker or linter
  would confirm or contradict the claim, that signal outranks intuition; a
  finding contradicted by a clean static check is downgraded or dropped.
- **Reproduce empirically when feasible — cost is not a constraint.** Where a
  cheap, non-mutating check can settle it, construct one read-only and let the
  result decide: run the existing test suite, the type-checker/linter, a query
  `EXPLAIN`, or a throwaway script in a scratch location *outside the repo tree*
  (never writing repo files — §1.1) that drives a catastrophic-regex input,
  triggers the boundary condition, or exercises the path. A finding that
  reproduces is `confirmed`, with the repro captured in its `evidence` /
  `scenarios`; one that cannot be made to bite despite a genuine attempt is
  `refuted`. Empirical reproduction outranks argument in both directions.
- Use a verifier reasoning path **distinct** from the reviewer that raised it
  (cross-check, don't self-confirm). Inline verification counts as "distinct"
  only if you **start from the code, not the finding**: open
  `file:line_start..line_end` fresh, re-derive whether the claim holds from the
  source and its callers, and try to refute it — do not read the reviewer's
  `description`/`recommendation` first. For `blocker`/`critical` claims, prefer a
  fresh read-only verifier agent (real context isolation), and run it on a
  **different model when the platform offers one** — cross-model falsification
  breaks the correlated blind spots that let a wrong finding look agreed-upon.
- **Verdict:** `confirmed` (proceed to fix), `downgraded` (re-severity to what
  the evidence supports — if it now sits **below** the fix floor, log and don't
  fix this round; if it is **still at/above** the floor, it stays a fix candidate
  at the new severity), or `refuted` (drop; record the refutation reason so it is
  not re-raised). `confirmed` and still-at/above-floor `downgraded` findings enter
  Phase C.

Verification is mandatory above the floor; below-floor findings are logged
without verification (their cost-of-wrong is low and they aren't fixed).

### Phase C — FIX (`fix-loop` only)

Apply fixes **only for `confirmed` findings at/above the severity floor**,
**coordinated and file-grouped** (never in parallel) to avoid edit conflicts.
Each fix:

- is the **minimal, localized** change that removes the root cause — no
  speculative redesign, no gold-plating, no abstraction the change didn't need
  (over-engineering is itself a finding; don't commit it in a fix),
- references the finding `id` in the commit message,
- must not silently change behavior beyond the fix's intent,
- **may add a short clarifying comment** when the fixed code (or a nearby
  correct-but-suspicious construct that drew a now-refuted finding) is
  non-obvious: one line stating *why* the code is correct/safe, so future readers
  and later review rounds don't re-flag it. Only when it genuinely aids
  understanding — never as noise, and never in place of the actual fix. A comment
  on a *refuted-finding* construct is the one allowed edit not tied to a
  `confirmed` fix; keep it to a single comment line, never a code change.

Each applied fix is itself verified: the gates below must pass, and the next
round's Phase A re-judges the finding (`resolved`?) **and** treats the fix's new
lines as suspect (regression hunt). After fixes: run build + type-check + lint +
tests. If anything breaks, repair or
revert **within this phase** — the round must end green. Commit the round
(`review-fleet round <n>: <summary>`). Verification that these fixes actually
worked is delegated to Phase A of the **next** round (every reviewer re-judges
and hunts regressions), closing the loop.

### Phase D — RECORD

Render a round report from `templates/round-report.md` and present it inline:
per-area counts (new / fixed / deferred-below-floor / regressed / still-open),
verification of the prior round's fixes, fixes applied, build/test status, diff
summary, and the round's convergence signal. Persist it to `reports/round-<n>.md`
only if the user asked for saved reports — never commit review artifacts into the
change under review unless asked.

### Loop control & convergence detection

**Actionable finding** = one that is `confirmed` by Phase B2 **and** sits at or
above the fix floor (§1 item 4). Every "new actionable findings" count below
counts only these — not below-floor or refuted ones.

- The verification of this round's fixes happens in **Phase A of the next round**
  — that is the "run again to verify the fixes and find new issues" step.
- **Converged (stop early, go to checkpoint):** a REVIEW phase returns **zero new
  `confirmed` actionable findings (≥ floor)** AND every prior *actionable*
  (≥ fix-floor) finding is `resolved` AND no `regressed` finding remains open.
  (Below-floor findings left `not_addressed` do **not** block convergence — they
  are reported as deferred, never fixed.) Note the cycle converged.
- **Plateaued:** the count of new actionable findings is flat or oscillating and
  no above-floor finding has been resolved in the latest round. Surface this at
  the checkpoint rather than burning the remaining budget silently.
- **Improving:** new-actionable-findings count is trending down round over round.
- Otherwise continue until the round budget is exhausted, then checkpoint.

The round report's `{{ROUND_VERDICT}}` label maps onto these convergence signals:
`CLEAN` ⇒ *converged*; `FIXED_PENDING_VERIFY` / `LOOPING` ⇒ *improving* (or still
in progress); `STALLED` ⇒ *plateaued*; `MAX_ROUNDS` ⇒ budget exhausted. Use the
same word in `templates/round-report.md` and `templates/final-status.md`.

`propose-only` uses Phase A, Phase B1, and mandatory Phase B2 exactly once, then
renders a verified fix plan to `review-fleet-plan.md` (working directory, or a
path the user names) using `templates/review-only-report.md` with the title
"Propose-only verified fix plan" (same per-area report shape as review-only —
the difference is the mandatory B2 gate run on every at/above-floor finding, not
the layout). Set `REPORT_MODE_SUMMARY` to
"Propose-only verified fix plan — nothing was changed." and `REPORT_FOLLOWUP` to
"These findings survived the adversarial verification gate; run fix-loop mode to
apply them." Set `REPORT_MODE_FOOTER` to "propose-only (read-only, single
verified-fix-plan pass)". Then stop. Do not run another round in `propose-only`;
no code changed, so there is no fix diff to verify.

---

## 3A. Review-only mode (single-round audit — explicit opt-in)

**Trigger:** the user explicitly asks for a **review-only / report-only /
read-only / audit** session ("review-only", "just review, don't change
anything", "audit this", "give me a findings report"). If it's ambiguous whether
they want fixes, confirm before entering this mode.

Review-only runs **exactly one round and changes nothing** — strictly read-only
end to end (no branch, no commits, no edits, no loop). Unlike `propose-only`
(which runs the **full Phase B2 gate** on every at/above-floor finding),
review-only runs **no full B2 verifier gate** — but a mandatory cheap inline
refutation is still applied to every `blocker`/`critical` finding (drop any that
fails it); findings below `blocker`/`critical` are reported as-is after the §3.3
confidence gate. If you need every fix-floor finding adversarially verified
without fixing, use `propose-only`, not review-only:

1. **Intake** as in §1, forced to: mode `review-only`, round budget **1**, no
   fix sub-step. Resolve `TARGET_FILES`/`BASE_REF`/`REPO_CONVENTIONS`/`SPEC_CONTEXT`
   the same way.
2. **Phase A — REVIEW (parallel).** Spawn all selected reviewers exactly as in §3
   Phase A, round 1 — full contract behavior: whole-file + cross-file/module
   review (`_contract.md` §1.6), external-tool/library web research (§1.7),
   optional sub-agents (§1.5), evidence-gating, and the confidence floors. There
   is no round 2, so none of `PREVIOUS_FIX_DIFF` / `OPEN_FINDINGS` /
   `REFUTED_FINDINGS`. **Add one line to each reviewer's Context block:
   "REVIEW-ONLY mode — populate every finding's prose fields to full depth
   (`title`, wide `description` with implications, `scenarios`, `likelihood`,
   `references`, `evidence`, `recommendation`); the orchestrator renders these
   into the full issue report. Keep the single JSON-object output shape unchanged
   (`_contract.md` §6) — this adds no fields."**
3. **Phase B1 — merge & dedup only** (no fixing): validate schema, re-gate
   confidence per the per-severity confidence floors (`_contract.md` §3.3), dedup
   on the structural `id`, resolve conflicts, and rank. **Do not run the full
   Phase B2 verifier gate and do not run Phase C** — nothing is fixed. You
   **must** still perform cheap inline refutation before reporting any
   `blocker`/`critical` finding, and drop anything that does not survive that
   check.
4. **Render the report.** Produce **one Markdown file** from
   `templates/review-only-report.md`: findings **collected by reviewer/area**, and
   within each area **grouped and sorted by severity** (`blocker` → `critical` →
   `major` → `minor` → `info`, then `confidence` desc). Every issue states its
   **one-sentence header, exact location, wide description, implications,
   confidence (probability the finding is real), `likelihood` (operating mode
   plus relative frequency of occurrence), possible scenarios/examples,
   source-of-truth links, evidence, and recommendation**.
   Write it to
   `review-fleet-report.md` in the working directory (or a path the user names) and
   present a short summary inline. Set `REPORT_TITLE` to "Review-only report",
   `REPORT_MODE_SUMMARY` to "Read-only audit — nothing was changed.", and
   `REPORT_FOLLOWUP` to "This is a single-round findings report. To act on it,
   re-run in fix-loop mode." Set `REPORT_MODE_FOOTER` to "review-only
   (read-only, single round)".

Then **stop** — there is no fix loop and no continue/stop checkpoint in
review-only mode. Hand the report to the user; if they then want fixes, switch to
`fix-loop` mode (§3) with the report's findings as the starting ledger.

---

## 4. End-of-cycle checkpoint (hand control to the user)

After the budget is reached (or convergence), present final status using
`templates/final-status.md`:

- per-area and overall counts: raised / fixed / remaining (by severity),
- the list of **remaining open findings** with severity, confidence, and a
  one-line rationale,
- regressions introduced and whether they were resolved,
- aggregate diff summary + current build/type-check/lint/test status,
- the per-round new-actionable-findings trend and a convergence verdict
  (converged / improving / plateaued / budget-exhausted).

Then ask the user to choose:

1. **Continue** — and **how many more rounds** (resumes from the next round
   number with the same scope/branch).
2. **Stop & finalize** — produce the final summary, leave the branch ready for
   the user to merge/PR. Do **not** auto-merge or push without explicit approval.
3. **Adjust** — change scope, reviewer subset, severity floor, or fix mode, then
   continue.

Never auto-continue past the budget and never decide for the user.

### 4A. PR comment format and duplicate suppression

When the user approves adding review-fleet findings to a PR:

1. Re-read the current PR comments/replies immediately before posting, because
   new comments may have appeared since intake. Refresh `PR_PRIOR_COMMENTS` and
   rerun duplicate suppression against the exact comments that will be posted.
2. Post only user-approved findings, only at or above the requested severity
   floor, and only if they are not already reported by any prior comment/reply.
3. Match the existing human review style when the PR has one. Default format:
   bold one-sentence header; wide description of the issue; concrete
   implications; examples/scenarios; likelihood (operating mode plus relative
   frequency of occurrence); current-code snippet or precise evidence; suggested
   fix; severity/confidence/reviewer tag; explicit source-of-truth links
   (official docs, upstream source, CVE/advisory, standards, repo
   spec/ADR/checklist).
4. Prefer inline comments anchored to the most diagnostic changed line. Use a
   top-level review body only for a short summary; do not hide issue details
   there when an inline anchor exists.

---

## 5. Spawning reviewers — exact mechanics

- Use the platform's subagent tool. In Claude Code, use the Task/Agent tool. In
  Codex, use `multi_agent_v1.spawn_agent` with `agent_type: "explorer"` for
  read-only reviewers. Put **all reviewer calls in one assistant message** so
  they execute in parallel where the platform supports it.
- Prompt assembly per agent: `contents(reviewers/_contract.md)` + `"\n\n"` +
  `contents(reviewers/<area>.md)` + a trailing **Context** block containing
  `ROUND_NUMBER`, `TARGET_FILES`, `REPO_CONVENTIONS`, `SPEC_CONTEXT`,
  `PR_PRIOR_COMMENTS` when available, and (round ≥ 2) `PREVIOUS_FIX_DIFF`,
  `OPEN_FINDINGS`, and `REFUTED_FINDINGS`.
- Reviewers are **read-only**: do not grant them edit/write/mutating tools. Their
  permitted actions are read, read git history/diffs, and non-mutating inspection
  (`_contract.md` §1.1). In Codex, explicitly instruct every reviewer that it is
  read-only and must not edit files, stage changes, commit, install, or run
  mutating commands.
- Adversarial verification in Phase B2 is **mandatory** for every at/above-floor
  finding (§3 B2); what is *optional* is spawning a **separate** read-only
  verifier agent for it (preferred for `blocker`/`critical`) rather than
  verifying inline. Such verifier agents are spawned the same way (read-only),
  with a verifier instruction to **refute** the specific finding, and must use a
  reasoning path distinct from the originating reviewer.
- **Reviewers may fan out internally and consult sibling areas.** Each reviewer
  may spawn read-only sub-agents to split a large file set or its area's
  sub-topics (`_contract.md` §1.5), and may spawn a read-only **cross-area
  consult** reviewer for a cross-cutting finding (`_contract.md` §1.6a); it owns
  and quality-gates all of their merged output — you still receive exactly **one**
  JSON object from each reviewer. Account for this in the concurrency budget: a
  reviewer's sub-agents and consult agents both count against the platform's
  parallel cap, so for large scope prefer batching reviewer waves (below) over
  assuming all twenty-two reviewers also fan out at once.
- If the platform caps parallel agents, batch reviewers in waves but keep a whole
  round's reviews within one phase before consolidating.
- **Mind the cost — unless the user prioritizes recall over it.** A round is up
  to 22 reviewers × whole-file reads (× any sub-agents/consults) × rounds. For
  large scope or a tight budget, narrow the reviewer subset (intake item 6) and
  batch waves rather than fanning everything out at once — recall degrades
  gracefully, token cost does not. **When the user explicitly prioritizes
  thoroughness/recall over token cost, do the opposite:** keep the full
  22-reviewer fleet, allow reviewer fan-out, and allow cross-area consults
  (§1.6a) freely — narrowing the subset is then only a last resort for a hard
  platform cap, and say so if you hit one.

---

## 6. Guardrails recap

- When applying fixes: branch + per-round commits; reversible at every step.
- Reviewers analyze (read-only, evidence-gated); orchestrator fixes.
- Every above-floor finding survives **adversarial verification** before it is
  fixed; refuted findings are recorded so they are not re-raised.
- Confidence-gated at the reviewer and again at merge; dedup on the structural,
  line-number-free finding `id`, never on text.
- Keep build/type-check/lint/tests green each round; a fix that breaks them is a
  defect to repair before recording.
- Respect the severity floor; don't gold-plate `minor`/`info`; minimal fixes only.
- Detect convergence/plateau explicitly; stop at the budget and ask the user;
  never push/merge/delete without approval.

---

## 7. Worked example — one round, end to end (illustrative)

A one-file change to `src/api/auth.py`, run with default settings.

1. **Intake (§1).** `BASE_REF = main`; `TARGET_FILES = [src/api/auth.py]` from
   `git diff --name-only main...HEAD`; fix mode `fix-loop`; fix floor `major`; gates
   `pytest -q` / `ruff` / `mypy`. Branch `review-fleet/20260616-1530`.
2. **Phase A — REVIEW (parallel).** All 22 reviewers run at once. The `security`
   reviewer returns one JSON object whose `findings[]` holds (abbreviated):
   `{"id":"security:src/api/auth.py:verify_token:jwt-alg-none-accepted","area":"security","severity":"critical","confidence":0.93,"blocking":true,"evidence":"algorithms=[header[\"alg\"]]","recommendation":"pin algorithms=[\"HS256\"]","cwe":"CWE-347", …}`.
   The other twenty-one return `findings: []` with honest one-line summaries.
3. **Phase B1 — merge.** Schema valid; `0.93 ≥ 0.90` critical floor; unique `id`
   → enters the ledger, ranked first.
4. **Phase B2 — adversarial verify.** A fresh read-only verifier opens `auth.py`,
   confirms the quoted line is verbatim and current, decomposes the claim (alg is
   read from the token header → attacker-controlled → forgeable), finds no guard
   pinning the algorithm, and names the path (every authenticated request).
   Verdict: `confirmed`.
5. **Phase C — fix.** Apply the minimal change (`algorithms=["HS256"]`); commit
   `review-fleet round 1: pin JWT alg (security:…:jwt-alg-none-accepted)`; run the
   gates → all green.
6. **Phase D — record.** Render `round-report.md`: `security` New 1 / Fixed 1,
   all gates PASS, verdict `FIXED_PENDING_VERIFY`, convergence `improving`.
7. **Round 2 — Phase A.** Every reviewer re-judges the open finding (now
   `resolved`, re-quoting the pinned line) and treats the fix's changed line as
   suspect for regressions → no new findings. **Converged** → checkpoint (§4).
