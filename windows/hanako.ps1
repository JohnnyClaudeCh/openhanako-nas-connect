# HanaAgent 远程管理 — PowerShell 版
# 首次使用前请先编辑 env.ps1 填入你自己的服务器信息

param([string]$cmd = "")

. "$PSScriptRoot\env.ps1"

$SSH_OPTS = @(
  "-p", "$NAS_PORT"
  "-i", "$SSH_KEY"
  "-o", "StrictHostKeyChecking=no"
  "-o", "UserKnownHostsFile=NUL"
)

$SSH_TARGET = "${NAS_USER}@${NAS_HOST}"

function run { param([string]$remoteCmd)
  & ssh $SSH_OPTS $SSH_TARGET $remoteCmd
}

switch ($cmd) {
  "start"   { run "bash $NAS_SCRIPT_DIR/hanako-start.sh" }
  "stop"    { run "bash $NAS_SCRIPT_DIR/hanako-stop.sh" }
  "restart" { run "bash $NAS_SCRIPT_DIR/hanako-restart.sh" }
  "status"  { run "bash $NAS_SCRIPT_DIR/hanako-status.sh" }
  "log"     { run "cat /tmp/hanako.log" }
  default {
    Write-Host ""
    Write-Host "===== HanaAgent NAS 管理 ====="
    Write-Host ""
    Write-Host "用法: .\hanako.ps1 <command>"
    Write-Host ""
    Write-Host "  start    启动服务"
    Write-Host "  stop     停止服务"
    Write-Host "  restart  重启服务"
    Write-Host "  status   查看状态"
    Write-Host "  log      查看日志"
    Write-Host ""
  }
}
