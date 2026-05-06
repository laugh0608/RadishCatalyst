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
