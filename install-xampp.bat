@echo off
setlocal EnableExtensions
title BLACK TIDE - XAMPP Installer
cd /d "%~dp0"

echo.
echo  ==========================================================
echo       BLACK TIDE ^| GLARIUM - LOCAL XAMPP INSTALLER
echo  ==========================================================
echo.
echo  Vereist: XAMPP (MySQL), Node.js 20 LTS of hoger.
echo.

where node >nul 2>nul
if errorlevel 1 (
  echo [FOUT] Node.js is niet gevonden.
  echo Installeer Node.js 20 LTS vanaf https://nodejs.org/
  pause
  exit /b 1
)
where npm >nul 2>nul
if errorlevel 1 (
  echo [FOUT] npm is niet gevonden. Herinstalleer Node.js met npm.
  pause
  exit /b 1
)

for /f "tokens=1" %%v in ('node -v') do echo [OK] Node.js %%v gevonden.
if not exist "backend\package.json" (
  echo [FOUT] backend\package.json ontbreekt. Start deze installer vanuit de projecthoofdmap.
  pause
  exit /b 1
)
if not exist "frontend\package.json" (
  echo [FOUT] frontend\package.json ontbreekt.
  pause
  exit /b 1
)

set "MYSQL_EXE=%ProgramFiles%\xampp\mysql\bin\mysql.exe"
if exist "C:\xampp\mysql\bin\mysql.exe" set "MYSQL_EXE=C:\xampp\mysql\bin\mysql.exe"
if not exist "%MYSQL_EXE%" (
  set /p MYSQL_EXE="Volledig pad naar mysql.exe (bijv. C:\xampp\mysql\bin\mysql.exe): "
)
if not exist "%MYSQL_EXE%" (
  echo [FOUT] mysql.exe niet gevonden.
  pause
  exit /b 1
)

echo.
echo Start in XAMPP Control Panel de module MySQL.
echo Apache is voor deze ontwikkelinstallatie niet nodig.
echo.
set /p DB_USER="MySQL gebruiker [root]: "
if not defined DB_USER set "DB_USER=root"
set /p DB_PASSWORD="MySQL wachtwoord (leeg laten bij standaard XAMPP): "
set "DB_NAME=glarium"

echo.
echo [1/5] Databaseverbinding controleren en database aanmaken...
if defined DB_PASSWORD (
  "%MYSQL_EXE%" -h 127.0.0.1 -P 3306 -u "%DB_USER%" -p%DB_PASSWORD% -e "CREATE DATABASE IF NOT EXISTS %DB_NAME% CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
) else (
  "%MYSQL_EXE%" -h 127.0.0.1 -P 3306 -u "%DB_USER%" -e "CREATE DATABASE IF NOT EXISTS %DB_NAME% CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
)
if errorlevel 1 (
  echo [FOUT] Geen verbinding met MySQL. Controleer XAMPP, gebruiker en wachtwoord.
  pause
  exit /b 1
)
echo [OK] Database %DB_NAME% bestaat.

echo.
echo [2/5] Backend .env configureren...
if not exist "backend\.env" (
  if defined DB_PASSWORD (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$u=$env:DB_USER; $p=[uri]::EscapeDataString($env:DB_PASSWORD); $db=$env:DB_NAME; $url='mysql://'+$u+':'+$p+'@127.0.0.1:3306/'+$db; $secret=[guid]::NewGuid().ToString('N')+[guid]::NewGuid().ToString('N'); @('DATABASE_URL="'+$url+'"','JWT_SECRET='+$secret,'JWT_EXPIRES_IN=7d') | Set-Content -Encoding ascii 'backend/.env'"
  ) else (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$u=$env:DB_USER; $db=$env:DB_NAME; $url='mysql://'+$u+'@127.0.0.1:3306/'+$db; $secret=[guid]::NewGuid().ToString('N')+[guid]::NewGuid().ToString('N'); @('DATABASE_URL="'+$url+'"','JWT_SECRET='+$secret,'JWT_EXPIRES_IN=7d') | Set-Content -Encoding ascii 'backend/.env'"
  )
  if errorlevel 1 (
    echo [FOUT] Aanmaken van backend\.env is mislukt.
    pause
    exit /b 1
  )
) else (
  echo [INFO] Bestaande backend\.env behouden.
)

echo.
echo [3/5] Backend dependencies installeren...
pushd backend
call npm install
if errorlevel 1 (
  popd
  echo [FOUT] Backend npm install mislukt.
  pause
  exit /b 1
)

echo.
echo [4/5] Prisma database-tabellen aanmaken...
call npx prisma generate --schema=src/dataAccess/prisma/schema.prisma
if errorlevel 1 (
  popd
  echo [FOUT] Prisma generate mislukt.
  pause
  exit /b 1
)
call npx prisma migrate deploy --schema=src/dataAccess/prisma/schema.prisma
if errorlevel 1 (
  popd
  echo [FOUT] Database migraties mislukt. Controleer backend\.env en MySQL.
  pause
  exit /b 1
)
call npm run seed
if errorlevel 1 (
  popd
  echo [FOUT] Speldata initialiseren is mislukt.
  pause
  exit /b 1
)
popd

echo.
echo [5/5] Frontend dependencies installeren...
pushd frontend
call npm install
if errorlevel 1 (
  popd
  echo [FOUT] Frontend npm install mislukt.
  pause
  exit /b 1
)
popd

echo.
echo  ==========================================================
echo   INSTALLATIE VOLTOOID
echo  ==========================================================
echo.
echo Start de game met start-local.bat
echo Frontend: http://localhost:3000
echo Backend:  http://localhost:3001/api/hello
echo.
echo Je kunt nu dit venster sluiten.
pause
exit /b 0
