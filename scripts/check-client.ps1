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
        Name = "client demo resource chain state"
        Script = "check-client-demo-resource-chain-state.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo save state contract"
        Script = "check-client-demo-save-state-contract.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo main path continuity"
        Script = "check-client-demo-main-path-continuity.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo runtime surface decomposition"
        Script = "check-client-demo-runtime-surface-decomposition.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo functional scene gameplay"
        Script = "check-client-demo-functional-scene-gameplay.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo functional scene gameplay density"
        Script = "check-client-demo-functional-scene-gameplay-density.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo functional transition spatial playability"
        Script = "check-client-demo-functional-transition-spatial-playability.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo midfield route playability"
        Script = "check-client-demo-midfield-route-playability.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo wind corridor transition playability"
        Script = "check-client-demo-wind-corridor-transition-playability.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo core approach handoff playability"
        Script = "check-client-demo-core-approach-handoff-playability.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo core stabilization run playability"
        Script = "check-client-demo-core-stabilization-run-playability.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo device panel operation readability"
        Script = "check-client-demo-device-panel-operation-readability.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo field loop payoff"
        Script = "check-client-demo-field-loop-payoff.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo route return and base reentry"
        Script = "check-client-demo-route-return-and-base-reentry.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo endpoint readiness"
        Script = "check-client-demo-endpoint-readiness.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo completion outcome readout"
        Script = "check-client-demo-completion-outcome-readout.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo playable experience coherence"
        Script = "check-client-demo-playable-experience-coherence.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo playable scene composition"
        Script = "check-client-demo-playable-scene-composition.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo combat evacuation recovery"
        Script = "check-client-demo-combat-evacuation-recovery.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo interaction affordance"
        Script = "check-client-demo-interaction-affordance.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo interaction prompt surface decomposition"
        Script = "check-client-demo-interaction-prompt-surface-decomposition.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo map surface decomposition"
        Script = "check-client-demo-map-surface-decomposition.ps1"
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
        Name = "client non-core scene identity"
        Script = "check-client-non-core-scene-identity.ps1"
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
    },
    @{
        Name = "client demo action feedback readability"
        Script = "check-client-demo-action-feedback-readability.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo action blocker recovery"
        Script = "check-client-demo-action-blocker-recovery.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo prototype visual pass"
        Script = "check-client-demo-prototype-visual-pass.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo quick slot supply readability"
        Script = "check-client-demo-quick-slot-supply-readability.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo supply pressure pacing"
        Script = "check-client-demo-supply-pressure-pacing.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo combat readability"
        Script = "check-client-demo-combat-readability.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo core scene playable space"
        Script = "check-client-demo-core-scene-playable-space.ps1"
        Parameters = @{
            RepoRoot = $RepoRoot
        }
    },
    @{
        Name = "client demo industrial module task rhythm"
        Script = "check-client-demo-industrial-module-task-rhythm.ps1"
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
