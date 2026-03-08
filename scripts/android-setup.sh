#!/bin/sh
# ═══════════════════════════════════════════════════════════════════════
#  OpenClaw Android / Termux Setup Script (DORMANT)
#  Zero impact on Railway. Only runs when explicitly executed on Android.
# ═══════════════════════════════════════════════════════════════════════
set -e

# 1. Detect Environment
if ! uname -a | grep -i "android" > /dev/null; then
  echo "❌ This script is only for Android (Termux) environments."
  exit 1
fi

echo "📱 OpenClaw Termux Setup Detected"

# 2. Check / Install Dependencies
if ! command -v proot-distro > /dev/null; then
  echo "Installing proot-distro (Ubuntu)..."
  pkg update && pkg install proot-distro -y
  proot-distro install ubuntu
fi

# 3. Create Android Config Overlay
CONFIG_DIR="$HOME/.openclaw"
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_DIR/android-overlay.json" << EOOVERLAY
{
  "gateway": {
    "bind": "loopback"
  },
  "memory": {
    "sqlWalMode": false
  }
}
EOOVERLAY

# 4. Create Start Wrapper
cat > "$HOME/.openclaw-android-start.sh" << 'EOSCRIPT'
#!/bin/sh
# Termux wrapper script
export NODE_OPTIONS="--max-old-space-size=512"
exec proot-distro login ubuntu -- bash -c "openclaw gateway --config ~/.openclaw/android-overlay.json"
EOSCRIPT

chmod +x "$HOME/.openclaw-android-start.sh"

# 5. Instructions for User
echo ""
echo "✅ Android environment prepared natively."
echo ""
echo "⚠️ IMPORTANT BATTERY SAVER INSTRUCTIONS (Phantom Process Killer):"
echo "To prevent Android from killing this background process, run via adb:"
echo 'adb shell "settings put global settings_enable_monitor_phantom_procs false"'
echo ""
echo "▶️ To start OpenClaw: ~/.openclaw-android-start.sh"
echo ""
