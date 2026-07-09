# 🤖 G1 EDU - Simulation Workspace

Entorno modular y reproducible para simular el robot humanoide Unitree G1 EDU utilizando MuJoCo y el Unitree SDK2 en un entorno WSL2 (Ubuntu).

## 🚀 Requisitos Previos
* **SO:** Windows 11 con WSL2 (Ubuntu 22.04+).
* **GPU:** Aceleración por hardware habilitada (probado en NVIDIA RTX 4060).
* **Red:** Interfaz local `lo` con multicast activado.

## 🛠️ Instalación y Configuración (Clonar en otra máquina)

1. **Clonar el repositorio con todos sus submódulos:**
   ```bash
   git clone --recurse-submodules [https://github.com/TU_USUARIO/g1_simulation_workspace.git](https://github.com/TU_USUARIO/g1_simulation_workspace.git)
   cd g1_simulation_workspace
Ejecutar el script de configuración automática:

Bash
chmod +x setup_workspace.sh
./setup_workspace.sh
Nota: Este script instalará dependencias, compilará el SDK, configurará MuJoCo y sintonizará el dominio DDS a 0.

🏃‍♂️ Ejecución de la Simulación
Habilitar Multicast en WSL2 (Requerido en cada reinicio):

Bash
sudo ip link set dev lo multicast on
Lanzar el entorno gráfico MuJoCo:

Bash
./run_simulation.sh
