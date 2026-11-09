#!/usr/bin/env bash
# shellcheck disable=SC1091

# Resets vscode/ to upstream HEAD and applies all patches in prepare_vscode.sh order; no npm/product.json/overlay steps

set -e

while getopts ":i" opt; do
  case "$opt" in
    i)
      export VSCODE_QUALITY="insider"
      ;;
    *)
      ;;
  esac
done

if [[ "${VSCODE_QUALITY}" != "insider" ]]; then
  export VSCODE_QUALITY="stable"
fi

case "${OSTYPE}" in
  darwin*)
    export OS_NAME="osx"
    ;;
  msys* | cygwin*)
    export OS_NAME="windows"
    ;;
  *)
    export OS_NAME="linux"
    ;;
esac

export DISABLE_UPDATE="${DISABLE_UPDATE:-yes}"

if [[ -f dev/build.env ]]; then
  . dev/build.env
fi

. ./utils.sh

cd vscode || { echo "'vscode' dir not found"; exit 1; }

git add -A
git reset -q --hard HEAD

while [[ -n "$( git log -1 | grep "VSCODIUM HELPER" )" ]]; do
  git reset -q --hard HEAD~
done

if [[ "${DISABLE_UPDATE}" == "yes" ]]; then
  apply_patch ../patches/00-update-disable.patch.yet
fi

for file in ../patches/*.json; do
  if [[ -f "${file}" ]]; then
    apply_actions "${file}"
  fi
done

for file in ../patches/*.patch; do
  if [[ -f "${file}" ]]; then
    apply_patch "${file}"
  fi
done

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  for file in ../patches/insider/*.patch; do
    if [[ -f "${file}" ]]; then
      apply_patch "${file}"
    fi
  done
fi

if [[ -d "../patches/${OS_NAME}/" ]]; then
  for file in "../patches/${OS_NAME}/"*.patch; do
    if [[ -f "${file}" ]]; then
      apply_patch "${file}"
    fi
  done
fi

for file in ../patches/user/*.patch; do
  if [[ -f "${file}" ]]; then
    apply_patch "${file}"
  fi
done

echo "All patches applied"
