#!/usr/bin/env bash
##
## Flux changes screen color on a mac
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
PHOTOMATIX_URL="${PHOTOMATIX_URL:-https://www.hdrsoft.com/download/photomatix-pro.html}"

DXO_VERSION="${DXO_VERSION:-4}"
CAPTUREONE_VERSION="${CAPTUREONE_VERSION:-"15.1.2"}"
PTGUI_VERSION="${PTGUI_VERSION:-"12.10"}"
# insert your GUID here but do not check in
OPTIND=1
while getopts "hdvp:c:" opt; do
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
	p)
		export PTGUI_GUID="$OPTARG"
		;;
	c)
		export CAPTUREONE_GUID="$OPTARG"
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
# blender - 3D editor
# exiftools - Read EXIF from files
# gimp - 2D editor
# handbrake - transcoding
# hugin - panaramas
# mkvnixtools - editing of MKV video files

PACKAGES+=(
	blender
	exiftool
	geotag
	gimp
	handbrake
	hugin
	mkvnixtools
)

# shellcheck disable=SC2086
package_install "${PACKAGES[@]}"

if [[ -v DXO_VERSION ]]; then
	DXO_URL="${DXO_URL:-"https://download-center.dxo.com/PhotoLab/v$DXO_VERSION/Mac/DxO_PhotoLab$DXO_VERSION.dmg"}"
	log_verbose "install DXO from $DXO_URL"
	download_url_open "$DXO_URL"
	log_verbose "Drag DXO App from Volume to Application Folder"
fi

log_warning "Capture One needs a user specific URL set as CAPTUREONE_GUID get by logging in "
if [[ -v CAPTUREONE_GUID ]]; then
	CAPTUREONE_URL="${CAPTUREONE_URL:-"https://downloads.phaseone.com/$CAPTUREONE_GUID/International/CaptureOne21.Mac.$CAPTUREONE_VERSION.dmg"}"
	log_verbose "Install Capture One from $CAPTUREONE_URL"
	download_url_open "$CAPTUREONE_URL"
	log_verbose "Drag Capture One and eject the Volume"
fi

log_warning "Cannot automatically install PTGui for Panaramas"
log_warning "goto https://www.ptgui.com and type in registration to and set PTGUI_GUID"
if [[ -v PTGUI_GUID ]]; then
	PTGUI_URL="${PTGUI_URL:-"https://www.ptgui.com/downloads/120000/reg/mac105/standard/112205/$PTGUI_GUID/PTGui_$PTGUI_VERSION.dmg"}"
	download_url_open "$PTGUI_URL"
	log_verbose "Drag PTGUI and eject the Volume"
fi

log_verbose install Photomatix for HDR photos
url="$(curl "$PHOTOMATIX_URL" 2>/dev/null |
	grep -o -m 1 "https://.*mac/Photomatix_Pro.*zip")"
log_verbose "photomatix url is $url"
download_url_open "$url"
