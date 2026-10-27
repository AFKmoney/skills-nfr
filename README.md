# skills-nfr

Agent skill that applies **NFR (Neural Fractal Reconstruction) / SRN** — Philippe's research on
sinusoidal representation networks — to game creation, procedural materials, upscaling,
implicit neural representations, and AI-model compression.

> Don't store the signal. Store the function that generates it.

## Contents

```
nfr-srn/
  SKILL.md                      # entry point: principle, working rules, decision checklist
  references/
    game-creation.md            # zero-asset worlds, SDF, SRN materials, melting plastic, spec-driven engine
    siren-recipes.md            # SIREN init / ω₀ / training / conditioning / weight quantization (measured)
    model-compression.md        # NFR ULTRA: lossless codec, int8/int4, prune + QAT ladder
  scripts/
    siren_fit.py                # NumPy-only SIREN fit + NFR-style int8 export (no torch)
    srn_material.glsl           # analytic sinusoidal materials (plastic, strata, lava, normals)
```

## Proofs this skill is built on

- **StudCraft Plastic Edition** — photoreal LEGO world, zero graphical assets, ~300 KB APK (without music).
- **NeonForge SRN Engine** — game-creation engine in a single ~123 KB HTML file (SDF + SRN + DSP).
- **Microvoxel** — Teardown-style voxel destruction.
- **NFR-Compressor** — `AFKmoney/NFR-Compressor` (v4 Holographic SIREN video, v5 lossless, NFR ULTRA).

## Install

Copy `nfr-srn/` into your agent's skills folder (e.g. `~/.claude/skills/nfr-srn/`).

## Quick test

```bash
python3 nfr-srn/scripts/siren_fit.py --demo bricks --steps 1500
# SIREN 8707 params: fp32 34828 B  PSNR ~39.7 dB
# NFR int8 (first layer fp16): 9292 B (3.75x smaller)  PSNR ~39.1 dB
```

© 2026 Philippe (Palier Labs). All rights reserved.
