#!/bin/sh
# Clones every repository in repos.txt next to ngumbah-platform; safe to re-run.
set -u
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

owner="${GITHUB_OWNER:-tahananazkaban}"
cloned=""; skipped=""; missing=""

for repo in $(list_repos); do
  target="$WORKSPACE_DIR/$repo"
  if [ -d "$target" ]; then
    info "$repo: already present, skipped"
    skipped="$skipped $repo"
    continue
  fi

  # gh handles private repositories with the existing login
  if command -v gh >/dev/null 2>&1 && gh repo view "$owner/$repo" >/dev/null 2>&1; then
    gh repo clone "$owner/$repo" "$target" -- --quiet && ok "$repo: cloned" && cloned="$cloned $repo"
  elif git ls-remote "https://github.com/$owner/$repo.git" >/dev/null 2>&1; then
    git clone --quiet "https://github.com/$owner/$repo.git" "$target" && ok "$repo: cloned" && cloned="$cloned $repo"
  else
    warn "$repo: not on GitHub yet, skipped"
    missing="$missing $repo"
  fi
done

echo
info "cloned:${cloned:- none}"
info "skipped (present):${skipped:- none}"
info "not on GitHub yet:${missing:- none}"
