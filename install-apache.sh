#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## install apache for linux
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
while getopts "hdvw:" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: flags: -d debug, -h help
            echo "    -w WS directory"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        w)
            WS_DIR="$OPTARG"
            ;;
        g)
            GIT_REPOS="$OPTARG"
            ;;
    esac
done
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

set -u

sudo apt-get install -y libapache2-mod-wsgi python-dev apache2
