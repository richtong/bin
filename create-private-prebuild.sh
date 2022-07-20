#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
## The above gets the latest bash on Mac or Ubuntu
##
## Creates the prebuild that lives in Private.dmg or the ecryptfs
##
##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
PRIVATE_DMG=${PRIVATE_DMG:-"$HOME/Dropbox/Private.dmg"}
PRIVATE_DIR=${PRIVATE_DIR:-"/Volumes/Private"}
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			$SCRIPTNAME: Copy prebuild scripts to /Private
			flags:
					-d debug $($DEBUGGING && echo "off" || echo "on")
					-v verbose $($VERBOSE && echo "off" || echo "on")
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
	*)
		echo "no -$opt flag" >&2
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

set -u

if [[ ! -e "$PRIVATE_DIR" ]]; then
	if [[ ! -e "$PRIVATE_DMG" ]]; then
		hdiutil create "$PRIVATE_DMG" -encryption AES-256 -volname "Private" -size 16 -fs HFS+J
	fi
	hdiutil attach "$PRIVATE_DMG"
fi

rsync -av install-1password.sh include.sh prebuild.sh ../lib/lib-debug.sh ../lib/lib-git.sh "$PRIVATE_DIR"
