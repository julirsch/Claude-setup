# Personal preferences (all projects)

Keep this file short: every line is read on every turn. Add a line only after
correcting Claude on the same thing twice. Project facts go in the project's CLAUDE.md.

## How I work
- Before saying a change is done, run the project's check command (tests, typecheck or lint) and report the real result.
- If a request is ambiguous and the wrong guess would be costly, ask one short question. Otherwise pick a sensible default and say which you picked.
- If I name a resource to use (file, folder, repo, site, post, tool, service) and you can't access it, stop and tell me right away. Then work on getting access: find exactly what blocks it and what I need to do. Don't continue without it or report it only as a limitation.
- Prefer the smallest change that solves the problem. Don't refactor unrelated code or add dependencies without saying why.
- Prefer existing command-line tools (gh, git, jq, the project's scripts) over writing new helpers.
- Commit only when I ask. Never force-push to a shared branch.

## Skills
- Add or create skills only through `~/.claude/bin/skill-index` (see `--help`). It files each skill as a guide behind an index skill, so it costs almost nothing until used.
- For a new skill, draft its folder in a temp directory, then run `skill-index add <dir> --tag "<when to use it>"`. For a collection, prefer `skill-index bundle` over installing a skill-heavy plugin.

## About me
<!-- Fill in only things Claude can't infer from the code. Delete the placeholders you don't use. -->
<!-- - Primary languages/stacks: ... -->
<!-- - Package manager preference: ... (e.g. pnpm over npm, uv over pip) -->
