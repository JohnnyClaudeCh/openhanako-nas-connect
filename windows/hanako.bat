@echo off
REM HanaAgent ???? ? CMD ?
REM ????????? env.bat ???????????

call "%~dp0env.bat"

set SSH_OPTS=-p %NAS_PORT% -i "%SSH_KEY%" -o StrictHostKeyChecking=no -o UserKnownHostsFile=NUL

if "%1"=="" (
  echo.
  echo ===== HanaAgent NAS ?? =====
  echo.
  echo ??: hanako [??]
  echo.
  echo   start     ????
  echo   stop      ????
  echo   restart   ????
  echo   status    ????
  echo   log       ????
  echo   logf      ??????
  echo.
  goto :eof
)

if "%1"=="start" (
  ssh %SSH_OPTS% %NAS_USER%@%NAS_HOST% "bash %NAS_SCRIPT_DIR%/hanako-start.sh"
  goto :eof
)
if "%1"=="stop" (
  ssh %SSH_OPTS% %NAS_USER%@%NAS_HOST% "bash %NAS_SCRIPT_DIR%/hanako-stop.sh"
  goto :eof
)
if "%1"=="restart" (
  ssh %SSH_OPTS% %NAS_USER%@%NAS_HOST% "bash %NAS_SCRIPT_DIR%/hanako-restart.sh"
  goto :eof
)
if "%1"=="status" (
  ssh %SSH_OPTS% %NAS_USER%@%NAS_HOST% "bash %NAS_SCRIPT_DIR%/hanako-status.sh"
  goto :eof
)
if "%1"=="log" (
  ssh %SSH_OPTS% %NAS_USER%@%NAS_HOST% "cat /tmp/hanako.log"
  goto :eof
)
if "%1"=="logf" (
  ssh %SSH_OPTS% %NAS_USER%@%NAS_HOST% "tail -f /tmp/hanako.log"
  goto :eof
)

echo ????: %1
echo ??: start, stop, restart, status, log
