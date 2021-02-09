#!/usr/bin/env bash
##
## merge with upstream
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
UPSTREAM_DEFAULT="${UPSTREAM_DEFAULT:-master}"
UPSTREAM="${UPSTREAM:-upstream}"
DRY_RUN_FLAG="${DRY_RUN_FLAG:-false}"
DRY_RUN="${DRY_RUN:-"echo "}"
MERGE_FLAGS="${MERGE_FLAGS:-"--ff-only"}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvnm:u:g:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Merge upstream changes to current branch
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"
			           -u Name of the upstream remote set with git remote add (default: $UPSTREAM)
			           -m The default main/master branch of upstream  (default: $UPSTREAM_DEFAULT)
			           -n dry run of the commands (default: $DRY_RUN_FLAG)
			           -g Git hub flags on merge (default: $MERGE_FLAGS)
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
	m)
		UPSTREAM_DEFAULT="$OPTARG"
		;;
	u)
		UPSTREAM="$OPTARG"
		;;
	g)
		MERGE_FLAGS="$OPTARG"
		;;
	n)
		DRY_RUN_FLAG=false
		;;
	*)
		echo "not flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-git.sh

if $DRY_RUN_FLAG; then
	DRY_RUN=""
fi

log_verbose "get latest with git fetch $UPSTREAM"
$DRY_RUN git fetch "$UPSTREAM"

log_verbose "do a git merge $MERGE_FLAGS $UPSTREAM/$UPSTREAM_DEFAULT"

# disable shellcheck in case there are no flags
# shellcheck disable=SC2086
$DRY_RUN git merge $MERGE_FLAGS "$UPSTREAM/$UPSTREAM_DEFAULT"
