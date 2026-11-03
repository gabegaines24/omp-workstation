# Fable Windows Setup

This file is the single execution plan for reproducing this OMP workstation on Windows.

Fable 5.1 must execute these instructions, not merely summarize them.

## Goal

Configure the current Windows machine to match the captured Mac workflow from this repository:

- OMP configuration, model roles, themes, symbols, skills, plugins, prompts, commands, rules, hooks, tools, and MCP files.
- Cursor settings, keybindings, snippets, skills, and extension list.
- Workflow project repositories listed in `projects/repos.json`.

Preserve native OMP discovery paths and relative layouts.

## Required procedure

1. Read `AGENTS.md` before changing anything.
2. Confirm the host is Windows.
3. Use PowerShell. Do not require WSL.
4. Run the bootstrap script from repository root:

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\bootstrap-windows.ps1
   ```

5. Run verification:

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify-windows.ps1
   ```

6. Read `MIGRATION-REPORT.md` and fix every actionable failure.
7. If provider authentication is missing, ask the user only to complete this local login:

   ```powershell
   omp login openrouter
   ```

8. Re-run verification after authentication.
9. Run one harmless, read-only OMP agent task from Cursor's PowerShell terminal.
10. Report completed checks, repaired Mac paths, skipped capabilities, cloned projects, and remaining manual actions.

## Safety rules

- Never print, copy, request, or commit API keys, OAuth tokens, passwords, private keys, `.env` files, databases, sessions, browser profiles, caches, logs, or credentials.
- Never delete existing OMP data. The bootstrap script must create a timestamped backup first.
- Never delete existing project directories.
- Never silently modify project source code.
- Never replace unsupported capabilities with fake fallbacks.
- Do not ask the user for paths or settings that scripts can discover.
- Pause only for provider authentication, secret entry, browser approval, or unavoidable transfer steps.
- Do not claim success until `verify-windows.ps1` passes.

## Success criteria

All of these must be true:

- Installed OMP version matches `MANIFEST.json`.
- OMP starts from Cursor's PowerShell terminal.
- Dark and light themes match the captured configuration.
- `symbolPreset` and `colorBlindMode` match.
- Expected skill files exist.
- OMP plugins and Codex plugins exist in their preserved layouts.
- Cursor settings, keybindings, snippets, skills, and extension records exist.
- Mac-only paths are removed from active Windows configuration.
- OpenRouter authentication works after local login.
- One harmless read-only agent task succeeds.
- Workflow repositories are cloned or explicitly reported.
- `MIGRATION-REPORT.md` records all skipped items and failures.

## Mac refresh

If this repository is running on the Mac source machine instead, do not run the Windows scripts. Run:

```sh
./scripts/sync-from-mac.sh
```

Then review the generated changes before committing them.
