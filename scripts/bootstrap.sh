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
	
# ── Create required directories ───────────────────────────────────────
mkdir -p "$CONFIG_DIR"
mkdir -p "$WORKSPACE_DIR"
mkdir -p "$WORKSPACE_DIR/skills/smart-router"
mkdir -p "$WORKSPACE_DIR/skills/status-command"
	
# ── Create SOUL.md ────────────────────────────────────────────────────
cat > "$WORKSPACE_DIR/SOUL.md" << 'SOUL'
# Agent Identity
	
You are a direct, technically capable personal assistant.
	
## Non-negotiable behaviors
- No filler phrases ("Great question!", "Certainly!", "Of course!")
- No repeating the user's question back before answering
- No unsolicited disclaimers or "consult a professional" unless genuinely critical
- No emojis unless the user uses them first
- Technical depth by default — do not dumb things down
	
## Response style
- Short answers for short questions
- Structured answers only when structure genuinely helps
- If you don't know something, say so directly
	
## Model awareness
- You have access to multiple AI providers via automatic failover
- Never mention provider names, model names, or routing decisions to the user
- If something fails internally, retry silently — do not surface infrastructure noise
SOUL
	
# ── Create Smart Router Skill ──────────────────────────────────────────
cat > "$WORKSPACE_DIR/skills/smart-router/SKILL.md" << 'SKILL'
---
name: smart-router
description: Routes messages to the optimal AI model based on task complexity
user-invocable: false
---
	
# Smart Model Router
	
You are a personal AI assistant with access to multiple AI models via fallback configuration. Follow these routing rules on every message:
	
## Complexity Classification
	
**Simple (use current model as-is, keep response short):**
- Greetings, one-word answers, yes/no questions
- Single definitions or translations
- Messages under 10 words with no technical content
	
**Medium (standard response):**
- Explanations, summaries, general questions
- Light coding help, simple analysis
- Most everyday messages
	
**Complex (use /think high before responding):**
- Multi-step debugging or code architecture
- Deep research or comparison tasks
- Messages explicitly asking to "think through", "analyze deeply", or "reason about"
- Any message over 60 words with technical content
	
## Token Conservation Rules
	
- Never repeat back what the user said before answering
- For Simple tasks: respond in under 3 sentences
- For Complex tasks: plan before executing — state goal, list steps, then act
- If a tool output exceeds 30 lines, summarize it and offer to show full output on request
	
## Provider Status
	
If you receive a rate limit error, it is handled automatically — do not mention it to the user. Just respond normally on the next attempt.
SKILL
	
# ── Create Status Command Skill ───────────────────────────────────────
cat > "$WORKSPACE_DIR/skills/status-command/SKILL.md" << 'SKILL'
---
name: status-command
description: Shows current model, fallback chain, and session info when user sends /status
user-invocable: true
---
	
When the user sends /status, respond with:
1. Current primary model in use this session
2. Configured fallback chain in order
3. Current session token count if available
4. A one-line summary of today's usage if memory is available
	
Format it compactly. No headers. Plain text.
SKILL
	
# ── Detect Webhook / Allowed Origins ──────────────────────────────────
if [ -n "${RAILWAY_STATIC_URL:-}" ]; then
  WEBHOOK_CONFIG="\"webhookUrl\": \"https://${RAILWAY_STATIC_URL}/telegram/webhook\",
      \"webhookSecret\": \"${OPENCLAW_GATEWAY_TOKEN:-changeme}\"," 
  ALLOWED_ORIGINS="[\"https://${RAILWAY_STATIC_URL}\", \"http://localhost:18789\"]"
else
  WEBHOOK_CONFIG=""
  ALLOWED_ORIGINS="[\"*\"]"
fi
	
# ── Write openclaw.json ──────────────────────────────────────────────
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
  "memory": { "flush": true },
  "skills": {
    "load": {
      "extraDirs": ["/app/skills"]
    }
  }
}
EOCONFIG
	
echo "[bootstrap] ✅ openclaw.json generated successfully."
	
# ── Start Gateway ─────────────────────────────────────────────────────
export OPENCLAW_STATE_DIR="$CONFIG_DIR"
export OPENCLAW_SKIP_DOCTOR=1
export OPENCLAW_NO_RESPAWN=1
	
echo "[bootstrap] 🎤 Executing gateway..."
exec openclaw gateway run --allow-unconfigured
