# review-fleet — Final status after {{ROUNDS_DONE}} of {{ROUND_BUDGET}} round(s)

**Scope:** {{TARGET_SUMMARY}} · **Fix mode:** {{FIX_MODE}} · **Severity floor:** {{FLOOR}}
**Branch:** {{BRANCH}} (ready for your review — NOT pushed or merged) · **Latest commit:** {{COMMIT_SHA}}
**Convergence:** {{improving | plateaued | converged}} — {{one line: why this verdict}}

## Headline
- Total findings raised: {{N}} · fixed: {{N}} · **remaining open: {{N}}**
- Remaining by severity — blocker: {{n}} · critical: {{n}} · major: {{n}} · minor: {{n}} · info: {{n}}
- Open findings at/above the fix floor ({{FLOOR}}): **{{n}}** ← these are what would block a merge
- Regressions introduced while fixing: {{n}} (resolved: {{n}}, **still open: {{n}}**)

## Per-area summary
Open cells show the by-severity split of what is still open (B=blocker / C=critical / Maj=major / Min=minor / Info), matching the header.

| Area | Raised | Fixed | Open (B/C/Maj/Min/Info) |
|------|----:|----:|----|
| correctness | {{N}} | {{N}} | {{0/0/0/0/0}} |
| concurrency-resources | {{N}} | {{N}} | {{0/0/0/0/0}} |
| performance | {{N}} | {{N}} | {{0/0/0/0/0}} |
| scale | {{N}} | {{N}} | {{0/0/0/0/0}} |
| error-handling | {{N}} | {{N}} | {{0/0/0/0/0}} |
| architecture-design | {{N}} | {{N}} | {{0/0/0/0/0}} |
| api-contract | {{N}} | {{N}} | {{0/0/0/0/0}} |
| data-migrations | {{N}} | {{N}} | {{0/0/0/0/0}} |
| release-rollout | {{N}} | {{N}} | {{0/0/0/0/0}} |
| duplication-reuse | {{N}} | {{N}} | {{0/0/0/0/0}} |
| readability-maintainability | {{N}} | {{N}} | {{0/0/0/0/0}} |
| security | {{N}} | {{N}} | {{0/0/0/0/0}} |
| privacy-governance | {{N}} | {{N}} | {{0/0/0/0/0}} |
| supply-chain-ci | {{N}} | {{N}} | {{0/0/0/0/0}} |
| ai-llm-safety | {{N}} | {{N}} | {{0/0/0/0/0}} |
| testing | {{N}} | {{N}} | {{0/0/0/0/0}} |
| observability | {{N}} | {{N}} | {{0/0/0/0/0}} |
| reliability-resilience | {{N}} | {{N}} | {{0/0/0/0/0}} |
| accessibility | {{N}} | {{N}} | {{0/0/0/0/0}} |
| internationalization | {{N}} | {{N}} | {{0/0/0/0/0}} |
| product-domain | {{N}} | {{N}} | {{0/0/0/0/0}} |
| documentation | {{N}} | {{N}} | {{0/0/0/0/0}} |
| **TOTAL** | {{N}} | {{N}} | {{0/0/0/0/0}} |

## Remaining open findings (highest severity first)
Each line: id · severity/confidence · likelihood (occurrence + operating condition) · location · title — one-line rationale for why it is still open
(below floor / deferred / risky to fix / needs your decision / not auto-fixable).
- `{{id}}` [{{severity}}/{{confidence}} · {{likelihood}}] {{file}}:{{line_start}}-{{line_end}} — {{title}} — {{rationale, incl. effort if relevant}}
- {{additional_open_findings_in_the_same_format_if_any}}
- (none above the fix floor → say so explicitly: "No open findings at/above {{FLOOR}}.")

## Regressions introduced during fixing
Defects that did not exist before this cycle and were caused by a fix (`introduced_by_fix: true`).
- `{{id}}` [{{severity}}] {{file}}:{{lines}} — {{title}} — introduced by fix for `{{origin_finding_id}}` — **{{resolved in round N | STILL OPEN}}**
- {{additional_regressions_in_the_same_format_if_any}}
- (none → "No regressions introduced.")

## Health & aggregate diff
- build: {{pass/fail}} · type-check: {{pass/fail}} · lint: {{pass/fail}} · tests: {{passed}}/{{total}} ({{+new tests added}})
- Net diff vs base ({{BASE_REF}}): **+{{added}} / −{{removed}} across {{files}} files**
- Per-round trend — new actionable findings (≥ floor): R1={{}} R2={{}} R3={{}} R4={{}} R5={{}}
- Per-round trend — open at/above floor remaining after fixes: R1={{}} R2={{}} R3={{}} R4={{}} R5={{}}

## Convergence verdict
- **{{improving | plateaued | converged}}**
  - *improving* — each round resolves more than it introduces; the open-≥-floor count is trending down.
  - *plateaued* — successive rounds surface roughly the same count / churn the same findings without net progress.
  - *converged* — a REVIEW phase returned zero new actionable findings (≥ floor) AND every prior actionable (≥ floor) finding is `resolved` AND no `regressed` finding remains open (below-floor findings left open do not block convergence).
- Evidence for this verdict: {{point at the two trend rows above + regression count}}

## Your decision
I will not continue automatically. Choose one:
1. **Continue** — how many more rounds? (resumes at round {{ROUNDS_DONE+1}}, same scope / branch / floor)
2. **Stop & finalize** — I write the final summary and leave branch `{{BRANCH}}` ready for you to open a PR or merge. I will NOT push, merge, or rewrite history without your explicit go-ahead.
3. **Adjust & continue** — change scope, reviewer subset, severity floor, or fix mode, then continue from round {{ROUNDS_DONE+1}}.

Tell me which option (and the round count if you pick 1).
