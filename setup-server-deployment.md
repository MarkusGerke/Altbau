# Server-Deployment Setup

## Was passiert:
1. Du pusht Code zu GitHub
2. GitHub Actions startet automatisch
3. GitHub verbindet sich via SSH zu deinem Server
4. Code wird automatisch auf deinem Server aktualisiert

## Setup-Schritte:

### 1. SSH-Schlüssel für Server erstellen
```bash
ssh-keygen -t ed25519 -C "server-deploy" -f ~/.ssh/server_deploy
```

### 2. Öffentlichen Schlüssel auf Server hinterlegen
```bash
# Kopiere den öffentlichen Schlüssel
cat ~/.ssh/server_deploy.pub

# Auf deinem Server:
mkdir -p ~/.ssh
echo "HIER-DEIN-ÖFFENTLICHER-SCHLÜSSEL" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### 3. GitHub Secrets konfigurieren
Gehe zu: https://github.com/MarkusGerke/Architektour/settings/secrets/actions

Füge hinzu:
- `SERVER_HOST`: dein-server.de
- `SERVER_USER`: dein-benutzername  
- `SERVER_PATH`: /pfad/zur/website/
- `SERVER_PORT`: 22
- `SERVER_SSH_KEY`: Inhalt von ~/.ssh/server_deploy (privater Schlüssel)

### 4. Git auf Server einrichten
```bash
# Auf deinem Server:
cd /pfad/zur/website/
git clone https://github.com/MarkusGerke/Architektour.git .
```

## Fertig!
Bei jedem `git push` wird automatisch auf deinem Server deployed.
