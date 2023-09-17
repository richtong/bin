#!/usr/bin/env bash
##
## Flux changes screen color on a mac
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"

PHOTOMATIX_URL="${PHOTOMATIX_URL:-https://www.hdrsoft.com/download/mac}"
PHOTOMATIX_VERSION="${PHOTOMATIX_VERSION:-6.3.2}"
DXO_VERSION="${DXO_VERSION:-6}"
DXO_URL="${DXO_URL:-"https://download-center.dxo.com/PhotoLab/v$DXO_VERSION/Mac/DxO_PhotoLab$DXO_VERSION.dmg"}"
CAPTUREONE_VERSION="${CAPTUREONE_VERSION:-"23"}"
PTGUI_VERSION="${PTGUI_VERSION:-"12.18"}"
# insert your GUID here but do not check in
FORCE="${FORCE:-false}"
OPTIND=1
while getopts "hdvp:c:t:a:f" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			         $SCRIPTNAME flags: -d debug
							-d $($DEBUGGING && echo "no ")debugging
							-v $($VERBOSE && echo "not ")verbose
			                -p PTGUI need GUID to download get from login
			                -t PTGUI version number (default: $PTGUI_VERSION)
			                -c Capture One needs GUID to download
			                -a Capture One Version (default: $CAPTUREONE_VERSION)
			                -f Force install Photomatix (default: $FORCE)
		EOF
		exit 0
		;;
	d)
		# invert the variable when flag is set
		DEBUGGING="$($DEBUGGING && echo false || echo true)"
		export DEBUGGING
		;;
	v)
		VERBOSE="$($VERBOSE && echo false || echo true)"
		export VERBOSE
		# add the -v which works for many commands
		if $VERBOSE; then export FLAGS+=" -v "; fi
		;;
	p)
		PTGUI_GUID="$OPTARG"
		;;
	t)
		PTGUI_VERSION="$OPTARG"
		;;
	c)
		CAPTUREONE_GUID="$OPTARG"
		;;
	a)
		CAPTUREONE_VERSION="$OPTARG"
		;;
	f)
		FORCE="$(FORCE && echo false || echo true)"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck disable=SC1091
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh
set -u

# log_verbose really want gimp 2.9, but load 2.8 for now
# blender - 3D editor
# exiftools - Read EXIF from files
# gimp - 2D editor
# handbrake - transcoding
# hugin - panaramas

log_verbose "handbrake needs libdvdcss from el capitan on"
PACKAGE+=(

	libdvdcss
	exiftool

)

Log_verbose "Install ${PACKAGE[*]}"
# shellcheck disable=SC2086
package_install "${PACKAGE[@]}"

# hugin not in snap or apt-get
# https://ubuntuhandbook.org/index.php/2022/04/hugin-panorama-stitcher-ubuntu-22-04/
if in_os linux; then
	apt_repository_install "ppa:ubuntuhandbook1/apps"
fi

# installs a cask on Mac or snap or apt-get on Ubuntu
APP+=(

	gimp
	hugin

)

log_verbose "Install common apps on MacOS and Linux"
package_install "${APP[@]}"

# rawtherapee: DxO open source version (deprecated no fresh Mac versions)
# darktable: Lightroom competitor open source use instead of rawtherapee
# luminance-hdr: HDR open source
# mkvtoolnix: Matrovska video file merge and info

CASK+=(

	blender
	darktable
	geotag
	handbrake
	luminance-hdr
	mkvtoolnix

)

SNAP+=(

	handbrake-jz

)
SNAP_CANDIDATE+=(

	kgeotag
	_
)
SNAP_CLASSIC+=(

	blender
)

if in_os mac; then
	# shellcheck disable=SC2068
	cask_install ${CASK[@]}

elif in_os linux; then
	# shellcheck disable=SC2068
	snap_install ${SNAP[@]}
	# shellcheck disable=SC2068
	snap_install --classic ${SNAP_CLASSIC[@]}
	# shellcheck disable=SC2068
	snap_install --candidate ${SNAP_CANDIDATE[@]}
	log_exit "Linux finished"
fi

log_verbose "Install Mac specific downloads"

if [[ -v DXO_VERSION ]]; then
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
	PTGUI_URL="${PTGUI_URL:-"https://www.ptgui.com/downloads/1218000/reg/mac105/standard/116185/$PTGUI_GUID/PTGui_$PTGUI_VERSION.dmg"}"
	download_url_open "$PTGUI_URL"
	log_verbose "Drag PTGUI and eject the Volume"
fi

if $FORCE || [[ ! -e "/Applications/Photomatix Pro 6.app" ]]; then
	log_verbose "install Photomatix for HDR photos"
	download_url_open "$PHOTOMATIX_URL/Photomatix_Pro_$PHOTOMATIX_VERSION.pkg.zip"
fi
