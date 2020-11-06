#!/usr/bin/env bash
##
## The above gets the latest bash on Mac or Ubuntu
##
## Standard include for all script
## symlink this to the CWD of each script directory
#

# assumes that the workspace has a "git" subdirectory
find_ws() {
	local dir=${1:-$SCRIPT_DIR}
	# shellcheck disable=SC2016
	local find_cmd='$(find "$dir" -maxdepth 2 -name mnt -prune -o -name git -print -quit 2>/dev/null)'
	local found
	while true; do
		# do not go into mnt
		eval found="$find_cmd"
		if [[ -n $found ]]; then
			dirname "$found"
			return 0
		fi
		if [[ $dir = / ]]; then break; fi
		dir=$(dirname "$dir")
	done
	# https://stackoverflow.com/questions/1489277/how-to-use-prune-option-of-find-in-sh
	# do not go down into the mount directory
	eval dir="$find_cmd"
	# if no ws, then create one
	if [[ -z $dir ]]; then mkdir -p "${dir:=$HOME/ws/git}"; fi
	eval dir="$find_cmd"
	echo "$dir"
}
export WS_DIR=${WS_DIR:-$(find_ws "$SCRIPT_DIR")}
export SOURCE_DIR=${SOURCE_DIR:-"$WS_DIR/git/src"}
# look for libs locally two levels up, then down from WS_DIR
source_lib() {
	while (($# > 0)); do
		# Change the sourcing to look first down from WS_DIR for speed
		# exclude mnt so we do not disaoppear into sshfs mounts
		# maxdepth needs to be high enough for ws/git/user to find
		# ws/git/src/infra/lib
		local lib
		lib=$(find "$WS_DIR" "$SCRIPT_DIR"/{.,..,../..} -maxdepth 7 \
			-name mnt -prune -o -name "$1" -print -quit)
		if [[ -n $lib ]]; then
			# shellcheck disable=SC1090
			source "$lib"
		fi
		shift
	done
}
source_lib lib-debug.sh
