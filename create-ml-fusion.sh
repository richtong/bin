#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## Create a machine learning instance with vmware fusion
##
## Moves secrets into a usb or a Dropbox
##
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
MACHINE=${MACHINE:-ml}
while getopts "hdvm" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			$SCRIPTNAME: create a vmware fusion machine with machine learning in it
			flags:
					-d debug $($DEBUGGING && echo "off" || echo "on")
					-v verbose $($VERBOSE && echo "off" || echo "on")
			       -m name of machine learning machine
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
	m)
		MACHINE="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# shellcheck disable=SC1091
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi

set -u
shift $((OPTIND - 1))

if [[ $(uname) != Darwin ]]; then
	log_exit "$SCRIPTNAME: only runs on a mac"
fi

if ! docker-machine status "$MACHINE" >/dev/null; then
	docker-machine create --driver vmwarefusion \
		--vmwarefusion-cpu-count 4 \
		--vmwarefusion-disk-size 100000 \
		--vmwarefusion-memory-size 4096 \
		"$MACHINE"
fi

if ! docker-machine status "$MACHINE" | grep Running >/dev/null; then
	docker-machine start "$MACHINE"
fi

echo "to access the machine '$MACHINE' run"
echo "    docker-machine env $MACHINE"
echo Note that the docker machine does not appear in the vmware fusion app
echo To access it you should run
echo "     docker-machine ssh $MACHINE"
