const fs = require("fs");
const path = require("path");

const source = path.join(__dirname, "src", "dataAccess", "prisma", "generated", "client");
const destination = path.join(__dirname, "dist", "backend", "src", "dataAccess", "prisma", "generated", "client");

if (!fs.existsSync(source)) {
  console.error("Prisma client ontbreekt. Voer eerst prisma generate uit.");
  process.exit(1);
}

fs.mkdirSync(path.dirname(destination), { recursive: true });
fs.cpSync(source, destination, { recursive: true, force: true });
console.log("Prisma client gekopieerd naar de backend build.");
