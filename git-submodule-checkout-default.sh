#!/usr/bin/env bash
# the check we need to do this for DRY_RUN since we don't want to glob
##
##
## Checks out all submodules and rebase in commits
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
ORIGIN_DEFAULT="${ORIGIN_DEFAULT:-main}"
FORCE_FLAG="${FORCE_FLAG:-false}"
FORCE="${FORCE:-""}"
DRY_RUN_ARG="${DRY_RUN_ARG:-""}"
DRY_RUN="${DRY_RUN:-false}"
DEST_REPO_PATH="${DEST_REPO_PATH:-"$PWD"}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvfng:p:m:l:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Gets the organization ready for a commit to main by
			Merge upstream changes from $UPSTREAM_ORG/$UPSTREAM_DEFAULT to origin/$ORIGIN_DEFAULT
			Rebase current branches to origin/$MAIN and push the changes to origin/$MAIN
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"
					   -f force pushs (default: $FORCE_FLAG)
					   -n dry run (default: $DRY_RUN)
					   -l Origin remote name (default: $ORIGIN_REMOTE)
					   -m Origin branch that is the default (default: $ORIGIN_DEFAULT)
			           -g Git repo Url extension (default: $GITHUB_URL)
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
		FORCE_FLAG=true
		FORCE="-$opt"
		;;
	n)
		DRY_RUN=true
		DRY_RUN_ARG="-$opt"
		;;
	l)
		ORIGIN_REMOTE="$OPTARG"
		;;
	m)
		ORIGIN_DEFAULT="$OPTARG"
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

if ! pushd "$DEST_REPO_PATH" >/dev/null; then
	log_error 1 "no $DEST_REPO_PATH"
fi
log_verbose "in $PWD"

if ! git_repo; then
	log_error 2 "$DEST_REPO_PATH is not a git repo"
fi

# shellcheck disable=SC2086
util_cmd -s $DRY_RUN_ARG "git remote set-head origin -a &&
					   git checkout \$(basename
					   \$(git rev-parse --abbrev-ref $ORIGIN_REMOTE/HEAD)) &&
					   git pull --rebase"
