Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoPath      = "C:\Users\Jorge\Documents\Proyectos\biostatanki\biostatAnki"
$cycleScript   = Join-Path $repoPath "run_cycle.js"
$logPath       = Join-Path $repoPath "autonomous_cycle_latest.log"
$stopFile      = Join-Path $repoPath "STOP_AUTONOMOUS_LOOP"
$agentLockFile = Join-Path $repoPath "AUTONOMOUS_ACTIVE_AGENT.txt"
$intervalMin   = 30
$agentName     = "chatgpt"

$packagePaths = @("R", "tests", "inst", "man", "vignettes", "DESCRIPTION", "NAMESPACE", "NEWS.md", "README.md")

function Write-Log {
    param([string]$Message)
    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path $logPath -Value $line -Encoding utf8
    Write-Host $line
}

function Get-NextSlot {
    param([datetime]$Now)
    $minutesUntilNext = $intervalMin - ($Now.Minute % $intervalMin)
    if ($minutesUntilNext -eq 0) { $minutesUntilNext = $intervalMin }
    return $Now.AddMinutes($minutesUntilNext).AddSeconds(-$Now.Second)
}

function Get-HeadHash {
    return (& git -C $repoPath rev-parse HEAD 2>&1).Trim()
}

function Test-ManagedProcessAlive {
    param([Nullable[int]]$PidToCheck)

    if (-not $PidToCheck) {
        return $false
    }

    return $null -ne (Get-Process -Id $PidToCheck -ErrorAction SilentlyContinue)
}

function Read-AgentLock {
    if (-not (Test-Path $agentLockFile)) {
        return $null
    }

    $raw = Get-Content $agentLockFile -Raw -Encoding utf8 -ErrorAction SilentlyContinue
    if (-not $raw) {
        return $null
    }

    try {
        $parsed = $raw | ConvertFrom-Json -ErrorAction Stop
        return [pscustomobject]@{
            agent      = "$($parsed.agent)".Trim()
            pid        = if ($null -eq $parsed.pid) { $null } else { [int]$parsed.pid }
            started_at = "$($parsed.started_at)".Trim()
        }
    }
    catch {
        return [pscustomobject]@{
            agent      = "$raw".Trim()
            pid        = $null
            started_at = ""
        }
    }
}

function Write-AgentLock {
    $payload = [pscustomobject]@{
        agent      = $agentName
        pid        = $PID
        started_at = (Get-Date).ToString("o")
    }

    $payload | ConvertTo-Json -Compress | Set-Content -Path $agentLockFile -Encoding utf8
}

function Get-RelevantChangedPaths {
    $tracked = @(
        & git -C $repoPath diff --name-only -- @packagePaths 2>$null |
            ForEach-Object { "$_".Trim() } |
            Where-Object { $_ }
    )
    $untracked = @(
        & git -C $repoPath ls-files --others --exclude-standard -- @packagePaths 2>$null |
            ForEach-Object { "$_".Trim() } |
            Where-Object { $_ }
    )

    @($tracked + $untracked | Sort-Object -Unique)
}

function Invoke-FallbackCommit {
    param(
        [string]$HeadBefore,
        [string[]]$DirtyBefore
    )

    Push-Location $repoPath
    try {
        $headNow = Get-HeadHash
        if ($headNow -ne $HeadBefore) {
            Write-Log "HEAD moved $HeadBefore -> $headNow. Skipping fallback commit."
            return
        }

        $dirtyAfter = @(Get-RelevantChangedPaths)
        if (-not $dirtyAfter) {
            Write-Log "No relevant changes detected. No fallback commit needed."
            return
        }

        $stageCandidates = @($dirtyAfter | Where-Object { $_ -notin $DirtyBefore })
        if (-not $stageCandidates) {
            Write-Log "Only pre-existing dirty package paths remain. No fallback commit."
            return
        }

        foreach ($path in $stageCandidates) {
            & git add -A -- $path 2>$null
        }

        $staged = @(
            & git diff --cached --name-only 2>&1 |
                ForEach-Object { "$_".Trim() } |
                Where-Object { $_ }
        )
        if (-not $staged) {
            Write-Log "No newly eligible package-path changes staged. No fallback commit."
            return
        }

        $ts = Get-Date -Format "yyyy-MM-dd HH:mm"
        $result = & git commit -m "chore: autonomous maintenance $ts" 2>&1
        Write-Log "Fallback commit: $result"
    }
    catch {
        Write-Log "Fallback commit error: $($_.Exception.Message)"
    }
    finally {
        Pop-Location
    }
}

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Log "ERROR: node command not found in PATH. Exiting."
    exit 1
}
if (-not (Test-Path $cycleScript)) {
    Write-Log "ERROR: cycle runner not found at $cycleScript. Exiting."
    exit 1
}

$existingLock = Read-AgentLock
if ($null -ne $existingLock -and $existingLock.agent) {
    $lockAlive = Test-ManagedProcessAlive -PidToCheck $existingLock.pid

    if ($lockAlive) {
        Write-Log "ERROR: another loop is active ($($existingLock.agent), pid $($existingLock.pid)). Stop it before starting $agentName."
        exit 1
    }

    Write-Log "Removing stale loop lock for agent '$($existingLock.agent)' (pid $($existingLock.pid))."
    Remove-Item -Path $agentLockFile -ErrorAction SilentlyContinue
}

Write-AgentLock
Write-Log "Autonomous loop started ($agentName). Interval: $intervalMin min. Repo: $repoPath"

try {
    while ($true) {
        if (Test-Path $stopFile) {
            Write-Log "Stop file detected ($stopFile). Exiting loop."
            break
        }

        Write-Log "=== Cycle start ==="
        $headBefore = Get-HeadHash
        $dirtyBefore = @(Get-RelevantChangedPaths)
        if ($dirtyBefore.Count -gt 0) {
            Write-Log ("Pre-existing dirty package paths excluded from fallback: " + ($dirtyBefore -join ", "))
        }

        Push-Location $repoPath
        $previousPref = $ErrorActionPreference
        try {
            $ErrorActionPreference = "Continue"
            & node $cycleScript 2>&1 | ForEach-Object { Write-Log "$_" }
            if ($LASTEXITCODE -ne 0) {
                Write-Log "Cycle runner exited with code $LASTEXITCODE."
            }
        }
        finally {
            $ErrorActionPreference = $previousPref
            Pop-Location
        }

        Invoke-FallbackCommit -HeadBefore $headBefore -DirtyBefore $dirtyBefore

        $next = Get-NextSlot -Now (Get-Date)
        $sleepSec = [Math]::Max(10, [int](($next - (Get-Date)).TotalSeconds))
        Write-Log "=== Cycle end. Next run at $next (sleep $sleepSec s) ==="
        Start-Sleep -Seconds $sleepSec
    }
}
finally {
    $activeLock = Read-AgentLock
    if ($null -ne $activeLock -and $activeLock.agent -eq $agentName -and $activeLock.pid -eq $PID) {
        Remove-Item -Path $agentLockFile -ErrorAction SilentlyContinue
    }
}
