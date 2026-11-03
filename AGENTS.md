# OMP Workstation Agent Instructions

## Mission

Maintain this repository as the portable source of truth for the user's `oh-my-pi` (`omp`) coding workflow.

The repository must let a Cursor agent reproduce the Mac setup on Windows with minimal user involvement.

When the user requests Windows setup, execute `FABLE-SETUP.md` as the single task file. Do not ask the user to restate its instructions.

## Operating rules

1. Read this file before changing anything.
2. Detect the current operating system before executing scripts.
3. On macOS, run `scripts/sync-from-mac.sh` to refresh the snapshot.
4. On Windows, run `scripts/bootstrap-windows.ps1`, then `scripts/verify-windows.ps1`.
5. Preserve OMP's native discovery layout. Do not flatten skills, commands, rules, tools, hooks, or plugins.
6. Do not convert OMP skills into always-on Cursor rules.
7. Do not copy OMP databases, sessions, caches, logs, browser profiles, credentials, or native binaries.
8. Do not print or commit secret values.
9. Do not ask the user for paths or settings that commands can discover.
10. Ask the user only for provider login, secret entry, browser approval, or an unavoidable manual transfer.
11. Back up existing Windows OMP data before importing.
12. Never delete backups or existing project directories.
13. Never silently modify project source code.
14. Record every skipped item, platform path repair, and failed check in `MIGRATION-REPORT.md`.
15. Do not claim completion until verification passes.

## Portable OMP roots

Preserve these roots and their relative layout:

- `omp/agent/`
- `omp/plugins/`
- `omp/caveman-plugin/`
- `cursor/skills-cursor/`
- `cursor/user/`
- `cursor/extensions.json`
- `external/codex/plugins/`

The Windows target is normally `%USERPROFILE%\\.omp`. Named OMP profiles must remain named profiles.

## Required verification

Verify all of these after Windows import:

- OMP version matches `MANIFEST.json`.
- OMP starts from Cursor's PowerShell terminal.
- `theme.dark`, `theme.light`, `symbolPreset`, and `colorBlindMode` match.
- Expected skill directories contain `SKILL.md` files.
- Commands, rules, prompts, instructions, hooks, tools, extensions, and MCP files exist.
- `models.yml` matches the captured portable configuration.
- No active configuration contains Mac-only paths.
- OpenRouter authentication works after local login.
- One harmless read-only agent task succeeds.
- Workflow repositories are cloned or explicitly reported.

## Secret handling

Provider credentials must be recreated locally on Windows. Use `omp login openrouter` or a local untracked `.env` file.

Never add `.env`, `secrets.yml`, private keys, `agent.db`, session files, or credential databases to Git.

## Change policy

Prefer exact file copying over reinterpretation. If Windows requires a platform change, patch only the affected configuration and record the reason.

If a capability cannot run on Windows, preserve its source and document its missing runtime dependency. Do not replace it with a fake fallback.
