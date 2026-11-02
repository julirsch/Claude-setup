# Lean Claude Code setup

A minimal, measured Claude Code configuration, built from an audit (Nov 2026) of Anthropic's
current docs (code.claude.com/docs: best practices, costs, memory, skills, hooks, MCP),
popular GitHub setups, and practitioner advice on X and HN.

**Thesis:** the defaults are strong, and most "power setups" cost more context than they save.
This kit adds only things that cost **zero always-on tokens** (hooks, statusline, deny rules)
plus a tiny personal CLAUDE.md. Everything else is added when a specific problem shows up; see `PLAYBOOK.md`.

## What's in it
| Path | What | Always-on context cost |
|---|---|---|
| `user/CLAUDE.md` | ~10 lines of cross-project working preferences | ~150 tokens |
| `user/settings.json` | Deny reading secrets (.env, ~/.ssh, cloud creds); statusline; notification hook | 0 |
| `user/statusline.sh` | `Opus 5.5 (medium) · ctx 23% · 5h 41% · $0.82 · repo (branch)`, colour-coded | 0 |
| `user/hooks/notify.sh` | Desktop alert when Claude needs input (macOS/Linux, bell fallback) | 0 |
| `user/bin/skill-index` | Files every skill as a guide behind an index skill, so it's read only when needed | n/a |
| `user/bin/xread` | Reads an X post as JSON via public endpoints; exits with an ERROR if X is blocked | n/a |
| `user/hooks/guard-skills.sh` | Blocks creating standalone skills; tells Claude to use `skill-index` instead | 0 |
| Default skills (fetched at install) | `systematic-debugging`, `pdf`, `xlsx`, `skill-creator`, `x-research` (free X search: `site:x.com` web search + `xread`), all in one `toolkit` index | ~100 tokens total |
| `project-template/CLAUDE.md` | Skeleton: commands, conventions, gotchas | per project |
| `project-template/.claude/settings.example.json` | Opt-in formatter + Stop-hook check (fill in placeholders) | 0 |
| `PLAYBOOK.md` | Habits, a "when to add what" table, what to skip, monthly audit | n/a |
| `optional/` | Off-by-default add-ons: Python LSP, reviewer subagent, Blender (as one index skill), Unreal, Playwright | only what you install |
| `cloud-setup.sh` | Rebuilds all of this in a Claude Code cloud session (see below) | n/a |

Not installed by default: MCP servers, subagents, plugin bundles, model/effort overrides.
They're in `optional/README.md`, each with its per-turn cost and when it's worth it.
Model, effort and auto mode stay at their defaults; change them interactively with `/model` and `/effort`.

## Install (on your own machine)
```bash
git clone https://github.com/julirsch/claude-setup.git && cd claude-setup
./install.sh --dry-run   # preview
./install.sh             # backs up, merges; never overwrites an existing CLAUDE.md
```
Requires `jq` and `git`. Re-runnable. Backups go to `~/.claude/backups/lean-setup-<timestamp>/`.
`--no-skills` skips fetching the default skills.

## How skills stay cheap
Every model-invocable skill normally puts its description into context on every turn. Here, every skill
lives as a guide inside an **index skill**. Only the index's one-line description is always loaded; Claude
reads the index table and then the one guide it needs. Measured: 4 default skills cost ~83 tokens/turn
instead of ~480, and 94 Blender skills ~15–36 instead of ~4,000.

This is the default for every skill you add later, without you asking:
- `~/.claude/bin/skill-index add|bundle|adopt|remove|rebuild|list` does the filing.
- A short rule in `~/.claude/CLAUDE.md` tells Claude to use it.
- A `PreToolUse` hook (`guard-skills.sh`) blocks creating standalone skills in any `.claude/skills/`
  and tells Claude the right command. Editing existing skills is still allowed.

Tested in a real session: asked to "create a personal skill called cite-check", Claude (Haiku) filed it in
the `toolkit` index via `skill-index` on its own. A debugging question then led it through the index to
the `systematic-debugging` guide.

The one gap: `/plugin install` of a plugin that ships skills bypasses this. Prefer
`skill-index bundle <repo> <skills-dir> <name> "<description>"` for skill collections.

## Cloud sessions (claude.ai/code)
Cloud containers start fresh, so `~/.claude` has to be rebuilt each session. The environment's
**Setup script** does it in ~10 seconds (settings, hooks, `skill-index`, default skills, pyright LSP):
```bash
git clone -q --depth 1 https://github.com/julirsch/claude-setup ~/.claude-setup || git -C ~/.claude-setup pull -q
bash ~/.claude-setup/cloud-setup.sh
```
Put those two lines in: session title bar → cloud environment menu → **Edit** → **Setup script**.
The setup script can only clone a **private** repo if it's added under that environment's
**Repositories**. The Default environment has no Repositories section, so either create a new
environment with this repo added, or make this repo public (it contains no secrets).

What works in the cloud: all settings, hooks, skills, `skill-index`, pyright, and the pdf/xlsx skills
(the image has Python's PDF/Excel libraries and LibreOffice; OCR of scanned PDFs needs tesseract, which
isn't installed). What doesn't: the Blender and Unreal MCP servers, which need the desktop apps on
your computer. Their guides still work for advice. The desktop notification and statusline don't
apply in the web UI, and they're harmless there.


## Key findings behind it
- Every CLAUDE.md line is read on every turn. Anthropic: stay under 200 lines, write only what Claude
  can't learn from the repo, no architecture tours, no ALL-CAPS emphasis.
- Instructions are advisory; hooks and deny rules are enforced. Use hooks for hard rules only.
- The highest-leverage single thing is a check command Claude can run to verify its work.
- MCP tool definitions are deferred by default now (tool search), but each server still adds
  instructions. CLIs like `gh` cost nothing until used.
- Skill descriptions load every turn unless `disable-model-invocation: true`. Big bundles have
  been reported to cost 50k+ tokens at startup (anthropics/claude-code#14882).
- Subagents cost extra tokens and re-gather context. Their real value is independent review and
  isolating noisy output, not "protecting context".
- The Claude Code team's own setup is modest: a short shared CLAUDE.md, plan mode, verification,
  a formatter hook, and parallel worktrees.
