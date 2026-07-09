
#!/bin/bash
# =====================================================================
# setup_workspace.sh
# Configura de forma modular y reproducible un entorno de simulación
# para el robot Unitree G1 EDU (unitree_sdk2 + unitree_mujoco) en WSL2.
# =====================================================================
set -e
set -o pipefail

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDK_INSTALL_PREFIX="/opt/unitree_robotics"
MUJOCO_VERSION="3.3.6"
MUJOCO_HOME="$HOME/.mujoco"
MUJOCO_DIR="$MUJOCO_HOME/mujoco-${MUJOCO_VERSION}"

SDK_DIR="$WORKSPACE_DIR/external/unitree_sdk2"
MUJOCO_SIM_DIR="$WORKSPACE_DIR/external/unitree_mujoco"
MUJOCO_SIMULATE_DIR="$MUJOCO_SIM_DIR/simulate"

log()  { echo -e "\n\033[1;32m==> $1\033[0m"; }
warn() { echo -e "\033[1;33m[!] $1\033[0m"; }

# ---------------------------------------------------------------------
# 1. Dependencias del sistema (Incluyendo SSL para DDS y Mesa para WSL2)
# ---------------------------------------------------------------------
log "[1/6] Instalando dependencias del sistema..."
sudo apt update
sudo apt install -y \
    build-essential cmake git git-lfs python3-pip python3-venv wget \
    libyaml-cpp-dev libspdlog-dev libboost-all-dev libglfw3-dev \
    libeigen3-dev libfmt-dev libssl-dev libpng-dev \
    libxinerama-dev libxcursor-dev libxi-dev \
    mesa-utils libgl1-mesa-dri libglx-mesa0 libosmesa6-dev

# ---------------------------------------------------------------------
# 2. Submódulos Quirúrgicos (Evita romper por culpa de IsaacLab)
# ---------------------------------------------------------------------
log "[2/6] Inicializando submódulos críticos de forma selectiva..."
cd "$WORKSPACE_DIR"

# En lugar de "all", traemos explícitamente lo necesario para MuJoCo
git submodule update --init --recursive external/unitree_sdk2
git submodule update --init --recursive external/unitree_mujoco

if [ ! -d "$SDK_DIR" ] || [ -z "$(ls -A "$SDK_DIR" 2>/dev/null)" ]; then
    warn "Error: external/unitree_sdk2 no se descargó correctamente."
    exit 1
fi
if [ ! -d "$MUJOCO_SIM_DIR" ] || [ -z "$(ls -A "$MUJOCO_SIM_DIR" 2>/dev/null)" ]; then
    warn "Error: external/unitree_mujoco no se descargó correctamente."
    exit 1
fi

# ---------------------------------------------------------------------
# 3. Compilar e instalar unitree_sdk2
# ---------------------------------------------------------------------
log "[3/6] Compilando e instalando unitree_sdk2 en ${SDK_INSTALL_PREFIX}..."
cd "$SDK_DIR"
rm -rf build && mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX="${SDK_INSTALL_PREFIX}" -DCMAKE_BUILD_TYPE=Release
make -j"$(nproc)"
sudo make install

# Ajustamos paths locales para el entorno de compilación actual
export CMAKE_PREFIX_PATH="${SDK_INSTALL_PREFIX}:${CMAKE_PREFIX_PATH}"
export LD_LIBRARY_PATH="${SDK_INSTALL_PREFIX}/lib:${LD_LIBRARY_PATH}"

# ---------------------------------------------------------------------
# 4. Descarga y Preparación de MuJoCo Binario
# ---------------------------------------------------------------------
log "[4/6] Preparando MuJoCo ${MUJOCO_VERSION}..."
mkdir -p "$MUJOCO_HOME"
if [ ! -d "$MUJOCO_DIR" ]; then
    cd /tmp
    MUJOCO_TARBALL="mujoco-${MUJOCO_VERSION}-linux-x86_64.tar.gz"
    wget -q --show-progress "https://github.com/google-deepmind/mujoco/releases/download/${MUJOCO_VERSION}/${MUJOCO_TARBALL}"
    tar -xf "$MUJOCO_TARBALL" -C "$MUJOCO_HOME"
    rm -f "$MUJOCO_TARBALL"
else
    log "MuJoCo ${MUJOCO_VERSION} detectado, omitiendo descarga."
fi

# Simlink clásico por si el fuente interno de unitree lo requiere de forma estática
if [ -L "$MUJOCO_SIMULATE_DIR/mujoco" ] || [ -e "$MUJOCO_SIMULATE_DIR/mujoco" ]; then
    rm -f "$MUJOCO_SIMULATE_DIR/mujoco"
fi
ln -s "$MUJOCO_DIR" "$MUJOCO_SIMULATE_DIR/mujoco"

# ---------------------------------------------------------------------
# 5. Compilar unitree_mujoco apuntando enlaces de CMake correctamente
# ---------------------------------------------------------------------
log "[5/6] Compilando unitree_mujoco/simulate..."
cd "$MUJOCO_SIMULATE_DIR"
rm -rf build && mkdir build && cd build

# CRÍTICO: Le pasamos los dos paths a CMake para que resuelva dependencias simbióticas
cmake .. \
    -DCMAKE_PREFIX_PATH="${SDK_INSTALL_PREFIX};${MUJOCO_DIR}" \
    -DCMAKE_BUILD_TYPE=Release

make -j"$(nproc)"

# ---------------------------------------------------------------------
# 6. Configurar el Robot por defecto & Crear Lanzador de Entorno
# ---------------------------------------------------------------------
log "[6/6] Aplicando configuraciones de entorno y generación de scripts..."
CONFIG_FILE="$MUJOCO_SIMULATE_DIR/config.yaml"
if [ -f "$CONFIG_FILE" ]; then
    # Cambiamos el robot por defecto a g1
    sed -i 's/^robot:.*/robot: "g1"/' "$CONFIG_FILE"
    # Sintonizamos el canal DDS al dominio 0 para que hable con el SDK
    sed -i 's/^domain_id:.*/domain_id: 0/' "$CONFIG_FILE"
else
    warn "No se encontró config.yaml, verifica el estado del repositorio externo."
fi

# Crear el script automatizado para correr la simulación
cat << 'EOF' > "$WORKSPACE_DIR/run_simulation.sh"
#!/bin/bash
WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDK_INSTALL_PREFIX="/opt/unitree_robotics"
MUJOCO_SIMULATE_DIR="$WORKSPACE_DIR/external/unitree_mujoco/simulate"

# Exportar librerías dinámicas del SDK
export LD_LIBRARY_PATH="${SDK_INSTALL_PREFIX}/lib:${LD_LIBRARY_PATH}"

# === APARTADO GRÁFICO OPTIMIZADO PARA NVIDIA EN WSL2 ===
unset LIBGL_ALWAYS_SOFTWARE
export MESA_D3D12_DEFAULT_DEVICE_TYPE=GPU
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia

cd "$MUJOCO_SIMULATE_DIR/build"
if [ -f "./unitree_mujoco" ]; then
    ./unitree_mujoco
else
    echo "Error: No se encontró el binario compilado. Ejecuta ./setup_workspace.sh primero."
fi
EOF

chmod +x "$WORKSPACE_DIR/run_simulation.sh"

log "¡Configuración completada con éxito!"
echo "Para simular el G1 ejecute directamente: ./run_simulation.sh"
