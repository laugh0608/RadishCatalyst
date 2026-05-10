[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$errors = [System.Collections.Generic.List[string]]::new()
$clientRoot = Join-Path $RepoRoot "client"
$sceneFiles = Get-ChildItem -LiteralPath $clientRoot -Recurse -File -Include *.tscn,*.tres,*.godot
$projectPath = Join-Path $clientRoot "project.godot"
$gameRootScenePath = Join-Path $clientRoot "scenes\game\GameRoot.tscn"
$hudScenePath = Join-Path $clientRoot "scenes\ui\PrototypeHud.tscn"
$verticalSliceMapScenePath = Join-Path $clientRoot "scenes\maps\VerticalSliceMap.tscn"
$verticalSliceMapScriptPath = Join-Path $clientRoot "scripts\map\vertical_slice_map.gd"

function Add-Error([string]$Message) {
    $errors.Add($Message)
}

function Read-JsonFile([string]$Path) {
    try {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -Depth 100
    }
    catch {
        Add-Error "$([System.IO.Path]::GetRelativePath($RepoRoot, $Path)): invalid JSON: $($_.Exception.Message)"
        return $null
    }
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

function Get-SceneNodes([string]$Content) {
    $nodes = [System.Collections.Generic.List[object]]::new()
    $currentNode = $null

    foreach ($line in ($Content -split "`r?`n")) {
        $nodeMatch = [regex]::Match($line, '^\[node name="(?<name>[^"]+)"(?<attributes>[^\]]*)\]')
        if ($nodeMatch.Success) {
            if ($null -ne $currentNode) {
                $nodes.Add($currentNode)
            }

            $attributes = $nodeMatch.Groups["attributes"].Value
            $parent = ""
            $parentMatch = [regex]::Match($attributes, 'parent="(?<parent>[^"]+)"')
            if ($parentMatch.Success) {
                $parent = $parentMatch.Groups["parent"].Value
            }

            $currentNode = [pscustomobject]@{
                Name = $nodeMatch.Groups["name"].Value
                Parent = $parent
                Properties = @{}
            }
            continue
        }

        if ($null -eq $currentNode) {
            continue
        }

        $propertyMatch = [regex]::Match($line, '^(?<key>[A-Za-z0-9_]+) = (?<value>.+)$')
        if ($propertyMatch.Success) {
            $currentNode.Properties[$propertyMatch.Groups["key"].Value] = $propertyMatch.Groups["value"].Value.Trim()
        }
    }

    if ($null -ne $currentNode) {
        $nodes.Add($currentNode)
    }

    return $nodes
}

function Get-NodeString($Properties, [string]$Key, [string]$DefaultValue = "") {
    if (-not $Properties.ContainsKey($Key)) {
        return $DefaultValue
    }

    $value = [string]$Properties[$Key]
    if ($value.Length -ge 2 -and $value.StartsWith('"') -and $value.EndsWith('"')) {
        return $value.Substring(1, $value.Length - 2)
    }
    return $value
}

function Get-NodeNumber($Properties, [string]$Key, [double]$DefaultValue) {
    if (-not $Properties.ContainsKey($Key)) {
        return $DefaultValue
    }

    return [double]::Parse($Properties[$Key], [System.Globalization.CultureInfo]::InvariantCulture)
}

function Get-GDScriptConstantNumber([string]$Content, [string]$ConstantName, [double]$DefaultValue) {
    $escapedName = [regex]::Escape($ConstantName)
    $match = [regex]::Match($Content, "(?m)^const $escapedName := (?<value>-?\d+(\.\d+)?)$")
    if (-not $match.Success) {
        return $DefaultValue
    }

    return [double]::Parse($match.Groups["value"].Value, [System.Globalization.CultureInfo]::InvariantCulture)
}

function Get-NodeVector2($Properties, [string]$Key) {
    if (-not $Properties.ContainsKey($Key)) {
        return $null
    }

    $value = [string]$Properties[$Key]
    $match = [regex]::Match($value, '^Vector2\((?<x>-?\d+(\.\d+)?),\s*(?<y>-?\d+(\.\d+)?)\)$')
    if (-not $match.Success) {
        return $null
    }

    return [pscustomobject]@{
        X = [double]::Parse($match.Groups["x"].Value, [System.Globalization.CultureInfo]::InvariantCulture)
        Y = [double]::Parse($match.Groups["y"].Value, [System.Globalization.CultureInfo]::InvariantCulture)
    }
}

function Get-MapRegionId($Position, [double]$CrystalRegionX, [double]$PollutionRegionX, [double]$PollutionDeepY, [double]$RuinOuterRingX, [double]$DeepRuinRegionX, [double]$InnerPhaseWellRegionX, [double]$PhaseWellSinkRegionX, [double]$PhaseWellChamberRegionX) {
    if ($null -eq $Position) {
        return ""
    }

    if ($Position.X -ge $PhaseWellChamberRegionX) {
        return "region.phase_well_chamber"
    }
    if ($Position.X -ge $PhaseWellSinkRegionX) {
        return "region.phase_well_sink"
    }
    if ($Position.X -ge $InnerPhaseWellRegionX) {
        return "region.inner_phase_well"
    }
    if ($Position.X -ge $DeepRuinRegionX) {
        return "region.deep_ruin_threshold"
    }
    if ($Position.X -ge $RuinOuterRingX) {
        return "region.ruin_outer_ring"
    }
    if ($Position.X -ge $PollutionRegionX -and $Position.Y -ge $PollutionDeepY) {
        return "region.pollution_edge"
    }
    if ($Position.X -ge $CrystalRegionX) {
        return "region.crystal_vein_field"
    }
    return "region.outpost_platform"
}

function Add-UniqueStringValue([hashtable]$Map, [string]$Key, [string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Key) -or [string]::IsNullOrWhiteSpace($Value)) {
        return
    }
    if (-not $Map.ContainsKey($Key)) {
        $Map[$Key] = [System.Collections.Generic.List[string]]::new()
    }
    if ($Map[$Key] -notcontains $Value) {
        $Map[$Key].Add($Value)
    }
}

function Add-QuestRegionRequirement([hashtable]$RequirementsByQuestRegion, [string]$QuestId, [string]$RegionId, [string]$Reason) {
    if ([string]::IsNullOrWhiteSpace($QuestId) -or [string]::IsNullOrWhiteSpace($RegionId) -or [string]::IsNullOrWhiteSpace($Reason)) {
        return
    }

    $key = "${QuestId}|${RegionId}"
    if (-not $RequirementsByQuestRegion.ContainsKey($key)) {
        $RequirementsByQuestRegion[$key] = [System.Collections.Generic.List[string]]::new()
    }
    if ($RequirementsByQuestRegion[$key] -notcontains $Reason) {
        $RequirementsByQuestRegion[$key].Add($Reason)
    }
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

function Test-PointInRect($Point, $Rect, [double]$Padding = 0.0) {
    if ($null -eq $Point -or $null -eq $Rect) {
        return $false
    }
    if ($Point.X -lt ($Rect.Left - $Padding)) {
        return $false
    }
    if ($Point.X -gt ($Rect.Right + $Padding)) {
        return $false
    }
    if ($Point.Y -lt ($Rect.Top - $Padding)) {
        return $false
    }
    if ($Point.Y -gt ($Rect.Bottom + $Padding)) {
        return $false
    }
    return $true
}

function Resolve-CameraAxis([double]$Focus, [double]$MinEdge, [double]$MaxEdge, [double]$ViewportSize) {
    $halfViewport = $ViewportSize * 0.5
    $minCenter = $MinEdge + $halfViewport
    $maxCenter = $MaxEdge - $halfViewport
    if ($minCenter -gt $maxCenter) {
        return ($MinEdge + $MaxEdge) * 0.5
    }
    return [Math]::Min([Math]::Max($Focus, $minCenter), $maxCenter)
}

function ConvertTo-SnakeCase([string]$Name) {
    $withWordBoundaries = [regex]::Replace($Name, '([A-Z]+)([A-Z][a-z])', '$1_$2')
    $withLowerBoundaries = [regex]::Replace($withWordBoundaries, '([a-z0-9])([A-Z])', '$1_$2')
    return $withLowerBoundaries.ToLowerInvariant()
}

function Get-MapObjectInstanceId([string]$NodeName) {
    return "map_object_instance.$(ConvertTo-SnakeCase $NodeName)"
}

function Test-SceneInteractable($Interactables, [string]$DefinitionId, [string]$InteractionType = "") {
    foreach ($interactable in $Interactables) {
        if ($interactable.DefinitionId -ne $DefinitionId) {
            continue
        }
        if (-not [string]::IsNullOrWhiteSpace($InteractionType) -and $interactable.InteractionType -ne $InteractionType) {
            continue
        }
        return $true
    }
    return $false
}

function Count-SceneInteractables($Interactables, [string]$DefinitionId, [string]$InteractionType = "") {
    $count = 0
    foreach ($interactable in $Interactables) {
        if ($interactable.DefinitionId -ne $DefinitionId) {
            continue
        }
        if (-not [string]::IsNullOrWhiteSpace($InteractionType) -and $interactable.InteractionType -ne $InteractionType) {
            continue
        }
        $count += 1
    }
    return $count
}

function Test-SceneEnemy($Enemies, [string]$DefinitionId) {
    foreach ($enemy in $Enemies) {
        if ($enemy.DefinitionId -eq $DefinitionId) {
            return $true
        }
    }
    return $false
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
            "VitalsPanel",
            "MapPanel",
            "PromptPanel",
            "DevicePanel",
            "LogPanel",
            "EvacuationPanel",
            "SupplyFeedbackPanel"
        )
        $panels = @()
        $debugPanelNames = @("SavePanel", "QuickSlotPanel")

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

            $width = $rect.Right - $rect.Left
            $height = $rect.Bottom - $rect.Top
            switch ($panelName) {
                "MapPanel" {
                    if ($width -gt 380.0 -or $height -gt 220.0 -or $rect.Left -gt 40.0 -or $rect.Top -gt 40.0 -or $rect.Right -gt 420.0 -or $rect.Bottom -gt 240.0) {
                        Add-Error "client/scenes/ui/PrototypeHud.tscn: MapPanel drifted out of distributed HUD map bounds"
                    }
                }
                "StatusPanel" {
                    if ($width -gt 560.0 -or $height -gt 220.0 -or $rect.Left -gt 40.0 -or $rect.Top -lt 180.0 -or $rect.Top -gt 260.0 -or $rect.Right -gt 580.0 -or $rect.Bottom -gt 460.0) {
                        Add-Error "client/scenes/ui/PrototypeHud.tscn: StatusPanel drifted out of distributed HUD objective-card bounds"
                    }
                }
                "VitalsPanel" {
                    if ($width -gt 460.0 -or $height -gt 200.0 -or $rect.Top -gt 40.0 -or $rect.Left -lt ($viewportWidth - 540.0) -or $rect.Right -gt $viewportWidth) {
                        Add-Error "client/scenes/ui/PrototypeHud.tscn: VitalsPanel drifted out of distributed HUD vitals-card bounds"
                    }
                }
                "PromptPanel" {
                    if ($width -gt 860.0 -or $height -gt 220.0 -or $rect.Left -gt 40.0 -or $rect.Right -gt 860.0 -or $rect.Top -lt ($viewportHeight - 320.0)) {
                        Add-Error "client/scenes/ui/PrototypeHud.tscn: PromptPanel drifted out of distributed HUD bottom-rail bounds"
                    }
                }
                "LogPanel" {
                    if ($width -gt 860.0 -or $height -gt 120.0 -or $rect.Left -gt 40.0 -or $rect.Right -gt 860.0 -or $rect.Top -lt ($viewportHeight - 400.0)) {
                        Add-Error "client/scenes/ui/PrototypeHud.tscn: LogPanel drifted out of distributed HUD log-rail bounds"
                    }
                }
            }
        }

        for ($i = 0; $i -lt $panels.Count; $i++) {
            for ($j = $i + 1; $j -lt $panels.Count; $j++) {
                $aIsDebug = $debugPanelNames -contains $panels[$i].Name
                $bIsDebug = $debugPanelNames -contains $panels[$j].Name
                if ($aIsDebug -xor $bIsDebug) {
                    continue
                }
                if (Test-RectOverlap $panels[$i] $panels[$j]) {
                    Add-Error "client/scenes/ui/PrototypeHud.tscn: $($panels[$i].Name) overlaps $($panels[$j].Name)"
                }
            }
        }

        $panelsByName = @{}
        foreach ($panel in $panels) {
            $panelsByName[$panel.Name] = $panel
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

if (Test-Path -LiteralPath $verticalSliceMapScenePath -PathType Leaf) {
    $mapSceneContent = Get-Content -LiteralPath $verticalSliceMapScenePath -Raw
    $mapNodes = Get-SceneNodes $mapSceneContent
    $crystalRegionX = -70.0
    $pollutionRegionX = 200.0
    $pollutionDeepY = -40.0
    $ruinOuterRingX = 390.0
    $deepRuinRegionX = 700.0
    $innerPhaseWellRegionX = 1460.0
    $phaseWellSinkRegionX = 1760.0
    $phaseWellChamberRegionX = 2040.0
    if (Test-Path -LiteralPath $verticalSliceMapScriptPath -PathType Leaf) {
        $mapScriptContent = Get-Content -LiteralPath $verticalSliceMapScriptPath -Raw
        $crystalRegionX = Get-GDScriptConstantNumber $mapScriptContent "CRYSTAL_REGION_X" $crystalRegionX
        $pollutionRegionX = Get-GDScriptConstantNumber $mapScriptContent "POLLUTION_REGION_X" $pollutionRegionX
        $pollutionDeepY = Get-GDScriptConstantNumber $mapScriptContent "POLLUTION_DEEP_Y" $pollutionDeepY
        $ruinOuterRingX = Get-GDScriptConstantNumber $mapScriptContent "RUIN_OUTER_RING_X" $ruinOuterRingX
        $deepRuinRegionX = Get-GDScriptConstantNumber $mapScriptContent "DEEP_RUIN_REGION_X" $deepRuinRegionX
        $innerPhaseWellRegionX = Get-GDScriptConstantNumber $mapScriptContent "INNER_PHASE_WELL_REGION_X" $innerPhaseWellRegionX
        $phaseWellSinkRegionX = Get-GDScriptConstantNumber $mapScriptContent "PHASE_WELL_SINK_REGION_X" $phaseWellSinkRegionX
        $phaseWellChamberRegionX = Get-GDScriptConstantNumber $mapScriptContent "PHASE_WELL_CHAMBER_REGION_X" $phaseWellChamberRegionX
    }
    else {
        Add-Error "client/scripts/map/vertical_slice_map.gd: missing map region source for scene region checks"
    }

    $interactables = [System.Collections.Generic.List[object]]::new()
    $enemies = [System.Collections.Generic.List[object]]::new()
    $interactablesByInstanceId = @{}
    $playerPosition = $null
    $outpostCorePosition = $null
    $backgroundBounds = $null

    foreach ($node in $mapNodes) {
        if ($node.Parent -eq "." -and $node.Name -eq "Player") {
            $playerPosition = Get-NodeVector2 $node.Properties "position"
        }
        if ($node.Parent -eq "." -and $node.Name -eq "Background") {
            $backgroundBounds = [pscustomobject]@{
                Left = Get-NodeNumber $node.Properties "offset_left" 0.0
                Top = Get-NodeNumber $node.Properties "offset_top" 0.0
                Right = Get-NodeNumber $node.Properties "offset_right" 0.0
                Bottom = Get-NodeNumber $node.Properties "offset_bottom" 0.0
            }
        }

        if ($node.Parent -eq "Interactables" -and $node.Properties.ContainsKey("definition_id")) {
            $instanceId = Get-MapObjectInstanceId $node.Name
            $position = Get-NodeVector2 $node.Properties "position"
            if ($node.Name -eq "OutpostCore") {
                $outpostCorePosition = $position
            }
            $interactable = [pscustomobject]@{
                Name = $node.Name
                InstanceId = $instanceId
                DefinitionId = Get-NodeString $node.Properties "definition_id"
                InteractionType = Get-NodeString $node.Properties "interaction_type"
                PrerequisiteInstanceId = Get-NodeString $node.Properties "prerequisite_instance_id"
                RegionId = Get-MapRegionId $position $crystalRegionX $pollutionRegionX $pollutionDeepY $ruinOuterRingX $deepRuinRegionX $innerPhaseWellRegionX $phaseWellSinkRegionX $phaseWellChamberRegionX
            }
            $interactables.Add($interactable)
            $interactablesByInstanceId[$instanceId] = $interactable
        }

        if ($node.Parent -eq "Enemies" -and $node.Properties.ContainsKey("definition_id")) {
            $position = Get-NodeVector2 $node.Properties "position"
            $enemies.Add([pscustomobject]@{
                Name = $node.Name
                DefinitionId = Get-NodeString $node.Properties "definition_id"
                RegionId = Get-MapRegionId $position $crystalRegionX $pollutionRegionX $pollutionDeepY $ruinOuterRingX $deepRuinRegionX $innerPhaseWellRegionX $phaseWellSinkRegionX $phaseWellChamberRegionX
            })
        }
    }

    foreach ($interactable in $interactables) {
        if ($interactable.InteractionType -ne "build" -or [string]::IsNullOrWhiteSpace($interactable.PrerequisiteInstanceId)) {
            continue
        }
        if (-not $interactablesByInstanceId.ContainsKey($interactable.PrerequisiteInstanceId)) {
            Add-Error "client/scenes/maps/VerticalSliceMap.tscn: build interactable '$($interactable.Name)' references missing prerequisite_instance_id '$($interactable.PrerequisiteInstanceId)'"
        }
    }

    if ((Test-Path -LiteralPath $gameRootScenePath -PathType Leaf) -and $null -ne $playerPosition -and $null -ne $outpostCorePosition -and $null -ne $panelsByName) {
        $gameRootContent = Get-Content -LiteralPath $gameRootScenePath -Raw
        $gameRootNodes = Get-SceneNodes $gameRootContent
        $mapRootNode = $null
        $cameraNode = $null
        foreach ($node in $gameRootNodes) {
            if ($node.Parent -eq "." -and $node.Name -eq "VerticalSliceMap") {
                $mapRootNode = $node
            }
            if ($node.Parent -eq "." -and $node.Name -eq "WorldCamera") {
                $cameraNode = $node
            }
        }

        if ($null -eq $mapRootNode) {
            Add-Error "client/scenes/game/GameRoot.tscn: missing VerticalSliceMap instance"
        }
        elseif ($null -eq $cameraNode) {
            Add-Error "client/scenes/game/GameRoot.tscn: missing WorldCamera follow camera"
        }
        else {
            $mapRootPosition = Get-NodeVector2 $mapRootNode.Properties "position"
            $mapRootScale = Get-NodeVector2 $mapRootNode.Properties "scale"
            if ($null -eq $mapRootPosition) {
                Add-Error "client/scenes/game/GameRoot.tscn: VerticalSliceMap is missing position"
            }
            else {
                if ($null -eq $mapRootScale) {
                    $mapRootScale = [pscustomobject]@{ X = 1.0; Y = 1.0 }
                }

                $blockingPanels = @("MapPanel", "StatusPanel", "PromptPanel")
                $hotspots = @(
                    @{ Label = "player spawn"; Position = $playerPosition },
                    @{ Label = "outpost core"; Position = $outpostCorePosition }
                )

                foreach ($hotspot in $hotspots) {
                    $worldPoint = [pscustomobject]@{
                        X = $mapRootPosition.X + $hotspot.Position.X * $mapRootScale.X
                        Y = $mapRootPosition.Y + $hotspot.Position.Y * $mapRootScale.Y
                    }
                    $cameraCenter = $worldPoint
                    if ($null -ne $backgroundBounds) {
                        $backgroundLeft = $mapRootPosition.X + $backgroundBounds.Left * $mapRootScale.X
                        $backgroundTop = $mapRootPosition.Y + $backgroundBounds.Top * $mapRootScale.Y
                        $backgroundRight = $mapRootPosition.X + $backgroundBounds.Right * $mapRootScale.X
                        $backgroundBottom = $mapRootPosition.Y + $backgroundBounds.Bottom * $mapRootScale.Y
                        $cameraCenter = [pscustomobject]@{
                            X = Resolve-CameraAxis $worldPoint.X $backgroundLeft $backgroundRight $viewportWidth
                            Y = Resolve-CameraAxis $worldPoint.Y $backgroundTop $backgroundBottom $viewportHeight
                        }
                    }
                    $screenPoint = [pscustomobject]@{
                        X = $viewportWidth * 0.5 + ($worldPoint.X - $cameraCenter.X)
                        Y = $viewportHeight * 0.5 + ($worldPoint.Y - $cameraCenter.Y)
                    }
                    foreach ($panelName in $blockingPanels) {
                        if (-not $panelsByName.ContainsKey($panelName)) {
                            continue
                        }
                        if (Test-PointInRect $screenPoint $panelsByName[$panelName] 12.0) {
                            Add-Error "client/scenes/game/GameRoot.tscn: ${panelName} occludes ${hotspot.Label} hotspot"
                        }
                    }
                }
            }
        }
    }

    $questsPath = Join-Path $clientRoot "data\quests.json"
    $mapObjectsPath = Join-Path $clientRoot "data\map_objects.json"
    $recipesPath = Join-Path $clientRoot "data\recipes.json"
    $regionsPath = Join-Path $clientRoot "data\regions.json"
    $enemiesPath = Join-Path $clientRoot "data\enemies.json"
    $questsJson = Read-JsonFile $questsPath
    $mapObjectsJson = Read-JsonFile $mapObjectsPath
    $recipesJson = Read-JsonFile $recipesPath
    $regionsJson = Read-JsonFile $regionsPath
    $enemiesJson = Read-JsonFile $enemiesPath

    if ($null -ne $questsJson -and $null -ne $mapObjectsJson -and $null -ne $recipesJson -and $null -ne $regionsJson -and $null -ne $enemiesJson) {
        $mapObjectsById = @{}
        foreach ($mapObject in $mapObjectsJson.entries) {
            $mapObjectsById[[string]$mapObject.id] = $mapObject
        }

        $enemiesById = @{}
        foreach ($enemy in $enemiesJson.entries) {
            $enemiesById[[string]$enemy.id] = $enemy
        }

        $questRefsByRegion = @{}
        foreach ($region in $regionsJson.entries) {
            $questRefsByRegion[[string]$region.id] = @($region.quest_refs) | ForEach-Object { [string]$_ } | Where-Object {
                -not [string]::IsNullOrWhiteSpace($_)
            }
        }

        $processorRegionsByBuilding = @{}
        foreach ($interactable in $interactables) {
            if ($interactable.InteractionType -eq "process_recipe") {
                Add-UniqueStringValue $processorRegionsByBuilding $interactable.DefinitionId $interactable.RegionId
            }
        }

        $recipesByCraftedRef = @{}
        $gatherRegionsByItem = @{}
        $craftRegionsByItem = @{}
        foreach ($recipe in $recipesJson.entries) {
            $requiredBuildingId = [string]$recipe.required_building_id
            $processorRegions = @()
            if ($processorRegionsByBuilding.ContainsKey($requiredBuildingId)) {
                $processorRegions = @($processorRegionsByBuilding[$requiredBuildingId])
            }

            foreach ($output in @($recipe.outputs)) {
                $craftedId = [string]$output.id
                if (-not $recipesByCraftedRef.ContainsKey($craftedId)) {
                    $recipesByCraftedRef[$craftedId] = [System.Collections.Generic.List[object]]::new()
                }
                $recipesByCraftedRef[$craftedId].Add($recipe)
                foreach ($regionId in $processorRegions) {
                    Add-UniqueStringValue $craftRegionsByItem $craftedId $regionId
                    Add-UniqueStringValue $gatherRegionsByItem $craftedId $regionId
                }
            }
            foreach ($byproduct in @($recipe.byproducts)) {
                $craftedId = [string]$byproduct.id
                if (-not $recipesByCraftedRef.ContainsKey($craftedId)) {
                    $recipesByCraftedRef[$craftedId] = [System.Collections.Generic.List[object]]::new()
                }
                $recipesByCraftedRef[$craftedId].Add($recipe)
                foreach ($regionId in $processorRegions) {
                    Add-UniqueStringValue $craftRegionsByItem $craftedId $regionId
                    Add-UniqueStringValue $gatherRegionsByItem $craftedId $regionId
                }
            }
        }

        foreach ($interactable in $interactables) {
            if (-not $mapObjectsById.ContainsKey($interactable.DefinitionId)) {
                continue
            }
            $mapObject = $mapObjectsById[$interactable.DefinitionId]
            foreach ($drop in @($mapObject.drops)) {
                Add-UniqueStringValue $gatherRegionsByItem ([string]$drop.id) $interactable.RegionId
            }
            foreach ($sampleResultId in @($mapObject.sample_result_refs)) {
                Add-UniqueStringValue $gatherRegionsByItem ([string]$sampleResultId) $interactable.RegionId
            }
        }

        foreach ($enemy in $enemies) {
            if (-not $enemiesById.ContainsKey($enemy.DefinitionId)) {
                continue
            }
            foreach ($drop in @($enemiesById[$enemy.DefinitionId].drops)) {
                Add-UniqueStringValue $gatherRegionsByItem ([string]$drop.id) $enemy.RegionId
            }
        }

        $questRegionRequirements = @{}

        foreach ($quest in $questsJson.entries) {
            $questId = [string]$quest.id
            foreach ($objective in @($quest.objectives)) {
                $objectiveType = [string]$objective.type
                $targetId = [string]$objective.target_id
                $requiredAmount = [double]$objective.amount
                $objectiveRegions = [System.Collections.Generic.List[string]]::new()

                if ($objectiveType -eq "interact" -and -not (Test-SceneInteractable $interactables $targetId)) {
                    Add-Error "client/scenes/maps/VerticalSliceMap.tscn: quest '${questId}' interact target '${targetId}' has no scene interactable"
                }

                if ($objectiveType -eq "sample_object" -and -not (Test-SceneInteractable $interactables $targetId "sample")) {
                    Add-Error "client/scenes/maps/VerticalSliceMap.tscn: quest '${questId}' sample_object target '${targetId}' has no sample scene interactable"
                }

                if ($objectiveType -eq "inspect" -and -not (Test-SceneInteractable $interactables $targetId "inspect")) {
                    Add-Error "client/scenes/maps/VerticalSliceMap.tscn: quest '${questId}' inspect target '${targetId}' has no inspect scene interactable"
                }

                if ($objectiveType -eq "build") {
                    $buildSiteCount = Count-SceneInteractables $interactables $targetId "build"
                    if ($buildSiteCount -lt $requiredAmount) {
                        Add-Error "client/scenes/maps/VerticalSliceMap.tscn: quest '${questId}' build target '${targetId}' needs $requiredAmount build sites, got ${buildSiteCount}"
                    }
                }

                if ($objectiveType -eq "defeat_enemy" -and -not (Test-SceneEnemy $enemies $targetId)) {
                    Add-Error "client/scenes/maps/VerticalSliceMap.tscn: quest '${questId}' defeat_enemy target '${targetId}' has no scene enemy"
                }

                if ($objectiveType -eq "craft_item" -and $recipesByCraftedRef.ContainsKey($targetId)) {
                    $hasSceneProcessor = $false
                    foreach ($recipe in $recipesByCraftedRef[$targetId]) {
                        $requiredBuildingId = [string]$recipe.required_building_id
                        if (Test-SceneInteractable $interactables $requiredBuildingId "process_recipe") {
                            $hasSceneProcessor = $true
                            break
                        }
                    }
                    if (-not $hasSceneProcessor) {
                        Add-Error "client/scenes/maps/VerticalSliceMap.tscn: quest '${questId}' craft_item target '${targetId}' has no scene processor for its recipe"
                    }
                }

                if ($objectiveType -eq "gather_item") {
                    $sceneGatherAmount = 0.0
                    foreach ($interactable in $interactables) {
                        if ($interactable.InteractionType -ne "gather" -or -not $mapObjectsById.ContainsKey($interactable.DefinitionId)) {
                            continue
                        }
                        $mapObject = $mapObjectsById[$interactable.DefinitionId]
                        foreach ($drop in @($mapObject.drops)) {
                            if ([string]$drop.id -eq $targetId) {
                                $sceneGatherAmount += [double]$drop.amount
                            }
                        }
                    }
                    if ($sceneGatherAmount -gt 0.0 -and $sceneGatherAmount -lt $requiredAmount) {
                        Add-Error "client/scenes/maps/VerticalSliceMap.tscn: quest '${questId}' gather_item target '${targetId}' needs $requiredAmount from scene gather nodes, got ${sceneGatherAmount}"
                    }
                }

                switch ($objectiveType) {
                    "visit_region" {
                        if ($targetId -like "region.*") {
                            $objectiveRegions.Add($targetId)
                        }
                    }
                    "return_region" {
                        if ($targetId -like "region.*") {
                            $objectiveRegions.Add($targetId)
                        }
                    }
                    "interact" {
                        foreach ($interactable in $interactables) {
                            if ($interactable.DefinitionId -eq $targetId) {
                                $objectiveRegions.Add($interactable.RegionId)
                            }
                        }
                    }
                    "sample_object" {
                        foreach ($interactable in $interactables) {
                            if ($interactable.DefinitionId -eq $targetId -and $interactable.InteractionType -eq "sample") {
                                $objectiveRegions.Add($interactable.RegionId)
                            }
                        }
                    }
                    "inspect" {
                        foreach ($interactable in $interactables) {
                            if ($interactable.DefinitionId -eq $targetId -and $interactable.InteractionType -eq "inspect") {
                                $objectiveRegions.Add($interactable.RegionId)
                            }
                        }
                    }
                    "build" {
                        foreach ($interactable in $interactables) {
                            if ($interactable.DefinitionId -eq $targetId -and $interactable.InteractionType -eq "build") {
                                $objectiveRegions.Add($interactable.RegionId)
                            }
                        }
                    }
                    "defeat_enemy" {
                        foreach ($enemy in $enemies) {
                            if ($enemy.DefinitionId -eq $targetId) {
                                $objectiveRegions.Add($enemy.RegionId)
                            }
                        }
                    }
                    "craft_item" {
                        if ($craftRegionsByItem.ContainsKey($targetId)) {
                            foreach ($regionId in $craftRegionsByItem[$targetId]) {
                                $objectiveRegions.Add($regionId)
                            }
                        }
                    }
                    "gather_item" {
                        if ($gatherRegionsByItem.ContainsKey($targetId)) {
                            foreach ($regionId in $gatherRegionsByItem[$targetId]) {
                                $objectiveRegions.Add($regionId)
                            }
                        }
                    }
                }

                $uniqueObjectiveRegions = @($objectiveRegions | Where-Object {
                    -not [string]::IsNullOrWhiteSpace($_)
                } | Sort-Object -Unique)
                foreach ($regionId in $uniqueObjectiveRegions) {
                    Add-QuestRegionRequirement $questRegionRequirements $questId $regionId "${objectiveType}:${targetId}"
                }
            }
        }

        foreach ($requirement in $questRegionRequirements.GetEnumerator()) {
            $parts = $requirement.Key -split '\|', 2
            $questId = $parts[0]
            $regionId = $parts[1]
            if (-not $questRefsByRegion.ContainsKey($regionId)) {
                Add-Error "client/data/regions.json: missing region '${regionId}' required by quest '${questId}' objective region check"
                continue
            }
            if ($questRefsByRegion[$regionId] -contains $questId) {
                continue
            }
            $reasons = @($requirement.Value) -join ", "
            Add-Error "client/data/regions.json:${regionId}.quest_refs is missing quest '${questId}' required by scene-backed objective regions (${reasons})"
        }
    }
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { [Console]::Error.WriteLine($_) }
    exit 1
}

Write-Host "Client scene references passed."
