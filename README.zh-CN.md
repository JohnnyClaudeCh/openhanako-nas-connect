# openhanako-nas-connect

[![English](https://img.shields.io/badge/🌐_English-0077B5?style=for-the-badge&logo=github)](README.md) [![中文](https://img.shields.io/badge/🌐_中文-FF6F00?style=for-the-badge&logo=github)](README.zh-CN.md)

将 HanaAgent 桌面客户端连接到局域网 NAS 服务器 —— CSP 补丁 + HTTP 代理 + 远程管理。

> **HanaAgent**: [liliMozi/openhanako](https://github.com/liliMozi/openhanako) — 开源桌面 AI 助手
>
> **配套仓库**: 如果还没有在 NAS 上部署 HanaAgent Server，先看 [`openhanako-nas-deploy`](https://github.com/JohnnyClaudeCh/openhanako-nas-deploy) 完成服务端搭建。

---

## 解决的问题

HanaAgent 桌面客户端（Electron）默认只能本地运行，连接到远程 NAS 服务器时有两个障碍：

### 1. CSP 策略限制（核心）

桌面客户端渲染进程的 `connection-csp.js` 仅放行了 `127.0.0.1`，无法直连 NAS（如 `192.168.50.60:14500`）。

虽然有 `readPersistedConnectionSources()` 动态添加机制，但存在鸡生蛋问题：连不上→存不到 localStorage→CSP 不放行→连不上。

### 2. settings.html 白名单

`server/routes/mobile-static.ts` 的白名单未包含 `settings.html`，浏览器访问设置页会返回 404。

---

## 文件结构

```
openhanako-nas-connect/
├── nas/                            # → 丢到 NAS 上执行
│   ├── hanako-config.sh            #   配置模板，用户改
│   ├── hanako.service              #   systemd 自启服务
│   ├── hanako-start.sh             #   启动
│   ├── hanako-stop.sh              #   停止
│   ├── hanako-restart.sh           #   重启
│   ├── hanako-status.sh            #   状态检查
│   └── patch_static.js             #   P0: 设置页白名单补丁
├── windows/                        # → 在 Windows 上执行
│   ├── env.bat                     #   连接配置 (CMD)
│   ├── env.ps1                     #   连接配置 (PowerShell)
│   ├── patch_asar_final.py         #   CSP 等长替换补丁
│   ├── proxy.js                    #   HTTP 代理（备选）
│   ├── hanako.bat                  #   远程管理脚本 (CMD)
│   └── hanako.ps1                  #   远程管理脚本 (PowerShell)
└── README.md
```

---

## 使用说明

### 方式 A：直接修改 app.asar（推荐）

1. 关闭 HanaAgent 桌面客户端
2. 运行 `python windows\patch_asar_final.py`
3. 重启 HanaAgent
4. 进入设置页，添加 NAS 地址

### 方式 B：HTTP 代理

```bash
node windows/proxy.js
```

桌面客户端设置页填入 `http://127.0.0.1:14501`（代理地址，同源无 CSP 问题）

### NAS 端设置页

编辑 `nas/hanako-config.sh`，把 HanaAgent 的安装路径改为你的实际路径：

```bash
HANAKO_DIR="/vol1/1000/Hanako"    # HanaAgent 源码目录
HANAKO_LOG="/tmp/hanako.log"       # 日志文件路径
```

编辑 `nas/hanako.service`，把 `User=` 改为你的 NAS 用户名。

#### 步骤 1：设置页白名单

```bash
node nas/patch_static.js
```

#### 步骤 2：部署 HanaAgent Server

```bash
# 将 HanaAgent 代码克隆或上传到 NAS
git clone <你的HanaAgent仓库> /vol1/1000/Hanako
cd /vol1/1000/Hanako
npm install
npm run build:client
```

#### 步骤 3：systemd 自启

```bash
sudo cp nas/hanako.service /etc/systemd/system/
sudo systemctl enable hanako
sudo systemctl start hanako
sudo systemctl status hanako
```

#### 步骤 4：验证

| 检查项 | 方法 | 预期 |
|--------|------|------|
| Web UI | 浏览器打开 `http://你的NAS:14500/desktop/` | HanaAgent 聊天界面 |
| 设置页 | 浏览器打开 `http://你的NAS:14500/desktop/settings.html` | 设置页面 |
| 桌面连接 | 桌面客户端设置页连接 NAS 地址 | 连接成功 |

---

## 远程管理

对 Windows 电脑上的 HanaAgent 进行日常管理：

```bash
hanako status       # 查看状态
hanako log          # 查看日志
hanako restart      # 重启
hanako stop         # 停止
hanako start        # 启动
```

需要先编辑 `nas/hanako-config.sh` 和 `windows/env.ps1` 填入你的服务器信息：

```bash
NAS_HOST="192.168.1.100"           # NAS 地址
NAS_USER="agent"                   # SSH 用户名
SSH_PORT="2222"                    # SSH 端口（非标端口）
SSH_KEY="C:\path\to\your_key"   # SSH 私钥路径
```

> Windows 用户：`.bat` 文件必须双击或用 `hanako` 命令调用。PowerShell 脚本需 `.\hanako.ps1`。

---

## 原理

### CSP 补丁 (`patch_asar_final.py`)

HanaAgent 桌面客户端使用 Electron 的 `contextIsolation: true` 安全模式，该模式下：
- `--disable-web-security` 启动参数被框架接管，无法绕过
- 只能在 `app.asar` 中直接修改 `connection-csp.js` 的 CSP 策略

脚本将 `connect-src` 从仅限 `127.0.0.1` 改为放行所有 `http:` / `https:` / `ws:` / `wss:` 源。

### 白名单补丁 (`patch_static.js`)

修改 HanaAgent Server 的 `mobile-static.ts`，将 `settings.html` 加入 `safeRelativePath` 白名单。

---

## 注意

- SSH 密钥建议用 `ssh-keygen` 单独生成一份给 HanaAgent 使用，不要用你现有的密钥
- asar JSON 头部不可重新序列化：用 `json.dumps` 重新序列化 asar 的 JSON 索引头部后，HanaAgent 会直接崩溃。必须用二进制等长替换
- `--disable-web-security` 在 Electron 21+ 的 HanaAgent 框架中已失效：`main.cjs` 的 `webPreferences` 设了 `contextIsolation: true`，HanaAgent 框架覆盖了该设置。只能直接修改 `app.asar` 中的 CSP 策略
