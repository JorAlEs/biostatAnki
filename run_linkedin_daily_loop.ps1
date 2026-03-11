param(
    [string]$RepoPath = (Get-Location).Path,
    [string]$OutputDir = "social/linkedin",
    [int]$RunHour = 9,
    [int]$RunMinute = 0,
    [switch]$RunImmediately
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$resolvedRepo = (Resolve-Path -Path $RepoPath).Path
$generatorScript = Join-Path $PSScriptRoot "generate_linkedin_post.ps1"
$logPath = Join-Path $resolvedRepo "linkedin_daily_runtime.log"

if (-not (Test-Path $generatorScript)) {
    throw "Generator script not found at $generatorScript."
}

if ($RunHour -lt 0 -or $RunHour -gt 23) {
    throw "RunHour must be between 0 and 23."
}

if ($RunMinute -lt 0 -or $RunMinute -gt 59) {
    throw "RunMinute must be between 0 and 59."
}

function Write-LoopLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path $logPath -Value $line -Encoding utf8
}

function Get-NextRunTime {
    param(
        [Parameter(Mandatory = $true)]
        [datetime]$Now,

        [Parameter(Mandatory = $true)]
        [int]$Hour,

        [Parameter(Mandatory = $true)]
        [int]$Minute
    )

    $candidate = Get-Date -Year $Now.Year -Month $Now.Month -Day $Now.Day -Hour $Hour -Minute $Minute -Second 0
    if ($candidate -le $Now) {
        return $candidate.AddDays(1)
    }

    return $candidate
}

function Invoke-Generation {
    Write-LoopLog "Generating LinkedIn draft for yesterday."
    & $generatorScript -RepoPath $resolvedRepo -OutputDir $OutputDir 2>&1 |
        ForEach-Object { Write-LoopLog "$_" }
    if ($LASTEXITCODE -ne 0) {
        throw "LinkedIn draft generation failed."
    }
    Write-LoopLog "Generation completed."
}

Write-LoopLog "LinkedIn daily loop started. Schedule: $RunHour`:$("{0:d2}" -f $RunMinute) local time."

if ($RunImmediately) {
    try {
        Invoke-Generation
    }
    catch {
        Write-LoopLog "Immediate run failed: $($_.Exception.Message)"
    }
}

while ($true) {
    $nextRun = Get-NextRunTime -Now (Get-Date) -Hour $RunHour -Minute $RunMinute
    $waitSeconds = [Math]::Max(1, [int](($nextRun - (Get-Date)).TotalSeconds))

    Write-LoopLog "Next run scheduled at $nextRun. Sleeping for $waitSeconds seconds."
    Start-Sleep -Seconds $waitSeconds

    try {
        Invoke-Generation
    }
    catch {
        Write-LoopLog "Scheduled run failed: $($_.Exception.Message)"
    }
}
