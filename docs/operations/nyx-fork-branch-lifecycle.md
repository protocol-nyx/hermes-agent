# Nyx Fork Branch Lifecycle

This document is the canonical operating model for Protocol Nyx's `hermes-agent` fork.

## Branch roles

### `main`
- Exact upstream sync mirror.
- Disposable by design.
- Updated by automation from `upstream/main`.
- Never used as the durable home for Nyx-specific workflows, release logic, or glue code.

### `nyx-patches`
- Durable Nyx control-plane branch.
- Default branch for the fork.
- Holds all custom GitHub Actions workflows, release glue, branch automation, and fork-only behavior.
- All feature work lands here through reviewed PRs from `issue/*` or `dev/*` branches.

### `integration/current`
- Generated operational branch.
- Rebuilt from `main` plus a merge of `nyx-patches`.
- Runs integration tests, container build validation, and release automation.
- Safe to overwrite and regenerate.
- Source branch for artifact publication and GitHub Releases.

### `issue/*` and `dev/*`
- Short-lived work branches.
- Always branch from `nyx-patches`.
- Always merge back into `nyx-patches` by PR.

## Core rules

1. `main` stays upstream-syncable.
2. Durable Nyx automation lives on `nyx-patches`, not on `main`.
3. `integration/current` is generated and may be force-updated.
4. If a fix is discovered on `integration/current`, port it back to `nyx-patches` immediately.
5. New custom behavior must enter through `issue/*` -> PR -> `nyx-patches`.

## Default branch

Set the fork's default branch to `nyx-patches`.

Reason:
- Scheduled workflows run from the default branch.
- Durable fork workflows cannot safely live on `main` because `main` is intentionally ephemeral.
- `nyx-patches` is the durable control plane for sync, integration refresh, and release orchestration.

## Workflow responsibilities

### `nyx-sync-main.yml`
- Runs on schedule or manual dispatch.
- Fetches `upstream/main`.
- Resets local `main` to `upstream/main`.
- Pushes `main` back to `origin`.

### `nyx-patch-ci.yml`
- Runs on PRs into `nyx-patches`.
- Validates Nyx-owned workflow and glue changes before they join the durable patch layer.

### `nyx-refresh-integration.yml`
- Runs after updates to `main` or `nyx-patches`, or by manual dispatch.
- Recreates `integration/current` from `origin/main`.
- Merges `origin/nyx-patches` into it.
- Force-pushes the regenerated branch.

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
7. `nyx-refresh-integration.yml` rebuilds `integration/current` from `main` + `nyx-patches`.
8. `tests.yml` validates `integration/current`.
9. `nyx-release.yml` publishes a container image from `integration/current` and creates a GitHub Release.

## GitHub repository settings to apply

1. Set default branch to `nyx-patches`.
2. Enable GitHub Actions read/write permissions.
3. Allow workflows to create and push branches if branch protections require it.
4. Protect `main` from direct human pushes.
5. Protect `nyx-patches` with PR-required checks.
6. Protect `integration/current` enough to guard releases, while allowing the refresh workflow to update it.
7. Enable GitHub Packages / GHCR publishing for the repo.

## Operational notes

- `integration/current` should be treated as generated state, not handcrafted truth.
- The durable truth for Nyx-specific repo behavior is `nyx-patches`.
- Upstream breakage is absorbed by the `main` sync step.
- Compatibility breakage is surfaced by the `integration/current` rebuild and test cycle.
- Release artifacts are produced from the branch that actually represents what Nyx intends to ship.
