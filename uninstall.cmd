@echo off
setlocal enableextensions enabledelayedexpansion

set "INSTALL_DIR=%LOCALAPPDATA%\joblist"

rem --- Remove wrapper directory ---------------------------------------------
if exist "%INSTALL_DIR%" (
    echo Removing "%INSTALL_DIR%"
    rmdir /s /q "%INSTALL_DIR%"
    if exist "%INSTALL_DIR%" (
        echo ERROR: Could not remove "%INSTALL_DIR%". Close any running joblist processes and retry.
        exit /b 1
    )
) else (
    echo "%INSTALL_DIR%" not found, nothing to delete.
)

rem --- Strip INSTALL_DIR from the user PATH ---------------------------------
set "USER_PATH="
for /f "skip=2 tokens=2,*" %%A in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "USER_PATH=%%B"

if not defined USER_PATH (
    echo User PATH empty or unreadable, nothing to strip.
    endlocal
    exit /b 0
)

set "USER_PATH_VAR=!USER_PATH!"
set "INSTALL_DIR_VAR=%INSTALL_DIR%"

for /f "delims=" %%P in ('powershell -NoProfile -Command "(($env:USER_PATH_VAR -split ';') ^| Where-Object { $_ -and ($_ -ne $env:INSTALL_DIR_VAR) }) -join ';'"') do set "NEW_PATH=%%P"

if "!NEW_PATH!"=="!USER_PATH!" (
    echo "%INSTALL_DIR%" was not on user PATH.
) else (
    setx PATH "!NEW_PATH!" >nul
    echo Removed "%INSTALL_DIR%" from user PATH. Open a NEW terminal for it to take effect.
)

echo.
echo Uninstalled. The 'joblist' command will be gone in new terminals.
endlocal
