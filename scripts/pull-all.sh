#!/bin/sh
# Fast-forwards main in every cloned repository; never touches uncommitted work.
set -u
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

for repo in ngumbah-platform $(list_repos); do
  dir="$WORKSPACE_DIR/$repo"
  [ -d "$dir/.git" ] || continue

  if [ -n "$(git -C "$dir" status --porcelain)" ]; then
    warn "$repo: uncommitted changes, skipped"
    continue
  fi

  branch="$(git -C "$dir" rev-parse --abbrev-ref HEAD)"
  if [ "$branch" = main ]; then
    if git -C "$dir" pull --quiet --ff-only; then ok "$repo: main updated"; else fail "$repo: pull failed"; fi
  else
    # Updates local main without switching away from the current branch
    if git -C "$dir" fetch --quiet origin main:main; then ok "$repo: main updated (on $branch)"; else fail "$repo: fetch failed"; fi
  fi
done
