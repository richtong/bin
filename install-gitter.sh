#!/usr/bin/env bash
##
## install gitter
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

# curl -L does not work they use javascript redirects
APP=${APP:-Gitter.app}
MAC_URL=${MAC_URL:-"https://update.gitter.im/osx/Gitter-1.162.dmg"}
LINUX_URL=${LINUX_URL:-"https://update.gitter.im/linux/latest"}
while getopts "hdvu:" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Install Gitter
            echo "flags: -d debug, -h help"
            echo "       -u url for program (default: $MAC_URL for MacOS, $LINUX_URL for Linux"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        u)
            URL="$OPTARG"
            ;;
    esac
done

if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-mac.sh lib-util.sh
set -u
shift $((OPTIND-1))

if in_os mac
then
    if [[ ! -e /Applications/$APP ]]
    then
        # note that the url basename is not meaningful for slack for mac
        log_verbose installing gitter on Mac
        download_url_open "$MAC_URL"
        find_in_volume_copy_then_detach "$APP"
    fi
else
    deb_install gitter "$LINUX_URL"
fi
