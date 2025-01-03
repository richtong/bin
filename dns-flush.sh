#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## Flush the DNS cache of old names
## https://help.dreamhost.com/hc/en-us/articles/214981288-Flushing-your-DNS-cache-in-Mac-OS-X-and-Linux
##
##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
OPTIND=1
while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo Flush DNS cache of stale names
		echo "usage: $SCRIPTNAME [ flags ]"
		echo
		echo "flags: -d debug, -v verbose, -h help"
		echo
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
	*)
		echo "no -$opt flag" >&2
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh

if in_os mac; then
	sudo killall -HUP mDNSResponder
else
	log_verbose with Ubuntu 16.04 dsnmasq set to no cache by default
	# https://ubuntuforums.org/showthread.php?t=2342883
	if sudo service nscd status | grep -q running; then
		log_verbose found nscd so restarting it as cache
		sudo service nscd restart
	fi
fi
