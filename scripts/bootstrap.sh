#!/bin/sh
# ═══════════════════════════════════════════════════════════════════════
#  OpenClaw Railway Edition — bootstrap.sh
#  Generates openclaw.json from env vars before first boot.
#  Fixes: D-01, D-02, D-06, D-07, GT-01, GT-03, SB-01, SB-02, GW-02,
#         M-02, M-03, WS-03, SEC-01
# ═══════════════════════════════════════════════════════════════════════
set -e

CONFIG_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-$CONFIG_DIR/workspace}"

echo "[bootstrap] OpenClaw Railway Edition starting..."
echo "[bootstrap] Config dir: $CONFIG_DIR"

# ── Create all required directories ───────────────────────────────────
mkdir -p "$CONFIG_DIR"
mkdir -p "$WORKSPACE_DIR"
mkdir -p "$WORKSPACE_DIR/memory"
mkdir -p "$WORKSPACE_DIR/skills"
mkdir -p "$CONFIG_DIR/logs"
mkdir -p "$CONFIG_DIR/credentials"
mkdir -p "$CONFIG_DIR/smart-router"

# ── Touch required files that gateway expects to exist ────────────────
touch "$WORKSPACE_DIR/MEMORY.md"       2>/dev/null || true
touch "$WORKSPACE_DIR/AGENTS.md"       2>/dev/null || true
touch "$WORKSPACE_DIR/SOUL.md"         2>/dev/null || true
touch "$WORKSPACE_DIR/memory/healthcheck.md" 2>/dev/null || true

# ── GW-02: Clear stale PID from previous crash ────────────────────────
rm -f "$CONFIG_DIR/gateway.pid" 2>/dev/null || true

# ── Skip config generation if already configured ──────────────────────
if [ -f "$CONFIG_FILE" ]; then
  echo "[bootstrap] Config already exists — skipping generation."
  echo "[bootstrap] Delete $CONFIG_FILE to force regeneration."
  exec "$@"
fi

echo "[bootstrap] Generating fresh openclaw.json from environment..."

# ── Detect Railway URL for webhook mode (fixes Flaw A-03) ─────────────
WEBHOOK_CONFIG=""
if [ -n "${RAILWAY_STATIC_URL:-}" ]; then
  TELEGRAM_WEBHOOK_URL="https://${RAILWAY_STATIC_URL}/telegram/webhook"
  echo "[bootstrap] Railway URL detected: $RAILWAY_STATIC_URL"
  echo "[bootstrap] Configuring Telegram webhook mode: $TELEGRAM_WEBHOOK_URL"
  WEBHOOK_CONFIG="\"webhookUrl\": \"${TELEGRAM_WEBHOOK_URL}\","
else
  echo "[bootstrap] No RAILWAY_STATIC_URL — using long-polling mode"
fi

# ── Set allowedOrigins from Railway URL (fixes Flaw D-06) ─────────────
if [ -n "${RAILWAY_STATIC_URL:-}" ]; then
  ALLOWED_ORIGINS="[\"https://${RAILWAY_STATIC_URL}\", \"http://localhost:18789\"]"
else
  ALLOWED_ORIGINS="[\"*\"]"
fi

PRIMARY_MODEL="${OPENCLAW_MODEL:-google/gemini-2.5-flash}"

# ── Write openclaw.json ── ONLY valid upstream schema keys ────────────
cat > "$CONFIG_FILE" << EOCONFIG
{
  "agent": {
    "model": "${PRIMARY_MODEL}"
  },
  "channels": {
    "telegram": {
      "botToken": "${TELEGRAM_BOT_TOKEN:-}",
      "allowFrom": ["${TELEGRAM_ALLOWED_USER_ID:-}"],
      ${WEBHOOK_CONFIG}
      "groups": {}
    }
  },
  "gateway": {
    "bind": "0.0.0.0",
    "port": ${PORT:-18789},
    "auth": {
      "mode": "token",
      "token": "${OPENCLAW_GATEWAY_TOKEN:-}"
    },
    "trustedProxies": ["100.64.0.0/10", "10.0.0.0/8"],
    "allowedOrigins": ${ALLOWED_ORIGINS}
  },
  "agents": {
    "defaults": {
      "sandbox": {
        "mode": "off"
      },
      "heartbeat": {
        "directPolicy": "block"
      },
      "workspace": "${WORKSPACE_DIR}"
    }
  },
  "memory": {
    "flush": true
  }
}
EOCONFIG

# ── Secure the config file ────────────────────────────────────────────
chmod 600 "$CONFIG_FILE" 2>/dev/null || true

echo "[bootstrap] ✅ openclaw.json generated at $CONFIG_FILE"
echo "[bootstrap] ✅ Memory directories initialized"
echo "[bootstrap] ✅ Sandbox disabled (no Docker on Railway)"
echo "[bootstrap] ✅ Trusted proxies set for Railway CIDR"
echo "[bootstrap] ✅ Starting gateway on port ${PORT:-18789}..."

exec "$@"
