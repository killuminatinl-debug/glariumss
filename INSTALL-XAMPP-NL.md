# BLACK TIDE installeren (automatisch)

1. Installeer XAMPP in de standaardmap `C:\\xampp`.
2. Download de ZIP: https://github.com/killuminatinl-debug/glariumss/archive/refs/heads/pirate-rework.zip
3. Pak de volledige inhoud rechtstreeks uit in `C:\\xampp\\htdocs\\` (dus niet in een extra submap).
4. Dubbelklik op `INSTALLER.bat` en bevestig eventueel de Windows-melding.

De installer doet daarna automatisch het volgende:
- installeert Node.js LTS als dat nog niet aanwezig is;
- start Apache en MySQL van XAMPP;
- maakt de database `glarium` aan met de standaard XAMPP-login;
- configureert de backend, installeert de pakketten en voert migraties en seed uit;
- bouwt de game, plaatst de frontend in `htdocs`, start de API en opent de browser.

Daarna speel je via http://localhost/

**Let op:** dit is een lokale XAMPP-installatie. Je hoeft geen Node-commando's of databasecommando's zelf in te voeren. De eerste installatie heeft internet nodig om Node.js en de projectpakketten op te halen. Als je MySQL een eigen wachtwoord gebruikt in plaats van de standaard XAMPP-login (root zonder wachtwoord), moet dat wachtwoord in `backend/.env` worden ingevuld.
