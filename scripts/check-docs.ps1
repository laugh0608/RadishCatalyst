[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

function Get-DocFiles {
    Get-ChildItem -Path (Join-Path $RepoRoot "docs") -Recurse -File -Filter "*.md" |
        ForEach-Object { [System.IO.Path]::GetRelativePath($RepoRoot, $_.FullName).Replace("\", "/") } |
        Sort-Object
}

function Get-DocKind([string]$RelativePath) {
    if (
        $RelativePath -eq "docs/README.md" -or
        $RelativePath -eq "docs/planning/current.md" -or
        $RelativePath -eq "docs/planning/daily-start.md" -or
        $RelativePath -match "^docs/.+/README\.md$"
    ) {
        return "entry"
    }

    if ($RelativePath -match "^docs/archive/") {
        return "archive"
    }

    if ($RelativePath -match "^docs/devlogs/") {
        return "devlog"
    }

    if ($RelativePath -match "^docs/reference/") {
        return "reference"
    }

    return "active"
}

function Get-LineCount([string]$Content) {
    if ([string]::IsNullOrEmpty($Content)) {
        return 0
    }

    $lineCount = ($Content -split "`n").Count
    if ($Content.EndsWith("`n")) {
        $lineCount -= 1
    }

    return $lineCount
}

$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()

foreach ($relativePath in Get-DocFiles) {
    $fullPath = Join-Path $RepoRoot $relativePath
    $content = [System.IO.File]::ReadAllText($fullPath)
    $lineCount = Get-LineCount $content
    $charCount = $content.Length
    $docKind = Get-DocKind $relativePath

    switch ($docKind) {
        "entry" {
            if ($lineCount -gt 120) {
                $errors.Add("${relativePath}: entry document has ${lineCount} lines, over 120 line hard limit")
            }

            if ($charCount -gt 6000) {
                $warnings.Add("${relativePath}: entry document has ${charCount} chars, over 6000 char budget; trim detail or link to source documents")
            }
        }
        "active" {
            if ($lineCount -gt 280) {
                $warnings.Add("${relativePath}: active document has ${lineCount} lines, over 280 line soft limit; split into overview and child documents")
            }
        }
        "devlog" {
            if ($lineCount -gt 350) {
                $warnings.Add("${relativePath}: development log has ${lineCount} lines, over 350 line soft limit; tighten the summary or split long retrospectives")
            }
        }
        "reference" {
            if ($lineCount -gt 350) {
                $warnings.Add("${relativePath}: reference document has ${lineCount} lines, over 350 line soft limit; split by topic or move raw material to archive")
            }
        }
        default {
        }
    }
}

if ($warnings.Count -gt 0) {
    Write-Warning "Documentation budget warnings:"
    $warnings | ForEach-Object { Write-Warning $_ }
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Error $_ }
    exit 1
}

if ($warnings.Count -gt 0) {
    Write-Host "Documentation budget check passed with warnings."
}
else {
    Write-Host "Documentation budget check passed."
}
