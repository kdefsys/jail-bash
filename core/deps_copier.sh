#!/bin/bash
# ===================================================================================
# Proyecto: jail-bash
# Componente: core/deps_copier.sh
# Descripción: Motor de resolución y clonación de dependencias dinámicas (.so)
# Autor: kdefsys
# ===================================================================================

# Evitamos la ejecución directa. Este script debe ser invocado por main.sh

if [[ -z "${JAIL_PATH}" ]]; then
	echo "[-] Error: Este script requiere variables de entorno globales." >&2
	exit 1
fi

##
# Función: copy_dependencias
# Argumento 1: Ruta abosluta del binario origen (Ej: /bin/bash)
##
copy_dependencies() {
	local target_binary="$1"

	# Validamos que el binario realmente exista en el host
	if [[ ! -f "$target_binary" ]]; then
		echo "[jail-bash] [WARN] El binario $target_binary no existe en el sistema host."
		return 1
	fi

	echo "[jail-bash] [INFO] Analizando dependencias para: $target_binary"

	# Usamos ldd para listar dependencias y gawk para filtrar solo las rutas absolutas.
	# Explicación del filtro gawl:
	# - Busca cualquier palabra que empieze con '/' (rutas de archivos .so)
	# - Imprime esa ruta limpia, eliminando paréntesis de direcciones de memoria.
	ldd "$target_binary" | gawk 'match($0, /\/[^ ]+/, m) {print m[0]}' | while read -r lib_path; do

		# Omitimos si por alguna razón la línea está vacía
		[ -z "$lib_path" ] && continue

		# Determinamos la ruta de destino dentro de nuestra jaula
		local dest_path="${JAIL_PATH}${lib_path}"
		local dest_dir=$(dirname "$dest_path")

		# Si el directorio destino no existe en la jaula, lo creamos
		if [ ! -d "$dest_dir" ]; then
			mkdir -p "$dest_dir"
		fi

		# Si la librería no ha sido copiada previamente, la clonamos
		if [ ! -f "$dest_path" ]; then
			cp "$lib_path" "$dest_path"
			echo "		-> Copiada: $lib_path"
		fi
	done
}
