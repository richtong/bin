#!/usr/bin/env bash
##
## Install Deluge client for bit torrents
## http://dev.deluge-torrent.org/wiki/Installing/Linux/Ubuntu
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
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
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh

set -u
shift $((OPTIND-1))

if ! in_os linux
then
    log_exit Linux only
fi

if in_linux ubuntu
then
    # http://dev.deluge-torrent.org/wiki/Installing/Linux/Ubuntu
    repository_install ppa:deluge-team/ppa
    package_install deluged deluge-web deluge-console
elif in_linux debian
then
    # http://forum.deluge-torrent.org/viewtopic.php?t=54413
    # install the ubuntu trusty version from latest ppa on ubuntu does not work
    # http://forum.deluge-torrent.org/viewtopic.php?t=54413
    # repository_install 'deb http://ppa.launchpad.net/deluge-team/ppa/ubuntu trusty main'
    # sudo apt-get install -t trusty libtorrent-rasterbar8 python-libtorrent deluged deluge-web
    # so we just take whatever is in the distro
    package_install deluged deluge-web
fi
