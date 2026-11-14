[CmdletBinding()]
param(
    [ValidateSet('state','window','storage-state','storage-window','timed-state','timed-window','feedback-state','feedback-window','load-state','load-window','play')]
    [string]$Mode = 'state',
    [string]$Batch = ("$Mode-" + [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()),
    [string]$GodotExe = ''
)
$ErrorActionPreference = 'Stop'
if ($Batch -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Invalid batch name.' }
$repoRoot = Split-Path $PSScriptRoot -Parent
. (Join-Path $repoRoot 'scripts/Resolve-GodotExe.ps1')
$godotBin = Resolve-GodotExe -GodotExe $GodotExe
$parent = if ($Mode -eq 'play') { 'review-worlds' } else { 'check-runs' }
$runRoot = Join-Path $repoRoot "tools/runtime-intake/$parent/factory-grid-controls-v1/$Batch"
if ($Mode -ne 'play' -and (Test-Path $runRoot)) { throw 'Use a new batch; existing evidence is retained.' }
New-Item -ItemType Directory -Path $runRoot -Force | Out-Null
if ($Mode -ne 'play') {
    $pythonExe = if ($env:PYTHON) { $env:PYTHON } else { 'python' }
    $auditScript = Join-Path $repoRoot 'tools/design/audit-four-sided-core-layout.py'
    $layout = & $pythonExe -c 'import json,runpy,sys; print(json.dumps(runpy.run_path(sys.argv[1])["audit"]("S1-P")))' $auditScript
    if ($LASTEXITCODE -ne 0) { throw 'Layout audit failed.' }
    [System.IO.File]::WriteAllText((Join-Path $runRoot 'layout.json'), ($layout -join "`n"), [System.Text.UTF8Encoding]::new($false))
}
function Invoke-GridStage([string]$Stage, [string[]]$GodotArgs) {
    $consoleLog = Join-Path $runRoot "$Stage-console.log"
    & $godotBin --path (Join-Path $repoRoot 'client') --log-file (Join-Path $runRoot "$Stage.log") @GodotArgs *> $consoleLog
    $exitCode = $LASTEXITCODE
    Get-Content $consoleLog -Tail 35
    if ($exitCode -ne 0 -or (Select-String -Path $consoleLog,(Join-Path $runRoot "$Stage.log") -Pattern '^(SCRIPT ERROR|ERROR:)' -Quiet)) {
        throw "Grid controls $Stage failed; evidence retained."
    }
}
$engineArgs = @()
if ($Mode.EndsWith('state')) { $engineArgs += @('--headless','--quit-after','1200') }
$engineArgs += @('--script','res://scripts/checks/factory_grid_controls_check.gd','--',"--batch=$Batch")
switch -Regex ($Mode) {
    '^storage-' { $engineArgs += '--storage' }
    '^timed-' { $engineArgs += '--timed' }
    '^feedback-' { $engineArgs += '--feedback' }
    '^load-' { $engineArgs += '--loads' }
}
if ($Mode -eq 'play') {
    Invoke-GridStage ("play-" + [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()) ($engineArgs + '--play')
} else {
    Invoke-GridStage 'write' $engineArgs
    if (-not (Test-Path (Join-Path $runRoot 'expected.json'))) { throw 'Missing write evidence; read was not started.' }
    Invoke-GridStage 'read' ($engineArgs + '--read')
    if (-not (Test-Path (Join-Path $runRoot 'restore.json'))) { throw 'Missing restore evidence.' }
}
