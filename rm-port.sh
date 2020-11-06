#!/usr/bin/env bash
##
## Remove all Mac Ports
##
## Used when you are switch from Mac Ports to Homebrew
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
OPTIND=1
while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo Remove all Mac Ports
		echo "usage: $SCRIPTNAME [ flags ]"
		echo
		echo "flags: -d debug, -v verbose, -h help"
		echo
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
shift $((OPTIND - 1))

if [[ ! $OSTYPE =~ darwin ]]; then
	log_exit "Mac only"
fi

if ! command -v port >/dev/null; then
	log_exit "No Mac Ports installed"
fi

if ! port installed | grep "No ports"; then
	sudo port -fp uninstall --follow-dependents installed
fi

log_assert "port installed | grep "No ports"" "Ports uninstalled"
