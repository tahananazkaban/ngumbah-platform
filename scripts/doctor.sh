#!/bin/sh
# Checks required and optional tools; reports, never installs.
set -u
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

case "$(uname -s)" in
  Darwin) PLATFORM=mac ;;
  *) PLATFORM=wsl ;;
esac

missing=0

# Extracts the first dotted version number from a string
first_version() {
  printf '%s' "$1" | grep -oE '[0-9]+(\.[0-9]+)+' | head -n 1
}

# check <name> <required|optional> <min> <version command> <mac hint> <wsl hint>
check() {
  name="$1"; kind="$2"; min="$3"; cmd="$4"
  if [ "$PLATFORM" = mac ]; then hint="$5"; else hint="$6"; fi

  raw="$(sh -c "$cmd" 2>&1)"
  status=$?
  ver="$(first_version "$raw")"

  if [ $status -ne 0 ] || [ -z "$ver" ]; then
    if [ "$kind" = optional ]; then
      warn "$name: not found (optional) -> $hint"
    else
      fail "$name: missing (need >= $min) -> $hint"
      missing=1
    fi
  elif [ -n "$min" ] && ! version_ge "$ver" "$min"; then
    if [ "$kind" = optional ]; then
      warn "$name $ver: older than $min (optional) -> $hint"
    else
      fail "$name $ver: too old (need >= $min) -> $hint"
      missing=1
    fi
  else
    ok "$name $ver"
  fi
}

info "platform: $PLATFORM"

check "docker engine" required 24.0 \
  "docker version --format '{{.Server.Version}}'" \
  "install Docker Desktop and start it: https://docs.docker.com/desktop/setup/install/mac-install/" \
  "install Docker Desktop for Windows with WSL integration: https://docs.docker.com/desktop/features/wsl/"
check "docker compose" required 2.20 \
  "docker compose version --short" \
  "update Docker Desktop" \
  "update Docker Desktop"
check "go" required 1.25 \
  "go env GOVERSION" \
  "brew install go" \
  "https://go.dev/doc/install"
# Accept Node 22+ installed through nvm even when the shell default is older
shell_node="$(first_version "$(node --version 2>/dev/null)")"
nvm_node=""
if [ -z "$shell_node" ] || ! version_ge "$shell_node" 22.0; then
  for d in "${NVM_DIR:-$HOME/.nvm}"/versions/node/v*; do
    [ -d "$d" ] || continue
    v="${d##*/v}"
    if version_ge "$v" 22.0 && { [ -z "$nvm_node" ] || version_ge "$v" "$nvm_node"; }; then
      nvm_node="$v"
    fi
  done
fi
if [ -n "$nvm_node" ]; then
  ok "node $nvm_node via nvm (shell default is ${shell_node:-none}; run 'nvm use 22' in Ngumbah repos)"
else
  check "node" required 22.0 \
    "node --version" \
    "nvm install 22 (https://github.com/nvm-sh/nvm)" \
    "nvm install 22 (https://github.com/nvm-sh/nvm)"
fi
check "rustup" required 1.27 \
  "rustup --version" \
  "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh" \
  "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
check "rustc" required 1.85 \
  "rustc --version" \
  "rustup default stable" \
  "rustup default stable"
check "opentofu" required 1.9 \
  "tofu version" \
  "brew install opentofu" \
  "https://opentofu.org/docs/intro/install/deb/"
check "buf" required 1.40 \
  "buf --version" \
  "brew install bufbuild/buf/buf" \
  "https://buf.build/docs/cli/installation/"
check "aws cli" required 2.0 \
  "aws --version" \
  "brew install awscli" \
  "https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
check "git" required 2.30 \
  "git --version" \
  "brew install git" \
  "sudo apt install git"
check "gh" required 2.40 \
  "gh --version" \
  "brew install gh" \
  "https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
check "grpcurl" optional "" \
  "grpcurl -version" \
  "brew install grpcurl" \
  "https://github.com/fullstorydev/grpcurl#installation"
check "air" optional "" \
  "air -v" \
  "go install github.com/air-verse/air@v1.67.4" \
  "go install github.com/air-verse/air@v1.67.4"

# Docker Desktop memory: 3-4 GB keeps an 8 GB laptop responsive
mem_bytes="$(docker info --format '{{.MemTotal}}' 2>/dev/null || true)"
if [ -n "$mem_bytes" ]; then
  mem_gb="$(awk -v b="$mem_bytes" 'BEGIN { printf "%.1f", b / 1073741824 }')"
  if awk -v g="$mem_gb" 'BEGIN { exit !(g < 2.8) }'; then
    warn "docker memory ${mem_gb} GB: below recommended 3-4 GB (Docker Desktop > Settings > Resources)"
  elif awk -v g="$mem_gb" 'BEGIN { exit !(g > 5) }'; then
    warn "docker memory ${mem_gb} GB: above recommended 3-4 GB, leaves little RAM for the host"
  else
    ok "docker memory ${mem_gb} GB"
  fi
fi

if [ $missing -ne 0 ]; then
  fail "some required tools are missing or too old"
  exit 1
fi
ok "all required tools present"
