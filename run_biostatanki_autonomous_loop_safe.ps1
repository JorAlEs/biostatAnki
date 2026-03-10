$repoPath = "C:\Users\Jorge\Documents\Proyectos\biostatanki\biostatAnki"
$logPath  = Join-Path $repoPath "autonomous_runtime.log"
$promptFile = Join-Path $repoPath "claude_cycle_prompt.txt"

$cyclePrompt = @"
Run one autonomous maintenance cycle on the local repo at:

C:\Users\Jorge\Documents\Proyectos\biostatanki\biostatAnki

Instructions:
- Inspect the real current repository state first.
- Ignore any prior summary unless verified from files.
- Choose exactly one small high-value improvement only.
- Implement it carefully.
- Validate it with the most relevant available checks.
- If the result is valid and the repo has meaningful changes, stage and commit them autonomously.
- Update AUTONOMOUS_REVIEW_STATE.md.
- End with the structured cycle report.

Priority order:
correctness, tests, security, reproducibility, CI/lint reliability, maintainability, docs, justified modernization.

Git rules:
- Commit only if changes are meaningful and validated.
- Do not commit logs, cache, temp files, or unrelated churn.
- Use a concise conventional commit message.
- If validation fails and cannot be fixed in the same cycle, do not commit.

Do not force a change if nothing safe and useful is warranted.
"@

Set-Content -Path $promptFile -Value $cyclePrompt -Encoding UTF8

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

function Invoke-FallbackCommit {
    param([string]$RepoPath)

    Push-Location $RepoPath
    try {
        $status = git status --porcelain
        if (-not $status) {
            Add-Content -Path $logPath -Value "[$(Get-Date)] No git changes detected after cycle."
            return
        }

        # Unstage/discard known noise files before committing
        $filesToExclude = @(
            "autonomous_runtime.log"
        )
        foreach ($excluded in $filesToExclude) {
            git restore --staged -- $excluded 2>$null
            git checkout -- $excluded 2>$null
        }

        $statusAfterExclude = git status --porcelain
        if (-not $statusAfterExclude) {
            Add-Content -Path $logPath -Value "[$(Get-Date)] Only excluded files changed. No commit created."
            return
        }

        git add -A

        $timestamp     = Get-Date -Format "yyyy-MM-dd HH:mm"
        $commitMessage = "chore: autonomous maintenance cycle $timestamp"

        git commit -m $commitMessage 2>&1 | Tee-Object -FilePath $logPath -Append
        Add-Content -Path $logPath -Value "[$(Get-Date)] Fallback commit created."
    }
    finally {
        Pop-Location
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

        Invoke-FallbackCommit -RepoPath $repoPath
    }
    else {
        Add-Content -Path $logPath -Value "[$now] Outside allowed window. Skipping cycle."
    }

    $nextRun      = Get-NextHalfHour -Now (Get-Date)
    $sleepSeconds = [Math]::Max(1, [int](($nextRun - (Get-Date)).TotalSeconds))
    Add-Content -Path $logPath -Value "[$(Get-Date)] Next run scheduled at $nextRun"
    Start-Sleep -Seconds $sleepSeconds
}
