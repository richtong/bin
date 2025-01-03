#!/usr/bin/env bash
##
## Install BCM4360 Wifi Adapter
## This is the adapater used on the MacBook 11,3 which is the Macbook Pro Retina 2014
##
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
while getopts "hdvw:" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Install BCM 4360"
		echo "flags: -d debug, -h help"
		echo "       -w workspace directory"
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	w)
		export WS_DIR="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh
set -u
shift $((OPTIND - 1))

# http://help.ubuntu.com/communit/WifiDocs/Driver/bcm43xx
if in_os linux && lspci | grep BCM4360; then
	package_install bcmwl-kernel-source
fi
