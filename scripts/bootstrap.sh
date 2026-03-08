#!/bin/sh
echo "[bootstrap] 🚀 Script started at $(date)"
# ═══════════════════════════════════════════════════════════════════════
#  OpenClaw Railway Edition — bootstrap.sh
#  Generates openclaw.json from env vars before first boot.
# ═══════════════════════════════════════════════════════════════════════
set -e

CONFIG_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-$CONFIG_DIR/workspace}"

echo "[bootstrap] OpenClaw Railway Edition starting..."

# ── Fix Railway volume ownership ──────────────────────────────────────
# Volume mounts as root:root drwxr-xr-x. Node user cannot write.
if [ -d "/data" ] && [ ! -w "/data" ]; then
  echo "[bootstrap] WARNING: /data not writable by uid=$(id -u). Attempting chown..."
  chown -R "$(id -u):$(id -g)" /data 2>/dev/null || true
  
  if [ ! -w "/data" ]; then
    echo "[bootstrap] /data still not writable — falling back to /home/node/.openclaw"
    CONFIG_DIR="/home/node/.openclaw"
    CONFIG_FILE="$CONFIG_DIR/openclaw.json"
    WORKSPACE_DIR="/home/node/workspace"
  fi
fi

echo "[bootstrap] Config dir: $CONFIG_DIR"

# ── Create all required directories ───────────────────────────────────
mkdir -p "$CONFIG_DIR"
mkdir -p "$WORKSPACE_DIR"
mkdir -p "$WORKSPACE_DIR/memory"
mkdir -p "$WORKSPACE_DIR/skills"
mkdir -p "$CONFIG_DIR/logs"
mkdir -p "$CONFIG_DIR/credentials"
mkdir -p "$CONFIG_DIR/smart-router"

# ── Touch required files ──────────────────────────────────────────────
touch "$WORKSPACE_DIR/MEMORY.md"       2>/dev/null || true
touch "$WORKSPACE_DIR/AGENTS.md"       2>/dev/null || true
if [ -f "/app/SOUL.md" ]; then cp "/app/SOUL.md" "$WORKSPACE_DIR/SOUL.md"; else touch "$WORKSPACE_DIR/SOUL.md" 2>/dev/null || true; fi
touch "$WORKSPACE_DIR/memory/healthcheck.md" 2>/dev/null || true

# ── Clear stale PID ───────────────────────────────────────────────────
rm -f "$CONFIG_DIR/gateway.pid" 2>/dev/null || true

# ── Detect Railway URL/Webhook ────────────────────────────────────────
WEBHOOK_CONFIG=""
WEBHOOK_SECRET=""
if [ -n "${RAILWAY_STATIC_URL:-}" ]; then
  TELEGRAM_WEBHOOK_URL="https://${RAILWAY_STATIC_URL}/telegram/webhook"
  WEBHOOK_SECRET=$(openssl rand -hex 16)
  echo "[bootstrap] Railway URL: $RAILWAY_STATIC_URL"
  WEBHOOK_CONFIG="\"webhookUrl\": \"${TELEGRAM_WEBHOOK_URL}\", \"webhookSecret\": \"${WEBHOOK_SECRET}\","
fi

# ── Setup Allowed Origins ─────────────────────────────────────────────
if [ -n "${RAILWAY_STATIC_URL:-}" ]; then
  ALLOWED_ORIGINS="[\"https://${RAILWAY_STATIC_URL}\", \"http://localhost:18789\"]"
else
  ALLOWED_ORIGINS="[\"*\"]"
fi

PRIMARY_MODEL="${OPENCLAW_MODEL:-google/gemini-2.5-flash}"

# ── Port configuration ────────────────────────────────────────────────
if [ -n "${PORT:-}" ] && [ "$PORT" -eq "$PORT" ] 2>/dev/null; then
  GATEWAY_PORT=$PORT
else
  GATEWAY_PORT=18789
fi

# ── Write openclaw.json (v2026 schema compliant) ───────────────────────
cat > "$CONFIG_FILE" << EOCONFIG
{
  "agents": {
    "defaults": {
      "model": "${PRIMARY_MODEL}",
      "workspace": "${WORKSPACE_DIR}",
      "sandbox": { "mode": "off" },
      "heartbeat": { "directPolicy": "block" }
    }
  },
  "channels": {
    "telegram": {
      "botToken": "${TELEGRAM_BOT_TOKEN:-}",
      "allowFrom": [$(if [ -n "$TELEGRAM_ALLOWED_USER_ID" ]; then echo "\"$TELEGRAM_ALLOWED_USER_ID\""; fi)],
      ${WEBHOOK_CONFIG}
      "groups": {}
    }
  },
  "gateway": {
    "mode": "local",
    "bind": "lan",
    "port": ${GATEWAY_PORT},
    "controlUi": {
      "enabled": true,
      "allowedOrigins": ${ALLOWED_ORIGINS},
      "dangerouslyAllowHostHeaderOriginFallback": true
    },
    "auth": {
      "mode": "token",
      "token": "${OPENCLAW_GATEWAY_TOKEN:-}"
    },
    "trustedProxies": ["100.64.0.0/10", "10.0.0.0/8"]
  }
}
EOCONFIG

chmod 600 "$CONFIG_FILE" 2>/dev/null || true
echo "[bootstrap] ✅ openclaw.json generated at $CONFIG_FILE"

# ── Start Gateway ─────────────────────────────────────────────────────
# Pass config path explicitly so openclaw doesn't fall back to default lookup.
# Using --bind lan as it's the correct enum value for the CLI.
# Export variables to ensure openclaw finds the config
export OPENCLAW_STATE_DIR="$CONFIG_DIR"
export OPENCLAW_CONFIG_PATH="$CONFIG_FILE"

# Increase memory limit to fit within Railway's 512MB plan
# 400MB is the user-requested limit for the 512MB free tier.
export NODE_OPTIONS="--max-old-space-size=400"

echo "[bootstrap] ✅ Starting gateway on port ${PORT:-8080}..."

# Start the gateway
# Use node directly with full path to ensure it's found regardless of PATH setup.
export OPENCLAW_SKIP_DOCTOR=1
echo "[bootstrap] 🎬 Executing gateway..."
exec node /app/openclaw.mjs gateway run \
  --bind 0.0.0.0 \
  --port "${PORT:-18789}" \
  --allow-unconfigured
