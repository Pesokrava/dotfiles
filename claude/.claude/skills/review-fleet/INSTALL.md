# review-fleet installation

This package contains the `review-fleet` skill, including the 22-reviewer fleet,
shared reviewer contract, templates, and Codex interface metadata.

## Option A: shared skill pool

Use this when Codex, Claude Code, and future agents should read the same skill
folder.

```sh
mkdir -p ~/.agents/skills ~/.codex/skills ~/.claude/skills
cp -R review-fleet ~/.agents/skills/
ln -sfn ~/.agents/skills/review-fleet ~/.codex/skills/review-fleet
ln -sfn ~/.agents/skills/review-fleet ~/.claude/skills/review-fleet
```

## Option B: Codex only

```sh
mkdir -p ~/.codex/skills
cp -R review-fleet ~/.codex/skills/
```

## Option C: Claude Code only

```sh
mkdir -p ~/.claude/skills
cp -R review-fleet ~/.claude/skills/
```

## Verify

Start a new agent session and ask it to run `review-fleet` on a small local diff
or PR in report-only mode. The agent should load `review-fleet/SKILL.md`, the
shared contract at `review-fleet/reviewers/_contract.md`, and the reviewer files
under `review-fleet/reviewers/`.
