# Personal preferences (all projects)

Keep this file short: every line is read on every turn. Add a line only after
correcting Claude on the same thing twice. Project facts go in the project's CLAUDE.md.

## How I work
- Before saying a change is done, run the project's check command (tests, typecheck or lint) and report the real result.
- If a request is ambiguous and the wrong guess would be costly, ask one short question. Otherwise pick a sensible default and say which you picked.
- Prefer the smallest change that solves the problem. Don't refactor unrelated code or add dependencies without saying why.
- Prefer existing command-line tools (gh, git, jq, the project's scripts) over writing new helpers.
- Commit only when I ask. Never force-push to a shared branch.

## About me
<!-- Fill in only things Claude can't infer from the code. Delete the placeholders you don't use. -->
<!-- - Primary languages/stacks: ... -->
<!-- - Package manager preference: ... (e.g. pnpm over npm, uv over pip) -->
