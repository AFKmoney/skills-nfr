# Zero-asset game creation with SRN

Proven in StudCraft Plastic Edition (three.js meshes + SRN shading), NeonForge SRN Engine
(WebGL raymarched SDF) and Microvoxel (voxel destruction). Patterns below are taken from them.

## 1. World = seed + edits

- Terrain, biomes, ores, villages, ruins: deterministic functions of `(seed, x, z)` (noise +
  stamping rules). Same seed rebuilds the same world.
- Save files store **only the player's modifications** (`[x, y, z, id]` list), position,
  inventory. An untouched infinite world costs ~nothing; a big castle costs a few MB.
- Test: walk into unexplored land; storage must not grow. If it grows, you are caching chunks.
- Compress saves with NFR ULTRA (edits are highly repetitive → strong ratios).

## 2. Geometry

- **Meshed voxels/bricks** (StudCraft): greedy or per-face mesher; studs, chamfers and
  bevels are generated geometry, not models.
- **Raymarched SDF** (NeonForge): `sdBox`, `sdCylinder`, smooth unions, domain repetition
  (`mod(p, cell)`) for infinite streets; keep a **JS mirror** of the SDF for collisions.
- **Destruction**: carve the SDF (persistent craters) or remove voxels. For LEGO, structural
  integrity should follow stud connections: after a break, flood-fill from the ground through
  connected bricks; anything not reached detaches as whole bricks (debris).

## 3. Materials without textures

Analytic sinusoids evaluated in the fragment shader (see `scripts/srn_material.glsl`):

```glsl
float siren(vec3 p){ return sin(p.x*7.1+sin(p.y*5.3))*sin(p.y*6.7+sin(p.z*4.9))*sin(p.z*8.3+sin(p.x*3.7)); }
```

- Plastic (ABS): low-amplitude micro-detail, roughness ~0.35–0.5, clearcoat-like specular,
  environment reflections, contact shadows / AO between studs. Realism comes from **lighting**,
  not pixels: highlights on studs, rounded edges catching light, ACES tone mapping.
- Normals from the field: finite-difference gradient of a height function (`sirenH`).
- Multi-channel: drive albedo, roughness, metalness, emission from different frequencies.
- Rock strata: `sin(p.y*1.3 + siren(p*0.5)*2.2)`; lava veins: `smoothstep(.72,.95, sin(p.y*2.6+siren(p*.8)*3.))`.

## 4. Melting plastic (StudCraft v4.15 pattern)

- Sparse maps only (empty when nothing burns): fire cells, burning cells, heat/melt per cell.
- Heat radiates from fire cells; `m` (melt 0..1) grows when `h > 0.5`; remesh a chunk only when
  `floor(m*8)` changes (≤ 8 remeshes per melt). At `m = 1` the cell becomes a puddle.
- Visual note observed in testing: shrinking each melted block in place leaves gaps between
  rows. For a convincing melt, sag the block toward the cell below and let upper rows settle
  (gravity) instead of shrinking around their own center.

## 5. Spec-driven engine (NeonForge design)

- A game = **JSON spec**: world generator id, palette, weather, mission type, NPCs, physics,
  quality, visual style, upscaling mode.
- The engine maps spec → shader uniforms + JS systems, live. Validate every field into a range.
- The LLM / local FR-EN translator only writes the spec. Seed → spec generator gives a full,
  deterministic game from one number (seed 42 → NOVA HAVEN).
- Export = one self-contained HTML (engine + spec), no assets.

## 6. Visual styles from one engine

Realistic, pixel, toon, retro CRT, film noir: post-process + material parameter sets over the
same SDF/SRN scene. Style is a spec field, not a new asset pack.

## 7. Performance on cheap devices

- Quality presets reduce raymarch steps, shadows, reflections, bloom.
- **Adaptive internal resolution** (scale factor tracking FPS) + **SRN upscaling**: render low,
  then re-evaluate the sinusoidal detail at output resolution. Detail is exact because the scene
  is a function. FSR1-style EASU + RCAS for edges (StudCraft).
- Preview tools (e.g. AI Studio) may cap FPS — measure on the real device / APK.
- Software-rendered capture (no GPU): drive the game clock frame by frame (override
  `requestAnimationFrame`/`performance.now`) to record smooth 30 fps footage at any render speed.

## 8. Audio

- Effects, ambience, UI: WebAudio DSP synthesis (oscillators, filtered noise) — 0 files.
- Music/voice are usually the heaviest part of the build (StudCraft: ~350 KB → ~14 MB with
  music). Options: Opus at 64–96 kb/s, download on first launch, or procedural music; SIREN
  `f(t)` for short sounds.

## 9. Characters and animation

Conditioned SIREN: input = coordinates + **identity latent** (who) + **pose parameters**
(joint angles from your animation formulas). One network covers a family of characters and all
their motions; a new character = a new latent. Needs example data to train; keep per-frame
evaluation cost in check (bake to a mesh/LOD when far away).
