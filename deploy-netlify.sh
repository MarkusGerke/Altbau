#!/bin/bash
# Direktes Netlify-Deployment Script für Altbau
# Dieses Script deployed direkt zu Netlify ohne GitHub

# === KONFIGURATION ===
NETLIFY_SITE_ID=""  # Wird automatisch erkannt wenn Site verknüpft ist
NETLIFY_PRODUCTION_BRANCH="main"

# === FUNKTIONEN ===
function deploy_to_netlify() {
    echo "🚀 Deploye Altbau direkt zu Netlify..."
    
    # Prüfe ob Netlify CLI installiert ist
    if ! command -v netlify &> /dev/null; then
        echo "❌ Netlify CLI nicht gefunden. Installiere es mit:"
        echo "   npm install -g netlify-cli"
        exit 1
    fi
    
    # Prüfe ob angemeldet
    if ! netlify status &> /dev/null; then
        echo "❌ Nicht bei Netlify angemeldet. Führen Sie 'netlify login' aus."
        exit 1
    fi
    
    # Prüfe ob Site verknüpft ist
    if ! netlify status | grep -q "Linked to"; then
        echo "🔗 Site nicht verknüpft. Verknüpfe mit bestehender Site..."
        echo "Verfügbare Sites:"
        netlify sites:list
        echo ""
        echo "Führen Sie 'netlify link' aus um eine Site zu verknüpfen."
        exit 1
    fi
    
    # Deploye zu Netlify
    echo "📤 Deploye zu Netlify..."
    netlify deploy --prod
    
    if [ $? -eq 0 ]; then
        echo "✅ Deployment erfolgreich!"
        echo "🌐 Website verfügbar unter: $(netlify status | grep 'Live URL' | cut -d' ' -f3)"
    else
        echo "❌ Deployment fehlgeschlagen!"
        exit 1
    fi
}

function deploy_draft() {
    echo "🚀 Deploye Draft-Version zu Netlify..."
    netlify deploy
}

function show_status() {
    echo "📊 Netlify Status:"
    netlify status
}

function link_site() {
    echo "🔗 Verknüpfe mit Netlify Site..."
    netlify link
}

function create_site() {
    echo "🆕 Erstelle neue Netlify Site..."
    netlify sites:create --name altbau-$(date +%s)
}

function show_help() {
    echo "🔧 Altbau Netlify Deployment Script"
    echo ""
    echo "Verwendung: $0 [deploy|draft|status|link|create|help]"
    echo ""
    echo "Befehle:"
    echo "  deploy  - Deploye zur Produktion (Live-Site)"
    echo "  draft   - Deploye als Draft-Version"
    echo "  status  - Zeige Netlify Status"
    echo "  link    - Verknüpfe mit bestehender Netlify Site"
    echo "  create  - Erstelle neue Netlify Site"
    echo "  help    - Zeige diese Hilfe"
    echo ""
    echo "📝 Erste Einrichtung:"
    echo "1. Netlify CLI installieren: npm install -g netlify-cli"
    echo "2. Bei Netlify anmelden: netlify login"
    echo "3. Site verknüpfen: $0 link"
    echo "4. Deployen: $0 deploy"
}

# === HAUPTMENÜ ===
case "$1" in
    "deploy")
        deploy_to_netlify
        ;;
    "draft")
        deploy_draft
        ;;
    "status")
        show_status
        ;;
    "link")
        link_site
        ;;
    "create")
        create_site
        ;;
    "help"|"--help"|"-h")
        show_help
        ;;
    *)
        echo "❓ Unbekannter Befehl: $1"
        echo ""
        show_help
        ;;
esac
