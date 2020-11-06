#!/usr/bin/env bash
##
# Install the nosleep utility for macs
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

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
source_lib lib-mac.sh lib-install.sh lib-util.sh
set -u

if ! in_os mac; then
	log_exit 0 "mac only"
fi

if cask_install nosleep; then
	log_exit "Brew cask installed for nosleep"
fi

if [[ ! -e /Library/PreferencePanes/NoSleep.prefPane ]]; then
	log_verbose 1.3 does not run on El Capitan, need to find another link for it
	download_url_open "https://github.com/integralpro/nosleep/releases/download/v1.4.0/NoSleep-1.4.0.dmg"
	find_in_volume_open_then_detach "NoSleep.pkg"
fi
