# Nyx Fork Branch Lifecycle

This document is the canonical operating model for Protocol Nyx's `hermes-agent` fork.

## Branch roles

### `main`
- Protected mirror of the latest adopted upstream release.
- Disposable by design.
- Updated by automation only when upstream publishes a newer release.
- Never used as the durable home for Nyx-specific workflows, release logic, or glue code.

### `nyx-patches`
- Durable Nyx control-plane branch.
- Default branch for the fork.
- Holds all custom GitHub Actions workflows, release glue, branch automation, and fork-only behavior.
- All feature work lands here through reviewed PRs from `issue/*` or `dev/*` branches.

### `integration/proposed`
- Generated candidate branch.
- Rebuilt from `main` plus a merge of `nyx-patches`.
- Safe to overwrite and regenerate.
- Always the PR source branch into `integration/current`.

### `integration/current`
- Protected operational branch.
- Updated only by PR from `integration/proposed`.
- Runs integration tests, container build validation, and release automation.
- Source branch for artifact publication and GitHub Releases.

### `issue/*` and `dev/*`
- Short-lived work branches.
- Always branch from `nyx-patches`.
- Always merge back into `nyx-patches` by PR.

## Core rules

1. `main` stays protected and tracks the latest adopted upstream release, not arbitrary upstream branch commits.
2. Durable Nyx automation lives on `nyx-patches`, not on `main`.
3. `integration/proposed` is generated and may be force-updated.
4. `integration/current` is protected and updated only through PRs.
5. If a fix is discovered on `integration/current`, port it back to `nyx-patches` immediately.
6. New custom behavior must enter through `issue/*` -> PR -> `nyx-patches`.

## Default branch

Set the fork's default branch to `nyx-patches`.

Reason:
- Scheduled workflows run from the default branch.
- Durable fork workflows cannot safely live on `main` because `main` is intentionally ephemeral.
- `nyx-patches` is the durable control plane for sync, integration refresh, and release orchestration.

## Workflow responsibilities

### `nyx-sync-main.yml`
- Runs every 6 hours or by manual dispatch.
- Polls the upstream repository's latest stable release.
- Compares the upstream release tag commit to the commit currently pointed to by `main`.
- Updates `main` only when a newer upstream release is available.

### `nyx-patch-ci.yml`
- Runs on PRs into `nyx-patches`.
- Lints workflow files with `actionlint`.
- Runs patch-scoped tests: changed test files when present, otherwise a small smoke suite.
- Validates Nyx-owned workflow and glue changes before they join the durable patch layer without being blocked by unrelated upstream test drift.

### `nyx-refresh-integration.yml`
- Runs after updates to `main` or `nyx-patches`, or by manual dispatch.
- Recreates `integration/proposed` from `origin/main`.
- Merges `origin/nyx-patches` into it.
- Force-pushes `integration/proposed`.
- Opens or updates a PR from `integration/proposed` into `integration/current`.

### `tests.yml`
- Runs the Python test suite on `integration/current`.
- Treats `integration/current` as the operational validation branch.

### `nyx-release.yml`
- Runs from `nyx-patches` by manual dispatch or on Nyx tag pushes.
- Validates that the release ref is contained in `origin/integration/current`.
- Builds and smoke-tests the container image.
- Publishes the image to GHCR.
- Creates the GitHub Release.

### `notify-harness.yml`
- Runs from `integration/current`.
- Dispatches downstream harness rebuilds only from the generated operational branch.

## Repo lifecycle: issue to release

1. Open issue.
2. Create `issue/<name>` from `nyx-patches`.
3. Implement the change.
4. Open PR into `nyx-patches`.
5. `nyx-patch-ci.yml` validates the patch.
6. Merge PR into `nyx-patches`.
7. `nyx-refresh-integration.yml` rebuilds `integration/proposed` from `main` + `nyx-patches` and opens/updates a PR into `integration/current`.
8. `tests.yml` validates the PR and branch state for `integration/current`.
9. Merge the integration PR into `integration/current`.
10. `nyx-release.yml` publishes a container image from `integration/current` and creates a GitHub Release.

## GitHub repository settings to apply

1. Set default branch to `nyx-patches`.
2. Enable GitHub Actions read/write permissions.
3. Allow workflows to create and push branches if branch protections require it.
4. Protect `main` from ordinary direct pushes while allowing the release-sync automation path to rewrite it to the latest adopted release tag.
5. Protect `nyx-patches` with PR-required checks.
6. Protect `integration/current` with PR-required checks.
7. Leave `integration/proposed` unprotected so automation can refresh it.
8. Enable GitHub Packages / GHCR publishing for the repo.

## Operational notes

- `integration/current` should be treated as generated state, not handcrafted truth.
- The durable truth for Nyx-specific repo behavior is `nyx-patches`.
- Upstream adoption happens at release boundaries, not at arbitrary mid-release commits.
- Compatibility breakage is surfaced by the `integration/current` rebuild and test cycle.
- Release artifacts are produced from the branch that actually represents what Nyx intends to ship.
