@echo off
setlocal enableextensions enabledelayedexpansion

set "APP_ROOT=%~dp0"
if "%APP_ROOT:~-1%"=="\" set "APP_ROOT=%APP_ROOT:~0,-1%"
set "APP_SOURCE=%APP_ROOT%\src\main\java\App.java"

if not exist "%APP_SOURCE%" (
    echo ERROR: App.java not found at "%APP_SOURCE%"
    exit /b 1
)

where java25 >nul 2>&1
if errorlevel 1 (
    echo ERROR: 'java25' not on PATH.
    echo Run https://github.com/oliverkotzina/windows-java25-installer first.
    exit /b 1
)

for /f "tokens=2 delims= " %%V in ('java25 -version 2^>^&1 ^| findstr /i "version"') do set "JAVA_VERSION=%%~V"
echo Using java25 !JAVA_VERSION!

set "INSTALL_DIR=%LOCALAPPDATA%\joblist"
set "WRAPPER=%INSTALL_DIR%\joblist.cmd"

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

(
    echo @echo off
    echo java25 "!APP_SOURCE!" %%*
) > "%WRAPPER%"

echo Wrote "%WRAPPER%"

set "USER_PATH="
for /f "skip=2 tokens=2,*" %%A in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "USER_PATH=%%B"

echo !USER_PATH! | find /I "%INSTALL_DIR%" >nul
if errorlevel 1 (
    if defined USER_PATH (
        setx PATH "!USER_PATH!;%INSTALL_DIR%" >nul
    ) else (
        setx PATH "%INSTALL_DIR%" >nul
    )
    echo Added "%INSTALL_DIR%" to user PATH. Open a NEW terminal for it to take effect.
) else (
    echo "%INSTALL_DIR%" already on user PATH.
)

echo.
echo Done. Usage from any terminal:
echo   cd C:\path\with\hop-files
echo   joblist
endlocal
