# pulse-to-pipewire
## 🎶 The Migration: From PulseAudio to PipeWire

##### This script, migrate-to-pipewire, is a clever utility for the modern Linux traveler, enabling a smooth, one-shot transition from the venerable PulseAudio server to the more capable PipeWire sound architecture. It not only performs the initial migration but also leaves behind a sturdy tool, fix-audio.sh, a quick balm for when the digital sound-stream inevitably stutters.

✨ Core Features
| Feature | Description |
|---|---|
| Distro-Agnostic | Auto-detects and installs correct packages for Alpine Linux (OpenRC) and Arch Linux (systemd). |
| Complete Stack | Installs the full PipeWire suite: core, pipewire-pulse (for compatibility), pipewire-alsa, and the wireplumber session manager. |
| Clean Transition | Removes or disables the PulseAudio daemon while preserving libpulse libraries to ensure older applications still find their voice. |
| Helper Script | Generates a reusable ~/fix-audio.sh for instantly killing stale audio processes, cleaning lockfiles, and restarting the PipeWire stack in the proper order. |
🛠️ Requirements & Setup
Before embarking on this sonic journey, ensure you have:
 * System: Either Alpine Linux (apk) or Arch Linux (pacman).
 * Privileges: Root access (sudo).
 * Foundation: A working user session and basic ALSA support for your hardware.
Installation
The path is swift and direct. Clone the repository and prepare the script:
``` bash
git clone https://github.com/yourname/migrate-to-pipewire.git
cd migrate-to-pipewire
chmod +x migrate-to-pipewire.sh
```

🚀 Usage: The Three Acts
1. The One-Time Migration
Execute the script with authority. This is the act of transformation:
sudo ./migrate-to-pipewire.sh

What Transpires:
 * Detection of Alpine or Arch.
 * Cessation of all running pulseaudio, pipewire, and wireplumber daemons.
 * Sanitization of stale user runtime sockets (/run/user/$UID, /tmp).
 * Installation of the correct PipeWire packages (including necessary ALSA and JACK components specific to the distro).
 * Dismantling of the old PulseAudio server, leaving only the compatibility libraries.
 * Creation of the trusty ~/fix-audio.sh helper.
2. The Healing Touch: fix-audio.sh
This script is your peace of mind. Run it whenever audio fails to find its way:
**~/fix-audio.sh**

It performs a robust reset by killing all user audio daemons, clearing residual files, and sequentially restarting pipewire, pipewire-pulse, and wireplumber.
3. Hyprland Integration
For those who govern their digital domain with Hyprland, ensure the fix is applied upon startup by adding this line to your config:
``` bash
 ~/.config/hypr/hyprland.conf
exec-once = ~/fix-audio.sh
```
This guarantees the user session starts the audio daemons correctly, bypassing system service quirks often found in Wayland environments.
✅ Verification: Did the Music Play?
After the migration, verify the success of the transition:
 * Pulse/PipeWire Check: Confirm the compatibility bridge is sound.
   pactl info

   > Expectation: The server name should report "PulseAudio (on PipeWire 1.x.x)".
   > 
 * ALSA Check: Confirm legacy ALSA applications route correctly.
   alsamixer
speaker-test -c2

 * Application Test: Use tools like pavucontrol to inspect streams and play media in a browser.
📜 Notes from the Architect
 * Compatibility First: We intentionally retain the libpulse libraries. The goal is to replace the server daemon, not break every application that links against the PulseAPI.
 * The Daemon is Gone: Whether on Alpine or Arch, the key victory is ensuring the old pulseaudio daemon no longer starts, letting PipeWire stand as the sole orchestrator.
