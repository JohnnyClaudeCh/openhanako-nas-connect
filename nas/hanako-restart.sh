#!/bin/bash
source "$(dirname "$0")/hanako-config.sh"
PID=$(ss -tlnp | grep 14500 | grep -o 'pid=[0-9]*' | cut -d= -f2)
[ -n "$PID" ] && kill -9 $PID
sleep 2
cd "$HANAKO_DIR" && nohup npm run server > "$HANAKO_LOG" 2>&1 &
echo "HanaAgent restarted (PID: $!)"
