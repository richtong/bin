#!/usr/bin/env bash
##
## Change the origin of a cloned submodule
## This is actually much hard than it looks there do not seem to
## https://gist.github.com/myusuf3/7f645819ded92bda6677
##
##@author Rich Tong
##@returns 0 on success
#
# https://stackoverflow.com/questions/4604486/how-do-i-move-an-existing-git-submodule-within-a-git-repository
# Note: if you just want to move a submodule within your tree
# git mv old/submodule new/submodule now works.
#
# This is the way to do with command line
#  https://stackoverflow.com/questions/60003502/git-how-to-change-url-path-of-a-submodule
#
# git config --file=.gitmodules submodule.Submod.url _new path_
# git config --file=.gitmodules submodule.Submod.branch Development
# git submodule sync
# This command means update all the module, initialize if they don't exis
# If there are submodules nested, keep traversing donw
# Sync with the remote
# git submodule update --init --recursive --remote
#
# This is the oldest way to do by manually hacking
# https://stackoverflow.com/questions/10317676/git-change-origin-of-cloned-submodule
# 1. change the url entry in .gitmodules
# 2. change the url entry in .git/config
# https://help.github.com/en/github/using-git/changing-a-remotes-url
# 3. git submodule sync --recursive or git remote set-url
#
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
ROOT="${ROOT:-""}"
MAIN="${MAIN:-""}"
REPOS="${REPOS:-""}"
FORCE="${FORCE:-false}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvm:fr:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			    Delete git submodule
			    usage: $SCRIPTNAME [ flags ] [ submodule_within_main_repo_full_relative_to_main ]
			    flags: -d debug, -v verbose, -h help
			           -m location of the submodules the default is SOURCEDIR/extern
			           -f the default is dry run this is so destructive force to do the work
			           -r root of the repo the default is SOURCE_DIR note if
						  you are using a different source then set like ~/wsn/git/src
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
		MAIN="$OPTARG"
		;;
	f)
		FORCE=true
		;;
	r)
		ROOT="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh

if ! in_os mac; then
	log_warning only tested on the Mac
fi

if [[ -z $ROOT ]]; then
	ROOT="$SOURCE_DIR"
fi
log_verbose "root of repo where .git lives is ROOT=$ROOT"

if [[ -z $MAIN ]]; then
	MAIN="$ROOT/extern"
fi

log_verbose "parent of external submodules is MAIN=$MAIN"

ROOT_GIT="$ROOT/.git"
if [[ -f "$ROOT/.git" ]]; then
	log_verbose "$ROOT/.git" is a file redirecting to true cache of modules
	ROOT_GIT="$(realpath "$ROOT/$(awk '{print $2}' <"$ROOT/.git")")"
fi
log_verbose "ROOT_GIT=$ROOT_GIT"

if [[ ! -e $ROOT_GIT ]]; then
	log_error 2 "Could not find root of git module cache at $ROOT_GIT"
fi

log_verbose arguments left are $#
if (($# > 0)); then
	log_verbose "found arguments taking set REPOS to  $*"
	REPOS="$*"
fi
log_verbose "moving to $MAIN"
if ! pushd "$MAIN" >/dev/null; then
	log_error 2 "no $MAIN"
fi
if ! $FORCE; then
	log_warning dryrun: "Will remove repos at $MAIN"
fi
log_verbose "looking for $REPOS"

# In the modules, git uses path relative to root
module_path="$(realpath --relative-to="$ROOT" "$MAIN")"
log_verbose ".git modules relative path is module_path=$module_path"

for repo_path in $REPOS; do
	log_verbose "git rm $repo_path"
	if $FORCE && git rm "$repo_path"; then
		log_verbose "git rm $repo_path succeeded"
		continue
	fi
	log_warning "git rm $repo_path failed using manual"

	log_verbose "In directory $PWD"
	repo="$(realpath --relative-to="$MAIN" "$repo_path")"
	log_verbose cleaning "$repo relative to $MAIN"
	log_warning "about to run git submodule deinit -f $repo"
	if $FORCE; then
		if ! git submodule deinit -f "$repo"; then
			log_error 1 "could not git submodule deinit -f $repo"
		fi
	fi

	if [[ ! -e $repo ]]; then
		log_warning "$MAIN/$repo does not exist so skip trying to remove it"
	elif ! $FORCE; then
		log_warning dryrun: git rm -rf "$repo" and rm-rf "$repo" if that fails
	elif [[ -e "$repo" ]] && ! git rm -rf "$repo"; then
		log_warning "try to git rm main repo at $repo"
		if ! rm -rf "$repo"; then
			log_warning rm -rf "$repo" also failed
		fi
	fi
	repo_in_git="$ROOT_GIT/modules/$module_path/$repo"
	if [[ ! -e $repo_in_git ]]; then
		log_warning "Repo in git at $repo_in_git not found"
	elif ! $FORCE; then
		log_warning dryrun: rm -rf "$repo_in_git"
	elif ! rm -rf "$repo_in_git"; then
		log_warning "removing rm -rf failed for $repo_in_git"
	fi
	# if this is a submodule inside another repo then
	# .git will actually be a pointer

	if ! $FORCE; then
		log_warning dryrun: git commit -m "Deleted submodule $repo"
	elif ! git commit -m "Deleted submodule $repo"; then
		log_warning git commit -m "Deleted submodule $repo" failed
	fi
done
popd >/dev/null || true

if ! $FORCE; then
	log_warning dryrun: to actually make the change rerun with FORCE flag
fi

if $VERBOSE || $FORCE; then
	log_warning current submodules are
	git submodule
fi
