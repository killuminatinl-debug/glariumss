@echo off
setlocal
title BLACK TIDE - Start Game
cd /d "%~dp0"

if not exist "backend\node_modules" (
  echo Dependencies ontbreken. Voer eerst install-xampp.bat uit.
  pause
  exit /b 1
)
if not exist "frontend\node_modules" (
  echo Frontend dependencies ontbreken. Voer eerst install-xampp.bat uit.
  pause
  exit /b 1
)

echo Start eerst MySQL in XAMPP Control Panel.
start "BLACK TIDE Backend" cmd /k "cd /d "%~dp0backend" && npm run dev"
timeout /t 3 /nobreak >nul
start "BLACK TIDE Frontend" cmd /k "cd /d "%~dp0frontend" && npm start"
timeout /t 5 /nobreak >nul
start "" "http://localhost:3000"
echo.
echo BLACK TIDE wordt gestart.
echo Laat beide terminalvensters open zolang je speelt.
echo Stoppen: sluit de twee terminalvensters.
