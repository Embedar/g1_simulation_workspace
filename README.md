# 🤖 Unitree G1 EDU - Control & Simulation Workspace

Este repositorio está diseñado para la **investigación, desarrollo y prueba de algoritmos de control** sobre el robot humanoide Unitree G1 EDU. Proporciona un entorno modular y reproducible utilizando MuJoCo y el Unitree SDK2 dentro de un entorno WSL2 (Ubuntu).

![Demostración de Simulación G1](aqui_pondremos_el_link_de_tu_gif.gif)

## 🚀 Requisitos Previos
* **SO:** Windows 11 con WSL2 (Ubuntu 22.04+).
* **GPU:** Aceleración por hardware habilitada (El entorno está optimizado para renderizado nativo en GPU).
* **Red:** Interfaz local `lo` con soporte multicast (requerido para la comunicación DDS).

## 🛠️ Instalación y Configuración

Para garantizar que todas las dependencias y submódulos (SDK y Simulador) se descarguen correctamente, clona el repositorio con el siguiente comando:

```bash
git clone --recurse-submodules [https://github.com/Embedar/g1_simulation_workspace.git](https://github.com/Embedar/g1_simulation_workspace.git)
cd g1_simulation_workspace
```

Una vez dentro de la carpeta principal, ejecuta el script de configuración automática:

```bash
chmod +x setup_workspace.sh
./setup_workspace.sh
```
*Este script instalará las librerías del sistema, compilará el Unitree SDK2, configurará los enlaces de MuJoCo y sintonizará el dominio DDS.*

## 🏃‍♂️ Ejecución de la Simulación (Paso a Paso)

Debido a la arquitectura de red de WSL2, es **obligatorio** habilitar el protocolo multicast cada vez que reinicies tu computadora. Sigue este orden operando siempre desde la carpeta principal del repositorio (`g1_simulation_workspace`):

### 1. Iniciar el Entorno Físico (Terminal 1)
Habilita el multicast y lanza el simulador gráfico MuJoCo:
```bash
sudo ip link set dev lo multicast on
./run_simulation.sh
```

### 2. Ejecutar Algoritmos de Control (Terminal 2)
El entorno compila automáticamente los ejemplos oficiales del Unitree SDK2. Para probar el movimiento del robot y enviarle comandos, abre una nueva terminal, navega a la carpeta de binarios y ejecuta el algoritmo deseado apuntando a la red local (`lo`):

```bash
cd external/unitree_sdk2/build/bin
./g1_dual_arm_example lo
```
*El robot en la ventana de MuJoCo responderá inmediatamente a los comandos de posición/torque enviados por el algoritmo.*
