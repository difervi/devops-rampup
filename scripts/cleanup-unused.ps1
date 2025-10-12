<#
.SYNOPSIS
  Safely moves a short list of known-unused artifacts into a repo-local
  backup folder so you can review them before deleting.

USAGE
  From the repository root run:
    .\scripts\cleanup-unused.ps1

  The script will prompt before moving files. It will not run git commands
  that change history automatically.
#>

Param(
  [switch]$AutoYes
)

Set-StrictMode -Version Latest

$repoRoot = (Get-Location).Path
$backupDir = Join-Path $repoRoot 'backup-unused'

$targets = @(
  'AWSSetup1.png',
  'AWSSetup2.png',
  'AWSSetup3.png',
  'movie-analyst-api;C'
)

Write-Host "Repository root: $repoRoot"
Write-Host "Planned backup folder: $backupDir"

if (-not (Test-Path $backupDir)) {
  New-Item -ItemType Directory -Path $backupDir | Out-Null
  Write-Host "Created backup folder: $backupDir"
}

Write-Host "The script will move the following files (if present) to the backup folder:`n"
$targets | ForEach-Object { Write-Host " - $_" }

if ($AutoYes) {
  $confirm = 'YES'
} else {
  $confirm = Read-Host "Type YES to proceed"
}

if ($confirm -ne 'YES') {
  Write-Host "Aborted by user. No changes made." -ForegroundColor Yellow
  exit 0
}

$moved = @()
$missing = @()

foreach ($t in $targets) {
  $path = Join-Path $repoRoot $t
  if (Test-Path $path) {
    try {
      Move-Item -Path $path -Destination $backupDir -Force
      $moved += $t
      Write-Host "Moved: $t"
    } catch {
      $msg = $_.Exception.Message -replace "\r|\n", ' '
  Write-Warning "Failed to move ${t}: $msg"
    }
  } else {
    $missing += $t
    Write-Host "Not found: $t"
  }
}

Write-Host "\nSummary:" -ForegroundColor Cyan
Write-Host "Moved files: " ($moved -join ', ')
Write-Host "Missing files: " ($missing -join ', ')

Write-Host "\nNext steps (recommended):"
Write-Host " 1) Inspect the backup folder: $backupDir"
Write-Host " 2) Run 'git status --short' and review changes"
Write-Host " 3) If OK, stage and commit: 'git add -A' then 'git commit -m "chore: remove unused artifacts"'"
