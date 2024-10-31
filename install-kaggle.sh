#!/usr/bin/env bash
##
## install kaggle downloader and api
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
export FLAGS="${FLAGS:-""}"
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Kaggle downloader and api keys
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"
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
	*)
		echo "no -$opt" >&2
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh

log_warning you need

if [[ ! -e $HOME/.kaggle/kaggle.json ]]; then
	log_warning get kaggle.json from kaggle.com/_your_name/account creat api key
fi

pipx_install kaggle
