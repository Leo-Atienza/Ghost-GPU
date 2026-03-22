#!/usr/bin/env bash
# GhostGPU — ROCm environment configuration
# Source this file before running ROCm/HIP applications:
#   source configs/rocm-env.sh

set -euo pipefail

ROCM_VERSION="${ROCM_VERSION:-5.7.1}"
ROCM_PATH="${ROCM_PATH:-/opt/rocm-${ROCM_VERSION}}"

# Fallback to generic /opt/rocm symlink if versioned path doesn't exist
if [ ! -d "${ROCM_PATH}" ] && [ -d "/opt/rocm" ]; then
    ROCM_PATH="/opt/rocm"
fi

if [ ! -d "${ROCM_PATH}" ]; then
    echo "ERROR: ROCm not found at ${ROCM_PATH}" >&2
    echo "Run sudo ./scripts/install-rocm.sh first." >&2
    # shellcheck disable=SC2317
    return 1 2>/dev/null || exit 1
fi

export ROCM_PATH
export PATH="${ROCM_PATH}/bin:${ROCM_PATH}/hip/bin:${PATH}"
export LD_LIBRARY_PATH="${ROCM_PATH}/lib:${ROCM_PATH}/hip/lib:${LD_LIBRARY_PATH:-}"
export HIP_PATH="${ROCM_PATH}/hip"
export ROCR_VISIBLE_DEVICES="${ROCR_VISIBLE_DEVICES:-0}"
export HSA_OVERRIDE_GFX_VERSION="${HSA_OVERRIDE_GFX_VERSION:-9.0.0}"

# AMD RX 580 is GFX803 (Polaris 20), but ROCm may need gfx900 override
# for certain workloads. Adjust if needed.
export HCC_AMDGPU_TARGET="${HCC_AMDGPU_TARGET:-gfx803}"

echo "✅ ROCm environment loaded from ${ROCM_PATH}"
echo "   HIP_PATH=${HIP_PATH}"
echo "   HCC_AMDGPU_TARGET=${HCC_AMDGPU_TARGET}"
echo "   ROCR_VISIBLE_DEVICES=${ROCR_VISIBLE_DEVICES}"
