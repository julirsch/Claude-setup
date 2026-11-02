# Lean Claude Code playbook

**Core rule:** the defaults are strong. Add setup only when a specific, repeated problem shows up,
and remove it when it stops paying for itself. Every always-loaded token taxes every turn.

## 1. Habits (free, highest leverage)
| Habit | Why |
|---|---|
| Give Claude a check to run (tests, typecheck), and ask it to run it before saying it's done | Anthropic calls this the single most useful thing you can provide |
| Plan mode (Shift+Tab) for anything non-trivial; for big features, interview, write `SPEC.md`, then build in a fresh session | Cheap to fix a plan, expensive to fix code |
| `/clear` between unrelated tasks | Free; every request resends the whole conversation |
| After two failed corrections: `/rewind` (Esc Esc) or `/clear` and write a better prompt | A polluted context keeps failing |
| `/compact <focus>` only when you need to keep a long thread | Compaction is itself a big request |
| Don't leave sessions idle and then resume; start a fresh one | The prompt cache expires (~1 h on a subscription, 5 min on API keys) |
| Parallel work goes in separate worktrees (`claude --worktree`, or `git worktree`) | How the Claude Code team runs 3–5 sessions at once |
| `/code-review` before a PR | A fresh reviewer hasn't seen your reasoning, so it catches more |
| Use effort level for depth (`/effort`, or `ultrathink` for one turn); don't switch models mid-session | Switching models re-reads the whole conversation uncached |
| Write prompts plainly: no ALL CAPS, IMPORTANT, "don't be lazy", or "keep going" | Current models over-apply emphasis |

## 2. When to add a feature
| Signal you notice | Add | Keep it cheap by… |
|---|---|---|
| Claude gets the same project fact wrong twice | A line in the project `CLAUDE.md` | Staying under 200 lines (10–40 is better); no architecture tours |
| A rule must never be broken (and Claude keeps breaking it) | A `command` hook or a `deny` rule | Using hooks only for hard rules; preference hooks get deleted |
| You paste the same multi-step procedure three times | A skill, via `skill-index add` (it goes into an index automatically) | A short, specific description; `disable-model-invocation: true` for anything with side effects (deploy, release), which also keeps its description out of context |
| You keep copying data from a system Claude can't reach | An MCP server | Prefer a CLI (`gh`, `aws`, `gcloud`) when one exists; disable unused servers in `/mcp` |
| A side task floods the conversation with output, or you want an independent review | A subagent (`.claude/agents/<name>.md`) | A one-line description, minimal `tools:`, `model: haiku` for simple lookups |
| Rules apply only to part of the repo | `.claude/rules/*.md` with `paths:` frontmatter | Putting must-survive-compaction rules in the root CLAUDE.md instead |
| A second repo needs the same setup | A plugin | Packaging only what you've actually used |

Ready-made, tested options for each row are in `optional/README.md`.

## 3. Skip (unless measured otherwise)
- Wholesale skill or agent bundles (e.g. 70+ agents or 300+ skills). Add single skills or whole bundles with `~/.claude/bin/skill-index` (the default here), then check `/context` before and after.
- Mandatory-workflow frameworks for small tasks. Their ceremony costs more than it saves.
- Subagents "to protect context" or "for a better answer". 1M windows plus auto-compaction make this rarely necessary.
- Agent teams (about 7× tokens) and `/batch` dynamic workflows, except for genuinely large parallel jobs.
- Long permission allowlists. Auto mode covers most of it; allow only your frequent safe commands.
- "Token saver" repos. Measure with `/usage` instead.
- `@imports` as a way to "save tokens". Imported files load anyway.

## 4. Monthly audit (5 minutes)
1. `/usage`: see where tokens go by skill, subagent, plugin and MCP server. Press `f` to apply suggested fixes.
2. `/context`: check the baseline before you've typed anything. If it's large, find out why.
3. `/skill-doctor`: per-skill cost and usage; turn off what you don't use.
4. `/doctor prompt-audit`: finds stale or contradictory CLAUDE.md lines.
5. `/mcp`: disable servers you didn't use this month.
6. Delete any hook, skill, agent or CLAUDE.md line that hasn't earned its place.

## 5. Project setup in 2 minutes
1. `/init`, then delete most of what it writes. Keep the shape of `project-template/CLAUDE.md`.
2. Optional: copy `project-template/.claude/settings.example.json` to `.claude/settings.json`, fill in
   your formatter and a **fast** check command (a slow Stop hook runs on every turn end), and commit it.
3. Commit `CLAUDE.md` and `.claude/settings.json` so the team shares them; personal tweaks go in
   `.claude/settings.local.json` (git-ignored) or `CLAUDE.local.md`.
