@echo off
setlocal
title BLACK TIDE - Automatische installatie
cd /d "%~dp0"
if not exist "%~dp0INSTALLER.ps1" (
  echo FOUT: INSTALLER.ps1 ontbreekt. Download de volledige nieuwste ZIP.
  pause
  exit /b 1
)
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALLER.ps1"
if errorlevel 1 (
  echo.
  echo Installatie is niet voltooid. Lees de foutmelding hierboven.
  pause
  exit /b 1
)
pause
