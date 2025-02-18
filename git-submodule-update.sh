#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
##
## INitializes all git submodules to the default branch latest
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
ORIGIN_REMOTE="${ORIGIN_REMOTE:-origin}"
DEST_REPO_PATH="${DEST_REPO_PATH:-"$WS_DIR/git/src"}"
DEST_REPOS=(bin lib app sys user)
FORCE_FLAG="${FORCE_FLAG:-false}"
DRY_RUN="${DRY_RUN:-""}"
DRY_RUN_ARG="${DRY_RUN_ARG:-""}"
DRY_RUN_FLAG="${DRY_RUN_FLAG:-false}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvnp:l:f" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Add submodules, update them to track their default branch and set commit to latest
				    usage: $SCRIPTNAME [ flags ] [ repos... ]
				    flags: -h help"
				-d debug $($DEBUGGING && echo "off" || echo "on")
				-v verbose $($VERBOSE && echo "off" || echo "on")
				-n dry run (default: $DRY_RUN_FLAG)
				-l Origin remote name (default: $ORIGIN_REMOTE)
				-p The location of the mono repo (default: $DEST_REPO_PATH)
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
	f)
		FORCE_FLAG=true
		;;
	n)
		DRY_RUN_FLAG=true
		DRY_RUN_ARG="-$opt"
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

if (($# > 1)); then
	log_verbose "set submodules to update"
	DEST_REPOS=("$@")
fi
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
#  old command which does a fetch pull and push
# '"git fetch -p --all && git pull --ff-only && git push"'
# shellcheck disable=SC2016
FOREACH=(
	'git switch `git rev-parse --abbrev-ref origin/HEAD | cut -d / -f 2`'
	'git pull --ff-only'
)

if ! pushd "$DEST_REPO_PATH" >/dev/null; then
	log_error 1 "no $DEST_REPO_PATH"
fi
log_verbose "in $PWD"
if ! git_repo; then
	log_error 2 "$PWD is not a git repo"
fi
log_verbose "cwd=$PWD"
for module in "${DEST_REPOS[@]}"; do
	if ! pushd "$module" >/dev/null; then
		log_verbose "cwd=$PWD $module not found"
		continue
	fi
	log_verbose "run cmds"
	# shellcheck disable=SC2086
	util_git_cmd $DRY_RUN_ARG "${CMDS[@]}"
	log_verbose "run foreaah"
	# shellcheck disable=SC2086
	util_git_cmd -s $DRY_RUN_ARG "${FOREACH[@]}"
	popd >/dev/null
done
