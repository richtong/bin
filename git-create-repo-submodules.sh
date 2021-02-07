#!/usr/bin/env bash
##
## Creates a new organization with specific
## helper repos for things like shared bin, lib directories
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
UPSTREAM_ORG="${UPSTREAM_ORG:-richtong}"
REPOS="${REPOS:-"bin lib docker user/rich"}"
DEST_REPO_PATH="${DEST_REPO_PATH:-"$PWD"}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvug:u:r:p:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Creates a new organization while adding submodules to shared repos
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"
			           -u Upstream Org to clone from (default: $UPSTREAM_ORG)
			           -g Git repo Url (default: $GITHUB_URL)
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
	u)
		UPSTREAM_ORG="$OPTARG"
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

log_verbose "Got to the "
if ! pushd "$DEST_REPO_PATH" >/dev/null; then
	log_error 1 "no $DEST_REPO_PATH"
fi

if ! git_repo; then
	log_error 2 "$DEST_REPO_PATH is not a git repo"
fi

for repo in $REPOS; do
	log_verbose "forking $UPSTREAM_ORG/$repo"
	if ! gh fork "$GITHUB_URL:$UPSTREAM_ORG/$repo" --clone=false; then
		log_warning "could not fork $repo it may already exist"
	fi
	if ! git submodule add "$GITHUB_URL:$(git_organization)/$repo" "$repo"; then
		log_warning "could not add the submodule it may already exist"
	fi
	if ! push "$repo" >/dev/null; then
		log_error 3 "$repo could not be created"
	fi
	if ! git remote add upstream "$GITHUB_URL:$UPSTREAM_ORG/$repo"; then
		log_warning "could not create upstream may already exist"
	fi
	git fetch upstream
	git fetch
done
