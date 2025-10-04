# Altbau: Berlin Building Classification Tool

Ein interaktives Karten-Tool zur Klassifizierung von Gebäuden in Berlin.

## Schnellstart

- Öffnen Sie `index.html` in einem modernen Browser (Chrome, Edge, Firefox, Safari)
- Klicken Sie auf Gebäude, um sie zu klassifizieren: grün → gelb → rot → keine Markierung
- Klassifizierungen werden lokal gespeichert (Browser localStorage). Verwenden Sie Export/Import um Daten zu übertragen

## Die Funktionalität

- Lädt eine MapLibre GL Karte von Berlin
- Verwendet den Standard OpenStreetMap `building` Layer von Vector Tiles für 3D-Ausdehnungen
- Ermöglicht die Kennzeichnung von Gebäuden (via OSM `way`/`relation` ID) als:
  - grün (Faktor 1.0, volle Höhe)
  - gelb (Faktor 0.5, halbe Höhe)  
  - rot (Faktor 0.0, flach)

## Datenschutzquellen

- Standard Demo verwendet kostenlose MapTiler Tiles (Provider können gewechselt werden). Fügen Sie Ihren eigenen API-Key hinzu.

## Deployment ausschließlich zu Ihrem Webspace

Dieses Projekt ist für **Webspace-Only-Deployment** konfiguriert. Netlify wird nur als Auslöser verwendet, alle Inhalte leben ausschließlich auf **Ihrem Webspace**.

### Erste Einrichtung auf Netlify

1. **Account erstellen**
   - Gehen Sie zu [netlify.com](https://netlify.com) und erstellen Sie einen kostenlosen Account
   
2. **Webspace-Setup**
   ```bash
   # SSH-Schlüssel anzeigen (zu kopieren):
   cat ~/.ssh/webspace_deploy_altbau.pub
   
   # Kopieren Sie diesen Schlüssel zu Ihrem Webspace in ~/.ssh/authorized_keys
   ```

3. **Webspace-Deployment konfigurieren**
   ```bash
   # Bearbeiten Sie die Webspace-Daten:
   nano deploy-webspace-only.sh
   
   # Ihre Daten eintragen (Host, User, Pfad)
   ```

4. **Infrastruktur einrichten**
   ```bash
   # Test der SSH-Verbindung:
   ./deploy-webspace-only.sh test
   
   # Automatisches Setup (MySQL, API, etc.):
   ./deploy-webspace-only.sh setup
   ```

5. **Deployment zu Ihrem Webspace**
   ```bash
   # Deployt AUSSCHLIESSLICH zu Ihrem Webspace:
   ./deploy-webspace-only.sh deploy
   ```

### Netlify-Konfiguration

Das Projekt enthält bereits diese Netlify-Konfigurationsdateien:

- `netlify.toml` - Hauptkonfiguration (Build-Einstellungen, Redirects, Headers)
- `_headers` - HTTP-Header für Performance und Sicherheit  
- `_redirects` - Umleitungssystem
- `netlify/functions/` - Verzeichnis für zukünftige Serverless-Funktionen

### Webspace-Only Workflow

**Vorteile des Webspace-Only-Deployments:**
- ✅ **Ihre Domain** - alles läuft auf Ihrer eigenen Domain
- ✅ **Volle Kontrolle** - Ihr Webspace, Ihre Datenbank, Ihre Infrastruktur
- ✅ **Keine Subdomains** - keine Netlify-URLs, nur Ihre Domain
- ✅ **Datenbankintegration** - vollständige MySQL-Integration
- ✅ **SSL-Traktion** - alles über Ihr eigenes SSL-Zertifikat

**Ihr neuer Workflow:**
```bash
# 1. Code ändern
# 2. Lokal testen (optional):
python3 -m http.server 8080

# 3. Zu Ihrem Webspace deployen:
./deploy-webspace-only.sh deploy

# Ergebnis: https://IHRE-DOMAIN.de (keine Netlify-URL!)
```

### Ihre Domain ist bereits Ihr Ziel

Da alles auf Ihrem Webspace läuft, verwenden Sie **automatisch Ihre eigene Domain**:
- 🌐 **Hauptsite**: `https://IHRE-DOMAIN.de`
- 🗄️ **API-Endpunkte**: `https://IHRE-DOMAIN.de/api/labels.php`
- 📊 **Datenbank**: Läuft auf Ihrem Webspace mit MySQL

**Keine Konfiguration nötig** - Sie verwenden bereits Ihre Domain! 🎯

## Lokale Entwicklung

- Da es sich um eine statische Seite handelt, ist kein Build-Prozess erforderlich
- Für bessere Performance mit lokalen Dateien, starten Sie einen einfachen HTTP-Server:
  - Python: `python3 -m http.server 8000`
  - Node: `npx http-server -p 8000 --yes`

## Produktions-Notizen

- Ihre Klassifizierungsdaten werden unter dem Schlüssel `altbau:labels` in localStorage gespeichert
- Export erstellt eine JSON-Datei; Import akzeptiert das gleiche Format
- Alle Konfigurationen sind bereits für Netlify optimiert

## Migration von GitHub Pages

Falls Sie bisher GitHub Pages verwendet haben:

1. **GitHub Pages deaktivieren**
   - GitHub Repository → Settings → Pages → "None" als Source auswählen

2. **Netlify einrichten** (siehe oben)

3. **Vorteile der Migration**
   - Schnellere Deployment-Zeiten
   - Bessere Performance-Caching
   - HTTPS automatisch aktiviert
   - Einfache Custom Domains
   - Serverless Functions verfügbar
   - **Direkter Workflow** ohne GitHub-Zwischenschritt





