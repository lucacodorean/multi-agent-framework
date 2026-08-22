# Self-contained document-engine image for external deploy (preview Compose).
#
# Differs from infra/shared/engine/Dockerfile only in baking application source:
# DDEV bind-mounts engine/ read-only; this image COPY's it so the container
# runs with no bind-mount. Apt set, base pin, lockfile, and CMD match DDEV.
#
# Build from repository root:
#   docker build -f infra/deploy/engine/Dockerfile -t oir-flow-preview-engine:t2 .

FROM python:3.12.13-slim-bookworm

# Same LibreOffice + fonts set as infra/shared/engine/Dockerfile.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libreoffice-writer \
      fonts-dejavu-core \
      fonts-liberation2 \
 && rm -rf /var/lib/apt/lists/*

# Runtime-agnostic dependency lock, read from the root context and never forked into a
# runtime directory: docs/architecture.md § Runtimes, docs/topology/preview.md § Rules.
COPY infra/shared/engine/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt && rm /tmp/requirements.txt

RUN useradd --create-home --shell /usr/sbin/nologin --uid 1000 engine
ENV HOME=/home/engine \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# WORKDIR contains engine/ so `engine.app.main` imports (cwd on sys.path).
WORKDIR /app
COPY engine/ /app/engine/

USER engine

EXPOSE 8000
CMD ["uvicorn", "engine.app.main:app", "--host", "0.0.0.0", "--port", "8000"]
