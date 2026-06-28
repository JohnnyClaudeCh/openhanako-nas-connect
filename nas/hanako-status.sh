#!/bin/bash
source "$(dirname "$0")/hanako-config.sh"
PID=$(ss -tlnp | grep 14500 | grep -o 'pid=[0-9]*' | cut -d= -f2)
if [ -n "$PID" ]; then
  echo "HanaAgent is running (PID: $PID)"
  tail -3 "$HANAKO_LOG" 2>/dev/null
else
  echo "HanaAgent is not running"
fi
