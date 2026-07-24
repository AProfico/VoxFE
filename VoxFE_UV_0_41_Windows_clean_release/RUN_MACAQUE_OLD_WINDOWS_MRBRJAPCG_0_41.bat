@echo off
setlocal
cd /d "%~dp0"

set "CASE_DIR=%~dp0models\Macaque_old_model"
set "PY=%~dp0.venv\Scripts\python.exe"
set "SOLVER=%~dp0SOLVER_0_41_mrbrjapcg.pyz"
set "EXPORTER=%~dp0export_loaded_unloaded_coordinates.py"
set "PREPARE=%~dp0prepare_autorun_script.py"
set "METHOD=MRBRJAPCG"
set "BACKEND=sparse_scipy"
if "%MAX_ITER%"=="" set "MAX_ITER=60000"
if "%MIN_ITER%"=="" set "MIN_ITER=1580"
if "%TOLERANCE%"=="" set "TOLERANCE=1e-06"
if "%COMPUTE_SED%"=="" set "COMPUTE_SED=false"
if "%SKIP_NONCONVERGED_OUTPUTS%"=="" set "SKIP_NONCONVERGED_OUTPUTS=0"
set "RUN_SCRIPT=%CASE_DIR%\Script_autorun_windows_MRBRJAPCG_0_41.txt"
set "SUMMARY=%CASE_DIR%\voxfe_solver_summary_windows_MRBRJAPCG_0_41.json"
set "LOG=%CASE_DIR%\solver_windows_MRBRJAPCG_0_41_stdout.log"
set "VALIDATION_LOG=%CASE_DIR%\voxfe_run_validation_log.json"
set "ELAPSED=%CASE_DIR%\windows_MRBRJAPCG_0_41_elapsed_time.txt"

if not exist "%PY%" (
    echo Local Python environment not found:
    echo   %PY%
    echo.
    echo Run INSTALL_OR_UPDATE_DEPENDENCIES.bat first.
    pause
    exit /b 1
)
if not exist "%SOLVER%" (
    echo Solver not found:
    echo   %SOLVER%
    pause
    exit /b 1
)
if not exist "%CASE_DIR%\Script.txt" (
    echo Script.txt not found:
    echo   %CASE_DIR%\Script.txt
    pause
    exit /b 1
)

"%PY%" -u "%PREPARE%" --source "%CASE_DIR%\Script.txt" --target "%RUN_SCRIPT%" --method "%METHOD%" --max-iter "%MAX_ITER%" --min-iter "%MIN_ITER%" --tolerance "%TOLERANCE%" --compute-sed "%COMPUTE_SED%"
if errorlevel 1 (
    echo ERROR: failed to prepare autorun script.
    pause
    exit /b 1
)

echo Solving Macaque old model on Windows with VoxFE 0.41 MRBRJAPCG
echo Case:      %CASE_DIR%
echo Python:    %PY%
echo Solver:    %SOLVER%
echo Method:    %METHOD%
echo Backend:   %BACKEND%
echo MaxIter:   %MAX_ITER%
echo MinIter:   %MIN_ITER%
echo Tolerance: %TOLERANCE%
echo Compute SED: %COMPUTE_SED%
if "%SKIP_NONCONVERGED_OUTPUTS%"=="0" (
    echo Save outputs if not production-valid: yes
) else (
    echo Save outputs if not production-valid: no
)
echo Log:       %LOG%
echo Validation log:
echo   %VALIDATION_LOG%
echo.

for /f %%t in ('powershell -NoProfile -Command "[DateTimeOffset]::Now.ToUnixTimeSeconds()"') do set "START_UNIX=%%t"
echo Started at: %DATE% %TIME%
echo Started at: %DATE% %TIME% > "%ELAPSED%"

cd /d "%CASE_DIR%"
set "VOXFE_SKIP_NONCONVERGED_OUTPUTS=%SKIP_NONCONVERGED_OUTPUTS%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { & '%PY%' -u '%SOLVER%' 'Script_autorun_windows_MRBRJAPCG_0_41.txt' --backend '%BACKEND%' --algorithm '%METHOD%' --threads auto --summary '%SUMMARY%' --progress-interval 50 --min-iter '%MIN_ITER%' 2>&1 | Tee-Object -FilePath '%LOG%'; exit $LASTEXITCODE }"
set "SOLVE_EXIT=%ERRORLEVEL%"

if "%SOLVE_EXIT%"=="0" if exist "%EXPORTER%" if exist "%CASE_DIR%\displacement.txt" (
    echo.
    echo Exporting loaded/unloaded coordinates...
    "%PY%" -u "%EXPORTER%" --case-dir "%CASE_DIR%" --script "%RUN_SCRIPT%" --summary "%CASE_DIR%\coordinate_export_summary_windows_MRBRJAPCG_0_41.json" >> "%LOG%" 2>&1
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
pause
exit /b %SOLVE_EXIT%
