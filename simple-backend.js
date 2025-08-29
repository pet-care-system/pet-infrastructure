const http = require('http');
const url = require('url');
const querystring = require('querystring');

const PORT = 8000;

// 简单的CORS头和频率限制
const requestCounts = new Map();
const RATE_LIMIT_WINDOW = 60000; // 1分钟
const RATE_LIMIT_MAX = 100; // 每分钟最多100次请求

function setCORS(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Request-ID, X-Request-Time');
  res.setHeader('Access-Control-Max-Age', '86400'); // 24小时预检缓存
}

function checkRateLimit(req) {
  const clientIP = req.connection.remoteAddress || req.socket.remoteAddress || 
    (req.connection.socket ? req.connection.socket.remoteAddress : null) || 'unknown';
  
  const now = Date.now();
  const clientKey = `${clientIP}`;
  
  if (!requestCounts.has(clientKey)) {
    requestCounts.set(clientKey, { count: 1, resetTime: now + RATE_LIMIT_WINDOW });
    return true;
  }
  
  const clientData = requestCounts.get(clientKey);
  
  if (now > clientData.resetTime) {
    // 重置计数器
    clientData.count = 1;
    clientData.resetTime = now + RATE_LIMIT_WINDOW;
    return true;
  }
  
  if (clientData.count >= RATE_LIMIT_MAX) {
    return false; // 超出限制
  }
  
  clientData.count++;
  return true;
}

// 解析POST数据
function parsePostData(req) {
  return new Promise((resolve) => {
    let body = '';
    req.on('data', chunk => body += chunk.toString());
    req.on('end', () => {
      try {
        resolve(JSON.parse(body));
      } catch {
        resolve({});
      }
    });
  });
}

// 创建HTTP服务器
const server = http.createServer(async (req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const { pathname, query } = parsedUrl;
  const method = req.method;

  // 设置CORS头
  setCORS(res);
  res.setHeader('Content-Type', 'application/json');

  // 检查频率限制（放宽限制，开发环境下更友好）
  if (!checkRateLimit(req)) {
    res.writeHead(429);
    res.end(JSON.stringify({
      success: false,
      error: '请求过于频繁，请稍后再试'
    }));
    return;
  }

  // 处理OPTIONS请求
  if (method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // 路由处理
  try {
    if (method === 'GET' && pathname === '/health') {
      res.writeHead(200);
      res.end(JSON.stringify({
        status: 'OK',
        service: '宠物管理系统API',
        version: '1.0.0',
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
      }));
    }
    else if (method === 'GET' && pathname === '/api/pets') {
      res.writeHead(200);
      res.end(JSON.stringify({
        success: true,
        data: [
          { id: 1, name: '小白', type: '狗', age: 2 },
          { id: 2, name: '小黑', type: '猫', age: 1 },
          { id: 3, name: '小花', type: '兔子', age: 3 }
        ]
      }));
    }
    else if (method === 'GET' && pathname === '/api/feeding') {
      res.writeHead(200);
      res.end(JSON.stringify({
        success: true,
        data: [
          { id: 1, petId: 1, time: '2025-08-28T08:00:00Z', food: '狗粮', amount: '100g' },
          { id: 2, petId: 2, time: '2025-08-28T09:00:00Z', food: '猫粮', amount: '80g' }
        ]
      }));
    }
    else if (method === 'POST' && pathname === '/api/auth/login') {
      const body = await parsePostData(req);
      const { username, password } = body;
      
      if (username === 'admin' && password === 'password') {
        res.writeHead(200);
        res.end(JSON.stringify({
          success: true,
          token: 'demo-token-' + Date.now(),
          user: { id: 1, username: 'admin', role: 'admin' }
        }));
      } else {
        res.writeHead(401);
        res.end(JSON.stringify({
          success: false,
          error: '用户名或密码错误'
        }));
      }
    }
    else {
      res.writeHead(404);
      res.end(JSON.stringify({
        success: false,
        error: '接口不存在'
      }));
    }
  } catch (error) {
    res.writeHead(500);
    res.end(JSON.stringify({
      success: false,
      error: '服务器内部错误'
    }));
  }
});

server.listen(PORT, () => {
  console.log(`🚀 宠物管理系统API服务器运行在 http://localhost:${PORT}`);
  console.log(`📊 健康检查: http://localhost:${PORT}/health`);
  console.log(`🐾 宠物列表: http://localhost:${PORT}/api/pets`);
  console.log(`🍽️ 喂食记录: http://localhost:${PORT}/api/feeding`);
});