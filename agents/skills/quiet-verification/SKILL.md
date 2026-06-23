---
name: quiet-verification
description: ALWAYS use this skill before running install, restore, build, lint, typecheck, or test commands. Minimize log output aggressively and require explicit timeouts for full test suites. Do not skip it for dotnet, npm, yarn, pnpm, bun, or common JS/TS test runners. Only relax these rules when debugging a specific failure.
---

# Quiet Verification

Use quiet output by default for verification commands, and always protect full test suites with explicit timeouts.

## Rules
- use the quietest safe logging mode for install, restore, build, lint, typecheck, and test commands
- do not paste successful command logs into the conversation; report only the outcome
- increase verbosity only after failure or during targeted debugging
- always set an explicit timeout for full test suites
- start with these limits:
  - unit: 2 to 8 minutes
  - integration: 5 to 12 minutes
  - e2e: 8 to 20 minutes
- never let a full suite run exceed 20 minutes total
- if a timeout fires, isolate the slow or hanging test before increasing the timeout

## Dotnet
For `dotnet restore`, `dotnet build`, and `dotnet test`, always:
- use quiet verbosity: `-v q`
- use errors-only console logging: `/clp:ErrorsOnly`
- use an overall timeout for full test suites
- use hang protection for tests: `--blame-hang --blame-hang-timeout <timeout>`

Examples:
- `dotnet restore -v q /clp:ErrorsOnly`
- `dotnet build -v q /clp:ErrorsOnly`
- `dotnet test -v q /clp:ErrorsOnly --blame-hang --blame-hang-timeout 5m`

## JS/TS ecosystem
For `npm`, `yarn`, `pnpm`, and `bun`:
- prefer the quietest available mode
- suppress progress and spinner output when possible
- use an explicit timeout for full suite runs

Examples of preferred noise reduction:
- `npm`: `--silent`, `--loglevel=error`, `--no-progress`
- use equivalent quiet or minimal-reporter options for `yarn`, `pnpm`, and `bun`

## Fallback
For Jest, Vitest, Playwright, Cypress, and any other verification command or test runner:
- use the quietest available output mode
- use an explicit timeout for full suite or potentially long-running commands
- keep output concise by default
- if a run times out, isolate the slow or hanging step before increasing the timeout
