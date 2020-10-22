#!/usr/bin/env bash
##
## Getting bin, lib and other standard libraries and dealing with upstream
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
REPOS="${REPOS:-"lib bin user/rich"}"
GIT_SOURCE_ORG="${GIT_SOURCE_ORG:-"git@github.com:richtong"}"
UPSTREAM_USER="{UPSTREAM_USER:-$USER}"
REBASE="{REBASE:-false}"
BRANCH="{BRANCH:-master}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvrbs:u:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs the standard helper dev repos at the SOURCE_DIR
				usage: $SCRIPTNAME [ flags ]
				flags: -d debug, -v verbose, -h help"

				-r rebase against origin/master (default: $REBASE)
				-b set your downstream branch (default: $BRANCH)
				-s set the source repo (default: $GIT_SOURCE_ORG)
				-u set the branch to use for you (default: $UPSTREAM_USER)
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
	r)
		REBASE=true
		;;
	*)
		echo "not flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh

if ! pushd "$SOURCE_DIR" >/dev/null; then
	log_error 1 "$SOURCE_DIR does not exist"
fi

# https://www.atlassian.com/git/tutorials/git-forks-and-upstreams
for repo in $REPOS; do
	base=${repo##*/}
	path=${repo%/*}
	mkdir -p "$path"
	if ! pushd "$path" >&/dev/null; then
		log_error 2 "could not create $path"
	fi
	git clone "$GIT_SOURCE_ORG/$base"
	if ! pushd "$base" >/dev/null; then
		log_error 3 "could not create repo $base"
	fi
	if ! git remote -v | grep ^upstream; then
		git remote add upstream "$GIT_SOURCE_ORG/$base"
	fi
	git fetch upstream

	log_verbose "Getting or creating $BRANCH"
	if ! git branch "$BRANCH" | grep "$BRANCH"; then
		log_verbose "no $BRANCH checking origin"
		if git branch -r --list "origin/$BRANCH"; then
			log_verbose "origin/$BRANCH exists checkout out"
			git checkout "$BRANCH"
		else
			log_verbose "no origin/$BRANCH creating"
			git checkout -b "$BRANCH"
			git push --set-upstream origin "$BRANCH"
		fi
	fi
	if $REBASE; then
		log_verbose "rebased origin/$BRANCH against upstream/master"
		git pull --rebase upstream/master
		if $VERBOSE; then
			git status
		fi
	fi

	# vs git rebase which does not pull
	log_verbose "created local branch $UPSTREAM_USER-upstream-$base for convenience"
	git checkout -b "$UPSTREAM_USER-upstream-$base" upstream/master
	log_verbose "To get changes from upstream:"
	log_verbose "   git checkout $UPSTREAM_USER-upstream-$base"
	log_verbose "	git pull --rebase $UPSTREAM_USER-upstream-$base"
	log_verbose "To push changes into upstream from origin/master:"
	log_verbose "    git rebase master && git rebase master -i && git push -f"

	popd || true
done

popd || true
