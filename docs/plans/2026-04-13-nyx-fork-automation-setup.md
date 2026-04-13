# Nyx fork automation setup plan

> For Hermes: implement this plan on `nyx-patches`, then regenerate `integration/current` from `main` plus the patch branch.

Goal: configure the Protocol Nyx `hermes-agent` fork so `main` remains a protected mirror of the latest upstream release, `nyx-patches` becomes the durable control plane, `integration/proposed` becomes the generated PR branch, and `integration/current` becomes the protected operational and release branch.

Architecture: keep upstream release state, durable fork glue, generated candidate state, and release state on separate branches. Host durable workflows on `nyx-patches` because scheduled workflows require a stable default branch. Poll upstream releases every 6 hours, update `main` only when a newer release tag exists, then rebuild `integration/proposed` from `main` and `nyx-patches` and flow changes into `integration/current` only through PRs.

Tech stack: Git, GitHub Actions, GHCR, pytest, uv, Docker Buildx, actionlint.

---

## Task 1: Canonicalize the branch model in repo docs

Objective: add one durable operating document explaining branch roles, workflow responsibilities, repo settings, and release flow.

Files:
- Create: `docs/operations/nyx-fork-branch-lifecycle.md`
- Modify: `AGENTS.md`

Steps:
1. Add a repo operations document covering `main`, `nyx-patches`, `integration/current`, and `issue/*` branches.
2. Add a contributor-facing summary to `AGENTS.md` so future agents do not improvise the branch model.
3. Verify the docs use the same branch names everywhere.

## Task 2: Add branch automation scripts

Objective: store the sync and regeneration logic in versioned shell scripts rather than burying it in YAML.

Files:
- Create: `scripts/nyx/sync_main_from_upstream.sh`
- Create: `scripts/nyx/rebuild_integration_branch.sh`

Steps:
1. Write a script that fetches `upstream/main`, resets local `main`, and pushes it to origin.
2. Write a script that fetches `origin/main` and `origin/nyx-patches`, resets `integration/current` from `origin/main`, merges `origin/nyx-patches`, and force-pushes the result.
3. Make both scripts executable.
4. Verify both scripts support token-authenticated pushes inside GitHub Actions.

## Task 3: Add durable workflow orchestration on `nyx-patches`

Objective: create workflows that safely manage sync and generated-branch refresh from the durable control plane.

Files:
- Create: `.github/workflows/nyx-sync-main.yml`
- Create: `.github/workflows/nyx-refresh-integration.yml`

Steps:
1. Create a scheduled/manual workflow to sync `main` from `upstream/main`.
2. Create a workflow that rebuilds `integration/current` whenever `main` or `nyx-patches` changes.
3. Give both workflows explicit `contents: write` permissions.
4. Keep repository-scoped guards so the workflows do not misfire in unrelated clones.

## Task 4: Validate patch-branch changes before they become durable

Objective: add a PR workflow for `nyx-patches` so new glue is tested before it reaches the durable branch.

Files:
- Create: `.github/workflows/nyx-patch-ci.yml`

Steps:
1. Trigger on pull requests targeting `nyx-patches`.
2. Lint workflow files with `actionlint`.
3. Run the fast Python test suite on the patch branch.
4. Keep runtime requirements aligned with the existing repo tooling.

## Task 5: Move operational validation to `integration/current`

Objective: make the generated branch the one that runs the main operational test pipeline.

Files:
- Modify: `.github/workflows/tests.yml`
- Modify: `.github/workflows/notify-harness.yml`

Steps:
1. Change the main test workflow to trigger on `integration/current` instead of `main`.
2. Keep manual dispatch support.
3. Change harness notification to trigger from `integration/current`.
4. Preserve the existing harness secret contract.

## Task 6: Add Nyx-owned release workflow

Objective: publish a container image and GitHub Release from the generated operational branch.

Files:
- Create: `.github/workflows/nyx-release.yml`

Steps:
1. Support manual release dispatch with `ref`, `tag`, and `publish_latest` inputs.
2. Verify the target commit is contained in `origin/integration/current`.
3. Build and smoke-test the container image.
4. Publish the image to GHCR.
5. Create the GitHub Release with generated notes.

## Task 7: Create the local branch scaffolding

Objective: reflect the branch model in the local repo so the workflow set has a concrete home.

Files:
- Branches: `main`, `nyx-patches`, `integration/current`

Steps:
1. Commit the automation/docs changes on `nyx-patches`.
2. Create or refresh `integration/current` from `main`.
3. Merge `nyx-patches` into `integration/current`.
4. Verify the generated branch contains the expected workflow set.

## Task 8: Repo settings follow-through

Objective: identify the remaining GitHub UI settings required after the code changes land.

Files:
- Reference only: GitHub repository settings

Steps:
1. Set default branch to `nyx-patches`.
2. Add branch protections for `main`, `nyx-patches`, and `integration/current`.
3. Ensure Actions can write contents and packages.
4. Confirm GHCR package visibility and permissions.
5. Add `NYX_GH_TOKEN` only if `GITHUB_TOKEN` cannot satisfy protected-branch updates.

## Verification checklist

- `docs/operations/nyx-fork-branch-lifecycle.md` exists and matches the final branch names.
- `AGENTS.md` explains the branch model.
- Sync and regeneration logic lives in `scripts/nyx/`.
- `nyx-sync-main.yml` and `nyx-refresh-integration.yml` exist.
- `nyx-patch-ci.yml` exists and targets `nyx-patches` PRs.
- `tests.yml` targets `integration/current`.
- `notify-harness.yml` targets `integration/current`.
- `nyx-release.yml` builds from `integration/current` and publishes GHCR + GitHub Release.
- Local branches `nyx-patches` and `integration/current` exist.
