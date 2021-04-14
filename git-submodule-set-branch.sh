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
ORIGIN_REMOTE="${ORIGIN_REMOTE:-origin}"
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
					   -l Set the default remote (default: $ORIGIN_REMOTE)
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
	log_error 2 "$DEST_REPO_PATH is not a git repo"
fi

# To make the git submodule foreach to work you must
# concatenate strings together so it is handled as a single argument
# these strings should be a single command
# https://stackoverflow.com/questions/3260920/how-to-quotes-in-bash-function-parameters
# To make this work, if you wrap "" then you need "\"\"" but not for single
# quotes this does not work for single quotes where \' does not work
# And that each $ has to be done as \$ since we are wrapped in a "
# https://git-scm.com/docs/git-submodule/en
# https://stackoverflow.com/questions/28666357/git-how-to-get-default-branch
# https://stackoverflow.com/questions/49929938/how-to-inject-variables-to-git-submodule-foreach
# https://stackoverflow.com/questions/28666357/git-how-to-get-default-branch
# https://stackoverflow.com/questions/8254120/how-to-escape-a-single-quote-in-single-quote-string-in-bash
# need the special $'string' to make this work so that you can quote single
# quotes
# shellcheck disable=SC2016,SC2154

# https://stackoverflow.com/questions/1777854/how-can-i-specify-a-branch-tag-when-adding-a-git-submodule
# The update pulls from the remote branch you set previously and checks it out
# which git submodule update --init --recursive does not
# note when we get the remote branch, we have to cd to the toplevel
# to actually run the set-branch as the branches are set in the parent repo
# we need the true because set-branch will return false if the
# change has already been made
log_verbose add the test commands
declare -a CMDS
if $VERBOSE; then
	CMDS+=(
		# test variables in foreach
		"git submodule foreach \"echo origin=$ORIGIN_REMOTE\"' sm_path=\$sm_path
		name=\$name displaypath=\$displaypath sha1=\$sha1 toplevel=\$toplevel'"
		# test correct syntax for passing variables
		"git submodule foreach 'default=$ORIGIN_REMOTE && echo \$default'"
		# test using ANSI strings with single quote escapes
		$'git submodule foreach \'default=foo && echo $default\''
		# test single quotes inside double quotes
		"git submodule foreach $'default=\'foo\' && echo \$default'"
		# test running commands and going to top level
		"git submodule foreach 'cd \$toplevel && pwd && echo \$sm_path'"

		# test quoting of double quotes inside double quotes
		#"git submodule foreach \"git remote set-head $ORIGIN_REMOTE -a\""
		# test setting defaults and trapping the errors
		"git submodule foreach
		'cd \$toplevel && pwd && echo \$sm_path &&
		 git submodule set-branch --default -- \$sm_path || true'"
		# test getting the right default branch (expensive)
		#"git submodule foreach
		#\$'default=\$(git remote set-head $ORIGIN_REMOTE -a |
		#awk \'{print \$NF}\') && echo \$default'"
		# now set to the right master
	)
fi
log_verbose "add working commands"
# note that submodule uses /bin/sh and not bash
CMDS+=(
	"git submodule foreach
		\$'default=\$(git remote set-head $ORIGIN_REMOTE -a | awk \'{print \$NF}\') &&
		echo \$default &&
		[ -n \$default ] && 
		git switch \$default &&
		cd \$toplevel &&
		git submodule set-branch -b \$default -- \$sm_path'"
	'git submodule update --init --recursive --remote'
)

log_verbose "Is this a dry run arg is $DRY_RUN_ARG"
# shellcheck disable=SC2086
util_cmd $DRY_RUN_ARG "${CMDS[@]}"

log_warning "look at .gitmodules and you can commit the changes"
