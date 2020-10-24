#!/usr/bin/env bash
##
## Merge a repo into another
## http://blog.caplin.com/2013/09/18/merging-two-git-repositories/
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
DEST=${DEST:-richtong/src}
# This intentionally does nothing
while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Merge a repo into the current one"
		echo "flags: -d debug, -h help"
		echo "       -t target user/repo (default: $DEST)"
		echo "list of user/repo pairs to be merged"
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh

shift $((OPTIND - 1))
set -u

if (($# < 1)); then
	log_error 1 "need at least the repo from which you are merging commits"
fi
# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
for repo in "$DEST" "$@"; do
	repo_user=$(dirname "$repo")
	repo_dir=$WS_DIR/git/$repo_user
	if [[ ! -e "$repo_dir" ]]; then
		mkdir -p "$repo_dir"
		cd "$repo_dir"
		git clone "git@github.com:$repo"
		cd -
	fi
done

cd "$WS_DIR/git/$DEST"

for repo in "$DEST" "$@"; do
	repo_name="$(basename "$repo")"
	repo_dir=$WS_DIR/git/$repo_user
	git remote add "$repo_name" "$repo_dir"
	git fetch "$repo_name"
	git branch "$repo_name-master" "$repo_name/master"
	git merge "$repo_name-master"
done
