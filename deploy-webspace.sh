#!/bin/bash
# SSH-Deployment Script für Altbau Webspace
# Dieses Script kann lokal ausgeführt werden für manuelle Deployments

# === KONFIGURATION ===
# Tragen Sie hier Ihre Webspace-Daten ein:
WEBSPACE_HOST="IHRE-DOMAIN.de"           # z.B. server.example.com
WEBSPACE_USER="IHRE-BENUTZERNAME"        # z.B. webuser
WEBSPACE_PATH="/pfad/zur/website/"       # z.B. /var/www/html/
WEBSPACE_PORT="22"                       # Meist 22

# SSH-Schlüssel-Pfad
SSH_KEY="~/.ssh/webspace_deploy_altbau"

# === FUNKTIONEN ===
function deploy() {
    echo "🚀 Deploye Altbau zu $WEBSPACE_USER@$WEBSPACE_HOST:$WEBSPACE_PATH"
    
    # Prüfe ob SSH-Schlüssel existiert
    if [ ! -f "$SSH_KEY" ]; then
        echo "❌ SSH-Schlüssel nicht gefunden: $SSH_KEY"
        echo "Führen Sie zuerst 'ssh-keygen -t ed25519 -C \"webspace-deploy-altbau\" -f ~/.ssh/webspace_deploy_altbau' aus"
        exit 1
    fi
    
    # Erstelle Zielverzeichnis falls nicht vorhanden
    ssh -i "$SSH_KEY" -p $WEBSPACE_PORT $WEBSPACE_USER@$WEBSPACE_HOST "mkdir -p $WEBSPACE_PATH"
    
    # Synchronisiere Dateien (ohne node_modules, .git, etc.)
    rsync -avz --delete \
        -e "ssh -i $SSH_KEY -p $WEBSPACE_PORT" \
        --exclude='node_modules/' \
        --exclude='.git/' \
        --exclude='test-results/' \
        --exclude='playwright-report/' \
        --exclude='.github/' \
        --exclude='tests/' \
        --exclude='tests-output/' \
        --exclude='deploy-template.sh' \
        ./ $WEBSPACE_USER@$WEBSPACE_HOST:$WEBSPACE_PATH
    
    # Berechtigungen setzen
    ssh -i "$SSH_KEY" -p $WEBSPACE_PORT $WEBSPACE_USER@$WEBSPACE_HOST \
        "chmod -R 755 $WEBSPACE_PATH"
    
    echo "✅ Deployment abgeschlossen!"
    echo "🌐 Website verfügbar unter: https://$WEBSPACE_HOST"
}

function test_connection() {
    echo "🔍 Teste SSH-Verbindung..."
    ssh -i "$SSH_KEY" -p $WEBSPACE_PORT $WEBSPACE_USER@$WEBSPACE_HOST "echo '✅ Verbindung erfolgreich!'"
}

function show_public_key() {
    echo "🔑 Öffentlicher SSH-Schlüssel für Webspace-Konfiguration:"
    echo ""
    cat ~/.ssh/webspace_deploy_altbau.pub
    echo ""
    echo "📋 Kopieren Sie diesen Schlüssel und fügen Sie ihn in die authorized_keys Ihres Webspaces ein:"
    echo "   ~/.ssh/authorized_keys"
}

# === HAUPTMENÜ ===
case "$1" in
    "deploy")
        deploy
        ;;
    "test")
        test_connection
        ;;
    "key")
        show_public_key
        ;;
    *)
        echo "🔧 Altbau Webspace Deployment Script"
        echo ""
        echo "Verwendung: $0 [deploy|test|key]"
        echo ""
        echo "Befehle:"
        echo "  deploy  - Deploye das Projekt zum Webspace"
        echo "  test    - Teste die SSH-Verbindung"
        echo "  key     - Zeige den öffentlichen SSH-Schlüssel"
        echo ""
        echo "📝 Vor der ersten Verwendung:"
        echo "1. Bearbeiten Sie dieses Script und tragen Sie Ihre Webspace-Daten ein"
        echo "2. Zeigen Sie den SSH-Schlüssel an: $0 key"
        echo "3. Fügen Sie den Schlüssel zu Ihrem Webspace hinzu"
        echo "4. Testen Sie die Verbindung: $0 test"
        echo "5. Deployen Sie: $0 deploy"
        ;;
esac
