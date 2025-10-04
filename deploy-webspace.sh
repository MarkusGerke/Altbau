#!/bin/bash
# SSH-Deployment Script für Altbau Webspace
# Dieses Script deployed die Altbau-Anwendung zu Ihrem Webspace

# === KONFIGURATION ===
# Tragen Sie hier Ihre Webspace-Daten ein:
WEBSPACE_HOST="IHRE-DOMAIN.de"           # z.B. server.example.com
WEBSPACE_USER="IHRE-BENUTZERNAME"        # z.B. webuser
WEBSPACE_PATH="/htdocs/"                 # Meist /htdocs/ oder /www/
WEBSPACE_PORT="22"                       # Meist 22

# SSH-Verbindungsoptionen
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

# === FUNKTIONEN ===
function deploy() {
    echo "🚀 Deploye Altbau zu $WEBSPACE_USER@$WEBSPACE_HOST:$WEBSPACE_PATH"
    
    # Erstelle Zielverzeichnis falls nicht vorhanden
    echo "📁 Erstelle Zielverzeichnis..."
    ssh $SSH_OPTS -p $WEBSPACE_PORT $WEBSPACE_USER@$WEBSPACE_HOST "mkdir -p $WEBSPACE_PATH"
    
    # Synchronisiere Dateien (ohne node_modules, .git, etc.)
    echo "📤 Synchronisiere Dateien..."
    rsync -avz --delete $SSH_OPTS \
        -e "ssh -p $WEBSPACE_PORT" \
    
    # Kopiere Webserver-Dateien
    --include='*.html' \
    --include='*.css' \
    --include='*.js' \
    --include='*.php' \
    --include='*.json' \
    --include='_headers' \
    --include='_redirects' \
    --include='api/' \
    --include='data/' \
    
    # Ignoriere Git und andere Verzeichnisse
    --exclude='node_modules/' \
    --exclude='.git/' \
    --exclude='test-results/' \
    --exclude='playwright-report/' \
    --exclude='.github/' \
    --exclude='tests/' \
    --exclude='tests-output/' \
    --exclude='deploy-*.sh' \
    --exclude='package*.json' \
    --exclude='playwright.config.ts' \
    --exclude='README.md' \
    
    ./ $WEBSPACE_USER@$WEBSPACE_HOST:$WEBSPACE_PATH
    
    # Berechtigungen setzen
    echo "🔐 Setze Berechtigungen..."
    ssh $SSH_OPTS -p $WEBSPACE_PORT $WEBSPACE_USER@$WEBSPACE_HOST \
        "chmod -R 755 $WEBSPACE_PATH && chmod 644 $WEBSPACE_PATH*.html $WEBSPACE_PATH*.css $WEBSPACE_PATH*.js $WEBSPACE_PATH*.php"
    
    echo "✅ Deployment abgeschlossen!"
    echo "🌐 Website sollte verfügbar sein unter: https://$WEBSPACE_HOST"
}

function test_connection() {
    echo "🔍 Teste SSH-Verbindung..."
    ssh $SSH_OPTS -p $WEBSPACE_PORT $WEBSPACE_USER@$WEBSPACE_HOST \
        "echo '✅ Verbindung erfolgreich!' && echo '📋 Server Info:' && uname -a && php -v 2>/dev/null || echo '❌ PHP nicht gefunden'"
}

function check_infrastructure() {
    echo "🔍 Prüfe Webspace-Infrastruktur..."
    ssh $SSH_OPTS -p $WEBSPACE_PORT $WEBSPACE_USER@$WEBSPACE_HOST "
        echo '📡 Server-Informationen:'
        echo 'OS: $(uname -s)'
        echo 'PHP Version: $(php -v 2>/dev/null | head -1 || echo \"❌ PHP nicht installiert\")'
        echo 'Webserver: $(apache2 -v 2>/dev/null | head -1 || nginx -v 2>/dev/null || echo \"❓ Unbekannt\")'
        echo ''
        echo '📁 Verzeichnisberechtigungen:'
        echo \"$(ls -la $WEBSPACE_PATH 2>/dev/null || echo \"$WEBSPACE_PATH nicht zugänglich\")\"
        echo ''
        echo '🔧 Verfügbare Erweiterungen:'
        php -m 2>/dev/null | grep -E '(pdo|mysql|sqlite|curl|json)' || echo '❌ Keine relevanten PHP-Extensions gefunden'
    "
}

function setup_env() {
    echo "⚙️ Erstelle Umgebungsdateien..."
    
    # Erstelle config.php für Datenbankverbindung
    cat > temp_config.php << 'EOF'
<?php
// Altbau Konfiguration für Webspace
define('DB_HOST', 'localhost');
define('DB_NAME', 'altbau_db');
define('DB_USER', 'DATABASE_USER');
define('DB_PASS', 'DATABASE_PASSWORD');
define('DB_CHARSET', 'utf8mb4');

// Timezone
date_default_timezone_set('Europe/Berlin');

// Error Reporting (für Entwicklung)
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Für Produktion:
// error_reporting(0);
// ini_set('display_errors', 0);
?>
EOF

    # Deploye config.php
    scpd $SSH_OPTS temp_config.php $WEBSPACE_USER@$WEBSPACE_HOST:$WEBSPACE_PATH/config.php
    rm temp_config.php
    
    echo "📄 config.php wurde erstellt. Bearbeiten Sie es mit Ihren Daten. Passwort-Infos."
}

function show_public_key() {
    echo "🔑 Öffentlicher SSH-Schlüssel für Webspace-Konfiguration:"
    echo ""
    if [ -f ~/.ssh/webspace_deploy_altbau.pub ]; then
        cat ~/.ssh/webspace_deploy_altbau.pub
    else
        echo "Erstelle neuen SSH-Schlüssel..."
        ssh-keygen -t ed25519 -C "altbau-webspace-deploy" -f ~/.ssh/webspace_deploy_altbau -N ""
        cat ~/.ssh/webspace_deploy_altbau.pub
    fi
    echo ""
    echo "📋 Kopieren Sie diesen Schlüssel und fügen Sie ihn in die authorized_keys Ihres Webspaces ein:"
    echo "   ~/.ssh/authorized_keys"
}

function update_preview() {
    echo "👀 Erstelle Vorschau-Datei für Deployment..."
    cat > temp_preview.html << 'EOF'
<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Altbau - Deployment Vorschau</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .status { padding: 15px; margin: 20px 0; border-radius: 5px; }
        .success { background: #d4edda; border: 1px solid #c3e6cb; color: #155724; }
        .info { background: #d1ecf1; border: 1px solid #bee5eb; color: #0c5460; }
        .warning { background: #fff3cd; border: 1px solid #ffeaa7; color: #856404; }
        .btn { display: inline-block; padding: 10px 20px; background: #007bff; color: white; text-decoration: none; border-radius: 5px; margin: 10px 5px; }
        .btn:hover { background: #0056b3; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🏠 Altbau - Deployment Status</h1>
        
        <div class="status success">
            <strong>✅ Deployment erfolgreich!</strong><br>
            Die Altbau-Anwendung wurde erfolgreich auf Ihren Webspace deployed.
        </div>
        
        <div class="status info">
            <strong>📡 Nächste Schritte für Datenbankintegration:</strong><br>
            <ol>
                <li>PhpMyAdmin oder MySQL-Zugang aktivieren</li>
                <li>Datenbank "altbau_db" erstellen</li>
                <li>config.php mit Datenbank-Zugangsdaten bearbeiten</li>
                <li>API-Endpunkte testen</li>
            </ol>
        </div>
        
        <div class="status warning">
            <strong>⚠️ Hinweis:</strong><br>
            Diese Vorschau-Seite wird automatisch entfernt, sobald die Hauptanwendung einsatzbereit ist.
        </div>
        
        <p>
            <a href="index.html" class="btn">🚀 Zur Hauptanwendung</a>
            <a href="api/test.php" class="btn">🔧 API-Test</a>
        </p>
        
        <hr>
        <small>Deployment erstellt: <?php echo date('d.m.Y H:i:s'); ?></small>
    </div>
</body>
</html>
EOF

    # Deploye Vorschau
    scpd $SSH_OPTS temp_preview.html $WEBSPACE_USER@$WEBSPACE_HOST:$WEBSPACE_PATH/deployment-preview.html
    rm temp_preview.html
    
    echo "👀 Vorschau-Seite erstellt: https://$WEBSPACE_HOST/deployment-preview.html"
}

# === HAUPTMENÜ ===
case "$1" in
    "deploy")
        deploy
        ;;
    "test")
        test_connection
        ;;
    "infra")
        check_infrastructure
        ;;
    "setup")
        setup_env
        ;;
    "preview")
        update_preview
    ;;
    "key")
        show_public_key
        ;;
    *)
        echo "🔧 Altbau Webspace Deployment Script"
        echo ""
        echo "Verwendung: $0 [deploy|test|infra|setup|preview|key]"
        echo ""
        echo "Befehle:"
        echo "  deploy  - Deploye das Projekt zum Webspace"
        echo "  test    - Teste die SSH-Verbindung"
        echo "  infra   - Prüfe Webspace-Infrastruktur"
        echo "  setup   - Erstelle Umgebungsdateien"
        echo "  preview - Erstelle Deployment-Vorschau"
        echo "  key     - Zeige den öffentlichen SSH-Schlüssel"
        echo ""
        echo "📝 Vor der ersten Verwendung:"
        echo "1. Bearbeiten Sie dieses Script und tragen Sie Ihre Webspace-Daten ein"
        echo "2. Zeigen Sie den SSH-Schlüssel an: $0 key"
        echo "3. Fügen Sie den Schlüssel zu Ihrem Webspace hinzu"
        echo "4. Testen Sie die Verbindung: $0 test"
        echo "5. Prüfen Sie die Infrastruktur: $0 infra"
        echo "6. Deployen Sie: $0 deploy"
        ;;
esac

