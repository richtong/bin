#!/usr/bin/env bash
##
## Install Tor browser client
## http://dev.deluge-torrent.org/wiki/Installing/Linux/Ubuntu
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: install tor browser"
		echo "flags: -d debug -v verbose"
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
RELEASE=${RELEASE:-1.5.2}
URL=${URL:-"https://github.com/docker/compose/releases/download/$RELEASE/docker-compose-$(uname -s)-$(uname -m)"}
DESTINATION=${DESTINATION:-"/usr/local/bin/docker-compose"}

# shellcheck source=./include.sh
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh

set -u
shift $((OPTIND - 1))

apt_repository_install ppa:webupd8team/tor-browser
package_install tor-browser
