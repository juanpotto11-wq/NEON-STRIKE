# NEON STRIKE V3 — Mobile FPS Vertical Slice

Godot 4.x prototype focused on a more polished AAA-style gameplay loop while staying mobile-friendly.

## V3
- Weapon recoil + weapon sway
- Muzzle flash, hit sparks and damage feedback
- Three weapon archetypes with distinct handling
- Four enemy archetypes: Drone, Assault, Brute, Hunter
- Enemy threat scaling by wave
- Boss every 5 waves
- Mission objectives and rewards
- Pause/settings/game-over flow
- Mobile HUD with virtual movement/look/fire/reload/weapon controls
- Procedural arena props and neon signage
- Object pooling for simple impact effects
- Dynamic difficulty and wave director
- Performance budget: max active enemies, low-cost lights, no real-time shadows on mobile
- Android export notes and quality presets

## Visual/audio assets
The project uses procedural meshes and generated placeholder SFX so it is self-contained.
Replace them with production GLB/GLTF models, textures, animations and WAV/OGG assets when available.

## APK
Open with Godot 4.x, configure Android SDK/JDK, then Project > Export > Android.
Recommended mobile baseline: 60 FPS target, GL Compatibility, 1280x720 internal UI scaling.
