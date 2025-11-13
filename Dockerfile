# -------
# Base image using GPU-enabled Python 3.12
# -------
FROM registry.deez.re/research/python-gpu-12-0:latest


# -------
# Environment variables not persisted in the final image
# -------
# Set non-interactive mode for apt-get
ARG DEBIAN_FRONTEND=noninteractive \
    # Working directory inside the container (can be changed as needed)
    WORKDIR_FOLDER=/workspace 


# -------
# Environment variables persisted in the final image
# -------
# Ensure Python does not create .pyc bytecode files (cleaner, faster)
ENV PYTHONDONTWRITEBYTECODE=1 \
    # Ensure Python output is not buffered (real-time logging)
    PYTHONUNBUFFERED=1 \
    # Change PYTHONPATH so that ${WORKDIR_FOLDER}/src behaves as the root for imports
    PYTHONPATH=${WORKDIR_FOLDER}/src


# -------
# Set up workspace (where the app code lives)
# -------
WORKDIR $WORKDIR_FOLDER


# -------
# Install system dependencies
# -------
RUN <<EOF
apt-get update
apt-get install -y --no-install-recommends curl ca-certificates python3 python3-pip python3-venv
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF

# -------
# Install uv package manager
# -------
# 1. Download the latest installer of uv
ADD https://astral.sh/uv/install.sh /uv-installer.sh

# 2. Run the installer then remove it
RUN sh /uv-installer.sh && rm /uv-installer.sh

# 3. Ensure the installed binary is on the `PATH`
ENV PATH="/root/.local/bin/:$PATH"


# -------
# Copy necessary files for uv
# -------
COPY pyproject.toml uv.lock ./


# ------
# Install dependencies with uv
# ------
RUN uv sync --locked

# And activate the project virtual environment
ENV PATH="/${WORKDIR_FOLDER}/.venv/bin:$PATH"


# -------
# Define the default command to run the application
# -------
CMD ["uv", "run", "-m", "src.main"]