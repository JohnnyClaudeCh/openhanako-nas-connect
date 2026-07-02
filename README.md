# openhanako-nas-connect

[![English](https://img.shields.io/badge/🌐_English-0077B5?style=for-the-badge&logo=github)](README.md) [![中文](https://img.shields.io/badge/🌐_中文-FF6F00?style=for-the-badge&logo=github)](README.zh-CN.md)

Connect your HanaAgent desktop client to a LAN NAS server — CSP patch + HTTP Proxy + Remote Management.

> **HanaAgent**: [liliMozi/openhanako](https://github.com/liliMozi/openhanako) — Open-source desktop AI assistant
>
> **Companion repo**: If you haven't deployed HanaAgent Server on your NAS yet, start with [`openhanako-nas-deploy`](https://github.com/JohnnyClaudeCh/openhanako-nas-deploy) first.

---

## The Problem

HanaAgent's desktop client (Electron) runs locally by default. Connecting to a remote NAS server faces two barriers:

### 1. CSP Policy (Core Issue)

The renderer process's `connection-csp.js` only allows `127.0.0.1` in `connect-src`, blocking direct connections to NAS IPs (e.g. `192.168.50.60:14500`).

A dynamic workaround exists via `readPersistedConnectionSources()`, but it has a chicken-and-egg problem: can't connect → can't persist to localStorage → CSP doesn't allow → can't connect.

### 2. settings.html Whitelist

The `server/routes/mobile-static.ts` whitelist doesn't include `settings.html`, so accessing the settings page in browser returns 404.

---

## File Structure

```
openhanako-nas-connect/
├── nas/                            # → Copy to your NAS
│   ├── hanako-config.sh            #   Config template (edit before use)
│   ├── hanako.service              #   systemd auto-start service
│   ├── hanako-start.sh             #   Start server
│   ├── hanako-stop.sh              #   Stop server
│   ├── hanako-restart.sh           #   Restart server
│   ├── hanako-status.sh            #   Check status
│   └── patch_static.js             #   P0: settings page whitelist patch
├── windows/                        # → Run on Windows
│   ├── env.bat                     #   Connection config (CMD)
│   ├── env.ps1                     #   Connection config (PowerShell)
│   ├── patch_asar_final.py         #   CSP binary patch (asar)
│   ├── proxy.js                    #   HTTP proxy (alternative)
│   ├── hanako.bat                  #   Remote management (CMD)
│   └── hanako.ps1                  #   Remote management (PowerShell)
└── README.md
```

---

## Usage

### Method A: Patch app.asar (Recommended)

1. Close HanaAgent desktop client
2. Run `python windows\patch_asar_final.py`
3. Restart HanaAgent
4. Go to settings page, add your NAS address

### Method B: HTTP Proxy

```bash
node windows/proxy.js
```

In the desktop client settings, enter `http://127.0.0.1:14501` (proxy address — no CSP issue since it's same-origin)

### NAS Side Setup

Edit `nas/hanako-config.sh` with your actual HanaAgent path:

```bash
HANAKO_DIR="/vol1/1000/Hanako"    # HanaAgent source directory
HANAKO_LOG="/tmp/hanako.log"       # Log file path
```

Edit `nas/hanako.service` and change `User=` to your NAS username.

#### Step 1: Settings Page Whitelist

```bash
node nas/patch_static.js
```

#### Step 2: Deploy HanaAgent Server

```bash
git clone <your-hanagent-repo> /vol1/1000/Hanako
cd /vol1/1000/Hanako
npm install
npm run build:client
```

#### Step 3: systemd Auto-start

```bash
sudo cp nas/hanako.service /etc/systemd/system/
sudo systemctl enable hanako
sudo systemctl start hanako
sudo systemctl status hanako
```

#### Step 4: Verification

| Check | Method | Expected |
|-------|--------|----------|
| Web UI | Open `http://your-nas:14500/desktop/` in browser | HanaAgent chat interface |
| Settings | Open `http://your-nas:14500/desktop/settings.html` | Settings page |
| Desktop connect | Connect to NAS address in desktop client settings | Connection successful |

---

## Remote Management

Manage your HanaAgent desktop client remotely from Windows:

```bash
hanako status       # Check status
hanako log          # View logs
hanako restart      # Restart
hanako stop         # Stop
hanako start        # Start
```

First edit `nas/hanako-config.sh` and `windows/env.ps1` with your server info:

```bash
NAS_HOST="192.168.1.100"           # NAS IP address
NAS_USER="agent"                   # SSH username
SSH_PORT="2222"                    # SSH port (non-standard)
SSH_KEY="C:\path\to\your_key"     # SSH private key path
```

> Windows: `.bat` files must be double-clicked or invoked via `hanako` command. PowerShell scripts require `.\hanako.ps1`.

---

## How It Works

### CSP Patch (`patch_asar_final.py`)

HanaAgent uses Electron's `contextIsolation: true` security mode. In this mode:
- `--disable-web-security` is intercepted by the framework — it doesn't work
- The only way is to directly modify `connection-csp.js` inside `app.asar`

The script changes `connect-src` from `127.0.0.1` only to allowing all `http:` / `https:` / `ws:` / `wss:` origins.

### Whitelist Patch (`patch_static.js`)

Modifies `mobile-static.ts` on the HanaAgent Server to add `settings.html` to the `safeRelativePath` whitelist.

---

## Notes

- **SSH keys**: Generate a dedicated key pair for HanaAgent (`ssh-keygen`). Don't reuse your existing keys.
- **asar JSON header**: Don't re-serialize with `json.dumps` — HanaAgent will crash. Must use binary in-place replacement.
- **`--disable-web-security`**: Ineffective on Electron 21+ under HanaAgent's framework (`contextIsolation: true` in `main.cjs`). Direct `app.asar` CSP modification is the only working approach.
