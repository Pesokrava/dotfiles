<!--
  review-fleet / round report
  Rendered by the orchestrator at the end of EACH review round and presented inline.
  Persist to reports/round-{{ROUND_N}}.md only if the user asked for saved reports;
  never commit review artifacts into the change under review unless asked.
  Placeholders are {{UPPER_SNAKE}}. Tables: keep one finding per row.
  Reviewers run read-only; counts below describe what the ORCHESTRATOR did this round.
-->

# Review-Fleet — Round {{ROUND_N}} / {{ROUND_MAX}}

**Branch:** `{{REVIEW_BRANCH}}`  ·  **Base:** `{{BASE_REF}}`  ·  **Head:** `{{HEAD_SHA}}`
**Scope:** {{TARGET_SUMMARY}}  ·  **Fix mode:** {{FIX_MODE}}  ·  **Severity floor (auto-fix):** `{{SEVERITY_FLOOR}}`
**Generated:** {{TIMESTAMP_ISO8601}}  ·  **Reviewers:** {{REVIEWER_COUNT}} ({{REVIEWER_LIST}})  ·  **Round duration:** {{ROUND_DURATION}}

> **Verdict:** {{ROUND_VERDICT}}
> One of: `CLEAN` (no findings at/above floor, all gates green) · `FIXED_PENDING_VERIFY` (fixes applied, re-run next round) · `LOOPING` (open findings remain, continuing) · `STALLED` (loop stopped early because the convergence signal is *plateaued* — no net progress vs. the previous round) · `MAX_ROUNDS` (loop budget exhausted, handing to user)

---

## 1. Round summary (one line)

{{ROUND_SUMMARY_SENTENCE}}
<!-- e.g. "3 new findings, 5 fixed, 1 deferred, 0 regressed; build+test+lint all green; ready to hand off." -->

## 2. Counts by area

<!-- Columns are deltas for THIS round. ALL 22 areas always listed, in this fixed order
     (even areas with no findings — a row of zeros is signal, not noise).
       new       = findings first seen this round
       fixed     = findings resolved by orchestrator fixes this round
       deferred  = below floor OR explicitly punted (see §8 reason)
       regressed = previously-fixed findings that reappeared, or new breakage a fix introduced
       open      = still unresolved at end of round (carried into next, see §7) -->

| Area | New | Fixed | Deferred | Regressed | Open (carry) |
|------|----:|------:|---------:|----------:|-------------:|
| correctness | {{CORRECTNESS_NEW}} | {{CORRECTNESS_FIXED}} | {{CORRECTNESS_DEFERRED}} | {{CORRECTNESS_REGRESSED}} | {{CORRECTNESS_OPEN}} |
| concurrency-resources | {{CONCURRENCY_NEW}} | {{CONCURRENCY_FIXED}} | {{CONCURRENCY_DEFERRED}} | {{CONCURRENCY_REGRESSED}} | {{CONCURRENCY_OPEN}} |
| performance | {{PERFORMANCE_NEW}} | {{PERFORMANCE_FIXED}} | {{PERFORMANCE_DEFERRED}} | {{PERFORMANCE_REGRESSED}} | {{PERFORMANCE_OPEN}} |
| scale | {{SCALE_NEW}} | {{SCALE_FIXED}} | {{SCALE_DEFERRED}} | {{SCALE_REGRESSED}} | {{SCALE_OPEN}} |
| error-handling | {{ERROR_HANDLING_NEW}} | {{ERROR_HANDLING_FIXED}} | {{ERROR_HANDLING_DEFERRED}} | {{ERROR_HANDLING_REGRESSED}} | {{ERROR_HANDLING_OPEN}} |
| architecture-design | {{ARCHITECTURE_NEW}} | {{ARCHITECTURE_FIXED}} | {{ARCHITECTURE_DEFERRED}} | {{ARCHITECTURE_REGRESSED}} | {{ARCHITECTURE_OPEN}} |
| api-contract | {{API_CONTRACT_NEW}} | {{API_CONTRACT_FIXED}} | {{API_CONTRACT_DEFERRED}} | {{API_CONTRACT_REGRESSED}} | {{API_CONTRACT_OPEN}} |
| data-migrations | {{DATA_MIGRATIONS_NEW}} | {{DATA_MIGRATIONS_FIXED}} | {{DATA_MIGRATIONS_DEFERRED}} | {{DATA_MIGRATIONS_REGRESSED}} | {{DATA_MIGRATIONS_OPEN}} |
| release-rollout | {{RELEASE_ROLLOUT_NEW}} | {{RELEASE_ROLLOUT_FIXED}} | {{RELEASE_ROLLOUT_DEFERRED}} | {{RELEASE_ROLLOUT_REGRESSED}} | {{RELEASE_ROLLOUT_OPEN}} |
| duplication-reuse | {{DUPLICATION_NEW}} | {{DUPLICATION_FIXED}} | {{DUPLICATION_DEFERRED}} | {{DUPLICATION_REGRESSED}} | {{DUPLICATION_OPEN}} |
| readability-maintainability | {{READABILITY_NEW}} | {{READABILITY_FIXED}} | {{READABILITY_DEFERRED}} | {{READABILITY_REGRESSED}} | {{READABILITY_OPEN}} |
| security | {{SECURITY_NEW}} | {{SECURITY_FIXED}} | {{SECURITY_DEFERRED}} | {{SECURITY_REGRESSED}} | {{SECURITY_OPEN}} |
| privacy-governance | {{PRIVACY_GOVERNANCE_NEW}} | {{PRIVACY_GOVERNANCE_FIXED}} | {{PRIVACY_GOVERNANCE_DEFERRED}} | {{PRIVACY_GOVERNANCE_REGRESSED}} | {{PRIVACY_GOVERNANCE_OPEN}} |
| supply-chain-ci | {{SUPPLY_CHAIN_CI_NEW}} | {{SUPPLY_CHAIN_CI_FIXED}} | {{SUPPLY_CHAIN_CI_DEFERRED}} | {{SUPPLY_CHAIN_CI_REGRESSED}} | {{SUPPLY_CHAIN_CI_OPEN}} |
| ai-llm-safety | {{AI_LLM_SAFETY_NEW}} | {{AI_LLM_SAFETY_FIXED}} | {{AI_LLM_SAFETY_DEFERRED}} | {{AI_LLM_SAFETY_REGRESSED}} | {{AI_LLM_SAFETY_OPEN}} |
| testing | {{TESTING_NEW}} | {{TESTING_FIXED}} | {{TESTING_DEFERRED}} | {{TESTING_REGRESSED}} | {{TESTING_OPEN}} |
| observability | {{OBSERVABILITY_NEW}} | {{OBSERVABILITY_FIXED}} | {{OBSERVABILITY_DEFERRED}} | {{OBSERVABILITY_REGRESSED}} | {{OBSERVABILITY_OPEN}} |
| reliability-resilience | {{RELIABILITY_RESILIENCE_NEW}} | {{RELIABILITY_RESILIENCE_FIXED}} | {{RELIABILITY_RESILIENCE_DEFERRED}} | {{RELIABILITY_RESILIENCE_REGRESSED}} | {{RELIABILITY_RESILIENCE_OPEN}} |
| accessibility | {{ACCESSIBILITY_NEW}} | {{ACCESSIBILITY_FIXED}} | {{ACCESSIBILITY_DEFERRED}} | {{ACCESSIBILITY_REGRESSED}} | {{ACCESSIBILITY_OPEN}} |
| internationalization | {{INTERNATIONALIZATION_NEW}} | {{INTERNATIONALIZATION_FIXED}} | {{INTERNATIONALIZATION_DEFERRED}} | {{INTERNATIONALIZATION_REGRESSED}} | {{INTERNATIONALIZATION_OPEN}} |
| product-domain | {{PRODUCT_DOMAIN_NEW}} | {{PRODUCT_DOMAIN_FIXED}} | {{PRODUCT_DOMAIN_DEFERRED}} | {{PRODUCT_DOMAIN_REGRESSED}} | {{PRODUCT_DOMAIN_OPEN}} |
| documentation | {{DOCUMENTATION_NEW}} | {{DOCUMENTATION_FIXED}} | {{DOCUMENTATION_DEFERRED}} | {{DOCUMENTATION_REGRESSED}} | {{DOCUMENTATION_OPEN}} |
| **TOTAL** | **{{TOT_NEW}}** | **{{TOT_FIXED}}** | **{{TOT_DEFERRED}}** | **{{TOT_REGRESSED}}** | **{{TOT_OPEN}}** |

## 3. Verification of previous round's fixes

<!-- Round 1 has nothing to verify — write "N/A — first round." Otherwise reconcile every
     fix claimed last round against what the reviewers see now. -->

- resolved: {{VERIFY_RESOLVED}} · partially: {{VERIFY_PARTIAL}} · not addressed: {{VERIFY_NOT_ADDRESSED}} · **regressed: {{VERIFY_REGRESSED}}**
- {{VERIFY_DETAIL_LINE}}
  <!-- one line per regressed/partial finding: `{{finding_id}}` — what's still wrong -->

## 4. Gate status

<!-- Run AFTER this round's fixes land. A red gate blocks handoff regardless of finding counts.
     Status vocab: PASS · FAIL · SKIP (no such gate in this repo) · N/A. -->

| Gate  | Status            | Detail                                              |
|-------|-------------------|-----------------------------------------------------|
| Build | {{BUILD_STATUS}}  | {{BUILD_DETAIL}}                                    |
| Tests | {{TEST_STATUS}}   | {{TEST_PASS}}/{{TEST_TOTAL}} pass · {{TEST_DETAIL}} |
| Lint  | {{LINT_STATUS}}   | {{LINT_DETAIL}}                                     |
| Types | {{TYPE_STATUS}}   | {{TYPE_DETAIL}}                                     |

<!-- Commands actually run: {{GATE_COMMANDS}} -->

## 5. Fixes applied this round

**Commit(s) this round:** {{ROUND_COMMIT_SHAS}}
**Net change:** {{FILES_CHANGED}} files · +{{LINES_ADDED}} / −{{LINES_REMOVED}}

| File | Δ | Findings addressed |
|------|---|--------------------|
| `{{FILE_1}}` | +{{F1_ADD}}/−{{F1_DEL}} | {{F1_FINDING_IDS}} |
| `{{FILE_2}}` | +{{F2_ADD}}/−{{F2_DEL}} | {{F2_FINDING_IDS}} |
| `{{FILE_N}}` | +{{FN_ADD}}/−{{FN_DEL}} | {{FN_FINDING_IDS}} |

<!-- If no fixes were applied this round (e.g. all findings below floor), write:
     "No fixes applied this round — all findings below severity floor `{{SEVERITY_FLOOR}}`." -->

## 6. Findings changed this round (ranked)

<!-- Ranked by severity desc, then confidence desc, then area. Include only findings that
     CHANGED state this round (new / fixed / deferred / regressed). Carried-but-unchanged
     findings live in §7. Every finding MUST cite concrete evidence — no evidence, no row.
     Schema (matches reviewers/_contract.md §3 — do not diverge):
       ID         stable id per §3.1: area:path:symbol:root-cause-slug  (NO line numbers)
       SEV        blocker | critical | major | minor | info  (§3.2)
       CONF       confidence 0.0–1.0  (§3.3; probability the FINDING IS REAL — distinct from severity. A finding whose SEV is below the auto-fix floor ⇒ deferred, not fixed)
       LIKELIHOOD how often the issue ACTUALLY OCCURS + the triggering operating mode: day-to-day | high-load | adversarial | edge-case | failure-mode (§3.1; distinct from CONF)
       STATE      this round's change to the finding's persistent `status`:
                  NEW (newly raised) · FIXED (status→resolved by a fix this round) ·
                  DEFERRED (below floor / punted) · REGRESSED (status→regressed)
       LOC        path:line_start(-line_end)
     SCENARIOS  concrete examples/inputs where the issue bites
     SOURCES    explicit source-of-truth links: official docs, upstream source, CVE/advisory, standard, repo spec/ADR/checklist
     EVIDENCE   verbatim quoted source / failing assert / spec or CVE ref — not a vibe -->

| Rank | ID | Sev | Conf | Likelihood | State | Area | Location | One-sentence header | Examples / scenarios | Source of truth | Evidence | Fix / Note |
|-----:|----|-----|-----:|------------|-------|------|----------|---------------------|----------------------|-----------------|----------|------------|
| 1 | {{ID_1}} | {{SEV_1}} | {{CONF_1}} | {{LIKELIHOOD_1}} | {{STATE_1}} | {{AREA_1}} | `{{LOC_1}}` | {{TITLE_1}} | {{SCENARIOS_1}} | {{SOURCES_1}} | {{EVIDENCE_1}} | {{FIXNOTE_1}} |
| 2 | {{ID_2}} | {{SEV_2}} | {{CONF_2}} | {{LIKELIHOOD_2}} | {{STATE_2}} | {{AREA_2}} | `{{LOC_2}}` | {{TITLE_2}} | {{SCENARIOS_2}} | {{SOURCES_2}} | {{EVIDENCE_2}} | {{FIXNOTE_2}} |
| N | {{ID_N}} | {{SEV_N}} | {{CONF_N}} | {{LIKELIHOOD_N}} | {{STATE_N}} | {{AREA_N}} | `{{LOC_N}}` | {{TITLE_N}} | {{SCENARIOS_N}} | {{SOURCES_N}} | {{EVIDENCE_N}} | {{FIXNOTE_N}} |

### Regressions (if any)

<!-- Pull REGRESSED rows out for visibility — these are the most expensive misses.
     Note which fix (commit/finding id) introduced or re-opened them. -->

- **{{REGRESSED_ID}}** ({{REGRESSED_SEV}}) at `{{REGRESSED_LOC}}` — {{REGRESSED_DESC}}
  Introduced by: {{REGRESSED_CAUSE}}

### Refuted / dropped this round (with reason)

<!-- Findings that did NOT survive adversarial verification (Phase B2), or were
     dropped at merge (below floor cannot be salvaged, ungrounded, out of lane,
     already-reported on the PR). Recorded so the fleet does NOT re-raise them in
     a later round (SKILL.md §0, §6). Omit the table only if nothing was refuted. -->

| ID | Sev (claimed) | Area | Location | Why refuted / dropped |
|----|---------------|------|----------|------------------------|
| {{REFUTED_ID}} | {{REFUTED_SEV}} | {{REFUTED_AREA}} | `{{REFUTED_LOC}}` | {{REFUTED_REASON}} |

## 7. Carried open findings (unchanged this round)

<!-- Still open, not touched this round. Brief — full detail is in their original round report. -->

| ID | Sev | Area | Location | Title | Why still open |
|----|-----|------|----------|-------|----------------|
| {{COPEN_ID}} | {{COPEN_SEV}} | {{COPEN_AREA}} | `{{COPEN_LOC}}` | {{COPEN_TITLE}} | {{COPEN_REASON}} |

## 8. Deferred findings (below floor or punted)

<!-- Surfaced so the user can lower the floor or pick them up manually. Not auto-fixed. -->

| ID | Sev | Conf | Area | Location | Title | Reason deferred |
|----|-----|-----:|------|----------|-------|-----------------|
| {{DEF_ID}} | {{DEF_SEV}} | {{DEF_CONF}} | {{DEF_AREA}} | `{{DEF_LOC}}` | {{DEF_TITLE}} | {{DEF_REASON}} |

## 9. Next action

**Convergence signal:** {{CONVERGENCE_SIGNAL}}
<!-- One of: improving · plateaued · converged -->

{{NEXT_ACTION}}
<!-- Pick the matching line:
  - LOOPING:    "→ Round {{NEXT_ROUND_N}}: re-running all {{REVIEWER_COUNT}} reviewers to verify {{TOT_FIXED}} fix(es) and catch regressions."
  - CLEAN:      "✓ No findings at/above floor and all gates green — handing checkpoint to user."
  - STALLED:    "■ No net progress vs. round {{PREV_ROUND_N}} ({{STALL_REASON}}) — stopping early, handing to user."
  - MAX_ROUNDS: "■ Round budget {{ROUND_MAX}} exhausted with {{TOT_OPEN}} open — handing to user with summary above."
-->

---

<sub>review-fleet · round {{ROUND_N}} · branch `{{REVIEW_BRANCH}}` · {{TIMESTAMP_ISO8601}} · reviewers run read-only; all edits by orchestrator on this branch only.</sub>
