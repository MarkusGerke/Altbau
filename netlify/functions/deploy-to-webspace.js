// Netlify Function für automatisches SSH-Deployment zu Webspace
// Diese Funktion wird nach jedem Netlify-Deployment ausgeführt

const { exec } = require('child_process');
const { promisify } = require('util');
const execAsync = promisify(exec);

exports.handler = async (event, context) => {
  // Nur bei POST-Requests (Build-Hook) ausführen
  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      body: JSON.stringify({ error: 'Method not allowed' })
    };
  }

  try {
    console.log('🚀 Starte SSH-Deployment ZU WEBSPACE (Netlify wird NICHT deployed)...');
    
    // SSH-Deployment-Befehl ausführen (nur zu Webspace)
    const deployCommand = `
      # Nur zu Webspace deployen - Netlify wird übersprungen
      rsync -avz --delete \\
        -e "ssh -o StrictHostKeyChecking=no" \\
        --include='*.html' \\
        --include='*.css' \\
        --include='*.js' \\
        --include='*.php' \\
        --include='*.json' \\
        --include='_headers' \\
        --include='_redirects' \\
        --include='api/' \\
        --include='data/' \\
        --exclude='node_modules/' \\
        --exclude='.git/' \\
        --exclude='test-results/' \\
        --exclude='playwright-report/' \\
        --exclude='netlify/' \\
        --exclude='deploy-*.sh' \\
        --exclude='package*.json' \\
        ./ ${process.env.WEBSPACE_USER}@${process.env.WEBSPACE_HOST}:${process.env.WEBSPACE_PATH}
      
      # Berechtigungen setzen
      ssh -o StrictHostKeyChecking=no ${process.env.WEBSPACE_USER}@${process.env.WEBSPACE_HOST} \\
        "chmod -R 755 ${process.env.WEBSPACE_PATH}"
    `;

    await execAsync(deployCommand);
    
    console.log('✅ SSH-Deployment zu Webspace erfolgreich abgeschlossen (Netlify übersprungen)');
    
    return {
      statusCode: 200,
      body: JSON.stringify({
        success: true,
        message: 'Deployment AUSSCHLIESSLICH zu Webspace erfolgreich',
        timestamp: new Date().toISOString(),
        webspace_url: `https://${process.env.WEBSPACE_HOST}`,
        note: 'Netlify-Deployment wurde bewusst übersprungen - Webspace ist Hauptziel'
      })
    };
    
  } catch (error) {
    console.error('❌ SSH-Deployment fehlgeschlagen:', error.message);
    
    return {
      statusCode: 500,
      body: JSON.stringify({
        success: false,
        error: 'SSH-Deployment fehlgeschlagen',
        details: error.message,
        timestamp: new Date().toISOString()
      })
    };
  }
};
