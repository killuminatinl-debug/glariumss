# BLACK TIDE installeren in XAMPP

1. Download: https://github.com/killuminatinl-debug/glariumss/archive/refs/heads/pirate-rework.zip
2. Pak ALLE bestanden rechtstreeks uit in `C:\xampp\htdocs\`. Dus `INSTALLER.bat`, `backend`, `frontend` en `shared` staan direct in htdocs.
3. Installeer Node.js 20 LTS via https://nodejs.org/.
4. Open XAMPP en start Apache en MySQL.
5. Dubbelklik op `INSTALLER.bat`. Gebruik bij standaard XAMPP de MySQL-gebruiker `root` en laat het wachtwoord leeg.
6. Wacht tot de installer meldt dat de installatie klaar is.
7. Dubbelklik op `START-GAME.bat`. Laat het zwarte venster open.
8. Speel via http://localhost/

De installer maakt de database, configureert de backend, installeert de pakketten, voert database-migraties en basisdata uit, bouwt de game en kopieert de frontend naar htdocs zodat Apache deze op localhost kan tonen.

Benodigd: XAMPP (Apache + MySQL) en Node.js 20 LTS. Dit is een lokale pc-installatie.
