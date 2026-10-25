#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
preview_data_dir="$(mktemp -d "${TMPDIR:-/tmp}/klipper-kde-preview.XXXXXX")"
trap 'rm -rf -- "$preview_data_dir"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# The SDK reloads by package ID, so it must also find the source by that ID.
widget_id="com.github.vitroidfpv.klipper-kde"
mkdir -p "$preview_data_dir/plasma/plasmoids"
ln -s "$project_dir/package" "$preview_data_dir/plasma/plasmoids/$widget_id"
export XDG_DATA_DIRS="$preview_data_dir:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
export QT_FORCE_STDERR_LOGGING=1
export QT_LOGGING_RULES="${QT_LOGGING_RULES:-qml.debug=true}"
plasmoidviewer --applet "$widget_id" "$@"
