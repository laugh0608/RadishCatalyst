[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/features/demo-playable-ui-and-art-pass-v1.md" = @(
        "启动界面与基地首屏第一印象",
        "新游戏",
        "载入存档",
        "联机（暂不开放）",
        "不开发真实联机"
    )
    "client/scenes/boot/Boot.tscn" = @(
        "res://scripts/boot/boot.gd"
    )
    "client/scripts/boot/boot.gd" = @(
        "STARTUP_MENU_SCENE",
        "StartupMenu",
        "SaveService.DEFAULT_SLOT_ID"
    )
    "client/scenes/ui/StartupMenu.tscn" = @(
        "StartupMenu",
        "新游戏",
        "载入存档",
        "联机（暂不开放）",
        "设置",
        "退出"
    )
    "client/scripts/ui/startup_menu.gd" = @(
        "class_name StartupMenu",
        "draw_rect",
        "draw_line",
        "configure_save_summary",
        "multiplayer_button.disabled = true"
    )
    "client/scripts/game/game_root.gd" = @(
        "startup_load_slot_id",
        "_load_from_slot(startup_load_slot_id)"
    )
    "client/scripts/checks/demo_startup_shell_check.gd" = @(
        "Demo startup shell checks passed.",
        "_check_startup_menu_structure",
        "_check_startup_menu_save_state",
        "_check_boot_starts_on_menu"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-startup-shell.py",
        "demo_startup_shell_check.gd"
    )
    "scripts/check-client.ps1" = @(
        "check-client-demo-startup-shell.ps1"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_startup_shell_check.gd"
    )
}

$errors = [System.Collections.Generic.List[string]]::new()

foreach ($relativePath in $requiredTextByFile.Keys) {
    $path = Join-Path $RepoRoot $relativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $errors.Add("${relativePath}: missing file")
        continue
    }

    $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    foreach ($requiredText in $requiredTextByFile[$relativePath]) {
        if (-not $content.Contains($requiredText)) {
            $errors.Add("${relativePath}: missing demo startup shell text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo startup shell checks passed."
