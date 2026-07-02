@echo off
chcp 65001 >nul
echo ========================================
echo   HanaAgent - 停止服务
echo ========================================
echo.

set NAS_HOST=192.168.50.60
set NAS_PORT=2222
set NAS_USER=Agent
set SSH_KEY=%~dp0nas_key

if not exist "%SSH_KEY%" (
    if exist "C:\Users\%USERNAME%\Desktop\OH-WorkSpace\nas_key" (
        set SSH_KEY=C:\Users\%USERNAME%\Desktop\OH-WorkSpace\nas_key
    ) else (
        echo 找不到 nas_key 文件！
        pause
        exit /b 1
    )
)

echo 正在停止服务 ...
ssh -p %NAS_PORT% -i "%SSH_KEY%" -o StrictHostKeyChecking=no -o ConnectTimeout=5 %NAS_USER%@%NAS_HOST% "bash /home/Agent/hanako-stop.sh" 2>&1
if %ERRORLEVEL% equ 0 (
    echo ✅ 已停止
) else (
    echo ❌ 停止命令执行完毕（可能未运行中）
)
echo.
pause
