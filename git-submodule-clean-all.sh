#!/usr/bin/env bash
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
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
FORCE="${FORCE:-false}"
export FLAGS="${FLAGS:-""}"
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Delete a submodule
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help
		EOF
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		# add the -v which works for many commands
		export FLAGS+=" -v "
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

git reset --hard
git submodule foreach --recursive git clean -xfd
git submodule update --init --recursive
git submodule foreach --recursive git reset --hard
git clean -xfd
