#!/bin/bash
# SSH-Deployment Template für Architektour
# Fülle die Variablen unten mit deinen echten Daten aus

# === HIER DEINE DATEN EINTRAGEN ===
SERVER_HOST="DEIN-SERVER.de"           # z.B. server.example.com
SERVER_USER="DEIN-BENUTZERNAME"        # z.B. webuser
SERVER_PATH="/pfad/zur/website/"       # z.B. /var/www/html/
SERVER_PORT="22"                       # Meist 22

# === DEPLOYMENT-FUNKTIONEN ===
function deploy() {
    echo "Deploye zu $SERVER_USER@$SERVER_HOST:$SERVER_PATH"
    
    # Erstelle Zielverzeichnis falls nicht vorhanden
    ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST "mkdir -p $SERVER_PATH"
    
    # Synchronisiere Dateien (ohne node_modules, .git, etc.)
    rsync -avz --delete \
        --exclude='node_modules/' \
        --exclude='.git/' \
        --exclude='test-results/' \
        --exclude='playwright-report/' \
        --exclude='.deploy-config' \
        ./ $SERVER_USER@$SERVER_HOST:$SERVER_PATH
    
    echo "Deployment abgeschlossen!"
}

function test_connection() {
    echo "Teste SSH-Verbindung..."
    ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST "echo 'Verbindung erfolgreich!'"
}

# === HAUPTMENÜ ===
case "$1" in
    "deploy")
        deploy
        ;;
    "test")
        test_connection
        ;;
    *)
        echo "Verwendung: $0 [deploy|test]"
        echo ""
        echo "1. Bearbeite dieses Script und trage deine Server-Daten ein"
        echo "2. Teste die Verbindung: $0 test"
        echo "3. Deploye: $0 deploy"
        ;;
esac
