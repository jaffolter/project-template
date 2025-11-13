.PHONY: usage build run run-bash stop logs uv check clean

# ----------------
# Variables
# ----------------

DOCKER_IMAGE_NAME := project-template
DOCKER_CONTAINER_NAME := project-template
CODE_DIRECTORY := src
GPU_DEVICE := 2
DATA_DIRECTORY := /data/nfs/analysis/interns/jaffolter

# GPU (comment if gpu not needed)
DOCKER_GPU_PARAMS := --gpus '"device=$(GPU_DEVICE)"' --shm-size=8g

# Mounts
DOCKER_MOUNTS := -v $(DATA_DIRECTORY):/workspace/data -v $(PWD):/workspace

# Base docker run
DOCKER_RUN := docker run $(DOCKER_GPU_PARAMS) $(DOCKER_MOUNTS)

# ----------------
# Usage
# ----------------

usage:
	@echo "Available commands:"
	@echo "  build       Build the Docker image"
	@echo "  run         Run the Docker image in a named background container"
	@echo "  run-bash    Start an interactive bash session in a fresh container"
	@echo "  stop        Stop and remove the named container"
	@echo "  logs        Follow logs of the named container"
	@echo "  uv          Run 'uv' inside Docker (e.g. 'make uv add requests')"
	@echo "  check       Run type-checking and linting with uv"
	@echo "  clean       Auto-fix linting/formatting issues with uv + ruff"

# ----------------
# Docker commands
# ----------------

build:
	docker build --no-cache --progress=plain -t $(DOCKER_IMAGE_NAME) .

# Launch the container in detached mode with the specified name
run: 
	$(DOCKER_RUN) --name $(DOCKER_CONTAINER_NAME) -dit --env-file .env $(DOCKER_IMAGE_NAME)

# Launch the container in detached mode with the specified name and start a bash session
run-bash: 
	$(DOCKER_RUN) --rm -it --env-file .env $(DOCKER_IMAGE_NAME) /bin/bash
stop:
	docker stop $(DOCKER_CONTAINER_NAME) || true
	docker rm $(DOCKER_CONTAINER_NAME) || true

logs:
	docker logs -f $(DOCKER_CONTAINER_NAME)

# ----------------
# uv passthrough
# ----------------

# Example : `make uv add requests`
uv:
	$(DOCKER_RUN_UV) uv $(filter-out $@,$(MAKECMDGOALS))
%:
	@:

# ----------------
# Code quality checks
# ----------------

check:
	$(DOCKER_RUN_UV) uv run mypy --show-error-codes $(CODE_DIRECTORY)
	$(DOCKER_RUN_UV) uv run ruff check --no-fix $(CODE_DIRECTORY)
	$(DOCKER_RUN_UV) uv run ruff format --check $(CODE_DIRECTORY)
	@echo
	@echo "All is good!"
	@echo

clean:
	$(DOCKER_RUN_UV) uv run ruff check --fix $(CODE_DIRECTORY)
	$(DOCKER_RUN_UV) uv run ruff format $(CODE_DIRECTORY)