# Cargar variables del archivo .env
ifneq (,$(wildcard .env))
    include .env
    export
endif

# Modelo por defecto si no está definido en el .env
OLLAMA_MODEL_TAG ?= qwen3.6:35b-a3b-q4_K_M

.PHONY: default run up down logs pull-model list-models clean restart

# Acción por defecto al ejecutar 'make'
default: run

# Levanta la infraestructura (si no está activa), verifica el modelo e inicia el CLI
run: up
	@echo "=========================================================="
	@echo " Esperando a que Ollama esté saludable..."
	@echo "=========================================================="
	@until [ "$$(docker inspect -f '{{.State.Health.Status}}' ollama 2>/dev/null)" = "healthy" ]; do \
		sleep 1; \
	done
	@echo "Ollama está listo."
	@echo "=========================================================="
	@echo " Verificando si el modelo '$(OLLAMA_MODEL_TAG)' está listo..."
	@echo "=========================================================="
	@if ! docker exec ollama ollama list | grep -q "$(OLLAMA_MODEL_TAG)"; then \
		echo "El modelo no se encuentra localmente. Iniciando descarga..."; \
		docker exec -it ollama ollama pull $(OLLAMA_MODEL_TAG); \
	else \
		echo "El modelo '$(OLLAMA_MODEL_TAG)' ya está listo."; \
	fi
	@echo "=========================================================="
	@echo " Iniciando interfaz interactiva (TUI) de OpenCode..."
	@echo "=========================================================="
	docker compose run --rm -it opencode-cli

# Levanta la infraestructura en segundo plano
up:
	@echo "Levantando contenedores..."
	docker compose up -d

# Apaga la infraestructura
down:
	@echo "Deteniendo contenedores..."
	docker compose down

# Reinicia la infraestructura
restart: down up

# Muestra los logs en tiempo real
logs:
	docker compose logs -f

# Muestra los modelos descargados en Ollama
list-models:
	docker exec -it ollama ollama list

# Fuerza la descarga manual del modelo actual
pull-model:
	docker exec -it ollama ollama pull $(OLLAMA_MODEL_TAG)

# Limpia los contenedores y borra los datos/historial
clean:
	@echo "ADVERTENCIA: Se borrarán los contenedores, volúmenes e historial de datos."
	docker compose down -v
	rm -rf ./data
