#!/usr/bin/env bash
set -euo pipefail

SOURCE_REMOTE="${SOURCE_REMOTE:-origin}"
MIRROR_BRANCH="${MIRROR_BRANCH:-main}"
PATCH_BRANCH="${PATCH_BRANCH:-nyx-patches}"
INTEGRATION_BRANCH="${INTEGRATION_BRANCH:-integration/proposed}"
PUSH_TOKEN="${PUSH_TOKEN:-}"
MERGE_MESSAGE="${MERGE_MESSAGE:-chore: rebuild ${INTEGRATION_BRANCH} from ${MIRROR_BRANCH} + ${PATCH_BRANCH}}"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Must be run inside a git repository" >&2
  exit 1
fi

if [ -n "$PUSH_TOKEN" ]; then
  repo_url="https://x-access-token:${PUSH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
  git remote set-url "$SOURCE_REMOTE" "$repo_url"
fi

echo "Fetching ${SOURCE_REMOTE}/${MIRROR_BRANCH} and ${SOURCE_REMOTE}/${PATCH_BRANCH}"
git fetch --prune "$SOURCE_REMOTE" "$MIRROR_BRANCH" "$PATCH_BRANCH"

echo "Recreating ${INTEGRATION_BRANCH} from ${SOURCE_REMOTE}/${MIRROR_BRANCH}"
git checkout -B "$INTEGRATION_BRANCH" "${SOURCE_REMOTE}/${MIRROR_BRANCH}"

echo "Merging ${SOURCE_REMOTE}/${PATCH_BRANCH} into ${INTEGRATION_BRANCH}"
if ! git merge --no-ff --no-edit "${SOURCE_REMOTE}/${PATCH_BRANCH}" -m "$MERGE_MESSAGE"; then
  echo "Merge conflict while rebuilding ${INTEGRATION_BRANCH}" >&2
  git merge --abort || true
  exit 1
fi

echo "Pushing ${INTEGRATION_BRANCH} to ${SOURCE_REMOTE}"
git push "$SOURCE_REMOTE" "$INTEGRATION_BRANCH" --force-with-lease
