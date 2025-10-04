#!/bin/bash
# Webspace Setup Script für Altbau
# Richtet automatisch die notwendige Infrastruktur auf Ihrem Webspace ein

# === KONFIGURATION ===
WEBSPACE_HOST="IHRE-DOMAIN.de"
WEBSPACE_USER="IHRE-BENUTZERNAME"
WEBSPACE_PATH="/htdocs/"
WEBSPACE_PORT="22"
DB_NAME="altbau_db"
DB_USER="DATABASE_USER"
DB_PASS="DATABASE_PASSWORD"

# === FUNKTIONEN ===
function setup_database() {
    echo "🗄️ Richte Datenbank ein..."
    
    ssh -o StrictHostKeyChecking=no -p $WEBSPACE_PORT $WEBSPACE_USER@$WEBSPACE_HOST "
        # MySQL-Befehle für Datenbankerstellung
        mysql -u $DB_USER -p$DB_PASS << 'EOF'
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE $DB_NAME;

-- Tabelle für Gebäude-Klassifizierungen
CREATE TABLE IF NOT EXISTS building_labels (
    id INT AUTO_INCREMENT PRIMARY KEY,
    osm_id VARCHAR(50) UNIQUE NOT NULL,
    label_type ENUM('green', 'yellow', 'red') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_osm_id (osm_id),
    INDEX idx_label_type (label_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabelle für Benutzer/Exporte
CREATE TABLE IF NOT EXISTS exports (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_session_id VARCHAR(100),
    export_data JSON NOT NULL,
    export_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_session (user_session_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Beispiel-Daten eingeben
INSERT IGNORE INTO building_labels (osm_id, label_type) VALUES ('osm:123', 'green');

-- Berechtigungen vergeben (anpassen nach Bedarf)
-- GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$WEBSPACE_USER'@'localhost';
-- FLUSH PRIVILEGES;

EOF
    "
    
    echo "✅ Datenbank $DB_NAME wurde erstellt und konfiguriert"
}

function setup_config() {
    echo "⚙️ Erstelle Konfigurationsdateien..."
    
    # Config.php für API erstellen
    cat > temp_config.php << EOF
<?php
// Altbau API Konfiguration - Automatisch generiert
error_reporting(0); // Produktion
ini_set('display_errors', 0);

// CORS-Header
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if (\$_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Datenbank-Konfiguration
define('DB_CONFIG', [
    'host' => 'localhost',
    'dbname' => '$DB_NAME',
    'username' => '$DB_USER',
    'password' => '$DB_PASS',
    'charset' => 'utf8mb4'
]);

date_default_timezone_set('Europe/Berlin');

// PDO-Verbindung
try {
    \$dsn = "mysql:host=" . DB_CONFIG['host'] . 
           ";dbname=" . DB_CONFIG['dbname'] . 
           ";charset=" . DB_CONFIG['charset'];
    
    \$pdo = new PDO(\$dsn, DB_CONFIG['username'], DB_CONFIG['password'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false
    ]);
    
} catch (PDOException \$e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Database connection failed',
        'message' => 'Setup required'
    ]);
    exit();
}

function sendResponse(\$data, \$code = 200) {
    http_response_code(\$code);
    header('Content-Type: application/json');
    echo json_encode(\$data, JSON_UNESCAPED_UNICODE);
    exit();
}

define('API_KEY', 'altbau-webspace-api-key-change-this');
?>
EOF

    # Upload config.php
    scpd temp_config.php $WEBSPACE_USER@$WEBSPACE_HOST:$WEBSPACE_PATH/api/config.php
    rm temp_config.php
    
    echo "✅ config.php wurde erstellt und hochgeladen"
}

function create_api_endpoints() {
    echo "🌐 Erstelle API-Endpunkte..."
    
    # Gebäude-Labels API
    cat > temp_labels.php << 'EOF'
<?php
require_once 'config.php';

switch ($_SERVER['REQUEST_METHOD']) {
    case 'GET':
        try {
            $stmt = $pdo->prepare("SELECT osm_id, label_type, created_at FROM building_labels ORDER BY updated_at DESC");
            $stmt->execute();
            $labels = $stmt->fetchAll();
            
            sendResponse([
                'success' => true,
                'count' => count($labels),
                'labels' => $labels
            ]);
        } catch (PDOException $e) {
            sendResponse(['error' => 'Database query failed'], 500);
        }
        break;
        
    case 'POST':
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($input['osm_id']) || !isset($input['label_type'])) {
            sendResponse(['error' => 'Missing required fields'], 400);
        }
        
        try {
            $stmt = $pdo->prepare("DELETE FROM building_labels WHERE osm_id = ?");
            $stmt->execute([$input['osm_id']]);
            
            $stmt = $pdo->prepare("INSERT INTO building_labels (osm_id, label_type) VALUES (?, ?)");
            $stmt->execute([$input['osm_id'], $input['label_type']]);
            
            sendResponse([
                'success' => true,
                'message' => 'Label saved',
                'osm_id' => $input['osm_id'],
                'label_type' => $input['label_type']
            ]);
        } catch (PDOException $e) {
            sendResponse(['error' => 'Failed to save label'], 500);
        }
        break;
        
    default:
        sendResponse(['error' => 'Method not allowed'], 405);
}
EOF

    # Export API
    cat > temp_exports.php << 'EOF'
<?php
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(['error' => 'Method not allowed'], 405);
}

$input = json_decode(file_get_contents('php://input'), true);

if (!isset($input['labels']) || !is_array($input['labels'])) {
    sendResponse(['error' => 'Invalid data format'], 400);
}

try {
    $sessionId = session_id() ?: 'anonymous_' . uniqid();
    
    $stmt = $pdo->prepare("INSERT INTO exports (user_session_id, export_data, export_count) VALUES (?, ?, ?)");
    $stmt->execute([
        $sessionId,
        json_encode($input['labels']),
        count($input['labels'])
    ]);
    
    sendResponse([
        'success' => true,
        'message' => 'Export saved to database',
        'session_id' => $sessionId,
        'count' => count($input['labels'])
    ]);
} catch (PDOException $e) {
    sendResponse(['error' => 'Failed to save export'], 500);
}
EOF

    # Upload API-Dateien
    scpd temp_labels.php $WEBSPACE_USER@$WEBSPACE_HOST:$WEBSPACE_PATH/api/labels.php
    scpd temp_exports.php $WEBSPACE_USER@$WEBSPACE_HOST:$WEBSPACE_PATH/api/exports.php
    
    rm temp_labels.php temp_exports.php
    
    echo "✅ API-Endpunkte erstellt: /api/labels.php und /api/exports.php"
}

function setup_ssl_and_headers() {
    echo "🔐 Richte SSL und Headers ein..."
    
    ssh -o StrictHostKeyChecking=no -p $WEBSPACE_PORT $WEBSPACE_USER@$WEBSPACE_HOST "
        # .htaccess für PHP und Sicherheit
        cat > $WEBSPACE_PATH/.htaccess << 'EOF'
# Altbau Webspace Konfiguration
RewriteEngine On

# HTTPS erzwingen
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]

# API-Routing
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^api/(.*)$ api/\$1 [L,QSA]

# Sicherheits-Headers
Header always set X-Frame-Options DENY
Header always set X-XSS-Protection '1; mode=block'
Header always set X-Content-Type-Options nosniff
Header always set Referrer-Policy 'strict-origin-when-cross-origin'

# Cache-Kontrolle
<FilesMatch \"\\.(html|css|js)$\">
    Header set Cache-Control \"public, max-age=3600\"
</FilesMatch>

# PHP-Einstellungen
php_flag display_errors Off
php_value error_reporting E_ALL
php_value upload_max_filesize 10M
php_value post_max_size 10M
EOF

        # Berechtigungen setzen
        chmod 644 $WEBSPACE_PATH/.htaccess
        chmod -R 755 $WEBSPACE_PATH/api/
    "
    
    echo "✅ SSL-Erzwingung und Sicherheits-Headers konfiguriert"
}

function test_setup() {
    echo "🧪 Teste Setup..."
    
    # Test API-Endpunkt
    TEST_URL="https://$WEBSPACE_HOST/api/labels.php"
    
    if curl -s -f "$TEST_URL" > /dev/null; then
        echo "✅ API-Endpunkt ist erreichbar: $TEST_URL"
    else
        echo "⚠️ API-Endpunkt-Test fehlgeschlagen: $TEST_URL"
        echo "💡 Möglicherweise müssen Sie noch:"
        echo "   1. SSL-Zertifikat aktivieren"
        echo "   2. Datenbank-Benutzer konfigurieren"
        echo "   3. PHP-Module aktivieren"
    fi
}

function show_deployment_info() {
    echo ""
    echo "🎉 Webspace-Setup abgeschlossen!"
    echo ""
    echo "📋 Ihre URLs:"
    echo "   Hauptseite: https://$WEBSPACE_HOST"
    echo "   API-Labels: https://$WEBSPACE_HOST/api/labels.php"
    echo "   API-Exports: https://$WEBSPACE_HOST/api/exports.php"
    echo ""
    echo "📊 Datenbank: $DB_NAME wurde erstellt"
    echo "🔧 Konfiguration: config.php erstellt"
    echo "🔐 Sicherheit: SSL + Headers aktiviert"
    echo ""
    echo "⚙️ Nächste Schritte:"
    echo "   1. Bearbeiten Sie config.php mit echten Datenbank-Daten"
    echo "   2. Testen Sie die API-Endpunkte"
    echo "   3. Konfigurieren Sie Netlify-Deployment"
}

# === HAUPTMENÜ ===
case "$1" in
    "full")
        setup_database
        setup_config
        create_api_endpoints
        setup_ssl_and_headers
        test_setup
        show_deployment_info
        ;;
    "db")
        setup_database
        ;;
    "config")
        setup_config
        ;;
    "api")
        create_api_endpoints
        ;;
    "ssl")
        setup_ssl_and_headers
        ;;
    "test")
        test_setup
        ;;
    *)
        echo "🔧 Altbau Webspace Setup Script"
        echo ""
        echo "Verwendung: $0 [full|db|config|api|ssl|test]"
        echo ""
        echo "Befehle:"
        echo "  full    - Vollständiges Setup (alle Schritte)"
        echo "  db      - Nur Datenbank einrichten"
        echo "  config  - Nur Konfiguration erstellen"
        echo "  api     - Nur API-Endpunkte erstellen"
        echo "  ssl     - Nur SSL und Headers"
        echo "  test    - Nur Setup testen"
        echo ""
        echo "📝 Vor dem Setup:"
        echo "1. Bearbeiten Sie dieses Script und tragen Sie Ihre Daten ein"
        echo "2. Stellen Sie sicher, dass MySQL/MariaDB läuft"
        echo "3. Erstellen Sie einen MySQL-Benutzer"
        echo "4. Führen Sie aus: $0 full"
        ;;
esac
