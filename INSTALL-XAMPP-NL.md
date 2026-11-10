# BLACK TIDE - installeren met XAMPP (Windows)

## Wat je nodig hebt
- XAMPP voor Windows, met MySQL/MariaDB.
- Node.js 20 LTS of nieuwer (npm wordt meegeleverd).
- Git (optioneel) of download de ZIP van de branch `pirate-rework`.

> Let op: XAMPP levert Apache en MySQL, maar deze game is een React + Node.js-app. De game draait lokaal via Node.js op poort 3000 (frontend) en 3001 (backend). Apache hoeft voor deze ontwikkelinstallatie niet aan te staan. Zet de React-map niet simpelweg in `htdocs`; daarmee start de Node-backend niet.

## Installeren
1. Installeer XAMPP en Node.js 20 LTS.
2. Download de ZIP van https://github.com/killuminatinl-debug/glariumss/archive/refs/heads/pirate-rework.zip
3. Pak het volledige project uit, bijvoorbeeld naar `C:\\xampp\\htdocs\\black-tide\\`. De mappen `backend`, `frontend` en `shared` moeten direct in deze map staan.
4. Open XAMPP Control Panel en klik bij **MySQL** op **Start**. Apache is voor deze lokale Node-installatie niet nodig.
5. Dubbelklik op `install-xampp.bat` in de projecthoofdmap.
6. Vul de MySQL-gebruiker in (standaard `root`). Laat het wachtwoord leeg als jouw XAMPP-installatie geen root-wachtwoord gebruikt.
7. De installer maakt database `glarium`, schrijft `backend/.env`, installeert de Node-pakketten, genereert Prisma, voert de bestaande database-migraties uit en vult de basis-speldata.
8. Als de installer zonder foutmelding eindigt, dubbelklik op `start-local.bat`.

## Spelen
- Open http://localhost:3000
- Backendcontrole: http://localhost:3001/api/hello
- Maak een account aan via het registratiescherm in de game.
- Laat de twee geopende terminalvensters en XAMPP MySQL open tijdens het spelen.

## Opnieuw starten
Start MySQL in XAMPP en voer daarna `start-local.bat` uit. De installatie hoef je niet opnieuw uit te voeren.

## Problemen oplossen
- **MySQL start niet:** controleer of poort 3306 al door een andere MySQL-service wordt gebruikt.
- **Database login mislukt:** controleer de MySQL-gebruiker en het wachtwoord en voer `install-xampp.bat` opnieuw uit. Een bestaande `backend/.env` wordt bewust niet overschreven; verwijder die alleen als je de verbinding opnieuw wilt laten configureren.
- **Poort 3000 of 3001 bezet:** sluit de andere applicatie die deze poort gebruikt.
- **Node/npm niet gevonden:** installeer Node.js 20 LTS en open daarna een nieuw terminalvenster.
- **Prisma-migratie faalt:** bekijk de fout in het installer-venster; controleer of MySQL actief is en of `backend/.env` naar `127.0.0.1:3306/glarium` verwijst.

## Beveiliging
Deze installer is bedoeld voor lokaal testen op je eigen pc. Gebruik geen standaard of leeg MySQL-wachtwoord op een publiek bereikbare server. Bewaar `backend/.env` privé en deel de JWT-secret niet. Voor publieke hosting is een aparte productieconfiguratie met HTTPS, process manager, firewall en een afgeschermde database nodig.
