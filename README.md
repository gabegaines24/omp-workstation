# omp-workstation

Private portability repository for this machine's `oh-my-pi` (`omp`) coding-agent setup.

This repository preserves portable configuration. It does not preserve credentials, databases, session history, caches, browser state, or platform-native binaries.

## Current snapshot

- OMP release: `18.14.1`
- Active OMP directory: `~/.omp/agent`
- Dark theme: `legible-dark`
- Light theme: `light-tokyo-night`
- Symbol preset: `ascii`
- Skill files captured: 235

## Use from Mac

Run from this repository:

```sh
./scripts/sync-from-mac.sh
```

That command refreshes portable OMP files, inventories workflow repositories, audits secrets, and rebuilds `MANIFEST.json`.

Review the generated changes before committing them.

## Use from Windows

Open this repository in Cursor. Ask the agent to read `AGENTS.md`, then run:

```powershell
.\scripts\bootstrap-windows.ps1
.\scripts\verify-windows.ps1
```

The bootstrap script installs the pinned OMP release, restores portable files, repairs Mac-only interpreter paths, and clones missing Git repositories.

OpenRouter authentication remains a local login step:

```powershell
omp login openrouter
```

Never place that key in this repository.

## Repository layout

- `omp/agent/`: portable OMP profile files.
- `omp/agent/skills/`: dereferenced skill files.
- `omp/plugins/`: portable OMP plugin metadata.
- `omp/caveman-plugin/`: portable Caveman plugin source.
- `cursor/skills-cursor/`: Cursor-managed skill files present on this machine.
- `cursor/user/`: Cursor settings, keybindings, and snippets.
- `cursor/extensions.json`: installed Cursor extension IDs and versions.
- `external/codex/plugins/`: portable Codex plugin payloads discovered on this machine.
- `projects/repos.json`: workflow repository inventory.
- `scripts/`: Mac synchronization, Windows bootstrap, verification, manifest, and secret audit tools.
- `OMP-WINDOWS-MIGRATION.md`: detailed migration runbook.
- `MANIFEST.json`: snapshot metadata and file hashes.

## Deliberately excluded

- `.env` files.
- API keys and OAuth credentials.
- Private keys.
- OMP SQLite databases and WAL files.
- Session transcripts and blobs.
- Browser profiles.
- Caches and logs.
- Mac native binaries.

The Windows machine must authenticate providers again. This is required for safe credential handling.
