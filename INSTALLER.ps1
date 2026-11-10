$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root
function Invoke-Checked([string]$Program, [string[]]$Arguments, [string]$WorkingDirectory) {
    Push-Location $WorkingDirectory
    try { & $Program @Arguments; if ($LASTEXITCODE -ne 0) { throw "Opdracht mislukt (exitcode $LASTEXITCODE): $Program $($Arguments -join ' ')" } }
    finally { Pop-Location }
}
function Find-Xampp {
    $candidates = @("C:\xampp", (Join-Path $env:ProgramFiles "xampp"))
    $pf86 = (Get-Item "Env:ProgramFiles(x86)" -ErrorAction SilentlyContinue).Value
    if ($pf86) { $candidates += (Join-Path $pf86 "xampp") }
    foreach ($candidate in $candidates) { if (Test-Path (Join-Path $candidate "mysql\bin\mysql.exe")) { return $candidate } }
    throw "XAMPP niet gevonden. Installeer XAMPP in C:\xampp en probeer opnieuw."
}
try {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Windows vraagt toestemming om de installatie uit te voeren..."
        $argList = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", ('"' + $PSCommandPath + '"'))
        Start-Process -FilePath "powershell.exe" -ArgumentList $argList -Verb RunAs
        exit 0
    }
    Write-Host "BLACK TIDE - Automatische XAMPP installatie" -ForegroundColor Yellow
    if (-not (Test-Path "$Root\backend\package.json") -or -not (Test-Path "$Root\frontend\package.json")) { throw "De mappen backend en frontend ontbreken. Pak de volledige ZIP rechtstreeks uit in C:\xampp\htdocs." }

    Write-Host ""; Write-Host "[1/6] XAMPP controleren" -ForegroundColor Cyan
    $Xampp = Find-Xampp
    $Mysql = Join-Path $Xampp "mysql\bin\mysql.exe"
    foreach ($required in @("$Xampp\apache_start.bat", "$Xampp\mysql_start.bat")) { if (-not (Test-Path $required)) { throw "XAMPP-bestand ontbreekt: $required" } }

    Write-Host ""; Write-Host "[2/6] Node.js controleren" -ForegroundColor Cyan
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        $winget = Get-Command winget -ErrorAction SilentlyContinue
        if ($winget) {
            & $winget.Source install --id OpenJS.NodeJS.LTS --exact --silent --accept-package-agreements --accept-source-agreements
            if ($LASTEXITCODE -ne 0) { throw "Node.js kon niet via winget worden geïnstalleerd." }
        } else {
            $release = Invoke-RestMethod "https://nodejs.org/dist/index.json" | Where-Object { $_.lts } | Select-Object -First 1
            if (-not $release) { throw "Kon geen actuele Node.js LTS-versie vinden." }
            $msi = "node-$($release.version)-x64.msi"; $download = Join-Path $env:TEMP $msi
            Invoke-WebRequest "https://nodejs.org/dist/$($release.version)/$msi" -OutFile $download
            $process = Start-Process -FilePath "msiexec.exe" -ArgumentList @("/i", $download, "/qn", "/norestart") -Wait -PassThru
            Remove-Item $download -Force -ErrorAction SilentlyContinue
            if ($process.ExitCode -notin @(0,3010)) { throw "Node.js-installatie is mislukt (code $($process.ExitCode))." }
        }
        $env:Path = "$env:ProgramFiles\nodejs;$env:APPDATA\npm;$env:Path"
    }
    $Node = (Get-Command node -ErrorAction Stop).Source
    $Npm = Get-Command npm.cmd -ErrorAction SilentlyContinue
    if (-not $Npm) { $Npm = Get-Command npm -ErrorAction Stop }
    $NpmPath = $Npm.Source
    Write-Host "Node: $(& $Node --version)"

    Write-Host ""; Write-Host "[3/6] Apache en MySQL starten" -ForegroundColor Cyan
    Start-Process -FilePath $env:ComSpec -ArgumentList @("/c", ('"' + $Xampp + '\apache_start.bat' + '"')) -WorkingDirectory $Xampp -WindowStyle Minimized
    Start-Process -FilePath $env:ComSpec -ArgumentList @("/c", ('"' + $Xampp + '\mysql_start.bat' + '"')) -WorkingDirectory $Xampp -WindowStyle Minimized
    $mysqlReady = $false
    for ($i=0; $i -lt 45; $i++) {
        & $Mysql -h 127.0.0.1 -u root -e "SELECT 1" *> $null
        if ($LASTEXITCODE -eq 0) { $mysqlReady = $true; break }
        Start-Sleep -Seconds 2
    }
    if (-not $mysqlReady) { throw "MySQL startte niet. Controleer in XAMPP of MySQL op poort 3306 draait." }

    Write-Host ""; Write-Host "[4/6] Database en configuratie herstellen" -ForegroundColor Cyan
    & $Mysql -h 127.0.0.1 -u root -e "CREATE DATABASE IF NOT EXISTS glarium CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    if ($LASTEXITCODE -ne 0) { throw "Database glarium kon niet worden aangemaakt. Deze installer verwacht XAMPP root zonder wachtwoord." }
    $envPath = Join-Path $Root "backend\.env"; $secret = ""
    if (Test-Path $envPath) {
        $existing = Get-Content $envPath -Raw -ErrorAction SilentlyContinue
        if ($existing -match '(?m)^JWT_SECRET=(.+)$') { $secret = $Matches[1].Trim() }
    }
    if ([string]::IsNullOrWhiteSpace($secret) -or $secret -match '%20|JWT_EXPIRES_IN|DATABASE_URL') { $secret = [Guid]::NewGuid().ToString("N") + [Guid]::NewGuid().ToString("N") }
    $envLines = [string[]]@("DATABASE_URL=mysql://root@127.0.0.1:3306/glarium", "JWT_SECRET=$secret", "JWT_EXPIRES_IN=7d")
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllLines($envPath, $envLines, $utf8NoBom)
    $check = [IO.File]::ReadAllLines($envPath)
    if ($check.Count -ne 3 -or $check[0] -ne "DATABASE_URL=mysql://root@127.0.0.1:3306/glarium" -or $check[1] -notmatch '^JWT_SECRET=.+$' -or $check[2] -ne "JWT_EXPIRES_IN=7d") { throw "backend/.env is niet correct aangemaakt." }
    Write-Host "DATABASE_URL, JWT_SECRET en JWT_EXPIRES_IN zijn apart gecontroleerd."

    Write-Host ""; Write-Host "[5/6] Backend installeren, migreren en bouwen" -ForegroundColor Cyan
    Invoke-Checked $NpmPath @("install") "$Root\backend"
    Invoke-Checked $NpmPath @("exec", "--", "prisma", "generate", "--schema=src/dataAccess/prisma/schema.prisma") "$Root\backend"
    Invoke-Checked $NpmPath @("exec", "--", "prisma", "migrate", "deploy", "--schema=src/dataAccess/prisma/schema.prisma") "$Root\backend"
    Invoke-Checked $NpmPath @("run", "seed") "$Root\backend"
    Invoke-Checked $NpmPath @("run", "build") "$Root\backend"
    $entry = Join-Path $Root "backend\dist\backend\src\index.js"
    if (-not (Test-Path $entry)) {
        $alternatives = @(Get-ChildItem "$Root\backend\dist" -Filter index.js -Recurse -ErrorAction SilentlyContinue)
        if ($alternatives.Count -eq 1) { $entry = $alternatives[0].FullName } else { throw "Backend build heeft geen eenduidige index.js opgeleverd." }
    }

    Write-Host ""; Write-Host "[6/6] Frontend bouwen, publiceren en server controleren" -ForegroundColor Cyan
    Invoke-Checked $NpmPath @("install") "$Root\frontend"
    Invoke-Checked $NpmPath @("run", "build") "$Root\frontend"
    $dist = Join-Path $Root "frontend\dist"
    if (-not (Test-Path (Join-Path $dist "index.html"))) { throw "Frontend build heeft geen index.html gemaakt." }
    Copy-Item (Join-Path $dist "*") -Destination $Root -Recurse -Force

    $logs = Join-Path $Root "backend\logs"; New-Item -ItemType Directory -Path $logs -Force | Out-Null
    $listener = Get-NetTCPConnection -LocalPort 3001 -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $listener) { Start-Process -FilePath $Node -ArgumentList @($entry) -WorkingDirectory "$Root\backend" -WindowStyle Hidden -RedirectStandardOutput "$logs\api.log" -RedirectStandardError "$logs\api-error.log" }
    $apiReady = $false
    for ($i=0; $i -lt 30; $i++) {
        try { $response = Invoke-WebRequest "http://127.0.0.1:3001/api/hello" -UseBasicParsing -TimeoutSec 2; if ($response.StatusCode -eq 200) { $apiReady=$true; break } } catch {}
        Start-Sleep -Seconds 2
    }
    if (-not $apiReady) { $apiLog = Get-Content "$logs\api-error.log" -Raw -ErrorAction SilentlyContinue; throw "API reageert niet op poort 3001. backend\logs\api-error.log: $apiLog" }
    $siteReady = $false
    for ($i=0; $i -lt 15; $i++) {
        try { $site = Invoke-WebRequest "http://127.0.0.1/" -UseBasicParsing -TimeoutSec 3; if ($site.StatusCode -eq 200) { $siteReady=$true; break } } catch {}
        Start-Sleep -Seconds 2
    }
    if (-not $siteReady) { throw "API werkt, maar Apache serveert de game niet op http://localhost/. Controleer Apache en poort 80." }
    Start-Process "http://localhost/"
    Write-Host ""; Write-Host "BLACK TIDE IS GEÏNSTALLEERD EN GECONTROLEERD." -ForegroundColor Green
    Write-Host "Game: http://localhost/ | API: http://127.0.0.1:3001/api/hello"
    exit 0
}
catch {
    Write-Host ""; Write-Host "INSTALLATIE MISLUKT: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Geen succesmelding: een controle is mislukt."
    exit 1
}