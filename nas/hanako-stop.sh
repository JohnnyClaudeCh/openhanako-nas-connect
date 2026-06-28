#!/bin/bash
source "$(dirname "$0")/hanako-config.sh"
PID=$(ss -tlnp | grep 14500 | grep -o 'pid=[0-9]*' | cut -d= -f2)
if [ -n "$PID" ]; then
  kill -9 $PID
  echo "HanaAgent stopped"
else
  echo "HanaAgent not running"
fi
