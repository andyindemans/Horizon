# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A fork of [VSCodium](https://github.com/VSCodium/vscodium) (origin: `andyindemans/Horizon`). It is **not** a fork of the editor source. It is a set of Bash build scripts that clone `microsoft/vscode` at a pinned commit, apply patches and rebranding, and build/package binaries. The editor product is still branded "VSCodium"/`codium`.

`vscode/` at the repo root is the **gitignored, disposable** upstream clone the scripts create (along with `VSCode-*` build outputs). Any change made directly in `vscode/` is lost on the next build unless it is captured into a patch under `patches/`. When working inside `vscode/` (for example while resolving a patch), upstream's own `vscode/AGENTS.md` applies there.

## Commands

All scripts are Bash. On Windows run them from Git Bash (`"C:\Program Files\Git\bin\bash.exe" ./dev/build.sh`) or `powershell -ExecutionPolicy ByPass -File .\dev\build.ps1`. Required on PATH: node (version in `.nvmrc`), `jq` (used by nearly every script), git, python 3.11, rustup; on Windows also 7-Zip (WiX v3 only for `.msi`).

Local build (`dev/build.sh`):
- `./dev/build.sh`: full stable build. Deletes and re-clones `vscode/`, applies patches, compiles.
- `-i` insider, `-l` use latest upstream VS Code instead of `upstream/<quality>.json` (also rewrites that JSON), `-o` skip compile, `-p` also produce packages/installers, `-s` reuse existing `vscode/` source (reads `dev/build.env` saved by the previous run).
- Run the built app from source: `cd vscode && npm run watch` then `./script/code.sh`.

Patch workflow (see `docs/howto-build.md`):
- `./dev/patch.sh <name>`: create or edit a single patch. It applies the prerequisites, pauses at "Press any key when the conflict have been resolved..." so you can edit `vscode/`, then regenerates `patches/<name>.patch` from the staged diff.
- `./dev/update_patches.sh [-i]`: walk every patch after an upstream bump. It pauses on each failing patch until all `*.rej` files are resolved, then rewrites the patch.
- `./dev/merge-patches.sh a b ... target`: combine patches.
- `./dev/update_api.sh [-i]`: sync `extensionEnabledApiProposals` in `product.json` from Microsoft's official build.

These scripts use `read -p` pauses, so they are interactive and are not suited to non-interactive tool execution.

Lint (via `justfile`, also enforced in CI):
- `just lint-ec` / `just lint-ec-fix`: `ecformat` EditorConfig check (see `.editorconfig`; patch files are exempt from whitespace rules).
- `just ci-lint` / `just ci-lint-fix`: `zizmor` security lint of GitHub workflows. Actions are pinned by commit SHA. Update them with `just ci-update` (`pinact`).

There is no unit test suite in this repo. Verification means building and running the app.

## Build pipeline architecture

The flow for both local and CI builds is `get_repo.sh` → `version.sh` → `build.sh` → `prepare_vscode.sh` → gulp tasks → `prepare_assets.sh` / `release.sh`.

- **`get_repo.sh`**: resolves `MS_TAG`/`MS_COMMIT` from `upstream/{stable,insider}.json` (or Microsoft's update API when `VSCODE_LATEST=yes`), computes `RELEASE_VERSION` = `<MS_TAG><4-digit hour-of-year>` (with an `-insider` suffix for insider), and shallow-fetches that commit into `vscode/`.
- **`prepare_vscode.sh`**: the core customization step. In order it:
  1. copies the `src/{stable,insider}/` overlay (icons, desktop files, resources) over `vscode/`
  2. sets branding and URL fields in `vscode/product.json` via `jq` (open-vsx gallery, app IDs, Windows GUIDs, update URLs), then deep-merges the root `product.json` on top
  3. applies patches
  4. runs `npm ci` with retries
  5. rewrites `package.json` and the server manifest
  6. runs `undo_telemetry.sh`, which blanks `*.data.microsoft.com` endpoints
  7. sed-rebrands Linux/Windows packaging templates
- **`build.sh`**: runs `npm run gulp vscode-min-prepack`, then the per-OS `vscode-<platform>-<arch>-min-packing` task, the CLI (`build_cli.sh`, Rust), and optionally the REH and REH-web servers.
- **`build/<os>/`**: per-OS packaging and asset scripts (`package_bin.sh`, `package_reh.sh`, `prepare_assets.sh`, `check_tags.sh`, Windows `msi/`/`appx/`/`rtf/`).
- **`check_tags.sh` / `release.sh` / `update_version.sh` / `update_upstream.sh`**: CI release logic. They decide whether a new upstream release needs building, publish GitHub releases, and push update metadata to the `versions` repo.
- **`stores/`**: snapcraft and winget manifests.

Branding is parameterized by the env vars `APP_NAME`, `BINARY_NAME`, `ORG_NAME`, `ASSETS_REPOSITORY`, `GH_REPO_PATH`, `VSCODE_QUALITY`, `OS_NAME` and `VSCODE_ARCH`. Defaults live in `utils.sh` and `dev/build.sh`, and CI sets them in the workflow `env:`. Many VSCodium-specific values (names, GUIDs, URLs) are still hardcoded in `prepare_vscode.sh`.

## Patch system

Patches are applied by `apply_patch` in `utils.sh`:
- Before `git apply --ignore-whitespace`, placeholders are substituted in the patch text: `!!APP_NAME!!`, `!!APP_NAME_LC!!`, `!!BINARY_NAME!!`, `!!ORG_NAME!!`, `!!GH_REPO_PATH!!`, `!!ASSETS_REPOSITORY!!`, `!!GLOBAL_DIRNAME!!`, `!!RELEASE_VERSION!!`, `!!TUNNEL_APP_NAME!!`. Use these in patches instead of literal branding.
- Order in `prepare_vscode.sh`:
  1. `00-update-disable.patch.yet` (only if `DISABLE_UPDATE=yes`)
  2. `patches/*.json` actions
  3. `patches/*.patch` (alphabetical)
  4. `patches/insider/` (insider only)
  5. `patches/<OS_NAME>/`
  6. `patches/user/` (local-only user patches)
  - `patches/linux/{client,reh}/`, `patches/linux/reh/<arch>/` and `patches/alpine/reh/` are applied later by the `build/<os>/package_*.sh` scripts.
- **Naming and dependencies:** `00-<area>-<desc>.patch` patches are standalone. A patch named `NM-*` with M ≥ 1 depends on the same-group patches `N0`…`N(M-1)`. The dev scripts apply those prerequisites first, so the generated diff is relative to them. For example, `11-update-use-github-release.patch` sits on top of `10-version-add-release.patch`.
- **Suffixes:** `.patch.no` is disabled (never applied). `.patch.yet` is conditionally applied. `.json` files (e.g. `52-ext-copilot-remove-it.json`, which strips Copilot/agent-host sources) are `{"action":"remove","paths":[...]}` lists executed by `apply_actions`. A missing path is a hard error (exit 4), so these lists must track upstream file moves.
- `patches/helper/settings.patch` is temporarily applied by the dev scripts as a "VSCODIUM HELPER" commit and excluded from generated patches.
- Patches are generated with `git diff --staged -U1` (1 line of context). Keep that format when hand-editing.
- `docs/patches.md` documents the rationale for specific patches.
- `font-size/` is a small TS tool (`npm run run -- [area]`) that regenerates the CSS inside `vscode/` used by `00-ui-custom-font.patch`.

## Upstream bumps

Bumping VS Code means updating `upstream/stable.json` (tag + commit). Then run `./dev/build.sh` and fix failing patches with `dev/update_patches.sh`. Commits follow conventional-commit style, e.g. `feat(1.143.1): update version`, `feat(1.143.1): update patches`, `fix: ...`, `ci(windows): ...`. Upstream VSCodium's convention is to open PRs against the `insider` branch. Upstream VSCodium's `CONTRIBUTING.md` asks contributors to disclose AI assistance and keep PRs focused and concise.
