param(
  [Parameter(Mandatory = $false)]
  [string]$TargetPath = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'

function Fail($msg) {
  Write-Host "GAEH doctor: FAIL - $msg" -ForegroundColor Red
  exit 2
}

function Ok($msg) {
  Write-Host "GAEH doctor: OK   - $msg" -ForegroundColor Green
}

if (-not (Test-Path -LiteralPath $TargetPath)) {
  Fail "TargetPath not found: $TargetPath"
}

$requiredDirs = @('project_control','ai_harness','specs','plans','reviews','reports')
foreach ($d in $requiredDirs) {
  $p = Join-Path $TargetPath $d
  if (-not (Test-Path -LiteralPath $p)) { Fail "Missing dir: $d" }
}
Ok "Directories present"

$requiredFiles = @(
  'project_control\goal.md',
  'project_control\phase_status.md',
  'project_control\task_queue.json',
  'project_control\decision_log.md',
  'project_control\approval.json',
  'project_control\change_requests.md',
  'project_control\issues.md',
  'ai_harness\harness_rules.md'
)
foreach ($f in $requiredFiles) {
  $p = Join-Path $TargetPath $f
  if (-not (Test-Path -LiteralPath $p)) { Fail "Missing file: $f" }
}
Ok "Core files present"

# Optional GGS check
$ggsRunner = Join-Path $TargetPath 'project_control\.ggs\templates\runner.prompt.md'
if (Test-Path -LiteralPath $ggsRunner) {
  Ok "GGS runner present"
} else {
  Write-Host "GAEH doctor: WARN - GGS runner not found (project_control/.ggs/templates/runner.prompt.md)" -ForegroundColor Yellow
}

# task_queue.json must be valid JSON
$queuePath = Join-Path $TargetPath 'project_control\task_queue.json'
try {
  $null = (Get-Content -Raw -LiteralPath $queuePath) | ConvertFrom-Json
  Ok "task_queue.json is valid JSON"
} catch {
  Fail "task_queue.json invalid JSON: $($_.Exception.Message)"
}

# approval.json must be valid JSON
$approvalPath = Join-Path $TargetPath 'project_control\approval.json'
try {
  $null = (Get-Content -Raw -LiteralPath $approvalPath) | ConvertFrom-Json
  Ok "approval.json is valid JSON"
} catch {
  Fail "approval.json invalid JSON: $($_.Exception.Message)"
}

# Optional adapters check
$codexSkill = Join-Path $TargetPath '.codex\skills\gaeh\SKILL.md'
if (Test-Path -LiteralPath $codexSkill) { Ok "Codex adapter present" } else { Write-Host "GAEH doctor: WARN - Codex adapter not found (.codex/skills/gaeh/SKILL.md)" -ForegroundColor Yellow }

$cursorRule = Join-Path $TargetPath '.cursor\rules\gaeh.mdc'
if (Test-Path -LiteralPath $cursorRule) { Ok "Cursor adapter present" } else { Write-Host "GAEH doctor: WARN - Cursor adapter not found (.cursor/rules/gaeh.mdc)" -ForegroundColor Yellow }

## Optional Git checks (professional workflow)
$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) {
  Write-Host "GAEH doctor: WARN - git not found in PATH (Git discipline features will be limited)" -ForegroundColor Yellow
} else {
  $gitDir = Join-Path $TargetPath '.git'
  if (Test-Path -LiteralPath $gitDir) {
    Ok "Git repo present"
    try {
      $origin = & git -C $TargetPath remote get-url origin 2>$null
      if ($origin) { Ok "Git remote 'origin' configured" } else { Write-Host "GAEH doctor: WARN - Git remote 'origin' missing" -ForegroundColor Yellow }
    } catch {
      Write-Host "GAEH doctor: WARN - Cannot read git remote 'origin'" -ForegroundColor Yellow
    }
  } else {
    Write-Host "GAEH doctor: WARN - .git not found (run: git init && git remote add origin <url>)" -ForegroundColor Yellow
  }
}

Write-Host "GAEH doctor: PASS" -ForegroundColor Green
