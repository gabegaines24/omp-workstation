# OMP Windows Migration Runbook

## Cursor agent instruction

This runbook is stored inside the `omp-workstation` repository.

When the repository is present, use it as the transfer source. Do not create a second ZIP archive.

Run the matching command:

```text
macOS:   ./scripts/sync-from-mac.sh
Windows: .\scripts\bootstrap-windows.ps1
Windows: .\scripts\verify-windows.ps1
```

Read root `AGENTS.md` first. It has precedence over this legacy two-machine explanation.

The goal is to reproduce the user's current `oh-my-pi` (`omp`) workflow on Windows:

- same OMP release
- same settings
- same themes and colors
- same skills
- same commands, rules, prompts, hooks, tools, extensions, and MCP configuration
- same model configuration
- OpenRouter ready after local authentication
- same workflow-directory project map

Do not replace OMP with Cursor rules. OMP must run natively on Windows.

If this file is used outside `omp-workstation`, follow the archive-based fallback phases below.

## Non-negotiable safety rules

1. Never print, copy, commit, or upload API keys, OAuth tokens, passwords, private keys, `.env` values, browser credentials, or secret database contents.
2. Never copy live SQLite databases, WAL files, caches, logs, browser profiles, or platform-native binaries.
3. Never delete an existing Windows OMP installation. Back it up before changing it.
4. Never overwrite an existing Windows project or configuration without creating a backup.
5. Never silently rewrite project source code. Only migrate OMP configuration and report project path changes.
6. Never guess a missing path. Inspect it, record it, or report it.
7. Ask the user only for secret entry, browser authentication, or physical file transfer.
8. Do not expose secret values in command output, reports, manifests, diffs, or chat.
9. Stop if a safety scan finds a credential-shaped value in the transfer payload. Report file paths only.
10. Complete verification after each phase. Do not finish after merely creating files.

## Portable versus machine-specific data

Migrate these portable OMP capabilities:

- `config.yml` or `config.yaml`
- `models.yml`
- custom themes
- authored skills
- managed skills
- slash commands
- rules
- prompts
- instructions
- hooks
- custom tools
- extensions and plugins
- MCP configuration
- `AGENTS.md`, `RULES.md`, `SYSTEM.md`, `SYSTEM_TEMPLATE.md`, `APPEND_SYSTEM.md`, and `TITLE_SYSTEM.md`
- keybindings
- non-secret project metadata

Do not migrate these runtime artifacts:

- `agent.db`, `history.db`, `models.db`, `skill-descriptions.db`, `stats.db`, and related `-wal` or `-shm` files
- session transcripts, blobs, terminal sessions, logs, caches, lock files, and run directories
- `natives/` and other compiled platform-specific modules
- browser profiles and Puppeteer data
- `.env`, `secrets.yml`, `secret-placeholder.key`, private keys, and credentials

Old session history and stored credentials are optional separate migrations. Re-authenticate providers on Windows instead.

## Phase A — Export from Mac

### A1. Inspect the active OMP installation

Run these commands without modifying OMP:

```sh
set -eu

command -v omp
omp --version
omp config path
```

Capture these values in memory and in the manifest, excluding secrets:

- OMP version
- active agent directory from `omp config path`
- active OMP profile name, if `OMP_PROFILE` is set
- `PI_CONFIG_DIR`, if set
- `PI_CODING_AGENT_DIR`, if set
- current home directory
- workflow directory path, if it exists

The current installation is expected to report `omp/18.14.1`, but always trust the live command output.

Resolve paths dynamically. Do not assume the active agent directory is the default if `omp config path` reports another path.

Define:

```sh
OMP_AGENT_DIR="$(omp config path)"
OMP_ROOT="$(cd "$OMP_AGENT_DIR/.." && pwd)"
TRANSFER_DIR="$HOME/Desktop/omp-windows-transfer-$(date +%Y%m%d-%H%M%S)"
```

Create this layout:

```text
omp-windows-transfer-<timestamp>/
├── MANIFEST.json
├── OMP-WINDOWS-MIGRATION.md
├── payload/
│   └── omp-root/
├── projects/
│   ├── repos.json
│   └── README.md
└── windows/
    └── IMPORT-RESULT.md
```

Copy this runbook into the transfer directory.

### A2. Copy portable OMP configuration

Copy the active OMP root into `payload/omp-root/`.

Use `rsync` or an equivalent file-copy operation. Exclude all runtime and secret paths listed below:

```text
**/.env
**/.env.*
**/secrets.yml
**/secret-placeholder.key
**/*.db
**/*.db-wal
**/*.db-shm
**/sessions/
**/terminal-sessions/
**/blobs/
**/cache/
**/logs/
**/run/
**/natives/
**/browser-profiles/
**/puppeteer/
```

Keep these paths when present:

```text
agent/config.yml
agent/config.yaml
agent/models.yml
agent/themes/
agent/skills/
agent/managed-skills/
agent/commands/
agent/rules/
agent/prompts/
agent/instructions/
agent/hooks/
agent/tools/
agent/extensions/
agent/mcp.json
agent/.mcp.json
agent/AGENTS.md
agent/RULES.md
agent/SYSTEM.md
agent/SYSTEM_TEMPLATE.md
agent/APPEND_SYSTEM.md
agent/TITLE_SYSTEM.md
agent/keybindings.json
agent/keybindings.yml
agent/keybindings.yaml
plugins/
caveman-plugin/
```

Preserve custom plugin source and configuration. Do not copy installed native dependencies blindly. Record plugin paths and versions in `MANIFEST.json`.

### A3. Record effective settings without secrets

Run:

```sh
omp config list --scope global --json
```

Store the output only if it contains no secrets. OMP normally redacts credential settings. If any value looks sensitive, omit that value and record only its setting name.

Record these files and directories in `MANIFEST.json`:

- relative path
- file or directory type
- byte size
- SHA-256 hash for regular files
- whether the item needs Windows path review

Do not store absolute Mac paths as replacement values. Store them only in a private migration report if needed.

### A4. Record theme and skill state

Inspect the active config and record:

```yaml
symbolPreset: <value>
theme.dark: <value>
theme.light: <value>
colorBlindMode: <value>
```

Verify custom theme files exist for selected non-built-in themes.

Count authored and managed skills. Record skill names and relative paths. Do not include skill contents in the manifest; the files are already in the payload.

The standard OMP skill layout is:

```text
<agent-dir>/skills/<skill-name>/SKILL.md
<agent-dir>/managed-skills/<skill-name>/SKILL.md
```

### A5. Record OpenRouter without exporting credentials

Inspect `models.yml`, configuration, and provider names.

Record:

- whether OpenRouter appears in model configuration
- configured OpenRouter model IDs
- selected model roles
- presence of `OPENROUTER_API_KEY` without recording its value
- whether authentication appears stored or environment-based

Exclude all API key values from the payload.

The Windows phase will use one of these safe actions:

```text
omp login openrouter
```

or manual entry into the Windows active agent `.env` file.

### A6. Record workflow projects

If `~/workflow` exists, inspect it without changing project files.

Create `projects/repos.json` containing, for each project:

- Mac path
- proposed Windows path under `%USERPROFILE%\workflow`
- repository name
- origin URL, if available
- current branch
- clean or dirty working tree state
- presence of `.omp`, `.cursor`, `AGENTS.md`, or other agent configuration

Never include uncommitted source files or secret files in this archive.

For non-Git projects, record the path and mark the project as requiring manual transfer.

Create `projects/README.md` explaining that repositories should be cloned from their private remotes. Do not place active repositories in OneDrive.

### A7. Scan transfer payload for secrets

Scan payload text files for credential-shaped values.

The scan may report file paths and line numbers, but never matching text.

At minimum check for:

```text
OPENROUTER_API_KEY=
ANTHROPIC_API_KEY=
OPENAI_API_KEY=
*_TOKEN=
*_SECRET=
*_PASSWORD=
Bearer <token>
sk-or-
sk-
-----BEGIN .* PRIVATE KEY-----
```

If a likely secret is found:

1. Remove the secret-bearing file from the payload, or replace the value with a placeholder.
2. Record the file path in `MANIFEST.json` as requiring manual recreation.
3. Re-run the scan.
4. Stop if the scan still finds a likely secret.

Do not paste scan matches into the Cursor conversation.

### A8. Create manifest and archive

Create `MANIFEST.json` with this shape:

```json
{
  "format": 1,
  "sourceOs": "macOS",
  "ompVersion": "omp/18.14.1",
  "sourceAgentDir": "<redacted-relative-or-placeholder>",
  "profile": "default",
  "portableRoot": "payload/omp-root",
  "workflowRoot": "~/workflow",
  "selectedTheme": {
    "dark": "legible-dark",
    "light": "light-tokyo-night",
    "symbolPreset": "ascii"
  },
  "requiresManualAuth": [
    "openrouter"
  ],
  "excludedCategories": [
    "secrets",
    "credentials",
    "databases",
    "sessions",
    "caches",
    "native-binaries"
  ],
  "pathReviewRequired": [],
  "files": []
}
```

Replace values with observed values. Never put secret values in the manifest.

Create a ZIP archive that Windows can extract. Include only the transfer directory.

After archiving, verify:

- the archive opens
- `MANIFEST.json` parses
- `config.yml` or `config.yaml` exists
- selected theme files exist
- at least one expected skill exists
- no excluded database, credential, or cache file exists
- the safety scan is clean

Report the archive path to the user. The user must move it to Windows.

## Phase B — Import on Windows

### B1. Inspect the transfer archive

Confirm the current OS is Windows and PowerShell is available.

Ask the user to extract the archive. Do not modify files until the extracted transfer directory contains:

```text
MANIFEST.json
payload/omp-root/
OMP-WINDOWS-MIGRATION.md
```

Read and validate `MANIFEST.json`.

Reject the archive if:

- `format` is unsupported
- the OMP version is missing
- the payload path is missing
- a secret or excluded runtime artifact appears
- the archive contains unexpected credential files

### B2. Install the exact OMP release

Extract the numeric version from `MANIFEST.json`.

Read the recorded `profile` value. If it is not `default`, set `OMP_PROFILE` for this import session before calling `omp config path`. Preserve that profile name in the Windows user environment after verification. Do not set an empty profile.

For `omp/18.14.1`, install `v18.14.1` with:

```powershell
& ([scriptblock]::Create((irm https://omp.sh/install.ps1))) -Binary -Ref v18.14.1
```

Use the version from the manifest, not the example version above.

Verify:

```powershell
omp --version
omp config path
```

If the installer reports an unsupported architecture or PowerShell version, stop and report the exact error.

### B3. Back up existing Windows OMP data

If `%USERPROFILE%\.omp` exists, move it to a timestamped backup beside it:

```powershell
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$ompRoot = Join-Path $env:USERPROFILE '.omp'
if (Test-Path -LiteralPath $ompRoot) {
    Move-Item -LiteralPath $ompRoot -Destination "$ompRoot.backup-$stamp"
}
```

Moving avoids duplicating credentials and live databases. Never delete the backup.

### B4. Restore portable OMP files

Determine the Windows active agent directory using:

```powershell
$agentDir = (omp config path).Trim()
$ompRoot = Split-Path $agentDir -Parent
```

Copy the transfer payload's OMP root into the Windows OMP root.

Merge files without deleting files that the installer created. Preserve the Windows installer's native binaries and shell configuration.

Restore these capabilities when present:

```text
config.yml or config.yaml
models.yml
themes/
skills/
managed-skills/
commands/
rules/
prompts/
instructions/
hooks/
tools/
extensions/
mcp.json
AGENTS.md
RULES.md
SYSTEM.md
SYSTEM_TEMPLATE.md
APPEND_SYSTEM.md
TITLE_SYSTEM.md
keybindings files
plugins/
caveman-plugin/
```

Do not restore databases, sessions, caches, logs, browser profiles, `.env` files, secret files, or Mac native binaries.


### B5. Repair platform-specific paths

Search restored text configuration and scripts for Mac-only paths:

```text
/Users/
/opt/homebrew/
/usr/local/
/bin/zsh
/bin/bash
.pyenv/
```

Do not globally replace paths.

For each match:

1. Determine whether the path is active.
2. Convert it to a Windows path or Windows command.
3. If no safe conversion exists, disable only that item and record it in `IMPORT-RESULT.md`.
4. Never alter project source code silently.

The current Mac configuration contains a Python path similar to:

```text
/Users/gabegaines/.pyenv/versions/3.12.12/bin/python
```

Install Python on Windows and replace `python.interpreter` with the real Windows interpreter path.

If copied settings specify a Mac `shellPath`, remove it or set it to a valid Windows shell. OMP's built-in shell is acceptable. Git Bash is optional.

### B6. Restore OpenRouter authentication

Do not copy Mac credentials.

Run:

```powershell
omp login openrouter
```

Let the user complete any browser or API-key prompt.

If the user chooses environment-based authentication, create this file manually:

```text
%USERPROFILE%\.omp\agent\.env
```

with:

```dotenv
OPENROUTER_API_KEY=<entered locally by the user>
```

Do not print the key. Do not commit the file. Do not include it in `IMPORT-RESULT.md`.

Restore model configuration from `models.yml`, then verify provider and model IDs without printing credentials.

### B7. Restore workflow project layout

Create:

```text
%USERPROFILE%\workflow
```

For every Git repository in `projects/repos.json`:

1. Create the proposed parent directory.
2. Clone from the recorded private origin URL.
3. Preserve the recorded repository name.
4. Do not overwrite an existing directory.
5. Report dirty Mac worktrees for manual transfer.
6. Do not place active repositories in OneDrive.

For non-Git projects, report the required manual transfer path. Do not fabricate missing source files.

### B8. Verify the restored OMP workflow

Run these checks:

```powershell
omp --version
omp config path
omp config get theme.dark
omp config get theme.light
omp config get symbolPreset
```

Verify these filesystem items:

- selected theme file exists
- expected skill directories exist
- expected command, rule, prompt, hook, tool, and extension files exist
- `models.yml` exists when the Mac payload had one
- no Mac-only absolute path remains in active OMP config
- no secret file entered the transfer payload

Start OMP from the extracted project or workflow directory and verify:

1. TUI starts.
2. Colors match the selected Mac theme.
3. Skills appear or resolve by name.
4. The selected model appears.
5. OpenRouter authentication succeeds.
6. One harmless read-only agent task completes.
7. The agent can access the restored workflow project.

Do not run a destructive task as migration verification.

### B9. Write import report

Create `IMPORT-RESULT.md` with:

- installed OMP version
- Windows active agent directory
- restored item counts
- selected theme values
- skill count
- provider/model status without credentials
- cloned project list
- skipped or path-repaired items
- manual actions still required
- verification commands and observed results

Never include secret values, tokens, private paths, or database contents.

## Completion criteria

The migration is complete only when:

- Windows runs the same OMP release as Mac.
- OMP starts natively from Cursor's PowerShell terminal.
- The selected theme and symbol preset match.
- Skills, commands, rules, prompts, hooks, tools, extensions, and MCP configuration load.
- Model roles and model configuration match.
- OpenRouter authentication works after user login.
- Workflow projects are cloned or explicitly reported as manual transfers.
- No secret or Mac-native runtime artifact was copied.
- `IMPORT-RESULT.md` records every exception.

If any criterion fails, keep working on the failure. Do not claim success from file presence alone.
