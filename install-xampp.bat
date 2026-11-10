@echo off
setlocal EnableExtensions
title BLACK TIDE - INSTALLER
cd /d "%~dp0"
color 0B
echo.
echo BLACK TIDE - INSTALLATIE VOOR XAMPP
echo.
echo Zet de volledige game rechtstreeks in C:\xampp\htdocs\
echo Start Apache en MySQL in XAMPP. Node.js 20 LTS is ook vereist.
echo.
pause
where node >nul 2>nul
if errorlevel 1 (echo Installeer eerst Node.js 20 LTS via https://nodejs.org/ & pause & exit /b 1)
if not exist "backend\package.json" (echo Backend-map ontbreekt. Pak de volledige ZIP uit in htdocs. & pause & exit /b 1)
if not exist "frontend\package.json" (echo Frontend-map ontbreekt. Pak de volledige ZIP uit in htdocs. & pause & exit /b 1)
set "MYSQL=C:\xampp\mysql\bin\mysql.exe"
if not exist "%MYSQL%" set "MYSQL=%ProgramFiles%\xampp\mysql\bin\mysql.exe"
if not exist "%MYSQL%" set /p MYSQL="Pad naar mysql.exe: "
if not exist "%MYSQL%" (echo mysql.exe niet gevonden. & pause & exit /b 1)
set /p DBUSER="MySQL gebruiker [root]: "
if not defined DBUSER set "DBUSER=root"
set /p DBPASS="MySQL wachtwoord (standaard leeg): "
echo.
echo [1/5] Database aanmaken...
if defined DBPASS ("%MYSQL%" -h 127.0.0.1 -u "%DBUSER%" -p%DBPASS% -e "CREATE DATABASE IF NOT EXISTS glarium CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;") else ("%MYSQL%" -h 127.0.0.1 -u "%DBUSER%" -e "CREATE DATABASE IF NOT EXISTS glarium CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;")
if errorlevel 1 (echo MySQL verbinding mislukt. Controleer XAMPP en wachtwoord. & pause & exit /b 1)
echo [2/5] Database-instellingen...
if not exist "backend\.env" powershell -NoProfile -ExecutionPolicy Bypass -Command "$u=$env:DBUSER; $p=[uri]::EscapeDataString($env:DBPASS); if($p){$auth=$u+':'+$p+'@'}else{$auth=$u+'@'}; $url='mysql://'+$auth+'127.0.0.1:3306/glarium'; $secret=[guid]::NewGuid().ToString('N')+[guid]::NewGuid().ToString('N'); @('DATABASE_URL="'+$url+'"','JWT_SECRET='+$secret,'JWT_EXPIRES_IN=7d') | Set-Content -Encoding ascii 'backend/.env'"
if errorlevel 1 (echo backend.env maken mislukt. & pause & exit /b 1)
echo [3/5] Backend installeren, database maken en vullen...
pushd backend
call npm install
if errorlevel 1 goto backendfail
call npx prisma generate --schema=src/dataAccess/prisma/schema.prisma
if errorlevel 1 goto backendfail
call npx prisma migrate deploy --schema=src/dataAccess/prisma/schema.prisma
if errorlevel 1 goto backendfail
call npm run seed
if errorlevel 1 goto backendfail
call npm run build
if errorlevel 1 goto backendfail
popd
echo [4/5] Frontend bouwen...
pushd frontend
call npm install
if errorlevel 1 goto frontendfail
call npm run build
if errorlevel 1 goto frontendfail
popd
echo [5/5] Game in htdocs plaatsen...
xcopy "frontend\dist\*" "%~dp0" /E /I /Y >nul
if errorlevel 1 (echo Kopieren mislukt. & pause & exit /b 1)
echo.
echo INSTALLATIE GEREED!
echo Open http://localhost/
echo Start daarna START-GAME.bat en laat dat venster open.
start "" "http://localhost/"
pause
exit /b 0
:backendfail
popd
echo Backend/database installatie mislukt. Lees de foutmelding hierboven.
pause
exit /b 1
:frontendfail
popd
echo Frontend installatie mislukt. Lees de foutmelding hierboven.
pause
exit /b 1
