[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$GodotExe = "",
    [switch]$WithGodot
)

$ErrorActionPreference = "Stop"
$runGodotChecks = $WithGodot -or ([Environment]::GetEnvironmentVariable("CHECK_CLIENT_WITH_GODOT") -match "^(1|true|yes)$")

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
        Name = "client industrial tech spine"
        Script = "check-client-industrial-tech-spine.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client scene art foundation"
        Script = "check-client-scene-art-foundation.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client functional transition route support"
        Script = "check-client-functional-transition-route-support.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo mainline completion"
        Script = "check-client-demo-mainline-completion.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo protective response"
        Script = "check-client-demo-protective-response.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo tool strike calibration"
        Script = "check-client-demo-tool-strike-calibration.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    }
)

if ($runGodotChecks) {
    . (Join-Path $PSScriptRoot "Resolve-GodotExe.ps1")
    $GodotExe = Resolve-GodotExe -GodotExe $GodotExe

    $checks += @(
        @{
            Name = "Godot client import"
            Script = "check-godot-client.ps1"
            Parameters = @{
                RepoRoot = $RepoRoot
                GodotExe = $GodotExe
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
            Name = "vertical slice flow and HUD runtime hints"
            Script = "check-client-flow.ps1"
            Parameters = @{
                RepoRoot = $RepoRoot
                GodotExe = $GodotExe
            }
        }
    )
}
else {
    Write-Host "Skipping Godot runtime checks. Use -WithGodot after confirming Godot can start in this environment."
}

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
