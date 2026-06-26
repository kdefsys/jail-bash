#!/bin/bash
# ====================================================================================
# Proyecto: jail-bash
# Componente: core/jailer.sh
# Descripción: Inicialización del mini-FHS, montajes de kernel y ejecución chroot
# Autor: kdefsys
# ====================================================================================

# Evitar la ejecución directa. Requiere variables globales de main.sh

if [[ -z "${JAIL_PATH}" ]]; then
	echo "[-] Error: Este script requiere variables de entorno globales." >&2
	exit 1
fi

# Importar el motor de clonación de librerías usando la ruta del script actual
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/deps_copier.sh"

##
# Función: build_jail
# Descripción: Crea la estructura FHS, copia binarios y resuelve dependencias
##
build_jail() {
	echo "[jail-bash] [INFO] Inicializando entornos estructural en: ${JAIL_PATH}"

	# 1. Creamos directorios esenciales basados en el estándar FHS de Linux
	mkdir -p "${JAIL_PATH}"/{bin,lib,lib64,proc,usr/bin,dev}

	# 2. Creamos nodos de dispositivos mínimos escenciales en /dev
	# Esto evita que comandos como 'ls' o 'bash' fallen por falta de terminales estándar
	[ ! -c "${JAIL_PATH}/dev/null" ] && mknod -m 666 "${JAIL_PATH}/dev/null" c 1 3
	[ ! -c "${JAIL_PATH}/dev/zero" ] && mknod -m 666 "${JAIL_PATH}/dev/zero" c 1 5

	# 3. Iteramos sobre la lista blanca de comandos para copiarlos y resolver sus .so
	for binary in "${COMMANDS_WHITELIST[@]}"; do
		if [[ -f "$binary" ]]; then
			# Copiar el binario base manteniendo su estructura de directorios exacta
			local dest_binary="${JAIL_PATH}${binary}"
			mkdir -p "$(dirname "$dest_binary")"
			cp "$binary" "$dest_binary"

			# Inovcar a la función de deps_copier.sh para resolver sus librerías
			copy_dependencies "$binary"
		else
			echo "[jail-bash] [WARN] Comando omitido (no encontrado en host): $binary"

		fi
	done
	echo "[jail-bash] [SUCESS] Estructura y dependencias clonadas correctamente."

}

##
# Función: enter_jail
# Descripción: Realiza montajes del kernel en caliente e ingresa al aislamiento
##
enter_jail() {
	# Validar que la jaula ya haya sido construida previamente
	if [[ ! -d "${JAIL_PATH}/bin" ]]; then
		echo "[jail-bash] [ERROR]: La jaula no existe. Ejecuta primero con --build" >&2
		return 1
	fi

	# 1. Montar el sistema de archivos procfs de forma aislada si no está montado ya
	if ! mountpoint -q "${JAIL_PATH}/proc"; then
		echo "[jail-bash] [INFO] Montando sistemas de archivos virtual procfs..."
		mount -t proc proc "${JAIL_PATH}/proc"
	fi

	echo "[jail-bash] [INFO] Iniciando entorno seguro restringido..."
	echo "================================================================"

	# 2. Ejecutar la mutación de raíz POSIX invocando chroot hacia la jaula
	# Forzamos la ejecución de una sesión de Bash limpia y aislada de variables del host
	chroot "${JAIL_PATH}" /bin/bash --login +h

	echo "================================================================"
	echo "[jail-bash] [INFO] Sesión finalizada. Saliendo del entorno aislado."

	# 3. Limpieza: Desmontar procfs al salir para evitar fugas de recursos en el host
	if mountpoint -q "${JAIL_PATH}/proc"; then
		echo "[jail-bash] [INFO] Desmontando procfs de forma segura..."
		umount "${JAIL_PATH}/proc"
	fi
}
