[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ($env:OS -ne 'Windows_NT') {
    throw 'verify-windows.ps1 requires Windows.'
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$manifest = Get-Content -LiteralPath (Join-Path $repoRoot 'MANIFEST.json') -Raw | ConvertFrom-Json
$expectedVersion = [string]$manifest.source.ompVersion
$expectedVersionNumber = ([regex]::Match($expectedVersion, '\d+\.\d+\.\d+')).Value
$actualVersion = (& omp --version 2>$null | Out-String).Trim()
if ($actualVersion -notmatch [regex]::Escape($expectedVersionNumber)) {
    throw "OMP version mismatch. Expected $expectedVersionNumber, got $actualVersion."
}

$agentDir = (& omp config path | Out-String).Trim()
$themeDark = (& omp config get theme.dark 2>$null | Out-String).Trim()
$themeLight = (& omp config get theme.light 2>$null | Out-String).Trim()
$symbolPreset = (& omp config get symbolPreset 2>$null | Out-String).Trim()
$expectedSkills = [int]$manifest.skillFiles
$skillCount = @(Get-ChildItem -LiteralPath (Join-Path $agentDir 'skills') -Recurse -File -Filter 'SKILL.md' -ErrorAction SilentlyContinue).Count

if ($skillCount -lt $expectedSkills) {
    throw "Skill count is lower than the snapshot. Expected at least $expectedSkills, found $skillCount."
}

$themePath = Join-Path $agentDir 'themes/legible-dark.json'
if ($themeDark -eq 'legible-dark' -and -not (Test-Path -LiteralPath $themePath)) {
    throw "Selected custom theme is missing: $themePath"
}

& (Join-Path $repoRoot 'scripts/audit-secrets.ps1')
$cursorUser = Join-Path $env:APPDATA 'Cursor\User'
$cursorSettingsPath = Join-Path $cursorUser 'settings.json'
$cursorKeybindingsPath = Join-Path $cursorUser 'keybindings.json'
$cursorExtensionCount = 0
$cursorExtensionManifest = Join-Path $repoRoot 'cursor/extensions.json'
if (Test-Path -LiteralPath $cursorExtensionManifest) {
    $cursorExtensionCount = @((Get-Content -LiteralPath $cursorExtensionManifest -Raw | ConvertFrom-Json)).Count
}

$scanRoots = @($agentDir, $cursorUser) | Where-Object { Test-Path -LiteralPath $_ }
$macPathMatches = @(
    Get-ChildItem -Path $scanRoots -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -in @('.yml', '.yaml', '.json', '.jsonc', '.md', '.mdc', '.ps1', '.js', '.ts', '.sh', '.py') } |
        Select-String -Pattern '/Users/|/opt/homebrew/|/usr/local/|\.pyenv/' -List |
        ForEach-Object { $_.Path }
)

$report = [System.Collections.Generic.List[string]]::new()
$report.Add('# Windows OMP Verification Report')
$report.Add('')
$report.Add("- OMP version: $actualVersion")
$report.Add("- Active agent directory: $agentDir")
$report.Add("- Dark theme: $themeDark")
$report.Add("- Light theme: $themeLight")
$report.Add("- Symbol preset: $symbolPreset")
$report.Add("- Skill files: $skillCount")
$report.Add("- Cursor settings present: $(Test-Path -LiteralPath $cursorSettingsPath)")
$report.Add("- Cursor keybindings present: $(Test-Path -LiteralPath $cursorKeybindingsPath)")
$report.Add("- Cursor extensions recorded: $cursorExtensionCount")
$report.Add("- OpenRouter login: run `omp login openrouter` if provider authentication is missing.")
$report.Add('')
$report.Add('## Manual checks')
$report.Add('')
$report.Add('- Start `omp` from Cursor PowerShell.')
$report.Add('- Confirm colors match the Mac terminal.')
$report.Add('- Resolve one skill by name.')
$report.Add('- Select the expected model.')
$report.Add('- Complete one harmless read-only agent task.')
if ($macPathMatches.Count -gt 0) {
    $report.Add('')
    $report.Add('## Remaining Mac-path references')
    $report.Add('')
    $macPathMatches | ForEach-Object { $report.Add("- $_") }
}

$reportPath = Join-Path $repoRoot 'MIGRATION-REPORT.md'
$report | Set-Content -LiteralPath $reportPath -Encoding UTF8
Write-Output ($report -join [Environment]::NewLine)
