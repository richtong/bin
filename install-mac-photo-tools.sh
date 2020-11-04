#!/usr/bin/env bash
##
## Flux changes screen color on a mac
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
OPTIND=1
PACKAGES=
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
PACKAGES+=" libdvdcss handbrake "

# log_verbose really want gimp 2.9, but load 2.8 for now
PACKAGEs+=" gimp exiftool "

# shellcheck disable=SC2086
package_install $PACKAGES

log_verbose install Photomatix for HDR photos
url=$(curl https://www.hdrsoft.com/download/photomatix-pro.html 2>/dev/null |
	grep -o -m 1 "https://.*mac/Photomatix_Pro.*zip")
log_verbose "photomatix url is $url"
download_url_open "$url"

log_warning Cannot automatically install PTGui for Panaramas
log_warning goto https://www.ptgui.com and type in registration to get
