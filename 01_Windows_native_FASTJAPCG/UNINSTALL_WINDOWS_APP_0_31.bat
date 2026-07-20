@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall_windows_app_0_31.ps1"
echo.
pause
