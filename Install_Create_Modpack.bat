@echo off
setlocal EnableExtensions EnableDelayedExpansion

title Create Modpack Installer
echo.
echo ============================================
echo   Create Modpack Installer for Windows
echo ============================================
echo.
echo This script will copy the modpack files from:
echo   %~dp0
echo into a Minecraft installation folder.
echo.
echo Mods will be copied into:
echo   ^<minecraft^>\mods
echo Shaderpacks will be copied into:
echo   ^<minecraft^>\shaderpacks
echo.

set "DEFAULT_MC=%APPDATA%\.minecraft"
set "MC_DIR="
set /p "MC_DIR=Minecraft folder [%DEFAULT_MC%]: "
if not defined MC_DIR set "MC_DIR=%DEFAULT_MC%"

if not exist "%MC_DIR%" (
    echo.
    echo Creating target folder...
    mkdir "%MC_DIR%" >nul 2>nul
    if errorlevel 1 (
        echo Failed to create "%MC_DIR%".
        exit /b 1
    )
)

set "MODS_DIR=%MC_DIR%\mods"
set "SHADERPACKS_DIR=%MC_DIR%\shaderpacks"

if not exist "%MODS_DIR%" mkdir "%MODS_DIR%" >nul 2>nul
if not exist "%SHADERPACKS_DIR%" mkdir "%SHADERPACKS_DIR%" >nul 2>nul

echo.
echo Installing mod files...
set "COPIED_MODS=0"

for /r "%~dp0" %%F in (*.jar) do (
    copy /y "%%~fF" "%MODS_DIR%\%%~nxF" >nul
    if not errorlevel 1 set /a COPIED_MODS+=1
)

echo Installing shaderpacks...
set "COPIED_SHADERPACKS=0"

if exist "%~dp0shaderpacks\" (
    for /r "%~dp0shaderpacks" %%F in (*) do (
        copy /y "%%~fF" "%SHADERPACKS_DIR%\%%~nxF" >nul
        if not errorlevel 1 set /a COPIED_SHADERPACKS+=1
    )
)

echo.
echo Done.
echo   Copied !COPIED_MODS! mod file(s)
echo   Copied !COPIED_SHADERPACKS! shaderpack file(s)
echo.
echo Launch Minecraft through your normal launcher after selecting this instance or folder.
echo.
pause
