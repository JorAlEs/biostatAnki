param(
    [string]$RepoPath = (Get-Location).Path,
    [string]$OutputDir = "social/linkedin",
    [int]$TopChanges = 5,
    [datetime]$ReferenceDate = (Get-Date)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-GitCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkingRepo,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $output = & git -C $WorkingRepo @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        $renderedArgs = $Arguments -join " "
        $renderedOutput = ($output | ForEach-Object { "$_" }) -join [Environment]::NewLine
        throw "git $renderedArgs failed.`n$renderedOutput"
    }

    return @($output)
}

function Get-CommitPrefix {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Subject
    )

    if ($Subject -match "^([A-Za-z]+)(\([^)]+\))?:\s+") {
        return $Matches[1].ToLowerInvariant()
    }

    return ""
}

function Format-SubjectForPost {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Subject
    )

    $clean = $Subject -replace "^[A-Za-z]+(\([^)]+\))?:\s*", ""
    $clean = $clean.Trim()
    if ([string]::IsNullOrWhiteSpace($clean)) {
        $clean = $Subject.Trim()
    }

    if ([string]::IsNullOrWhiteSpace($clean)) {
        return "Updated project internals."
    }

    $first = $clean.Substring(0, 1).ToUpperInvariant()
    if ($clean.Length -gt 1) {
        $clean = $first + $clean.Substring(1)
    } else {
        $clean = $first
    }

    if (-not $clean.EndsWith(".")) {
        $clean += "."
    }

    return $clean
}

function Get-RepositoryUrl {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkingRepo
    )

    $urlOutput = & git -C $WorkingRepo config --get remote.origin.url 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $urlOutput) {
        return ""
    }

    $url = @($urlOutput)[0].Trim()
    if ([string]::IsNullOrWhiteSpace($url)) {
        return ""
    }

    if ($url -match "^git@github\.com:(.+)\.git$") {
        return "https://github.com/$($Matches[1])"
    }

    if ($url -match "^https://github\.com/.+\.git$") {
        return $url.Substring(0, $url.Length - 4)
    }

    return $url
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git is required but was not found in PATH."
}

$resolvedRepo = (Resolve-Path -Path $RepoPath).Path
$workTreeCheck = & git -C $resolvedRepo rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -ne 0 -or @($workTreeCheck)[0].Trim() -ne "true") {
    throw "The path '$resolvedRepo' is not a git repository."
}

$targetDate = $ReferenceDate.Date.AddDays(-1)
$dateStamp = $targetDate.ToString("yyyy-MM-dd")
$humanDate = $targetDate.ToString("yyyy-MM-dd")
$windowStart = $targetDate.ToString("yyyy-MM-dd 00:00:00")
$windowEnd = $targetDate.AddDays(1).ToString("yyyy-MM-dd 00:00:00")

$fieldSeparator = [char]31
$prettyFormat = "%H%x1f%s%x1f%an"
$rawCommitLines = Invoke-GitCommand -WorkingRepo $resolvedRepo -Arguments @(
    "log",
    "--since=$windowStart",
    "--until=$windowEnd",
    "--no-merges",
    "--pretty=format:$prettyFormat"
)

$allCommits = @()
foreach ($line in $rawCommitLines) {
    if ([string]::IsNullOrWhiteSpace($line)) {
        continue
    }

    $parts = $line -split [regex]::Escape([string]$fieldSeparator), 3
    if ($parts.Count -lt 3) {
        continue
    }

    $subject = $parts[1].Trim()
    if ([string]::IsNullOrWhiteSpace($subject)) {
        continue
    }

    $allCommits += [pscustomobject]@{
        Hash = $parts[0].Trim()
        Subject = $subject
        Author = $parts[2].Trim()
    }
}

$excludedPrefixes = @("chore", "docs", "ci", "build", "style", "test")
$noiseTerms = @(
    "autonomous maintenance cycle",
    "repo facts",
    "review_state",
    "review state",
    "cycle "
)

$productCommits = @()
foreach ($commit in $allCommits) {
    $subjectLower = $commit.Subject.ToLowerInvariant()
    $isNoise = $false
    foreach ($term in $noiseTerms) {
        if ($subjectLower.Contains($term)) {
            $isNoise = $true
            break
        }
    }
    if ($isNoise) {
        continue
    }

    $prefix = Get-CommitPrefix -Subject $commit.Subject
    if ($prefix -and ($excludedPrefixes -contains $prefix)) {
        continue
    }

    $productCommits += [pscustomobject]@{
        Hash = $commit.Hash
        Subject = $commit.Subject
        Author = $commit.Author
        Prefix = $prefix
    }
}

if ($productCommits.Count -eq 0 -and $allCommits.Count -gt 0) {
    foreach ($fallbackCommit in ($allCommits | Select-Object -First $TopChanges)) {
        $productCommits += [pscustomobject]@{
            Hash = $fallbackCommit.Hash
            Subject = $fallbackCommit.Subject
            Author = $fallbackCommit.Author
            Prefix = (Get-CommitPrefix -Subject $fallbackCommit.Subject)
        }
    }
}

$highlightCommits = @($productCommits | Select-Object -First $TopChanges)
$changedFiles = @()
foreach ($commit in $highlightCommits) {
    $fileLines = Invoke-GitCommand -WorkingRepo $resolvedRepo -Arguments @(
        "show",
        "--pretty=",
        "--name-only",
        $commit.Hash
    )

    foreach ($file in $fileLines) {
        $trimmed = "$file".Trim()
        if (-not [string]::IsNullOrWhiteSpace($trimmed)) {
            $changedFiles += $trimmed
        }
    }
}

$uniqueFiles = @($changedFiles | Sort-Object -Unique)
$areaCounts = @{}
foreach ($file in $uniqueFiles) {
    $normalized = $file -replace "\\", "/"
    if ($normalized.Contains("/")) {
        $area = $normalized.Split("/", 2)[0]
    } else {
        $area = "(repo root)"
    }

    if (-not $areaCounts.ContainsKey($area)) {
        $areaCounts[$area] = 0
    }
    $areaCounts[$area] += 1
}

$topAreas = @()
if ($areaCounts.Count -gt 0) {
    $topAreas = @(
        $areaCounts.GetEnumerator() |
            Sort-Object -Property Value -Descending |
            Select-Object -First 4 |
            ForEach-Object { "$($_.Key) ($($_.Value))" }
    )
}

$repoUrl = Get-RepositoryUrl -WorkingRepo $resolvedRepo
$postLines = New-Object System.Collections.Generic.List[string]
$postLines.Add("Daily GitHub update for biostatAnki ($humanDate):")
$postLines.Add("")

if ($allCommits.Count -eq 0) {
    $postLines.Add("No commits landed yesterday, so there are no product changes to share today.")
} else {
    $postLines.Add("Yesterday we shipped:")

    foreach ($commit in $highlightCommits) {
        $postLines.Add("- $(Format-SubjectForPost -Subject $commit.Subject)")
    }

    if ($topAreas.Count -gt 0) {
        $postLines.Add("")
        $postLines.Add("Main areas touched: $($topAreas -join ", ").")
    }
}

$postLines.Add("")
$postLines.Add("I will share another concise update tomorrow.")
if (-not [string]::IsNullOrWhiteSpace($repoUrl)) {
    $postLines.Add("Repository: $repoUrl")
}
$postLines.Add("#opensource #github #rstats #shiny")

$postText = ($postLines -join [Environment]::NewLine).TrimEnd()

$outputRoot = Join-Path $resolvedRepo $OutputDir
New-Item -Path $outputRoot -ItemType Directory -Force | Out-Null

$datedTextPath = Join-Path $outputRoot ("linkedin-post-{0}.txt" -f $dateStamp)
$datedMarkdownPath = Join-Path $outputRoot ("linkedin-post-{0}.md" -f $dateStamp)
$latestPath = Join-Path $outputRoot "latest.txt"

Set-Content -Path $datedTextPath -Value $postText -Encoding utf8
Set-Content -Path $latestPath -Value $postText -Encoding utf8

$metadataLines = New-Object System.Collections.Generic.List[string]
$metadataLines.Add("# LinkedIn draft for $dateStamp")
$metadataLines.Add("")
$metadataLines.Add("Date window: $windowStart to $windowEnd (local time on the runner).")
$metadataLines.Add("Commits considered: $($allCommits.Count)")
$metadataLines.Add("Commits highlighted: $($highlightCommits.Count)")
$metadataLines.Add("")
$metadataLines.Add("## Post")
$metadataLines.Add("")
$metadataLines.Add($postText)

if ($highlightCommits.Count -gt 0) {
    $metadataLines.Add("")
    $metadataLines.Add("## Highlighted commits")
    foreach ($commit in $highlightCommits) {
        $shortHash = $commit.Hash
        if ($shortHash.Length -gt 7) {
            $shortHash = $shortHash.Substring(0, 7)
        }
        $metadataLines.Add("- $shortHash $($commit.Subject)")
    }
}

Set-Content -Path $datedMarkdownPath -Value ($metadataLines -join [Environment]::NewLine) -Encoding utf8

Write-Host "LinkedIn draft generated:"
Write-Host " - $datedTextPath"
Write-Host " - $datedMarkdownPath"
Write-Host " - $latestPath"
