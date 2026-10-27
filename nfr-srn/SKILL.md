---
name: nfr-srn
description: Apply Philippe's NFR / SRN (sinusoidal representation network) approach — zero-asset game graphics, SRN materials and upscaling, implicit neural representations of images/video/audio/3D, and NFR ULTRA compression of AI models. Use for any SRN, SIREN, SDF, procedural-asset or neural-compression work.
---

# NFR / SRN — replace stored data with functions

NFR (Neural Fractal Reconstruction) is Philippe's research line (GitHub `AFKmoney/NFR-Compressor`).
It takes the 2020 SIREN idea — a tiny MLP with `sin` activations can represent any continuous
signal — and applies it everywhere: games, materials, upscaling, video, and the compression of
the networks themselves. His shipped proofs: **StudCraft Plastic Edition** (photoreal LEGO, zero
graphical assets, ~300 KB APK without music), **NeonForge SRN Engine** (game-creation engine in
one ~123 KB HTML file), **Microvoxel** (Teardown-style destruction).

## Core principle

> Don't store the signal. Store the function that generates it.

Every asset is a function of coordinates: `f(x,y) → color`, `f(x,y,z) → distance/material`,
`f(t) → sample`, `f(t,x,y) → RGB`. Pick how the function is obtained:

| Signal | Get the function by… | Typical size |
|---|---|---|
| Regular / stylized (bricks, voxels, cities, terrain, plastic, metal, toon, pixel) | **Writing it** — SDF + analytic sinusoids in the shader | bytes – a few KB |
| Unique / organic (a specific face, character, logo, recorded sound, a video) | **Fitting it** — train a SIREN on that example | ~2 KB – 1 MB, then ÷4–8 with NFR quantization |
| A family (many characters, all their poses) | **Conditioning** — one SIREN fed an identity code + pose parameters | a few MB for the whole family |

## Working rules (Philippe's method — follow them)

1. **Never call something impossible from training knowledge.** Prototype it and measure. If
   there is a real limit, name the limit with a number, not a verdict.
2. **Measure first, then claim.** Report size in bytes, quality (PSNR/SNR/cosine, or bpb and
   accuracy for models), and speed (ms/frame or FPS) on the target device. No overclaiming in
   READMEs; publish failures too.
3. **Lossless vs lossy is always stated.** A fitted SRN is a generative/lossy approximation
   (e.g. NFR v4 Holographic). Bit-perfect needs predictor + residual entropy coding (NFR v5) or
   the zero-weight context mixer (NFR ULTRA).
4. **The translator is not the engine.** An LLM (or a local parser) only produces a JSON spec;
   the engine turns the spec into equations (NeonForge's design).
5. **Keep it light on cheap devices.** CPU-only must work; adaptive internal resolution + SRN
   detail regeneration instead of brute-force pixels.

## Which reference to read

- Building a game, world, material, upscaler, or a zero-asset scene → `references/game-creation.md`
- Fitting a SIREN (init, ω₀, training, conditioning, quantizing its weights) → `references/siren-recipes.md`
- Compressing files or AI models with NFR ULTRA (lossless, int8/int4, prune + QAT) → `references/model-compression.md`

## Scripts

- `scripts/siren_fit.py` — NumPy-only SIREN: fits an image (or a built-in procedural brick
  pattern), reports PSNR, then exports fp32 and NFR-style int8 weights (first layer kept fp16)
  with sizes and the PSNR after quantization. No torch needed.
  `python3 scripts/siren_fit.py --demo bricks --steps 1500` or `--image in.png --out weights.npz`
- `scripts/srn_material.glsl` — drop-in analytic sinusoidal material functions (plastic studs,
  surface micro-detail, strata, lava veins) and a gradient-normal helper, as used in NeonForge.

## Quick decision checklist

- Is the content regular? → write SDF + sinusoids, store **seed + parameters + player edits only**.
- Is it unique? → fit a SIREN, quantize int8 (first layer fp16), entropy-code with NFR ULTRA.
- Is it a family with variations? → conditioned SIREN (identity latent + pose/params).
- Is the GPU weak or absent? → render at lower internal resolution and re-evaluate the
  sinusoidal detail at full resolution (exact detail, not hallucinated — that is the advantage
  over DLSS-style upscalers, which must guess).
- Is the heavy part audio? → DSP synthesis for effects/ambience; SIREN `f(t)` or a codec for
  recorded music/voice — voice is the hardest signal to make tiny.
