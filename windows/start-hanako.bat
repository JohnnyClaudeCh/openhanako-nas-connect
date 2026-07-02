@echo off
chcp 65001 >nul
echo ========================================
echo   HanaAgent - 启动服务
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
        echo 请把 SSH 密钥放到本脚本同目录下，改名为 nas_key
        pause
        exit /b 1
    )
)

echo 正在连接 NAS ... 
ssh -p %NAS_PORT% -i "%SSH_KEY%" -o StrictHostKeyChecking=no -o ConnectTimeout=5 %NAS_USER%@%NAS_HOST% "bash /home/Agent/hanako-start.sh" 2>&1
if %ERRORLEVEL% equ 0 (
    echo.
    echo ✅ 启动成功！
) else (
    echo.
    echo ❌ 启动失败，检查 NAS 是否在线
)
echo.
pause
