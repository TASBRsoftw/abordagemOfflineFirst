// Popula dados mock antes de subir os serviços
const { execSync } = require('child_process');
/*try {
  execSync('node services/mock-data.js', { stdio: 'inherit' });
} catch (e) {
  console.error('Erro ao popular mock:', e);
}*/
const { spawn } = require('child_process');
const path = require('path');

function startService(name, script, cwd = __dirname, env = {}) {
  const proc = spawn('node', [script], {
    cwd,
    env: { ...process.env, ...env },
    stdio: 'inherit',
    shell: true,
  });
  proc.on('close', code => {
    console.log(`[${name}] finalizado com código ${code}`);
  });
  console.log(`[${name}] iniciado.`);
}

// Iniciar List Service (RabbitMQ Producer)
startService('list-service', path.join('services', 'list-service', 'server.js'));

// Iniciar Consumer Log/Notification
startService('consumer-log', path.join('services', 'consumer-log', 'index.js'));

// Iniciar Consumer Analytics
startService('consumer-analytics', path.join('services', 'consumer-analytics', 'index.js'));

// (Opcional) Iniciar outros serviços se migrados para src/
// Exemplo: startService('user-service', path.join('src', 'user-service', 'server.js'));
