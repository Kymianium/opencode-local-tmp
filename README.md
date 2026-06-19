# OpenCode con GLM 5.2 Local - Docker Compose Setup

Este proyecto te permite levantar un entorno local de desarrollo utilizando **OpenCode** (el agente de programación de código abierto) conectado a un modelo **GLM 5.2** (Mixture-of-Experts) ejecutándose localmente a través de **Ollama**.

El entorno está optimizado para funcionar con aceleración por GPU (NVIDIA), ideal para ejecutarse en plataformas de alto rendimiento como tu **DGX SPARK**.

---

## Estructura del Proyecto

*   `docker-compose.yml`: Define los servicios de Ollama, el descargador automático del modelo y el servidor de OpenCode.
*   `config/opencode.json`: Archivo de configuración que mapea OpenCode para consumir la API OpenAI-compatible de Ollama y utilizar el modelo `glm-5.2`.
*   `workspace/`: Carpeta compartida donde puedes colocar tus proyectos para que OpenCode pueda leerlos, modificarlos y trabajar en ellos.
*   `.env`: Archivo de configuración de variables de entorno (puertos, contraseñas, etiquetas de modelos).

---

## Requisitos Previos

1.  **Docker** y **Docker Compose** instalados.
2.  **NVIDIA Container Toolkit** instalado y configurado en Docker (para que Ollama pueda hacer uso de las GPUs de tu servidor DGX).

---

## Cómo Levantar el Entorno

1.  **(Opcional) Ajustar Configuración**: Abre el archivo `.env` para cambiar la contraseña predeterminada de OpenCode, ajustar puertos o modificar la versión del modelo.
2.  **Iniciar los Contenedores**:
    Ejecuta el siguiente comando en la raíz del proyecto para iniciar los servicios en segundo plano:
    ```bash
    docker compose up -d
    ```
3.  **Monitorear la descarga del modelo**:
    Como GLM 5.2 es un modelo de gran escala, la primera vez tardará en descargarse. Puedes ver el progreso de la descarga en tiempo real ejecutando:
    ```bash
    docker compose logs -f ollama-pull-model
    ```
4.  **Verificar el uso de GPU**:
    Mientras el modelo se descarga o se ejecuta, puedes verificar que Ollama está detectando y utilizando las GPUs del DGX corriendo en la máquina host:
    ```bash
    nvidia-smi
    ```

---

## Cómo Trabajar con OpenCode

Una vez que los contenedores estén levantados y el modelo se haya descargado por completo:

### 1. Colocar tu Proyecto
Pon los archivos de tu proyecto dentro de la carpeta local `./workspace/` en este directorio. Cualquier cambio que hagas en esta carpeta en tu máquina host será visible inmediatamente para OpenCode en `/workspace` dentro del contenedor.

### 2. Acceder al Servidor de OpenCode
OpenCode iniciará en modo servidor (`opencode serve`). Puedes conectarte a él de las siguientes maneras:

*   **A través del Navegador / Web UI (si se implementa o conecta a un cliente compatible)**:
    Accede a `http://localhost:4096` (o la IP de tu servidor DGX en el puerto `4096`).
*   **Mediante contraseña**:
    Cuando te solicite credenciales, utiliza la contraseña definida en tu archivo `.env` (por defecto `opencode_secure_pass`).
*   **Conexión por CLI / TUI**:
    Si tienes instalado el cliente local de OpenCode en tu máquina, puedes conectarte directamente al backend remoto ejecutando:
    ```bash
    opencode run --attach http://<IP_DEL_DGX>:4096
    ```

### 3. Usar OpenCode interactivo en la Terminal
Si deseas interactuar con OpenCode directamente desde la línea de comandos (utilizando la interfaz TUI nativa) sin pasar por el servidor web, puedes levantar la base de datos de Ollama de fondo y ejecutar el cliente interactivo directamente:

1. Levanta el servicio Ollama en segundo plano (y el descargador del modelo):
   ```bash
   docker compose up -d ollama
   ```
2. Lanza la interfaz de terminal interactiva de OpenCode:
   ```bash
   docker compose run --rm -it opencode-cli
   ```

---

## Personalización y Resolución de Problemas

### Cambiar de Modelo
Si necesitas probar un modelo más ligero para depurar o verificar la conectividad rápidamente (por ejemplo, `qwen2.5-coder:7b`), simplemente:
1.  Modifica el valor de `OLLAMA_MODEL_TAG` en el archivo `.env`.
2.  Actualiza el nombre del modelo correspondiente en `config/opencode.json` (sección `models` y `model`).
3.  Ejecuta `docker compose up -d` para reiniciar el puller y descargar el nuevo modelo.

### Permisos del Workspace
El contenedor de OpenCode corre bajo usuario `root` por defecto, mapeando `./workspace` a `/workspace`. Si tienes problemas de lectura/escritura de archivos creados por el agente desde el host, asegúrate de ajustar los permisos de la carpeta en Linux (`chmod -R 777 ./workspace` o asignando el UID/GID correcto).
