param(
  [Parameter(Mandatory = $false)]
  [string]$TargetPath = (Get-Location).Path,

  [Parameter(Mandatory = $false)]
  [int]$StaleMinutes = 20,

  [Parameter(Mandatory = $false)]
  [int]$IntervalSeconds = 60,

  [Parameter(Mandatory = $false)]
  [switch]$Once
)

$ErrorActionPreference = 'Stop'

function Read-Json([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return $null }
  (Get-Content -Raw -LiteralPath $Path) | ConvertFrom-Json
}

function Write-Json([string]$Path, $Obj) {
  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
  }
  ($Obj | ConvertTo-Json -Depth 50) | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-FileMTime([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return $null }
  (Get-Item -LiteralPath $Path).LastWriteTime
}

function Get-QueueSummary([string]$QueuePath) {
  $obj = Read-Json $QueuePath
  if (-not $obj) { return @{ ok = $false; pending = 0; active = 0; done = 0; current_task_id = $null } }
  $tasks = @()
  if ($null -ne $obj.tasks) { $tasks = @($obj.tasks) }

  $pending = 0
  $active = 0
  $done = 0
  foreach ($t in $tasks) {
    $s = ''
    if ($t.status) { $s = $t.status.ToString().Trim().ToLowerInvariant() }
    if ($s -eq 'done' -or $s -eq 'completed') { $done++; continue }
    if ($s -eq 'in_progress' -or $s -eq 'active' -or $s -eq 'running') { $active++; continue }
    $pending++
  }
  return @{
    ok = $true
    pending = $pending
    active = $active
    done = $done
    current_task_id = $obj.current_task_id
  }
}

function Ensure-RecoveryPrompt([string]$PromptPath) {
  $lines = @()
  $lines += "# Recovery Prompt (machine-generated)"
  $lines += ""
  $lines += "You are running GAEH. Resume from files, not chat memory."
  $lines += ""
  $lines += "1) Read goal + control artifacts:"
  $lines += "- project_control/goal.md"
  $lines += "- project_control/phase_status.md"
  $lines += "- project_control/current_task.md"
  $lines += "- project_control/task_queue.json"
  $lines += "- project_control/approval.json"
  $lines += "- project_control/issues.md"
  $lines += "- project_control/change_requests.md"
  $lines += ""
  $lines += "2) Decide current state:"
  $lines += "- If owner approval is required and not approved: ask the smallest unblock questions and request token APPROVE."
  $lines += "- Else: pick the next not-done task, generate/update spec/plan/review as needed, execute, verify, and write a report."
  $lines += ""
  $lines += "3) Update persistence:"
  $lines += "- Update project_control/task_queue.json statuses and updated_at."
  $lines += "- Append decisions to project_control/decision_log.md."
  $lines += "- Write progress heartbeat to project_control/agent_heartbeat.json (status/active_task_id/active_step)."
  $lines += ""
  $lines += "Constraint: no silent scope expansion. If new work appears, capture to change_requests.md and request approval."
  $lines += ""
  ($lines -join "`n") | Set-Content -LiteralPath $PromptPath -Encoding UTF8
}

function Check-Once {
  param([string]$TargetPath, [int]$StaleMinutes)

  $pc = Join-Path $TargetPath 'project_control'
  $hbPath = Join-Path $pc 'agent_heartbeat.json'
  $queuePath = Join-Path $pc 'task_queue.json'
  $promptPath = Join-Path $pc 'recovery_prompt.md'

  $queue = Get-QueueSummary $queuePath

  $hb = Read-Json $hbPath
  $hbUpdated = $null
  if ($hb -and $hb.updated_ts) {
    try { $hbUpdated = [DateTime]::Parse($hb.updated_ts.ToString()) } catch { $hbUpdated = $null }
  }
  if (-not $hbUpdated) { $hbUpdated = Get-FileMTime $hbPath }

  $fallback = @(
    (Get-FileMTime $queuePath),
    (Get-FileMTime (Join-Path $TargetPath 'reports\recent_reports.md')),
    (Get-FileMTime (Join-Path $pc 'decision_log.md'))
  ) | Where-Object { $_ -ne $null } | Sort-Object -Descending

  $activityTime = $hbUpdated
  if (-not $activityTime -and $fallback.Count -gt 0) { $activityTime = $fallback[0] }

  $now = Get-Date
  $ageMin = $null
  if ($activityTime) { $ageMin = [int][Math]::Floor(($now - $activityTime).TotalMinutes) }

  $status = 'UNKNOWN'
  if ($hb -and $hb.status) { $status = $hb.status.ToString().Trim().ToUpperInvariant() }

  Write-Host ("GAEH watchdog check @ {0}" -f $now.ToString('s'))
  if ($queue.ok) {
    Write-Host ("Queue: pending={0} active={1} done={2} current_task_id={3}" -f $queue.pending, $queue.active, $queue.done, $queue.current_task_id)
  } else {
    Write-Host "Queue: (missing or invalid) project_control/task_queue.json" -ForegroundColor Yellow
  }
  if ($activityTime) {
    Write-Host ("Last activity: {0} ({1} min ago)" -f $activityTime.ToString('s'), $ageMin)
  } else {
    Write-Host "Last activity: unknown (no heartbeat/queue/report timestamps found)" -ForegroundColor Yellow
  }
  if ($hb) {
    Write-Host ("Heartbeat: status={0} active_task_id={1} active_step={2}" -f $status, $hb.active_task_id, $hb.active_step)
  } else {
    Write-Host "Heartbeat: missing project_control/agent_heartbeat.json" -ForegroundColor Yellow
  }

  $hasWork = $false
  if ($queue.ok -and ($queue.pending -gt 0 -or $queue.active -gt 0)) { $hasWork = $true }

  $isStale = $false
  if ($ageMin -ne $null -and $ageMin -ge $StaleMinutes) { $isStale = $true }

  if ($hasWork -and $isStale) {
    Write-Host ("ALERT: appears stalled (no activity >= {0} minutes) while tasks remain." -f $StaleMinutes) -ForegroundColor Red
    Ensure-RecoveryPrompt -PromptPath $promptPath

    if (-not $hb) {
      $hb = [pscustomobject]@{
        schema_version = '1.0'
        updated_at = (Get-Date).ToString('yyyy-MM-dd')
        updated_ts = (Get-Date).ToString('s')
        status = 'STUCK'
        active_task_id = $queue.current_task_id
        active_step = 'WATCHDOG_DETECTED_STALL'
        last_artifact = 'project_control/recovery_prompt.md'
        note = ("auto-marked STUCK by watchdog; stale_minutes={0}" -f $StaleMinutes)
      }
    } else {
      $hb.updated_at = (Get-Date).ToString('yyyy-MM-dd')
      $hb.updated_ts = (Get-Date).ToString('s')
      $hb.status = 'STUCK'
      if (-not $hb.active_task_id) { $hb.active_task_id = $queue.current_task_id }
      $hb.active_step = 'WATCHDOG_DETECTED_STALL'
      $hb.last_artifact = 'project_control/recovery_prompt.md'
      $hb.note = ("auto-marked STUCK by watchdog; stale_minutes={0}" -f $StaleMinutes)
    }
    Write-Json -Path $hbPath -Obj $hb

    Write-Host ("Wrote recovery prompt: {0}" -f $promptPath) -ForegroundColor Yellow
    Write-Host ("Updated heartbeat: {0}" -f $hbPath) -ForegroundColor Yellow
  } elseif (-not $hasWork) {
    Write-Host "OK: no pending/active tasks detected." -ForegroundColor Green
  } else {
    Write-Host "OK: activity looks recent or within threshold." -ForegroundColor Green
  }
}

while ($true) {
  Check-Once -TargetPath $TargetPath -StaleMinutes $StaleMinutes
  if ($Once) { break }
  Start-Sleep -Seconds $IntervalSeconds
}

