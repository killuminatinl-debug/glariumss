@echo off
title BLACK TIDE - GAME SERVER
cd /d "%~dp0backend"
if not exist "dist\backend\src\index.js" (echo Voer eerst INSTALLER.bat uit. ^& pause ^& exit /b 1)
echo BLACK TIDE API start op poort 3001. Laat dit venster open.
npm start
pause
