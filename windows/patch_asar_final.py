"""
HanaAgent CSP Patcher — 等长二进制替换
自动检测 HanaAgent 安装路径，替换 app.asar 中的 CSP 策略。
不修改 JSON 头部，文件大小完全不变。
"""
import os, sys

def find_asar():
    """自动检测 HanaAgent 安装路径"""
    candidates = [
        os.path.expandvars(r'%LOCALAPPDATA%\Programs\HanaAgent\resources\app.asar'),
        r'C:\Program Files\HanaAgent\resources\app.asar',
        r'D:\Program Files\HanaAgent\resources\app.asar',
    ]
    for p in candidates:
        if os.path.isfile(p):
            return p
    # 如果没找到，让用户手动输入
    p = input("未自动检测到 HanaAgent，请输入 app.asar 路径: ").strip().strip('"')
    if os.path.isfile(p):
        return p
    print(f"文件不存在: {p}")
    sys.exit(1)

asar_path = find_asar()
bak_path = asar_path + '.bak'
print(f"目标: {asar_path}")

# 创建备份（如果不存在）
if not os.path.isfile(bak_path):
    import shutil
    shutil.copy2(asar_path, bak_path)
    print(f"备份已创建: {bak_path}")
else:
    print(f"使用已有备份: {bak_path}")

# 从备份恢复
with open(bak_path, 'rb') as f:
    data = bytearray(f.read())
print(f"文件大小: {len(data)} bytes")

# === 等长替换模式 ===

# Pattern 1: connection-csp.js 中的 JS 对象 (67 bytes)
old1 = b'"connect-src": ["\'self\'", "ws://127.0.0.1:*", "http://127.0.0.1:*"]'
new1 = b'"connect-src": ["\'self\'", "http:", "https:", "ws:", "wss:"        ]'

# Pattern 2/3: quick-chat.html 中的 CSP (用 connect-src 子串替换)
old_cs = b"connect-src 'self' ws://127.0.0.1:* http://127.0.0.1:*"
new_cs_pad = b"connect-src 'self' http: https: ws: wss:"
new_cs = new_cs_pad + b" " * (len(old_cs) - len(new_cs_pad))

# 长度校验
assert len(old1) == len(new1), f"P1: {len(old1)} vs {len(new1)}"
assert len(old_cs) == len(new_cs), f"CS: {len(old_cs)} vs {len(new_cs)}"

# 统计
print(f"\n模式 P1 (连接CSP.js): {data.count(old1)}x, {len(old1)} bytes")
print(f"模式 CS (HTML CSP):   {data.count(old_cs)}x, {len(old_cs)} bytes")

# 应用 P1
n1 = 0; i = 0
while True:
    i = data.find(old1, i)
    if i < 0: break
    data[i:i+len(old1)] = new1
    n1 += 1; i += len(new1)

# 应用 CS
n2 = 0; i = 0
while True:
    i = data.find(old_cs, i)
    if i < 0: break
    data[i:i+len(old_cs)] = new_cs
    n2 += 1; i += len(new_cs)

print(f"\n补丁: P1={n1}x, CS={n2}x")
print(f"新文件大小: {len(data)} bytes (不变)")

# 验证
print(f"\n验证:")
print(f"  旧 P1 残留: {data.count(old1)}x (应为0)")
print(f"  新 P1 存在: {data.count(new1)}x (应为1)")
print(f"  旧 CS 残留: {data.count(old_cs)}x (应为0)")
print(f"  新 CS 存在: {data.count(new_cs)}x (应为3)")

# 写入
with open(asar_path, 'wb') as f:
    f.write(data)

# 终验
with open(asar_path, 'rb') as f:
    v = f.read()
print(f"\n写入成功! 文件: {len(v)} bytes")
print(f"旧 P1: {v.count(old1)}x, 新 P1: {v.count(new1)}x")
print(f"\n完成! 重启 HanaAgent 后测试连接。")
