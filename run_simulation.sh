#!/bin/bash
WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDK_INSTALL_PREFIX="/opt/unitree_robotics"
MUJOCO_SIMULATE_DIR="$WORKSPACE_DIR/external/unitree_mujoco/simulate"

# Exportar librerías dinámicas del SDK
export LD_LIBRARY_PATH="${SDK_INSTALL_PREFIX}/lib:${LD_LIBRARY_PATH}"

# === APARTADO GRÁFICO OPTIMIZADO PARA NVIDIA EN WSL2 ===
# Quitamos el modo software y forzamos el uso del driver D3D12 acoplado a Windows
unset LIBGL_ALWAYS_SOFTWARE
export MESA_D3D12_DEFAULT_DEVICE_TYPE=GPU
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia

cd "$MUJOCO_SIMULATE_DIR/build"
if [ -f "./unitree_mujoco" ]; then
    ./unitree_mujoco
else
    echo "Error: No se encontró el binario compilado."
fi
