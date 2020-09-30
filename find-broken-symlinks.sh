#!/usr/bin/env bash
##
## Find broken symlinks
## https://unix.stackexchange.com/questions/34248/how-can-i-find-broken-symlinks
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
DIR="${DIR:-$PWD}"
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Find broken symlinks using gnu find at

			    usage: $SCRIPTNAME [ flags ] [directory]
			    flags: -d debug, -v verbose, -h help"
			    directory:  directory to search (default: $DIR)
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
		echo "not flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh

find "$DIR" -xtype l -exec test ! -e {} \; -print
