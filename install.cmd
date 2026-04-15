@echo off
setlocal enableextensions enabledelayedexpansion

set "APP_ROOT=%~dp0"
if "%APP_ROOT:~-1%"=="\" set "APP_ROOT=%APP_ROOT:~0,-1%"
set "APP_SOURCE=%APP_ROOT%\src\main\java\App.java"
set "INSTALL_DIR=%LOCALAPPDATA%\joblist"
set "WRAPPER=%INSTALL_DIR%\joblist.cmd"
set "JAVA_INSTALLER_URL=https://raw.githubusercontent.com/oliverkotzina/windows-java25-installer/main/install-java25.cmd"

if not exist "%APP_SOURCE%" (
    echo ERROR: App.java not found at "%APP_SOURCE%"
    exit /b 1
)

rem --- Prerequisite: java25 on PATH -----------------------------------------
where java25 >nul 2>&1
if errorlevel 1 (
    echo.
    echo java25 is not on PATH.
    choice /c YN /n /m "Install Java 25 via windows-java25-installer now? [Y/N] "
    if errorlevel 2 (
        echo Aborted. Run %JAVA_INSTALLER_URL% first, then re-run install.cmd.
        exit /b 1
    )
    set "JAVA_INSTALLER=%TEMP%\install-java25.cmd"
    echo Downloading install-java25.cmd ...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri '%JAVA_INSTALLER_URL%' -OutFile '!JAVA_INSTALLER!' -UseBasicParsing } catch { Write-Error $_; exit 1 }"
    if errorlevel 1 (
        echo ERROR: Download of install-java25.cmd failed.
        exit /b 1
    )
    call "!JAVA_INSTALLER!"
    if errorlevel 1 (
        echo ERROR: Java 25 installation failed.
        exit /b 1
    )
    echo.
    echo Java 25 installed. Open a NEW terminal and re-run install.cmd to finish installing the joblist command.
    exit /b 0
)

for /f "tokens=2 delims= " %%V in ('java25 -version 2^>^&1 ^| findstr /i "version"') do set "JAVA_VERSION=%%~V"
echo Using java25 !JAVA_VERSION!

rem --- Clean previous install so every run starts fresh ---------------------
if exist "%INSTALL_DIR%" (
    echo Cleaning previous install at "%INSTALL_DIR%"
    rmdir /s /q "%INSTALL_DIR%"
    if exist "%INSTALL_DIR%" (
        echo ERROR: Could not remove "%INSTALL_DIR%". Close any running joblist processes and retry.
        exit /b 1
    )
)
mkdir "%INSTALL_DIR%"

(
    echo @echo off
    echo java25 "!APP_SOURCE!" %%*
) > "%WRAPPER%"

echo Wrote "%WRAPPER%"

rem --- Ensure INSTALL_DIR is on the user PATH -------------------------------
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
