#!/usr/bin/env bash
##
## install 1password editing applications
## https://apps.wordpress.com/desktop/?ref=promo_reader_a0002
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME=$(basename $0)
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
APP="${APP:-WordPress.com}"
OPTIND=1
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Install wordpress.com App
            echo "flags: -d debug, -v verbose, -h help"
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
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-mac.sh lib-install.sh
shift $((OPTIND-1))

log_exit no longer using desktop app use in browser app instead

if [[ $OSTYPE =~ darwin ]]
then
    if [[ ! -e /Applications/$APP.app ]]
    then
        # need to look through the download page to find the location
        download_url_open  "https://public-api.wordpress.com/rest/v1.1/desktop/osx/download?type=dmg" \
            "wordpress.com.dmg" "$WS_DIR/cache"
        find_in_volume_copy_then_detach "$APP.app"
    fi
    exit
fi
# this doesn't quite work because the actual name of the download is
# different would need to modify deb-install with specific desktop names
deb_install wordpress \
    "https://public-api.wordpress.com/rest/v1.1/desktop/linux/download?type=deb"
