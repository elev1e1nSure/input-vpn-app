#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Generate CHANGELOG.md entry from git commits between tags.

.DESCRIPTION
    Categorizes commits (feat, fix, refactor, etc.) and outputs
    formatted Markdown for the CHANGELOG.md file.

.PARAMETER FromTag
    Starting tag (defaults to latest tag).

.PARAMETER ToRef
    Ending ref (defaults to HEAD).

.EXAMPLE
    .\scripts\generate_changelog.ps1
    Generates changelog from latest tag to HEAD.

.EXAMPLE
    .\scripts\generate_changelog.ps1 -FromTag v1.1.0 -ToRef v1.2.0
#>

param(
    [string]$FromTag = (git describe --tags --abbrev=0),
    [string]$ToRef = "HEAD"
)

$ErrorActionPreference = "Stop"

function Write-Header($text) {
    Write-Host "`n$text" -ForegroundColor Cyan
    Write-Host ("=" * $text.Length) -ForegroundColor Cyan
}

function Get-CategorizedCommits($from, $to) {
    $commits = git log "$from..$to" --pretty=format:"%s|%h|%an" --no-merges
    
    $categories = @{
        Added    = @()
        Fixed    = @()
        Changed  = @()
        Removed  = @()
        Breaking = @()
        Other    = @()
    }
    
    foreach ($line in $commits) {
        if (-not $line) { continue }
        $parts = $line -split "\|", 3
        $subject = $parts[0]
        $hash = $parts[1]
        $author = $parts[2]
        
        $entry = "$subject ($hash) — @$author"
        
        if ($subject -match "^\w+\!\s*:") {
            $categories.Breaking += $entry
        }
        elseif ($subject -match "^(feat|add|introduce|test)\s*:") {
            $categories.Added += $entry
        }
        elseif ($subject -match "^(fix|repair|correct|hotfix)\s*:") {
            $categories.Fixed += $entry
        }
        elseif ($subject -match "^(refactor|style|update|chore|ci|build|perf|docs)\s*:") {
            $categories.Changed += $entry
        }
        elseif ($subject -match "^(remove|delete|drop|deprecate)\s*:") {
            $categories.Removed += $entry
        }
        else {
            $categories.Other += $entry
        }
    }
    
    return $categories
}

function Format-ChangelogSection($categories, $from, $to) {
    $date = Get-Date -Format "yyyy-MM-dd"
    $output = @"
## [$to] - $date

"@
    
    if ($categories.Breaking.Count -gt 0) {
        $output += "### ⚠️ Breaking Changes`n"
        $output += ($categories.Breaking | ForEach-Object { "- $_" }) -join "`n"
        $output += "`n`n"
    }
    
    if ($categories.Added.Count -gt 0) {
        $output += "### ✨ Added`n"
        $output += ($categories.Added | ForEach-Object { "- $_" }) -join "`n"
        $output += "`n`n"
    }
    
    if ($categories.Changed.Count -gt 0) {
        $output += "### 🔧 Changed`n"
        $output += ($categories.Changed | ForEach-Object { "- $_" }) -join "`n"
        $output += "`n`n"
    }
    
    if ($categories.Fixed.Count -gt 0) {
        $output += "### 🐛 Fixed`n"
        $output += ($categories.Fixed | ForEach-Object { "- $_" }) -join "`n"
        $output += "`n`n"
    }
    
    if ($categories.Removed.Count -gt 0) {
        $output += "### 🗑️ Removed`n"
        $output += ($categories.Removed | ForEach-Object { "- $_" }) -join "`n"
        $output += "`n`n"
    }
    
    if ($categories.Other.Count -gt 0) {
        $output += "### 📦 Other`n"
        $output += ($categories.Other | ForEach-Object { "- $_" }) -join "`n"
        $output += "`n`n"
    }
    
    return $output
}

# Main
Write-Header "Changelog Generator"
Write-Host "From: $FromTag"
Write-Host "To:   $ToRef"

$categories = Get-CategorizedCommits $FromTag $ToRef
$changelog = Format-ChangelogSection $categories $FromTag $ToRef

Write-Host "`nGenerated changelog:" -ForegroundColor Green
Write-Host "---"
Write-Host $changelog
Write-Host "---"

# Copy to clipboard
$changelog | Set-Clipboard
Write-Host "`n✅ Copied to clipboard! Paste into CHANGELOG.md" -ForegroundColor Green

# Optionally update CHANGELOG.md
$changelogFile = Join-Path $PSScriptRoot ".." "CHANGELOG.md"
$changelogFile = Resolve-Path $changelogFile

Write-Host "`nTo update CHANGELOG.md automatically, run:" -ForegroundColor Yellow
Write-Host "  .\scripts\update_changelog.ps1" -ForegroundColor Yellow
