#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Update CHANGELOG.md with generated entry from latest commits.

.DESCRIPTION
    Runs generate_changelog.ps1 and inserts the output into CHANGELOG.md
    under the [Unreleased] section.

.EXAMPLE
    .\scripts\update_changelog.ps1
#>

$ErrorActionPreference = "Stop"

$scriptDir = $PSScriptRoot
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")
$changelogFile = Join-Path $repoRoot "CHANGELOG.md"

Write-Host "Updating CHANGELOG.md..." -ForegroundColor Cyan

# Generate changelog content
$changelogEntry = & (Join-Path $scriptDir "generate_changelog.ps1") 2>$null

if (-not $changelogEntry) {
    Write-Error "Failed to generate changelog"
    exit 1
}

# Read current CHANGELOG.md
$content = Get-Content $changelogFile -Raw

# Find [Unreleased] section and insert after it
$unreleasedPattern = "## \[Unreleased\]"
$nextVersionPattern = "## \[\d+\.\d+\.\d+\]"

if ($content -match $unreleasedPattern) {
    $parts = $content -split $nextVersionPattern, 2
    
    if ($parts.Count -eq 2) {
        $newContent = $parts[0].TrimEnd() + "`n`n" + $changelogEntry + "`n" + $nextVersionPattern + $parts[1]
    }
    else {
        $newContent = $content.TrimEnd() + "`n`n" + $changelogEntry
    }
    
    $newContent | Set-Content $changelogFile -NoNewline
    Write-Host "CHANGELOG.md updated successfully!" -ForegroundColor Green
}
else {
    Write-Error "Could not find [Unreleased] section in CHANGELOG.md"
    exit 1
}
