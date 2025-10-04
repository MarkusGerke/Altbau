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

## Deployment auf Netlify + Webspace

Dieses Projekt ist für **Netlify** konfiguriert und zusätzlich für **automatisches SSH-Deployment** zu Ihrem Webspace.

### Erste Einrichtung auf Netlify

1. **Account erstellen**
   - Gehen Sie zu [netlify.com](https://netlify.com) und erstellen Sie einen kostenlosen Account
   
2. **Projekt verbinden**
   - Loggen Sie sich bei Netlify ein und klicken Sie auf "Add new site" → "Import an existing project"
   - Verbinden Sie Ihr GitHub Repository: `MarkusGerke/Altbau`
   - Oder ziehen Sie den `_site` Ordner direkt per Drag & Drop in Netlify

3. **Build-Einstellungen konfigurieren**
   ```
   Build command: (leer lassen - statisches Projekt)
   Publish directory: (leer lassen - root)
   ```

4. **Automatisches Deployment**
   - Bei jedem `git push` zu Ihrem Repository wird automatisch ein neues Deployment erstellt
   - Netlify erstellt eine eindeutige URL für Ihre Website (z.B. `https://courageous-croquembouche-123abc.netlify.app`)

### Netlify-Konfiguration

Das Projekt enthält bereits diese Netlify-Konfigurationsdateien:

- `netlify.toml` - Hauptkonfiguration (Build-Einstellungen, Redirects, Headers)
- `_headers` - HTTP-Header für Performance und Sicherheit  
- `_redirects` - Umleitungssystem
- `netlify/functions/` - Verzeichnis für zukünftige Serverless-Funktionen

### SSH-Deployment zu Webspace

Das Projekt wird **automatisch** bei jedem `git push` sowohl zu Netlify als auch zu Ihrem Webspace deployed.

#### Erste Einrichtung für Webspace-Deployment:

1. **SSH-Schlüssel auf Webspace hinterlegen**
   ```bash
   # Öffentlichen Schlüssel anzeigen:
   cat ~/.ssh/webspace_deploy_altbau.pub
   ```
   Kopieren Sie diesen Schlüssel und fügen Sie ihn in `~/.ssh/authorized_keys` auf Ihrem Webspace ein.

2. **GitHub Secrets konfigurieren**
   Gehen Sie zu: https://github.com/MarkusGerke/Altbau/settings/secrets/actions
   
   Fügen Sie diese Secrets hinzu:
   - `WEBSPACE_HOST`: Ihre Domain (z.B. `example.com`)
   - `WEBSPACE_USER`: Ihr SSH-Benutzername
   - `WEBSPACE_PATH`: Pfad zum Website-Verzeichnis (z.B. `/var/www/html/`)
   - `WEBSPACE_SSH_KEY`: Inhalt von `~/.ssh/webspace_deploy_altbau` (privater Schlüssel)

3. **Manueller Test (optional)**
   ```bash
   # Script konfigurieren:
   nano deploy-webspace.sh
   
   # Verbindung testen:
   ./deploy-webspace.sh test
   
   # Manuell deployen:
   ./deploy-webspace.sh deploy
   ```

#### Automatisches Deployment

Bei jedem `git push` zu `main`:
- ✅ **Netlify** wird automatisch aktualisiert
- ✅ **Webspace** wird automatisch via SSH aktualisiert
- ✅ Beide Deployments laufen parallel

### Custom Domain (Optional)

Um Ihre eigene Domain zu verwenden:

1. Besorgen Sie sich eine Domain
2. In Netlify Dashboard: Site settings → Domain management → Add custom domain
3. Folgen Sie den DNS-Konfigurationsanweisungen

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
   - **Doppeltes Backup**: Netlify + eigener Webspace





