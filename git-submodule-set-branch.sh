#!/usr/bin/env bash
# the check we need to do this for DRY_RUN since we don't want to glob
##
##
## For git submodule which do not have a default branch set
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
REMOTE_DEFAULT="${REMOTE_DEFAULT:-origin}"
FORCE_FLAG="${FORCE_FLAG:-false}"
DRY_RUN_ARG="${DRY_RUN_ARG:-""}"
DRY_RUN_FLAG="${DRY_RUN_FLAG:-false}"
DEST_REPO_PATH="${DEST_REPO_PATH:-"$PWD"}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvfnl:p:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			For all modules, set their submodule branch to the repo's default
			branch
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"
					   -f force pushs (default: $FORCE_FLAG)
					   -n dry run (default: $DRY_RUN_FLAG)
					   -l Set the default remote (default: $REMOTE_DEFAULT)
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
		;;
	n)
		DRY_RUN_FLAG=true
		DRY_RUN_ARG="-$opt"
		;;
	l)
		REMOTE_DEFAULT="$OPTARG"
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
	log_error 2 "$DEST_REPO_PATH is not a git repo"
fi

# shellcheck disable=SC2016,SC2154
CMDS=("git submodule foreach
		\"git submodule set-branch
			--branch \$(basename
						\$(git rev-parse --abbrev-ref $REMOTE_DEFAULT/HEAD))
	        -- \"\\\$sm_path\"\"
   ")

# shellcheck disable=SC2086
util_cmd $DRY_RUN_ARG "${CMDS[@]}"
