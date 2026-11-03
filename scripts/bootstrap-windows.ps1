[CmdletBinding()]
param(
    [switch]$SkipProjects
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ($env:OS -ne 'Windows_NT') {
    throw 'bootstrap-windows.ps1 requires Windows.'
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$manifestPath = Join-Path $repoRoot 'MANIFEST.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json

$versionText = [string]$manifest.source.ompVersion
if ($versionText -notmatch '(\d+\.\d+\.\d+)') {
    throw "Manifest has invalid OMP version: $versionText"
}
$version = $Matches[1]
$profile = [string]$manifest.profile

if ($profile -and $profile -ne 'default') {
    $env:OMP_PROFILE = $profile
}

$ompProcess = Get-Process -Name omp -ErrorAction SilentlyContinue
if ($null -ne $ompProcess) {
    throw 'Close running OMP sessions before importing configuration.'
}

$oldRoot = Join-Path $env:USERPROFILE '.omp'
$backup = $null
if (Test-Path -LiteralPath $oldRoot) {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backup = "$oldRoot.backup-$stamp"
    Move-Item -LiteralPath $oldRoot -Destination $backup
}

$ompCommand = Get-Command omp -ErrorAction SilentlyContinue
$currentVersion = if ($null -ne $ompCommand) { (& omp --version 2>$null | Out-String).Trim() } else { '' }
if ($currentVersion -notmatch [regex]::Escape($version)) {
    $installer = Invoke-RestMethod 'https://omp.sh/install.ps1'
    & ([scriptblock]::Create($installer)) -Binary -Ref "v$version"
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'User') + ';' + [Environment]::GetEnvironmentVariable('Path', 'Machine')
}

if (-not (Get-Command omp -ErrorAction SilentlyContinue)) {
    throw 'OMP was not found after installation.'
}

$agentDir = (& omp config path | Out-String).Trim()
if ([string]::IsNullOrWhiteSpace($agentDir)) {
    throw 'OMP returned an empty configuration path.'
}
$ompRoot = Split-Path -Parent $agentDir
New-Item -ItemType Directory -Force -Path $agentDir | Out-Null

function Copy-Tree {
    param(
        [Parameter(Mandatory)] [string]$Source,
        [Parameter(Mandatory)] [string]$Destination
    )
    if (-not (Test-Path -LiteralPath $Source)) { return }
    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    $children = Get-ChildItem -LiteralPath $Source -Force
    foreach ($child in $children) {
        Copy-Item -LiteralPath $child.FullName -Destination $Destination -Recurse -Force
    }
}

$portableStamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$cursorSkillsTarget = Join-Path $env:USERPROFILE '.cursor/skills-cursor'
if (Test-Path -LiteralPath $cursorSkillsTarget) {
    Move-Item -LiteralPath $cursorSkillsTarget -Destination "$cursorSkillsTarget.backup-$portableStamp"
}
$codexPluginsTarget = Join-Path $env:USERPROFILE '.codex/.tmp/plugins/plugins'
if (Test-Path -LiteralPath $codexPluginsTarget) {
    Move-Item -LiteralPath $codexPluginsTarget -Destination "$codexPluginsTarget.backup-$portableStamp"
}
Copy-Tree (Join-Path $repoRoot 'omp/agent') $agentDir
Copy-Tree (Join-Path $repoRoot 'omp/plugins') (Join-Path $ompRoot 'plugins')
Copy-Tree (Join-Path $repoRoot 'omp/caveman-plugin') (Join-Path $ompRoot 'caveman-plugin')
Copy-Tree (Join-Path $repoRoot 'cursor/skills-cursor') $cursorSkillsTarget
Copy-Tree (Join-Path $repoRoot 'external/codex/plugins') $codexPluginsTarget

$cursorUser = Join-Path $env:APPDATA 'Cursor\User'
$cursorBackup = Join-Path $env:APPDATA ("Cursor\User.backup-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Force -Path $cursorUser | Out-Null
foreach ($cursorFile in @('settings.json', 'keybindings.json')) {
    $source = Join-Path $repoRoot "cursor/user/$cursorFile"
    $destination = Join-Path $cursorUser $cursorFile
    if (Test-Path -LiteralPath $source) {
        if (Test-Path -LiteralPath $destination) {
            New-Item -ItemType Directory -Force -Path $cursorBackup | Out-Null
            Copy-Item -LiteralPath $destination -Destination (Join-Path $cursorBackup $cursorFile)
        }
        Copy-Item -LiteralPath $source -Destination $destination -Force
    }
}
$snippetSource = Join-Path $repoRoot 'cursor/user/snippets'
$snippetDestination = Join-Path $cursorUser 'snippets'
if (Test-Path -LiteralPath $snippetSource) {
    if (Test-Path -LiteralPath $snippetDestination) {
        New-Item -ItemType Directory -Force -Path $cursorBackup | Out-Null
        Copy-Item -LiteralPath $snippetDestination -Destination (Join-Path $cursorBackup 'snippets') -Recurse -Force
    }
    Copy-Tree $snippetSource $snippetDestination
}

$cursorSettings = Join-Path $cursorUser 'settings.json'
if (Test-Path -LiteralPath $cursorSettings) {
    $settingsText = Get-Content -LiteralPath $cursorSettings -Raw
    $editorPython = Get-Command python -ErrorAction SilentlyContinue
    if ($null -eq $editorPython) { $editorPython = Get-Command py -ErrorAction SilentlyContinue }
    if ($null -ne $editorPython) {
        $settingsText = $settingsText.Replace('/usr/local/bin/python3', 'python')
    } else {
        $settingsText = [regex]::Replace($settingsText, '(?m)^\s*"python\.defaultInterpreterPath"\s*:\s*"[^"]+",?\s*\r?\n', '')
    }
    $compiler = Get-Command clang -ErrorAction SilentlyContinue
    if ($null -eq $compiler) { $compiler = Get-Command cl -ErrorAction SilentlyContinue }
    if ($null -ne $compiler) {
        $settingsText = $settingsText.Replace('/usr/bin/clang', $compiler.Name)
    } else {
        $settingsText = [regex]::Replace($settingsText, '(?m)^\s*"C_Cpp\.default\.compilerPath"\s*:\s*"[^"]+",?\s*\r?\n', '')
    }
    Set-Content -LiteralPath $cursorSettings -Value $settingsText -Encoding UTF8
}

$cursorKeybindings = Join-Path $cursorUser 'keybindings.json'
if (Test-Path -LiteralPath $cursorKeybindings) {
    $keybindingsText = Get-Content -LiteralPath $cursorKeybindings -Raw
    $keybindingsText = $keybindingsText.Replace('cmd+', 'ctrl+')
    Set-Content -LiteralPath $cursorKeybindings -Value $keybindingsText -Encoding UTF8
}

$extensionStatus = 'Cursor extension CLI not checked.'
$extensionManifest = Join-Path $repoRoot 'cursor/extensions.json'
$cursorCli = Get-Command cursor -ErrorAction SilentlyContinue
if ($null -ne $cursorCli -and (Test-Path -LiteralPath $extensionManifest)) {
    $extensions = Get-Content -LiteralPath $extensionManifest -Raw | ConvertFrom-Json
    foreach ($extension in @($extensions)) {
        $id = [string]$extension.identifier.id
        $extensionVersion = [string]$extension.version
        if ($id) {
            & cursor --install-extension "$id@$extensionVersion" --force
        }
    }
    $extensionStatus = 'Cursor extensions requested from cursor/extensions.json.'
} else {
    $extensionStatus = 'Cursor CLI unavailable; extension installation recorded for manual completion.'
}

$configPath = Join-Path $agentDir 'config.yml'
$pythonCommand = Get-Command python -ErrorAction SilentlyContinue
if ($null -eq $pythonCommand) { $pythonCommand = Get-Command py -ErrorAction SilentlyContinue }
$pythonNote = 'Python path was not changed.'
if ((Test-Path -LiteralPath $configPath) -and $null -ne $pythonCommand) {
    $pythonPath = $pythonCommand.Source.Replace("'", "''")
    $config = Get-Content -LiteralPath $configPath -Raw
    $config = [regex]::Replace($config, '(?m)^(\s*interpreter:\s*).+$', { param($m) $m.Groups[1].Value + "'" + $pythonPath + "'" })
    Set-Content -LiteralPath $configPath -Value $config -Encoding UTF8
    $pythonNote = "Python interpreter set to $pythonPath."
}

& (Join-Path $repoRoot 'scripts/audit-secrets.ps1')

$report = [System.Collections.Generic.List[string]]::new()
$report.Add('# Windows OMP Bootstrap Report')
$report.Add('')
$report.Add("- Expected OMP version: $version")
$report.Add("- Installed OMP version: $((& omp --version 2>$null | Out-String).Trim())")
$report.Add("- Active agent directory: $agentDir")
if ($null -ne $backup) { $report.Add("- Previous OMP backup: $backup") }
$report.Add("- Cursor settings: restored to $cursorUser")
$report.Add("- Cursor extensions: $extensionStatus")
$report.Add("- $pythonNote")
$report.Add('- OpenRouter: run `omp login openrouter` if not authenticated.')
$report.Add('- Verification: run `scripts/verify-windows.ps1`.')

if (-not $SkipProjects) {
    $reposPath = Join-Path $repoRoot 'projects/repos.json'
    if ((Test-Path -LiteralPath $reposPath) -and (Get-Command git -ErrorAction SilentlyContinue)) {
        $repos = Get-Content -LiteralPath $reposPath -Raw | ConvertFrom-Json
        $workflowRoot = Join-Path $env:USERPROFILE 'workflow'
        foreach ($repo in @($repos.repositories)) {
            if ([string]::IsNullOrWhiteSpace([string]$repo.origin) -or [string]$repo.origin -like '<redacted*') {
                $report.Add("- Skipped project without safe origin: $($repo.relativePath)")
                continue
            }
            $target = Join-Path $workflowRoot ([string]$repo.relativePath -replace '/', '\')
            if (Test-Path -LiteralPath $target) {
                $report.Add("- Existing project left untouched: $target")
                continue
            }
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
            & git clone ([string]$repo.origin) $target
            if ($LASTEXITCODE -eq 0) {
                $report.Add("- Cloned project: $target")
            } else {
                if (Test-Path -LiteralPath $target) {
                    Remove-Item -LiteralPath $target -Recurse -Force
                }
                $report.Add("- Failed to clone project: $target")
            }
        }
    } else {
        $report.Add('- Project cloning skipped because Git or projects/repos.json is unavailable.')
    }
}

$report | Set-Content -LiteralPath (Join-Path $repoRoot 'MIGRATION-REPORT.md') -Encoding UTF8
Write-Output ($report -join [Environment]::NewLine)
