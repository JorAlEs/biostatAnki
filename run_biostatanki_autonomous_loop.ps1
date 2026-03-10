$repoPath = "C:\Users\Jorge\Documents\Proyectos\biostatanki\biostatAnki"
$logPath = Join-Path $repoPath "autonomous_runtime.log"
$promptFile = Join-Path $repoPath "claude_cycle_prompt.txt"

# Prompt is read from claude_cycle_prompt.txt — edit that file to change cycle instructions.

function Test-AllowedWindow {
    param([datetime]$Now)
    return $true  # Run all hours, every day
}

function Get-NextHalfHour {
    param([datetime]$Now)

    if ($Now.Minute -lt 30) {
        return Get-Date -Year $Now.Year -Month $Now.Month -Day $Now.Day -Hour $Now.Hour -Minute 30 -Second 0
    } else {
        $next = $Now.AddHours(1)
        return Get-Date -Year $next.Year -Month $next.Month -Day $next.Day -Hour $next.Hour -Minute 0 -Second 0
    }
}

while ($true) {
    $now = Get-Date
    Add-Content -Path $logPath -Value "[$now] Loop tick"

    if (Test-AllowedWindow -Now $now) {
        Add-Content -Path $logPath -Value "[$now] Inside allowed window. Starting cycle."

        Push-Location $repoPath
        try {
            & claude --print --dangerously-skip-permissions `
                -p (Get-Content $promptFile -Raw) `
                2>&1 | Tee-Object -FilePath $logPath -Append
        }
        finally {
            Pop-Location
        }
    }
    else {
        Add-Content -Path $logPath -Value "[$now] Outside allowed window. Skipping cycle."
    }

    $nextRun      = Get-NextHalfHour -Now (Get-Date)
    $sleepSeconds = [Math]::Max(1, [int](($nextRun - (Get-Date)).TotalSeconds))
    Add-Content -Path $logPath -Value "[$(Get-Date)] Next run scheduled at $nextRun"
    Start-Sleep -Seconds $sleepSeconds
}
