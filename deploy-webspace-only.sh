#!/bin/bash
# Webspace-Only Deployment für Altbau
# Dieses Script deployed AUSSCHLIESSLICH zu Ihrem Webspace - über Netlify wird nicht deployed

# === KONFIGURATION ===
# Tragen Sie hier Ihre Webspace-Daten ein:
WEBSPACE_HOST="IHRE-DOMAIN.de"           # z.B. server.example.com oder Ihre Domain
WEBSPACE_USER="IHRE-BENUTZERNAME"        # z.B. webuser oder Ihr SSH-Benutzername
WEBSPACE_PATH="/htdocs/"                 # Meist /htdocs/ oder /www/ oder /public_html/
WEBSPACE_PORT="22"                       # Meist 22, manchmal 2222

# SSH-Verbindungsoptionen
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

# === FUNKTIONEN ===
function deploy_to_webspace() {
    echo "🚀 Deploye Altbau AUSSCHLIESSLICH zu Ihrem Webspace..."
    echo "📍 Ziel: $WEBSPACE_USER@$WEBSPACE_HOST:$WEBSPACE_PATH"
    echo "❌ Netlify wird NICHT deployed - nur Webspace!"
    
    # Erstelle Zielverzeichnis falls nicht vorhanden
    echo "📁 Erstelle Zielverzeichnis..."
    ssh $SSH_OPTS -p $WEBSPACE_PORT $WEBSPACE_USER@$WEBSPACE_HOST "mkdir -p $WEBSPACE_PATH"
    
    # Synchronisiere Dateien (ohne node_modules, .git, etc.)
    echo "📤 Synchronisiere Dateien zu Webspace..."
    rsync -avz --delete $SSH_OPTS \
        -e "ssh -p $WEBSPACE_PORT" \
    
    # Kopiere Webserver-Dateien (alle wichtigen Web-Dateien)
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
    --exclude='netlify/' \
    --exclude='deploy-*.sh' \
    --exclude='package*.json' \
    --exclude='playwright.config.ts' \
    --exclude='README.md' \
    
    ./ $WEBSPACE_USER@$WEBSPACE_HOST:$WEBSPACE_PATH
    
    # Berechtigungen setzen
    echo "🔐 Setze Berechtigungen..."
    ssh $SSH_OPTS -p $WEBSPACE_PORT $WEBSPACE_USER@$WEBSPACE_HOST \
        "chmod -R 755 $WEBSPACE_PATH && chmod 644 $WEBSPACE_PATH*.html $WEBSPACE_PATH*.css $WEBSPACE_PATH*.js $WEBSPACE_PATH*.php 2>/dev/null || true"
    
    echo "✅ Deployment zu Webspace erfolgreich abgeschlossen!"
    echo "🌐 Ihre Website ist verfügbar unter: https://$WEBSPACE_HOST"
    echo "💡 Hinweis: Netlify wurde bewusst nicht deployed - alles läuft auf Ihrem Webspace!"
}

function setup_webspace_infrastructure() {
    echo "⚙️ Richte Webspace-Infrastruktur ein..."
    
    # Führe Webspace-Setup aus, falls verfügbar
    if [ -f "webspace-setup.sh" ]; then
        echo "🔧 Starte automatisches Webspace-Setup..."
        ./webspace-setup.sh full
    else
        echo "⚠️ webspace-setup.sh nicht gefunden"
        echo "💡 Hinweis: Stellen Sie sicher, dass MySQL läuft und erstellen Sie eine Datenbank 'altbau_db'"
    fi
}

function test_connection() {
    echo "🔍 Teste SSH-Verbindung zum Webspace..."
    ssh $SSH_OPTS -p $WEBSPACE_PORT $WEBSPACE_USER@$WEBSPACE_HOST \
        "echo '✅ Verbindung zum Webspace erfolgreich!' && echo '📍 Server Info:' && uname -a && php -v 2>/dev/null || echo '❌ PHP nicht gefunden - benötigt für API'"
}

function show_deployment_status() {
    echo ""
    echo "🎉 WEBSPACE-ONLY DEPLOYMENT STATUS"
    echo "================================"
    echo "🌐 Hauptseite: https://$WEBSPACE_HOST"
    echo "🗄️ API-Endpunkte:"
    echo "   - Labels: https://$WEBSPACE_HOST/api/labels.php"
    echo "   - Exports: https://$WEBSPACE_HOST/api/exports.php"
    echo "   - Config: https://$WEBSPACE_HOST/api/config.php"
    echo ""
    echo "📊 Webspace-Status:"
    ssh $SSH_OPTS -p $WEBSPACE_PORT $WEBSPACE_USER@$WEBSPACE_HOST \
        "echo '📁 Verzeichnis:'; ls -la $WEBSPACE_PATH | head -10; echo ''; echo '🔧 PHP-Version:'; php -v 2>/dev/null | head -1 || echo 'PHP nicht verfügbar'"
}

function show_help() {
    echo "🔧 Altbau Webspace-Only Deployment"
    echo ""
    echo "Dieses Script deployed AUSSCHLIESSLICH zu Ihrem Webspace."
    echo "Netlify wird komplett übersprungen - alle Inhalte leben nur auf Ihrem Webspace!"
    echo ""
    echo "Verwendung: $0 [deploy|setup|test|status|help]"
    echo ""
    echo "Befehle:"
    echo "  deploy  - Deploye nur zu Webspace (Netlify wird ignoriert)"
    echo "  setup   - Richte Webspace-Infrastruktur ein"
    echo "  test    - Teste SSH-Verbindung zum Webspace"
    echo "  status  - Zeige Webspace-Status und URLs"
    echo "  help    - Zeige diese Hilfe"
    echo ""
    echo "📝 Vor der ersten Verwendung:"
    echo "1. Bearbeiten Sie dieses Script und tragen Sie Ihre Webspace-Daten ein"
    echo "2. Testen Sie die Verbindung: $0 test"
    echo "3. Richten Sie die Infrastruktur ein: $0 setup"
    echo "4. Deployen Sie: $0 deploy"
    echo ""
    echo "🎯 Workflow:"
    echo "- Für lokale Tests: python3 -m http.server 8080"
    echo "- Für Webspace-Deployment: $0 deploy"
    echo "- Für automatisches Deployment über Git: verwenden Sie webhook"
}

# === HAUPTMENÜ ===
case "$1" in
    "deploy")
        deploy_to_webspace
        ;;
    "setup")
        setup_webspace_infrastructure
        ;;
    "test")
        test_connection
        ;;
    "status")
        show_deployment_status
        ;;
    "help"|"--help"|"-h"|"")
        show_help
        ;;
    *)
        echo "❓ Unbekannter Befehl: $1"
        echo ""
        show_help
        ;;
esac
