const http = require('http');

const PORT = Number(process.env.PORT || 3000);
const HEARTBEAT_TIMEOUT_MS = 45_000;
const pairs = new Map();

function sendJson(res, statusCode, body) {
  const payload = JSON.stringify(body);
  res.writeHead(statusCode, {
    'content-type': 'application/json; charset=utf-8',
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET,POST,OPTIONS',
    'access-control-allow-headers': 'content-type',
  });
  res.end(payload);
}

function readJson(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', (chunk) => {
      body += chunk;
      if (body.length > 64 * 1024) reject(new Error('request too large'));
    });
    req.on('end', () => {
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch (_) {
        reject(new Error('invalid json'));
      }
    });
    req.on('error', reject);
  });
}

function getPair(pairingCode) {
  if (!pairs.has(pairingCode)) pairs.set(pairingCode, new Map());
  return pairs.get(pairingCode);
}

function isOnline(user) {
  return Date.now() - user.lastSeen < HEARTBEAT_TIMEOUT_MS;
}

const server = http.createServer(async (req, res) => {
  const requestUrl = new URL(req.url, `http://${req.headers.host || 'localhost'}`);

  if (req.method === 'OPTIONS') return sendJson(res, 204, {});

  if (req.method === 'GET' && requestUrl.pathname === '/health') {
    return sendJson(res, 200, { ok: true });
  }

  if (req.method === 'POST' && requestUrl.pathname === '/api/heartbeat') {
    try {
      const body = await readJson(req);
      const pairingCode = String(body.pairingCode || '').trim().toUpperCase();
      const userId = String(body.userId || '').trim();
      const userName = String(body.userName || '').trim();
      if (!/^[A-Z0-9]{6}$/.test(pairingCode) || !userId || !userName) {
        return sendJson(res, 400, { error: 'pairingCode, userId and userName are required' });
      }
      getPair(pairingCode).set(userId, { userId, userName, lastSeen: Date.now() });
      return sendJson(res, 200, { ok: true });
    } catch (error) {
      return sendJson(res, 400, { error: error.message });
    }
  }

  const match = requestUrl.pathname.match(/^\/api\/pairs\/([^/]+)\/status$/);
  if (req.method === 'GET' && match) {
    const pairingCode = decodeURIComponent(match[1]).toUpperCase();
    const userId = requestUrl.searchParams.get('userId') || '';
    const users = getPair(pairingCode);
    const companionOnline = [...users.values()].some(
      (user) => user.userId !== userId && isOnline(user),
    );
    return sendJson(res, 200, { pairingCode, companionOnline });
  }

  sendJson(res, 404, { error: 'not found' });
});

setInterval(() => {
  for (const [pairingCode, users] of pairs) {
    for (const [userId, user] of users) {
      if (!isOnline(user)) users.delete(userId);
    }
    if (users.size === 0) pairs.delete(pairingCode);
  }
}, HEARTBEAT_TIMEOUT_MS);

server.listen(PORT, () => {
  console.log(`Companionship server listening on port ${PORT}`);
});
