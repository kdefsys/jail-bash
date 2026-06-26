#!/bin/bash
# ======================================================================================
# Proyecto: jail-bash
# Componente: core/main.sh
# Descripción: Orquestador principal, manejo de argumentos y control de privilegios
# Autor: kdefsys
# ======================================================================================

# 1. Aseguramos que el script se ejecute estrictamente con privilegios de root (sudo)
if [[ "$EUID" -ne 0 ]]; then
	echo "[-] Error de seguridad: Este script requiere privilegios de superusuario (sudo)"
	exit 1
fi

# 2. Obtenemos la ruta absoluta del directorio donde reside este script
BASE_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
PROJECT_ROOT="$(dirname "$BASE_DIR")"

# 3. Cargamos el archivo de configuración global de forma segura
# Busca primero en la ruta de instalación global (/etc) y si no, recurre al entorno local
if [ -f "/etc/jail-bash/jail.conf" ]; then
	CONFIG_PATH="/etc/jail-bash/jail.conf"
else
	CONFIG_PATH="${PROJECT_ROOT}/config/jail.conf"
fi

if [ -f "$CONFIG_PATH" ]; then
	source "$CONFIG_PATH"
else
	echo "[-] Error crítico: No se encontró el archivo de configuración en $CONFIG_PATH"
	exit 1
fi

# 4. Importamos la lógica de construcción y ejecución de la jaula
JAILER_PATH_SCRIPT="${BASE_DIR}/jailer.sh"
if [ -f "$JAILER_PATH_SCRIPT" ]; then
	source "$JAILER_PATH_SCRIPT"
else
	echo "[-] Error crítico: No se encontró el componente modular $JAILER_PATH_SCRIPT"
	exit 1
fi

##
# Función: show_usage
# Descripción: Mustra la interfaz de ayuda en la terminal
##

show_usage() {
	echo "Uso: sudo jail-bash [OPCIÓN]"
	echo ""
	echo "Opciones válidas:"
	echo "  --build    Inicializa el mini-FHS, copia binarios y resuelve dependencias dinámicas."
	echo "  --enter    Monta los sistemas virtuales e ingresa al entorno aislado (chroot)."
	echo "  --help     Muestra esta interfaz de ayuda."
	echo ""
	echo "Desarrollado por kdefsys | Enfoque en Seguridad & Aislamiento POSIX"
}

# ======================================================================================
# EVALUACION DE ARGUMENTOS DE LINEA DE COMANDOS
# ======================================================================================

if [ $# -eq 0 ]; then
	show_usage
	exit 0
fi

case "$1" in
	--build)
		build_jail
		;;
	--enter)
		enter_jail
		;;
	--help)
		show_usage
		;;
	*)
		echo "[-] Opción inválida: $1" >&2
		echo "Use 'sudo jail-bash --help' para ver las opciones disponibles."
		exit 1
		;;
esac
