<#
.SYNOPSIS
  Read-only candidate inventory for the Basic Memory memory-garden skill.
.DESCRIPTION
  Uses only Markdown frontmatter last_gardened_at and filesystem LastWriteTimeUtc.
  No hashes, databases, manifests, budgets, or LLM calls.
  Missing archived means NOT archived. Archived notes may be listed for gardening.
  Never edits files. Reads only frontmatter, not full Markdown bodies.
.EXAMPLE
  .\scripts\Find-GardenCandidates.ps1 -Root 'C:\basic-memory\main'
.EXAMPLE
  .\scripts\Find-GardenCandidates.ps1 -Root 'C:\basic-memory\main' -Folder 'engineering' |
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

function Get-FrontmatterValues {
    param([string] $FilePath)
    $result = @{ Archived = $false; LastGardenedAt = $null }
    $reader = [System.IO.StreamReader]::new($FilePath)
    try {
        if ($reader.ReadLine() -ne '---') { return $result }
        while (($line = $reader.ReadLine()) -ne $null) {
            if ($line -eq '---') { break }
            # Read only top-level scalar fields; no full YAML parsing needed.
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

# Stamping last_gardened_at itself changes mtime; accept a small write-time
# tolerance to avoid immediately re-reviewing a note just stamped.
$tolerance = [TimeSpan]::FromSeconds(5)

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

    $reason = if (-not $frontmatter.LastGardenedAt) {
        'never-gardened'
    } elseif (-not $valid) {
        'invalid-watermark'
    } elseif (($file.LastWriteTimeUtc - $stamp.UtcDateTime) -gt $tolerance) {
        'modified-since-gardening'
    } else {
        'unchanged'
    }

    if ($IncludeUnchanged -or $reason -ne 'unchanged') {
        [pscustomobject]@{
            Path = $file.FullName.Substring($projectRoot.Length).TrimStart([char]92,[char]47).Replace([char]92,[char]47)
            Bytes = $file.Length
            ModifiedUtc = $file.LastWriteTimeUtc.ToString('o')
            LastGardenedAt = $frontmatter.LastGardenedAt
            Archived = $frontmatter.Archived
            Reason = $reason
        }
    }
}
