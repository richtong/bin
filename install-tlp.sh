#!/usr/bin/env bash
##
## Install TLP laptop power management for ubuntu
## http://www.webupd8.org/2014/10/advanced-power-management-tool-tlp-06.html
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename $0)
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Install 1Password
            echo "flags: -d debug, -h help"
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
source_lib lib-install.sh
set -u
shift $((OPTIND-1))

if [[ ! $OSTYPE =~ linux ]]
then
    log_error 1 "for linux only"
fi

sudo apt-get purge laptop-mode-tools

repository_install ppa:linrunner/tlp
package_install tlp

log_verbose starting tlp
sudo tlp start
