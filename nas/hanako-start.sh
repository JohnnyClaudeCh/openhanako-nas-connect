#!/bin/bash
source "$(dirname "$0")/hanako-config.sh"
cd "$HANAKO_DIR" && nohup npm run server > "$HANAKO_LOG" 2>&1 &
echo "HanaAgent started (PID: $!)"
