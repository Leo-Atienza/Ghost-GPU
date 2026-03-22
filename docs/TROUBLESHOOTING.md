# GhostGPU Troubleshooting Guide

## GPU Not Detected by `lspci`

**Symptom**: `lspci | grep -i amd` returns nothing.

**Causes & Fixes**:
1. **PCIe riser not seated properly** — Reseat the FFC cable and riser connection.
2. **PSU not providing power to GPU** — Check that the PCIe power cable is connected and the PSU is switched on before booting.
3. **PCIe not enabled on Pi 5** — Run `setup-pi.sh` which adds `dtparam=pcie=on` to `/boot/firmware/config.txt`, then reboot.
4. **Riser compatibility** — Not all risers work with Pi 5. Try a different USB 3.0 to PCIe riser.

```bash
# Check PCIe config
grep pcie /boot/firmware/config.txt
# Should show: dtparam=pcie=on
```

---

## ROCm Does Not See GPU (`rocm-smi` shows no devices)

**Symptom**: `rocm-smi` shows no GPU or `rocminfo` reports no agents.

**Fixes**:
1. Ensure your user is in the `render` and `video` groups:
   ```bash
   sudo usermod -aG render,video $USER
   # Log out and back in
   groups
   ```
2. Check KFD device:
   ```bash
   ls -la /dev/kfd /dev/dri/render*
   ```
3. Reload KFD module:
   ```bash
   sudo modprobe -r amdgpu && sudo modprobe amdgpu
   dmesg | grep -i amdgpu | tail -20
   ```

---

## llama-server Crashes or Reports Out-of-Memory

**Symptom**: `GGML_ASSERT` or `out of memory` error when starting llama-server.

**Fixes**:
1. Reduce `--n-gpu-layers`:
   ```bash
   # Try fewer layers
   --n-gpu-layers 28
   ```
2. Use a lower quantization (Q4_K_M instead of Q8_0).
3. Reduce `--ctx-size`:
   ```bash
   --ctx-size 2048
   ```
4. Check available VRAM:
   ```bash
   rocm-smi --showmeminfo vram
   ```

---

## Poor Performance / Low Tokens Per Second

**Symptom**: Getting <5 t/s when expecting 15–25 t/s.

**Fixes**:
1. Confirm GPU layers are actually being used:
   ```bash
   # Look for lines like: "ggml_hip: found 1 ROCm devices"
   ./llama.cpp/build/bin/llama-server --model ... --n-gpu-layers 35 --verbose 2>&1 | head -30
   ```
2. Check GPU utilization:
   ```bash
   rocm-smi --showuse
   ```
3. Thermal throttling — check temperatures:
   ```bash
   rocm-smi --showtemp
   vcgencmd measure_temp
   ```
4. Confirm ROCm env is sourced:
   ```bash
   source configs/rocm-env.sh
   which rocm-smi
   ```

---

## HSA_OVERRIDE_GFX_VERSION Warnings

**Symptom**: ROCm prints warnings about unsupported GPU or GFX version.

The RX 580 is GFX803 (Polaris). Some ROCm versions require an override:

```bash
export HSA_OVERRIDE_GFX_VERSION=9.0.0
```

This is already set in `configs/rocm-env.sh`. If you still see issues, try:

```bash
export HSA_OVERRIDE_GFX_VERSION=8.0.3
```

---

## systemd Service Fails to Start

**Symptom**: `systemctl status llama-server` shows failed state.

**Fixes**:
1. Check logs:
   ```bash
   sudo journalctl -u llama-server -n 50
   ```
2. Verify the model file path exists:
   ```bash
   ls -lh /home/pi/models/
   ```
3. Verify the llama-server binary exists:
   ```bash
   ls -lh /home/pi/Ghost-GPU/llama.cpp/build/bin/llama-server
   ```
4. Verify the `User=` in the service file matches your username:
   ```bash
   sudo nano /etc/systemd/system/llama-server.service
   sudo systemctl daemon-reload && sudo systemctl restart llama-server
   ```

---

## Connection Refused from Laptop

**Symptom**: `curl: (7) Failed to connect to <pi-ip> port 8080`.

**Fixes**:
1. Confirm llama-server is running:
   ```bash
   systemctl status llama-server
   # or
   ps aux | grep llama-server
   ```
2. Confirm it's listening on `0.0.0.0`, not just `127.0.0.1`:
   ```bash
   ss -tlnp | grep 8080
   ```
3. Check Pi firewall:
   ```bash
   sudo ufw status
   sudo ufw allow 8080
   ```
4. Verify IP address:
   ```bash
   hostname -I
   ```

---

## Still Stuck?

Open an issue at [GitHub Issues](https://github.com/Leo-Atienza/Ghost-GPU/issues) with:
- Output of `lspci | grep -i amd`
- Output of `rocm-smi`
- Output of `dmesg | grep -i amdgpu | tail -30`
- Your Pi model, OS version, ROCm version, and riser model
