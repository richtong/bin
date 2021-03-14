#!/usr/bin/env bash
##
## Flux changes screen color on a mac
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
OPTIND=1
PHOTOMATIX_URL="${PHOTOMATIX_URL:-https://www.hdrsoft.com/download/photomatix-pro.html}"
DXO_VERSION="${DXO_VERSION:-4}"
DXO_URL="${DXO_URL:-"https://download-center.dxo.com/PhotoLab/v$DXO_VERSION/Mac/DxO_PhotoLab$DXO_VERSION.dmg"}"
# insert your GUID here but do not check in
PTGUI_GUID="${PTGUI_GUID="Do_not_check_in_this_guid"}"
PTGUI_URL="${PTGUI_URL:-"https://www.ptgui.com/downloads/120000/reg/mac105/standard/112205/$PTGUI_GUID/PTGui_12.0.dmg"}"
CAPTUREONE_GUID="${CAPTUREONE_GUID:-"Do_check_in_this_guid"}"
CAPTUREONE_URL="${CAPTUREONE_URL:-"https://downloads.phaseone.com/$CAPTUREONE_GUID/International/CaptureOne21.Mac.14.1.0.dmg"}"
OPTIND=1
while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME flags: -d debug"
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh
set -u

if ! in_os mac; then
	log_error 1 only work on a Mac
fi

log_verbose handbrake needs libdvdcss from el capitan on
PACKAGES=(libdvdcss handbrake)

# log_verbose really want gimp 2.9, but load 2.8 for now
PACKAGEs+=(gimp exiftool)

# shellcheck disable=SC2086
package_install "${PACKAGES[@]}"

log_verbose "install DXO from $DXO_URL"
download_url_open "$DXO_URL"
log_verbose "Drag DXO App from Volume to Application Folder"

log_warning "Capture One needs a user specific URLK set as CAPTUREONE_GUID"
log_verbose "Install Capture One from $CAPTUREONE_URL"
download_url_open "$CAPTUREONE_URL"
log_verbose "Drag Capture One and eject the Volume"

log_verbose install Photomatix for HDR photos
log_warning "PT Gui needs a user specific URLK set as PTGUI_GUID"
url="$(curl "$PHOTOMATIX_URL" 2>/dev/null |
	grep -o -m 1 "https://.*mac/Photomatix_Pro.*zip")"
log_verbose "photomatix url is $url"
download_url_open "$url"

log_warning "Cannot automatically install PTGui for Panaramas"
log_warning goto https://www.ptgui.com and type in registration to get
download_url_open "$PTGUI_URL"
log_verbose "Drag PTGUI and eject the Volume"
