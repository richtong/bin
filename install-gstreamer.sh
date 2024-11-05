#!/usr/bin/env bash
##
## install gstreamer on Mac or Linux
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Install Gstreamer"
		echo "flags: -d debug, -v verbose, -h help"
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
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh
set -u
shift $((OPTIND - 1))
PACKAGES+=(
	# gstreamer  #
	libnice # this include gstremer now
	# gst-plugins-base  # now part of gstreamer
	# gst-plugins-good  # now part of gstreamer
	# gst-plugins-bad   # now part of gstreamer
	# gst-plugins-ugly  # now part of gstreamer
)

package_install "${PACKAGES[@]}"
