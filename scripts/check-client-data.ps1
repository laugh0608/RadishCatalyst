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
