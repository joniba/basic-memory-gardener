<#
.SYNOPSIS
  Read-only candidate inventory for the Basic Memory memory-garden skill.
.DESCRIPTION
  Compares explicit canonical YAML frontmatter 'modified' with the gardener's
  'last_gardened_at'. Never uses filesystem mtime or Git commit timestamps.
  Notes missing an explicit, valid, offset-aware 'modified' stay eligible:
  Basic Memory's indexed 'updated_at' may otherwise be an mtime fallback.
  No hashes, databases, manifests, budgets, LLM calls, or file writes.
  Missing 'archived' means NOT archived. Reads top-level frontmatter scalars.
  Role/capture body protection is advisory, independent of legacy status.
  The helper does not authorize mutation.
.EXAMPLE
  # Run from the installed memory-garden skill's scripts directory:
  .\Find-GardenCandidates.ps1 -Root 'C:\basic-memory\main'
.EXAMPLE
  .\Find-GardenCandidates.ps1 -Root 'C:\basic-memory\main' -Folder 'engineering' |
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
    $result = @{
        Archived = $false; Modified = $null; LastGardenedAt = $null
        NoteRole = $null; CaptureStatus = $null; HasThreadId = $false
        HasCaptureStatus = $false; SawCaptureRole = $false
        SawSourceRole = $false; AmbiguousCaptureMetadata = $false
        InvalidFrontmatter = $false; AmbiguousTimestamps = $false
    }
    $seen = @{}
    $reader = [System.IO.StreamReader]::new($FilePath)
    try {
        if ($reader.ReadLine() -ne '---') { return $result }
        $result.InvalidFrontmatter = $true
        while (($line = $reader.ReadLine()) -ne $null) {
            if ($line -eq '---') {
                $result.InvalidFrontmatter = $false
                break
            }
            # Only top-level scalar YAML fields. A nested 'modified' is not
            # the Basic Memory canonical note timestamp.
            if ($line -match '^archived:\s*(?<value>[^#]*?)\s*(?:#.*)?$') {
                $raw = $Matches.value.Trim().Trim([char]39,[char]34)
                if ($seen.ContainsKey('archived')) { $result.AmbiguousCaptureMetadata = $true }
                $seen['archived'] = $true
                $result.Archived = $result.Archived -or ($raw -ieq 'true')
            } elseif ($line -match '^modified:\s*(?<value>[^#]*?)\s*(?:#.*)?$') {
                if ($seen.ContainsKey('modified')) { $result.AmbiguousTimestamps = $true }
                $seen['modified'] = $true
                $result.Modified = $Matches.value.Trim().Trim([char]39,[char]34)
            } elseif ($line -match '^last_gardened_at:\s*(?<value>[^#]*?)\s*(?:#.*)?$') {
                if ($seen.ContainsKey('last_gardened_at')) { $result.AmbiguousTimestamps = $true }
                $seen['last_gardened_at'] = $true
                $result.LastGardenedAt = $Matches.value.Trim().Trim([char]39,[char]34)
            } elseif ($line -match '^(?<key>note_role|capture_status|thread_id):\s*(?<value>[^#]*?)\s*(?:#.*)?$') {
                $key = $Matches.key
                $value = $Matches.value.Trim().Trim([char]39,[char]34)
                if ($seen.ContainsKey($key)) { $result.AmbiguousCaptureMetadata = $true }
                $seen[$key] = $true
                switch ($key) {
                    'thread_id' { $result.HasThreadId = $true }
                    'capture_status' {
                        $result.HasCaptureStatus = $true
                        $result.CaptureStatus = $value
                    }
                    'note_role' {
                        $result.NoteRole = $value
                        if ($value -cin @('session_capture', 'thread_capture', 'thread_capture_and_project_index')) {
                            $result.SawCaptureRole = $true
                        }
                        if ($value -ceq 'source_evidence') { $result.SawSourceRole = $true }
                    }
                }
            }
        }
        if ($result.InvalidFrontmatter) { $result.AmbiguousCaptureMetadata = $true }
    } finally {
        $reader.Dispose()
    }
    return $result
}

function Convert-ExplicitOffsetTimestamp {
    param([string] $Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    # BM accepts date-only/naive dates, but without an explicit offset the
    # inventory cannot safely compare across machines/timezones. Stay eligible.
    if ($Value -notmatch '(?:Z|[+-][0-9]{2}:[0-9]{2})$') { return $null }
    $parsed = [DateTimeOffset]::MinValue
    $valid = [DateTimeOffset]::TryParse(
        $Value,
        [Globalization.CultureInfo]::InvariantCulture,
        [Globalization.DateTimeStyles]::None,
        [ref] $parsed
    )
    if (-not $valid) { return $null }
    return $parsed
}

Get-ChildItem -LiteralPath $scanRoot -File -Recurse -Filter '*.md' | ForEach-Object {
    $file = $_
    $fm = Get-FrontmatterValues -FilePath $file.FullName
    $modified = Convert-ExplicitOffsetTimestamp -Value $fm.Modified
    $gardened = Convert-ExplicitOffsetTimestamp -Value $fm.LastGardenedAt
    $isCapture = $fm.HasThreadId -or $fm.HasCaptureStatus -or $fm.SawCaptureRole
    $protection = if ($isCapture -and $fm.Archived) {
        'archived-capture'
    } elseif ($fm.SawSourceRole) {
        'source-evidence'
    } elseif ($isCapture) {
        'capture-body'
    } else {
        'none'
    }

    $reason = if ($fm.InvalidFrontmatter) {
        'invalid-frontmatter'
    } elseif ($fm.AmbiguousTimestamps) {
        'ambiguous-timestamps'
    } elseif ([string]::IsNullOrWhiteSpace($fm.LastGardenedAt)) {
        'never-gardened'
    } elseif ($null -eq $gardened) {
        'invalid-watermark'
    } elseif ([string]::IsNullOrWhiteSpace($fm.Modified)) {
        'missing-canonical-modified'
    } elseif ($null -eq $modified) {
        'invalid-or-ambiguous-canonical-modified'
    } elseif ($modified.UtcDateTime -gt $gardened.UtcDateTime) {
        'modified-since-gardening'
    } else {
        'unchanged'
    }

    if ($IncludeUnchanged -or $reason -ne 'unchanged') {
        [pscustomobject]@{
            Path = $file.FullName.Substring($projectRoot.Length).TrimStart([char]92,[char]47).Replace([char]92,[char]47)
            Bytes = $file.Length
            Modified = $fm.Modified
            LastGardenedAt = $fm.LastGardenedAt
            Archived = $fm.Archived
            Reason = $reason
            NoteRole = $fm.NoteRole
            IsCapture = $isCapture
            CaptureStatus = $fm.CaptureStatus
            Protection = $protection
            AmbiguousCaptureMetadata = $fm.AmbiguousCaptureMetadata
            AmbiguousTimestamps = $fm.AmbiguousTimestamps
        }
    }
}
