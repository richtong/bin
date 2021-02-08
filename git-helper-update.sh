#!/usr/bin/env bash
# shellcheck disable=SC2086
# https://github.com/koalaman/shellcheck/issues/779
# Note this needs to be right after shebang to disable
# the check we need to do this for DRY_RUN since we don't want to glob
##
##
## Updates the helper repos and prepares them for a commit
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
GITHUB_URL="${GITHUB_URL:-"git@github.com:"}"
UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-upstream}"
UPSTREAM_DEFAULT="${UPSTREAM_DEFAULT:-main}"
ORIGIN_REMOTE="${UPSTREAM_REMOTE:-origin}"
ORIGIN_DEFAULT="${ORIGIN_DEFAULT:-main}"
REPOS="${REPOS:-"bin lib docker user/rich"}"
DEST_REPO_PATH="${DEST_REPO_PATH:-"$PWD"}"
FORCE="${FORCE:-false}"
DRY_RUN="${DRY_RUN:-""}"
DRY_RUN_FLAG="${DRY_RUN_FLAG:-false}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvug:u:r:p:w:m:l:fn" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Gets the organization ready for a commit to main by
			Merge upstream changes from $UPSTREAM_ORG/$UPSTREAM_DEFAULT to origin/$ORIGIN_DEFAULT
			Rebase current branches to origin/$MAIN and push the changes to origin/$MAIN
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"
					   -f force pushs (default: $FORCE)
					   -n dry run (default: $DRY_RUN_FLAG)
			           -u Upstream remote name to clone from (default: $UPSTREAM_REMOTE)
			           -w Upstream branch to clone from (default: $UPSTREAM_DEFAULT)
					   -l Origin remote name (default: $ORIGIN_REMOTE)
					   -m Origin branch that is the default (default: $ORIGIN_DEFAULT)
			           -g Git repo Url extension (default: $GITHUB_URL)
			           -r list of repos to use (default:$REPOS)
			           -p The path to the repo being created (default: $DEST_REPO_PATH)
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
		export FORCE=true
		export FORCE_FLAG=" -f "
		;;
	n)
		DRY_RUN_FLAG="$OPT_ARG"
		;;
	u)
		UPSTREAM_REMOTE="$OPTARG"
		;;
	w)
		UPSTREAM_DEFAULT="$OPTARG"
		;;
	l)
		ORIGIN_REMOTE="$OPTARG"
		;;
	m)
		ORIGIN_DEFAULT="$OPTARG"
		;;
	g)
		GITHUB_URL="$OPTARG"
		;;
	r)
		REPOS="$OPTARG"
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

if $DRY_RUN_FLAG; then
	DRY_RUN="echo"
fi

if ! pushd "$DEST_REPO_PATH" >/dev/null; then
	log_error 1 "no $DEST_REPO_PATH"
fi

if ! git_repo; then
	log_error 2 "$DEST_REPO_PATH is not a git repo"
fi

# note this assumes repos names do not have special characters
# https://www.c-sharpcorner.com/article/how-to-merge-upstream-repository-changes-with-your-fork-repository-using-git/
for repo in $REPOS; do
	dev_branch="$(git branch --show-current)"
	log_verbose "In $repo assuming current branch $dev_branch is development branch"

	log_verbose "fetching $UPSTREAM_ORG"
	if ! $DRY_RUN git fetch --all; then
		log_error 1 "could git fetch --all"
	fi
	if ! $DRY_RUN git checkout "$ORIGIN_DEFAULT"; then
		log_error 4 "could not checkout $ORIGIN_DEFAULT"
	fi
	if ! $DRY_RUN git pull --rebase; then
		log_error 5 "could not pull from $ORIGIN_REMOTE/$ORIGIN_DEFAULT"
	fi
	if ! $DRY_RUN git push $FORCE; then
		log_error 6 "could not push local changes on $ORIGIN_DEFAULT to $ORIGIN_REMOTE"
	fi
	if ! $DRY_RUN git merge --ff-only "$UPSTREAM_REMOTE/$UPSTREAM_DEFAULT"; then
		log_error 2 "could not fast forward $ORIGIN_DEFAULT to $UPSTREAM_REMOTE/$UPSTREAM_DEFAULT"
	fi
	if ! $DRY_RUN git push $FORCE_FLAG; then
		log_error 3 "could not push $FORCE_FLAG to $ORIGIN_REMOTE/$ORIGIN_DEFAULT"
	fi
	if ! $DRY_RUN git checkout "$dev_branch"; then
		log_error 6 "could not checkout $dev_branch"
	fi
	if ! $DRY_RUN git rebase "$ORIGIN_DEFAULT"; then
		log_error 7 "rebasing $dev_branch against $ORIGIN_DEFAULT"
	fi
	if ! $DRY_RUN git push $FORCE_FLAG; then
		log_error 8 "could not push to $dev_branch"
	fi
	if ! $DRY_RUN git push "$ORIGIN_REPO" "$dev_branch:$ORIGIN_DEFAULT"; then
		log_error 9 "pushing $ORIGIN_REPO $dev_branch to $DEFAULT_BRANCH"
	fi
	if ! $DRY_RUN git push "$UPSTREAM_REPO" "$dev_branch:$UPSTREAM_DEFAULT"; then
		log_error 10 "pushing change to upstream"
	fi
done
