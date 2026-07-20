param(
    [switch]$NoDesktop
)

$ErrorActionPreference = "Stop"
$AppDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LauncherBat = Join-Path $AppDir "LAUNCH_VoxFE_UV_0_30_WINDOWS.bat"
$AppPyz = Join-Path $AppDir "VoxFE_UV_0_30_petsc_fastjapcg.pyz"
$CompatPyz = Join-Path $AppDir "VoxFE_UV_0_27_fast.pyz"

if (-not (Test-Path -LiteralPath $LauncherBat)) {
    throw "Launcher not found: $LauncherBat"
}
if (-not (Test-Path -LiteralPath $AppPyz) -and -not (Test-Path -LiteralPath $CompatPyz)) {
    throw "Viewer app not found in: $AppDir"
}

$StartMenuDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\VoxFE-UV"
$DesktopDir = [Environment]::GetFolderPath("Desktop")
$CommandDir = Join-Path $env:LOCALAPPDATA "VoxFE-UV\bin"
$IconPath = Join-Path $AppDir "voxfe_uv_icon.ico"
New-Item -ItemType Directory -Force -Path $StartMenuDir, $CommandDir | Out-Null

$CommandPath = Join-Path $CommandDir "voxfe-uv.cmd"
@"
@echo off
call "$LauncherBat" %*
"@ | Set-Content -LiteralPath $CommandPath -Encoding ASCII

function New-VoxFEShortcut {
    param(
        [Parameter(Mandatory=$true)][string]$Path
    )
    $Shell = New-Object -ComObject WScript.Shell
    $Shortcut = $Shell.CreateShortcut($Path)
    $Shortcut.TargetPath = $LauncherBat
    $Shortcut.WorkingDirectory = $AppDir
    $Shortcut.Description = "VoxFE-UV voxel finite-element viewer and solver"
    if (Test-Path -LiteralPath $IconPath) {
        $Shortcut.IconLocation = $IconPath
    } elseif (Test-Path -LiteralPath $AppPyz) {
        $Shortcut.IconLocation = $AppPyz
    }
    $Shortcut.Save()
}

$StartShortcut = Join-Path $StartMenuDir "VoxFE-UV.lnk"
New-VoxFEShortcut -Path $StartShortcut

if (-not $NoDesktop) {
    $DesktopShortcut = Join-Path $DesktopDir "VoxFE-UV.lnk"
    New-VoxFEShortcut -Path $DesktopShortcut
}

$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (($UserPath -split ";") -notcontains $CommandDir) {
    $NewPath = if ([string]::IsNullOrWhiteSpace($UserPath)) { $CommandDir } else { "$UserPath;$CommandDir" }
    [Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
}

Write-Host "VoxFE-UV installed for this Windows user."
Write-Host "Start Menu: $StartShortcut"
if (-not $NoDesktop) {
    Write-Host "Desktop:    $DesktopShortcut"
}
Write-Host "Command:    $CommandPath"
Write-Host ""
Write-Host "If 'voxfe-uv' is not found in an already-open terminal, open a new terminal."
