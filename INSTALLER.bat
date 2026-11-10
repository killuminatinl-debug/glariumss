@echo off
setlocal EnableExtensions
title BLACK TIDE - Automatische installatie
color 0B
cd /d "%~dp0"

:: Vraag automatisch beheerdersrechten voor Node.js en XAMPP.
net session >nul 2>nul
if not "%errorlevel%"=="0" (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

echo.
echo  ==========================================
echo          BLACK TIDE - AUTOMATISCHE SETUP
echo  ==========================================
echo.
echo Dit programma regelt de installatie en start de game.
echo.

:: Controleer of de bestanden op de juiste plek staan.
if not exist "backend\package.json" (
  echo FOUT: De map backend ontbreekt.
  echo Pak de volledige ZIP rechtstreeks uit in C:\xampp\htdocs\
  goto fail
)
if not exist "frontend\package.json" (
  echo FOUT: De map frontend ontbreekt.
  echo Pak de volledige ZIP rechtstreeks uit in C:\xampp\htdocs\
  goto fail
)

:: Zoek XAMPP automatisch.
set "XAMPP=C:\xampp"
if not exist "%XAMPP%\mysql\bin\mysql.exe" set "XAMPP=%ProgramFiles%\xampp"
if not exist "%XAMPP%\mysql\bin\mysql.exe" set "XAMPP=%ProgramFiles(x86)%\xampp"
if not exist "%XAMPP%\mysql\bin\mysql.exe" (
  echo FOUT: XAMPP niet gevonden. Installeer XAMPP eerst in C:\xampp.
  goto fail
)

:: Node.js wordt automatisch geinstalleerd als het ontbreekt.
where node >nul 2>nul
if errorlevel 1 (
  echo [1/6] Node.js wordt automatisch geinstalleerd...
  where winget >nul 2>nul
  if not errorlevel 1 (
    winget install --id OpenJS.NodeJS.LTS --exact --silent --accept-package-agreements --accept-source-agreements
  ) else (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $v=Invoke-RestMethod 'https://nodejs.org/dist/index.json' | Where-Object { $_.lts -ne $false } | Select-Object -First 1; $msi='node-'+$v.version+'-x64.msi'; $url='https://nodejs.org/dist/'+$v.version+'/'+$msi; $out=Join-Path $env:TEMP $msi; Invoke-WebRequest $url -OutFile $out; Start-Process msiexec.exe -ArgumentList @('/i', $out, '/qn', '/norestart') -Wait; Remove-Item $out -Force"
  )
  if errorlevel 1 (
    echo Node.js automatisch installeren is mislukt.
    goto fail
  )
  set "PATH=%ProgramFiles%\nodejs;%APPDATA%\npm;%PATH%"
)
where node >nul 2>nul
if errorlevel 1 (
  echo Node.js is geinstalleerd, maar Windows kan het nog niet vinden.
  echo Start Windows opnieuw en voer INSTALLER.bat nogmaals uit.
  goto fail
)

echo [2/6] Apache en MySQL starten...
if not exist "%XAMPP%\apache\bin\httpd.exe" (
  echo FOUT: Apache ontbreekt in de XAMPP-installatie.
  goto fail
)
if not exist "%XAMPP%\apache_start.bat" (
  echo FOUT: apache_start.bat niet gevonden.
  goto fail
)
if not exist "%XAMPP%\mysql_start.bat" (
  echo FOUT: mysql_start.bat niet gevonden.
  goto fail
)
start "BLACK TIDE Apache" /min cmd /c ""%XAMPP%\apache_start.bat""
start "BLACK TIDE MySQL" /min cmd /c ""%XAMPP%\mysql_start.bat""

echo Wachten op MySQL...
set "MYSQL=%XAMPP%\mysql\bin\mysql.exe"
set /a WAIT=0
:waitmysql
"%MYSQL%" -h 127.0.0.1 -u root -e "SELECT 1" >nul 2>nul
if not errorlevel 1 goto mysqlready
set /a WAIT+=1
if %WAIT% GEQ 20 (
  echo MySQL start niet. Controleer of poort 3306 vrij is.
  goto fail
)
timeout /t 2 /nobreak >nul
goto waitmysql

:mysqlready
echo [3/6] Database automatisch aanmaken...
"%MYSQL%" -h 127.0.0.1 -u root -e "CREATE DATABASE IF NOT EXISTS glarium CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
if errorlevel 1 goto dbfail
set "DBUSER=root"
set "DBPASS="
if not exist "backend\.env" (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$u=$env:DBUSER; $p=[uri]::EscapeDataString($env:DBPASS); $auth=if($p){$u+':'+$p+'@'}else{$u+'@'}; $url='mysql://'+$auth+'127.0.0.1:3306/glarium'; $secret=[guid]::NewGuid().ToString('N')+[guid]::NewGuid().ToString('N'); @('DATABASE_URL="'+$url+'"','JWT_SECRET='+$secret,'JWT_EXPIRES_IN=7d') | Set-Content -Encoding ascii 'backend/.env'"
  if errorlevel 1 goto fail
)

echo [4/6] Backend installeren en database vullen...
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

echo [5/6] Gamebestanden bouwen...
pushd frontend
call npm install
if errorlevel 1 goto frontendfail
call npm run build
if errorlevel 1 goto frontendfail
popd
xcopy "frontend\dist\*" "%~dp0" /E /I /Y >nul
if errorlevel 1 goto fail

echo [6/6] Game starten...
:: Voorkom dat de API dubbel wordt gestart.
netstat -ano | findstr ":3001" | findstr "LISTENING" >nul
if errorlevel 1 start "BLACK TIDE API" /min cmd /c "cd /d ""%~dp0backend"" && npm start"
timeout /t 4 /nobreak >nul
start "" "http://localhost/"

echo.
echo ==========================================
echo       BLACK TIDE IS GEINSTALLEERD!
echo ==========================================
echo De game is geopend in je browser.
echo Starten kan voortaan door INSTALLER.bat opnieuw te openen.
echo.
pause
exit /b 0

:dbfail
echo Database kon niet worden aangemaakt met de standaard XAMPP-login.
echo Gebruik je een aangepast MySQL-wachtwoord? Pas backend\.env handmatig aan.
goto fail

:backendfail
popd
echo Backend-installatie mislukt. De foutmelding staat hierboven.
goto fail

:frontendfail
popd
echo Frontend-build mislukt. De foutmelding staat hierboven.
goto fail

:fail
echo.
echo INSTALLATIE NIET VOLTOOID.
pause
exit /b 1
