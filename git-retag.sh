#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
##
## Retag a release
##
## This delete the local and global tags
## then repushes the current release
## Used for testing Github actions
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -ueo pipefail && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Push a release with the same tag as before
			    usage: $SCRIPTNAME [ flags ] tags...
			    flags: -h help
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
		echo "no -$opt" >&2
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

for tag in "$@"; do
	log_verbose "delete $tag"
	if ! git tag -d "$tag"; then
		log_verbose "no $tag on local"
	fi
	log_verbose "delete remote $tag"
	if ! git push origin :"$tag"; then
		log_verbose "no remote $tag"
	fi
	log_verbose "commit new local $tag"
	git tag -a "$tag" -m "Testing $tag"
	log_verbose "push local to remote $tag"
	git push origin "$tag"
done
