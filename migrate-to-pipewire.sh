#!/usr/bin/env bash
set -e

# migrate-to-pipewire.sh
# Works on: Alpine Linux (OpenRC) and Arch Linux (systemd)
# Goal: migrate from PulseAudio → PipeWire and provide a "fix-audio" function

########################################
# 0. Detect distro
########################################

if command -v apk >/dev/null 2>&1; then
  DISTRO="alpine"
elif command -v pacman >/dev/null 2>&1; then
  DISTRO="arch"
else
  echo "Unsupported distro (need Alpine or Arch)."
  exit 1
fi

echo "Detected distro: $DISTRO"

########################################
# 1. Stop ALL audio daemons and clean sockets
########################################

echo "[*] Killing existing audio daemons..."

killall pipewire pipewire-pulse wireplumber pulseaudio 2>/dev/null || true
sleep 2

echo "[*] Cleaning runtime sockets/locks..."
rm -rf /run/user/$(id -u)/pipewire-* /run/user/$(id -u)/pulse /tmp/pipewire-* 2>/dev/null || true

########################################
# 2. Install PipeWire stack (per distro)
########################################

if [ "$DISTRO" = "alpine" ]; then
  echo "[*] Installing PipeWire stack on Alpine..."

  sudo apk add \
    pipewire pipewire-alsa pipewire-pulse wireplumber \
    alsa-plugins-pulse pipewire-alsa \
    alsa-utils pavucontrol || true  # pavucontrol may be optional

elif [ "$DISTRO" = "arch" ]; then
  echo "[*] Installing PipeWire stack on Arch..."

  sudo pacman -S --needed --noconfirm \
    pipewire pipewire-alsa pipewire-pulse pipewire-jack \
    wireplumber alsa-utils pavucontrol
fi

########################################
# 3. Remove / disable PulseAudio server (keep libpulse)
########################################

echo "[*] Removing PulseAudio server components (but keeping libpulse)..."

if [ "$DISTRO" = "alpine" ]; then
  # On Alpine, pipewire-pulse depends on pulseaudio-utils; do NOT force-remove deps.
  # Just remove the main pulseaudio daemon packages if present.
  sudo apk del pulseaudio pulseaudio-alsa pulseaudio-jack pulseaudio-bluetooth \
    pulseaudio-elogind 2>/dev/null || true

  # OpenRC services (in case PulseAudio was ever added)
  sudo rc-update del pulseaudio default 2>/dev/null || true
  sudo rc-service pulseaudio stop 2>/dev/null || true

elif [ "$DISTRO" = "arch" ]; then
  sudo pacman -Rns --noconfirm pulseaudio pulseaudio-alsa pulseaudio-bluetooth 2>/dev/null || true
fi

########################################
# 4. Create fix-audio.sh helper in HOME
########################################

FIX_SCRIPT="$HOME/fix-audio.sh"
echo "[*] Writing $FIX_SCRIPT ..."

cat > "$FIX_SCRIPT" << 'EOF'
#!/bin/sh
# fix-audio.sh - restart PipeWire stack for current user

echo "[fix-audio] Killing audio daemons..."
killall pipewire pipewire-pulse wireplumber pipewire-launcher pulseaudio 2>/dev/null || true
sleep 2

echo "[fix-audio] Cleaning runtime dirs..."
rm -rf /run/user/$(id -u)/pipewire-* /run/user/$(id -u)/pulse /tmp/pipewire-* 2>/dev/null || true
sleep 1

echo "[fix-audio] Starting PipeWire stack..."
pipewire &
sleep 1
pipewire-pulse &
sleep 1
wireplumber &
sleep 2

echo "[fix-audio] pactl info:"
pactl info || echo "pactl: still not connected"
EOF

chmod +x "$FIX_SCRIPT"

echo "[*] You can now run '$FIX_SCRIPT' anytime audio breaks."

########################################
# 5. Hyprland integration hint (manual step)
########################################

echo
echo "========================================"
echo " MANUAL STEP: add this to Hyprland conf "
echo "========================================"
echo "Edit: ~/.config/hypr/hyprland.conf"
echo "Add (or replace existing audio exec-once lines) with:"
echo
echo "  exec-once = $FIX_SCRIPT"
echo
echo "This will auto-fix audio on every Hyprland start on both Alpine and Arch."
echo
echo "Now run: $FIX_SCRIPT"
echo "and then test with: pactl info  &&  alsamixer  &&  speaker-test -c2"
echo
EOF
