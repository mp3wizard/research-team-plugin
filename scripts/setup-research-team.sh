#!/usr/bin/env bash
# Optional setup for the research-team plugin.
#
# The plugin's skill is discoverable on its own once installed — you do NOT need
# this script to use it. Run it only if you want the routing to be MANDATORY:
# it appends a global research-workflow rule to ~/.claude/CLAUDE.md so every
# task that gathers external information is funnelled through this skill.
#
# Idempotent — safe to re-run; it no-ops if the rule is already present.
#
# CLI/MCP channels (grok, codex, pplx, wigolo, anysearch, notebooklm, apify) are
# per-machine installs — see this skill's "Setup on a new machine" section.
set -euo pipefail

CLAUDE_MD="$HOME/.claude/CLAUDE.md"
MARKER="Research Workflow"

mkdir -p "$HOME/.claude"
if [ -f "$CLAUDE_MD" ] && grep -q "$MARKER" "$CLAUDE_MD"; then
  echo "[setup] research rule already in $CLAUDE_MD — nothing to do"
  exit 0
fi

cat >> "$CLAUDE_MD" <<'RULE'

## Research Workflow

Any task that gathers external information — web lookups, "หาข้อมูล/ค้นเพิ่ม", investigating tools/libraries/topics, community reactions, video content, repo history — MUST follow the `research-team` skill (multi-channel fan-out: wigolo cache→memory, wigolo/anysearch/web-agent→web, codex→repo/git, grok→X/Twitter, pplx (Perplexity API)→assessment/academic/deep research, watch→video-you-must-see, NotebookLM→long media, browser→blocked pages; synthesize in the main loop). Apify is a paid last-resort scraping channel (~$5 credit) — never call it without confirming cost with the user first; see the skill's budget gate.

This applies at every entry point:
- `/wayfinder` — research tickets resolve via research-team; when charting a map, add "Research tickets follow the research-team skill" to the map's `## Notes`.
- `/deep-research` and `/research` — instruct their fan-out subagents to use the research-team roster (grok for X angles, watch/NotebookLM for video sources, codex for repo angles), not WebSearch alone.
- Ad-hoc questions — size per the skill (small → wigolo cache then search; medium+ → fan out).

Never use `agy` (Antigravity) for research. Never let a search channel write the final synthesis (this includes wigolo's own `research`/`agent` tools).
RULE

echo "[setup] appended research rule to $CLAUDE_MD"
echo "[setup] done. Next: install the CLI/MCP channels (see research-team SKILL.md)."
