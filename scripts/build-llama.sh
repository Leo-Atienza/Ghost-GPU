#!/usr/bin/env bash
# GhostGPU — Build llama.cpp with ROCm/HIP support
# Run as your regular user (NOT root): ./scripts/build-llama.sh

set -euo pipefail

LLAMA_DIR="${LLAMA_DIR:-llama.cpp}"
LLAMA_REPO="https://github.com/ggerganov/llama.cpp.git"
ROCM_PATH="${ROCM_PATH:-/opt/rocm}"
BUILD_DIR="${LLAMA_DIR}/build"
JOBS="$(nproc)"

echo "=== GhostGPU: Building llama.cpp with ROCm/HIP ==="
echo ""

# Load ROCm environment if available
if [ -f "configs/rocm-env.sh" ]; then
    # shellcheck source=/dev/null
    source configs/rocm-env.sh
elif [ -d "$ROCM_PATH" ]; then
    export PATH="${ROCM_PATH}/bin:${PATH}"
    export LD_LIBRARY_PATH="${ROCM_PATH}/lib:${LD_LIBRARY_PATH:-}"
    export HIP_PATH="${ROCM_PATH}/hip"
    export HCC_AMDGPU_TARGET="${HCC_AMDGPU_TARGET:-gfx803}"
    export HSA_OVERRIDE_GFX_VERSION="${HSA_OVERRIDE_GFX_VERSION:-9.0.0}"
else
    echo "WARNING: ROCm not found at $ROCM_PATH. Building CPU-only fallback." >&2
    ROCM_AVAILABLE=false
fi

ROCM_AVAILABLE="${ROCM_AVAILABLE:-true}"

echo "--- Step 1: Clone or update llama.cpp ---"
if [ -d "$LLAMA_DIR/.git" ]; then
    echo "llama.cpp already cloned. Pulling latest..."
    git -C "$LLAMA_DIR" pull
else
    echo "Cloning llama.cpp from ${LLAMA_REPO}..."
    git clone --depth=1 "$LLAMA_REPO" "$LLAMA_DIR"
fi

echo ""
echo "--- Step 2: Configure build ---"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

if [ "$ROCM_AVAILABLE" = "true" ]; then
    echo "Configuring with ROCm/HIP support (AMDGPU_TARGETS=${HCC_AMDGPU_TARGET:-gfx803})"
    cmake .. \
        -DGGML_HIP=ON \
        -DAMDGPU_TARGETS="${HCC_AMDGPU_TARGET:-gfx803}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DLLAMA_NATIVE=OFF \
        -GNinja
else
    echo "Configuring CPU-only build"
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DLLAMA_NATIVE=OFF \
        -GNinja
fi

echo ""
echo "--- Step 3: Build (using ${JOBS} parallel jobs) ---"
echo "This may take 20–40 minutes on Raspberry Pi 5..."
cmake --build . --parallel "$JOBS"

cd - > /dev/null

echo ""
echo "=== Build complete! ==="
echo ""
echo "Binary location: ${BUILD_DIR}/bin/llama-server"
ls -lh "${BUILD_DIR}/bin/llama-server" 2>/dev/null || echo "WARNING: llama-server binary not found in expected location."
echo ""
echo "Next step: download a model and start the server."
echo "See docs/SETUP_GUIDE.md for instructions."
