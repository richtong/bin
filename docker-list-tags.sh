#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
## The above gets the latest bash on Mac or Ubuntu
##
##install 1password for linux
## https://news.ycombinator.com/item?id=9091691 for linux gui
## https://news.ycombinator.com/item?id=8441388 for cli
## https://www.npmjs.com/package/onepass-cli for npm package
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
		echo "$SCRIPTNAME: List remote tags from a docker public registry"
		echo flags: -d debug, -h help
		echo "      repo/image repo/image repo/image..."
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
		export VERBOSE=true
		;;
	*)
		echo "no -$opt flag"
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
set -u

shift $((OPTIND - 1))
# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
for item in "$@"; do
	curl --silent "https://registry.hub.docker.com/v2/repositories/$item/tags/" | jq -c '.results[]["name"]'
done
