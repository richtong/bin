#!/usr/bin/env bash
##
## install Flux
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
VERSION="${VERSION:-7}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvr:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs flux
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"
			           -r version number (default: $VERSION)
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

if ! in_os mac; then
	log_error 1 "only work on a Mac"
fi

mac_download_and_move Flux.App https://justgetflux.com/mac/Flux.zip
