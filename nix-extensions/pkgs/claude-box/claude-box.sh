#!/usr/bin/env bash
# claude-box runs Claude Code in a Docker container.
# The container mounts the current directory at the same path.
# The agent sees nothing outside that directory.
#
#   claude-box                 start an interactive session in $PWD
#   claude-box --safe          keep the normal permission prompts
#   claude-box --build         rebuild the image first
#   claude-box --shell         start bash in the container
#   claude-box --reset-config  delete the persistent home volume
#   claude-box -p "..."        pass any other argument to claude
#
# Environment:
#   CLAUDE_BOX_CONTEXT=<dir>    directory that holds the Dockerfile
#                               (default: the copy in this package)
#   CLAUDE_BOX_VERSION=latest   npm version of @anthropic-ai/claude-code
#   CLAUDE_BOX_MOUNTS="a:b ..." extra docker -v specs, space separated
#   CLAUDE_BOX_NETWORK=none     docker network mode, none blocks the API
set -euo pipefail

CTX="${CLAUDE_BOX_CONTEXT:-@context@}"
UID_="$(id -u)"; GID_="$(id -g)"
VERSION="${CLAUDE_BOX_VERSION:-latest}"
IMAGE="claude-box:${UID_}-${GID_}"
# The volume holds the whole home, not only ~/.claude.
# Claude Code keeps onboarding state, the account and per-project trust in
# ~/.claude.json. That file sits beside ~/.claude, not inside it.
VOLUME="claude-box-home-${UID_}"

die() { echo "claude-box: $*" >&2; exit 1; }

safe=0 build=0 shell=0
args=()
for a in "$@"; do
  case "$a" in
    --safe)         safe=1 ;;
    --build)        build=1 ;;
    --shell)        shell=1 ;;
    --reset-config) docker volume rm -f "$VOLUME" >/dev/null && echo "removed volume $VOLUME"; exit 0 ;;
    *)              args+=("$a") ;;
  esac
done

PROJECT="$(pwd -P)"
[[ "$PROJECT" == "$HOME" ]] && die "refusing to mount your home directory; cd into a project first"
[[ "$PROJECT" == "/" ]]     && die "refusing to mount /"

command -v docker >/dev/null || die "docker not found on PATH"
docker info >/dev/null 2>&1 || die "cannot talk to the docker daemon"
[[ -f "$CTX/Dockerfile" ]]  || die "no Dockerfile in $CTX (set CLAUDE_BOX_CONTEXT)"

# --- image ---------------------------------------------------------------
if [[ $build -eq 1 ]] || ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "claude-box: building $IMAGE ..." >&2
  docker build \
    --build-arg "HOST_UID=$UID_" \
    --build-arg "HOST_GID=$GID_" \
    --build-arg "CLAUDE_VERSION=$VERSION" \
    -t "$IMAGE" "$CTX"
fi

# Runs one command in a throw-away container as the host user.
# The home volume is attached, so the command can write into it.
in_volume() {
  docker run --rm -i --user "$UID_:$GID_" -v "$VOLUME:/home/dev" \
    --entrypoint sh "$IMAGE" -c "$1"
}

# Check if the volume exists yet. Seed ~/.claude.json only if it does not.
fresh=0
docker volume inspect "$VOLUME" >/dev/null 2>&1 || fresh=1

# Copy the host config in on every start, so host edits reach the next run.
# The list leaves out transcripts, sessions, caches and credentials.
# tar -h copies what a symlink points at. These paths often point into a
# config repo that the container cannot see.
sync=()
for item in settings.json settings.local.json CLAUDE.md \
            agents commands skills hooks plugins output-styles; do
  [[ -e "$HOME/.claude/$item" ]] && sync+=("./$item")
done
if (( ${#sync[@]} )); then
  (( fresh )) && echo "claude-box: seeding $VOLUME from ~/.claude (${sync[*]#./}) ..." >&2
  tar -C "$HOME/.claude" -hcf - "${sync[@]}" \
    | in_volume "mkdir -p /home/dev/.claude && cd /home/dev/.claude \
                 && rm -rf ${sync[*]} && tar -xf -"
fi

# Onboarding flags, account record and project trust.
# Seed this file once only. The container then keeps its own project history
# in it.
if (( fresh )) && [[ -f "$HOME/.claude.json" ]]; then
  in_volume 'umask 077; cat > /home/dev/.claude.json' < "$HOME/.claude.json"
fi

# Merge claude-box defaults into ~/.claude/CLAUDE.md on every run.
# Keep host-provided content, but enforce one managed defaults block.
if [[ -f "$CTX/CLAUDE.md" ]]; then
  in_volume 'umask 077; mkdir -p /home/dev/.claude; touch /home/dev/.claude/CLAUDE.md'

  {
    printf '\n### BEGIN CLAUDE-BOX DEFAULTS ###\n'
    cat "$CTX/CLAUDE.md"
    printf '### END CLAUDE-BOX DEFAULTS ###\n'
  } | in_volume '
    set -e
    file=/home/dev/.claude/CLAUDE.md
    tmp="$(mktemp)"
    sed "/^### BEGIN CLAUDE-BOX DEFAULTS ###$/,/^### END CLAUDE-BOX DEFAULTS ###$/d" "$file" > "$tmp"
    cat "$tmp" - > "$file"
    rm -f "$tmp"
  '
fi

# --- per-run home prep ---------------------------------------------------
# Create the bind-mount targets first.
# Docker creates a missing target as a root-owned directory in the volume.
prep='umask 077; mkdir -p /home/dev/.claude /home/dev/.config/git'
# Copy the credentials in on every start. Do not bind-mount them.
# Claude Code writes a new token file, then renames it over the old one.
# The kernel will not allow that rename on a bind-mounted file ("Device or
# resource busy"). The container updates its own copy while it runs.
# Log in again on the host and the next start picks it up.
if [[ -f "$HOME/.claude/.credentials.json" ]]; then
  in_volume "$prep; cat > /home/dev/.claude/.credentials.json" \
    < "$HOME/.claude/.credentials.json"
else
  in_volume "$prep"
  [[ -z "${ANTHROPIC_API_KEY:-}" ]] && \
    echo "claude-box: no host credentials and no ANTHROPIC_API_KEY — you'll be asked to log in." >&2
fi

# --- mounts --------------------------------------------------------------
mounts=(-v "$PROJECT:$PROJECT" -v "$VOLUME:/home/dev")
# Git identity, mounted read-only. -f follows a symlink, so a home-manager
# link into the store works. home-manager puts the config at the XDG path,
# not at ~/.gitconfig.
if [[ -f "$HOME/.gitconfig" ]]; then
  mounts+=(-v "$HOME/.gitconfig:/home/dev/.gitconfig:ro")
elif [[ -f "$HOME/.config/git/config" ]]; then
  mounts+=(-v "$HOME/.config/git/config:/home/dev/.config/git/config:ro")
fi
for m in ${CLAUDE_BOX_MOUNTS:-}; do mounts+=(-v "$m"); done

envs=()
for v in ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_BASE_URL ANTHROPIC_MODEL \
         CLAUDE_CODE_USE_BEDROCK CLAUDE_CODE_USE_VERTEX GH_TOKEN GITHUB_TOKEN; do
  [[ -n "${!v:-}" ]] && envs+=(-e "$v=${!v}")
done

run=(docker run --rm -it --init
     --hostname claude-box
  --user "$UID_:$GID_"
     --workdir "$PROJECT"
     "${mounts[@]}" "${envs[@]}")
[[ -n "${CLAUDE_BOX_NETWORK:-}" ]] && run+=(--network "$CLAUDE_BOX_NETWORK")

if [[ $shell -eq 1 ]]; then
  exec "${run[@]}" --entrypoint bash "$IMAGE"
fi

claude_args=("${args[@]}")
# The container only shows $PROJECT. A skipped prompt cannot touch the rest.
[[ $safe -eq 0 ]] && claude_args=(--dangerously-skip-permissions "${claude_args[@]}")
exec "${run[@]}" "$IMAGE" "${claude_args[@]}"
