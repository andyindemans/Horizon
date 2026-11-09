#!/usr/bin/env bash
# shellcheck disable=SC1091,2154

set -e

# include common functions and brand defaults (sourced once: build.sh sources this script, so a second source would double the insider GLOBAL_DIRNAME suffix)
. ./utils.sh

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  cp -rp src/insider/* vscode/
else
  cp -rp src/stable/* vscode/
fi

cp -f LICENSE vscode/LICENSE.txt

bash ./install_builtin_extensions.sh

cd vscode || { echo "'vscode' dir not found"; exit 1; }

{ set +x; } 2>/dev/null

# {{{ product.json
cp product.json{,.bak}

setpath() {
  local jsonTmp
  { set +x; } 2>/dev/null
  jsonTmp=$( jq --arg 'value' "${3}" "setpath(path(.${2}); \$value)" "${1}.json" )
  echo "${jsonTmp}" > "${1}.json"
  set -x
}

setpath_json() {
  local jsonTmp
  { set +x; } 2>/dev/null
  jsonTmp=$( jq --argjson 'value' "${3}" "setpath(path(.${2}); \$value)" "${1}.json" )
  echo "${jsonTmp}" > "${1}.json"
  set -x
}

setpath "product" "checksumFailMoreInfoUrl" "https://go.microsoft.com/fwlink/?LinkId=828886"
setpath "product" "documentationUrl" "https://go.microsoft.com/fwlink/?LinkID=533484#vscode"
setpath_json "product" "extensionsGallery" '{"serviceUrl": "https://open-vsx.org/vscode/gallery", "itemUrl": "https://open-vsx.org/vscode/item", "latestUrlTemplate": "https://open-vsx.org/vscode/gallery/{publisher}/{name}/latest", "controlUrl": "https://raw.githubusercontent.com/EclipseFdn/publish-extensions/refs/heads/master/extension-control/extensions.json"}'

setpath "product" "introductoryVideosUrl" "https://go.microsoft.com/fwlink/?linkid=832146"
setpath "product" "keyboardShortcutsUrlLinux" "https://go.microsoft.com/fwlink/?linkid=832144"
setpath "product" "keyboardShortcutsUrlMac" "https://go.microsoft.com/fwlink/?linkid=832143"
setpath "product" "keyboardShortcutsUrlWin" "https://go.microsoft.com/fwlink/?linkid=832145"
setpath "product" "licenseUrl" "https://github.com/${GH_REPO_PATH}/blob/master/LICENSE"
setpath_json "product" "linkProtectionTrustedDomains" '["https://open-vsx.org"]'
setpath "product" "releaseNotesUrl" "https://go.microsoft.com/fwlink/?LinkID=533483#vscode"
setpath "product" "reportIssueUrl" "https://github.com/${GH_REPO_PATH}/issues/new"
setpath "product" "requestFeatureUrl" "https://go.microsoft.com/fwlink/?LinkID=533482"
setpath "product" "tipsAndTricksUrl" "https://go.microsoft.com/fwlink/?linkid=852118"
setpath "product" "twitterUrl" "https://go.microsoft.com/fwlink/?LinkID=533687"

if [[ "${DISABLE_UPDATE}" != "yes" ]]; then
  # Horizon: no update server; dev/build.sh sets DISABLE_UPDATE=yes
  setpath "product" "updateUrl" "https://raw.githubusercontent.com/VSCodium/versions/refs/heads/master"

  if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
    setpath "product" "downloadUrl" "https://github.com/${ASSETS_REPOSITORY}/releases"
  else
    setpath "product" "downloadUrl" "https://github.com/${ASSETS_REPOSITORY}/releases"
  fi
fi

# if [[ "${OS_NAME}" == "windows" ]]; then
#   setpath_json "product" "win32VersionedUpdate" "true"
# fi

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  setpath "product" "nameShort" "Horizon - Insiders"
  setpath "product" "nameLong" "Horizon - Insiders"
  setpath "product" "applicationName" "horizon-insiders"
  setpath "product" "dataFolderName" ".horizon-insiders"
  setpath "product" "linuxIconName" "horizon-insiders"
  setpath "product" "quality" "insider"
  setpath "product" "urlProtocol" "horizon-insiders"
  setpath "product" "serverApplicationName" "horizon-server-insiders"
  setpath "product" "serverDataFolderName" ".horizon-server-insiders"
  setpath "product" "darwinBundleIdentifier" "com.andyindemans.horizon.insiders"
  setpath "product" "win32AppUserModelId" "Horizon.HorizonInsiders"
  setpath "product" "win32DirName" "Horizon Insiders"
  setpath "product" "win32MutexName" "horizoninsiders"
  setpath "product" "win32NameVersion" "Horizon Insiders"
  setpath "product" "win32RegValueName" "HorizonInsiders"
  setpath "product" "win32ShellNameShort" "Horizon Insiders"
  setpath "product" "win32AppId" "{{C768DB75-4B2E-4305-8B31-C32AA2E6B62C}"
  setpath "product" "win32x64AppId" "{{79784F3A-BB45-4F5B-B7FB-E0370EAC4464}"
  setpath "product" "win32arm64AppId" "{{973BA464-331D-4278-A7AD-481284616300}"
  setpath "product" "win32UserAppId" "{{81A85BA5-26E1-491E-A7D7-BF69B20975E6}"
  setpath "product" "win32x64UserAppId" "{{7649FC78-158D-442D-96A9-01C437C60FBA}"
  setpath "product" "win32arm64UserAppId" "{{74D7BE8A-1602-4713-A922-187691EEC6B6}"
  setpath "product" "tunnelApplicationName" "horizon-insiders-tunnel"
  setpath "product" "win32TunnelServiceMutex" "horizoninsiders-tunnelservice"
  setpath "product" "win32TunnelMutex" "horizoninsiders-tunnel"
  setpath "product" "win32ContextMenu.x64.clsid" "602EFEF1-D4E9-462E-97CB-1EF832F3052A"
  setpath "product" "win32ContextMenu.arm64.clsid" "DDF47D6A-96E0-4330-8C02-9A8890BDE5CF"
else
  setpath "product" "nameShort" "Horizon"
  setpath "product" "nameLong" "Horizon"
  setpath "product" "applicationName" "horizon"
  setpath "product" "dataFolderName" ".horizon"
  setpath "product" "linuxIconName" "horizon"
  setpath "product" "quality" "stable"
  setpath "product" "urlProtocol" "horizon"
  setpath "product" "serverApplicationName" "horizon-server"
  setpath "product" "serverDataFolderName" ".horizon-server"
  setpath "product" "darwinBundleIdentifier" "com.andyindemans.horizon"
  setpath "product" "win32AppUserModelId" "Horizon.Horizon"
  setpath "product" "win32DirName" "Horizon"
  setpath "product" "win32MutexName" "horizon"
  setpath "product" "win32NameVersion" "Horizon"
  setpath "product" "win32RegValueName" "Horizon"
  setpath "product" "win32ShellNameShort" "Horizon"
  setpath "product" "win32AppId" "{{8314FD48-0556-4A27-A952-9DCFF113E5BA}"
  setpath "product" "win32x64AppId" "{{F841A869-0BCD-4BF1-8345-BC916ACE789E}"
  setpath "product" "win32arm64AppId" "{{F7A8A835-9A68-4E35-80F1-573EC59618D0}"
  setpath "product" "win32UserAppId" "{{6BF8A9C4-2C76-4753-9430-4D80A1864340}"
  setpath "product" "win32x64UserAppId" "{{5A488EDF-905B-493F-8750-22FC285BB6B0}"
  setpath "product" "win32arm64UserAppId" "{{6203F8AA-B0F2-43B8-AF1E-D67FF2BFF61D}"
  setpath "product" "tunnelApplicationName" "horizon-tunnel"
  setpath "product" "win32TunnelServiceMutex" "horizon-tunnelservice"
  setpath "product" "win32TunnelMutex" "horizon-tunnel"
  setpath "product" "win32ContextMenu.x64.clsid" "364ED0B1-28DE-49C9-B68C-BFCFB1F6DD4D"
  setpath "product" "win32ContextMenu.arm64.clsid" "219627C0-9A14-4FCD-926C-A760FAB252EB"
fi

setpath_json "product" "tunnelApplicationConfig" '{}'

jsonTmp=$( jq -s '.[0] * .[1]' product.json ../product.json )
echo "${jsonTmp}" > product.json && unset jsonTmp

cat product.json
# }}}

# {{{ apply patches

echo "APP_NAME=\"${APP_NAME}\""
echo "APP_NAME_LC=\"${APP_NAME_LC}\""
echo "ASSETS_REPOSITORY=\"${ASSETS_REPOSITORY}\""
echo "BINARY_NAME=\"${BINARY_NAME}\""
echo "GH_REPO_PATH=\"${GH_REPO_PATH}\""
echo "GLOBAL_DIRNAME=\"${GLOBAL_DIRNAME}\""
echo "ORG_NAME=\"${ORG_NAME}\""
echo "TUNNEL_APP_NAME=\"${TUNNEL_APP_NAME}\""

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
# }}}

set -x

# {{{ install dependencies
export ELECTRON_SKIP_BINARY_DOWNLOAD=1
export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

if [[ "${OS_NAME}" == "linux" ]]; then
  export VSCODE_SKIP_NODE_VERSION_CHECK=1

  if [[ "${npm_config_arch}" == "arm" ]]; then
    export npm_config_arm_version=7
  fi
elif [[ "${OS_NAME}" == "windows" ]]; then
  if [[ "${npm_config_arch}" == "arm" ]]; then
    export npm_config_arm_version=7
  fi
else
  if [[ "${CI_BUILD}" != "no" ]]; then
    clang++ --version
  fi
fi

node build/npm/preinstall.ts

for i in {1..5}; do # try 5 times
  if [[ "${CI_BUILD}" != "no" && "${OS_NAME}" == "osx" ]]; then
    CXX=clang++ npm ci && break
  else
    npm ci && break
  fi

  if [[ $i == 5 ]]; then
    echo "Npm install failed too many times" >&2
    exit 1
  fi
  echo "Npm install failed $i, trying again..."

  sleep $(( 15 * (i + 1)))
done
# }}}

# package.json
cp package.json{,.bak}

setpath "package" "version" "${RELEASE_VERSION%-insider}"

replace "s|Microsoft Corporation|${ORG_NAME}|" package.json
replace "s|--max-old-space-size=8192|--max-old-space-size=${MAX_OLD_SPACE_SIZE}|" package.json

cp resources/server/manifest.json{,.bak}

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  setpath "resources/server/manifest" "name" "${APP_NAME} - Insiders"
  setpath "resources/server/manifest" "short_name" "${APP_NAME} - Insiders"
else
  setpath "resources/server/manifest" "name" "${APP_NAME}"
  setpath "resources/server/manifest" "short_name" "${APP_NAME}"
fi

# announcements
replace "s|\\[\\/\\* BUILTIN_ANNOUNCEMENTS \\*\\/\\]|$( tr -d '\n' < ../announcements-builtin.json )|" src/vs/workbench/contrib/welcomeGettingStarted/browser/gettingStarted.ts

../undo_telemetry.sh

replace "s|Microsoft Corporation|${ORG_NAME}|" build/lib/electron.ts
replace "s|([0-9]) Microsoft|\\1 ${ORG_NAME}|" build/lib/electron.ts

if [[ "${OS_NAME}" == "linux" ]]; then
  # microsoft adds their apt repo to sources
  # unless the app name is code-oss
  # as we are renaming the application
  # we need to edit a line in the post install template
  if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
    sed -i "s/code-oss/${BINARY_NAME}/" resources/linux/debian/postinst.template
  else
    sed -i "s/code-oss/${BINARY_NAME}/" resources/linux/debian/postinst.template
  fi

  # fix the packages metadata
  # code.appdata.xml
  sed -i "s|Visual Studio Code|${APP_NAME}|g" resources/linux/code.appdata.xml
  sed -i "s|https://code.visualstudio.com/docs/setup/linux|https://github.com/${GH_REPO_PATH}#download-install|" resources/linux/code.appdata.xml
  sed -i "s|https://code.visualstudio.com/home/home-screenshot-linux-lg.png|https://github.com/${GH_REPO_PATH}|" resources/linux/code.appdata.xml
  sed -i "s|https://code.visualstudio.com|https://github.com/${GH_REPO_PATH}|" resources/linux/code.appdata.xml

  # control.template
  sed -i "s|Microsoft Corporation <vscode-linux@microsoft.com>|${ORG_NAME} https://github.com/${GH_REPO_PATH}|"  resources/linux/debian/control.template
  sed -i "s|Visual Studio Code|${APP_NAME}|g" resources/linux/debian/control.template
  sed -i "s|https://code.visualstudio.com/docs/setup/linux|https://github.com/${GH_REPO_PATH}#download-install|" resources/linux/debian/control.template
  sed -i "s|https://code.visualstudio.com|https://github.com/${GH_REPO_PATH}|" resources/linux/debian/control.template

  # code.spec.template
  sed -i "s|Microsoft Corporation|${ORG_NAME}|" resources/linux/rpm/code.spec.template
  sed -i "s|Visual Studio Code Team <vscode-linux@microsoft.com>|${ORG_NAME} https://github.com/${GH_REPO_PATH}|" resources/linux/rpm/code.spec.template
  sed -i "s|Visual Studio Code|${APP_NAME}|" resources/linux/rpm/code.spec.template
  sed -i "s|https://code.visualstudio.com/docs/setup/linux|https://github.com/${GH_REPO_PATH}#download-install|" resources/linux/rpm/code.spec.template
  sed -i "s|https://code.visualstudio.com|https://github.com/${GH_REPO_PATH}|" resources/linux/rpm/code.spec.template

  # snapcraft.yaml
  sed -i "s|Visual Studio Code|${APP_NAME}|" resources/linux/rpm/code.spec.template
elif [[ "${OS_NAME}" == "windows" ]]; then
  # code.iss
  sed -i "s|https://code.visualstudio.com|https://github.com/${GH_REPO_PATH}|" build/win32/code.iss
  sed -i "s|Microsoft Corporation|${ORG_NAME}|" build/win32/code.iss
fi

cd ..
