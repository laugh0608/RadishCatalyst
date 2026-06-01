function Resolve-GodotExe {
    param(
        [string]$GodotExe
    )

    $candidates = [System.Collections.Generic.List[string]]::new()
    if (-not [string]::IsNullOrWhiteSpace($GodotExe)) {
        $candidates.Add($GodotExe)
    }

    $envGodotExe = [Environment]::GetEnvironmentVariable("GODOT_EXE")
    if (-not [string]::IsNullOrWhiteSpace($envGodotExe)) {
        $candidates.Add($envGodotExe)
    }

    foreach ($commandName in @("godot", "godot4")) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($null -ne $command -and -not [string]::IsNullOrWhiteSpace($command.Source)) {
            $candidates.Add($command.Source)
        }
    }

    $candidates.Add("/Applications/Godot.app/Contents/MacOS/Godot")
    $candidates.Add("D:\Program Files\Godot\Godot_v4.6.2-stable_win64_console.exe")

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    Write-Error "Godot executable not found. Set -GodotExe or GODOT_EXE, or install Godot as godot/godot4 or /Applications/Godot.app."
    exit 1
}
