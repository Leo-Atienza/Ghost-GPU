# GhostGPU Setup Guide

This guide walks you through setting up a GhostGPU wireless eGPU bridge from scratch.

## Prerequisites

- Raspberry Pi 5 (4 GB or 8 GB recommended)
- AMD Radeon RX 580 (8 GB GDDR5)
- PCIe x1 or x4 riser (USB 3.0 form factor, with power)
- ATX PSU ≥ 500 W
- 32 GB+ microSD card or NVMe SSD (via Pi 5 M.2 HAT)
- 5 GHz Wi-Fi network (802.11ac/ax recommended)
- Linux laptop or desktop as the client

---

## Step 1: Flash Raspberry Pi OS

1. Download [Raspberry Pi Imager](https://www.raspberrypi.com/software/).
2. Select **Raspberry Pi OS (64-bit)** — Bookworm or later.
3. Enable SSH and set your username/password in the imager settings.
4. Flash to your microSD or NVMe.
5. Insert and boot the Pi.

---

## Step 2: Connect the GPU

1. Power off the Pi.
2. Connect the PCIe riser to the Pi 5's PCIe FFC connector (use the official FFC cable for best results).
3. Connect the RX 580 to the riser.
4. Connect PCIe power cables from the ATX PSU to the RX 580.
5. Power on the ATX PSU, then power on the Pi.

---

## Step 3: Verify PCIe Device

SSH into the Pi and run:

```bash
lspci | grep -i amd
```

Expected output:
```
0001:00:00.0 VGA compatible controller: Advanced Micro Devices, Inc. [AMD/ATI] Ellesmere [Radeon RX 470/480/570/570X/580/580X/590] (rev e7)
```

If you don't see the GPU, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

---

## Step 4: Clone GhostGPU

```bash
cd ~
git clone https://github.com/Leo-Atienza/Ghost-GPU.git
cd Ghost-GPU
chmod +x scripts/*.sh
```

---

## Step 5: Run Setup Scripts

```bash
# Install system dependencies and configure PCIe
sudo ./scripts/setup-pi.sh

# Reboot to apply PCIe config changes
sudo reboot
```

After reboot:

```bash
cd ~/Ghost-GPU

# Install ROCm
sudo ./scripts/install-rocm.sh

# Build llama.cpp with HIP/ROCm support
./scripts/build-llama.sh

# Verify ROCm sees the GPU
./scripts/verify-gpu.sh
```

---

## Step 6: Download a Model

```bash
mkdir -p ~/models

# Example: Mistral 7B Instruct Q4_K_M (~4.1 GB)
wget https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf \
     -O ~/models/mistral-7b-instruct-v0.2.Q4_K_M.gguf
```

---

## Step 7: Start the Server

```bash
source configs/rocm-env.sh

./llama.cpp/build/bin/llama-server \
  --model ~/models/mistral-7b-instruct-v0.2.Q4_K_M.gguf \
  --n-gpu-layers 35 \
  --host 0.0.0.0 \
  --port 8080
```

---

## Step 8: Connect from Your Laptop

```bash
# Replace <pi-ip> with your Pi's IP address
curl http://<pi-ip>:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mistral",
    "messages": [{"role": "user", "content": "Hello from GhostGPU!"}]
  }'
```

---

## Step 9: Enable Auto-start (Optional)

```bash
sudo cp configs/llama-server.service /etc/systemd/system/
# Edit the service file to match your model path and username
sudo nano /etc/systemd/system/llama-server.service
sudo systemctl daemon-reload
sudo systemctl enable --now llama-server
sudo journalctl -fu llama-server
```

---

## Next Steps

- See [ARCHITECTURE.md](ARCHITECTURE.md) for a deep dive into how GhostGPU works.
- See [PERFORMANCE.md](PERFORMANCE.md) for tuning tips and benchmarks.
- See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) if something goes wrong.
