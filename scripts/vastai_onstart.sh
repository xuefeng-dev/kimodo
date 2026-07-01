#!/bin/bash
# Vast.ai 会覆盖 Docker CMD，实例启动时由此脚本拉起 Kimodo
export GRADIO_SERVER_PORT="${GRADIO_SERVER_PORT:-9550}"
export SERVER_NAME="${SERVER_NAME:-0.0.0.0}"
export GRADIO_SERVER_NAME="${GRADIO_SERVER_NAME:-0.0.0.0}"

if pgrep -f kimodo-vastai-start >/dev/null 2>&1; then
  echo "kimodo-vastai-start already running"
  exit 0
fi

nohup kimodo-vastai-start >> /var/log/kimodo.log 2>&1 &
echo "Started kimodo-vastai-start (pid $!)"
