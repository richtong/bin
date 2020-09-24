#!/usr/bin/env bash
##
## Install Tor browser client
## http://dev.deluge-torrent.org/wiki/Installing/Linux/Ubuntu
#
set -e && SCRIPTNAME="$(basename $0)"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: install tor browser
            echo $0 "flags: -d debug -v verbos"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
    esac
done
RELEASE=${RELEASE:-1.5.2}
URL=${URL:-"https://github.com/docker/compose/releases/download/$RELEASE/docker-compose-$(uname -s)-$(uname -m)"}
DESTINATION=${DESTINATION:-"/usr/local/bin/docker-compose"}

if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh

set -u
shift $((OPTIND-1))

repository_install ppa:webupd8team/tor-browser
package_install tor-browser
