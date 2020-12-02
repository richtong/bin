#!/usr/bin/env bash
##
## Post installation a major MacOS upgrade
## Big things that break are osx fuse with catalina
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
# https://apple.stackexchange.com/questions/406351/osxfuse-veracrypt-on-big-sur-osxfuse-seems-to-be-missing-on-your-machine
# Currnetly needs version 3.x to run
HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-"/usr/local"}"
# osxfuse reinstall now fails on Big Sur so do not reinstall
#INCOMPATIBLE_CASKS="${INCOMPATIBLE_CASKS:-"osxfuse"}"
INCOMPATIBLE_CASKS="${INCOMPATIBLE_CASKS:-""}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvi:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Post installation after a major OSX upgrade
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"
			           -i incompatible casks (default: $INCOMPATIBLE_CASKS)
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
	i)
		INCOMPATIBLE_CASKS="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh

if ! in_os mac; then
	log_exit "Mac only"
fi

log_verbose "run unshallow operation so update works"
# https://github.com/Homebrew/brew/pull/9383
for lib in homebrew-core homebrew-cask
do
	repo="$HOMEBREW_PREFIX/Homebrew/Library/Taps/homebrew/$lib"
	if [[ $(git -C "$repo" rev-parse --is-shallow-repository) =~ true ]]
	then
		git -C "$repo" fetch --unshallow
	fi
done

log_verbose "upgrade brew and all casks overriding all autoupdates"
brew update
brew upgrade --greedy

# Need for osfuse which veracrypt ueses this is no longer needed with Big Sur
log_verbose "now reinstall incompatibles"
for c in $INCOMPATIBLE_CASKS; do
	# https://stackoverflow.com/questions/37531605/how-to-test-if-git-repository-is-shallow
	brew reinstall "$c"
done

# homebrew changed so upgrade greedy does casks and packages
# if ! brew upgrade --cask; then
	# log_verbose brew cask failed with $?
# fi

log_warning "you should now reboot"
