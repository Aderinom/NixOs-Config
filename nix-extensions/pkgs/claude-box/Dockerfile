# Sandbox image for Claude Code. Docker mounts the project directory into it.
FROM node:22-bookworm-slim

ARG HOST_UID=1000
ARG HOST_GID=1000
ARG CLAUDE_VERSION=latest

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git gnupg jq less ripgrep fd-find \
      python3 python3-venv unzip nano procps \
 && ln -s /usr/bin/fdfind /usr/local/bin/fd \
 && rm -rf /var/lib/apt/lists/*

# Match the host user. Files in the bind mount then keep host ownership.
RUN set -eux; \
    if ! getent group "$HOST_GID" >/dev/null; then groupadd -g "$HOST_GID" devgrp; fi; \
    existing_user="$(getent passwd "$HOST_UID" | cut -d: -f1 || true)"; \
    if [ -n "$existing_user" ]; then userdel -r "$existing_user"; fi; \
    useradd -m -u "$HOST_UID" -g "$HOST_GID" -s /bin/bash dev

RUN npm install -g "@anthropic-ai/claude-code@${CLAUDE_VERSION}" \
 && npm cache clean --force

USER dev
ENV HOME=/home/dev \
    SHELL=/bin/bash \
    IS_SANDBOX=1 \
    NODE_OPTIONS=--max-old-space-size=4096
RUN mkdir -p /home/dev/.claude /home/dev/.config/git
ENTRYPOINT ["claude"]
