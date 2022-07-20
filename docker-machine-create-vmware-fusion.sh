#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## Recreate the Mac VMware Fusion box for running apps
## Need this because xhyve in docker for mac is not working
## or well supported as of September 2017
##
##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
MACHINE=${MACHINE:-fusion}
OPTIND=1
while getopts "hdvm:" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Create default VMware Fusion for the Mac"
		echo "flags: -d debug, -v verbose, -h help"
		echo "       -m name of the machine (default: $MACHINE)"
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
	m)
		MACHINE="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh

if ! in_os mac; then
	log_error 1 only runs on Mac
fi

if docker-machine status "$MACHINE"; then
	if docker-machine status "$MACHINE" | grep Running; then
		docker-machine stop "$MACHINE"
	fi
	docker-machine rm -f "$MACHINE"
fi

docker-machine create -d vmwarefusion --vmwarefusion-cpu-count "4" \
	--vmwarefusion-disk-size "100000" --vmwarefusion-memory-size "4096" "$MACHINE"

docker login

echo "$MACHINE created, to use run the command"
echo "eval $(docker-machine env "$MACHINE")"
