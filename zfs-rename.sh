#!/usr/bin/env bash
##
## Rename a pool
## This does require the pool not be busy
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
		echo Install Rename a pool by an export and an import
		echo "usage: $SCRIPTNAME [ flags ] old-name new-name"
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
source_lib lib-fs.sh
shift $((OPTIND - 1))

if [[ ! $OSTYPE =~ linux ]]; then
	log_exit Linux only
fi

if (($# < 2)); then
	log_error 1 "need to old name and then the new name"
fi

CURRENT="${CURRENT:-"$1"}"
NEW="${NEW:-"$2"}"

log_verbose move to root and hope that the mounts are not busy
cd /
if ! sudo zpool export "$CURRENT"; then
	log_error 3 "could not import $CURRENT could you be in that folder then cd /?"
fi
sudo zpool import "$CURRENT" "$NEW"

if $VERBOSE; then
	sudo zfs list
fi
