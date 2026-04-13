#!/usr/bin/env bash
set -euo pipefail

UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-upstream}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-main}"
TARGET_REMOTE="${TARGET_REMOTE:-origin}"
TARGET_BRANCH="${TARGET_BRANCH:-main}"
PUSH_TOKEN="${PUSH_TOKEN:-}"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Must be run inside a git repository" >&2
  exit 1
fi

if [ -n "$PUSH_TOKEN" ]; then
  repo_url="https://x-access-token:${PUSH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
  git remote set-url "$TARGET_REMOTE" "$repo_url"
fi

echo "Fetching ${UPSTREAM_REMOTE}/${UPSTREAM_BRANCH}"
git fetch --prune "$UPSTREAM_REMOTE" "$UPSTREAM_BRANCH"

echo "Resetting ${TARGET_BRANCH} to ${UPSTREAM_REMOTE}/${UPSTREAM_BRANCH}"
git checkout -B "$TARGET_BRANCH" "${UPSTREAM_REMOTE}/${UPSTREAM_BRANCH}"

echo "Pushing ${TARGET_BRANCH} to ${TARGET_REMOTE}"
git push "$TARGET_REMOTE" "$TARGET_BRANCH" --force-with-lease
