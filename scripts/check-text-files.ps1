[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$textExtensions = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
@(
    ".cs", ".gd", ".gdshader", ".ts", ".tsx", ".js", ".jsx", ".rs", ".py",
    ".json", ".yaml", ".yml", ".toml", ".ini", ".cfg", ".xml", ".csproj",
    ".fsproj", ".props", ".targets", ".sln", ".godot", ".tscn",
    ".tres", ".md", ".txt", ".csv", ".ps1", ".sh", ".bat", ".cmd",
    ".gitattributes", ".gitignore", ".editorconfig", ".dockerignore",
    ".svg", ".gltf"
) | ForEach-Object { [void]$textExtensions.Add($_) }

$sourceExtensions = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
@(".cs", ".gd", ".ts", ".tsx", ".js", ".jsx", ".rs", ".py", ".ps1", ".sh") | ForEach-Object {
    [void]$sourceExtensions.Add($_)
}

$skipTrailingWhitespaceExtensions = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
@(".md", ".csv") | ForEach-Object { [void]$skipTrailingWhitespaceExtensions.Add($_) }

function Get-RepositoryFiles {
    Push-Location $RepoRoot
    try {
        $files = & git ls-files --cached --others --exclude-standard
        if ($LASTEXITCODE -eq 0 -and $files) {
            return $files
        }

        return Get-ChildItem -Recurse -File -Force |
            Where-Object { $_.FullName -notmatch "[/\\]\.git[/\\]" } |
            ForEach-Object { [System.IO.Path]::GetRelativePath($RepoRoot, $_.FullName) }
    }
    finally {
        Pop-Location
    }
}

function Test-IsTextFile([string]$RelativePath) {
    $name = [System.IO.Path]::GetFileName($RelativePath)
    $extension = [System.IO.Path]::GetExtension($RelativePath)

    if ($textExtensions.Contains($name)) {
        return $true
    }

    return $textExtensions.Contains($extension)
}

$utf8Strict = [System.Text.UTF8Encoding]::new($false, $true)
$errors = [System.Collections.Generic.List[string]]::new()
$files = Get-RepositoryFiles

foreach ($relativePath in $files) {
    if (-not (Test-IsTextFile $relativePath)) {
        continue
    }

    $fullPath = Join-Path $RepoRoot $relativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        continue
    }

    $bytes = [System.IO.File]::ReadAllBytes($fullPath)
    if ($bytes.Length -eq 0) {
        continue
    }

    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $errors.Add("${relativePath}: contains UTF-8 BOM")
        continue
    }

    try {
        $content = $utf8Strict.GetString($bytes)
    }
    catch {
        $errors.Add("${relativePath}: is not valid UTF-8")
        continue
    }

    if ($content.Contains("`r")) {
        $errors.Add("${relativePath}: contains CR or CRLF line endings")
    }

    if (-not $content.EndsWith("`n")) {
        $errors.Add("${relativePath}: missing final newline")
    }

    $extension = [System.IO.Path]::GetExtension($relativePath)
    if (-not $skipTrailingWhitespaceExtensions.Contains($extension)) {
        $lines = $content -split "`n", -1
        for ($index = 0; $index -lt $lines.Length; $index++) {
            $line = $lines[$index]
            if ($line.EndsWith(" ") -or $line.EndsWith("`t")) {
                $lineNumber = $index + 1
                $errors.Add("${relativePath}:${lineNumber}: trailing whitespace")
                break
            }
        }
    }

    if ($sourceExtensions.Contains($extension)) {
        $lineCount = ($content -split "`n").Count
        if ($lineCount -gt 1500) {
            $errors.Add("${relativePath}: source file has ${lineCount} lines, over 1500 line hard limit")
        }
    }
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Host "Repo hygiene passed."
