<!--
  review-fleet / non-editing report  (SKILL.md §3A and propose-only note in §3)
  One single Markdown file for a read-only, single-round audit or verified fix plan.
  NO fixes were made.
  Organization (exactly this order):
    1. collected BY REVIEWER / AREA  (the 22 areas, roster order — _contract.md §2)
    2. within each area, GROUPED BY SEVERITY: blocker → critical → major → minor → info
    3. within each group, SORTED by `confidence` (probability the finding is REAL) descending
  Severity + confidence + id use the canonical scheme from reviewers/_contract.md §3
  (blocker|critical|major|minor|info ; confidence 0.0–1.0 ; id = area:path:symbol:slug).
  Placeholders are {{UPPER_SNAKE}}. Every issue MUST quote real evidence — no evidence, no issue.
-->

# review-fleet — {{REPORT_TITLE}}

**Scope:** {{TARGET_SUMMARY}}  ·  **Base:** `{{BASE_REF}}`  ·  **Head:** `{{HEAD_SHA}}`
**Generated:** {{TIMESTAMP_ISO8601}}  ·  **Reviewers:** {{REVIEWER_COUNT}} ({{REVIEWER_LIST}})

> **{{REPORT_MODE_SUMMARY}}** No branch, no commits, no edits.
> {{REPORT_FOLLOWUP}}

---

## Summary

**Total findings: {{TOTAL}}** — blocker {{N_BLOCKER}} · critical {{N_CRITICAL}} · major {{N_MAJOR}} · minor {{N_MINOR}} · info {{N_INFO}}

<!-- One row per area; areas with zero findings still listed (a zero row is signal). -->

| Area | Blocker | Critical | Major | Minor | Info | Total |
|------|--------:|---------:|------:|------:|-----:|------:|
| correctness | {{C_B}} | {{C_C}} | {{C_MAJ}} | {{C_MIN}} | {{C_I}} | {{C_T}} |
| concurrency-resources | {{CR_B}} | {{CR_C}} | {{CR_MAJ}} | {{CR_MIN}} | {{CR_I}} | {{CR_T}} |
| performance | {{P_B}} | {{P_C}} | {{P_MAJ}} | {{P_MIN}} | {{P_I}} | {{P_T}} |
| scale | {{SC_B}} | {{SC_C}} | {{SC_MAJ}} | {{SC_MIN}} | {{SC_I}} | {{SC_T}} |
| error-handling | {{EH_B}} | {{EH_C}} | {{EH_MAJ}} | {{EH_MIN}} | {{EH_I}} | {{EH_T}} |
| architecture-design | {{AD_B}} | {{AD_C}} | {{AD_MAJ}} | {{AD_MIN}} | {{AD_I}} | {{AD_T}} |
| api-contract | {{AC_B}} | {{AC_C}} | {{AC_MAJ}} | {{AC_MIN}} | {{AC_I}} | {{AC_T}} |
| data-migrations | {{DM_B}} | {{DM_C}} | {{DM_MAJ}} | {{DM_MIN}} | {{DM_I}} | {{DM_T}} |
| release-rollout | {{RR_B}} | {{RR_C}} | {{RR_MAJ}} | {{RR_MIN}} | {{RR_I}} | {{RR_T}} |
| duplication-reuse | {{DR_B}} | {{DR_C}} | {{DR_MAJ}} | {{DR_MIN}} | {{DR_I}} | {{DR_T}} |
| readability-maintainability | {{RM_B}} | {{RM_C}} | {{RM_MAJ}} | {{RM_MIN}} | {{RM_I}} | {{RM_T}} |
| security | {{S_B}} | {{S_C}} | {{S_MAJ}} | {{S_MIN}} | {{S_I}} | {{S_T}} |
| privacy-governance | {{PG_B}} | {{PG_C}} | {{PG_MAJ}} | {{PG_MIN}} | {{PG_I}} | {{PG_T}} |
| supply-chain-ci | {{SCI_B}} | {{SCI_C}} | {{SCI_MAJ}} | {{SCI_MIN}} | {{SCI_I}} | {{SCI_T}} |
| ai-llm-safety | {{AILLM_B}} | {{AILLM_C}} | {{AILLM_MAJ}} | {{AILLM_MIN}} | {{AILLM_I}} | {{AILLM_T}} |
| testing | {{T_B}} | {{T_C}} | {{T_MAJ}} | {{T_MIN}} | {{T_I}} | {{T_T}} |
| observability | {{O_B}} | {{O_C}} | {{O_MAJ}} | {{O_MIN}} | {{O_I}} | {{O_T}} |
| reliability-resilience | {{REL_B}} | {{REL_C}} | {{REL_MAJ}} | {{REL_MIN}} | {{REL_I}} | {{REL_T}} |
| accessibility | {{A11Y_B}} | {{A11Y_C}} | {{A11Y_MAJ}} | {{A11Y_MIN}} | {{A11Y_I}} | {{A11Y_T}} |
| internationalization | {{I18N_B}} | {{I18N_C}} | {{I18N_MAJ}} | {{I18N_MIN}} | {{I18N_I}} | {{I18N_T}} |
| product-domain | {{PD_B}} | {{PD_C}} | {{PD_MAJ}} | {{PD_MIN}} | {{PD_I}} | {{PD_T}} |
| documentation | {{D_B}} | {{D_C}} | {{D_MAJ}} | {{D_MIN}} | {{D_I}} | {{D_T}} |
| **TOTAL** | **{{N_BLOCKER}}** | **{{N_CRITICAL}}** | **{{N_MAJOR}}** | **{{N_MINOR}}** | **{{N_INFO}}** | **{{TOTAL}}** |

---

## Findings by reviewer

<!--
  Repeat the AREA block below for ALL 22 areas, in roster order. If an area has no
  findings, emit just:  "### <area>\n\n_No findings._"
  Within an area, emit only the severity groups that have findings, in the fixed
  order blocker → critical → major → minor → info. Within a group, render one ISSUE
  block per finding, sorted by confidence (probability the finding is REAL) descending.

  ISSUE BLOCK template (every field comes from the finding's _contract.md §3 schema):

    #### {{SEVERITY}} · {{TITLE}}
    - **ID:** `{{ID}}`
    - **Location:** `{{FILE}}:{{LINE_START}}-{{LINE_END}}`  <!-- if occurrences[]: append " · also: {{FILE}}:{{LINE_START}}-{{LINE_END}}" per extra location -->
    - **Header:** {{one-sentence issue header from `title`}}
    - **Description:** {{wide description of the issue and why it is wrong}}
    - **Implications:** {{what breaks, for whom, the security/performance/design/productivity cost if left as-is — the `description` impact}}
    - **Probability (finding is real):** {{CONFIDENCE as 0.0–1.0}}  ·  **Blocking:** {{true|false}}  ·  **Effort:** {{trivial|small|medium|large}}{{ · **CWE:** {{CWE}} for security}}
    - **Likelihood of occurrence:** {{likelihood — how often the issue actually fires + the operating condition that triggers it: day-to-day | high-load | adversarial | edge-case | failure-mode (distinct from the Probability above, which is whether the finding is real)}}
    - **Examples / scenarios:** {{scenarios[] — concrete inputs/conditions under which it bites; one per line if several}}
    - **Source of truth:** {{references[] — official docs, upstream source, advisories/CVEs, standards, spec/ADR/checklist URLs, or "none"}}
    - **Evidence:**
      ```
      {{verbatim quoted source from FILE:LINE_START..LINE_END}}
      ```
    - **Recommendation:** {{the concrete minimal change; may include a fenced diff}}
-->

### correctness

#### blocker · {{TITLE}}
- **ID:** `{{ID}}`
- **Location:** `{{FILE}}:{{LINE_START}}-{{LINE_END}}`
- **Header:** {{TITLE}}
- **Description:** {{DESCRIPTION}}
- **Implications:** {{IMPLICATIONS}}
- **Probability (finding is real):** {{CONFIDENCE}}  ·  **Blocking:** {{BLOCKING}}  ·  **Effort:** {{EFFORT}}
- **Likelihood of occurrence:** {{LIKELIHOOD}}
- **Examples / scenarios:** {{SCENARIOS}}
- **Source of truth:** {{REFERENCES}}
- **Evidence:**
  ```
  {{EVIDENCE}}
  ```
- **Recommendation:** {{RECOMMENDATION}}

<!-- …more correctness issues (critical, major, minor, info groups in order)… -->

### concurrency-resources
_No findings._

### performance
_No findings._

### scale
_No findings._

### error-handling
_No findings._

### architecture-design
_No findings._

### api-contract
_No findings._

### data-migrations
_No findings._

### release-rollout
_No findings._

### duplication-reuse
_No findings._

### readability-maintainability
_No findings._

### security
_No findings._

### privacy-governance
_No findings._

### supply-chain-ci
_No findings._

### ai-llm-safety
_No findings._

### testing
_No findings._

### observability
_No findings._

### reliability-resilience
_No findings._

### accessibility
_No findings._

### internationalization
_No findings._

### product-domain
_No findings._

### documentation
_No findings._

---

<sub>review-fleet · {{REPORT_MODE_FOOTER}} · {{TIMESTAMP_ISO8601}} · no changes were made to the code under review.</sub>
