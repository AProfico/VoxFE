@echo off
setlocal
cd /d "%~dp0"

echo VoxFE-UV 0.41 dependency setup
echo.

set "MIN_PYTHON=3.10"
set "WINGET_PYTHON_ID=Python.Python.3.12"
set "REQUIREMENTS_FILE="
set "PYTHON_EXE="
set "PYTHON_ARGS="

if exist "%~dp0requirements.txt" set "REQUIREMENTS_FILE=%~dp0requirements.txt"
if not defined REQUIREMENTS_FILE if exist "%~dp0..\requirements.txt" set "REQUIREMENTS_FILE=%~dp0..\requirements.txt"
if not defined REQUIREMENTS_FILE if exist "%~dp0..\..\requirements.txt" set "REQUIREMENTS_FILE=%~dp0..\..\requirements.txt"
if not defined REQUIREMENTS_FILE if exist "%~dp0..\..\..\requirements.txt" set "REQUIREMENTS_FILE=%~dp0..\..\..\requirements.txt"

if not defined REQUIREMENTS_FILE (
    echo ERROR: requirements.txt was not found near this installer.
    echo Move this file back into the VoxFE-UV package or run the root installer.
    pause
    exit /b 1
)

call :FindPython

if not defined PYTHON_EXE (
    echo Python %MIN_PYTHON% or newer was not found.
    echo.
    echo Installing Python 3.12 for the current user with winget...
    call :InstallPython
    if errorlevel 1 (
        echo.
        echo ERROR: Automatic Python installation failed.
        echo Install Python %MIN_PYTHON% or newer from:
        echo https://www.python.org/downloads/windows/
        echo.
        echo During installation, enable "Add python.exe to PATH".
        start "" "https://www.python.org/downloads/windows/"
        pause
        exit /b 1
    )
    call :FindPython
)

if not defined PYTHON_EXE (
    echo ERROR: Python was installed, but this script could not find it.
    echo Close this window and run INSTALL_OR_UPDATE_DEPENDENCIES.bat again.
    pause
    exit /b 1
)

echo Using Python command:
echo     "%PYTHON_EXE%" %PYTHON_ARGS%
call :RunPython --version
if errorlevel 1 (
    echo ERROR: Python exists but could not run.
    pause
    exit /b 1
)

call :RunPython -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)" >nul 2>nul
if errorlevel 1 (
    echo ERROR: Python %MIN_PYTHON% or newer is required.
    pause
    exit /b 1
)

echo.
echo Using requirements file:
echo     %REQUIREMENTS_FILE%

echo.
echo Creating/updating local environment: .venv
call :RunPython -m venv .venv
if errorlevel 1 (
    echo ERROR: Could not create .venv. Check that your Python installation includes venv.
    pause
    exit /b 1
)

if not exist ".venv\Scripts\python.exe" (
    echo ERROR: .venv was created, but .venv\Scripts\python.exe was not found.
    pause
    exit /b 1
)

echo.
echo Installing Python packages...
".venv\Scripts\python.exe" -m pip install --upgrade pip
if errorlevel 1 (
    echo ERROR: Could not upgrade pip.
    pause
    exit /b 1
)

".venv\Scripts\python.exe" -m pip install --upgrade --prefer-binary -r "%REQUIREMENTS_FILE%"
if errorlevel 1 (
    echo ERROR: Dependency installation failed.
    echo Check your internet connection, then run this file again.
    pause
    exit /b 1
)

echo.
echo Checking installed packages...
".venv\Scripts\python.exe" -c "import tkinter; import numpy, scipy, pyamg, numba, pyvista, vtk, PIL, imageio; print('Dependencies OK')"
if errorlevel 1 (
    echo ERROR: One or more dependencies are still missing.
    echo NumPy/SciPy/PyAMG/Numba are installed by requirements.txt; check the pip output above for the failed package.
    pause
    exit /b 1
)

echo.
echo Setup complete. You can now run LAUNCH_VoxFE_UV_0_41_WINDOWS.bat
pause
exit /b 0

:FindPython
set "PYTHON_EXE="
set "PYTHON_ARGS="

where py >nul 2>nul
if not errorlevel 1 (
    py -3.12 -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)" >nul 2>nul
    if not errorlevel 1 (
        set "PYTHON_EXE=py"
        set "PYTHON_ARGS=-3.12"
        exit /b 0
    )

    py -3 -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)" >nul 2>nul
    if not errorlevel 1 (
        set "PYTHON_EXE=py"
        set "PYTHON_ARGS=-3"
        exit /b 0
    )
)

where python >nul 2>nul
if not errorlevel 1 (
    python -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)" >nul 2>nul
    if not errorlevel 1 (
        set "PYTHON_EXE=python"
        exit /b 0
    )
)

for %%P in (
    "%LocalAppData%\Programs\Python\Python312\python.exe"
    "%ProgramFiles%\Python312\python.exe"
    "%LocalAppData%\Programs\Python\Python313\python.exe"
    "%ProgramFiles%\Python313\python.exe"
    "%LocalAppData%\Programs\Python\Python314\python.exe"
    "%ProgramFiles%\Python314\python.exe"
    "%LocalAppData%\Programs\Python\Python311\python.exe"
    "%ProgramFiles%\Python311\python.exe"
    "%LocalAppData%\Programs\Python\Python310\python.exe"
    "%ProgramFiles%\Python310\python.exe"
) do (
    if exist "%%~P" (
        "%%~P" -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)" >nul 2>nul
        if not errorlevel 1 (
            set "PYTHON_EXE=%%~P"
            exit /b 0
        )
    )
)

exit /b 0

:InstallPython
where winget >nul 2>nul
if errorlevel 1 (
    echo ERROR: winget was not found, so Python cannot be installed automatically.
    echo.
    exit /b 1
)

winget install --id %WINGET_PYTHON_ID% -e --source winget --scope user --accept-package-agreements --accept-source-agreements
if errorlevel 1 (
    echo User-scope winget installation failed. Retrying with winget default scope...
    winget install --id %WINGET_PYTHON_ID% -e --source winget --accept-package-agreements --accept-source-agreements
)
exit /b %errorlevel%

:RunPython
if defined PYTHON_ARGS (
    "%PYTHON_EXE%" %PYTHON_ARGS% %*
) else (
    "%PYTHON_EXE%" %*
)
exit /b %errorlevel%
