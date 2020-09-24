#!/usr/bin/env bash
##
## Flush the DNS cache of old names
## https://help.dreamhost.com/hc/en-us/articles/214981288-Flushing-your-DNS-cache-in-Mac-OS-X-and-Linux
##
##@author Rich Tong
##@returns 0 on success
#
set -ue && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo Flush DNS cache of stale names
            echo usage: $SCRIPTNAME [ flags ]
            echo
            echo "flags: -d debug, -v verbose, -h help"
            echo
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
shift $((OPTIND-1))
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh

if in_os mac
then
    sudo killall -HUP mDNSResponder
else
    log_verbose with Ubuntu 16.04 dsnmasq set to no cache by default
    # https://ubuntuforums.org/showthread.php?t=2342883
    if sudo service nscd status | grep -q running
    then
        log_verbose found nscd so restarting it as cache
        sudo service nscd restart
    fi
fi
