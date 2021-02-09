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
DRY_RUN_FLAG="${DRY_RUN_FLAG:-false}"
DRY_RUN="${DRY_RUN:-"echo"}"
OLD_DEFAULT="${OLD_DEFAULT:-master}"
NEW_DEFAULT="${NEW_DEFAULT:-main}"
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
			           -f the current branch (default: $OLD_DEFAULT)
			           -t the new branch name (default: $NEW_DEFAULT)
			           -r the remote location (default: $REMOTE)
			           -n dry run (default: $DRY_RUN_FLAG)
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
		OLD_DEFAULT="$OPTARG"
		;;
	t)
		NEW_DEFAULT="$OPTARG"
		;;
	r)
		REMOTE="$OPTARG"
		;;
	n)
		DRY_RUN_FLAG=true
		;;
	*)
		echo "not flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

if ! $DRY_RUN_FLAG; then
	log_verbose not a dry run
	DRY_RUN=""
fi

log_warning "This not longer works, use the UI at github.com"
log_warning "to change the default branch"

# do not need expansion, the eval takes care of this
# shellcheck disable=SC2016
CMDS=(
	'git fetch --all'
	'git checkout $OLD_DEFAULT'
	'git pull --rebase'
	'git push $FORCE'
	'git push --set-upstream "$REMOTE" "$OLD_DEFAULT:$NEW_DEFAULT"'
)

for cmd in "${CMDS[@]}"; do
	log_verbose "run $cmd"
	# want there to be splitting
	# shellcheck disable=SC2086
	if ! eval $DRY_RUN_FLAG $cmd; then
		log_error 2 "Failed with $?: $cmd"
	fi
done

"$SCRIPT_DIR/git-set-default.sh"

# do not need expansion, the eval takes care of this
# shellcheck disable=SC2016
CMDS=(
	'git checkout "$NEW_DEFAULT"'
	'git push --delete "$REMOTE" "$OLD_DEFAULT"'
	'git branch -d "$OLD_DEFAULT"'
)

for cmd in "${CMDS[@]}"; do
	log_verbose "run $cmd"
	# want there to be splitting
	# shellcheck disable=SC2086
	if ! eval $DRY_RUN_FLAG $cmd; then
		log_error 2 "Failed with $?: $cmd"
	fi
done
