# ==============================================================================
# Proyecto: jail-bash
# Componente: Makefile
# Descripción: Automatización de instalación y desinstalación global en Linux
# Autor: kdefsys
# ==============================================================================

PREFIX = /usr/local
CONF_DIR = /etc/jail-bash
PROJECT_DIR = /opt/jail-bash

.PHONY: install uninstall

install:
	@echo "[jail-bash] [INSTALL] Instalando componentes en el sistema..."
	# 1. Crear el directorio del proyecto en /opt para mantener el código base seguro
	mkdir -p $(PROJECT_DIR)/core
	mkdir -p $(CONF_DIR)
	
	# 2. Copiar scripts y darles permisos de ejecución estrictos
	cp core/main.sh core/jailer.sh core/deps_copier.sh $(PROJECT_DIR)/core/
	chmod 700 $(PROJECT_DIR)/core/*.sh
	
	# 3. Copiar configuración global (Solo si no existe ya, para no pisar tus cambios)
	if [ ! -f $(CONF_DIR)/jail.conf ]; then \
		cp config/jail.conf $(CONF_DIR)/; \
		chmod 600 $(CONF_DIR)/jail.conf; \
	fi

	# 4. Crear enlace simbólico global en /usr/local/bin
	ln -sf $(PROJECT_DIR)/core/main.sh $(PREFIX)/bin/jail-bash
	@echo "[jail-bash] [INSTALL] Instalación completada con éxito."
	@echo "Modifica tu configuración en: $(CONF_DIR)/jail.conf"
	@echo "Ejecuta la herramienta con: sudo jail-bash --help"

uninstall:
	@echo "[jail-bash] [UNINSTALL] Removiendo componentes globales..."
	
	# 1. Cargar configuración para saber dónde está la jaula y desmontar procfs si sigue vivo
	@if [ -f $(CONF_DIR)/jail.conf ]; then \
		. $(CONF_DIR)/jail.conf; \
		if mountpoint -q $$JAIL_PATH/proc; then \
			echo "[jail-bash] [UNINSTALL] Limpiando montajes activos..."; \
			umount $$JAIL_PATH/proc; \
		fi; \
		echo "[jail-bash] [UNINSTALL] Removiendo directorio de la jaula: $$JAIL_PATH"; \
		rm -rf $$JAIL_PATH; \
	fi

	# 2. Purgar archivos binarios e infraestructura del host
	rm -f $(PREFIX)/bin/jail-bash
	rm -rf $(PROJECT_DIR)
	rm -rf $(CONF_DIR)
	@echo "[jail-bash] [UNINSTALL] Desinstalación completada de forma limpia."
