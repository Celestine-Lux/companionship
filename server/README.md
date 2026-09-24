# Companionship Server

这是 Companionship Flutter App 使用的开发服务端，提供在线心跳和配对房间状态查询。

## 环境

- Node.js 18 或更高版本
- Debian 11/12、Ubuntu 22.04+ 或 Windows 10/11

## 启动

Linux/Debian:

```bash
PORT=3000 node server.js
```

Windows PowerShell:

```powershell
$env:PORT=3000
node server.js
```

服务启动后检查：

```text
GET http://localhost:3000/health
```

## App 配置

在 App 的“设置”页面填写服务器 URL 并保存。

- Android 模拟器：`http://10.0.2.2:3000`
- Android 真机：`http://电脑局域网IP:3000`
- 已部署 HTTPS 服务：`https://你的域名`

真机和服务器必须在同一局域网，服务器防火墙需要放行 TCP 端口 3000。

## 接口

```text
GET  /health
POST /api/heartbeat
GET  /api/pairs/{pairingCode}/status?userId={userId}
```

心跳请求示例：

```json
{
  "pairingCode": "ABC234",
  "userId": "device-a",
  "userName": "小明"
}
```

当前配对码是双方共享的六位房间码。服务端在线状态保存在内存中，进程重启后会清空；45 秒未收到心跳会被视为离线。生产环境还需要 HTTPS、鉴权、限流和持久化数据库。
