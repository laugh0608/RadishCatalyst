[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$errors = [System.Collections.Generic.List[string]]::new()
$clientRoot = Join-Path $RepoRoot "client"
$sceneFiles = Get-ChildItem -LiteralPath $clientRoot -Recurse -File -Include *.tscn,*.tres,*.godot

function Add-Error([string]$Message) {
    $errors.Add($Message)
}

foreach ($file in $sceneFiles) {
    $relativePath = [System.IO.Path]::GetRelativePath($RepoRoot, $file.FullName)
    $content = Get-Content -LiteralPath $file.FullName -Raw
    $matches = [regex]::Matches($content, 'path="(res://[^"]+)"')

    foreach ($match in $matches) {
        $resourcePath = $match.Groups[1].Value
        $relativeResourcePath = $resourcePath.Substring("res://".Length).Replace("/", [System.IO.Path]::DirectorySeparatorChar)
        $fullResourcePath = Join-Path $clientRoot $relativeResourcePath

        if (-not (Test-Path -LiteralPath $fullResourcePath -PathType Leaf)) {
            Add-Error "${relativePath}: missing resource ${resourcePath}"
        }
    }

    if ($content -match "(?m)^(reward_id|reward_amount) = ") {
        Add-Error "${relativePath}: contains obsolete prototype reward properties"
    }
}

$scriptFiles = Get-ChildItem -LiteralPath (Join-Path $clientRoot "scripts") -Recurse -File -Filter *.gd
foreach ($scriptFile in $scriptFiles) {
    $uidPath = "$($scriptFile.FullName).uid"
    if (-not (Test-Path -LiteralPath $uidPath -PathType Leaf)) {
        Add-Error "$([System.IO.Path]::GetRelativePath($RepoRoot, $scriptFile.FullName)): missing Godot script uid file"
    }
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { [Console]::Error.WriteLine($_) }
    exit 1
}

Write-Host "Client scene references passed."
