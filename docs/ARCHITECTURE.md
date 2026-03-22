# GhostGPU Architecture

## Overview

GhostGPU creates a wireless eGPU (external GPU) bridge using commodity hardware. It routes GPU compute from a client laptop over Wi-Fi, through a Raspberry Pi 5, to an AMD Radeon RX 580 connected via a PCIe riser.

```
┌─────────────────────────┐              ┌───────────────────────────────────────┐
│       Client Laptop     │              │          Raspberry Pi 5               │
│                         │   Wi-Fi      │                                       │
│  ┌─────────────────┐    │ ◄──────────► │  ┌──────────────────────────────┐    │
│  │  llama.cpp      │    │  HTTP/WS     │  │  llama-server                │    │
│  │  (client mode   │    │  port 8080   │  │  --n-gpu-layers 35           │    │
│  │   or any        │    │              │  │  --host 0.0.0.0              │    │
│  │   OpenAI API    │    │              │  └────────────┬─────────────────┘    │
│  │   client)       │    │              │               │ ROCm HIP API          │
│  └─────────────────┘    │              │  ┌────────────▼─────────────────┐    │
│                         │              │  │  ROCm Runtime (5.x)          │    │
└─────────────────────────┘              │  │  HSA / KFD driver            │    │
                                         │  └────────────┬─────────────────┘    │
                                         │               │ PCIe x1 riser         │
                                         └───────────────┼───────────────────────┘
                                                         │
                                             ┌───────────▼───────────┐
                                             │  AMD Radeon RX 580    │
                                             │  8 GB GDDR5           │
                                             │  2304 stream procs    │
                                             │  GFX803 (Polaris 20)  │
                                             └───────────────────────┘
```

---

## Component Roles

### Raspberry Pi 5
- Acts as the **GPU host**: it physically connects to the RX 580 via PCIe.
- Runs the **llama-server** (from llama.cpp), exposing an OpenAI-compatible HTTP API on port 8080.
- ROCm communicates with the RX 580 via the **HSA/KFD** kernel driver stack.
- Accessible on the local Wi-Fi network by its IP address.

### AMD Radeon RX 580
- Provides **GPU compute** for LLM inference (matrix multiplications, attention layers).
- Connected via a **PCIe riser** to the Pi 5's PCIe FFC connector.
- Powered independently by an ATX PSU.
- Identified by ROCm as GFX803 (Polaris architecture).

### ROCm Stack
- **KFD (Kernel Fusion Driver)**: kernel module that exposes the GPU to userspace.
- **HSA Runtime**: heterogeneous system architecture runtime layer.
- **HIP**: ROCm's CUDA-compatible compute API used by llama.cpp.
- **rocBLAS / hipBLAS**: GPU-accelerated BLAS libraries for fast matrix ops.

### llama.cpp
- LLM inference engine written in C++.
- Built with `LLAMA_HIP=1` to enable GPU offload via ROCm.
- `--n-gpu-layers N` controls how many model layers are offloaded to the RX 580.
- Exposes an OpenAI-compatible REST API (`/v1/chat/completions`, `/v1/completions`).

### Client (Laptop)
- Any HTTP client, OpenAI SDK, or llama.cpp client binary.
- Points to `http://<pi-ip>:8080` instead of `api.openai.com`.
- No GPU required on the client side — all inference is done on the Pi + RX 580.

---

## Data Flow

```
User prompt (laptop)
    │
    ▼
HTTP POST /v1/chat/completions (Wi-Fi)
    │
    ▼
llama-server (Pi 5, port 8080)
    │
    ▼
llama.cpp inference engine
    │  (CPU handles tokenization, non-offloaded layers)
    │  (GPU handles offloaded layers via HIP)
    ▼
AMD RX 580 (GDDR5, 2304 shaders)
    │
    ▼
Token stream response (HTTP chunked / SSE)
    │
    ▼
Client receives streamed tokens
```

---

## PCIe Connectivity

The Pi 5 exposes a single PCIe 2.0 x1 lane via its FFC connector. The riser adapter converts this to a standard PCIe x16 slot (electrically x1 or x4 depending on riser). Bandwidth is limited but sufficient for GPU VRAM transfers during inference.

| Link | Bandwidth |
|---|---|
| PCIe 2.0 x1 | ~500 MB/s |
| PCIe 2.0 x4 | ~2 GB/s |
| GDDR5 (RX 580 internal) | ~256 GB/s |

The bottleneck for inference is compute, not PCIe bandwidth (model weights are loaded once into VRAM).

---

## Network Protocol

GhostGPU uses the **OpenAI REST API** protocol:

- `POST /v1/chat/completions` — chat completions (streaming SSE supported)
- `POST /v1/completions` — raw text completions
- `GET /v1/models` — list loaded models
- `GET /health` — server health check

---

## Security Notes

- The API is unauthenticated by default. **Use only on a trusted local network.**
- Consider adding a reverse proxy (nginx/caddy) with basic auth or mTLS for any exposure beyond LAN.
- The Pi should be on a separate IoT VLAN if possible.
