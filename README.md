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
| `project-template/CLAUDE.md` | Skeleton: commands, conventions, gotchas | per project |
| `project-template/.claude/settings.example.json` | Opt-in formatter + Stop-hook check (fill in placeholders) | 0 |
| `PLAYBOOK.md` | Habits, a "when to add what" table, what to skip, monthly audit | n/a |

Deliberately **not** included: MCP servers, subagents, skill or plugin bundles, model/effort overrides.
Model, effort and auto mode stay at their defaults; change them interactively with `/model` and `/effort`.

## Install (on your own machine)
```bash
git clone <this repo> && cd claude-setup
./install.sh --dry-run   # preview
./install.sh             # backs up, merges; never overwrites an existing CLAUDE.md
```
Requires `jq`. Re-runnable. Backups go to `~/.claude/backups/lean-setup-<timestamp>/`.

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
