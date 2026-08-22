# Document-engine image — Python 3.12 + LibreOffice Writer (headless).
#
# SOURCE OF TRUTH: infra/shared/engine/Dockerfile — a runtime-agnostic shared input, owned
# by no runtime: docs/architecture.md § Runtimes. `.ddev/engine-build/Dockerfile` is a copy
# installed by infra/ddev/bootstrap.sh — edit HERE, then re-run bootstrap and rebuild.
# Build context, the local bind-mount vs the preview bake, and the CI consequence:
# infra/README.md § engine — the document-engine service.
#
# Base pinned to an exact patch tag, not the floating `3.12-slim`:
#   python:3.12.13-slim-bookworm
#   digest sha256:d50fb7611f86d04a3b0471b46d7557818d88983fc3136726336b2a4c657aa30b
#   (recorded 2026-07-28; `docker pull python:3.12.13-slim-bookworm` to re-verify)
# engine/pyproject.toml declares requires-python >=3.12.
FROM python:3.12.13-slim-bookworm

# LibreOffice Writer, NOT only libreoffice-core: with -core alone every conversion
# fails with "source file could not be loaded" (engine/vendor/modul_pdf/__init__.py).
# --no-install-recommends keeps Java and the l10n bundles out; the two font
# packages are the minimum a .docx render needs (DejaVu = LibreOffice's fallback,
# Liberation = metric-compatible with Arial/Times/Courier, which the NJ template uses).
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libreoffice-writer \
      fonts-dejavu-core \
      fonts-liberation2 \
 && rm -rf /var/lib/apt/lists/*

# Runtime dependencies, fully pinned (including transitives) so the image is
# reproducible. Floors live in engine/pyproject.toml (owned by the engine tier); this
# lock is the platform tier's resolution of them — see the file header for how to
# regenerate it after a floor change. Source of truth:
# infra/shared/engine/requirements.txt, resolved from the build context (see header).
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt && rm /tmp/requirements.txt

# Non-root. The bind-mounted source is read-only and world-readable; everything the
# engine writes at runtime goes to a tempfile.TemporaryDirectory under /tmp (removed in
# a finally block — the engine keeps nothing durable). HOME must exist and be writable
# because LibreOffice touches it even with an isolated -env:UserInstallation profile.
RUN useradd --create-home --shell /usr/sbin/nologin --uid 1000 engine
ENV HOME=/home/engine \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# WORKDIR is the directory that CONTAINS engine/, so that `engine.app.main` imports
# (uvicorn puts the cwd on sys.path). /app/engine is the bind mount.
WORKDIR /app
USER engine

EXPOSE 8000
CMD ["uvicorn", "engine.app.main:app", "--host", "0.0.0.0", "--port", "8000"]
