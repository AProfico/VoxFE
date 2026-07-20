$ErrorActionPreference = "Stop"

$StartMenuDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\VoxFE-UV"
$DesktopShortcut = Join-Path ([Environment]::GetFolderPath("Desktop")) "VoxFE-UV.lnk"
$CommandDir = Join-Path $env:LOCALAPPDATA "VoxFE-UV\bin"
$CommandPath = Join-Path $CommandDir "voxfe-uv.cmd"

Remove-Item -LiteralPath $DesktopShortcut -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $StartMenuDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $CommandPath -Force -ErrorAction SilentlyContinue

$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($UserPath) {
    $Parts = @($UserPath -split ";" | Where-Object { $_ -and ($_ -ne $CommandDir) })
    [Environment]::SetEnvironmentVariable("Path", ($Parts -join ";"), "User")
}

Write-Host "VoxFE-UV Windows shortcuts removed. The release folder was not deleted."
