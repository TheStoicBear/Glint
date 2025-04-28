
![This area will not be visable on the banner And only visable once they open the forum page (2)](https://github.com/user-attachments/assets/f4ad4571-1968-44d6-adda-6ecd6aa51e65)

# GLINT – Vehicle Spotlight System for FiveM

GLINT provides an advanced vehicle-mounted spotlight system for **FiveM** servers. Players can toggle floodlights, alley lights, or a smart tracking beam via UI or hotkeys, with full network synchronization — so everyone sees each other’s lights in real time.

---

## Overview 🔦

GLINT provides advanced vehicle-mounted spotlights for FiveM servers. Players can toggle floodlights, alley lights, or a smart tracking beam via UI or hotkeys, with full network synchronization so every player sees each other’s lights in real time.

---

## Features ✨

- **Floodlights:** Three forward-facing beams with adjustable intensity.
- **Alley lights:** Side-mounted downward-tilted beams.
- **Tracking beam:** Auto-aims at the nearest vehicle ahead with smoothing.
- **UI Panel (`/spotlightui`):** Toggle modes and "all on/off" options.
- **Hotkey Support:** Single-tap `L` for floodlights, double-tap `L` for alley lights.
- **Networked State Sync:** Everyone sees each other's lights live.
- **Optimized:** Lightweight and performance-focused.

---

## Installation 📦

1. Download the `Glint` resource folder.
2. Place it into your server’s `resources/` directory.
3. Add `ensure Glint` to your `server.cfg`.
4. Restart your server, or use `refresh` + `ensure Glint` in console.

---

## Configuration ⚙️ *(⚠️COMING SOON⚠️)*

Tune your spotlight behavior by editing `config.lua`:

```lua
-- Double-tap threshold (ms)
Config.DoubleTapThreshold    = 300

-- Tracking smooth factor (0.0–1.0)
Config.RotationSmoothFactor  = 0.15

-- Max distance and angle for auto-tracking
Config.TrackMaxDistance      = 250.0
Config.TrackAngleThreshold   = math.cos(math.rad(90))

-- Spotlight parameters
Config.FloodInnerRadius      = 40.0
Config.FloodOuterRadius      = 40.0
Config.FloodDistance         = 50.0
Config.FloodIntensity        = 40.0

Config.AlleyInnerRadius      = 30.0
Config.AlleyOuterRadius      = 20.0
Config.AlleyDistance         = 35.0
Config.AlleyIntensity        = 5.0

Config.TrackInnerRadius      = 50.0
Config.TrackOuterRadius      = 30.0
Config.TrackDistance         = 25.0
Config.TrackIntensity        = 28.6
```

---

## Usage 🚀

Open the spotlight UI via:

```bash
/spotlightui
```

Or press `L`:

- Single-tap `L` for floodlights.
- Double-tap `L` for alley lights.

In the UI:

- Click **Track** to enable auto-tracking spotlight mode.
- Click **All** to toggle all lights at once.
- Click **Close** to hide the UI panel.

---

## Scripts 📜

- `client.lua` — Handles input, NUI, spotlight rendering, auto-tracking, and network state synchronization.
- `server.lua` — Receives updates, maintains `lightStates`, and broadcasts state to all clients.

---

© 2025 GLINT • Vehicle Spotlight System for FiveM
