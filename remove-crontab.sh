#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
##
## Comment out crontab jobs
##
## @author Rich Tong
## @returns 0 on success
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

# over kill for a single flag to debug, but good practice
OPTIND=1
while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME installs a crontab job to run the scons pre build"
		echo flags: -d debug, -h help, -v verbose
		exit 0
		;;
	d)
		export DEBUGGING=true
		;&
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

# assumes all after the added by goes away
crontab -l |
	sed -n "/^# Added by install-crontab/q;p" |
	crontab
