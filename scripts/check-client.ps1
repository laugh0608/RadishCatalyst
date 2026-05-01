[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$GodotExe = "D:\Program Files\Godot\Godot_v4.6.2-stable_win64_console.exe"
)

$ErrorActionPreference = "Stop"

$checks = @(
    @{
        Name = "client static data"
        Script = "check-client-data.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client scenes"
        Script = "check-client-scenes.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client save runtime"
        Script = "check-client-save.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
            GodotExe = $GodotExe
        }
    },
    @{
        Name = "client quest rules"
        Script = "check-client-quests.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
            GodotExe = $GodotExe
        }
    },
    @{
        Name = "vertical slice flow"
        Script = "check-client-flow.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
            GodotExe = $GodotExe
        }
    },
    @{
        Name = "Godot client import"
        Script = "check-godot-client.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
            GodotExe = $GodotExe
        }
    }
)

foreach ($check in $checks) {
    Write-Host "Running $($check.Name)..."
    $parameters = $check.Parameters
    & (Join-Path $PSScriptRoot $check.Script) @parameters
    if (-not $?) {
        Write-Error "$($check.Name) failed."
        exit 1
    }
}

Write-Host "Client checks passed."
