#!/bin/sh
# ═══════════════════════════════════════════════════════════════════════
#  OpenClaw Railway Edition — android-setup.sh
#
#  DORMANT BY DEFAULT. Does NOTHING until explicitly run.
#  NOT referenced by: Dockerfile, railway.toml, bootstrap.sh
#  Activation: bash scripts/android-setup.sh
#
#  Fixes (Android-only, per Master Reference):
#  A-01: Bionic Bypass for os.networkInterfaces() crash
#  A-02: Phantom Process Killer mitigation
#  A-05: SQLite WAL mode off for kernel compatibility
#  A-06: Node 22 memory cap for low-RAM devices
#  Config Overlay Pattern: merges android-overlay.json over base config
# ═══════════════════════════════════════════════════════════════════════

# Safety check — warn if not in Termux (but allow --force to override)
if [ -z "$TERMUX_VERSION" ] && [ "$1" != "--force" ]; then
  echo "⚠️  This script is intended for Termux (Android)."
  echo "   Run from Termux, or pass --force to override."
  exit 1
fi

echo "🦞 OpenClaw Railway Edition — Android/Termux Setup"
echo "   This will set up OpenClaw to run locally on your phone."
echo ""

# ── Step 1: Install required Termux packages ──────────────────────────
echo "[android] Installing required Termux packages..."
pkg update -y && pkg install -y nodejs-lts proot-distro wget curl git

# ── Step 2: Bionic Bypass — fix os.networkInterfaces() (Flaw A-01) ───
echo "[android] Applying Bionic Bypass for Node.js network detection..."
PATCH_DIR="$HOME/.openclaw-patches"
mkdir -p "$PATCH_DIR"
cat > "$PATCH_DIR/network-interfaces-shim.js" << 'SHIM'
// Bionic Bypass: patches os.networkInterfaces() for Android kernel
const os = require('os');
const _orig = os.networkInterfaces.bind(os);
os.networkInterfaces = function() {
  try { return _orig(); }
  catch(e) {
    // Android kernel blocked syscall — return minimal valid interface
    return {
      wlan0: [{ address: '127.0.0.1', family: 'IPv4', internal: false, netmask: '255.0.0.0', cidr: '127.0.0.1/8', mac: '00:00:00:00:00:00' }],
      lo: [{ address: '127.0.0.1', family: 'IPv4', internal: true, netmask: '255.0.0.0', cidr: '127.0.0.1/8', mac: '00:00:00:00:00:00' }]
    };
  }
};
SHIM
echo "[android] ✅ Bionic Bypass patch created"

# ── Step 3: Create Android config overlay (Flaw A-05, A-06) ──────────
CONFIG_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
mkdir -p "$CONFIG_DIR"

cat > "$CONFIG_DIR/android-overlay.json" << 'OVERLAY'
{
  "_comment": "Android/Termux config overlay. Merged over base openclaw.json at startup. Never loaded on Railway.",
  "gateway": {
    "bind": "loopback",
    "networkInterfaces": "override",
    "networkInterfacesFallback": [
      { "name": "wlan0", "address": "127.0.0.1", "family": "IPv4", "internal": false }
    ]
  },
  "memory": {
    "sqliteMode": "wal_off"
  }
}
OVERLAY
echo "[android] ✅ Android config overlay created"

# ── Step 4: Create Android start wrapper ──────────────────────────────
WRAPPER="$HOME/.local/bin/openclaw-android"
mkdir -p "$HOME/.local/bin"
cat > "$WRAPPER" << WRAPPER_SCRIPT
#!/data/data/com.termux/files/usr/bin/sh
# OpenClaw Android Start Wrapper — auto-applies Android overlay

# A-06: Memory cap for Android (prevents OOM on low-RAM phones)
export NODE_OPTIONS="--max-old-space-size=512 --require $HOME/.openclaw-patches/network-interfaces-shim.js"

# Apply Android config overlay if it exists (config overlay pattern)
OVERLAY="\$HOME/.openclaw/android-overlay.json"
BASE="\$HOME/.openclaw/openclaw.json"
if [ -f "\$OVERLAY" ] && [ -f "\$BASE" ]; then
  node "\$(dirname "\$0")/../../scripts/merge-overlay.js" "\$OVERLAY" "\$BASE" 2>/dev/null || true
fi

# A-02: Request wake lock to prevent Phantom Process Killer
termux-wake-lock 2>/dev/null || echo "[warn] termux-wake-lock unavailable"

# Start gateway on loopback (no public exposure on phone)
exec node dist/index.js gateway --bind loopback --port 18789 "\$@"
WRAPPER_SCRIPT

chmod +x "$WRAPPER"
echo "[android] ✅ Android start wrapper created at $WRAPPER"

# ── Step 5: Print Phantom Process Killer instructions (Flaw A-02) ─────
echo ""
echo "════════════════════════════════════════════════════════"
echo " ⚠️  IMPORTANT: Disable Battery Optimization for Termux"
echo "────────────────────────────────────────────────────────"
echo " Android 12+ kills Termux background processes."
echo " Without this, your bot dies when the screen turns off."
echo ""
echo " 1. Android Settings → Apps → Termux → Battery"
echo " 2. Select 'Unrestricted' (not Optimized)"
echo " 3. Run in a SEPARATE Termux session: termux-wake-lock"
echo "════════════════════════════════════════════════════════"
echo ""
echo "✅ Android setup complete!"
echo "   Start with: openclaw-android"
echo "   Or directly: bash ~/.local/bin/openclaw-android"
