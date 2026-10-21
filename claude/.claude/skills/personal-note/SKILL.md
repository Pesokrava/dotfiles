---
name: personal-note
description: Use when the user wants to jot, save, or file a personal note, remark, or pre-GA TODO, or asks what their personal notes say about a topic — phrases like "note this", "personal note", "remember for GA", "add to my TODOs", "what did I note about X", "check my notes", or /personal-note.
---

# Personal Note

One Notion page holds the user's personal pre-GA remarks and TODOs. This skill
reads it or appends to it, nothing else.

**Page:** `https://app.notion.com/p/Personal-Pre-GA-TODOs-3d19c62101548177884de77a0b031d96`
(id `3d19c62101548177884de77a0b031d96`). Use the Notion MCP tools `notion-fetch`
and `notion-update-page`. If the Notion MCP is not connected, say so and stop;
never write the note anywhere else.

## Decide the action

- Request mentions storing, adding, noting, remembering → **write**.
- Request asks what the notes say, whether something was noted, or to list TODOs → **recall**.
- Ambiguous → recall first, then ask whether to write.

## Recall

1. `notion-fetch` the page.
2. Answer from the page content only. Quote the matching section's heading and
   TODO line with its checkbox state; include the body only if the user asks for
   detail. Mention adjacent sections in one line each; skip near-misses. If
   nothing matches and the fetch result is not `truncated`, say nothing matches.
3. Do not update the page during a recall.

## Write

1. `notion-fetch` the page first — check whether the subject already has a
   section. If it does, amend that section via `notion-update-page` instead of
   adding a duplicate.
2. New subject → `notion-update-page` with an `insert_content_after` command
   anchored on the last block of the page, so the section lands at the end. The
   `# New Remarks` heading mid-page is a placeholder, not an insertion point.
   Follow the page's existing shape:

```markdown
# <Short Title Case subject>
- [ ] <one-line actionable TODO>
<one or two sentences of context: what is true today and why it is not GA-ready>
## Required Resolution
- <concrete step>
## Acceptance Criteria
- <verifiable check>
Source: `<repo path or ticket>`
```

   Omit `Required Resolution` / `Acceptance Criteria` for a plain remark with no
   action. Always include `Source:` when a repo path or ticket exists.
3. Write current state only — no "previously", "changed from", or change history.
4. Never edit or tick another section's checkbox unless the user asks.
5. Reply with the section title and one line confirming it landed.

## Common mistakes

- Writing before fetching → duplicate sections.
- Inserting under `# New Remarks` or prepending → sections out of order. Append at the end.
- Paraphrasing on recall → quote the page; the user wrote it deliberately.
