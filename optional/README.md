# Optional add-ons (off by default)

Each item says what it costs on **every turn** while installed, and when it's worth it.
Install at **project scope** whenever the add-on only matters for some projects, so your other
work pays nothing. After adding anything, run `/context` (or `/skill-doctor` for skills) to see the real cost.

Everything here was checked on 2026-11-02 against Claude Code v2.1.316, Anthropic's official plugin
marketplace, and the source repos. `skill-index` was run against the real repos.

**Already installed by default** (by `install.sh`, in the `toolkit` index, ~83 tokens/turn for all four):
`systematic-debugging`, `pdf`, `xlsx`, `skill-creator`. Any skill you add later goes through
`~/.claude/bin/skill-index` automatically; a guard hook and a CLAUDE.md rule make sure of it.

## Menu

| Add-on | Always-on cost | Install if… |
|---|---|---|
| [Python code intelligence](#python-code-intelligence-pyright-lsp) | small (verify with `/context`) | You write Python. Anthropic's cost docs recommend LSP over grep-and-read exploration. |
| [Reviewer subagent](#reviewer-subagent) | ~40 tokens | You want a second opinion beyond the built-in `/code-review` |
| [More skills](#more-skills) | ~5–10 tokens each (one line in an index) | A specific procedure keeps coming up |
| [Blender (94 guides, as one index skill)](#blender) | **~15–36 tokens** (vs ~4,000 as a plugin) | You work in Blender. Project scope. |
| [Unreal Engine](#unreal-engine) | ~750 tokens, Unreal projects only | You work in Unreal. Project scope. |
| [Playwright browser MCP](#playwright) | tool names only (schemas deferred) | You build or test web UIs. Project scope. |

**Not recommended:** installing whole bundles (all of `obra/superpowers`, `everything-claude-code`, or a
plugin with dozens of skills). Superpowers also adds a session-start hook telling Claude to check its
skills before *every* response, which is overhead on small tasks. Cherry-pick instead, or index the bundle.

---

## Keeping big skill bundles cheap

Claude Code puts every model-invocable skill's name and description into context on every turn.
The listing is capped at 1% of the context window (`skillListingBudgetFraction`, default 0.01).
Past that cap, descriptions get shortened, which makes skills trigger less reliably. There is no
built-in on-demand loading for installed skills, so you have three levers, cheapest first:

1. **Index skill (the default here).** `skill-index` files skills into one index skill: a
   ~1-line description that's always in context, plus a table of guides read only when relevant, plus
   the guides themselves (renamed `GUIDE.md` so they're not registered individually). Claude still
   picks guides on its own. Tested: one registered skill, all links intact, and Claude picked the right
   3 of 94 guides for a sample task.
2. **`skillOverrides` in settings.** Per skill, `"name-only"` drops the description (~6 tokens),
   `"user-invocable-only"` hides it from Claude but keeps `/name` (0 tokens), and `"off"` hides it
   completely:
   ```json
   { "skillOverrides": { "xlsx": "name-only", "release": "user-invocable-only" } }
   ```
3. **`disable-model-invocation: true`** in a skill's own frontmatter. Use it for side-effect workflows
   (deploy, release) you only ever trigger yourself.

`/skill-doctor` shows per-skill cost and usage. Turn off whatever isn't used.

---

## Python code intelligence (pyright-lsp)
Gives Claude go-to-definition, references and type errors after each edit, instead of grepping and
reading whole files.
```bash
npm install -g pyright
```
```bash
claude plugin install pyright-lsp@claude-plugins-official
```
`pyright-langserver` must be on your PATH (the npm package provides it). For C/C++ use
`clangd-lsp@claude-plugins-official`, which needs `clangd` on PATH (e.g. `brew install llvm`).
Official LSP plugins also exist for TypeScript, Rust, Go, Java, C#, Swift and more; see `/plugin`.
There's no official R language server plugin.

## Reviewer subagent
A read-only reviewer that hasn't seen your reasoning (the real reason fresh reviewers catch more).
It runs on Sonnet to keep cost down. It has Bash only for `git diff`/`grep`, and is told not to edit.
```bash
mkdir -p ~/.claude/agents && cp optional/agents/reviewer.md ~/.claude/agents/
```
Use it by asking "have the reviewer check this". `/code-review` already covers the common case, so
skip this if that's enough.

## More skills
You can just ask Claude ("add the docx skill from anthropics/skills", "make me a skill for X"). It will
use `skill-index`. Or run it yourself. It lists any bundled code for review and runs nothing:
```bash
~/.claude/bin/skill-index add anthropics/skills skills/docx --tag "Word documents"
```
```bash
~/.claude/bin/skill-index add ./my-draft-skill --tag "when to use it" --group lab   # your own skill; --group keeps related ones together
```
```bash
~/.claude/bin/skill-index list
```
`--project` puts a skill in this repo's `.claude/skills` instead of your user folder. `remove <group> <name>`
deletes one, `adopt <name>` moves an existing standalone skill into an index, and `rebuild` refreshes the
index after you edit a guide. Run `skill-index --help` for everything.

A skill that should trigger on its own very reliably can stay standalone: edit it directly or ask Claude
to. The guard only blocks *creating* new standalone skills.

## Blender
Source: [arjun988/blender-skills](https://github.com/arjun988/blender-skills) (MIT, 94 skills, Markdown only, no code).
Installing it as a plugin costs ~4k tokens on every turn (15.4k characters of descriptions). That's
above the 1% listing budget on 200k-context models, so descriptions would be shortened. Its bundled
MCP config also launches via `cmd /c`, which only works on Windows. So index it instead and add the
MCP server yourself.

In your Blender project:
```bash
~/.claude/bin/skill-index bundle arjun988/blender-skills .claude/skills blender "Index of 94 Blender guides (modeling, materials, rigging, VFX, export pipelines, art styles, Blender MCP). Use for any Blender or 3D asset task." --project
```
```bash
cp ~/path/to/claude-setup/optional/project-settings/blender.mcp.json .mcp.json
```
Drop `--project` to install the index for all projects instead (~36 tokens everywhere). Or just ask
Claude to "add the Blender skills from arjun988/blender-skills".
Re-run with `--force` to update (the old copy is moved to `.claude/skill-backups/`).

To let Claude drive Blender, use the MCP server [mcp-for-blender](https://github.com/ahujasid/mcp-for-blender)
(formerly `blender-mcp`):
1. Install [uv](https://docs.astral.sh/uv/getting-started/installation/), which provides `uvx`.
2. Install the add-on: download `addon.py` from that repo, then in Blender go to **Edit → Preferences → Add-ons → Install…**.
3. In Blender's 3D view press **N**, open the **BlenderMCP** tab and click **Connect to Claude**. It listens on `localhost:9876`.
4. In Claude Code, `/mcp` should show `blender` as connected.

`DISABLE_TELEMETRY=true` in the config turns off the server's anonymous telemetry; I checked the
variable name in the package source. The server can also call third-party asset APIs (Poly Haven,
Sketchfab and others) when you ask it to.

## Unreal Engine
Source: [EpicGames/unreal-engine-skills-for-claude-code-plugin](https://github.com/EpicGames/unreal-engine-skills-for-claude-code-plugin)
(MIT, in the official marketplace). Small: 3 skills (~750 tokens of descriptions) plus a session-start
hook. I read the hook: it only checks whether the folder is an Unreal project, and if so adds a ~80-token
note. It doesn't write files or use the network. The editor's MCP tools are deferred by tool search.

In your Unreal project (installs Unreal skills plus C++ code intelligence, for this project only):
```bash
claude plugin install unreal-engine-skills-for-claude-code@claude-plugins-official --scope project
```
```bash
claude plugin install clangd-lsp@claude-plugins-official --scope project
```
For a team, commit `project-settings/unreal.json` as the project's `.claude/settings.json`
(merge with what's there), and teammates are prompted to install. Then, in the Unreal editor console:
`ModelContextProtocol.StartServer`, then `ModelContextProtocol.GenerateClientConfig ClaudeCode` (writes `.mcp.json`).
clangd needs a `compile_commands.json` for Unreal C++. Generate one with Unreal's project-file tools.

## Playwright
Microsoft's browser automation MCP, from the official marketplace (runs `npx @playwright/mcp@latest`).
```bash
claude plugin install playwright@claude-plugins-official --scope project
```
For one-off checks, asking Claude to write a small Playwright script is often enough without the MCP.
