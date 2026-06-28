/**
 * HanaAgent HTTP 代理
 * 把本地的 HTTP 请求转发到远程 HanaAgent 服务器
 *
 * 使用方法: node proxy.js
 * 然后在桌面客户端设置页填写 http://127.0.0.1:14501
 *
 * 如需修改目标地址，编辑下面的 TARGET 和 PORT 即可。
 */

// ===== 配置 - 改成你的 HanaAgent 服务器地址 =====
const TARGET = 'YOUR_NAS_IP';       // 例如 '192.168.1.100'
const PORT   = 14500;                // HanaAgent Server 端口
const LOCAL_PORT = 14501;            // 本地监听端口
// ====================================

const http = require('http');

const server = http.createServer((req, res) => {
  const options = {
    hostname: TARGET,
    port: PORT,
    path: req.url,
    method: req.method,
    headers: req.headers
  };
  const proxy = http.request(options, proxyRes => {
    res.writeHead(proxyRes.statusCode, proxyRes.headers);
    proxyRes.pipe(res, { end: true });
  });
  req.pipe(proxy, { end: true });
  proxy.on('error', () => { res.writeHead(502); res.end('proxy error'); });
});

server.listen(LOCAL_PORT, '127.0.0.1', () => {
  console.log('Proxy running: http://127.0.0.1:' + LOCAL_PORT + ' → http://' + TARGET + ':' + PORT);
});
