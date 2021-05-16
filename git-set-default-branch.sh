#!/usr/bin/env bash
##
## Set a new default branch
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
REMOTE="${REMOTE:-origin}"
NEW_DEFAULT="${NEW_DEFAULT:-main}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvlf:t:r:n" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Change the from branch to a new branch and set as default on a remote
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"
			           -l leave the master branch do not delete (default: $LEAVE)
			           -f the current default branch
			           -t the new default branch name (default: $NEW_DEFAULT)
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
source_lib lib-git.sh lib-util.sh

if ! $DRY_RUN_FLAG; then
	log_verbose not a dry run
	DRY_RUN=""
fi

log_warning "As of Feb 2021 this does not seem to work go to github.com it is"
log_warning "best to use the gui see https://github.com/github/renaming"
log_warning "settings/branches and change the branch which will create the new one"

# https://github.com/github/renaming
# https://stevenmortimer.com/5-steps-to-change-github-default-branch-from-master-to-main/
# https://dev.to/softprops/digitally-unmastered-the-github-cli-edition-1cc4
# https://www.hanselman.com/blog/easily-rename-your-git-default-branch-from-master-to-main
# finding default branch on github
# https://dev.to/bowmanjd/get-github-default-branch-from-the-command-line-powershell-or-bash-zsh-37m9
# shellcheck disable=SC2016
# https://docs.github.com/en/github/administering-a-repository/renaming-a-branch

# https://stackoverflow.com/questions/28666357/git-how-to-get-default-branch
# git symbolic-ref refs/remotes/origin/HEAD does not work, it always returns
# only the original master, you have to actually run an api call to get it. :w

# https://stackoverflow.com/questions/28666357/git-how-to-get-default-branch
log_verbose "Determine the default branch on github"
OLD_DEFAULT="$(git_default_branch)"
log_verbose "current default branch is $OLD_DEFAULT"

if [[ $OLD_DEFAULT == "$NEW_DEFAULT" ]]; then
	log_exit "default is already $NEW_DEFAULT"
fi

# shellcheck disable=SC2016
CMDS=(
	'gh api -XPATCH "repos/:owner/:repo" -f default_branch="$NEW_DEFAULT" >/dev/null'
	'git branch -m "$OLD_DEFAULT" "$NEW_DEFAULT"'
	'git fetch "$ORIGIN"'
	'git branch -u "$ORIGIN/$NEW_DEFAULT" "$NEW_DEFAULT"'
)

for cmd in "${CMDS[@]}"; do
	log_verbose "run $cmd"
	# shellcheck disable=SC2086
	if ! eval $DRY_RUN $cmd; then
		log_error 1 "failed $?: $cmd"
	fi
done

log_verbose "update all open pull requests"
for pr_count in $(gh pr list -B "$OLD_DEFAULT" -L 999 | cut -f 1); do
	log_verbose "updating with gh api -XPATCH repos/:owner/:repo/pulls/$pr_count -f base=$NEW_DEFAULT"
	if ! $DRY_RUN gh api -XPATCH "repos/:owner/:repo/pulls/$pr_count" -f base="NEW_DEFAULT"; then
		log_error 2 "pr update failed"
	fi
done
