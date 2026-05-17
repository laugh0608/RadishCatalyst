[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$dataRoot = Join-Path $RepoRoot "client/data"
$dataFiles = @(
    "items.json",
    "fluids.json",
    "recipes.json",
    "buildings.json",
    "equipment.json",
    "enemies.json",
    "regions.json",
    "map_objects.json",
    "pollution_types.json",
    "weather_types.json",
    "quests.json"
)

$errors = [System.Collections.Generic.List[string]]::new()
$definitions = @{}
$filesByName = @{}

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

foreach ($fileName in $dataFiles) {
    $path = Join-Path $dataRoot $fileName
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Error "client/data/${fileName}: missing data file"
        continue
    }

    $json = Read-JsonFile $path
    if ($null -eq $json) {
        continue
    }

    if ($null -eq $json.schema_version) {
        Add-Error "client/data/${fileName}: missing schema_version"
    }
    if ($null -eq $json.entries -or $json.entries.Count -eq 0) {
        Add-Error "client/data/${fileName}: missing entries"
        continue
    }

    $filesByName[$fileName] = $json
    foreach ($entry in $json.entries) {
        if ([string]::IsNullOrWhiteSpace($entry.id)) {
            Add-Error "client/data/${fileName}: entry has empty id"
            continue
        }
        if ($entry.id -notmatch "^[a-z]+[a-z0-9_]*\.[a-z0-9_]+$") {
            Add-Error "client/data/${fileName}: invalid id format '$($entry.id)'"
        }
        if ($definitions.ContainsKey($entry.id)) {
            Add-Error "client/data/${fileName}: duplicate id '$($entry.id)'"
        }
        else {
            $definitions[$entry.id] = "client/data/${fileName}"
        }

        foreach ($field in @("display_name_key", "description_key", "public_level")) {
            if ([string]::IsNullOrWhiteSpace($entry.$field)) {
                Add-Error "client/data/${fileName}: '$($entry.id)' missing ${field}"
            }
        }
    }
}

function Test-DefinitionRef([string]$Source, [string]$ReferenceId) {
    if ([string]::IsNullOrWhiteSpace($ReferenceId)) {
        return
    }
    if ($ReferenceId -like "effect.*" -or $ReferenceId -like "drop.*" -or $ReferenceId -like "slice_*" -or $ReferenceId -like "world.*") {
        return
    }
    if (-not $definitions.ContainsKey($ReferenceId)) {
        Add-Error "${Source}: unknown reference '${ReferenceId}'"
    }
}

function Add-BudgetRef([hashtable]$Inventory, [string]$DefinitionId, [double]$Amount) {
    if ([string]::IsNullOrWhiteSpace($DefinitionId) -or $Amount -le 0) {
        return
    }

    if (-not $Inventory.ContainsKey($DefinitionId)) {
        $Inventory[$DefinitionId] = 0.0
    }
    $Inventory[$DefinitionId] = [double]$Inventory[$DefinitionId] + $Amount
}

function Use-BudgetRef([hashtable]$Inventory, [string]$DefinitionId, [double]$Amount, [string]$Source) {
    if ([string]::IsNullOrWhiteSpace($DefinitionId) -or $Amount -le 0) {
        return
    }

    $currentAmount = 0.0
    if ($Inventory.ContainsKey($DefinitionId)) {
        $currentAmount = [double]$Inventory[$DefinitionId]
    }

    if ($currentAmount + 0.0001 -lt $Amount) {
        Add-Error "client resource budget:${Source} requires '${DefinitionId}' x$Amount but only has $currentAmount"
        $Inventory[$DefinitionId] = 0.0
        return
    }

    $Inventory[$DefinitionId] = $currentAmount - $Amount
}

function Invoke-MainResourceBudgetCheck {
    if (-not $filesByName.ContainsKey("quests.json") -or -not $filesByName.ContainsKey("recipes.json") -or -not $filesByName.ContainsKey("buildings.json")) {
        return
    }

    $questsById = @{}
    $mainQuestIds = [System.Collections.Generic.List[string]]::new()
    foreach ($quest in $filesByName["quests.json"].entries) {
        $questId = [string]$quest.id
        $questsById[$questId] = $quest
        if ([string]$quest.quest_type -eq "main") {
            $mainQuestIds.Add($questId)
        }
    }

    $mainRoots = @(
        $mainQuestIds |
            Where-Object {
                $prerequisites = @($questsById[$_].prerequisites) | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
                $prerequisites.Count -eq 0
            }
    )
    if ($mainRoots.Count -ne 1) {
        return
    }

    $recipesByOutput = @{}
    $recipeOutputAmounts = @{}
    foreach ($recipe in $filesByName["recipes.json"].entries) {
        foreach ($output in @($recipe.outputs)) {
            $outputId = [string]$output.id
            if ([string]::IsNullOrWhiteSpace($outputId) -or $recipesByOutput.ContainsKey($outputId)) {
                continue
            }
            $recipesByOutput[$outputId] = $recipe
            $recipeOutputAmounts[$outputId] = [double]$output.amount
        }
    }

    $buildingsById = @{}
    foreach ($building in $filesByName["buildings.json"].entries) {
        $buildingsById[[string]$building.id] = $building
    }

    $mapObjectsById = @{}
    if ($filesByName.ContainsKey("map_objects.json")) {
        foreach ($mapObject in $filesByName["map_objects.json"].entries) {
            $mapObjectsById[[string]$mapObject.id] = $mapObject
        }
    }

    $inventory = @{
        "item.basic_parts" = 4.0
        "item.repair_gel" = 1.0
        "fluid.basic_solvent" = 3.0
    }
    $interactionConsumes = @{
        "map_object.outer_ring_barrier" = "item.phase_anchor"
        "map_object.deep_ruin_door" = "item.deep_ruin_coordinates"
        "map_object.deep_ruin_latch" = "item.deep_override_key"
        "map_object.deep_signal_array" = "item.deep_route_imprint"
        "map_object.phase_return_anchor" = "item.deep_signal_matrix"
        "map_object.phase_fault_spire" = "item.relay_tuning_lens"
        "map_object.phase_well_lock" = "item.phase_well_key"
        "map_object.inner_phase_well" = "item.phase_well_probe"
        "map_object.phase_well_sink" = "item.phase_well_pike"
        "map_object.phase_well_chamber" = "item.phase_well_shunt"
        "map_object.phase_well_loom" = "item.phase_well_shuttle"
        "map_object.phase_well_frame" = "item.phase_well_frame_key"
        "map_object.phase_well_tether" = "item.phase_well_tether_spike"
        "map_object.phase_well_anchor_field" = "item.phase_well_anchor_stake"
    }
    $craftingStack = @{}

    function Get-BudgetAmount([hashtable]$Inventory, [string]$DefinitionId) {
        if ($Inventory.ContainsKey($DefinitionId)) {
            return [double]$Inventory[$DefinitionId]
        }
        return 0.0
    }

    function Ensure-BudgetRef([hashtable]$Inventory, [string]$DefinitionId, [double]$Amount, [string]$Source) {
        if ([string]::IsNullOrWhiteSpace($DefinitionId) -or $Amount -le 0) {
            return
        }
        if ((Get-BudgetAmount $Inventory $DefinitionId) + 0.0001 -ge $Amount) {
            return
        }
        if ($DefinitionId -eq "item.basic_parts") {
            return
        }
        if (-not $recipesByOutput.ContainsKey($DefinitionId)) {
            return
        }
        if ($craftingStack.ContainsKey($DefinitionId)) {
            Add-Error "client resource budget:${Source} has recursive intermediate crafting for '${DefinitionId}'"
            return
        }

        $craftingStack[$DefinitionId] = $true
        $recipe = $recipesByOutput[$DefinitionId]
        $outputAmount = [double]$recipeOutputAmounts[$DefinitionId]
        if ($outputAmount -le 0) {
            $outputAmount = 1.0
        }
        $shortage = $Amount - (Get-BudgetAmount $Inventory $DefinitionId)
        $runs = [Math]::Ceiling($shortage / $outputAmount)
        for ($run = 0; $run -lt $runs; $run += 1) {
            foreach ($inputRef in @($recipe.inputs)) {
                Ensure-BudgetRef $Inventory ([string]$inputRef.id) ([double]$inputRef.amount) "${Source} -> $([string]$recipe.id).inputs"
                Use-BudgetRef $Inventory ([string]$inputRef.id) ([double]$inputRef.amount) "${Source} -> $([string]$recipe.id).inputs"
            }
            foreach ($outputRef in @($recipe.outputs)) {
                Add-BudgetRef $Inventory ([string]$outputRef.id) ([double]$outputRef.amount)
            }
            foreach ($byproductRef in @($recipe.byproducts)) {
                Add-BudgetRef $Inventory ([string]$byproductRef.id) ([double]$byproductRef.amount)
            }
        }
        $craftingStack.Remove($DefinitionId)
    }

    $visited = @{}
    $questId = [string]$mainRoots[0]
    while (-not [string]::IsNullOrWhiteSpace($questId)) {
        if ($visited.ContainsKey($questId)) {
            Add-Error "client resource budget: main quest graph loops at '${questId}'"
            return
        }
        $visited[$questId] = $true

        $quest = $questsById[$questId]
        foreach ($objective in @($quest.objectives)) {
            $objectiveType = [string]$objective.type
            $targetId = [string]$objective.target_id
            $amount = [double]$objective.amount
            if ($amount -le 0) {
                $amount = 1.0
            }

            if ($objectiveType -eq "gather_item") {
                Add-BudgetRef $inventory $targetId $amount
                continue
            }

            if ($objectiveType -eq "sample_object") {
                if ($mapObjectsById.ContainsKey($targetId)) {
                    foreach ($sampleResultId in @($mapObjectsById[$targetId].sample_result_refs)) {
                        Add-BudgetRef $inventory ([string]$sampleResultId) $amount
                    }
                }
                continue
            }

            if ($objectiveType -eq "craft_item") {
                if (-not $recipesByOutput.ContainsKey($targetId)) {
                    Add-Error "client resource budget:${questId} cannot craft '${targetId}' because no recipe output produces it"
                    continue
                }

                $recipe = $recipesByOutput[$targetId]
                $outputAmount = [double]$recipeOutputAmounts[$targetId]
                if ($outputAmount -le 0) {
                    $outputAmount = 1.0
                }
                $runs = [Math]::Ceiling($amount / $outputAmount)
                for ($run = 0; $run -lt $runs; $run += 1) {
                    foreach ($inputRef in @($recipe.inputs)) {
                        Ensure-BudgetRef $inventory ([string]$inputRef.id) ([double]$inputRef.amount) "${questId} -> $([string]$recipe.id).inputs"
                        Use-BudgetRef $inventory ([string]$inputRef.id) ([double]$inputRef.amount) "${questId} -> $([string]$recipe.id).inputs"
                    }
                    foreach ($outputRef in @($recipe.outputs)) {
                        Add-BudgetRef $inventory ([string]$outputRef.id) ([double]$outputRef.amount)
                    }
                    foreach ($byproductRef in @($recipe.byproducts)) {
                        Add-BudgetRef $inventory ([string]$byproductRef.id) ([double]$byproductRef.amount)
                    }
                }
                continue
            }

            if ($objectiveType -eq "build") {
                if (-not $buildingsById.ContainsKey($targetId)) {
                    Add-Error "client resource budget:${questId} cannot build unknown building '${targetId}'"
                    continue
                }

                $building = $buildingsById[$targetId]
                for ($run = 0; $run -lt [int]$amount; $run += 1) {
                    foreach ($costRef in @($building.build_cost)) {
                        Ensure-BudgetRef $inventory ([string]$costRef.id) ([double]$costRef.amount) "${questId} -> ${targetId}.build_cost"
                        Use-BudgetRef $inventory ([string]$costRef.id) ([double]$costRef.amount) "${questId} -> ${targetId}.build_cost"
                    }
                }
                continue
            }

            if ($objectiveType -eq "inspect" -and $interactionConsumes.ContainsKey($targetId)) {
                Use-BudgetRef $inventory ([string]$interactionConsumes[$targetId]) 1.0 "${questId} -> ${targetId}.inspect"
            }
        }

        foreach ($rewardRef in @($quest.rewards)) {
            Add-BudgetRef $inventory ([string]$rewardRef.id) ([double]$rewardRef.amount)
        }

        $nextMainQuestIds = @(
            @($quest.next_quest_ids) | ForEach-Object { [string]$_ } | Where-Object {
                -not [string]::IsNullOrWhiteSpace($_) -and $questsById.ContainsKey($_) -and [string]$questsById[$_].quest_type -eq "main"
            }
        )
        if ($nextMainQuestIds.Count -eq 0) {
            break
        }
        if ($nextMainQuestIds.Count -gt 1) {
            Add-Error "client resource budget:${questId} has multiple main next quests, budget check expects a single current main path"
            return
        }
        $questId = [string]$nextMainQuestIds[0]
    }

    Use-BudgetRef $inventory "item.basic_parts" 3.0 "allowed miscraft buffer"
    $terminalBasicParts = 0.0
    if ($inventory.ContainsKey("item.basic_parts")) {
        $terminalBasicParts = [double]$inventory["item.basic_parts"]
    }
    if ($terminalBasicParts -lt 8.0) {
        Add-Error "client resource budget: terminal basic parts buffer should be at least 8 after main path and 3 miscrafts, got $terminalBasicParts"
    }
}

foreach ($fileName in $filesByName.Keys) {
    foreach ($entry in $filesByName[$fileName].entries) {
        foreach ($property in $entry.PSObject.Properties) {
            $name = $property.Name
            $value = $property.Value

            if ($name -match "(_id|_refs|refs|resources|pollution_types|weather_pool|recommended_equipment|quest_refs|prerequisites|unlock_effects|next_quest_ids)$") {
                if ($value -is [array]) {
                    foreach ($ref in $value) {
                        Test-DefinitionRef "client/data/${fileName}:$($entry.id).${name}" ([string]$ref)
                    }
                }
                else {
                    Test-DefinitionRef "client/data/${fileName}:$($entry.id).${name}" ([string]$value)
                }
            }

            if ($name -in @("inputs", "outputs", "byproducts", "build_cost", "drops", "rewards")) {
                foreach ($refObject in @($value)) {
                    Test-DefinitionRef "client/data/${fileName}:$($entry.id).${name}" ([string]$refObject.id)
                }
            }

            if ($name -eq "objectives") {
                foreach ($objective in @($value)) {
                    Test-DefinitionRef "client/data/${fileName}:$($entry.id).${name}" ([string]$objective.target_id)
                }
            }
        }
    }
}

if ($filesByName.ContainsKey("quests.json") -and $filesByName.ContainsKey("regions.json")) {
    $questRefsByRegion = @{}
    foreach ($region in $filesByName["regions.json"].entries) {
        $regionId = [string]$region.id
        $questRefsByRegion[$regionId] = @($region.quest_refs) | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    }

    foreach ($quest in $filesByName["quests.json"].entries) {
        $questId = [string]$quest.id
        foreach ($objective in @($quest.objectives)) {
            $targetId = [string]$objective.target_id
            if ($targetId -notlike "region.*" -or -not $questRefsByRegion.ContainsKey($targetId)) {
                continue
            }
            if ($questRefsByRegion[$targetId] -notcontains $questId) {
                Add-Error "client/data/regions.json:${targetId}.quest_refs is missing quest '${questId}' required by direct region objective"
            }
        }
    }
}

if ($filesByName.ContainsKey("quests.json") -and $filesByName.ContainsKey("recipes.json")) {
    $recipeUnlockSources = @{}
    foreach ($quest in $filesByName["quests.json"].entries) {
        foreach ($effectId in @($quest.unlock_effects)) {
            $effectId = [string]$effectId
            if ($effectId -notlike "recipe.*") {
                continue
            }
            if (-not $recipeUnlockSources.ContainsKey($effectId)) {
                $recipeUnlockSources[$effectId] = [System.Collections.Generic.List[string]]::new()
            }
            $recipeUnlockSources[$effectId].Add([string]$quest.id)
        }
    }

    foreach ($recipe in $filesByName["recipes.json"].entries) {
        $recipeId = [string]$recipe.id
        $conditions = @($recipe.unlock_conditions) | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        if ($conditions.Count -eq 0) {
            continue
        }

        if (-not $recipeUnlockSources.ContainsKey($recipeId)) {
            Add-Error "client/data/recipes.json:${recipeId}.unlock_conditions declares quest gates but no quest unlock_effects contains '${recipeId}'"
            continue
        }

        $sources = @($recipeUnlockSources[$recipeId])
        foreach ($condition in $conditions) {
            if ($sources -notcontains $condition) {
                Add-Error "client/data/recipes.json:${recipeId}.unlock_conditions contains '${condition}', but that quest does not unlock '${recipeId}'"
            }
        }
        foreach ($source in $sources) {
            if ($conditions -notcontains $source) {
                Add-Error "client/data/recipes.json:${recipeId}.unlock_conditions is missing quest unlock source '${source}'"
            }
        }
    }
}

if ($filesByName.ContainsKey("quests.json")) {
    foreach ($quest in $filesByName["quests.json"].entries) {
        $nextQuestIds = @($quest.next_quest_ids) | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        $questUnlockEffects = @($quest.unlock_effects) | ForEach-Object { [string]$_ } | Where-Object { $_ -like "quest.*" }
        foreach ($nextQuestId in $nextQuestIds) {
            if ($questUnlockEffects -contains $nextQuestId) {
                Add-Error "client/data/quests.json:$($quest.id) lists '${nextQuestId}' in both next_quest_ids and unlock_effects"
            }
        }
    }
}

if ($filesByName.ContainsKey("quests.json")) {
    $questsById = @{}
    $mainQuestIds = [System.Collections.Generic.List[string]]::new()
    foreach ($quest in $filesByName["quests.json"].entries) {
        $questId = [string]$quest.id
        $questsById[$questId] = $quest
        if ([string]$quest.quest_type -eq "main") {
            $mainQuestIds.Add($questId)
        }
    }

    $mainRoots = [System.Collections.Generic.List[string]]::new()
    foreach ($questId in $mainQuestIds) {
        $quest = $questsById[$questId]
        $prerequisites = @($quest.prerequisites) | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        if ($prerequisites.Count -eq 0) {
            $mainRoots.Add($questId)
        }

        foreach ($prerequisiteId in $prerequisites) {
            if (-not $questsById.ContainsKey($prerequisiteId)) {
                continue
            }
            $prerequisite = $questsById[$prerequisiteId]
            if ([string]$prerequisite.quest_type -ne "main") {
                continue
            }
            $prerequisiteNextIds = @($prerequisite.next_quest_ids) | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            if ($prerequisiteNextIds -notcontains $questId) {
                Add-Error "client/data/quests.json:${questId}.prerequisites lists '${prerequisiteId}', but that quest does not include '${questId}' in next_quest_ids"
            }
        }

        $nextQuestIds = @($quest.next_quest_ids) | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        foreach ($nextQuestId in $nextQuestIds) {
            if (-not $questsById.ContainsKey($nextQuestId)) {
                continue
            }
            $nextQuest = $questsById[$nextQuestId]
            if ([string]$nextQuest.quest_type -ne "main") {
                continue
            }

            $nextPrerequisites = @($nextQuest.prerequisites) | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            if ($nextPrerequisites -notcontains $questId) {
                Add-Error "client/data/quests.json:${questId}.next_quest_ids lists '${nextQuestId}', but that quest prerequisites do not include '${questId}'"
            }

            if ([int]$nextQuest.stage -le [int]$quest.stage) {
                Add-Error "client/data/quests.json:${questId}.next_quest_ids points to '${nextQuestId}' with non-increasing stage $($nextQuest.stage)"
            }
        }
    }

    if ($mainRoots.Count -ne 1) {
        Add-Error "client/data/quests.json: main quest graph should have exactly one root with no prerequisites, got $($mainRoots.Count): $($mainRoots -join ', ')"
    }

    if ($mainRoots.Count -gt 0) {
        $visitedMainQuestIds = @{}
        $visitingMainQuestIds = @{}
        $stack = [System.Collections.Generic.Stack[string]]::new()
        $stack.Push($mainRoots[0])

        while ($stack.Count -gt 0) {
            $questId = $stack.Peek()
            if ($visitedMainQuestIds.ContainsKey($questId)) {
                [void]$stack.Pop()
                continue
            }
            if ($visitingMainQuestIds.ContainsKey($questId)) {
                $visitedMainQuestIds[$questId] = $true
                $visitingMainQuestIds.Remove($questId)
                [void]$stack.Pop()
                continue
            }

            $visitingMainQuestIds[$questId] = $true
            $quest = $questsById[$questId]
            foreach ($nextQuestId in @($quest.next_quest_ids)) {
                $nextQuestId = [string]$nextQuestId
                if (-not $questsById.ContainsKey($nextQuestId)) {
                    continue
                }
                if ([string]$questsById[$nextQuestId].quest_type -ne "main") {
                    continue
                }
                if ($visitedMainQuestIds.ContainsKey($nextQuestId)) {
                    continue
                }
                if ($visitingMainQuestIds.ContainsKey($nextQuestId)) {
                    Add-Error "client/data/quests.json: main quest graph has a cycle involving '${nextQuestId}'"
                    continue
                }
                $stack.Push($nextQuestId)
            }
        }

        foreach ($questId in $mainQuestIds) {
            if (-not $visitedMainQuestIds.ContainsKey($questId)) {
                Add-Error "client/data/quests.json:${questId} is not reachable from main quest root '$($mainRoots[0])' through next_quest_ids"
            }
        }
    }

    $terminalMainQuestIds = [System.Collections.Generic.List[string]]::new()
    foreach ($questId in $mainQuestIds) {
        $quest = $questsById[$questId]
        $nextMainQuestIds = @($quest.next_quest_ids) | ForEach-Object { [string]$_ } | Where-Object {
            -not [string]::IsNullOrWhiteSpace($_) -and $questsById.ContainsKey($_) -and [string]$questsById[$_].quest_type -eq "main"
        }
        if ($nextMainQuestIds.Count -eq 0) {
            $terminalMainQuestIds.Add($questId)
        }
    }

    $sliceCompletionTerminalCount = 0
    foreach ($questId in $terminalMainQuestIds) {
        $questUnlockEffects = @($questsById[$questId].unlock_effects) | ForEach-Object { [string]$_ }
        if ($questUnlockEffects -contains "slice_01_complete") {
            $sliceCompletionTerminalCount += 1
        }
    }
    if ($sliceCompletionTerminalCount -ne 1) {
        Add-Error "client/data/quests.json: main quest graph should have exactly one terminal quest unlocking slice_01_complete, got $sliceCompletionTerminalCount"
    }
}

if ($filesByName.ContainsKey("quests.json")) {
    $gatherSourcesById = @{}
    $craftSourcesById = @{}

    function Add-Source([hashtable]$SourcesById, [string]$DefinitionId, [string]$Source) {
        if ([string]::IsNullOrWhiteSpace($DefinitionId)) {
            return
        }
        if (-not $SourcesById.ContainsKey($DefinitionId)) {
            $SourcesById[$DefinitionId] = [System.Collections.Generic.List[string]]::new()
        }
        $SourcesById[$DefinitionId].Add($Source)
    }

    function Test-HasSource([hashtable]$SourcesById, [string]$DefinitionId) {
        return $SourcesById.ContainsKey($DefinitionId) -and $SourcesById[$DefinitionId].Count -gt 0
    }

    if ($filesByName.ContainsKey("map_objects.json")) {
        foreach ($mapObject in $filesByName["map_objects.json"].entries) {
            $mapObjectId = [string]$mapObject.id
            foreach ($drop in @($mapObject.drops)) {
                Add-Source $gatherSourcesById ([string]$drop.id) "map_object:${mapObjectId}.drops"
            }
            foreach ($sampleResultId in @($mapObject.sample_result_refs)) {
                Add-Source $gatherSourcesById ([string]$sampleResultId) "map_object:${mapObjectId}.sample_result_refs"
            }
        }
    }

    if ($filesByName.ContainsKey("enemies.json")) {
        foreach ($enemy in $filesByName["enemies.json"].entries) {
            $enemyId = [string]$enemy.id
            foreach ($drop in @($enemy.drops)) {
                Add-Source $gatherSourcesById ([string]$drop.id) "enemy:${enemyId}.drops"
            }
        }
    }

    if ($filesByName.ContainsKey("recipes.json")) {
        foreach ($recipe in $filesByName["recipes.json"].entries) {
            $recipeId = [string]$recipe.id
            foreach ($output in @($recipe.outputs)) {
                Add-Source $craftSourcesById ([string]$output.id) "recipe:${recipeId}.outputs"
            }
            foreach ($byproduct in @($recipe.byproducts)) {
                Add-Source $craftSourcesById ([string]$byproduct.id) "recipe:${recipeId}.byproducts"
            }
        }
    }

    foreach ($quest in $filesByName["quests.json"].entries) {
        $questId = [string]$quest.id
        foreach ($reward in @($quest.rewards)) {
            Add-Source $gatherSourcesById ([string]$reward.id) "quest:${questId}.rewards"
        }
    }

    foreach ($craftedId in $craftSourcesById.Keys) {
        foreach ($source in $craftSourcesById[$craftedId]) {
            Add-Source $gatherSourcesById $craftedId $source
        }
    }

    $enemiesById = @{}
    if ($filesByName.ContainsKey("enemies.json")) {
        foreach ($enemy in $filesByName["enemies.json"].entries) {
            $enemiesById[[string]$enemy.id] = $enemy
        }
    }

    foreach ($quest in $filesByName["quests.json"].entries) {
        $questId = [string]$quest.id
        foreach ($objective in @($quest.objectives)) {
            $objectiveType = [string]$objective.type
            $targetId = [string]$objective.target_id

            if ($objectiveType -eq "gather_item" -and -not (Test-HasSource $gatherSourcesById $targetId)) {
                Add-Error "client/data/quests.json:${questId}.objectives target '${targetId}' has no gatherable source from map objects, enemies, recipes, byproducts, or quest rewards"
            }

            if ($objectiveType -eq "craft_item" -and -not (Test-HasSource $craftSourcesById $targetId)) {
                Add-Error "client/data/quests.json:${questId}.objectives target '${targetId}' has no recipe output or byproduct source"
            }

            if ($objectiveType -eq "defeat_enemy") {
                if (-not $enemiesById.ContainsKey($targetId)) {
                    continue
                }
                $enemy = $enemiesById[$targetId]
                $spawnRegions = @($enemy.spawn_regions) | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
                if ($spawnRegions.Count -eq 0) {
                    Add-Error "client/data/quests.json:${questId}.objectives target '${targetId}' has no spawn_regions or explicit task-stage spawn source"
                }
            }
        }
    }
}

Invoke-MainResourceBudgetCheck

$localizationPath = Join-Path $dataRoot "localization/zh_cn.json"
$localization = Read-JsonFile $localizationPath
if ($null -ne $localization -and $null -ne $localization.entries) {
    foreach ($fileName in $filesByName.Keys) {
        foreach ($entry in $filesByName[$fileName].entries) {
            foreach ($keyField in @("display_name_key", "description_key")) {
                $key = [string]$entry.$keyField
                if (-not [string]::IsNullOrWhiteSpace($key) -and $null -eq $localization.entries.$key) {
                    Add-Error "client/data/localization/zh_cn.json: missing key '${key}'"
                }
            }
        }
    }
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { [Console]::Error.WriteLine($_) }
    exit 1
}

Write-Host "Client static data passed."
