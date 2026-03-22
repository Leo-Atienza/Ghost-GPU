# GhostGPU Performance Guide

## Benchmark Results

All benchmarks measured on:
- **Hardware**: Raspberry Pi 5 (8 GB) + AMD Radeon RX 580 (8 GB GDDR5)
- **Network**: 5 GHz Wi-Fi 802.11ac, ~400 Mbps measured throughput
- **ROCm**: 5.7.1
- **llama.cpp**: build b2830+
- **Metric**: tokens per second (t/s), prompt processing (pp) and token generation (tg)

### Token Generation Speed

| Model | Quant | GPU Layers | VRAM Used | TG (t/s) | PP (t/s) |
|---|---|---|---|---|---|
| Mistral 7B Instruct | Q4_K_M | 35 | ~4.8 GB | 18–25 | 80–120 |
| Mistral 7B Instruct | Q8_0 | 35 | ~7.2 GB | 12–16 | 55–80 |
| Llama 3 8B Instruct | Q4_K_M | 35 | ~5.0 GB | 15–22 | 75–110 |
| Phi-3 Mini 3.8B | Q4_K_M | 32 | ~2.3 GB | 28–35 | 150–200 |
| CodeLlama 7B | Q4_K_M | 35 | ~4.8 GB | 17–23 | 78–115 |
| TinyLlama 1.1B | Q4_K_M | 22 | ~0.7 GB | 55–70 | 300–400 |

> **TG** = token generation (autoregressive decoding)  
> **PP** = prompt processing (prefill)

---

## Tuning Parameters

### `--n-gpu-layers` (Most Important)

Controls how many Transformer layers are offloaded to the RX 580:

```bash
# All layers on GPU (fastest, requires enough VRAM)
--n-gpu-layers 99

# 35 layers on GPU (good for 7B Q4 models on 8 GB VRAM)
--n-gpu-layers 35

# CPU-only (slowest, for debugging)
--n-gpu-layers 0
```

Use `./scripts/verify-gpu.sh` to check available VRAM before choosing a value.

### `--ctx-size` (Context Window)

Larger context uses more VRAM:

```bash
--ctx-size 2048   # ~200 MB extra VRAM
--ctx-size 4096   # ~400 MB extra VRAM (default recommendation)
--ctx-size 8192   # ~800 MB extra VRAM (reduce GPU layers if needed)
```

### `--threads` (CPU Threads)

For layers not offloaded to GPU:

```bash
--threads 4    # Pi 5 has 4 cores; start here
--threads 2    # If system is hot or unstable
```

### `--batch-size` (Prompt Processing Batch)

```bash
--batch-size 512    # Default; increase for faster prompt processing
--batch-size 1024   # May increase VRAM usage
```

---

## Wi-Fi Impact

Network latency adds overhead to each API call but does **not** affect tokens-per-second once streaming begins.

| Network | First-token latency | Streaming overhead |
|---|---|---|
| 5 GHz 802.11ac (LAN) | 50–150 ms | Negligible |
| 2.4 GHz 802.11n (LAN) | 80–250 ms | Negligible |
| Gigabit Ethernet (LAN) | 10–30 ms | Negligible |

For best results, use **5 GHz Wi-Fi** or a wired Ethernet connection.

---

## Thermal Throttling

The RX 580 can reach 70–85°C under sustained inference load. Ensure adequate airflow:

1. **GPU fan** must spin freely — use an open-air test bench or well-ventilated case.
2. **Raspberry Pi** thermal throttles at 80°C — attach an active cooler.
3. Monitor temperatures:

```bash
# GPU temperature (via rocm-smi)
rocm-smi --showtemp

# Pi CPU temperature
vcgencmd measure_temp
```

---

## Power Consumption

| Component | Idle | Load |
|---|---|---|
| Raspberry Pi 5 | ~5 W | ~10–12 W |
| AMD RX 580 | ~15 W | ~120–150 W |
| **Total** | **~20 W** | **~130–162 W** |

Ensure your ATX PSU is ≥ 500 W and the PCIe power cable is firmly connected.

---

## Comparison with Cloud APIs

| Service | Cost/month | Latency | Privacy | Speed (t/s) |
|---|---|---|---|---|
| GhostGPU (this project) | $0 | 50–150 ms | ✅ Local | 15–35 |
| OpenAI GPT-4o | $15–$60+ | 200–800 ms | ❌ Cloud | ~80–200 |
| Groq (free tier) | $0 | 50–200 ms | ❌ Cloud | ~200–500 |
| Local PC RTX 3070 | $0 | 5–20 ms | ✅ Local | 50–80 |

GhostGPU trades some speed for **full local privacy** and **zero ongoing cost**.
