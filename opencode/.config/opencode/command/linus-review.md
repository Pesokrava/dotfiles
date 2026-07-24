---
description: Blunt Linus-Torvalds-style code/spec review — correctness, security, data structures, taste. No sugarcoating.
argument-hint: [file, PR, diff, or spec to review — defaults to the working diff]
---

Use the `linus-review` skill to review $ARGUMENTS.

If no target is given, review the current working diff (`git diff` + staged changes).

Follow the skill exactly: priority-ordered lens, every finding carries a concrete
failure scenario and a fix, ranked worst-first, ending with a MERGE / MERGE AFTER
FIXES / REJECT verdict.
