#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## install [Jupyter](https://github.com/jupyter/docker-stacks) run on docker
##
##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
OPTIND=1
REPO="${REPO:-"jupyter"}"
NOTEBOOK="${NOTEBOOK:-"tensorflow-notebook"}"
while getopts "hdvr:n:" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Install jupyter running on docker"
		echo "flags: -d debug, -v verbose, -h help"
		echo "       -r repo (default: $REPO)"
		echo "positional  notebook (default: $NOTEBOOK)"
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
	n)
		NOTEBOOK="$OPTARG"
		;;
	*)
		echo "no -$opt"
		;;
	esac
done

# shellcheck disable=SC1090
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-docker.sh

set -u
shift $((OPTIND - 1))
if (($# > 0)); then
	NOTEBOOK="$1"
fi

# pulls things assuming your git directory is $WS_DIR/git a la Sam's convention
# There is an optional 2nd parameter for the repo defaults to surround-io

if docker_find_container "$NOTEBOOK"; then
	log_error 0 "$NOTEBOOK already exists"
fi

log_verbose "running $REPO/$NOTEBOOK"
docker run -d --rm -p 8888:8888 --name "$NOTEBOOK" "$REPO/$NOTEBOOK"
log_verbose show the logs as they main have token info wait a little
sleep 5
docker logs "$NOTEBOOK"
