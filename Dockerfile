FROM node:22-bookworm

# ── Optional: extra apt packages baked into the image ─────────────────────────
# Pass via: docker compose build --build-arg OPENCLAW_DOCKER_APT_PACKAGES="ffmpeg jq"
ARG OPENCLAW_DOCKER_APT_PACKAGES=""
RUN if [ -n "$OPENCLAW_DOCKER_APT_PACKAGES" ]; then \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $OPENCLAW_DOCKER_APT_PACKAGES && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; \
  fi

# ── Fetch OpenClaw source from GitHub ─────────────────────────────────────────
# No local source needed, the repo is cloned during the image build.
# Pin to a specific tag or commit via: --build-arg OPENCLAW_REF=v1.2.3
ARG OPENCLAW_REF=main
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates \
  && rm -rf /var/lib/apt/lists/* \
  && git clone --depth 1 --branch ${OPENCLAW_REF} https://github.com/openclaw/openclaw /app

# ── Build ──────────────────────────────────────────────────────────────────────
# Install Bun (required for build scripts)
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /app

# Dependency layer cached separately so pnpm install only reruns on lockfile change
RUN pnpm install --frozen-lockfile

RUN pnpm build

# Force pnpm for UI build (avoids Bun failures on ARM/Synology)
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:build

ENV NODE_ENV=production

# Allow non-root user to write temp files at runtime
RUN chown -R node:node /app

# Provide a global "openclaw" command inside the container.
# This helps scripts/tools that invoke: openclaw <subcommand>
RUN printf '#!/bin/sh\nexec node /app/dist/index.js "$@"\n' > /usr/local/bin/openclaw \
  && chmod +x /usr/local/bin/openclaw

# Run as non-root (node uid 1000) to reduce attack surface
USER node

# Bind to lan so the port is reachable from outside the container
CMD ["node", "dist/index.js", "gateway", "--allow-unconfigured", "--bind", "lan"]
