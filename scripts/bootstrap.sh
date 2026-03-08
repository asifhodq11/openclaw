#!/bin/sh
# ═══════════════════════════════════════════════════════════════════════
#  OpenClaw Railway Edition — bootstrap.sh
#  Generates openclaw.json from env vars before first boot.
#  Fixes: D-01, D-06, D-07, D-08, F-01→F-09, M-02, M-03, SEC-01, SEC-03
#
#  IMPORTANT: This file is NEVER referenced by android-setup.sh
#  and android-setup.sh is NEVER referenced here (zero Railway impact).
# ═══════════════════════════════════════════════════════════════════════
set -e

CONFIG_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-$CONFIG_DIR/workspace}"

echo "[bootstrap] OpenClaw Railway Edition starting..."
echo "[bootstrap] Config dir: $CONFIG_DIR"

# ── F-02: Create all required directories ─────────────────────────────
mkdir -p "$CONFIG_DIR"
mkdir -p "$WORKSPACE_DIR"
mkdir -p "$WORKSPACE_DIR/memory"
mkdir -p "$WORKSPACE_DIR/skills"
mkdir -p "$CONFIG_DIR/logs"
mkdir -p "$CONFIG_DIR/credentials"

# ── F-02: Touch required files that gateway expects to exist ──────────
touch "$WORKSPACE_DIR/MEMORY.md" 2>/dev/null || true
touch "$WORKSPACE_DIR/AGENTS.md" 2>/dev/null || true
touch "$WORKSPACE_DIR/memory/healthcheck.md" 2>/dev/null || true

# ── Skip if already configured (preserve existing config on redeploy) ─
if [ -f "$CONFIG_FILE" ]; then
  echo "[bootstrap] Config already exists — skipping generation."
  echo "[bootstrap] Delete $CONFIG_FILE to regenerate from env vars."
  exec "$@"
fi

echo "[bootstrap] Generating fresh openclaw.json from environment..."

# ── F-08: Detect Railway URL for webhook mode (fixes Flaw A-03) ───────
WEBHOOK_CONFIG=""
if [ -n "${RAILWAY_STATIC_URL:-}" ]; then
  TELEGRAM_WEBHOOK_URL="https://${RAILWAY_STATIC_URL}/telegram/webhook"
  echo "[bootstrap] Railway URL detected: $RAILWAY_STATIC_URL"
  echo "[bootstrap] Configuring Telegram webhook mode: $TELEGRAM_WEBHOOK_URL"
  WEBHOOK_CONFIG="\"webhookUrl\": \"${TELEGRAM_WEBHOOK_URL}\","
else
  echo "[bootstrap] No RAILWAY_STATIC_URL — using long-polling mode"
fi

# ── F-05: Set allowedOrigins from Railway URL (fixes Flaw D-06) ───────
if [ -n "${RAILWAY_STATIC_URL:-}" ]; then
  ALLOWED_ORIGINS="[\"https://${RAILWAY_STATIC_URL}\", \"http://localhost:18789\"]"
else
  ALLOWED_ORIGINS="[\"*\"]"
fi

# ── Build the model config section ────────────────────────────────────
# Primary: OpenRouter with confirmed-working Gemini model
# Falls back via OpenRouter's own routing to other free models
PRIMARY_MODEL="${OPENCLAW_MODEL:-google/gemini-2.5-flash}"

# ── F-01: Write openclaw.json ──────────────────────────────────────────
cat > "$CONFIG_FILE" << EOCONFIG
{
  "agent": {
    "model": "${PRIMARY_MODEL}"
  },
  "channels": {
    "telegram": {
      "botToken": "${TELEGRAM_BOT_TOKEN:-}",
      "allowFrom": ["${TELEGRAM_ALLOWED_USER_ID:-8334914208}"],
      ${WEBHOOK_CONFIG}
      "groups": {}
    }
  },
  "gateway": {
    "bind": "lan",
    "port": ${PORT:-18789},
    "auth": {
      "mode": "token",
      "token": "${OPENCLAW_GATEWAY_TOKEN:-}"
    },
    "allowedOrigins": ${ALLOWED_ORIGINS}
  },
  "agents": {
    "defaults": {
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

# ── F-07: Secure the config (protect API keys written above) ──────────
chmod 600 "$CONFIG_FILE" 2>/dev/null || true

echo "[bootstrap] ✅ openclaw.json generated at $CONFIG_FILE"
echo "[bootstrap] ✅ Memory directories initialized"
echo "[bootstrap] ✅ Starting gateway on port ${PORT:-18789}..."

exec "$@"
