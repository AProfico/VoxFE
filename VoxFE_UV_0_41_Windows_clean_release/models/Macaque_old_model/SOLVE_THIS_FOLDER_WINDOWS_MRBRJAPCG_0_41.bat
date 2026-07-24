@echo off
setlocal

rem Put this BAT inside the model folder that contains Script.txt.
rem Optional overrides before launch:
rem   set MAX_ITER=60000
rem   set MIN_ITER=1580
rem   set TOLERANCE=1e-06
rem   set COMPUTE_SED=false
rem   set VOXFE_RELEASE_DIR=C:\path\to\01_Windows_VoxFE_UV_0_41

set "CASE_DIR=%~dp0"
cd /d "%CASE_DIR%"

set "RELEASE_DIR="
if not "%VOXFE_RELEASE_DIR%"=="" if exist "%VOXFE_RELEASE_DIR%\SOLVER_0_41_mrbrjapcg.pyz" set "RELEASE_DIR=%VOXFE_RELEASE_DIR%"
if "%RELEASE_DIR%"=="" if exist "%CASE_DIR%SOLVER_0_41_mrbrjapcg.pyz" set "RELEASE_DIR=%CASE_DIR%"
if "%RELEASE_DIR%"=="" if exist "%CASE_DIR%..\SOLVER_0_41_mrbrjapcg.pyz" set "RELEASE_DIR=%CASE_DIR%.."
if "%RELEASE_DIR%"=="" if exist "%CASE_DIR%..\..\SOLVER_0_41_mrbrjapcg.pyz" set "RELEASE_DIR=%CASE_DIR%..\.."
if "%RELEASE_DIR%"=="" if exist "%CASE_DIR%..\..\..\SOLVER_0_41_mrbrjapcg.pyz" set "RELEASE_DIR=%CASE_DIR%..\..\.."

if "%RELEASE_DIR%"=="" (
    echo Could not find VoxFE Windows 0.41 release folder.
    echo.
    echo Fix option 1:
    echo   Put this BAT inside a model folder under 01_Windows_VoxFE_UV_0_41\models
    echo.
    echo Fix option 2:
    echo   set VOXFE_RELEASE_DIR=C:\path\to\01_Windows_VoxFE_UV_0_41
    echo   then run this BAT again.
    pause
    exit /b 1
)

for %%I in ("%RELEASE_DIR%") do set "RELEASE_DIR=%%~fI"

set "PY=%RELEASE_DIR%\.venv\Scripts\python.exe"
set "SOLVER=%RELEASE_DIR%\SOLVER_0_41_mrbrjapcg.pyz"
set "EXPORTER=%RELEASE_DIR%\export_loaded_unloaded_coordinates.py"
set "PREPARE=%RELEASE_DIR%\prepare_autorun_script.py"
set "METHOD=MRBRJAPCG"
set "BACKEND=sparse_scipy"

if "%MAX_ITER%"=="" set "MAX_ITER=60000"
if "%MIN_ITER%"=="" set "MIN_ITER="
if "%TOLERANCE%"=="" set "TOLERANCE=1e-06"
if "%COMPUTE_SED%"=="" set "COMPUTE_SED=false"
if "%SKIP_NONCONVERGED_OUTPUTS%"=="" set "SKIP_NONCONVERGED_OUTPUTS=0"

set "RUN_SCRIPT=%CASE_DIR%Script_autorun_windows_MRBRJAPCG_0_41.txt"
set "SUMMARY=%CASE_DIR%voxfe_solver_summary_windows_MRBRJAPCG_0_41.json"
set "LOG=%CASE_DIR%solver_windows_MRBRJAPCG_0_41_stdout.log"
set "VALIDATION_LOG=%CASE_DIR%voxfe_run_validation_log.json"
set "ELAPSED=%CASE_DIR%windows_MRBRJAPCG_0_41_elapsed_time.txt"

if not exist "%PY%" (
    echo Local Python environment not found:
    echo   %PY%
    echo.
    echo Run this first:
    echo   %RELEASE_DIR%\INSTALL_OR_UPDATE_DEPENDENCIES.bat
    pause
    exit /b 1
)
if not exist "%SOLVER%" (
    echo Solver not found:
    echo   %SOLVER%
    pause
    exit /b 1
)
if not exist "%PREPARE%" (
    echo Autorun script preparer not found:
    echo   %PREPARE%
    pause
    exit /b 1
)
if not exist "%CASE_DIR%Script.txt" (
    echo Script.txt not found in this folder:
    echo   %CASE_DIR%
    echo.
    echo Put this BAT in the folder containing Script.txt.
    pause
    exit /b 1
)

if "%MIN_ITER%"=="" (
    "%PY%" -u "%PREPARE%" --source "%CASE_DIR%Script.txt" --target "%RUN_SCRIPT%" --method "%METHOD%" --max-iter "%MAX_ITER%" --tolerance "%TOLERANCE%" --compute-sed "%COMPUTE_SED%"
) else (
    "%PY%" -u "%PREPARE%" --source "%CASE_DIR%Script.txt" --target "%RUN_SCRIPT%" --method "%METHOD%" --max-iter "%MAX_ITER%" --min-iter "%MIN_ITER%" --tolerance "%TOLERANCE%" --compute-sed "%COMPUTE_SED%"
)
if errorlevel 1 (
    echo ERROR: failed to prepare autorun script.
    pause
    exit /b 1
)

echo Solving only the folder containing this BAT:
echo   %CASE_DIR%
echo.
echo VoxFE release:
echo   %RELEASE_DIR%
echo Python:
echo   %PY%
echo Solver:
echo   %SOLVER%
echo Method:    %METHOD%
echo Backend:   %BACKEND%
echo MaxIter:   %MAX_ITER%
if "%MIN_ITER%"=="" (
    echo MinIter:   empty
) else (
    echo MinIter:   %MIN_ITER%
)
echo Tolerance: %TOLERANCE%
echo Compute SED: %COMPUTE_SED%
echo Live output: enabled
echo Log:
echo   %LOG%
echo Validation log:
echo   %VALIDATION_LOG%
echo.

for /f %%t in ('powershell -NoProfile -Command "[DateTimeOffset]::Now.ToUnixTimeSeconds()"') do set "START_UNIX=%%t"
echo Started at: %DATE% %TIME%
echo Started at: %DATE% %TIME% > "%ELAPSED%"

set "VOXFE_SKIP_NONCONVERGED_OUTPUTS=%SKIP_NONCONVERGED_OUTPUTS%"
if "%MIN_ITER%"=="" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "& { & '%PY%' -u '%SOLVER%' 'Script_autorun_windows_MRBRJAPCG_0_41.txt' --backend '%BACKEND%' --algorithm '%METHOD%' --threads auto --summary '%SUMMARY%' --progress-interval 50 2>&1 | Tee-Object -FilePath '%LOG%'; exit $LASTEXITCODE }"
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "& { & '%PY%' -u '%SOLVER%' 'Script_autorun_windows_MRBRJAPCG_0_41.txt' --backend '%BACKEND%' --algorithm '%METHOD%' --threads auto --summary '%SUMMARY%' --progress-interval 50 --min-iter '%MIN_ITER%' 2>&1 | Tee-Object -FilePath '%LOG%'; exit $LASTEXITCODE }"
)
set "SOLVE_EXIT=%ERRORLEVEL%"

if "%SOLVE_EXIT%"=="0" if exist "%EXPORTER%" if exist "%CASE_DIR%displacement.txt" (
    echo.
    echo Exporting loaded/unloaded coordinates...
    "%PY%" -u "%EXPORTER%" --case-dir "%CASE_DIR%" --script "%RUN_SCRIPT%" --summary "%CASE_DIR%coordinate_export_summary_windows_MRBRJAPCG_0_41.json" >> "%LOG%" 2>&1
)

for /f %%t in ('powershell -NoProfile -Command "[DateTimeOffset]::Now.ToUnixTimeSeconds()"') do set "END_UNIX=%%t"
set /a ELAPSED_SECONDS=%END_UNIX%-%START_UNIX%
echo.
echo Finished at: %DATE% %TIME%
echo Elapsed seconds: %ELAPSED_SECONDS%
echo Finished at: %DATE% %TIME%>> "%ELAPSED%"
echo Elapsed seconds: %ELAPSED_SECONDS%>> "%ELAPSED%"
echo Exit code: %SOLVE_EXIT%>> "%ELAPSED%"

echo.
echo Exit code: %SOLVE_EXIT%
echo Log:
echo   %LOG%
echo Summary:
echo   %SUMMARY%
echo Validation log:
echo   %VALIDATION_LOG%
echo Elapsed time:
echo   %ELAPSED%
pause
exit /b %SOLVE_EXIT%
