@echo off
setlocal
set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "PY=%ROOT%\.venv\Scripts\python.exe"
set "APP=%ROOT%\VoxFE_UV_0_41.pyz"

if not exist "%PY%" (
    echo Python environment not found:
    echo   %PY%
    echo.
    echo Running INSTALL_OR_UPDATE_DEPENDENCIES.bat now...
    call "%ROOT%\INSTALL_OR_UPDATE_DEPENDENCIES.bat"
    if errorlevel 1 (
        echo.
        echo Dependency setup failed. Run INSTALL_OR_UPDATE_DEPENDENCIES.bat manually and check the messages above.
        pause
        exit /b 1
    )
)
if not exist "%APP%" (
    echo App not found:
    echo   %APP%
    pause
    exit /b 1
)

"%PY%" "%APP%"
if errorlevel 1 pause
