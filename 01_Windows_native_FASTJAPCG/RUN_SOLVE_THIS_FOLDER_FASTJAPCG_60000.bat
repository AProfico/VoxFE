@echo off
setlocal
set "BAT_DIR=%~dp0"
if "%BAT_DIR:~-1%"=="\" set "BAT_DIR=%BAT_DIR:~0,-1%"
set "PYTHON_ROOT=%BAT_DIR%\..\.."
set "PS1=%BAT_DIR%\..\..\solve_this_folder_0_28.ps1"

if not exist "%PS1%" (
    echo Missing companion script:
    echo   %PS1%
    pause
    exit /b 1
)

echo Solving only this model folder:
echo   %BAT_DIR%
echo.
echo Method: FASTJAPCG
echo Backend: sparse_scipy
echo Max iterations: 60000
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -CaseDir "%BAT_DIR%" -PythonRoot "%PYTHON_ROOT%" -ReleaseRoot "%PYTHON_ROOT%" -Method FASTJAPCG -Backend sparse_scipy -MaxIter 60000 -ProgressInterval 50
if errorlevel 1 (
    echo.
    echo Solve failed. See solver_single_60000_stdout.log in this folder.
    pause
    exit /b 1
)

echo.
echo Done.
pause
