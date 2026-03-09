#!/bin/sh
set -e

echo "[bootstrap] OpenClaw Railway Edition starting..."

CONFIG_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-$CONFIG_DIR/workspace}"

# ── Fix Railway volume ownership ──────────────────────────────────────
if [ -d "/data" ] && [ ! -w "/data" ]; then
  echo "[bootstrap] WARNING: /data not writable by uid=$(id -u). Attempting chmod..."
  chmod 777 /data 2>/dev/null || true
  install -d -m 777 /data 2>/dev/null || true
fi

# Re-check after fix attempt
if [ -w "/data" ]; then
  export OPENCLAW_STATE_DIR="/data/.openclaw"
  export OPENCLAW_WORKSPACE_DIR="/data/workspace"
  CONFIG_DIR="/data/.openclaw"
  CONFIG_FILE="$CONFIG_DIR/openclaw.json"
  WORKSPACE_DIR="/data/workspace"
  echo "[bootstrap] ✅ /data is writable — using persistent storage"
else
  echo "[bootstrap] ⚠️ /data not writable — memory will not persist across redeploys"
fi

# ── Validate required env vars ─────────────────────────────────────────
if [ -z "${TELEGRAM_BOT_TOKEN:-}" ]; then
  echo "[bootstrap] FATAL: TELEGRAM_BOT_TOKEN is not set." >&2; exit 1
fi
if [ -z "${TELEGRAM_ALLOWED_USER_ID:-}" ]; then
  echo "[bootstrap] FATAL: TELEGRAM_ALLOWED_USER_ID not set — must be a numeric ID." >&2; exit 1
fi
if [ -z "${OPENCLAW_GATEWAY_TOKEN:-}" ]; then
  echo "[bootstrap] FATAL: OPENCLAW_GATEWAY_TOKEN is not set." >&2; exit 1
fi

mkdir -p "$CONFIG_DIR"
mkdir -p "$WORKSPACE_DIR/skills"

# Copy skills if mapped in Dockerfile
if [ -d "/app/skills" ]; then
  cp -r /app/skills/* "$WORKSPACE_DIR/skills/" 2>/dev/null || true
fi

# ── Detect Webhook / Allowed Origins ──────────────────────────────────
if [ -n "${RAILWAY_STATIC_URL:-}" ]; then
  WEBHOOK_CONFIG="\"webhookUrl\": \"https://${RAILWAY_STATIC_URL}/telegram/webhook\",
      \"webhookSecret\": \"${OPENCLAW_GATEWAY_TOKEN:-changeme}\","
  ALLOWED_ORIGINS="[\"https://${RAILWAY_STATIC_URL}\", \"http://localhost:18789\"]"
else
  WEBHOOK_CONFIG=""
  ALLOWED_ORIGINS="[\"*\"]"
fi

cat > "$CONFIG_FILE" << EOCONFIG
{
  "\$schema": "openclaw",
  "update": {
    "checkOnStart": false
  },
  "channels": {
    "telegram": {
      "botToken": "${TELEGRAM_BOT_TOKEN:-}",
      "dmPolicy": "allowlist",
      "allowFrom": ["${TELEGRAM_ALLOWED_USER_ID:-}"],
      ${WEBHOOK_CONFIG}
      "groups": {}
    }
  },
  "gateway": {
    "bind": "0.0.0.0",
    "port": ${PORT:-8080},
    "auth": {
      "mode": "token",
      "token": "${OPENCLAW_GATEWAY_TOKEN:-}"
    },
    "trustedProxies": ["100.64.0.0/10", "10.0.0.0/8"],
    "allowedOrigins": ${ALLOWED_ORIGINS}
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "groq/llama-3.1-8b-instant",
        "fallbacks": [
          "openrouter/google/gemini-2.5-flash-preview-05-20:free",
          "openrouter/meta-llama/llama-3.3-70b-instruct:free",
          "openrouter/deepseek/deepseek-r1:free",
          "openrouter/google/gemini-2.5-pro-exp:free"
        ]
      },
      "sandbox": { "mode": "off" },
      "heartbeat": {
        "directPolicy": "block",
        "every": "0m"
      },
      "workspace": "${WORKSPACE_DIR}"
    }
  },
  "session": {
    "dmScope": "per-channel-peer",
    "reset": {
      "mode": "daily",
      "atHour": 4,
      "idleMinutes": 120
    }
  },
  "memory": { "flush": true }
}
EOCONFIG

echo "[bootstrap] ✅ openclaw.json generated successfully."

# ── Start Gateway ─────────────────────────────────────────────────────
export OPENCLAW_STATE_DIR="$CONFIG_DIR"
export OPENCLAW_SKIP_DOCTOR=1
export OPENCLAW_NO_RESPAWN=1

echo "[bootstrap] 🎬 Executing gateway..."
exec openclaw gateway run --allow-unconfigured
