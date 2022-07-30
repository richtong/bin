#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## Swaps Docker for Mac edge vs stable release (deprecated)
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -ueo pipefail && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
# this replace set -e by running exit on any error use for bashdb
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
OPTIND=1
export FLAGS="${FLAGS:-""}"
DRYRUN="${DRYRUN:-false}"
while getopts "hdvn" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Edge or Stable release of docker, the default is to swap
			Deprecated docker now implements this with an experimental flag in
			Docker desktop
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"
			           -n show the commands you would run (default: $DRYRUN)

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
		;;
	n)
		DRYRUN=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh

log_exit "Deprecated no more docker edge or stable installations in homebrew"

if brew_is_installed; then
	log_verbose docker is installed so remove it
	brew_uninstall docker
	log_verbose install docker edge
	# docker-edge is now in homebrew
	# tap_install caskroom/versions
	brew_install docker-edge
	log_exit Docker Edge installed
fi

log_verbose uninstall docker-edge if present
brew_uninstall docker-edge || true
log_verbose installing docker stable
brew_install docker
log_exit Docker stable installed
