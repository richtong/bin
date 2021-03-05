#!/usr/bin/env bash
##
##
## Updates all the submodules from their origins
## Then rebases the current local with the remotes
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
ORIGIN_REMOTE="${ORIGIN_REMOTE:-origin}"
DEST_REPO_PATH="${DEST_REPO_PATH:-"$PWD"}"
FORCE_FLAG="${FORCE_FLAG:-false}"
DRY_RUN="${DRY_RUN:-""}"
DRY_RUN_ARG="${DRY_RUN_ARG:-""}"
DRY_RUN_FLAG="${DRY_RUN_FLAG:-false}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvunfg:p:l:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Gets the organization ready for a commit to main by
			Merge upstream changes from $UPSTREAM_ORG/$UPSTREAM_DEFAULT to origin/$ORIGIN_DEFAULT
			Rebase current branches to origin/$MAIN and push the changes to origin/$MAIN
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"
					   -f force pushs (default: $FORCE_FLAG)
					   -n dry run (default: $DRY_RUN_FLAG)
					   -l Origin remote name (default: $ORIGIN_REMOTE)
			           -p The path of the parent repo (default: $DEST_REPO_PATH)
			    Note that repos cannot have white space in their names
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
	f)
		FORCE_FLAG=true
		;;
	n)
		DRY_RUN_FLAG=true
		DRY_RUN_ARG="$opt"
		;;
	l)
		ORIGIN_REMOTE="$OPTARG"
		;;
	p)
		DEST_REPO_PATH="$OPTARG"
		;;
	*)
		echo "not flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh lib-util.sh

DRY_RUN=""
if $DRY_RUN_FLAG; then
	DRY_RUN="echo"
fi
log_verbose "DRY_RUN is $DRY_RUN"

FORCE=""
if $FORCE_FLAG; then
	# shellcheck disable=SC2034
	# only appear unused but is used in the eval
	FORCE="-f"
fi

if ! pushd "$DEST_REPO_PATH" >/dev/null; then
	log_error 1 "no $DEST_REPO_PATH"
fi

log_verbose "in $PWD"
if ! git_repo; then
	log_error 2 "$PWD is not a git repo"
fi

# https://stackoverflow.com/questions/1979167/git-submodule-update
# when you run git submodule update it checks out but not in a branch
# you do not want to work with a detached head
# Remember the original purpose of a submodule was not to work on it
# but just to have a specific commit point that is reliable.
# but most of the time we actually work on it, so then you will have branches
# and then the second line takes care of it. I do not think you need the
# --rebase in the first if you do have something already there that was not
# committed, it takes care of this problem.
# https://stackoverflow.com/questions/8191299/update-a-submodule-to-the-latest-commit
#
# For repos that you are not working on,
# So what the first line does is fine the latest commit point, regardless of
# branch on the remote side. If then runs a rebase against whatever commit you
# are on. Basically, the update is independent of the branch.
#
# The second is branch aware, it says get all the branches from all remotes
# like origin and upstream, then with the current branch, you do a git pull and
# then a push on the local. We are conservative here and will fail if a
# straight fast-forward is not enough. And then we push everything up to the
# default remote usually origin to keep local and remote in sync.
#
#  this looks like duplication to me but I do not understand what update is for
# https://stackoverflow.com/questions/10168449/git-update-submodules-recursively
# if the submodule was created by with git submodule --set-branch then
# we can use the --remote to pull from the main branch
# Note that we are still running in detached mode so need to git switch
CMDS=(
	'git submodule update --init --recursive --rebase --remote'
)
FOREACH=(
	'"git fetch -p --all && git pull --ff-only && git push"'
)
# do not need expansion, the eval takes care of this
# shellcheck disable=SC2086
util_cmd $DRY_RUN_ARG "${CMDS[@]}"

# shellcheck disable=SC2086
util_cmd -s $DRY_RUN_ARG "${FOREACH[@]}"
