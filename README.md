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

## Deployment direkt zu Netlify

Dieses Projekt ist für **direktes Netlify-Deployment** konfiguriert - ohne GitHub als Zwischenschritt.

### Erste Einrichtung auf Netlify

1. **Account erstellen**
   - Gehen Sie zu [netlify.com](https://netlify.com) und erstellen Sie einen kostenlosen Account
   
2. **Netlify CLI installieren**
   ```bash
   npm install -g netlify-cli
   ```

3. **Bei Netlify anmelden**
   ```bash
   netlify login
   ```

4. **Site erstellen oder verknüpfen**
   ```bash
   # Neue Site erstellen:
   ./deploy-netlify.sh create
   
   # Oder mit bestehender Site verknüpfen:
   ./deploy-netlify.sh link
   ```

5. **Direktes Deployment**
   ```bash
   # Produktions-Deployment:
   ./deploy-netlify.sh deploy
   
   # Oder Draft-Version testen:
   ./deploy-netlify.sh draft
   ```

### Netlify-Konfiguration

Das Projekt enthält bereits diese Netlify-Konfigurationsdateien:

- `netlify.toml` - Hauptkonfiguration (Build-Einstellungen, Redirects, Headers)
- `_headers` - HTTP-Header für Performance und Sicherheit  
- `_redirects` - Umleitungssystem
- `netlify/functions/` - Verzeichnis für zukünftige Serverless-Funktionen

### Workflow ohne GitHub

**Vorteile des direkten Netlify-Deployments:**
- ✅ **Kein GitHub-Zwischenschritt** - direkter Push zu Netlify
- ✅ **Schnellere Deployments** - keine Wartezeit auf GitHub Actions
- ✅ **Einfachere Konfiguration** - weniger Abhängigkeiten
- ✅ **Lokale Kontrolle** - Sie entscheiden wann deployed wird
- ✅ **Draft-Versionen** - Testen vor Live-Schaltung möglich

**Typischer Workflow:**
```bash
# 1. Code ändern
# 2. Testen (optional)
./deploy-netlify.sh draft

# 3. Live-Deployment
./deploy-netlify.sh deploy
```

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
   - **Direkter Workflow** ohne GitHub-Zwischenschritt





