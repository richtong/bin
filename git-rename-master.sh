#!/usr/bin/env bash
##
## Change the default branch from master to main and delete master
## https://gist.github.com/mislav/5ac69530acbe1b4ca909e272caabfdba
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1

LEAVE="${LEAVE:-false}"
DRY_RUN="${DRY_RUN:-false}"
DRY_RUN_PREFIX="${DRY_RUN_PREFIX:-"echo "}"
OLD_BRANCH="${OLD_BRANCH:-master}"
NEW_BRANCH="${NEW_BRANCH:-main}"
REMOTE="${REMOTE:-origin}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvlf:t:r:n" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Change the from branch to a new branch and set as default on a remote
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"
			           -l leave the master branch do not delete (default: $LEAVE)
			           -f the current branch (default: $OLD_BRANCH)
			           -t the new branch name (default: $NEW_BRANCH)
			           -r the remote location (default: $REMOTE)
			           -n dry run (default: $DRY_RUN)
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
	l)
		LEAVE=true
		;;
	f)
		OLD_BRANCH="$OPTARG"
		;;
	t)
		NEW_BRANCH="$OPTARG"
		;;
	r)
		REMOTE="$OPTARG"
		;;
	n)
		DRY_RUN=true
		;;
	*)
		echo "not flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

if ! $DRY_RUN; then
	log_verbose not a dry run
	DRY_RUN_PREFIX=""
fi

log_verbose "getting with git fetch $REMOTE $OLD_BRANCH"
$DRY_RUN_PREFIX git fetch "$REMOTE" "$OLD_BRANCH"
log_verbse "fast forwarding git pull --ff-only $OLD_BRANCH"
$DRY_RUN_PREFIX git merge --ff-only "$OLD_BRANCH"
log_verbose "send updates to $REMOTE"
$DRY_RUN_PREFIX git push "$REMOTE" "$OLD_BRANCH"
log_verbose "creating new with git push -u $REMOTE $OLD_BRANCH:$NEW_BRANCH"
$DRY_RUN_PREFIX git push --set-upstream "$REMOTE" "$OLD_BRANCH:$NEW_BRANCH"

log_verbose "changing default with gh api -XPATCH repos/:owner/:repo -f default_branch=$NEW_BRANCH"
$DRY_RUN_PREFIX gh api -XPATCH "repos/:owner/:repo" -f default_branch="$NEW_BRANCH"

log_verbose "update all open pull requests"
for pr_count in $(gh pr list -B "$OLD_BRANCH" -L 999 | cut -f 1); do
	log_verbose "updating with gh api -XPATCH repos/:owner/:repo/pulls/$pr_count -f base=$NEW_BRANCH"
	$DRY_RUN_PREFIX gh api -XPATCH "repos/:owner/:repo/pulls/$pr_count" -f base="NEW_BRANCH"
done

log_verbose "deleting $OLD_BRANCH with git push --delete $REMOTE $OLD_BRANCH"
$DRY_RUN_PREFIX git push --delete "$REMOTE" "$OLD_BRANCH"
$DRY_RUN_PREFIX git checkout "$NEW_BRANCH"
$DRY_RUN_PREFIX git branch -d "$OLD_BRANCH"
