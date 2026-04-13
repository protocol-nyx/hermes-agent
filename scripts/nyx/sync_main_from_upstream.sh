#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-${GITHUB_REPOSITORY:-}}"
TARGET_BRANCH="${TARGET_BRANCH:-main}"
UPSTREAM_REPO="${UPSTREAM_REPO:-NousResearch/hermes-agent}"
GH_TOKEN="${GH_TOKEN:-${PUSH_TOKEN:-}}"
SOURCE_REMOTE_URL="${SOURCE_REMOTE_URL:-https://github.com/${UPSTREAM_REPO}.git}"

if [ -z "$REPO" ]; then
  echo "GITHUB_REPOSITORY or REPO must be set" >&2
  exit 1
fi

if [ -z "$GH_TOKEN" ]; then
  echo "GH_TOKEN (or PUSH_TOKEN) must be set" >&2
  exit 1
fi

export GH_TOKEN

latest_tag="$(gh api "repos/${UPSTREAM_REPO}/releases/latest" --jq '.tag_name')"
if [ -z "$latest_tag" ] || [ "$latest_tag" = "null" ]; then
  echo "Could not determine latest upstream release tag" >&2
  exit 1
fi

echo "Latest upstream release tag: ${latest_tag}"

git fetch --force --tags "$SOURCE_REMOTE_URL" "refs/tags/${latest_tag}:refs/tags/${latest_tag}"
release_sha="$(git rev-list -n 1 "$latest_tag")"
current_main_sha="$(gh api "repos/${REPO}/branches/${TARGET_BRANCH}" --jq '.commit.sha')"

if [ "$current_main_sha" = "$release_sha" ]; then
  echo "${REPO}:${TARGET_BRANCH} already points at upstream release ${latest_tag} (${release_sha})"
  exit 0
fi

echo "Updating ${REPO}:${TARGET_BRANCH} from ${current_main_sha} to ${latest_tag} (${release_sha})"

gh api \
  -X PATCH \
  "repos/${REPO}/git/refs/heads/${TARGET_BRANCH}" \
  -f sha="$release_sha" \
  -F force=true >/dev/null

echo "Updated ${TARGET_BRANCH} to latest upstream release ${latest_tag}"
