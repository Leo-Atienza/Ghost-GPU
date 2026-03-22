#!/usr/bin/env bash
# GhostGPU — Verify ROCm GPU detection
# Run as your regular user: ./scripts/verify-gpu.sh

set -euo pipefail

echo "=== GhostGPU: GPU Verification ==="
echo ""

PASS=0
FAIL=0

check() {
    local label="$1"
    local cmd="$2"
    echo "--- ${label} ---"
    if eval "$cmd" 2>&1; then
        echo "✅ PASS: ${label}"
        PASS=$((PASS + 1))
    else
        echo "❌ FAIL: ${label}"
        FAIL=$((FAIL + 1))
    fi
    echo ""
}

# Load ROCm environment
if [ -f "configs/rocm-env.sh" ]; then
    # shellcheck source=configs/rocm-env.sh
    source configs/rocm-env.sh
elif [ -d "/opt/rocm" ]; then
    export PATH="/opt/rocm/bin:${PATH}"
    export LD_LIBRARY_PATH="/opt/rocm/lib:${LD_LIBRARY_PATH:-}"
    export HSA_OVERRIDE_GFX_VERSION="${HSA_OVERRIDE_GFX_VERSION:-9.0.0}"
fi

# 1. PCIe device detection
check "PCIe GPU detection (lspci)" "lspci | grep -i amd"

# 2. KFD device node
check "KFD device node exists" "ls -la /dev/kfd"

# 3. DRI render nodes
check "DRI render node exists" "ls /dev/dri/render* 2>/dev/null"

# 4. rocm-smi
check "rocm-smi GPU list" "rocm-smi --showproductname"

# 5. rocminfo
check "rocminfo GPU agents" "rocminfo 2>/dev/null | grep -A3 'Agent [0-9]' | head -30"

# 6. hipcc version
check "hipcc version" "hipcc --version"

# 7. ROCm BLAS
check "rocBLAS library present" "ls /opt/rocm/lib/librocblas* 2>/dev/null || ls /opt/rocm/rocblas/lib/librocblas* 2>/dev/null"

# 8. llama-server binary
check "llama-server binary built" "test -x llama.cpp/build/bin/llama-server && echo 'Found: llama.cpp/build/bin/llama-server'"

echo "==============================="
echo "Results: ${PASS} passed, ${FAIL} failed"
echo ""

if [ "$FAIL" -eq 0 ]; then
    echo "✅ All checks passed! GhostGPU is ready."
    echo ""
    echo "Start the server:"
    echo "  source configs/rocm-env.sh"
    echo "  ./llama.cpp/build/bin/llama-server --model ~/models/<model>.gguf --n-gpu-layers 35 --host 0.0.0.0 --port 8080"
else
    echo "⚠️  Some checks failed. See docs/TROUBLESHOOTING.md for help."
    exit 1
fi
