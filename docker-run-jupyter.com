#!/usr/bin/env bash
##
## install [Jupyter](https://github.com/jupyter/docker-stacks) run on docker
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
REPO="${REPO:-"jupyter"}"
NOTEBOOK="${NOTEBOOK:-"tensorflow-notebook"}"
while getopts "hdvr:" opt; do
	case "$opt" in
	h)
		echo $SCRIPTNAME: Install jupyter running on docker
		echo "flags: -d debug, -v verbose, -h help"
		echo "       -r repo (default: $REPO)"
		echo "positional  notebook (default: $NOTEBOOK)"
		exit 0
		;;
	d)
		DEBUGGING=true
		;;
	v)
		VERBOSE=true
		;;
	n)
		NOTEBOOK="$OPTARG"
		;;
	esac
done

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

log_verbose running $REPO/$NOTEBOOK
docker run -d --rm -p 8888:8888 --name "$NOTEBOOK" "$REPO/$NOTEBOOK"
log_verbose show the logs as they main have token info wait a little
sleep 5
docker logs "$NOTEBOOK"
