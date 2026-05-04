[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$errors = [System.Collections.Generic.List[string]]::new()
$clientRoot = Join-Path $RepoRoot "client"
$sceneFiles = Get-ChildItem -LiteralPath $clientRoot -Recurse -File -Include *.tscn,*.tres,*.godot
$projectPath = Join-Path $clientRoot "project.godot"
$hudScenePath = Join-Path $clientRoot "scenes\ui\PrototypeHud.tscn"

function Add-Error([string]$Message) {
    $errors.Add($Message)
}

function Get-ConfigNumber([string]$Content, [string]$Key, [double]$DefaultValue) {
    $escapedKey = [regex]::Escape($Key)
    $match = [regex]::Match($Content, "(?m)^$escapedKey=(?<value>-?\d+(\.\d+)?)$")
    if (-not $match.Success) {
        return $DefaultValue
    }

    return [double]::Parse($match.Groups["value"].Value, [System.Globalization.CultureInfo]::InvariantCulture)
}

function Get-HudNodeProperties([string]$Content) {
    $nodes = @{}
    $currentName = $null
    $currentProperties = $null

    foreach ($line in ($Content -split "`r?`n")) {
        $nodeMatch = [regex]::Match($line, '^\[node name="(?<name>[^"]+)"')
        if ($nodeMatch.Success) {
            if ($null -ne $currentName) {
                $nodes[$currentName] = $currentProperties
            }

            $currentName = $nodeMatch.Groups["name"].Value
            $currentProperties = @{}
            continue
        }

        if ($null -eq $currentName) {
            continue
        }

        $propertyMatch = [regex]::Match($line, '^(?<key>[A-Za-z0-9_]+) = (?<value>.+)$')
        if ($propertyMatch.Success) {
            $currentProperties[$propertyMatch.Groups["key"].Value] = $propertyMatch.Groups["value"].Value.Trim()
        }
    }

    if ($null -ne $currentName) {
        $nodes[$currentName] = $currentProperties
    }

    return $nodes
}

function Get-NodeNumber($Properties, [string]$Key, [double]$DefaultValue) {
    if (-not $Properties.ContainsKey($Key)) {
        return $DefaultValue
    }

    return [double]::Parse($Properties[$Key], [System.Globalization.CultureInfo]::InvariantCulture)
}

function Get-PanelRect($Nodes, [string]$NodeName, [double]$ViewportWidth, [double]$ViewportHeight) {
    if (-not $Nodes.ContainsKey($NodeName)) {
        Add-Error "client/scenes/ui/PrototypeHud.tscn: missing HUD panel ${NodeName}"
        return $null
    }

    $properties = $Nodes[$NodeName]
    $anchorLeft = Get-NodeNumber $properties "anchor_left" 0.0
    $anchorRight = Get-NodeNumber $properties "anchor_right" 0.0
    $anchorTop = Get-NodeNumber $properties "anchor_top" 0.0
    $anchorBottom = Get-NodeNumber $properties "anchor_bottom" 0.0

    return [pscustomobject]@{
        Name = $NodeName
        Left = $anchorLeft * $ViewportWidth + (Get-NodeNumber $properties "offset_left" 0.0)
        Top = $anchorTop * $ViewportHeight + (Get-NodeNumber $properties "offset_top" 0.0)
        Right = $anchorRight * $ViewportWidth + (Get-NodeNumber $properties "offset_right" 0.0)
        Bottom = $anchorBottom * $ViewportHeight + (Get-NodeNumber $properties "offset_bottom" 0.0)
    }
}

function Test-RectOverlap($A, $B) {
    if ($A.Right -le $B.Left) {
        return $false
    }
    if ($A.Left -ge $B.Right) {
        return $false
    }
    if ($A.Bottom -le $B.Top) {
        return $false
    }
    if ($A.Top -ge $B.Bottom) {
        return $false
    }
    return $true
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

if (Test-Path -LiteralPath $projectPath -PathType Leaf) {
    $projectContent = Get-Content -LiteralPath $projectPath -Raw
    $viewportWidth = Get-ConfigNumber $projectContent "window/size/viewport_width" 2500.0
    $viewportHeight = Get-ConfigNumber $projectContent "window/size/viewport_height" 1400.0

    if (Test-Path -LiteralPath $hudScenePath -PathType Leaf) {
        $hudContent = Get-Content -LiteralPath $hudScenePath -Raw
        $nodes = Get-HudNodeProperties $hudContent
        $panelNames = @(
            "SavePanel",
            "CompletionPanel",
            "QuickSlotPanel",
            "StatusPanel",
            "MapPanel",
            "PromptPanel",
            "DevicePanel",
            "LogPanel",
            "EvacuationPanel",
            "SupplyFeedbackPanel"
        )
        $panels = @()

        foreach ($panelName in $panelNames) {
            $rect = Get-PanelRect $nodes $panelName $viewportWidth $viewportHeight
            if ($null -eq $rect) {
                continue
            }

            $panels += $rect
            if ($rect.Left -lt 0 -or $rect.Top -lt 0 -or $rect.Right -gt $viewportWidth -or $rect.Bottom -gt $viewportHeight) {
                Add-Error "client/scenes/ui/PrototypeHud.tscn: ${panelName} is outside viewport bounds"
            }
            if ($rect.Right -le $rect.Left -or $rect.Bottom -le $rect.Top) {
                Add-Error "client/scenes/ui/PrototypeHud.tscn: ${panelName} has invalid rect"
            }
        }

        for ($i = 0; $i -lt $panels.Count; $i++) {
            for ($j = $i + 1; $j -lt $panels.Count; $j++) {
                if (Test-RectOverlap $panels[$i] $panels[$j]) {
                    Add-Error "client/scenes/ui/PrototypeHud.tscn: $($panels[$i].Name) overlaps $($panels[$j].Name)"
                }
            }
        }
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
