# Nix-based sandbox image for Claude Code. Docker mounts the project directory into it.
FROM nixos/nix:latest

ARG HOST_UID=1000
ARG HOST_GID=1000
ARG CLAUDE_VERSION=latest

ENV NIX_CONFIG="experimental-features = nix-command flakes"
ENV PATH=/nix/var/nix/profiles/default/bin:/root/.nix-profile/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# The container runs as dev and has no nix daemon. Nix then works in
# single-user mode and must own the store and its database.
# Build users only exist for a root-run nix, so turn them off.
# The chown runs in the same layer as the install. A separate layer copies
# the whole store again.
RUN nix profile install --profile /nix/var/nix/profiles/default \
    nixpkgs#bashInteractive \
    nixpkgs#coreutils-full \
    nixpkgs#curl \
    nixpkgs#fd \
    nixpkgs#findutils \
    nixpkgs#git \
    nixpkgs#gnupg \
    nixpkgs#gnused \
    nixpkgs#gnugrep \
    nixpkgs#gawk \
    nixpkgs#glibc^out \
    nixpkgs#jq \
    nixpkgs#less \
    nixpkgs#nano \
    nixpkgs#nodejs_22 \
    nixpkgs#procps \
    nixpkgs#python3 \
    nixpkgs#shadow \
    nixpkgs#ripgrep \
    nixpkgs#unzip \
    nixpkgs#which \
    nixpkgs#zip \
    --priority 6 \
 && chown -R "$HOST_UID:$HOST_GID" /nix \
 && echo "build-users-group =" >> /etc/nix/nix.conf

# Match the host user. Files in the bind mount then keep host ownership.
# The base image links /etc/passwd, group and shadow into the store and has
# no gshadow, so useradd fails. Copy the files and edit them directly.
# The base image also has no /bin/bash, and no /lib64 loader for prebuilt
# glibc binaries such as the claude binary from npm.
RUN set -eux; \
    for f in passwd group shadow; do \
      cp --remove-destination "$(readlink -f /etc/$f)" /etc/$f; chmod u+w /etc/$f; \
    done; \
    ln -sf "$(command -v bash)" /bin/bash; \
    mkdir -p /lib64; \
    ln -sf /nix/var/nix/profiles/default/lib/ld-linux-x86-64.so.2 /lib64/; \
    grep -q "^[^:]*:[^:]*:$HOST_GID:" /etc/group || echo "dev:x:$HOST_GID:" >> /etc/group; \
    sed -i "/^[^:]*:[^:]*:$HOST_UID:/d" /etc/passwd; \
    echo "dev:x:$HOST_UID:$HOST_GID::/home/dev:/bin/bash" >> /etc/passwd; \
    echo "dev:!:1::::::" >> /etc/shadow; \
    mkdir -p /home/dev; chown "$HOST_UID:$HOST_GID" /home/dev

# npm defaults to the nodejs store path as its global prefix. That bin
# directory is not on PATH.
ENV NPM_CONFIG_PREFIX=/usr/local
RUN npm install -g "@anthropic-ai/claude-code@${CLAUDE_VERSION}" \
 && npm cache clean --force

USER dev
ENV HOME=/home/dev \
    SHELL=/bin/bash \
    IS_SANDBOX=1 \
    NODE_OPTIONS=--max-old-space-size=4096
RUN mkdir -p /home/dev/.claude /home/dev/.config/git
ENTRYPOINT ["claude"]
