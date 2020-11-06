#!/usr/bin/env bash
##
## What to do after an upgrade
##
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
trap 'exit $?' ERR

OPTIND=1
POOL="${POOL:-"zfs"}"
OUTPUT="${OUTPUT:-"2>&1 >/dev/null"}"
while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Install ZFS and configure out server"
		echo "flags: -d debug, -h help"
		echo "       -s quotd list of shares (default: $SHARES)"
		echo "       -a max memory zfs arc should take in a fraction (default: $ARC_MAX_FRACTION)"
		echo "	     -f force the change so overwrite existing (default: $FORCE)"
		echo "positionals: /dev/sdb /dev/sdc ...."
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		FLAGS+=" -v "
		OUTPUT=""
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh lib-avahi.sh lib-fs.sh
shift $((OPTIND - 1))

if [[ ! $OSTYPE =~ linux ]]; then
	log_exit "run on linux only"
fi

# if there are no pools, that is sent to stderr
log_verbose "list of importable pools: $(sudo zpool import 2>&1)"

# $OUTPUT handles if zpool send to /dev/null note we do not want quotes
# so the redirection is correctly handled and need eval so that this is handled
# properly other the redirection will look just like an argument to zpool
# shellcheck disable=SC2086
if ! eval sudo zpool list "$POOL" $OUTPUT; then
	log_verbose We could have had a system update so need to import pool
	sudo zpool import "$POOL"
fi
