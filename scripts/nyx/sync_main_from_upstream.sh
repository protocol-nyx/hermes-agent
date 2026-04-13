#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-${GITHUB_REPOSITORY:-}}"
TARGET_BRANCH="${TARGET_BRANCH:-main}"
GH_TOKEN="${GH_TOKEN:-${PUSH_TOKEN:-}}"

if [ -z "$REPO" ]; then
  echo "GITHUB_REPOSITORY or REPO must be set" >&2
  exit 1
fi

if [ -z "$GH_TOKEN" ]; then
  echo "GH_TOKEN (or PUSH_TOKEN) must be set" >&2
  exit 1
fi

export GH_TOKEN

echo "Syncing ${REPO}:${TARGET_BRANCH} from upstream via GitHub fork-sync API"
gh api \
  -X POST \
  "repos/${REPO}/merge-upstream" \
  -f branch="$TARGET_BRANCH"
