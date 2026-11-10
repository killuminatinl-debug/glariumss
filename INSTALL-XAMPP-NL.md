# BLACK TIDE installeren op Windows met XAMPP

## Eenmalige installatie

1. Installeer XAMPP in de standaardmap `C:\xampp`.
2. Download de nieuwste ZIP van de branch `pirate-rework`:
   https://github.com/killuminatinl-debug/glariumss/archive/refs/heads/pirate-rework.zip
3. Pak de volledige ZIP uit in `C:\xampp\htdocs\`. De bestanden `INSTALLER.bat`, `INSTALLER.ps1`, `backend` en `frontend` moeten direct in `htdocs` staan.
4. Dubbelklik op `INSTALLER.bat` en bevestig de Windows-beheerdersmelding.
5. Laat het installatievenster open tot de melding **BLACK TIDE IS GEÏNSTALLEERD EN GECONTROLEERD** verschijnt.

De installer controleert XAMPP en Node.js, start Apache/MySQL, maakt de database `glarium`, schrijft een schone `backend\.env`, installeert de pakketten, genereert Prisma, voert migraties en seed uit, bouwt backend en frontend, start de API en controleert beide webadressen.

Speel via http://localhost/

## Als de installatie stopt

De installer meldt nu de stap die is mislukt en toont geen onterechte succesmelding. De API-logbestanden staan in:
- `backend\logs\api.log`
- `backend\logs\api-error.log`

Deze standaardinstallatie verwacht XAMPP MySQL met gebruiker `root` zonder wachtwoord en poort `3306`. Als je MySQL zelf een wachtwoord hebt gegeven, moet de databaseverbinding daarop worden aangepast.

## Opnieuw starten

Start Apache en MySQL in XAMPP Control Panel en voer `start-local.bat` uit om de API te starten. Open daarna http://localhost/
