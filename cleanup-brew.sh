#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## Does cleanup of obsolete software when brew uninstall fails
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
VERSION="${VERSION:-7}"
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdvr:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Cleanup brew packages
			    usage: $SCRIPTNAME [ flags ] [ packages... ]
			    flags: -h help"
			           -r version number (default: $VERSION)
					-d debug $($DEBUGGING && echo "off" || echo "on")
					-v verbose $($VERBOSE && echo "off" || echo "on")
		EOF
		exit 0
		;;
	d)
		# invert the variable when flag is set
		DEBUGGING="$($DEBUGGING && echo false || echo true)"
		export DEBUGGING
		;;
	v)
		VERBOSE="$($VERBOSE && echo false || echo true)"
		export VERBOSE
		# add the -v which works for many commands
		if $VERBOSE; then export FLAGS+=" -v "; fi
		# add the -v which works for many commands
		export FLAGS+=" -v "
		;;
	r)
		VERSION="$OPTARG"
		;;
	*)
		echo "not flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh

if ! in_os mac; then
	exit
fi

log_verbose "python 2.x is obsolete so make sure to remove it"
brew uninstall python@2

# https://stackoverflow.com/questions/56011009/how-do-i-uninstall-a-homebrew-cask-manually
brew update
brew cleanup
brew doctor

log_verbose "Remove all the casks (if any)"
for PACKAGE in "$@"; do
	for LOCATION in Caskroom Cellar; do
		# use the conditional to make sure this doesn't become just root
		if rm -rf "${HOMEBREW_PREFIX:?}/$LOCATION/$PACKAGE"; then
			log_verbose "Found and removed $HOMEBREW_PREFIX/$LOCATION/$PACKAGE"
		fi
	done
done
