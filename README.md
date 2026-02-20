# OpenClaw Docker Setup (No Local Source Required)

This folder runs OpenClaw with Docker Compose.
The image builds OpenClaw from GitHub during `docker compose build`, so you do not need the OpenClaw source code checked out locally.

## TL;DR (copy/paste command list) (Windows PowerShell)

```powershell
# 0) one-time: create .env 
Copy-Item .env.example .env

# 1) edit .env and set these two paths (absolute paths):
# OPENCLAW_CONFIG_DIR=C:/Users/<you>/.openclaw
# OPENCLAW_WORKSPACE_DIR=C:/Users/<you>/.openclaw/workspace

# 2) build image
docker compose build

# 3) onboarding wizard (first run)
docker compose run --rm openclaw-cli onboard

# 4) start gateway
docker compose up -d openclaw-gateway

# 5) open dashboard link (copy URL)
docker compose run --rm openclaw-cli dashboard --no-open

# 6) approve device if needed
docker compose run --rm openclaw-cli devices list
docker compose run --rm openclaw-cli devices approve <requestId>

# 7) verify
docker compose run --rm openclaw-cli health
```

Daily use:

```powershell
docker compose up -d openclaw-gateway
docker compose run --rm openclaw-cli status
```

Stop everything:

```powershell
docker compose down
```

## Prerequisites

- Docker Desktop (or Docker Engine + Compose v2)
- Internet access (image build clones `openclaw/openclaw`)

## 1) Configure environment

Create your `.env` from the template:

```powershell
Copy-Item .env.example .env
```

Edit `.env` and set at least:

- `OPENCLAW_CONFIG_DIR`
- `OPENCLAW_WORKSPACE_DIR`

Example (Windows):

```env
OPENCLAW_CONFIG_DIR=C:/Users/Daniel/.openclaw
OPENCLAW_WORKSPACE_DIR=C:/Users/Daniel/.openclaw/workspace
```

Important:
- Use absolute paths.
- Do **not** use `%USERPROFILE%` or `$HOME` in `.env` values.

## 2) Build the image

```powershell
docker compose build
```

Optional build settings in `.env`:

- `OPENCLAW_REF=main` (or a tag/branch)
- `OPENCLAW_DOCKER_APT_PACKAGES=ffmpeg build-essential`

## 3) Run onboarding (first-time)

```powershell
docker compose run --rm openclaw-cli onboard
```

This creates initial config and helps you set up provider auth/token.

## 4) Start the gateway

```powershell
docker compose up -d openclaw-gateway
```

Open:
- http://127.0.0.1:18789/

## 5) Useful CLI commands

```powershell
# Dashboard link (no auto-open)
docker compose run --rm openclaw-cli dashboard --no-open

# Device pairing status
docker compose run --rm openclaw-cli devices list

# Approve pairing request
docker compose run --rm openclaw-cli devices approve <requestId>
```

## 6) Stop / restart

```powershell
# Stop services
docker compose down

# Restart gateway
docker compose restart openclaw-gateway
```

## Troubleshooting

### `service ... refers to undefined volume %USERPROFILE%/...`
Cause: `.env` used `%USERPROFILE%`.
Fix: replace with real absolute path like `C:/Users/<name>/.openclaw`.

### `failed to calculate checksum ... "/scripts": not found`
Cause: Dockerfile expected local source files.
Fix: this project Dockerfile now clones OpenClaw during build; run `docker compose build` again.

### `The "HOME" variable is not set`
Cause: old compose files using `${HOME}` on Windows.
Fix: use this repo’s current `.env` path variables (`OPENCLAW_CONFIG_DIR`, `OPENCLAW_WORKSPACE_DIR`).

### `gateway closed (1006 abnormal closure)` when running `openclaw-cli` commands
Cause: CLI container could not reach the gateway loopback target.
Fix: this repo now runs `openclaw-cli` with `network_mode: service:openclaw-gateway` so `ws://127.0.0.1:18789` resolves to the gateway container.

Also make sure the gateway is up first:

```powershell
docker compose up -d openclaw-gateway
```

### `unauthorized: gateway token missing` / `pairing required`
Cause: `OPENCLAW_GATEWAY_TOKEN` is empty or device pairing is pending.
Fix:

```powershell
# Get a fresh dashboard link + token flow
docker compose run --rm openclaw-cli dashboard --no-open

# Check pending device requests
docker compose run --rm openclaw-cli devices list

# Approve one request
docker compose run --rm openclaw-cli devices approve <requestId>
```

Then set `OPENCLAW_GATEWAY_TOKEN` in `.env` and restart the gateway:

```powershell
docker compose up -d --force-recreate openclaw-gateway
```
