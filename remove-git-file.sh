#!/usr/bin/env bash
##
## Remove a file like .env that was accidentally checked into a repo
##
##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
# do not need To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# trap 'exit $?' ERR
OPTIND=1
ORG="${ORG:-tongfamily}"
VERSION="${VERSION:-7}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvo" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Remove a files and directories from a git repo
			    usage: $SCRIPTNAME [ flags ] repo [files...]
				flags: -d debug (not functional use bashdb), -v verbose, -h help"
					   -o GitHub organization (default: $ORG)
				note: you should create a new repo for this purpose and leave
					  the old repo as a backup. Do not do this for a working
					  repo. Then clone this repo and operate on it. Finally
					  you can rename this to the old repo name and keep the
					  other one for archive purposes.
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
	o)
		export ORG="$OPTARG"
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

if [[ ! -v REPO ]]; then
	if (($# < 1)); then
		log_error 2 "Must specifiy a repo on command line or as REPO env variable"
	fi
	REPO="$1"
	shift
fi

package_install git-filter-repo

# https://www.toolsqa.com/git/difference-between-git-clone-and-git-fork/
log_verbose "Note that we mirror clone the repo as you cannot fork"
log_verbose "a repo into the same account"
log_verbose "Mirroring $REPO to $REPO-new"

# http://blog.plataformatec.com.br/2013/05/how-to-properly-mirror-a-git-repository/
log_verbose "mirroring $REPO to $REPO-new"

# jq syntax is .[] means all entries and then filter just for the repo name
if [[ ! $(gh repo list "$ORG" --json name --jq '.[] | .name') =~ $REPO-new ]]; then
	log_verbose "No $REPO-new found so create it"
	pushd "$WS_DIR/git" >&/dev/null
	git clone --mirror "git@github.com:$ORG/$REPO" "$REPO-new"
	pushd "$REPO-new" >&/dev/null
	git push --mirror "git@github.com:$ORG/REPO-new"
fi

if ! find "$WS_DIR/git" -maxdepth 1 -name "$REPO-new"; then
	log_verbose "No $WS_DIR/git/$REPO-new found so clone it"
	git clone "git@github.com:$ORG/$REPO-new"
fi

for file in "$@"; do
	log_verbose "Removing $file from $REPO-new"
	# with out invert-path filter would *only* get the $file
	git filter-repo --path "$file" --invert-path
done

log_verbose "Filter complete push it"
git push origin --tags

log_warning "Filter complete examine the $REPO-new and if correct"
log_warning "rename $REPO to $REPO-$(date "_%Y-%M-%d") and $REPO-new to $REPO"
