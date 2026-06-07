#!/bin/sh
set -eu

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
project_dir="${PROJECT_DIR:-$(cd "${script_dir}/../.." && pwd)}"
resources_path="${UNLOCALIZED_RESOURCES_FOLDER_PATH:-Resources}"
source_dir="${project_dir}/Runner/Resources"
target_dir="${TARGET_BUILD_DIR:-${project_dir}/../build/ffprobe_runtime_check}/${resources_path}"
source_ffprobe="${source_dir}/bin/ffprobe"

if [ ! -x "${source_ffprobe}" ]; then
  echo "error: Missing bundled ffprobe at ${source_ffprobe}" >&2
  exit 1
fi

mkdir -p "${target_dir}/bin" "${target_dir}/lib"
/usr/bin/ditto "${source_dir}/bin" "${target_dir}/bin"
/usr/bin/ditto "${source_dir}/lib" "${target_dir}/lib"
chmod 755 "${target_dir}/bin/ffprobe" "${target_dir}/lib/"*.dylib

if command -v xattr >/dev/null 2>&1; then
  xattr -dr com.apple.quarantine "${target_dir}/bin" "${target_dir}/lib" 2>/dev/null || true
  xattr -dr com.apple.provenance "${target_dir}/bin" "${target_dir}/lib" 2>/dev/null || true
fi

if command -v codesign >/dev/null 2>&1; then
  codesign --force --sign - "${target_dir}/lib/"*.dylib "${target_dir}/bin/ffprobe"
fi
