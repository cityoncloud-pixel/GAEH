param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Args
)

$ErrorActionPreference = 'Stop'

function Get-KitRoot { return $PSScriptRoot }

function Get-UserHome {
  if ($env:USERPROFILE) { return $env:USERPROFILE }
  if ($HOME) { return $HOME }
  throw "Cannot resolve user home folder."
}

function Get-GaehHome { Join-Path (Get-UserHome) '.gaeh' }

function Ensure-Dir([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
  }
}

function Read-Json([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return $null }
  (Get-Content -Raw -LiteralPath $Path) | ConvertFrom-Json
}

function Write-Json([string]$Path, $Obj) {
  $dir = Split-Path -Parent $Path
  Ensure-Dir $dir
  ($Obj | ConvertTo-Json -Depth 50) | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Print-Help {
  @"
GAEH CLI (PowerShell)

Usage:
  .\gaeh.ps1 install
  .\gaeh.ps1 init    [-TargetPath <path>] [-Adapters codex,cursor] [-Force]
  .\gaeh.ps1 doctor  [-TargetPath <path>]
  .\gaeh.ps1 ggs     [-TargetPath <path>]
  .\gaeh.ps1 start
  .\gaeh.ps1 watchdog [-TargetPath <path>] [-StaleMinutes <n>] [-IntervalSeconds <n>] [-Once]
  .\gaeh.ps1 approve [-TargetPath <path>] [-Scope start_execution] [-TaskId <id>] [-Note <text>]

Tip:
  After install, run: gaeh init
"@ | Write-Host
}

function Cmd-Install {
  $kitRoot = Get-KitRoot
  $gaehHome = Get-GaehHome

  Ensure-Dir $gaehHome
  Ensure-Dir (Join-Path $gaehHome 'bin')
  Ensure-Dir (Join-Path $gaehHome 'kits')

  $metaPath = Join-Path $kitRoot 'gaeh-kit.json'
  $meta = Read-Json $metaPath
  if (-not $meta) { throw "Missing kit metadata: $metaPath" }
  $version = $meta.version
  if (-not $version) { throw "Missing version in gaeh-kit.json" }

  $dstKit = Join-Path (Join-Path $gaehHome 'kits') $version
  $srcResolved = $null
  $dstResolved = $null
  try { $srcResolved = (Resolve-Path -LiteralPath $kitRoot).Path } catch { }
  try { $dstResolved = (Resolve-Path -LiteralPath $dstKit).Path } catch { }

  $samePath = $false
  if ($srcResolved -and $dstResolved -and ($srcResolved.TrimEnd('\\') -ieq $dstResolved.TrimEnd('\\'))) {
    $samePath = $true
  }

  if (-not $samePath) {
    if (Test-Path -LiteralPath $dstKit) { Remove-Item -Recurse -Force -LiteralPath $dstKit }
    Ensure-Dir $dstKit

    $srcGaeh = Join-Path $kitRoot 'gaeh.ps1'
    if (-not (Test-Path -LiteralPath $srcGaeh)) { throw "Invalid kit root (missing gaeh.ps1): $kitRoot" }
    Copy-Item -Recurse -Force -Path (Join-Path $kitRoot '*') -Destination $dstKit
  }

  # Update "current" pointer
  $currentPath = Join-Path $gaehHome 'current.txt'
  Set-Content -LiteralPath $currentPath -Value $dstKit -Encoding UTF8

  # Default config (non-destructive)
  $cfgPath = Join-Path $gaehHome 'config.json'
  if (-not (Test-Path -LiteralPath $cfgPath)) {
    $cfg = @{
      schema_version = '1.0'
      default_adapters = @('codex','cursor')
    }
    Write-Json -Path $cfgPath -Obj $cfg
  }

  # Create shim command (PowerShell)
  $shim = @'
param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Args)
$ErrorActionPreference = "Stop"
$userHome = if ($env:USERPROFILE) { $env:USERPROFILE } elseif ($HOME) { $HOME } else { throw "Cannot resolve user home." }
$gaehHome = Join-Path $userHome ".gaeh"
$current = Join-Path $gaehHome "current.txt"
if (-not (Test-Path -LiteralPath $current)) { throw "GAEH not installed (missing ~/.gaeh/current.txt). Run: gaeh.ps1 install" }
$kit = (Get-Content -Raw -LiteralPath $current).Trim()
if (-not (Test-Path -LiteralPath $kit)) { throw "GAEH kit path not found: $kit" }
. (Join-Path $kit "gaeh.ps1") @Args
'@
  $shimPath = Join-Path (Join-Path $gaehHome 'bin') 'gaeh.ps1'
  Set-Content -LiteralPath $shimPath -Value $shim -Encoding UTF8

  # Create CMD shim for shorter command name: `gaeh`
  $cmdShim = @'
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\.gaeh\bin\gaeh.ps1" %*
'@
  $cmdShimPath = Join-Path (Join-Path $gaehHome 'bin') 'gaeh.cmd'
  Set-Content -LiteralPath $cmdShimPath -Value $cmdShim -Encoding ASCII

  Write-Host "GAEH installed to: $dstKit"
  Write-Host "Shim created: $shimPath"
  Write-Host "CMD shim created: $cmdShimPath"
  Write-Host "Add to PATH (current session):"
  $binPath = (Join-Path $gaehHome 'bin')
  Write-Host ("  `$env:PATH = `"{0};$env:PATH`"" -f $binPath)
}

function Cmd-Init {
  param(
    [string]$TargetPath = (Get-Location).Path,
    [string[]]$Adapters = $null,
    [switch]$Force
  )

  if (-not $Adapters -or $Adapters.Count -eq 0) {
    $cfg = Read-Json (Join-Path (Get-GaehHome) 'config.json')
    if ($cfg -and $cfg.default_adapters) {
      $Adapters = @($cfg.default_adapters | ForEach-Object { $_.ToString() })
    }
  }

  $kitRoot = Get-KitRoot
  $bootstrap = Join-Path $kitRoot 'gaeh-bootstrap.ps1'
  if (-not (Test-Path -LiteralPath $bootstrap)) { throw "Missing bootstrap: $bootstrap" }

  $cmd = @('-ExecutionPolicy','Bypass','-File',$bootstrap,'-TargetPath',$TargetPath)
  if ($Adapters -and $Adapters.Count -gt 0) { $cmd += @('-Adapters',($Adapters -join ',')) }
  if ($Force) { $cmd += @('-Force') }
  & powershell @cmd
}

function Cmd-Doctor {
  param([string]$TargetPath = (Get-Location).Path)
  $kitRoot = Get-KitRoot
  $doctor = Join-Path $kitRoot 'gaeh-doctor.ps1'
  if (-not (Test-Path -LiteralPath $doctor)) { throw "Missing doctor script: $doctor" }
  & powershell -ExecutionPolicy Bypass -File $doctor -TargetPath $TargetPath
}

function Cmd-Ggs {
  param([string]$TargetPath = (Get-Location).Path)
  $idea = Join-Path $TargetPath 'project_control\.ggs\idea.md'
  $runner = Join-Path $TargetPath 'project_control\.ggs\templates\runner.prompt.md'
  Write-Host "GGS (Goal Generation) runner:"
  Write-Host "  1) Edit: $idea"
  Write-Host "  2) Paste runner prompt from: $runner"
  Write-Host ""
  Write-Host "Expected outputs:"
  Write-Host "  - project_control\\goal.md"
  Write-Host "  - project_control\\.ggs\\goal.review.json"
}

function Cmd-Start {
  Write-Host "Start GAEH: clarify goal (boundary + UI) -> propose minimal questions -> wait for owner token 'APPROVE' -> execute end-to-end until acceptance; persist to plans/reviews/reports and project_control/*.md."
}

function Cmd-Watchdog {
  param(
    [string]$TargetPath = (Get-Location).Path,
    [int]$StaleMinutes = 20,
    [int]$IntervalSeconds = 60,
    [switch]$Once
  )

  $kitRoot = Get-KitRoot
  $script = Join-Path $kitRoot 'gaeh-watchdog.ps1'
  if (-not (Test-Path -LiteralPath $script)) { throw "Missing watchdog script: $script" }

  $cmd = @('-ExecutionPolicy','Bypass','-File',$script,'-TargetPath',$TargetPath,'-StaleMinutes',$StaleMinutes,'-IntervalSeconds',$IntervalSeconds)
  if ($Once) { $cmd += @('-Once') }
  & powershell @cmd
}

function Cmd-Approve {
  param(
    [string]$TargetPath = (Get-Location).Path,
    [string]$Scope = 'start_execution',
    [string]$TaskId = $null,
    [string]$Note = ''
  )

  $path = Join-Path $TargetPath 'project_control\approval.json'
  if (-not (Test-Path -LiteralPath $path)) { throw "approval.json not found: $path (run init/bootstrap first)" }

  if ($Scope) { $Scope = $Scope.Trim() }
  if ([string]::IsNullOrWhiteSpace($TaskId)) { $TaskId = $null }

  $obj = (Get-Content -Raw -LiteralPath $path) | ConvertFrom-Json
  $props = @($obj.PSObject.Properties.Name)
  if (-not ($props -contains 'pending')) { $obj | Add-Member -NotePropertyName pending -NotePropertyValue @() }
  if (-not ($props -contains 'history')) { $obj | Add-Member -NotePropertyName history -NotePropertyValue @() }

  $now = (Get-Date).ToString('s')
  $obj.updated_at = (Get-Date).ToString('yyyy-MM-dd')

  $approvedAny = $false
  $newPending = @()
  $pendingList = @()
  if ($null -ne $obj.pending) { $pendingList = @($obj.pending) }
  foreach ($p in $pendingList) {
    $pScope = if ($p.scope) { $p.scope.ToString().Trim() } else { '' }
    $pStatus = if ($p.status) { $p.status.ToString().Trim().ToUpperInvariant() } else { '' }
    $pTaskId = $p.task_id
    $matchTask = ($null -eq $TaskId) -or ($pTaskId -eq $TaskId)
    if ($pScope -eq $Scope -and $matchTask -and $pStatus -eq 'PENDING') {
      $p.status = 'APPROVED'
      $p.owner_note = $Note
      if (@($p.PSObject.Properties.Name) -contains 'approved_at') {
        $p.approved_at = $now
      } else {
        $p | Add-Member -NotePropertyName approved_at -NotePropertyValue $now
      }
      $obj.history += $p
      $approvedAny = $true
    } else {
      $newPending += $p
    }
  }
  $obj.pending = $newPending

  if (-not $approvedAny -and $pendingList.Count -eq 1) {
    $only = $pendingList[0]
    $onlyStatus = if ($only.status) { $only.status.ToString().Trim().ToUpperInvariant() } else { '' }
    if ($onlyStatus -eq 'PENDING') {
      $only.status = 'APPROVED'
      $only.owner_note = $Note
      if (@($only.PSObject.Properties.Name) -contains 'approved_at') {
        $only.approved_at = $now
      } else {
        $only | Add-Member -NotePropertyName approved_at -NotePropertyValue $now
      }
      $obj.history += $only
      $obj.pending = @()
      $approvedAny = $true
    }
  }

  ($obj | ConvertTo-Json -Depth 50) | Set-Content -LiteralPath $path -Encoding UTF8
  if ($approvedAny) {
    Write-Host "Approved: scope=$Scope task_id=$TaskId"
  } else {
    Write-Host "No pending approval matched: scope=$Scope task_id=$TaskId" -ForegroundColor Yellow
  }
}

if (-not $Args -or $Args.Count -eq 0) { Print-Help; exit 0 }

$cmd = $Args[0].ToLowerInvariant()
$rest = @()
if ($Args.Count -gt 1) { $rest = $Args[1..($Args.Count-1)] }

switch ($cmd) {
  'install' { Cmd-Install; break }
  'init' {
    $tp = (Get-Location).Path
    $ad = @()
    $force = $false
    for ($i=0; $i -lt $rest.Count; $i++) {
      $a = $rest[$i]
      if ($a -eq '-TargetPath' -and $i+1 -lt $rest.Count) { $tp = $rest[$i+1]; $i++; continue }
      if ($a -eq '-Adapters' -and $i+1 -lt $rest.Count) {
        # Support: -Adapters "codex,cursor"  OR  -Adapters codex,cursor  OR  -Adapters codex cursor
        $v = $rest[$i+1]
        $i++
        if ($v -match '[,;]') {
          $ad += @($v)
        } else {
          $ad += @($v)
          while ($i+1 -lt $rest.Count -and -not ($rest[$i+1] -like '-*')) {
            $ad += @($rest[$i+1])
            $i++
          }
        }
        continue
      }
      if ($a -eq '-Force') { $force = $true; continue }
    }
    if ($force) { Cmd-Init -TargetPath $tp -Adapters $ad -Force } else { Cmd-Init -TargetPath $tp -Adapters $ad }
    break
  }
  'doctor' {
    $tp = (Get-Location).Path
    for ($i=0; $i -lt $rest.Count; $i++) {
      $a = $rest[$i]
      if ($a -eq '-TargetPath' -and $i+1 -lt $rest.Count) { $tp = $rest[$i+1]; $i++; continue }
    }
    Cmd-Doctor -TargetPath $tp
    break
  }
  'ggs' {
    $tp = (Get-Location).Path
    for ($i=0; $i -lt $rest.Count; $i++) {
      $a = $rest[$i]
      if ($a -eq '-TargetPath' -and $i+1 -lt $rest.Count) { $tp = $rest[$i+1]; $i++; continue }
    }
    Cmd-Ggs -TargetPath $tp
    break
  }
  'start' { Cmd-Start; break }
  'watchdog' {
    $tp = (Get-Location).Path
    $stale = 20
    $interval = 60
    $once = $false
    for ($i=0; $i -lt $rest.Count; $i++) {
      $a = $rest[$i]
      if ($a -eq '-TargetPath' -and $i+1 -lt $rest.Count) { $tp = $rest[$i+1]; $i++; continue }
      if ($a -eq '-StaleMinutes' -and $i+1 -lt $rest.Count) { $stale = [int]$rest[$i+1]; $i++; continue }
      if ($a -eq '-IntervalSeconds' -and $i+1 -lt $rest.Count) { $interval = [int]$rest[$i+1]; $i++; continue }
      if ($a -eq '-Once') { $once = $true; continue }
    }
    Cmd-Watchdog -TargetPath $tp -StaleMinutes $stale -IntervalSeconds $interval -Once:([bool]$once)
    break
  }
  'approve' {
    $tp = (Get-Location).Path
    $scope = 'start_execution'
    $taskId = $null
    $note = ''
    for ($i=0; $i -lt $rest.Count; $i++) {
      $a = $rest[$i]
      if ($a -eq '-TargetPath' -and $i+1 -lt $rest.Count) { $tp = $rest[$i+1]; $i++; continue }
      if ($a -eq '-Scope' -and $i+1 -lt $rest.Count) { $scope = $rest[$i+1]; $i++; continue }
      if ($a -eq '-TaskId' -and $i+1 -lt $rest.Count) { $taskId = $rest[$i+1]; $i++; continue }
      if ($a -eq '-Note' -and $i+1 -lt $rest.Count) { $note = $rest[$i+1]; $i++; continue }
    }
    if ([string]::IsNullOrWhiteSpace($taskId)) {
      Cmd-Approve -TargetPath $tp -Scope $scope -Note $note
    } else {
      Cmd-Approve -TargetPath $tp -Scope $scope -TaskId $taskId -Note $note
    }
    break
  }
  'help' { Print-Help; break }
  default { Print-Help; exit 1 }
}
