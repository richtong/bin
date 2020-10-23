#!/usr/bin/env bash
##
## Recreate the Mac Virtualbox default to be ready for compile
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

MACHINE=${MACHINE:-default}
OPTIND=1
while getopts "hdvm:" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Create default virtualbox for the Mac"
		echo "flags: -d debug, -v verbose, -h help"
		echo "       -m name of the machine (default: $MACHINE)"
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
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

docker-machine create -d virtualbox -virtualbox-cpu-count "4" \
	--virtualbox-disk-size "100000" --virtualbox-memory "4096" "$MACHINE"

docker login

echo "$MACHINE created, to use run the command"
echo "eval $(docker-machine env "$MACHINE")"
