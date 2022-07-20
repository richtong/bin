#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
## The above gets the latest bash on Mac or Ubuntu
##
# Due to git build issues sometimes we get merge issues
# So this utility resets personal to master to prevent this
#

set -ueo pipefail && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
# over kill for a single flag to debug, but good practice
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
OPTIND=1
while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Post prebuild installation of packages"
		echo "flags: -d debug, -h help -v verbose"
		exit 0
		;;
	d)
		# invert the variable when flag is set
		DEBUGGING="$($DEBUGGING && echo false || echo true)"
		export DEBUGGING
		;&
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

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

# The default is ws and others, you can either set in flags
# Or as shell variables exported
# For whatever reason you must use $HOME here and not ~ even though
# test works in interactive bash but won't work in a script
SOURCE_DIR=${SOURCE_DIR:-"$WS_DIR/git/src"}
PERSONAL_DIR=${PERSONAL_DIR:-"$WS_DIR/git/user"}

set -u

for repo in "$SOURCE_DIR" "$PERSONAL_DIR"; do
	log_verbose "resetting $repo"
	pushd "$repo" >/dev/null
	git fetch
	git checkout master
	git reset --hard origin/master
	popd
done
