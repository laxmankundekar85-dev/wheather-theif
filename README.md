# Weather Thief: The Last Sky 🌩️

[![Godot Engine](https://img.shields.io/badge/Godot-v4.7.2%20Stable-478cbf?logo=godotengine&logoColor=white)](https://godotengine.org)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Android-green?logo=windows&logoColor=white)](https://github.com/laxmankundekar85-dev/wheather-theif)
[![Genre](https://img.shields.io/badge/Genre-Third--Person%20Shooter%20%2F%20Action%20RPG-blueviolet)](#gameplay--features)
[![License](https://img.shields.io/badge/License-MIT-blue)](#license)

**Weather Thief: The Last Sky** is a 3D tactical third-person shooter and action RPG built in Godot 4. Step into the boots of **Kael**, an operative fighting alongside his companion **Lyra** to liberate the realm of Aetheria from the tyrannical **Shadow Vanguard**, an elite syndicate that has captured the world's weather in ancient atmospheric siphons.

---

## 🎮 Gameplay & Features

### 1. Tactical Third-Person Shooter Locomotion
- **Humanoid Character Rigging & Animation:** Procedural spine aiming, realistic running, sprinting, crouching, combat slide, and dynamic hand/weapon IK bone attachments.
- **Weapon System:**
  - `Skybreaker Assault Rifle` (Selective/Full-auto standard issue)
  - `Viper SMG` (High fire-rate close-quarters weapon)
  - `Tempest Shotgun` (High-spread multi-pellet close range)
  - `Aetheria Carbine` (Burst-fire precision firearm)
  - `Stormfall Sniper Rifle` (High-caliber anti-materiel rifle with optical scoping)
- **3-Mode Central Camera State Machine:**
  - **Third-Person Free Cam:** Optimal situational awareness (FOV: 72°).
  - **Over-The-Shoulder ADS (Aim Down Sights):** Precision tactical stance (FOV: 48°).
  - **Optical Scoping:** 8x long-range zoom with customized crosshair reticle and FOV-scaled sensitivity (FOV: 18°).

### 2. Tactical Human Enemy AI (`ShadowVanguardSoldier`)
- Elite Vanguard operatives with distinct combat roles: **Troopers**, **Enforcers**, **Infiltrators**, **Marksmen**, and **Overseer Bosses**.
- Full 3D humanoid models with tactical ballistic gear, glowing optic visors, and realistic weapon holding.
- Dynamic line-of-sight perception, cover navigation, reload timings, directional flinch animations, and overhead health indicators (`[Soldier Name [HP/MaxHP]]`).
- Weak-point mechanics: Double-damage headshots with audio-visual hitmarker confirmation (`headshot_ding`).

### 3. Complete 55-Level Story Campaign
Explore 55 missions across 5 handcrafted visual regions:
- **Level 1 — Verdantia Combat Outpost:** The original hand-crafted rebel fortress infiltration.
- **Levels 2–15 — The Forgotten District:** Mediterranean paver streets, two-story stone villas, archways, fountains, street lanterns, ivy trims, merchant stalls, and sunken canals.
- **Levels 16–25 — The Frozen Mountains:** Snow-frosted stone paths, fortified military guard watchtowers, pine forests, wooden bridges, and APC wrecks under pale arctic skies.
- **Levels 26–35 — The Sky Islands:** Lush floating plateaus, ancient ruined temples, hanging bridges, water fountains, and high-altitude sun glare.
- **Levels 36–45 — The Sunken Desert:** Sandstone ruins, buried desert cities, terracotta plazas, bazaar stalls, and atmospheric heat haze.
- **Levels 46–55 — The Storm Kingdom:** Dark obsidian stone, fortified triple bastion towers, military barricades, lightning strikes, and dramatic climactic boss battles.

### 4. Elemental Weather Abilities & Siphons
Infuse weapons and area abilities with elemental forces:
- 🌧️ **Rain:** Hydrating shield regeneration and corrosive ammo.
- ⚡ **Thunder:** High-voltage chain lightning and critical burst shocks.
- ❄️ **Snow / Frost:** Area crowd control and freezing enemy movement.
- ☀️ **Sun / Solar:** High-intensity incinerating damage.
- 💨 **Wind:** Mobility surges and projectile redirection.

### 5. Multi-Platform Support (Desktop & Mobile)
- **Desktop (Windows):** Full mouse capture, crosshair aiming, remappable key bindings, and graphics scaling.
- **Mobile (Android Touch & Gyroscope):**
  - Left-hand 360° virtual joystick with dedicated sprint control.
  - Right-hand tactical combat cluster: dedicated `FIRE`, `AIM` (ADS), `SCOPE` (Sniper), `RELOAD`, `JUMP`, `CROUCH`, `WEAPON SWITCH`, and `WEATHER` ability buttons.
  - Gyroscope precision aiming support on compatible Android hardware.

---

## 🕹️ Controls Guide

### Desktop Controls (PC)

| Action | Key / Input |
| :--- | :--- |
| **Move** | `W`, `A`, `S`, `D` |
| **Look / Aim** | `Mouse Move` |
| **Fire Weapon** | `Left Mouse Button` |
| **Aim Down Sights (ADS)** | `Right Mouse Button` (Hold/Toggle) |
| **Scope Zoom (Sniper)** | `Middle Mouse Button` / `V` |
| **Sprint** | `Shift` |
| **Jump** | `Space` |
| **Crouch / Slide** | `C` |
| **Reload** | `R` |
| **Weapon Selection** | `1`, `2`, `3`, `4`, `5` / `Mouse Wheel` |
| **Weather Ultimate** | `G` |
| **Pause Menu** | `Escape` |

### Mobile Touch Controls (Android)

| Control | Position | Description |
| :--- | :--- | :--- |
| **Virtual Joystick** | Bottom-Left | 360° smooth character locomotion |
| **⚡ SPRINT** | Left (above joystick) | Activates high-speed sprint |
| **🔥 FIRE** | Bottom-Right | Primary firearm discharge |
| **🎯 AIM** | Right side | Toggles Over-The-Shoulder ADS |
| **🔭 SCOPE** | Right side | Activates optical sniper scope |
| **🔄 RELOAD** | Right side | Swaps magazine |
| **🦘 JUMP** | Right side | Character jump / obstacle vault |
| **🛡️ CROUCH** | Right side | Crouch or combat slide |
| **🔫 SWITCH** | Right side | Cycles equipped weapons |

---

## 📁 Project Architecture

```
R:\wheather theif\
├── assets/                    # 3D models, textures, audio SFX, background art
│   ├── characters/            # Kael avatar rigs (GLB), textures, Lyra model
│   ├── environments/          # PBR textures (cobblestone, sandstone, obsidian, grass)
│   └── weapons/               # 3D firearms models and optics
├── autoload/                  # Global singletons
│   ├── game_manager.gd        # Game state, checkpoints, persistent references
│   ├── audio_manager.gd       # 12-channel procedural sound & music engine
│   ├── level_manager.gd       # 55-level progression & campaign state
│   ├── save_manager.gd        # Encrypted JSON game save/load system
│   ├── weather_manager.gd     # Elemental state & atmospheric effects
│   ├── combat_manager.gd      # Damage numbers, hit detection, boss events
│   └── scene_transition.gd    # Smooth screen fading & scene loading
├── scenes/
│   ├── levels/
│   │   ├── verdantia_combat_outpost.tscn   # Level 1 (Intact Master Outpost)
│   │   └── campaign/                       # Level 02 through Level 55 scenes
│   ├── player/                # Kael shooter protagonist & Lyra companion
│   ├── enemies/               # Shadow Vanguard humanoid operatives
│   ├── environment/           # Modular 3D buildings, ruins, watchtowers, cover crates
│   ├── ui/                    # Reusable ShooterHUD, touch controls, pause menu
│   └── weapons/               # Firearm PackedScenes
├── scripts/                   # GDScript 2.0 gameplay logic
├── shaders/                   # Custom visual shaders
├── export_presets.cfg         # Windows Desktop & Android export configurations
└── project.godot              # Godot 4 project configuration
```

---

## 🚀 Building & Exporting

### Prerequisites
- **Engine:** [Godot Engine v4.x (Standard 64-bit)](https://godotengine.org/download)
- **Android Export (Optional):** Android SDK (Build Tools 34+), OpenJDK 17+, Debug Keystore

### Export via Godot Console CLI
```bash
# Export Windows Desktop Release
Godot_v4.x_console.exe --headless --path "R:/wheather theif" --export-release "Windows Desktop" "R:/WeatherThief_Windows/Weather Thief.exe"

# Export Android Debug / Release APK
Godot_v4.x_console.exe --headless --path "R:/wheather theif" --export-debug "Android" "R:/WeatherThief.apk"
```

---

## 📜 Credits & License
- **Lead Developer & Creator:** Laxman Kundekar ([@laxmankundekar85-dev](https://github.com/laxmankundekar85-dev))
- **Engine:** Godot Engine (MIT License)
- **License:** Distributed under the MIT License. See `LICENSE` for more information.
