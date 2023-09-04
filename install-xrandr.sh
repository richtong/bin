#!/usr/bin/env bash
# vim: set noet ts=4 sw=4:
#
## Install a new screen resolution with XRandR
## @author Rich Tong
## @returns 0 on success
#
# https://igor.technology/solving-ubuntu-2004lts-external-monitor-resolution-problems/
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
MONITOR="${MONITOR:-DP-2}"
RESOLUTION="${RESOLUTION:-2560x1440}"
SIGNIN="${SIGNIN:-my}"
OPTIND=1
export FLAGS="${FLAGS:-""}"

while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Install a new screen resolution to a display (Linux only)
			usage: $SCRIPTNAME [flags] [[monitor (default: $MONITOR)] resolution: (default: $RESOLUTION)]
			flags:
				   -h help
				   -d $($DEBUGGING && echo "no ")debugging
				   -v $($VERBOSE && echo "not ")verbose
			Current modes:
		EOF
		if command -v xrandr >/dev/null; then
			xrandr
		fi
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
		echo "no flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh

if ! in_os linux; then
	log_exit "Linux only"
fi

if ! command -v xrandr >/dev/null; then
	log_error 3 "No xrandr available"
fi

log_verbose "Make sure the monitor requested is there"
if [[ ! $(xrandr --listactivemonitors | awk '{print $4}') =~ $MONITOR ]]; then
	log_error 1 "$MONITOR Monitor not found"
fi

log_verbose "Make sure the mode is in xrandr"
if [[ ! $(xrandr | grep "^ " | awk '{print $1}' | sort -u) =~ $RESOLUTION ]]; then
	log_error 2 "$RESOLUTION resolution not available"
fi

# it is not easy to figure
if [[ $(xrandr | awk "/^$MONITOR/{f=1; next} /^[a-zA-Z]/{f=0} f") =~ $RESOLUTION ]]; then
	log_exit "$MONITOR already has $RESOLUTION mode"
fi

xrandr --addmode "$MONITOR" "$RESOLUTION"
