# Migration scripts

- `sync-from-mac.sh`: refreshes portable OMP, shared skills, Cursor skills, Caveman plugin, Codex plugins, workflow inventory, secret audit, and manifest.
- `inventory-workflow.sh`: records Git repositories under `~/workflow` without copying project source.
- `build-manifest.sh`: hashes portable files and records the OMP snapshot.
- `audit-secrets.sh`: Mac payload secret audit.
- `bootstrap-windows.ps1`: installs the pinned OMP release and restores portable files.
- `audit-secrets.ps1`: Windows payload secret audit.
- `verify-windows.ps1`: checks version, themes, skills, paths, and migration status.

Provider authentication stays outside Git. Run `omp login openrouter` on Windows.
