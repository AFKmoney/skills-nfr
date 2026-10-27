# SIREN recipes

## Architecture

`y = W_out · sin(ω₀ (W_k · … sin(ω₀ (W_1 x + b_1)) … + b_k)) + b_out`

- ω₀ = 30 (NFR v4 uses 30 on every sine layer).
- Coordinates normalized to [-1, 1].
- Typical sizes: tiny lab 2×20 (~500 params, ~2 KB); NFR v4 video 3×48 (~7 000 params, 28 KB
  fp32 → 34 KB file); detailed image/shape 4–5×256 (~200 k params, ~800 KB fp32).

## Initialization (critical)

- First layer: `W ~ U(-1/in, 1/in)`.
- Hidden layers: `W ~ U(-√(6/in)/ω₀, √(6/in)/ω₀)`.
- Biases small (or the same uniform). Bad init = the net never converges or outputs noise.

## Training

- Adam, lr 1e-4 (PyTorch, large nets) to ~1e-3 (small nets); MSE on sampled coordinates.
- Full-batch for images up to ~256²; random coordinate batches for video/3D.
- Report PSNR (images), SNR (audio), IoU/Chamfer (shapes). PSNR > 30 dB looks clean.

## Conditioning (families of assets)

- Concatenate a learned latent `z` (8–64 dims) to the input, or modulate each layer
  (FiLM: `sin(ω₀(Wx + b) · γ(z) + β(z))`).
- Add pose / time / parameter inputs the same way. Train on many examples; inference = pick `z`.

## Compressing the weights (NFR)

1. fp32 → **int8 per-block symmetric** (block 64): ~4×, usually invisible.
2. **Keep the first layer in fp16/fp32**: its weights are multiplied by ω₀ = 30 before the
   sine, so quantization error there is amplified ~30×. Hidden/output layers tolerate int8/int4.
3. int4 + k-means-16 codebook: ~8×; check PSNR after dequantization.
4. Entropy-code the index stream with NFR ULTRA (bell-shaped → +5–10 % free).
5. Optional: prune neurons + short fine-tune + QAT (quantizer in the loop) for 10×+.
6. Always print: bytes before/after, PSNR (or task metric) before/after.

`scripts/siren_fit.py` implements steps 1–2 and reports both numbers.

Measured with `siren_fit.py --demo bricks --steps 1500` (64×64, 3×64 sine layers, 8 707 params):

| Weights | Size | PSNR |
|---|---|---|
| fp32 | 34 828 B | 39.75 dB |
| int8 per-block, **first layer fp16** | 9 292 B (3.75×) | 39.06 dB |
| int8 per-block, first layer int8 too | ~8.9 KB | 33.51 dB (−5.5 dB) |

Keeping the first layer in fp16 costs ~0.4 KB and saves ~5.5 dB.

## Lossless?

A fitted SIREN is lossy by nature. For bit-perfect: SIREN (or context model) as **predictor**,
entropy-code the residuals (NFR v5), or use NFR ULTRA's adaptive context mixing (no stored weights).
