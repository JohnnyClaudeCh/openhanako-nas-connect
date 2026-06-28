# Hanako-NAS-Connect

将 HanaAgent 桌面客户端连接到局域网 NAS 服务器 —— CSP 补丁 + HTTP 代理 + 远程管理。

> **HanaAgent**: [liliMozi/openhanako](https://github.com/liliMozi/openhanako) — 开源桌面 AI 助手
>
> **配套仓库**: 如果还没有在 NAS 上部署 HanaAgent Server，先看 `Hanako-NAS-Deploy` 完成服务端搭建。

---

## 📋 快速导航

- [背景](#背景)
- [你需要准备的](#你需要准备的)
- [文件结构](#文件结构)
- [部署步骤](#部署步骤)
  - [① 配置你的信息](#①-配置你的信息)
  - [② NAS 端部署](#②-nas-端部署)
  - [③ Windows 桌面端 CSP 补丁](#③-windows-桌面端-csp-补丁)
  - [④ 验证](#④-验证)
- [日常管理](#日常管理)
- [升级后恢复](#升级后恢复)
- [附录：文件说明](#附录文件说明)

---

## 背景

HanaAgent 桌面客户端（Electron）默认只能本地运行，连接到远程 NAS 服务器时有两个障碍：

1. **设置页白名单缺失** — Web 设置页面（`settings.html`）被路由拦截，返回 404
2. **CSP 限制** — Electron 只允许连接 `127.0.0.1`，阻止向 NAS 发请求
3. **NAS 重启后无自启** — 服务不会自动恢复

本仓库提供最小侵入式补丁，不破坏 HanaAgent 源码结构。

---

## 你需要准备的

| 项目 | 说明 | 可选？ |
|------|------|--------|
| 一台 Linux NAS 或服务器 | 运行 HanaAgent Server | ❌ 必须 |
| 一台 Windows 电脑 | 运行 HanaAgent 桌面客户端 | ❌ 必须 |
| SSH 密钥 | 用于从 Windows 免密登录 NAS | ⚠️ 管理脚本需要 |
| Node.js ≥18 | NAS 上运行 HanaAgent | ❌ 必须 |
| Python 3 | Windows 上运行 CSP 补丁 | ❌ 必须 |

---

## 文件结构

```
Hanako-NAS-Connect/
├── README.md                       ← 本文件
├── .gitignore
├── nas/                            # → 丢到 NAS 上
│   ├── hanako-config.sh            #   NAS 配置（编辑填入路径）
│   ├── patch_static.js             #   设置页白名单补丁
│   ├── hanako.service              #   systemd 自启服务
│   ├── hanako-start.sh             #   启动
│   ├── hanako-stop.sh              #   停止
│   ├── hanako-restart.sh           #   重启
│   └── hanako-status.sh            #   状态检查
└── windows/                        # → 在 Windows 上使用
    ├── env.bat                     #   配置（编辑填入 NAS 信息）⚠️ 先改这里！
    ├── env.ps1                     #   配置 (PowerShell 版)
    ├── patch_asar_final.py         #   CSP 等长替换补丁
    ├── proxy.js                    #   HTTP 代理（备选方案）
    ├── hanako.bat                  #   远程管理脚本 (CMD)
    └── hanako.ps1                  #   远程管理脚本 (PowerShell)
```

---

## 部署步骤

### ① 配置你的信息 ⚠️ 第一步要做

> 💡 **还没在 NAS 上装 HanaAgent？** 先看 `Hanako-NAS-Deploy` —— 从零搭建服务端，包括环境安装、模型配置、用户认证、自启服务。

#### Windows 端

编辑 `windows/env.bat`（或 `windows/env.ps1`），把其中 4 个值改成你自己的：

```
NAS_HOST      → 你的 NAS IP 或域名（如 192.168.1.100）
NAS_PORT      → SSH 端口（默认 22，非标端口如 2222）
NAS_USER      → SSH 用户名（如 Agent）
SSH_KEY       → 密钥文件路径（默认找同目录下的 nas_key）
```

> 💡 **密钥文件**：将你的 SSH 私钥复制到 `windows/nas_key`。`env.bat` 默认会找这个位置。**不要提交密钥到 GitHub！**

#### NAS 端

编辑 `nas/hanako-config.sh`，把 HanaAgent 的安装路径改为你的实际路径：

```
HANAKO_DIR    → HanaAgent 源码目录（如 /vol1/1000/Hanako）
HANAKO_LOG    → 日志文件路径（如 /tmp/hanako.log）
```

编辑 `nas/hanako.service`，把 `User=` 改为你的 NAS 用户名。

---

### ② NAS 端部署

#### 步骤 1：基础环境

登录 NAS，确认 Node.js 已安装：

```bash
node --version    # 需要 ≥18
npm --version
```

#### 步骤 2：部署 HanaAgent Server

```bash
# 将 HanaAgent 代码克隆或上传到 NAS
git clone <你的HanaAgent仓库> /vol1/1000/Hanako
cd /vol1/1000/Hanako
npm install
npm run build          # 构建前端
npm run server         # 启动测试
```

访问 `http://你的NAS地址:14500/desktop/`，应看到 HanaAgent 界面。
按 Ctrl+C 停止临时服务。

#### 步骤 3：设置页白名单补丁

把 `nas/` 目录全部上传到 NAS，然后执行：

```bash
node /path/to/nas/patch_static.js
```

> **原理**：这个脚本把 `settings.html` 加入 HanaAgent 静态文件路由的白名单，否则它返回 404。
>
> 如果提示找不到文件，检查脚本里的路径 `/vol1/1000/Hanako/server/routes/mobile-static.ts`
> 是否是你的实际路径。如果不同，直接改 `patch_static.js` 里的路径即可。

验证：

```bash
curl http://localhost:14500/desktop/settings.html
# 应返回 200（HTML 内容）
```

#### 步骤 4：systemd 自启

```bash
sudo cp /path/to/nas/hanako.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable hanako
sudo systemctl start hanako
```

验证：

```bash
sudo systemctl status hanako
# 应显示 active (running)
```

---

### ③ Windows 桌面端 CSP 补丁

> **问题**：HanaAgent 桌面客户端内置的安全策略（CSP）只允许连接 `127.0.0.1`，连接到 NAS 时会报 `Failed to fetch`。
>
> **解决**：用本补丁替换 `app.asar` 中的 CSP 规则，放行所有地址。

确保 HanaAgent 桌面客户端已关闭：

```powershell
taskkill /F /IM HanaAgent.exe
```

运行补丁脚本：

```powershell
python windows/patch_asar_final.py
```

脚本会自动：
1. 检测 HanaAgent 安装路径（扫描常见目录）
2. 首次运行自动创建 `app.asar.bak` 备份
3. 等长替换 CSP 字符串（文件大小不变）
4. 写入补丁后的 `app.asar`

重新启动 HanaAgent 桌面客户端。

> **如果补丁后客户端打不开？** 恢复备份：把 `app.asar.bak` 改回 `app.asar`，然后检查 Python 版本（需要 3.x）。

**备选方案**：如果 CSP 补丁不好使，可以用 HTTP 代理。

先编辑 `windows/proxy.js`，把 `YOUR_NAS_IP` 改成你的 NAS 地址，然后：

```bash
node windows/proxy.js
# 输出: Proxy running: http://127.0.0.1:14501 → http://你的NAS:14500
```

在桌面客户端设置页填 `http://127.0.0.1:14501` 即可。

---

### ④ 验证

| 测试项 | 方法 | 预期结果 |
|--------|------|---------|
| Web UI | 浏览器打开 `http://你的NAS:14500/desktop/` | HanaAgent 聊天界面 |
| 设置页 | 浏览器打开 `http://你的NAS:14500/desktop/settings.html` | 设置页面 |
| 桌面连接 | 桌面客户端 → 设置 → 访问与设备 → 输入 NAS 地址 | 连接成功 |
| API 连通 | `curl -X POST http://你的NAS:14500/api/web-auth/login -H "Content-Type: application/json" -d '{"credential":"你的凭据"}'` | 返回 `{"ok":true,...}` |

---

## 日常管理

### 从 Windows 管理 NAS 服务

```powershell
# PowerShell
.\hanako.ps1 status       # 查看状态
.\hanako.ps1 log          # 查看日志
.\hanako.ps1 restart      # 重启
```

```cmd
:: CMD
hanako status
hanako log
hanako restart
```

### 直接 SSH

```bash
ssh -p 你的SSH端口 -i 你的密钥 用户名@NAS地址 "sudo systemctl status hanako"
ssh -p 你的SSH端口 -i 你的密钥 用户名@NAS地址 "tail -20 /tmp/hanako.log"
```

### 桌面客户端

直接启动 HanaAgent.exe 即可。

---

## 升级后恢复

| 组件 | 更新后丢失 | 恢复方法 |
|------|-----------|---------|
| NAS 设置页白名单 | `patch_static.js` 的修改会被覆盖 | 重新执行 `node patch_static.js` |
| 桌面 CSP 补丁 | `app.asar` 被新版替换 | 重新执行 `python windows/patch_asar_final.py` |

一键恢复桌面端：

```powershell
taskkill /F /IM HanaAgent.exe
python windows/patch_asar_final.py
# 然后手动启动 HanaAgent
```

---

## 附录：文件说明

### `nas/patch_static.js`
将 `settings.html` 加入 HanaAgent Server 的静态文件白名单。修改 `mobile-static.ts` 中的 `safeRelativePath()` 函数。

### `nas/hanako.service`
systemd 服务配置。确保 NAS 重启后 HanaAgent 自动启动。

### `windows/patch_asar_final.py`
核心补丁脚本。使用**等长二进制替换**修改 `app.asar` 中的 CSP 规则：

| 位置 | 变更 |
|------|------|
| `connection-csp.js` | `ws://127.0.0.1:* http://127.0.0.1:*` → `http: https: ws: wss:` |
| `quick-chat.html` ×2 | 同上 |

技术要点：替换前后字节数完全相同（67 bytes / 203 bytes），不修改 asar 的 JSON 索引头部，避免渲染进程崩溃。

### `windows/proxy.js`
HTTP 代理，将 `127.0.0.1` 的请求转发到 NAS。备选方案，用于 CSP 补丁不可用时。

### `windows/hanako.bat` / `hanako.ps1`
Windows 端 NAS 管理脚本。通过 SSH 执行远程命令。首次使用前需编辑 `env.bat` / `env.ps1` 填好你的 NAS 信息。

---

## ⚠️ 安全提醒

- **不要**把 SSH 密钥、密码、API Key 提交到 GitHub
- `env.bat` 和 `env.ps1` 只存 IP/端口/用户名，不存密码
- SSH 密钥建议用 `ssh-keygen` 单独生成一份给 HanaAgent 使用，不要用你现有的密钥

---

## 踩坑记录

### asar JSON 头部不可重新序列化
用 `json.dumps` 重新序列化 asar 的 JSON 索引头部后，HanaAgent 拒绝启动。必须用等长替换，保证文件大小完全不变。

### Electron `--disable-web-security` 无效
HanaAgent 框架覆盖了该设置。只能直接修改 `app.asar` 中的 CSP 策略。

### Windows CMD 不能执行 `./script` 形式
`.bat` 文件必须双击或用 `hanako` 命令调用。PowerShell 脚本需 `.\hanako.ps1`。
