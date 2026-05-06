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
$verticalSliceMapScenePath = Join-Path $clientRoot "scenes\maps\VerticalSliceMap.tscn"

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

if (Test-Path -LiteralPath $verticalSliceMapScenePath -PathType Leaf) {
    $mapSceneContent = Get-Content -LiteralPath $verticalSliceMapScenePath -Raw
    $mapNodes = Get-SceneNodes $mapSceneContent
    $interactables = [System.Collections.Generic.List[object]]::new()
    $enemies = [System.Collections.Generic.List[object]]::new()
    $interactablesByInstanceId = @{}

    foreach ($node in $mapNodes) {
        if ($node.Parent -eq "Interactables" -and $node.Properties.ContainsKey("definition_id")) {
            $instanceId = Get-MapObjectInstanceId $node.Name
            $interactable = [pscustomobject]@{
                Name = $node.Name
                InstanceId = $instanceId
                DefinitionId = Get-NodeString $node.Properties "definition_id"
                InteractionType = Get-NodeString $node.Properties "interaction_type"
                PrerequisiteInstanceId = Get-NodeString $node.Properties "prerequisite_instance_id"
            }
            $interactables.Add($interactable)
            $interactablesByInstanceId[$instanceId] = $interactable
        }

        if ($node.Parent -eq "Enemies" -and $node.Properties.ContainsKey("definition_id")) {
            $enemies.Add([pscustomobject]@{
                Name = $node.Name
                DefinitionId = Get-NodeString $node.Properties "definition_id"
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

    $questsPath = Join-Path $clientRoot "data\quests.json"
    $mapObjectsPath = Join-Path $clientRoot "data\map_objects.json"
    $recipesPath = Join-Path $clientRoot "data\recipes.json"
    $questsJson = Read-JsonFile $questsPath
    $mapObjectsJson = Read-JsonFile $mapObjectsPath
    $recipesJson = Read-JsonFile $recipesPath

    if ($null -ne $questsJson -and $null -ne $mapObjectsJson -and $null -ne $recipesJson) {
        $mapObjectsById = @{}
        foreach ($mapObject in $mapObjectsJson.entries) {
            $mapObjectsById[[string]$mapObject.id] = $mapObject
        }

        $recipesByCraftedRef = @{}
        foreach ($recipe in $recipesJson.entries) {
            foreach ($output in @($recipe.outputs)) {
                $craftedId = [string]$output.id
                if (-not $recipesByCraftedRef.ContainsKey($craftedId)) {
                    $recipesByCraftedRef[$craftedId] = [System.Collections.Generic.List[object]]::new()
                }
                $recipesByCraftedRef[$craftedId].Add($recipe)
            }
            foreach ($byproduct in @($recipe.byproducts)) {
                $craftedId = [string]$byproduct.id
                if (-not $recipesByCraftedRef.ContainsKey($craftedId)) {
                    $recipesByCraftedRef[$craftedId] = [System.Collections.Generic.List[object]]::new()
                }
                $recipesByCraftedRef[$craftedId].Add($recipe)
            }
        }

        foreach ($quest in $questsJson.entries) {
            $questId = [string]$quest.id
            foreach ($objective in @($quest.objectives)) {
                $objectiveType = [string]$objective.type
                $targetId = [string]$objective.target_id
                $requiredAmount = [double]$objective.amount

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
            }
        }
    }
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { [Console]::Error.WriteLine($_) }
    exit 1
}

Write-Host "Client scene references passed."
