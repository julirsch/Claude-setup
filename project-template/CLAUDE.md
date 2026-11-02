# <Project name>

<!--
Only write down what Claude can't find by reading the repo. Aim for 10–40 lines; stay under 200.
Not here: architecture tours, file-layout lists, tech-stack lists (Claude reads the code),
multi-step procedures (make a skill), ALL-CAPS or IMPORTANT emphasis (if a rule keeps being
ignored, make it a hook). Tip: run /init, then mostly delete lines.
-->

## Commands
- Install: `<e.g. pnpm install>`
- Check everything before calling a task done: `<e.g. pnpm typecheck && pnpm test>`
- Run one test file: `<e.g. pnpm vitest run path/to/file.test.ts>`
- Lint/format: `<e.g. pnpm lint --fix>`

## Conventions
- <e.g. Use the helpers in src/lib/errors.ts; never throw raw strings>
- <e.g. src/legacy/ is live code but don't copy its patterns>

## Gotchas
- <e.g. Integration tests need DATABASE_URL; see .env.example>
- <Anything you've had to correct Claude on twice>
