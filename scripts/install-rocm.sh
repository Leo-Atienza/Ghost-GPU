#!/usr/bin/env bash
# GhostGPU — ROCm 5.x installation script for Raspberry Pi 5 (ARM64)
# Run as root: sudo ./scripts/install-rocm.sh

set -euo pipefail

ROCM_VERSION="${ROCM_VERSION:-5.7.1}"
AMDGPU_INSTALL_DEB="amdgpu-install_5.7.50701-1_all.deb"
AMDGPU_INSTALL_URL="https://repo.radeon.com/amdgpu-install/5.7.1/ubuntu/jammy/${AMDGPU_INSTALL_DEB}"

echo "=== GhostGPU: Installing ROCm ${ROCM_VERSION} ==="
echo ""

# Check we're running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root (sudo)." >&2
    exit 1
fi

# Check for ARM64
ARCH="$(uname -m)"
if [ "$ARCH" != "aarch64" ]; then
    echo "WARNING: This script is designed for ARM64 (aarch64). Detected: $ARCH" >&2
    echo "ROCm ARM64 support is experimental. Proceeding anyway..." >&2
fi

echo "--- Step 1: Install prerequisites ---"
apt-get update -y
apt-get install -y wget curl gnupg2 lsb-release software-properties-common

echo ""
echo "--- Step 2: Download amdgpu-install ---"
cd /tmp
if [ -f "$AMDGPU_INSTALL_DEB" ]; then
    echo "amdgpu-install already downloaded"
else
    echo "Downloading from ${AMDGPU_INSTALL_URL}..."
    wget -q --show-progress "$AMDGPU_INSTALL_URL" -O "$AMDGPU_INSTALL_DEB"
fi

echo ""
echo "--- Step 3: Install amdgpu-install ---"
dpkg -i "$AMDGPU_INSTALL_DEB"
apt-get install -f -y

echo ""
echo "--- Step 4: Install ROCm components ---"
amdgpu-install --usecase=rocm --no-dkms -y || {
    echo "DKMS install failed; trying rocm only..."
    amdgpu-install --usecase=rocm -y
}

echo ""
echo "--- Step 5: Install additional ROCm packages ---"
apt-get install -y \
    rocm-dev \
    rocm-libs \
    rocm-hip-sdk \
    rocblas \
    hipblas \
    rocm-smi-lib \
    || echo "WARNING: Some packages may not be available for ARM64. Continuing..."

echo ""
echo "--- Step 6: Add user to groups ---"
ACTUAL_USER="${SUDO_USER:-pi}"
usermod -aG render,video "$ACTUAL_USER" || true
echo "User $ACTUAL_USER added to render and video groups"

echo ""
echo "--- Step 7: Set ROCm environment for future sessions ---"
ROCM_ENV_FILE="/etc/profile.d/rocm.sh"
cat > "$ROCM_ENV_FILE" << 'EOF'
# ROCm environment (added by GhostGPU install-rocm.sh)
export ROCM_PATH=/opt/rocm
export PATH="${ROCM_PATH}/bin:${ROCM_PATH}/hip/bin:${PATH}"
export LD_LIBRARY_PATH="${ROCM_PATH}/lib:${ROCM_PATH}/hip/lib:${LD_LIBRARY_PATH:-}"
export HIP_PATH="${ROCM_PATH}/hip"
export HCC_AMDGPU_TARGET="gfx803"
export HSA_OVERRIDE_GFX_VERSION="9.0.0"
EOF
chmod +x "$ROCM_ENV_FILE"
echo "ROCm environment written to $ROCM_ENV_FILE"

echo ""
echo "=== ROCm ${ROCM_VERSION} installation complete! ==="
echo ""
echo "Please log out and back in (or reboot) for group changes to take effect."
echo "Then run: ./scripts/verify-gpu.sh"
