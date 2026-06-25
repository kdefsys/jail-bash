# jail-bash ⛓️

[![Bash Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Security Focus](https://img.shields.io/badge/Focus-Cybersecurity%20%7C%20Sandboxing-red?logo=linuxfoundation&logoColor=white)](https://en.wikipedia.org/wiki/Sandbox_(computer_security))

**jail-bash** es una herramienta nativa de automatización de seguridad y administración de sistemas escrita en Bash. Su objetivo principal es el despliegue dinámico de entornos de ejecución restringidos (*chroot jails*), aislando procesos y usuarios rebeldes dentro de un mini-FHS (*Filesystem Hierarchy Standard*) controlado.

A diferencia de configuraciones manuales propensas a errores, **jail-bash** implementa un motor automatizado de resolución de dependencias binarias que utiliza `ldd` para rastrear, mapear y clonar objetos compartidos (`.so`), garantizando que los binarios aislados funcionen sin exponer librerías ni rutas críticas del sistema anfitrión (*host*).

---

## 🧠 Principios de Funcionamiento Técnico

Para lograr un aislamiento seguro sin la sobrecarga de un contenedor Docker completo, **jail-bash** modifica dinámicamente el entorno del proceso hijo en 4 etapas críticas:

1. **Abstracción del Sistema de Archivos Virtual:** Genera un árbol de directorios mínimo clonando las rutas `/bin`, `/lib`, `/lib64`, y `/proc` en un subdirectorio aislado.
2. **Resolución Estática de Enlaces Dinámicos:** Analiza los ejecutables permitidos mediante `ldd`, parseando las direcciones de memoria y copiando las dependencias de bajo nivel exactas (como `libc.so` y el enlazador dinámico `ld-linux-*.so`).
3. **Aislamiento del Espacio de Nombres de Procesos:** Monta una instancia independiente del sistema de archivos `procfs` dentro de la jaula, limitando la visibilidad del Kernel para que el usuario encarcelado no pueda interactuar con los PIDs del host.
4. **Mutación de la Raíz POSIX:** Invoca la llamada al sistema `chroot` para redefinir el nodo raíz (`/`) del proceso ejecutor, denegando cualquier vector de escape (*escape vectors*) hacia el sistema de archivos anfitrión.

---

## 📂 Arquitectura del Proyecto

```text
jail-bash/
├── core/
│   ├── main.sh          # Interfaz de comandos y orquestador del ciclo de vida
│   ├── jailer.sh        # Lógica de montaje, inicialización de FHS y chroot
│   └── deps_copier.sh   # Motor de análisis sintáctico y clonación con 'ldd'
├── config/
│   └── jail.conf        # Directivas de configuración y lista blanca de binarios
└── Makefile             # Despliegue global automatizado en el sistema operativo
```

---

## 🛠️ Instalación y Configuración

### Requisitos Mínimos
* Sistema Operativo Linux (Kernel 2.6+).
* Privilegios de superusuario (`sudo`) para la manipulación del árbol de directorios raíz y montajes del Kernel.
* Utilidades esenciales de espacio de usuario: `gawk`, `ldd`, `mount`.

### Despliegue Automatizado
Clona el repositorio e instala la herramienta globalmente siguiendo el estándar del sistema de archivos jerárquico de Linux:

```bash
git clone [https://github.com/kdefsys/jail-bash.git](https://github.com/kdefsys/jail-bash.git)
cd jail-bash
sudo make install
```

---

## ⚙️ Directivas de Configuración

El comportamiento de la jaula y el endurecimiento del entorno (*hardening*) se definen en el archivo `/etc/jail-bash/jail.conf`:

```bash
# Ruta absoluta del directorio que actuará como raíz aislada
JAIL_PATH="/var/lib/jailbash/sandbox"

# Lista blanca de binarios del sistema permitidos dentro de la celda
# El script resolverá automáticamente las librerías dinámicas para cada uno
COMMANDS_WHITELIST=(
    "/bin/bash"
    "/bin/ls"
    "/bin/cat"
    "/bin/mkdir"
    "/usr/bin/id"
)
```
---

## 📊 Demostración de Uso

**1. Inicialización y Construcción de la jaula**

Ejecuta el orquestador principal para construir el mini-FHS, resolver dependencias dinámicas e inyectar los binarios configurados:

``` sudo jail-bash --build ```

Ejemplo de salida del proceso de construcción:

```
[jail-bash] [INFO] Inicializando entorno en /var/lib/jailbash/sandbox...
[jail-bash] [INFO] Extrayendo dependencias para /bin/bash...
             -> Copiando /lib/x86_64-linux-gnu/libc.so.6 a la jaula.
             -> Copiando /lib64/ld-linux-x86-64.so.2 a la jaula.
[jail-bash] [INFO] Extrayendo dependencias para /bin/ls...
             -> Copiando /lib/x86_64-linux-gnu/libselinux.so.1 a la jaula.
[jail-bash] [INFO] Montando sistema de archivos virtual procfs de forma aislada...
[jail-bash] [SUCCESS] Jaula de seguridad construida con éxito.

```

**2. Entrar al Entorno Aislado (SandBox)**

Para cancelar un proceso de forma interactiva y verificar la restricción total:

```sudo jail-bash --enter```

Prueba de concepto de aislamiento dentro de la jaula:

```
# Intentar listar la raíz real del sistema host
bash-5.2# cd /
bash-5.2# ls -la
total 16
drwxr-xr-x  5 root root 4096 Jun 25 01:20 .
drwxr-xr-x  5 root root 4096 Jun 25 01:20 ..
drwxr-xr-x  2 root root 4096 Jun 25 01:20 bin
drwxr-xr-x  3 root root 4096 Jun 25 01:20 lib
drwxr-xr-x  2 root root 4096 Jun 25 01:20 lib64
drwxr-xr-x  2 root root 4096 Jun 25 01:20 proc

# Intentar ejecutar un comando no autorizado (No está en la lista blanca)
bash-5.2# python3
bash: python3: command not found

```

## 🗑️ Limpieza y Desinstalación

Para desmontar de forma segura los sistemas de archivos virtuales y purgar los binarios del sistema anfitrión:

``` sudo make uninstall ```

## 📄 Licencia

Este proyecto está distribuido bajo los términos de la Licencia MIT. Para mayor información, revisar el archivo LICENSE.

Desarrollado con enfoque en seguridad por kdefsys

