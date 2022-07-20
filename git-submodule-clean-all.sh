#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## Reset submodules when they break
##
##@author Rich Tong
##@returns 0 on success
#
# https://stackoverflow.com/questions/10317676/git-change-origin-of-cloned-submodule
# Three steps
# 1. Fix [submodule _dirname_ ]  entry in .gitmodules to new repo location
# 2. Fix [submodule _dirname_releative_to_git_root ] entry in .git/config
# 3. then do a git submodule sysn --recursive in git > 2.1 or In the repo ielf run `git config remote.origin.url [new_url]
#
set -ueo pipefail && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
OPTIND=1
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
FORCE="${FORCE:-false}"
DRY_RUN="${DRY_RUN:-false}"
DRY_RUN_FLAG="${DRY_RUN_FLAG:-""}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvn:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Delete a submodule
			    usage: $SCRIPTNAME [ flags ]
			    flags: -h help
					-d debug $($DEBUGGING && echo "off" || echo "on")
					-v verbose $($VERBOSE && echo "off" || echo "on")
				-n Dry run (default: DRY_RUN)
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
		# add the -v which works for many commands
		export FLAGS+=" -v "
		;;
	n)
		DRY_RUN=true
		DRY_RUN_FLAG="-$opt"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh

CMDS=(
	"git reset --hard"
	"git clean -xfd"
)
PARENT_CMDS=(
	"git submodule update --init --recursive --remote"
)

log_verbose "clean the parent repo"

# shellcheck disable=SC2086
util_cmd $DRY_RUN_FLAG "${CMDS[@]}"
# shellcheck disable=SC2086
util_cmd $DRY_RUN_FLAG "${PARENT_CMDS[@]}"

log_verbose "now clean the subdirectories"
# shellcheck disable=SC2086
util_cmd -s $DRY_RUN_FLAG "${CMDS[@]}"
