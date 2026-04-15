# Hermes Agent Patch Registry

This repository serves as the **Control Plane** for the `protocol-nyx/hermes-agent` fork. 

Instead of using traditional Git merges to maintain customizations—which leads to "merge-conflict loops" and "dirty" history—this registry treats the codebase as a composition of artifacts.

## ⚙️ How it Works: The Modular Core

The system uses an **Assembler** to generate a functional runtime from two distinct sources:
1. **The Mirror (`main`)**: A read-only, bit-for-bit mirror of the official `NousResearch/hermes-agent` release tags.
2. **The Registry**: This repository, containing discrete `.patch` files and a `manifest.yaml`.

### The Assembly Pipeline
Every 6 hours (or on manual trigger), the following process occurs:
1. **Sync (Conditional)**: The system polls for the latest upstream release tag. If the mirror (`main`) already matches the latest tag, the sync is skipped to avoid unnecessary noise. Otherwise, it hard-resets `main` to the new tag.
2. **Assemble**: The `assembler.py` script clones the mirrored `main` and applies patches in a specific priority order:
   `core` $
ightarrow$ `cli` $
ightarrow$ `gateway` $
ightarrow$ `ops` $
ightarrow$ `tests`.
3. **Inject**: Custom test suites from the registry are injected into the runtime.
4. **Deploy**: The resulting state is force-pushed to the `integration` branch.

## 📂 Structure

- `/patches/[group]/`: Contains `.patch` files (unified diffs). Each patch corresponds to a specific GitHub issue.
- `/tests/nyx_custom/`: Custom Python tests that are injected into the runtime to verify patch integrity.
- `manifest.yaml`: The source of truth for patch sequencing and group prioritization.
- `assembler.py`: The engine that performs the composition.

## 🛠️ Adding a Customization

To add a new feature or fix:
1. Create a temporary branch from the current `main` mirror.
2. Implement the change and verify it with a test.
3. Generate a unified diff: `git diff > issue-XXX-description.patch`.
4. Add the `.patch` file to the appropriate group folder.
5. Register the patch in `manifest.yaml`.
6. Submit a PR to this registry.

## 🎯 Goals
- **Zero-Drift**: We never "fight" upstream history.
- **Atomic Removal**: Deleting a patch file completely removes a feature without leaving git-residue.
- **Stable Base**: By pinning to release tags, we avoid unstable upstream commits.
