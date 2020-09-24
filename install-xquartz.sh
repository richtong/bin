#!/usr/bin/env bash
##
## install xQuartz
## See https://www.xquartz.org
## note that the mac ports version is 1.8 and will not run on El Capitan
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

VERSION=${VERSION:-2.7.9}
CONFIG="${CONFIG:-/etc/ssh/sshd_config}"
DOWNLOAD_URL="${DOWNLOAD_URL:-"https://dl.bintray.com/xquartz/downloads/XQuartz-$VERSION.dmg"}"
OPTIND=1
while getopts "hdvr:c:" opt
do
    case "$opt" in
        h)
            cat <<EOF
Install XQuartz
usage: $SCRIPTNAME [ flags ]
flags: -d debug, -v verbose, -h help
       -r release to download (default: $VERSION)
       -c location of sshd_config and ssh_config (default: $CONFIG)
EOF
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        r)
            VERSION="$OPTARG"
            ;;
        c)
            CONFIG="$OPTARG"
            ;;
    esac
done
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-mac.sh lib-install.sh lib-config.sh
shift $((OPTIND-1))


if [[ ! $OSTYPE =~ darwin ]]
then
    log_exit Only for Mac
fi

log_verbose install using brew
# https://apple.stackexchange.com/questions/224373/install-xquartz-using-homebrew-on-mac-os-x-el-capitan
if ! command -v brew > /dev/null
then
    "$SCRIPT_DIR/install-brew.sh"
fi

cask_install xquartz
if [[ ! -e /Applications/Utilities/XQuartz.app ]]
then
    log_verbose falling back to dmg installation
    download_url_open "$DOWNLOAD_URL"
    # look for XQuartz in a volume prefixed by the name XQuartz
    find_in_volume_open_then_detach XQuartz.pkg XQuartz
fi


log_assert "[[ -e /Applications/Utilities/XQuartz.app ]]" "XQuartz installed" ]]


log_verbose making sure the $CONFIG allows X11 forwarding which can be reset on MacOS upgrades

# https://stackoverflow.com/questions/39622173/cant-run-ssh-x-on-macos-sierra
# note that when you are passing this, you need to make sure not to quote the
# entire line  don't quote it
config_add_once "$CONFIG" X11Forwarding yes
config_add_once "$CONFIG" X11DisplayOffset 10
# This location changed with Sierra apparently
config_add_once "$CONFIG" XAuthLocation /opt/X11/bin/xauth

log_verbose make sure the client allows X11 forwarding
config_add_once "$HOME/.ssh/config" "XAuthLocation /opt/X11/bin/xauth"
config_add_once "$HOME/.ssh/config" "ForwardX11Timeout 596h"
