<#
.SYNOPSIS
  Read-only candidate inventory for a Git-backed Basic Memory gardening worktree.
.DESCRIPTION
  Compares frontmatter last_gardened_at with the last COMMITTED modification
  time of each Markdown file. Git worktree checkouts reset filesystem mtimes,
  so LastWriteTimeUtc is NOT a valid cross-run watermark in a fresh worktree.
  Uses one git log pass; no hashes, manifests, databases, budgets, or LLM calls.
  Missing archived means NOT archived. Never edits files.
.EXAMPLE
  # Run from the installed skill's scripts directory:
  .\Find-GardenCandidates.ps1 -Root 'C:\garden-worktrees\run\notes'
.EXAMPLE
  .\Find-GardenCandidates.ps1 -Root 'C:\garden-worktrees\run\notes' -Folder 'engineering' |
    Format-Table -AutoSize
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Root,
    [string] $Folder = '',
    [switch] $IncludeUnchanged
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $Root).Path).TrimEnd([char]92,[char]47)
$scanRoot = if ([string]::IsNullOrWhiteSpace($Folder)) {
    $projectRoot
} else {
    [System.IO.Path]::GetFullPath((Join-Path $projectRoot $Folder)).TrimEnd([char]92,[char]47)
}
$separator = [System.IO.Path]::DirectorySeparatorChar
if ($scanRoot -ne $projectRoot -and
    -not $scanRoot.StartsWith($projectRoot + $separator, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Folder must be inside the Basic Memory project root: $projectRoot"
}
if (-not (Test-Path -LiteralPath $scanRoot -PathType Container)) {
    throw "Folder does not exist: $scanRoot"
}

# Fail fast unless this is a Git-backed corpus. Use the current worktree's
# committed history, not the live BM checkout or fresh checkout file mtimes.
$gitRootLines = @(& git -C $projectRoot rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0 -or $gitRootLines.Count -ne 1) {
    throw "BM project must be inside a local Git worktree: $projectRoot"
}
$gitRoot = [System.IO.Path]::GetFullPath($gitRootLines[0]).TrimEnd([char]92,[char]47)
$pathspec = $scanRoot.Substring($gitRoot.Length).TrimStart([char]92,[char]47).Replace([char]92,[char]47)
if (-not $pathspec) { $pathspec = '.' }

# One Git history pass yields the most recent committed modification for every
# path. A first occurrence wins because git log returns newest commits first.
$commitByPath = @{}
$currentCommitAt = $null
$history = @(& git -C $gitRoot -c core.quotepath=false log --name-only --no-renames --format='GARDEN-COMMIT:%cI' -- $pathspec)
if ($LASTEXITCODE -ne 0) { throw "Failed to read Git history for $scanRoot" }
foreach ($line in $history) {
    if ($line.StartsWith('GARDEN-COMMIT:', [StringComparison]::Ordinal)) {
        $dateText = $line.Substring('GARDEN-COMMIT:'.Length)
        $parsed = [DateTimeOffset]::MinValue
        if (-not [DateTimeOffset]::TryParse(
            $dateText, [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::None, [ref] $parsed)) {
            throw "Unparseable Git commit time: $dateText"
        }
        $currentCommitAt = $parsed
    } elseif ($line -and $null -ne $currentCommitAt) {
        $gitPath = $line.Replace([char]92,[char]47)
        if (-not $commitByPath.ContainsKey($gitPath)) {
            $commitByPath[$gitPath] = $currentCommitAt
        }
    }
}

function Get-FrontmatterValues {
    param([string] $FilePath)
    $result = @{ Archived = $false; LastGardenedAt = $null }
    $reader = [System.IO.StreamReader]::new($FilePath)
    try {
        if ($reader.ReadLine() -ne '---') { return $result }
        while (($line = $reader.ReadLine()) -ne $null) {
            if ($line -eq '---') { break }
            # Top-level scalar YAML fields only; no full YAML parser required.
            if ($line -match '^archived:\s*(?<value>[^#]*?)\s*(?:#.*)?$') {
                $raw = $Matches.value.Trim().Trim([char]39,[char]34)
                $result.Archived = ($raw -ieq 'true')
            } elseif ($line -match '^last_gardened_at:\s*(?<value>[^#]*?)\s*(?:#.*)?$') {
                $result.LastGardenedAt = $Matches.value.Trim().Trim([char]39,[char]34)
            }
        }
    } finally {
        $reader.Dispose()
    }
    return $result
}

# The gardening commit itself is normally seconds after last_gardened_at was
# stamped. Tolerate that gap; a very fast subsequent edit could be missed.
# This is a conscious, approximate watermark, not a deterministic change engine.
$tolerance = [TimeSpan]::FromMinutes(5)

Get-ChildItem -LiteralPath $scanRoot -File -Recurse -Filter '*.md' | ForEach-Object {
    $file = $_
    $frontmatter = Get-FrontmatterValues -FilePath $file.FullName
    $stamp = [DateTimeOffset]::MinValue
    $valid = $false
    if (-not [string]::IsNullOrWhiteSpace($frontmatter.LastGardenedAt)) {
        $valid = [DateTimeOffset]::TryParse(
            $frontmatter.LastGardenedAt,
            [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::AssumeUniversal,
            [ref] $stamp
        )
    }

    $gitPath = $file.FullName.Substring($gitRoot.Length).TrimStart([char]92,[char]47).Replace([char]92,[char]47)
    $committedAt = if ($commitByPath.ContainsKey($gitPath)) { $commitByPath[$gitPath] } else { $null }
    $reason = if ($null -eq $committedAt) {
        'not-committed'
    } elseif (-not $frontmatter.LastGardenedAt) {
        'never-gardened'
    } elseif (-not $valid) {
        'invalid-watermark'
    } elseif (($committedAt.UtcDateTime - $stamp.UtcDateTime) -gt $tolerance) {
        'modified-since-gardening'
    } else {
        'unchanged'
    }

    if ($IncludeUnchanged -or $reason -ne 'unchanged') {
        [pscustomobject]@{
            Path = $file.FullName.Substring($projectRoot.Length).TrimStart([char]92,[char]47).Replace([char]92,[char]47)
            Bytes = $file.Length
            LastCommittedAt = if ($null -ne $committedAt) { $committedAt.ToString('o') } else { $null }
            LastGardenedAt = $frontmatter.LastGardenedAt
            Archived = $frontmatter.Archived
            Reason = $reason
        }
    }
}
