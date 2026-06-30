#!/usr/bin/env bash
set -euo pipefail

# Vast.ai 单容器启动入口：先启动 text encoder，再启动 Web GUI。
export HF_ENDPOINT="${HF_ENDPOINT:-https://huggingface.co}"
export HF_HOME="${HF_HOME:-/workspace/.cache/huggingface}"
export TEXT_ENCODERS_DIR="${TEXT_ENCODERS_DIR:-/workspace/text_encoders}"
export GRADIO_SERVER_NAME="${GRADIO_SERVER_NAME:-0.0.0.0}"
export GRADIO_SERVER_PORT="${GRADIO_SERVER_PORT:-9550}"
export TEXT_ENCODER_MODE="${TEXT_ENCODER_MODE:-api}"
export TEXT_ENCODER_URL="${TEXT_ENCODER_URL:-http://127.0.0.1:${GRADIO_SERVER_PORT}/}"
export LOCAL_CACHE="${LOCAL_CACHE:-True}"
export SERVER_NAME="${SERVER_NAME:-0.0.0.0}"
export SERVER_PORT="${SERVER_PORT:-7860}"

TEXT_ENCODER_PID=""
DEMO_PID=""

cleanup() {
  if [[ -n "${DEMO_PID}" ]] && kill -0 "${DEMO_PID}" >/dev/null 2>&1; then
    kill "${DEMO_PID}" >/dev/null 2>&1 || true
  fi

  if [[ -n "${TEXT_ENCODER_PID}" ]] && kill -0 "${TEXT_ENCODER_PID}" >/dev/null 2>&1; then
    kill "${TEXT_ENCODER_PID}" >/dev/null 2>&1 || true
  fi

  wait >/dev/null 2>&1 || true
}

trap cleanup EXIT
trap 'exit 143' INT TERM

mkdir -p "${HF_HOME}" "${TEXT_ENCODERS_DIR}"

echo "Starting Kimodo text encoder on ${GRADIO_SERVER_NAME}:${GRADIO_SERVER_PORT}..."
kimodo_textencoder &
TEXT_ENCODER_PID="$!"

TEXT_ENCODER_WAIT_RETRIES="${TEXT_ENCODER_WAIT_RETRIES:-120}"
for attempt in $(seq 1 "${TEXT_ENCODER_WAIT_RETRIES}"); do
  if curl -fsS "${TEXT_ENCODER_URL}" >/dev/null 2>&1; then
    echo "Text encoder is ready."
    break
  fi

  if ! kill -0 "${TEXT_ENCODER_PID}" >/dev/null 2>&1; then
    echo "Text encoder exited before becoming ready." >&2
    wait "${TEXT_ENCODER_PID}"
    exit 1
  fi

  if [[ "${attempt}" == "${TEXT_ENCODER_WAIT_RETRIES}" ]]; then
    echo "Timed out waiting for text encoder at ${TEXT_ENCODER_URL}." >&2
    exit 1
  fi

  sleep 2
done

echo "Starting Kimodo Web GUI on ${SERVER_NAME}:${SERVER_PORT}..."
kimodo_demo &
DEMO_PID="$!"

set +e
wait "${DEMO_PID}"
STATUS="$?"
set -e

exit "${STATUS}"
