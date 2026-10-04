# research-team (Claude Code plugin)

Multi-channel research fan-out for Claude Code. Routes each research angle to the
channel that can actually reach it, runs them in parallel, and synthesizes in the
main loop — instead of letting one search tool answer a multi-angle question.

Ships as a self-contained plugin: the skill installs with one command; the search
channels are per-machine CLI/MCP installs (secrets never ride in a plugin).

## Roster

| Channel | Reaches |
|---|---|
| wigolo cache | every page already fetched — cross-session, 0ms, free (probed first) |
| wigolo web | general web — 18 engines fused + on-device rerank, local, keyless |
| codex | local repo, git history, `gh` |
| web-agent | blogs, forums, docs, non-X social |
| anysearch | general web + full-page extract (second source / fallback) |
| grok X search | X/Twitter — **real-time** posts, handles, threads via grok's native `x_*` tools — re-verified working 2026-10-04 (grok 1.0.46) |
| pplx search (Perplexity API) | Perplexity's index as raw ranked results — domain/date filters stand in for academic & finance modes. $5/1k calls |
| pplx agent (Perplexity API) | synthesized answer + sources — risk/assessment framing; preset `high` = deep research. `pplx-agent` (plugin `bin/`, on PATH), pay-per-call |
| watch | video you need to *see* — real frames + transcript, local (short clips/demos) |
| NotebookLM | long video/podcast/audio + PDFs — semantic Q&A |
| browser | login-walled / heavy-JS pages |
| Apify ⚠️paid | public Facebook/social scrapes — last resort, ~$5 credit |

See [skills/research-team/SKILL.md](./skills/research-team/SKILL.md) for the full
process, sizing rules, and channel notes.

## Install

```bash
# add this repo as a marketplace, then install the plugin
claude plugin marketplace add mp3wizard/research-team-plugin   # or a local path to this dir
claude plugin install research-team@research-team
```

The skill auto-discovers on the next session — no symlink step.

### Optional: make the routing mandatory

```bash
bash "$(claude plugin root research-team)/scripts/setup-research-team.sh"
```

Appends a global research-workflow rule to `~/.claude/CLAUDE.md` so every
external-info task is funnelled through this skill. The skill is discoverable
without it; the rule just makes routing non-optional. Idempotent.

### Per-machine channels (not shipped in the plugin)

```bash
# grok  (X search — real-time posts via native x_* tools)
curl -fsSL https://x.ai/cli/install.sh | bash      # macOS / Linux
grok login
# codex  (repo / git / gh)
npm i -g @openai/codex
# pplx  (Perplexity API — pay-per-call search + Agent API / deep research)
#   install per https://docs.perplexity.ai/docs/cli/overview, then:
pplx auth login
export PERPLEXITY_API_KEY=...   # also needed by pplx-agent (add to your shell profile)
# wigolo  (local web engine + cross-session cache)
npx wigolo init --agents=claude-code,codex
# watch  (video → frames + transcript): the /watch skill auto-installs ffmpeg/yt-dlp on first run
# anysearch / notebooklm / apify: claude mcp add ... then authenticate
```

## What syncs vs. what's per-machine

| | via the plugin | per machine |
|---|---|---|
| the skill (SKILL.md + scripts) | ✅ `claude plugin install` / `update` | — |
| global CLAUDE.md mandate rule | via `setup-research-team.sh` | run once (optional) |
| grok / codex / wigolo / pplx CLI + `PERPLEXITY_API_KEY` | ❌ | install + login |
| wigolo `~/.wigolo/` cache, watch `~/.config/watch/.env` | ❌ | local, never sync |
| MCP auth (anysearch, notebooklm, Apify) | ❌ | add + authenticate |

## Relationship to other skills

`research-team` references `/wayfinder`, `/deep-research`, and `/research` as
integration points. Those are separate skills (maintained in the
[mattpocock/skills](https://github.com/mattpocock/skills) plugin) — this plugin
does not bundle them. If you have them installed, the integrations light up; if
you don't, the references are inert. Nothing here hard-depends on their code.

## License

MIT.
