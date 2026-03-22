#!/usr/bin/env bash
# GhostGPU — Raspberry Pi 5 system setup script
# Run as root: sudo ./scripts/setup-pi.sh

set -euo pipefail

echo "=== GhostGPU: Raspberry Pi 5 System Setup ==="

# Check we're running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root (sudo)." >&2
    exit 1
fi

# Detect OS
if [ ! -f /etc/os-release ]; then
    echo "ERROR: Cannot detect OS. Is this Raspberry Pi OS?" >&2
    exit 1
fi
# shellcheck source=/dev/null
. /etc/os-release
echo "Detected OS: $PRETTY_NAME"

echo ""
echo "--- Step 1: Update system packages ---"
apt-get update -y
apt-get upgrade -y

echo ""
echo "--- Step 2: Install required system packages ---"
apt-get install -y \
    git \
    cmake \
    build-essential \
    ninja-build \
    python3 \
    python3-pip \
    curl \
    wget \
    pciutils \
    lshw \
    htop \
    vim \
    libssl-dev \
    libffi-dev

echo ""
echo "--- Step 3: Enable PCIe on Raspberry Pi 5 ---"
CONFIG_FILE="/boot/firmware/config.txt"
if [ ! -f "$CONFIG_FILE" ]; then
    CONFIG_FILE="/boot/config.txt"
fi

if grep -q "dtparam=pcie=on" "$CONFIG_FILE"; then
    echo "PCIe already enabled in $CONFIG_FILE"
else
    {
        echo ""
        echo "# GhostGPU: Enable PCIe interface"
        echo "dtparam=pcie=on"
    } >> "$CONFIG_FILE"
    echo "PCIe enabled in $CONFIG_FILE"
fi

# Enable PCIe Gen 3 (experimental, may improve bandwidth)
if grep -q "dtparam=pciex1_gen=3" "$CONFIG_FILE"; then
    echo "PCIe Gen 3 already configured"
else
    echo "dtparam=pciex1_gen=3" >> "$CONFIG_FILE"
    echo "PCIe Gen 3 configured in $CONFIG_FILE"
fi

echo ""
echo "--- Step 4: Add user to render and video groups ---"
ACTUAL_USER="${SUDO_USER:-pi}"
usermod -aG render,video "$ACTUAL_USER" || true
echo "User $ACTUAL_USER added to render and video groups"

echo ""
echo "--- Step 5: Configure GPU memory (disable Pi GPU blob) ---"
if grep -q "gpu_mem=16" "$CONFIG_FILE"; then
    echo "GPU memory already configured"
else
    {
        echo ""
        echo "# GhostGPU: Minimize VideoCore GPU memory (we use the RX 580)"
        echo "gpu_mem=16"
    } >> "$CONFIG_FILE"
    echo "GPU memory set to 16 MB"
fi

echo ""
echo "=== Setup complete! ==="
echo "Please REBOOT the Raspberry Pi before continuing:"
echo "  sudo reboot"
echo ""
echo "After reboot, run: ./scripts/install-rocm.sh"
