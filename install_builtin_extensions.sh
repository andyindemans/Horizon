#!/usr/bin/env bash
# Copies prebuilt built-in extensions from a local, untracked directory into vscode/extensions/.
# Set HORIZON_BUILTIN_EXTENSIONS_DIR (for example in dev/local.env, which is gitignored).
# Each direct subfolder containing a package.json is copied to vscode/extensions/<subfolder>.
set -e

if [[ -z "${HORIZON_BUILTIN_EXTENSIONS_DIR}" ]]; then
  echo "No prebuilt built-in extensions configured"
  exit 0
fi

if [[ ! -d "${HORIZON_BUILTIN_EXTENSIONS_DIR}" ]]; then
  echo "HORIZON_BUILTIN_EXTENSIONS_DIR not found, skipping: ${HORIZON_BUILTIN_EXTENSIONS_DIR}" >&2
  exit 0
fi

for ext in "${HORIZON_BUILTIN_EXTENSIONS_DIR}"/*/; do
  if [[ ! -f "${ext}package.json" ]]; then
    continue
  fi

  name="$( basename "${ext}" )"

  if git -C vscode ls-files --error-unmatch "extensions/${name}/package.json" > /dev/null 2>&1; then
    echo "Refusing to overwrite upstream extension: ${name}" >&2
    exit 1
  fi

  rm -rf "vscode/extensions/${name}"
  cp -rp "${ext%/}" "vscode/extensions/${name}"

  echo "Installed prebuilt built-in extension: ${name}"
done
