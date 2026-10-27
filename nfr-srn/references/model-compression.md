# NFR ULTRA — file and AI-model compression

Source: `AFKmoney/NFR-Compressor`, folder `nfr_ultra/` (C99 core, Python CLIs). CPU-first,
`gcc` only at runtime. All figures below come from the repo README (reproduced in-repo; Muse
reproduced the same numbers).

## Tools

| Tool | Use | Output |
|---|---|---|
| `nfr_ultra.py` + `nfr_core.c` | Generic lossless codec: adaptive context mixing (orders 1–5 + word + LZ match, logistic mixer, APM) + range coder; **zero stored weights** | `.nfu` |
| `nfr_model.py` | AI-model compressor: lossless byte-plane split of fp32, or per-block int8/int4(+kmeans) entropy-coded | `.nfum` |
| `nfr_prune.py` | Gate-aware structured pruning (+ optional SVD) + ULTRA; emits `.npz` + torch loader + fine-tune snippet | `.nfup` |
| `nfr_qat.py` / `nfr_gpt.py` | Functional benchmarks (LSTM / nanoGPT) with QAT using the deployed quantizer | — |

## Commands

```bash
python3 nfr_ultra/nfr_ultra.py compress file.bin file.nfu
python3 nfr_ultra/nfr_ultra.py decompress file.nfu restored.bin
python3 nfr_ultra/nfr_ultra.py bench file1 file2      # vs zlib / bz2 / lzma
python3 nfr_ultra/nfr_ultra.py verify file.bin        # round trip

python3 nfr_ultra/nfr_model.py analyze model.pt       # ALWAYS FIRST: Shannon ceiling
python3 nfr_ultra/nfr_model.py compress model.pt m.nfum --mode lossless
python3 nfr_ultra/nfr_model.py compress model.pt m.nfum --mode extreme --bits 8
python3 nfr_ultra/nfr_model.py compress model.pt m.nfum --mode extreme --bits 4 --kmeans
python3 nfr_ultra/nfr_prune.py compress model.pt m.nfup --keep 0.25 --bits 4 --kmeans [--keepd 0.4375]
python3 nfr_ultra/nfr_qat.py bench                    # train → compress → eval → QAT → eval
python3 nfr_ultra/nfr_gpt.py bench
```

Input: `torch.save()` zip (fp32 FloatStorage) or raw fp32 dumps.

## The honest ladder (measured)

| Target | Recipe | Ratio | Functional cost |
|---|---|---|---|
| Free | int8 extreme | ~3.96× | none (Δbpb 0.0002) |
| Better + small | int8 + QAT | ~3.95× | negative (70.95 % vs 69.27 % fp32) |
| ~8× | int4 + kmeans | 7.98× | tiny (cos 0.995) |
| ~11× (transformer) | prune MLP 50 % → FT → QAT int4 | 11.05× | +7.4 pts over original |
| ~61× | keep 25 % + int4 kmeans + FT + QAT | 61.2× | ~−5.5 pts |
| ~152× | keep 6.25 % + FT + QAT | 152× | −28 pts, still useful |
| ~268× (max proven) | keep 4 % + keepd 0.4375 + FT + QAT | 268× | −31 pts, still works |

Lossless on trained fp32 weights is capped by mantissa entropy (~1.2×); ULTRA reaches 1.205× on
a 1.21× ceiling. Anything beyond is controlled-lossy and must print cosine/SNR or bpb/accuracy.

Rule of thumb: `total ≈ pruning × quant (int8 4×, int4 8×) × ULTRA entropy (1.05–1.35×)` minus
codebooks/header (dominant below ~20 KB).

## Applying it elsewhere

- **SRN game assets**: int8 hidden layers, fp16 first layer, then ULTRA (see `siren-recipes.md`).
- **Save files / edit lists**: `nfr_ultra.py compress` (repetitive → high ratios).
- **Small on-device models** (Fractus-class, LSTM/byte models): analyze → int8 (+QAT) first;
  prune + FT + QAT only when you need >10× and can afford a short fine-tune.
- **Video / images as functions**: NFR v4 Holographic (overfit SIREN f(t,x,y) — lossy,
  generative); NFR v5 for bit-perfect (NanoSiren predictor + arithmetic-coded residuals).
