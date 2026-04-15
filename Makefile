.DEFAULT_GOAL := help

# =============================================================================
# CFL — Makefile operativo para entorno Linux/Ubuntu
# Soporta multiples ambientes (prd/dev) en el mismo servidor.
# Soporte oficial del Makefile: Linux Bash / Windows Git Bash.
# Repos esperados (relativos a este Makefile):
#   ../cfl-front-ng
#   ../cfl-back
# =============================================================================

# --- Rutas base ---------------------------------------------------------------
ROOT_DIR       := $(abspath $(CURDIR))
INFRA_DIR      := $(ROOT_DIR)
CFL_FRONT_DIR  := $(abspath $(INFRA_DIR)/../cfl-front-ng)
CFL_BACK_DIR   := $(abspath $(INFRA_DIR)/../cfl-back)

# --- Shell -------------------------------------------------------------------
# Soporte oficial:
#   - Linux con bash en PATH
#   - Windows con Git Bash / bash.exe en PATH
BASH           ?=
ifeq ($(strip $(BASH)),)
  ifeq ($(OS),Windows_NT)
    BASH := $(strip $(shell command -v bash 2>/dev/null))
    ifeq ($(strip $(BASH)),)
      ifneq ($(wildcard C:/Progra~1/Git/bin/bash.exe),)
        BASH := C:/Progra~1/Git/bin/bash.exe
      else ifneq ($(wildcard C:/Progra~1/Git/usr/bin/bash.exe),)
        BASH := C:/Progra~1/Git/usr/bin/bash.exe
      else ifneq ($(wildcard C:/Progra~1/Git/usr/bin/sh.exe),)
        BASH := C:/Progra~1/Git/usr/bin/sh.exe
      else ifneq ($(wildcard C:/Progra~2/Git/bin/bash.exe),)
        BASH := C:/Progra~2/Git/bin/bash.exe
      else ifneq ($(wildcard C:/Progra~2/Git/usr/bin/bash.exe),)
        BASH := C:/Progra~2/Git/usr/bin/bash.exe
      else ifneq ($(wildcard C:/Progra~2/Git/usr/bin/sh.exe),)
        BASH := C:/Progra~2/Git/usr/bin/sh.exe
      else
        BASH := $(firstword $(subst \,/,$(shell where.exe bash 2>NUL)))
        ifeq ($(strip $(BASH)),)
          BASH := $(firstword $(subst \,/,$(shell where.exe sh 2>NUL)))
        endif
      endif
    endif
  else
    BASH := $(strip $(shell command -v bash 2>/dev/null))
  endif
endif
ifeq ($(strip $(BASH)),)
  $(error Bash no encontrado. Soporte oficial: Linux con Bash y Windows con Git Bash/bash.exe en PATH)
endif

SHELL          := $(BASH)
.SHELLFLAGS    := -o pipefail -c

# --- Compose / env ------------------------------------------------------------
COMPOSE_FILE   := $(INFRA_DIR)/docker-compose.yml
ENV_FILE       := $(INFRA_DIR)/.env
ENV_EXAMPLE    := $(INFRA_DIR)/.env.example

COMPOSE        := docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE)
COMPOSE_NODE   := $(COMPOSE) --profile node

# --- Ambiente (leido del .env) ------------------------------------------------
CFL_ENV_RAW    := $(strip $(shell "$(BASH)" -lc 'if [ -f "$$1" ]; then grep -m1 "^CFL_ENV=" "$$1" | cut -d= -f2 | tr -d " \r"; fi' _ "$(ENV_FILE)"))
CFL_ENV        := $(if $(CFL_ENV_RAW),$(CFL_ENV_RAW),prd)

CFL_NETWORK    := greenvic-cfl-$(CFL_ENV)_default
EXPECTED_BRANCH := $(if $(filter prd,$(CFL_ENV)),main,dev)

# --- Utilidades ---------------------------------------------------------------
TAIL           ?= 200

# --- Phony targets ------------------------------------------------------------
.PHONY: help
.PHONY: env-check repo-check net-check branch-check doctor env-info
.PHONY: setup-env
.PHONY: build-cfl-front build-cfl-back build-all rebuild
.PHONY: up up-build down down-v stop start restart restart-cfl-front restart-cfl-back
.PHONY: ps logs logs-cfl-front logs-cfl-back
.PHONY: config pull deploy redeploy
.PHONY: exec-cfl-front exec-cfl-back
.PHONY: images volumes networks
.PHONY: prune prune-soft
.PHONY: status

# =============================================================================
# Help
# =============================================================================
help:
	@echo "Shell soportado oficialmente: Linux Bash / Windows Git Bash"
	@echo "Greenvic Control Fletes — Makefile (ambiente: $(CFL_ENV))"
	@echo ""
	@echo "Setup:"
	@echo "  make setup-env ENV=prd  Copia .env.prd.example a .env (o ENV=dev)"
	@echo "  make env-check          Verifica .env"
	@echo "  make repo-check         Verifica que existan los repos esperados"
	@echo "  make branch-check       Verifica que las ramas coincidan con CFL_ENV"
	@echo "  make doctor             Verifica docker, compose, .env, repos y ambiente"
	@echo "  make env-info           Muestra ambiente, red y branches actuales"
	@echo ""
	@echo "Build:"
	@echo "  make build-cfl-front    Build de cfl-front-ng"
	@echo "  make build-cfl-back     Build de cfl-back"
	@echo "  make build-all          Build de todas las imagenes"
	@echo "  make rebuild            Rebuild completo sin cache"
	@echo ""
	@echo "Run:"
	@echo "  make up                 Levanta el stack"
	@echo "  make up-build           Levanta reconstruyendo"
	@echo "  make down               Baja el stack"
	@echo "  make down-v             Baja el stack y elimina volumenes"
	@echo "  make stop               Detiene servicios"
	@echo "  make start              Inicia servicios ya creados"
	@echo "  make restart            Reinicia todo el stack"
	@echo ""
	@echo "Ops:"
	@echo "  make ps                 Estado de contenedores"
	@echo "  make status             Estado + resumen"
	@echo "  make logs               Logs de todo el stack"
	@echo "  make logs-cfl-front     Logs de cfl-front-ng"
	@echo "  make logs-cfl-back      Logs de cfl-back"
	@echo "  make restart-cfl-front  Reinicia cfl-front-ng"
	@echo "  make restart-cfl-back   Reinicia cfl-back"
	@echo ""
	@echo "Debug:"
	@echo "  make config             Render de docker compose"
	@echo "  make exec-cfl-front     Shell en cfl-front-ng"
	@echo "  make exec-cfl-back      Shell en cfl-back"
	@echo ""
	@echo "Deploy:"
	@echo "  make pull               Git pull en front/back/infra"
	@echo "  make deploy             Pull + up -d --build"
	@echo "  make redeploy           Down + deploy"
	@echo ""
	@echo "Infra:"
	@echo "  make images             Lista imagenes"
	@echo "  make volumes            Lista volumenes"
	@echo "  make networks           Lista redes"
	@echo "  make prune-soft         Limpieza suave"
	@echo "  make prune              Limpieza agresiva"
	@echo ""
	@echo "Variables opcionales:"
	@echo "  TAIL=500 make logs"
	@echo ""
	@true

# =============================================================================
# Setup
# =============================================================================
setup-env:
	@if [ -z "$(ENV)" ]; then \
		echo "Uso: make setup-env ENV=prd   (o ENV=dev)"; \
		exit 1; \
	fi
	@if [ ! -f "$(INFRA_DIR)/.env.$(ENV).example" ]; then \
		echo "ERROR: No existe .env.$(ENV).example"; \
		exit 1; \
	fi
	@if [ -f "$(ENV_FILE)" ]; then \
		echo "WARN: Ya existe $(ENV_FILE). Se creara backup .env.bak"; \
		cp "$(ENV_FILE)" "$(ENV_FILE).bak"; \
	fi
	@cp "$(INFRA_DIR)/.env.$(ENV).example" "$(ENV_FILE)"
	@echo "Copiado .env.$(ENV).example -> .env"
	@echo "Edita $(ENV_FILE) para completar los valores sensibles (secretos, passwords)."

# =============================================================================
# Validaciones
# =============================================================================
env-check:
	$(if $(wildcard $(ENV_FILE)),,$(error ERROR: Falta $(ENV_FILE). Ejecuta: make setup-env ENV=prd  (o ENV=dev)))
	@echo ".env OK"

net-check:
	@docker network inspect $(CFL_NETWORK) > /dev/null 2>&1 || \
		(echo "ERROR: La red $(CFL_NETWORK) no existe. Levanta el stack platform primero." && exit 1)
	@docker network inspect platform_identity > /dev/null 2>&1 || \
		(echo "ERROR: La red platform_identity no existe. Levanta el stack platform primero." && exit 1)

repo-check:
	@if [ ! -d "$(CFL_FRONT_DIR)" ]; then \
		echo "ERROR: No existe repo front en $(CFL_FRONT_DIR)"; \
		exit 1; \
	fi
	@if [ ! -d "$(CFL_BACK_DIR)" ]; then \
		echo "ERROR: No existe repo back en $(CFL_BACK_DIR)"; \
		exit 1; \
	fi
	@if [ ! -f "$(COMPOSE_FILE)" ]; then \
		echo "ERROR: No existe $(COMPOSE_FILE)"; \
		exit 1; \
	fi

branch-check:
	@FAIL=0; \
	for repo in "$(CFL_FRONT_DIR)" "$(CFL_BACK_DIR)" "$(INFRA_DIR)"; do \
		if [ -d "$$repo/.git" ]; then \
			ACTUAL=$$(cd "$$repo" && git rev-parse --abbrev-ref HEAD 2>/dev/null); \
			if [ "$$ACTUAL" != "$(EXPECTED_BRANCH)" ]; then \
				echo "WARNING: $$repo esta en branch '$$ACTUAL' (esperado '$(EXPECTED_BRANCH)' para CFL_ENV=$(CFL_ENV))"; \
				FAIL=1; \
			fi; \
		fi; \
	done; \
	if [ "$$FAIL" = "1" ]; then \
		echo ""; \
		echo "Las ramas no coinciden con el ambiente $(CFL_ENV). Verifica antes de continuar."; \
	fi

env-info:
	@echo "== Informacion de ambiente =="
	@echo "CFL_ENV          = $(CFL_ENV)"
	@echo "CFL_NETWORK      = $(CFL_NETWORK)"
	@echo "EXPECTED_BRANCH  = $(EXPECTED_BRANCH)"
	@echo "ENV_FILE         = $(ENV_FILE)"
	@echo "COMPOSE_FILE     = $(COMPOSE_FILE)"
	@echo ""
	@echo "== Branches actuales =="
	@for repo in "$(INFRA_DIR)" "$(CFL_FRONT_DIR)" "$(CFL_BACK_DIR)"; do \
		if [ -d "$$repo/.git" ]; then \
			BRANCH=$$(cd "$$repo" && git rev-parse --abbrev-ref HEAD 2>/dev/null); \
			echo "  $$repo -> $$BRANCH"; \
		else \
			echo "  $$repo -> (no es repo git)"; \
		fi; \
	done

doctor: env-check repo-check
	@echo "== Doctor (CFL_ENV=$(CFL_ENV)) =="
	@echo ""
	@echo "[Docker]"
	@docker --version
	@echo ""
	@echo "[Docker Compose]"
	@docker compose version
	@echo ""
	@echo "[Ambiente]"
	@echo "CFL_ENV: $(CFL_ENV)"
	@echo "Red esperada: $(CFL_NETWORK)"
	@echo "Branch esperado: $(EXPECTED_BRANCH)"
	@echo ""
	@echo "[Repos]"
	@echo "INFRA: $(INFRA_DIR)"
	@echo "FRONT: $(CFL_FRONT_DIR)"
	@echo "BACK : $(CFL_BACK_DIR)"
	@echo ""
	@for repo in "$(INFRA_DIR)" "$(CFL_FRONT_DIR)" "$(CFL_BACK_DIR)"; do \
		if [ -d "$$repo/.git" ]; then \
			BRANCH=$$(cd "$$repo" && git rev-parse --abbrev-ref HEAD 2>/dev/null); \
			echo "  $$repo -> branch $$BRANCH"; \
		fi; \
	done
	@echo ""
	@echo "[Compose file]"
	@echo "$(COMPOSE_FILE)"
	@echo ""
	@echo "[Env file]"
	@echo "$(ENV_FILE)"
	@echo ""
	@echo "[Redes Docker]"
	@docker network inspect $(CFL_NETWORK) > /dev/null 2>&1 && echo "  $(CFL_NETWORK): OK" || echo "  $(CFL_NETWORK): NO EXISTE"
	@docker network inspect platform_identity > /dev/null 2>&1 && echo "  platform_identity: OK" || echo "  platform_identity: NO EXISTE"
	@echo ""
	@echo "OK"

# =============================================================================
# Build
# =============================================================================
build-cfl-front: env-check repo-check
	$(COMPOSE) build front-ng

build-cfl-back: env-check repo-check
	$(COMPOSE_NODE) build back

build-all: env-check repo-check
	$(COMPOSE_NODE) build

rebuild: env-check repo-check
	$(COMPOSE_NODE) build --no-cache

# =============================================================================
# Run
# =============================================================================
up: env-check repo-check net-check branch-check
	$(COMPOSE_NODE) up -d

up-build: env-check repo-check net-check branch-check
	$(COMPOSE_NODE) up -d --build

down: env-check repo-check
	$(COMPOSE_NODE) down --remove-orphans

down-v: env-check repo-check
	$(COMPOSE_NODE) down -v --remove-orphans

stop: env-check repo-check
	$(COMPOSE_NODE) stop

start: env-check repo-check
	$(COMPOSE_NODE) start

restart: env-check repo-check
	$(COMPOSE_NODE) restart

restart-cfl-front: env-check repo-check
	$(COMPOSE) restart front-ng

restart-cfl-back: env-check repo-check
	$(COMPOSE_NODE) restart back

# =============================================================================
# Ops
# =============================================================================
ps: env-check repo-check
	$(COMPOSE_NODE) ps

status: env-check repo-check
	@echo "== Estado de contenedores ($(CFL_ENV)) =="
	@$(COMPOSE_NODE) ps
	@echo ""
	@echo "== Imagenes CFL =="
	@docker images | grep -i cfl || true

logs: env-check repo-check
	$(COMPOSE_NODE) logs -f --tail=$(TAIL)

logs-cfl-front: env-check repo-check
	$(COMPOSE) logs -f --tail=$(TAIL) front-ng

logs-cfl-back: env-check repo-check
	$(COMPOSE_NODE) logs -f --tail=$(TAIL) back

# =============================================================================
# Debug / acceso a contenedores
# =============================================================================
config: env-check repo-check
	$(COMPOSE_NODE) config

exec-cfl-front: env-check repo-check
	$(COMPOSE) exec front-ng sh

exec-cfl-back: env-check repo-check
	$(COMPOSE_NODE) exec back sh

# =============================================================================
# Git / Deploy
# =============================================================================
pull: repo-check
	@echo "== Git pull cfl-front-ng =="
	@if [ -d "$(CFL_FRONT_DIR)/.git" ]; then \
		cd "$(CFL_FRONT_DIR)" && git pull; \
	else \
		echo "WARN: $(CFL_FRONT_DIR) no es repo git"; \
	fi
	@echo ""
	@echo "== Git pull cfl-back =="
	@if [ -d "$(CFL_BACK_DIR)/.git" ]; then \
		cd "$(CFL_BACK_DIR)" && git pull; \
	else \
		echo "WARN: $(CFL_BACK_DIR) no es repo git"; \
	fi
	@echo ""
	@echo "== Git pull infra =="
	@if [ -d "$(INFRA_DIR)/.git" ]; then \
		cd "$(INFRA_DIR)" && git pull; \
	else \
		echo "WARN: $(INFRA_DIR) no es repo git"; \
	fi

deploy: env-check repo-check branch-check pull
	$(COMPOSE_NODE) up -d --build --remove-orphans

redeploy: env-check repo-check branch-check
	$(COMPOSE_NODE) down --remove-orphans
	$(COMPOSE_NODE) up -d --build --remove-orphans

# =============================================================================
# Infra helpers
# =============================================================================
images:
	@docker images

volumes:
	@docker volume ls

networks:
	@docker network ls

prune-soft:
	@docker image prune -f
	@docker container prune -f
	@docker network prune -f

prune:
	@docker system prune -af --volumes
