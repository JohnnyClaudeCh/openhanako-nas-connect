# HanaAgent 连接配置 (PowerShell)
# 把下面这些值改成你自己的服务器信息

$NAS_HOST = "YOUR_NAS_IP"       # NAS 的 IP 或域名
$NAS_PORT = "22"                 # SSH 端口
$NAS_USER = "YOUR_USERNAME"      # SSH 用户名

# 密钥文件路径（建议放到当前文件夹，命名为 nas_key）
$SSH_KEY = Join-Path $PSScriptRoot "nas_key"

# NAS 上脚本存放路径（不用改）
$NAS_SCRIPT_DIR = "/home/$NAS_USER"
