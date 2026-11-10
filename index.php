<?php
declare(strict_types=1);

$gameIndex = __DIR__ . DIRECTORY_SEPARATOR . 'index.html';

if (!is_file($gameIndex)) {
    http_response_code(503);
    header('Content-Type: text/plain; charset=utf-8');
    echo "BLACK TIDE is nog niet gebouwd. Voer INSTALLER.bat uit.";
    exit;
}

header('Content-Type: text/html; charset=utf-8');
readfile($gameIndex);
