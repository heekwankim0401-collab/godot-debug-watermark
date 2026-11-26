<#
.SYNOPSIS
Runs the automated tests of the Debug Watermark add-on (Windows, PowerShell 5.1+).

.DESCRIPTION
Copies the project to a work folder, enables the test runner plugin in the copy
(the project folder itself is not changed) and runs these cases:

  default         Runs first, with project.godot as shipped. Game run with
                  the editor binary, default settings: watermark shown, on top
                  of another CanvasLayer and an embedded dialog, clicks pass
                  through.
  editor          Headless editor: turns the add-on off and on, checks the
                  autoload, the project settings and project.godot. Afterwards
                  Godot 4.4+ stores the autoload as "*uid://...".
  custom          Same, with override.cfg changing text, corner, margin, font
                  size, opacity and hide_after_seconds.
  stretch         Same as default, with stretch mode canvas_items / aspect keep
                  (the window is resized to 800x600 at the end, adding bars).
  no_editor_runs  Same, with show_when_run_from_editor = false: no watermark.
  export_debug    Only with -DebugTemplate: debug export (with
                  show_when_run_from_editor = false): watermark shown.
  export_release  Only with -ReleaseTemplate: release export: no watermark.

Game runs open a window for a few seconds. Results and screenshots go to -Out.

.EXAMPLE
.\test\run_tests.ps1 -Godot C:\Godot\Godot_v4.7.2-stable_win64_console.exe

.EXAMPLE
.\test\run_tests.ps1 -Godot C:\Godot\Godot_v4.7.2-stable_win64_console.exe -DebugTemplate C:\t\windows_debug_x86_64.exe -ReleaseTemplate C:\t\windows_release_x86_64.exe
#>
param(
	[Parameter(Mandatory = $true)][string]$Godot,
	[string]$DebugTemplate = "",
	[string]$ReleaseTemplate = "",
	[string]$Out = (Join-Path $env:TEMP "debug_watermark_tests")
)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
$Out = [IO.Path]::GetFullPath($Out)
$work = Join-Path $Out "project"
$shots = Join-Path $Out "screenshots"
$script:failedCases = @()

# Only remove what this script creates inside -Out.
New-Item -ItemType Directory -Force $Out | Out-Null
foreach ($d in @($work, $shots, (Join-Path $Out "export_debug"), (Join-Path $Out "export_release"))) {
	if (Test-Path $d) { Remove-Item -Recurse -Force $d }
}
Get-ChildItem $Out -Filter "results_*.txt" | Remove-Item -Force
New-Item -ItemType Directory -Force $work, $shots | Out-Null

function Write-Utf8NoBom([string]$Path, [string]$Text) {
	[IO.File]::WriteAllText($Path, $Text, (New-Object System.Text.UTF8Encoding($false)))
}

function Show-Result([string]$Case, [string]$File) {
	Write-Host "----- $Case"
	if (-not (Test-Path $File)) {
		Write-Host "FAIL  no results file (the run crashed or did not start)"
		$script:failedCases += $Case
		return
	}
	$text = Get-Content $File -Raw
	Write-Host $text.TrimEnd()
	if ($text -notmatch "RESULT: 0 failure") { $script:failedCases += $Case }
}

# Runs Godot and waits. Godot prints warnings to stderr; with output redirected,
# PowerShell 5.1 turns those into error records, so don't stop on them here.
function Invoke-Godot([string[]]$GodotArgs) {
	$ErrorActionPreference = "Continue"
	& $Godot @GodotArgs
}

function Invoke-Game([string]$Case, [string]$WmCase, [string]$Exe, [string[]]$GodotArgs, [string]$OverrideDir, [string]$Override) {
	$result = Join-Path $Out "results_$Case.txt"
	$ov = Join-Path $OverrideDir "override.cfg"
	if ($Override) { Write-Utf8NoBom $ov $Override } elseif (Test-Path $ov) { Remove-Item $ov }
	$env:WM_OUT = $result
	$env:WM_CASE = $WmCase
	$env:WM_SHOTS = $shots
	$env:WM_RUN = $Case
	try {
		if ($GodotArgs.Count -gt 0) {
			Start-Process -FilePath $Exe -ArgumentList $GodotArgs -Wait -NoNewWindow | Out-Null
		} else {
			Start-Process -FilePath $Exe -Wait -NoNewWindow | Out-Null
		}
	} finally {
		Remove-Item Env:WM_OUT, Env:WM_CASE, Env:WM_SHOTS, Env:WM_RUN -ErrorAction SilentlyContinue
		if ($Override -and (Test-Path $ov)) { Remove-Item $ov }
	}
	Show-Result $Case $result
}

# 1. Copy the project and enable the test runner in the copy.
Copy-Item (Join-Path $repo "project.godot") $work
Copy-Item -Recurse (Join-Path $repo "addons") $work
Copy-Item -Recurse (Join-Path $repo "test") $work
$projectFile = Join-Path $work "project.godot"
$project = [IO.File]::ReadAllText($projectFile)
$enabledLine = 'enabled=PackedStringArray("res://addons/debug_watermark/plugin.cfg")'
if (-not $project.Contains($enabledLine)) { throw "project.godot does not have the expected editor_plugins line" }
$project = $project.Replace($enabledLine, 'enabled=PackedStringArray("res://addons/debug_watermark/plugin.cfg", "res://addons/debug_watermark_test/plugin.cfg")')
Write-Utf8NoBom $projectFile $project
$q = '"' + $work + '"'
$md5BeforeImport = (Get-FileHash -Algorithm MD5 $projectFile).Hash

Write-Host "== import"
Invoke-Godot @("--headless", "--path", $work, "--import")
# Godot 4.2 returns 1 from --import even when the import worked, so only warn;
# the cases below fail if the project really did not import.
if ($LASTEXITCODE -ne 0) { Write-Host "note: --import returned $LASTEXITCODE" }

# 2. Game run with project.godot as shipped (autoload stored as "*res://...").
Write-Host "== game run from the editor binary, project.godot as shipped"
Invoke-Game "default" "default" $Godot @("--path", $q) $work ""

# 3. Editor: toggle the add-on. Godot 4.4+ then stores the autoload as
# "*uid://...", so the runs after this one cover that form.
Write-Host "== editor"
$editorResult = Join-Path $Out "results_editor.txt"
$env:WM_EDITOR_OUT = $editorResult
$env:WM_EDITOR_START_MD5 = $md5BeforeImport
try { Invoke-Godot @("--headless", "-e", "--path", $work) } finally { Remove-Item Env:WM_EDITOR_OUT, Env:WM_EDITOR_START_MD5 -ErrorAction SilentlyContinue }
Show-Result "editor" $editorResult

# 4. More game runs with the editor binary.
Write-Host "== game runs from the editor binary"
$custom = @"
[debug_watermark]

general/text="DBG {project_name} {project_version} {godot_version}"
general/hide_after_seconds=1.0
layout/corner=0
layout/margin=40
style/font_size=32
style/opacity=1.0
"@
Invoke-Game "custom" "custom" $Godot @("--path", $q) $work $custom
$stretch = @"
[display]

window/stretch/mode="canvas_items"
window/stretch/aspect="keep"
"@
Invoke-Game "stretch" "default" $Godot @("--path", $q) $work $stretch
$noEditorRuns = @"
[debug_watermark]

general/show_when_run_from_editor=false
"@
Invoke-Game "no_editor_runs" "hidden" $Godot @("--path", $q) $work $noEditorRuns

# 5. Exports.
if ($DebugTemplate -or $ReleaseTemplate) {
	$dbg = ([IO.Path]::GetFullPath($(if ($DebugTemplate) { $DebugTemplate } else { $ReleaseTemplate }))) -replace '\\', '/'
	$rel = ([IO.Path]::GetFullPath($(if ($ReleaseTemplate) { $ReleaseTemplate } else { $DebugTemplate }))) -replace '\\', '/'
	$preset = @"
[preset.0]

name="Windows Desktop"
platform="Windows Desktop"
runnable=true
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path=""

[preset.0.options]

custom_template/debug="$dbg"
custom_template/release="$rel"
debug/export_console_wrapper=0
binary_format/embed_pck=false
application/modify_resources=false
"@
	Write-Utf8NoBom (Join-Path $work "export_presets.cfg") $preset
	$kinds = @()
	if ($DebugTemplate) { $kinds += "debug" }
	if ($ReleaseTemplate) { $kinds += "release" }
	foreach ($kind in $kinds) {
		Write-Host "== export_$kind"
		$dir = Join-Path $Out "export_$kind"
		New-Item -ItemType Directory -Force $dir | Out-Null
		$exe = Join-Path $dir "debug_watermark_test.exe"
		Invoke-Godot @("--headless", "--path", $work, "--export-$kind", "Windows Desktop", $exe)
		if (-not (Test-Path $exe)) {
			Write-Host "FAIL  export_$kind produced no executable"
			$script:failedCases += "export_$kind"
			continue
		}
		if ($kind -eq "debug") {
			# The editor-runs switch must not hide the watermark in a debug export.
			Invoke-Game "export_debug" "default" $exe @() $dir $noEditorRuns
		} else {
			Invoke-Game "export_release" "hidden" $exe @() $dir ""
		}
	}
} else {
	Write-Host "== exports skipped (pass -DebugTemplate and -ReleaseTemplate to test them)"
}

Write-Host ""
Write-Host "Results and screenshots: $Out"
if ($script:failedCases.Count -gt 0) {
	Write-Host ("FAILED: " + ($script:failedCases -join ", "))
	exit 1
}
Write-Host "ALL PASSED"
