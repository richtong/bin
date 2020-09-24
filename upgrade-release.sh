#!/usr/bin/env bash
##
## Upgrade from major version of Ubuntu
## For instance Ubuntu 14.04 to 16.04
## https://sillycodes.com/upgrading-ubuntu-1404-to-ubuntu/
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
            echo $SCRIPTNAME: Upgrade your system to the next major release
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
source_lib lib-util.sh lib-install.sh

shift $((OPTIND-1))

if ! in_linux ubuntu
then
    log_exit "ONly for Ubuntu"
fi

log_verbose Upgrade all packages
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade

log_verbose upgrade the operating system
package_install update-manager-core
sudo do-release-upgrade
