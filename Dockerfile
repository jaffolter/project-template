FROM registry.deez.re/research/python-gpu-12-0:latest

# Système
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    python3 python3-venv python3-pip curl ca-certificates wget \
    ffmpeg libsndfile-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV PYTHONUNBUFFERED=1

# Installer uv (binaire) — simple et rapide
COPY --from=ghcr.io/astral-sh/uv:0.9.8 /uv /uvx /bin/

WORKDIR /workspace

# Étape deps: ne copie que les fichiers de résolution pour maximiser le cache
COPY pyproject.toml uv.lock ./

# Crée la venv .venv et installe selon le lockfile
RUN uv sync --frozen

# Ajouter le code applicatif après (garde le cache deps)
COPY src/ src/
ENV PYTHONPATH=/workspace/src

# uv place la venv dans .venv : l’ajouter au PATH pour exécuter directement
ENV PATH="/workspace/.venv/bin:${PATH}"

# Lancer l'app avec uv (pas Poetry)
CMD ["uv", "run", "-m", "livi.main"]