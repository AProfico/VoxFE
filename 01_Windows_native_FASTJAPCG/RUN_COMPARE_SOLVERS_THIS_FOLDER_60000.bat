@echo off
setlocal
set "BAT_DIR=%~dp0"
if "%BAT_DIR:~-1%"=="\" set "BAT_DIR=%BAT_DIR:~0,-1%"
set "RELEASE_ROOT=%BAT_DIR%\..\.."
set "PYTHON_ROOT=%RELEASE_ROOT%"
set "BENCH=%RELEASE_ROOT%\compare_solvers_this_folder_0_28.py"

echo Comparing all available solvers in this folder only:
echo   %BAT_DIR%
echo.
echo Methods:
echo   SPSOLVE, FASTJAPCG, CG, JAPCG, AMGCG, FASTMG, ROWCG, ROWJAPCG, ROWAMG, MATRIXFREE
echo.
echo Max iterations: 60000
echo Real-time output: enabled
echo.

"%PYTHON_ROOT%\.venv\Scripts\python.exe" -u "%BENCH%" --case-dir "%BAT_DIR%" --python-root "%PYTHON_ROOT%" --release-root "%RELEASE_ROOT%" --max-iter 60000
if errorlevel 1 (
    echo.
    echo Comparison failed. See solver_comparison_runs\METHOD\solver_compare_stdout.log files.
    pause
    exit /b 1
)

echo.
echo Comparison completed.
echo Results: solver_comparison.csv
pause
