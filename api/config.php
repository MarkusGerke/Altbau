<?php
// Altbau API Konfiguration für Webspace
// Diese Datei enthält die Datenbankverbindungseinstellungen

// Fehlerbehandlung für Entwicklung
error_reporting(E_ALL);
ini_set('display_errors', 1);

// CORS-Header für Frontend-Anfragen
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Options-Requests behandeln
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Datenbank-Konfiguration
// ⚠️ ÄNDERN SIE DIESE WERTE FÜR IHRE UMWELTUNG ⚠️
define('DB_CONFIG', [
    'host' => 'localhost',
    'dbname' => 'altbau_db',
    'username' => 'DATABASE_USER',
    'password' => 'DATABASE_PASSWORD',
    'charset' => 'utf8mb4'
]);

// Timezone
date_default_timezone_set('Europe/Berlin');

// PDO-Verbindung erstellen
try {
    $dsn = "mysql:host=" . DB_CONFIG['host'] . 
           ";dbname=" . DB_CONFIG['dbname'] . 
           ";charset=" . DB_CONFIG['charset'];
    
    $pdo = new PDO($dsn, DB_CONFIG['username'], DB_CONFIG['password'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false
    ]);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Database connection failed',
        'message' => $e->getMessage()
    ]);
    exit();
}

// Hilfsfunktion für JSON-Response
function sendResponse($data, $code = 200) {
    http_response_code($code);
    header('Content-Type: application/json');
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit();
}

// Authentifizierungs-Token (einfache Implementierung)
define('API_KEY', 'altbau-api-key-change-this');
?>
